extends MessageBus
class_name CommandBus

## Command bus for dispatching commands with exactly one handler.
##
## Commands represent imperative actions that should have exactly one handler.
## Dispatch returns the handler's result, or raises an error if no handler or
## multiple handlers are registered.
##
## Usage:
##   var bus = CommandBus.create()
##   bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
##       return move_player(cmd.target_position)
##   )
##   var result = await bus.dispatch(MovePlayerCommand.new(Vector2(10, 20)))

## Error class for command bus errors
class CommandBusError extends RefCounted:
	var message: String
	var code: int
	
	enum ErrorCode {
		NO_HANDLER,
		MULTIPLE_HANDLERS,
		HANDLER_FAILED
	}
	
	func _init(msg: String, err_code: int):
		message = msg
		code = err_code
	
	func to_string() -> String:
		return "[CommandBusError: %s (code=%d)]" % [message, code]

## Register a handler for a command type (replaces existing handler).
## [code]command_type[/code]: Command class or StringName
## [code]handler[/code]: Callable that takes the command and returns a result
func handle(command_type, handler: Callable) -> void:
	var key = get_message_key(command_type)
	var existing = get_subscription_count(command_type)
	
	if existing > 0:
		clear_message_type(command_type)
		if _verbose:
			print("[CommandBus] Replaced existing handler for ", key)
	
	subscribe(command_type, handler, 0, false, null)

## Unregister the handler for a command type.
func unregister_handler(command_type) -> void:
	clear_message_type(command_type)

## Dispatch a command to its handler.
## Returns the handler's result (may be Variant, including async results).
## Throws CommandBusError if no handler or multiple handlers are registered.
func dispatch(command: Command) -> Variant:
	var key = get_key_from_message(command)
	# Use the command instance itself for subscription lookup (get_key_from_message handles it)
	var subs = _get_valid_subscriptions(key)
	
	if subs.is_empty():
		var err = CommandBusError.new("No handler registered for command type: %s" % key, CommandBusError.ErrorCode.NO_HANDLER)
		push_error(err.to_string())
		return err
	
	if subs.size() > 1:
		var err = CommandBusError.new("Multiple handlers registered for command type: %s (expected exactly one)" % key, CommandBusError.ErrorCode.MULTIPLE_HANDLERS)
		push_error(err.to_string())
		return err
	
	var sub = subs[0]
	
	if _trace_enabled:
		print("[CommandBus] Dispatching ", key, " -> handler (priority=", sub.priority, ")")
	
	if not sub.is_valid():
		var err = CommandBusError.new("Handler is invalid (freed object) for command type: %s" % key, CommandBusError.ErrorCode.HANDLER_FAILED)
		push_error(err.to_string())
		return err
	
	var result = sub.callable.call(command)
	
	# Support async handlers (if they return GDScriptFunctionState)
	if result is GDScriptFunctionState:
		result = await result
	
	return result

## Check if a handler is registered for a command type.
func has_handler(command_type) -> bool:
	return get_subscription_count(command_type) > 0

## Static factory method.
static func create() -> CommandBus:
	return CommandBus.new()
