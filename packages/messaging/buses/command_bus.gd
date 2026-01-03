const MessageBus = preload("res://packages/messaging/internal/message_bus.gd")
const CommandRules = preload("res://packages/messaging/rules/command_rules.gd")
const Command = preload("res://packages/messaging/types/command.gd")

extends MessageBus
class_name CommandBus

## Command bus for dispatching commands with exactly one handler.
##
## Implements the Command pattern, where commands represent imperative actions
## that must be handled by exactly one handler. Commands can return values,
## making them suitable for request-response patterns.
##
## **Key Characteristics:**
## - Commands must have exactly one registered handler
## - Dispatch returns the handler's result (supports async handlers)
## - Returns [CommandError] if no handler or multiple handlers are registered
## - Supports middleware for pre/post-processing
## - Supports performance metrics tracking
##
## **Thread Safety:** This implementation is not thread-safe. All operations
## should be performed from the main thread.
##
## @example Basic usage:
##   const Messaging = preload("res://packages/messaging/messaging.gd")
##   var bus = Messaging.CommandBus.new()
##   
##   # Register handler (replaces existing handler if present)
##   bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
##       return move_player(cmd.target_position)
##   )
##   
##   # Dispatch command (returns handler result)
##   var result = await bus.dispatch(MovePlayerCommand.new(Vector2(10, 20)))
##
## @example Async handler:
##   bus.handle(SaveGameCommand, func(cmd: SaveGameCommand):
##       await save_to_file(cmd.filename)
##       return true
##   )
##   var success = await bus.dispatch(SaveGameCommand.new("save1.dat"))
##
## @example Error handling:
##   var result = bus.dispatch(UnknownCommand.new())
##   if result is CommandBus.CommandError:
##       print("Error: ", result.message)

## Error class for command dispatch failures.
##
## Represents errors that occur during command dispatch, such as missing handlers
## or multiple handlers being registered for the same command type.
##
## @note This extends [RefCounted] and is automatically memory-managed.
class CommandError extends RefCounted:
	var message: String
	var code: int
	
	enum ErrorCode {
		NO_HANDLER,
		MULTIPLE_HANDLERS,
		HANDLER_FAILED
	}
	
	func _init(msg: String, err_code: int) -> void:
		assert(not msg.is_empty(), "CommandError message cannot be empty")
		assert(err_code >= 0, "CommandError code must be non-negative")
		message = msg
		code = err_code
	
	func to_string() -> String:
		return "[CommandError: %s (code=%d)]" % [message, code]

