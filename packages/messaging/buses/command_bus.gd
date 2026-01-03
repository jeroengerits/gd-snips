const MessageBus = preload("res://packages/messaging/internal/message_bus.gd")
const CommandRules = preload("res://packages/messaging/rules/command_rules.gd")
const Command = preload("res://packages/messaging/types/command.gd")

extends MessageBus
class_name CommandBus

## Command bus: dispatches commands with exactly one handler.
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

## Add pre-processing middleware.
func add_middleware_pre(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_pre(callback, priority)

## Add post-processing middleware.
func add_middleware_post(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_post(callback, priority)

## Remove middleware.
func remove_middleware(middleware_id: int) -> bool:
	return super.remove_middleware(middleware_id)

## Enable metrics tracking.
func set_metrics_enabled(enabled: bool) -> void:
	super.set_metrics_enabled(enabled)

## Get metrics for a command type.
func get_metrics(command_type) -> Dictionary:
	return super.get_metrics(command_type)

## Get all metrics.
func get_all_metrics() -> Dictionary:
	return super.get_all_metrics()

## Register handler for a command type (replaces existing).
func handle(command_type, handler: Callable) -> void:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = get_key(command_type)
	var existing: int = get_subscription_count(command_type)
	
	if existing > 0:
		clear_type(command_type)
		if _verbose:
			print("[CommandBus] Replaced existing handler for ", key)
	
	subscribe(command_type, handler, 0, false, null)

## Unregister handler for a command type.
func unregister(command_type) -> void:
	clear_type(command_type)

## Dispatch command to its handler. Returns handler result or CommandError.
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

## Check if handler is registered.
func has_handler(command_type) -> bool:
	return get_subscription_count(command_type) > 0
