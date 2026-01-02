const MessageBus = preload("res://core/messaging/src/message_bus.gd")
const CommandRules = preload("res://core/messaging/src/command_rules.gd")
const Command = preload("res://core/messaging/src/command.gd")

extends MessageBus
class_name CoreMessagingCommandBus

## Command bus for dispatching commands with exactly one handler.
##
## Commands represent imperative actions that should have exactly one handler.
## Dispatch returns the handler's result, or raises an error if no handler or
## multiple handlers are registered.
##
## Usage:
##   const Messaging = preload("res://core/messaging/messaging.gd")
##   var bus = Messaging.CommandBus.new()
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
func dispatch(cmd: CoreMessagingCommand) -> Variant:
	var key = get_key_from_message(cmd)
	var subs = _get_valid_subscriptions(key)
	
	# Use domain service to validate routing rules
	var validation = CommandRules.validate_handler_count(subs.size())
	
	match validation:
		CommandRules.ValidationResult.NO_HANDLER:
			var err = CommandBusError.new("No handler registered for command type: %s" % key, CommandBusError.ErrorCode.NO_HANDLER)
			push_error(err.to_string())
			return err
		
		CommandRules.ValidationResult.MULTIPLE_HANDLERS:
			var err = CommandBusError.new("Multiple handlers registered for command type: %s (expected exactly one)" % key, CommandBusError.ErrorCode.MULTIPLE_HANDLERS)
			push_error(err.to_string())
			return err
		
		_:
			# VALID - continue with dispatch
			pass
	
	var sub = subs[0]
	
	if _trace_enabled:
		print("[CommandBus] Dispatching ", key, " -> handler (priority=", sub.priority, ")")
	
	if not sub.is_valid():
		var err = CommandBusError.new("Handler is invalid (freed object) for command type: %s" % key, CommandBusError.ErrorCode.HANDLER_FAILED)
		push_error(err.to_string())
		return err
	
	var result = sub.callable.call(cmd)
	
	# Support async handlers (if they return GDScriptFunctionState)
	if result is GDScriptFunctionState:
		result = await result
	
	return result

## Check if a handler is registered for a command type.
func has_handler(command_type) -> bool:
	return get_subscription_count(command_type) > 0

