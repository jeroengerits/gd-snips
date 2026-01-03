const Subscribers = preload("res://addons/subscribers/subscribers_class.gd")
const CommandValidator = preload("res://addons/command/command_validator.gd")
const Command = preload("res://addons/command/command_class.gd")
const CommandRoutingError = preload("res://addons/command/command_routing_error.gd")
const MessageTypeResolver = preload("res://addons/message/message_type_resolver.gd")

extends Subscribers
class_name CommandBus

## CommandBus: routes commands to exactly one handler.

## Add before-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName) and returns bool (false to cancel)
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func before(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_before(callback, priority)

## Add after-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName, result: Variant) and returns void
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func after(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_after(callback, priority)

## Remove middleware by ID.
##
## @param middleware_id: Middleware ID returned from before() or after()
## @return: true if middleware was found and removed, false otherwise
func remove_middleware(middleware_id: int) -> bool:
	return super.remove_middleware(middleware_id)

## Clear all middleware.
func clear_middleware() -> void:
	super.clear_middleware()

## Register handler for a command type (replaces existing).
##
## @param command_type: Command class (must have class_name), instance, or StringName
## @param handler: Callable that accepts a Command and returns Variant
## @example:
## ```gdscript
## command_bus.handle(MovePlayerCommand, func(cmd): return true)
## ```
func handle(command_type: Variant, handler: Callable) -> void:
	assert(handler.is_valid(), "Handler callable must be valid")
	
	# Validate command_type for better error messages
	if not (command_type is GDScript or command_type is Object or command_type is StringName or command_type is String):
		push_error("[CommandBus] Invalid command_type: %s (expected GDScript class, Object instance, StringName, or String)" % [command_type])
		return
	
	var key: StringName = MessageTypeResolver.resolve_type(command_type)
	var existing: int = get_registration_count(command_type)
	
	if existing > 0:
		clear_registrations(command_type)
		if _verbose:
			print("[CommandBus] Replaced existing handler for ", key)
	
	register(command_type, handler, 0, false, null)

## Unregister handler for a command type.
##
## @param command_type: Command class (must have class_name), instance, or StringName
func unregister_handler(command_type: Variant) -> void:
	clear_registrations(command_type)

## Handle routing error: create error, log it, execute after-middleware, and return it.
func _handle_routing_error(cmd: Command, key: StringName, error_code: CommandRoutingError.Code, message: String) -> CommandRoutingError:
	var err: CommandRoutingError = CommandRoutingError.new(message, error_code)
	push_error(err.to_string())
	_execute_middleware_after(cmd, key, err)
	return err

## Dispatch command. Returns handler result or CommandRoutingError.
##
## @param cmd: Command instance to dispatch
## @return: Handler result (Variant) or CommandRoutingError if routing/execution fails
## @example:
## ```gdscript
## var result = await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
## if result is Transport.CommandRoutingError:
##     print("Command failed: ", result.message)
## ```
func dispatch(cmd: Command) -> Variant:
	assert(cmd != null, "Command cannot be null")
	assert(cmd is Command, "Command must be an instance of Command")
	var key: StringName = MessageTypeResolver.resolve_type(cmd)
	var start_time: int = Time.get_ticks_msec()
	
	# Execute before-middleware (can cancel delivery)
	if not _execute_middleware_before(cmd, key):
		if _trace_enabled:
			print("[CommandBus] Dispatching ", key, " cancelled by middleware")
		return CommandRoutingError.new("Command execution cancelled by middleware", CommandRoutingError.Code.HANDLER_FAILED)
	
	var entries: Array = _get_valid_registrations(key)
	
	# Validate routing rules
	var validation: CommandValidator.Result = CommandValidator.validate_count(entries.size())
	
	match validation:
		CommandValidator.Result.NO_HANDLER:
			return _handle_routing_error(cmd, key, CommandRoutingError.Code.NO_HANDLER, "No handler registered for command type: %s" % key)
		
		CommandValidator.Result.MULTIPLE_HANDLERS:
			return _handle_routing_error(cmd, key, CommandRoutingError.Code.MULTIPLE_HANDLERS, "Multiple handlers registered for command type: %s (expected exactly one)" % key)
		
		_:
			# VALID - continue with execution
			pass
	
	var entry = entries[0]
	
	if _trace_enabled:
		print("[CommandBus] Dispatching ", key, " -> handler (priority=", entry.priority, ")")
	
	if not entry.is_valid():
		return _handle_routing_error(cmd, key, CommandRoutingError.Code.HANDLER_FAILED, "Handler is invalid (freed object) for command type: %s" % key)
	
	var result: Variant = entry.callable.call(cmd)
	
	# Support async handlers (if they return GDScriptFunctionState)
	if result is GDScriptFunctionState:
		result = await result
	
	# Record performance metrics (if enabled)
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	_record_metrics(key, elapsed)
	
	# Execute after-middleware
	_execute_middleware_after(cmd, key, result)
	
	return result

