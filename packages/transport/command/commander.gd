const SubscriptionRegistry = preload("res://packages/transport/event/registry.gd")
const Validator = preload("res://packages/transport/command/validator.gd")
const Command = preload("res://packages/transport/type/command.gd")

extends SubscriptionRegistry
class_name Commander

## Commander: routes commands to exactly one handler.

## Error raised during command routing/execution.
class CommandRoutingError extends RefCounted:
	var message: String
	var code: int
	
	enum Code {
		NO_HANDLER,
		MULTIPLE_HANDLERS,
		HANDLER_FAILED
	}
	
	func _init(msg: String, err_code: int) -> void:
		assert(not msg.is_empty(), "CommandRoutingError message cannot be empty")
		assert(err_code >= 0, "CommandRoutingError code must be non-negative")
		message = msg
		code = err_code
	
	func to_string() -> String:
		return "[CommandRoutingError: %s (code=%d)]" % [message, code]

## Register handler for a command type (replaces existing).
func register_handler(command_type, handler: Callable) -> void:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = resolve_type_key(command_type)
	var existing: int = get_registration_count(command_type)
	
	if existing > 0:
		clear_registrations(command_type)
		if _verbose:
			print("[Commander] Replaced existing handler for ", key)
	
	register(command_type, handler, 0, false, null)

## Unregister handler for a command type.
func unregister_handler(command_type) -> void:
	clear_registrations(command_type)

## Execute command. Returns handler result or CommandRoutingError.
func execute(cmd: Command) -> Variant:
	assert(cmd != null, "Command cannot be null")
	assert(cmd is Command, "Command must be an instance of Command")
	var key: StringName = resolve_type_key_from(cmd)
	var start_time: int = Time.get_ticks_msec()
	
	# Execute pre-middleware (can cancel delivery)
	if not _execute_middleware_pre(cmd, key):
		if _trace_enabled:
			print("[Commander] Executing ", key, " cancelled by middleware")
		return CommandRoutingError.new("Command execution cancelled by middleware", CommandRoutingError.Code.HANDLER_FAILED)
	
	var entries: Array = _get_valid_registrations(key)
	
	# Validate routing rules
	var validation: Validator.Result = Validator.validate_count(entries.size())
	
	match validation:
		Validator.Result.NO_HANDLER:
			var err: CommandRoutingError = CommandRoutingError.new("No handler registered for command type: %s" % key, CommandRoutingError.Code.NO_HANDLER)
			push_error(err.to_string())
			_execute_middleware_post(cmd, key, err)
			return err
		
		Validator.Result.MULTIPLE_HANDLERS:
			var err: CommandRoutingError = CommandRoutingError.new("Multiple handlers registered for command type: %s (expected exactly one)" % key, CommandRoutingError.Code.MULTIPLE_HANDLERS)
			push_error(err.to_string())
			_execute_middleware_post(cmd, key, err)
			return err
		
		_:
			# VALID - continue with execution
			pass
	
	var entry = entries[0]
	
	if _trace_enabled:
		print("[Commander] Executing ", key, " -> handler (priority=", entry.priority, ")")
	
	if not entry.is_valid():
		var err: CommandRoutingError = CommandRoutingError.new("Handler is invalid (freed object) for command type: %s" % key, CommandRoutingError.Code.HANDLER_FAILED)
		push_error(err.to_string())
		_execute_middleware_post(cmd, key, err)
		return err
	
	var result: Variant = entry.callable.call(cmd)
	
	# Support async handlers (if they return GDScriptFunctionState)
	if result is GDScriptFunctionState:
		result = await result
	
	# Record performance metrics (if enabled)
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	_record_metrics(key, elapsed)
	
	# Execute post-middleware
	_execute_middleware_post(cmd, key, result)
	
	return result

## Check if handler is registered.
func has_handler(command_type) -> bool:
	return get_registration_count(command_type) > 0