## Add pre-processing middleware (before command dispatch).
## [code]callback[/code]: Callable(command: Command, key: StringName) -> bool (return false to cancel)
## [code]priority[/code]: Higher priority runs first (default: 0)
## Returns: Middleware ID for removal
func add_middleware_pre(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_pre(callback, priority)

## Add post-processing middleware (after command dispatch).
## [code]callback[/code]: Callable(command: Command, key: StringName, result: Variant) -> void
## [code]priority[/code]: Higher priority runs first (default: 0)
## Returns: Middleware ID for removal
func add_middleware_post(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_post(callback, priority)

## Remove middleware by ID.
func remove_middleware(middleware_id: int) -> bool:
	return super.remove_middleware(middleware_id)

## Enable performance metrics tracking.
func set_metrics_enabled(enabled: bool) -> void:
	super.set_metrics_enabled(enabled)

## Get performance metrics for a command type.
func get_metrics(command_type) -> Dictionary:
	return super.get_metrics(command_type)

## Get all performance metrics.
func get_all_metrics() -> Dictionary:
	return super.get_all_metrics()

## Register a handler for a command type.
##
## Registers a handler function for the specified command type. If a handler
## already exists for this command type, it will be replaced. The handler will
## be called when [method dispatch] is invoked with a command of this type.
##
## **Handler Signature:** The handler should accept one parameter (the command
## instance) and return a [Variant] result. The handler can be async and return
## a [GDScriptFunctionState], which will be automatically awaited.
##
## @param command_type The command class (preferred) or [StringName] type identifier.
##   For best type resolution, use classes with [code]class_name[/code] defined.
## @param handler A [Callable] that takes the command instance and returns a result.
##   The handler signature should be: [code]func(cmd: CommandType) -> Variant[/code]
##
## @example Register handler:
##   bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
##       player.position = cmd.target_position
##       return true
##   )
##
## @note This replaces any existing handler for the command type. To unregister,
##   use [method unregister].
func handle(command_type, handler: Callable) -> void:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = get_key(command_type)
	var existing: int = get_subscription_count(command_type)
	
	if existing > 0:
		clear_type(command_type)
		if _verbose:
			print("[CommandBus] Replaced existing handler for ", key)
	
	subscribe(command_type, handler, 0, false, null)

## Unregister the handler for a command type.
func unregister(command_type) -> void:
	clear_type(command_type)

## Dispatch a command to its registered handler.
##
## Executes the command by calling its registered handler. The handler's return
## value is returned directly. If the handler is async (returns [GDScriptFunctionState]),
## it will be automatically awaited.
##
## **Validation:** Before dispatch, validates that exactly one handler is registered
## for the command type. If validation fails, returns a [CommandError] instead
## of calling the handler.
##
## **Middleware:** Pre-middleware is executed before dispatch (can cancel delivery).
## Post-middleware is executed after dispatch completes.
##
## **Performance:** If metrics are enabled, execution time is recorded for the
## command type.
##
## @param cmd The [Command] instance to dispatch. Must not be [code]null[/code] and
##   must be an instance of a [Command] subclass.
##
## @return The handler's return value as a [Variant], or a [CommandError] if
##   dispatch fails (no handler, multiple handlers, or handler failure).
##
## @example Dispatch command:
##   var cmd = MovePlayerCommand.new(Vector2(100, 200))
##   var result = await bus.dispatch(cmd)
##   if result is CommandBus.CommandError:
##       print("Dispatch failed: ", result.message)
##   else:
##       print("Player moved successfully: ", result)
##
## @note This method is async-safe - it will await async handlers automatically.
##   Always use [code]await[/code] when calling this method, even for sync handlers.
func dispatch(cmd: Command) -> Variant:
	assert(cmd != null, "Command cannot be null")
	assert(cmd is Command, "Command must be an instance of Command")
	var key: StringName = get_key_from(cmd)
	var start_time: int = Time.get_ticks_msec()
	
	# Execute pre-middleware (can cancel delivery)
	if not super._execute_middleware_pre(cmd, key):
		if super._trace_enabled:
			print("[CommandBus] Dispatching ", key, " cancelled by middleware")
		return CommandError.new("Command dispatch cancelled by middleware", CommandError.ErrorCode.HANDLER_FAILED)
	
	var subs: Array = super._get_valid_subscriptions(key)
	
	# Use domain service to validate routing rules
	var validation: CommandRules.ValidationResult = CommandRules.validate_count(subs.size())
	
	match validation:
		CommandRules.ValidationResult.NO_HANDLER:
			var err: CommandError = CommandError.new("No handler registered for command type: %s" % key, CommandError.ErrorCode.NO_HANDLER)
			push_error(err.to_string())
			_execute_middleware_post(cmd, key, err)
			return err
		
		CommandRules.ValidationResult.MULTIPLE_HANDLERS:
			var err: CommandError = CommandError.new("Multiple handlers registered for command type: %s (expected exactly one)" % key, CommandError.ErrorCode.MULTIPLE_HANDLERS)
			push_error(err.to_string())
			_execute_middleware_post(cmd, key, err)
			return err
		
		_:
			# VALID - continue with dispatch
			pass
	
	var sub = subs[0]
	
	if super._trace_enabled:
		print("[CommandBus] Dispatching ", key, " -> handler (priority=", sub.priority, ")")
	
	if not sub.is_valid():
		var err: CommandError = CommandError.new("Handler is invalid (freed object) for command type: %s" % key, CommandError.ErrorCode.HANDLER_FAILED)
		push_error(err.to_string())
		_execute_middleware_post(cmd, key, err)
		return err
	
	var result: Variant = sub.callable.call(cmd)
	
	# Support async handlers (if they return GDScriptFunctionState)
	if result is GDScriptFunctionState:
		result = await result
	
	# Record performance metrics (if enabled)
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	super._record_metrics(key, elapsed)
	
	# Execute post-middleware
	super._execute_middleware_post(cmd, key, result)
	
	return result

## Check if a handler is registered for a command type.
func has_handler(command_type) -> bool:
	return get_subscription_count(command_type) > 0
