extends MessageBus
class_name CommandBus

## Command bus for dispatching commands.
##
## Register handlers for commands, then dispatch messages.
## Can be used as an autoload singleton or instantiated as needed.

var _handlers: Dictionary = {}

## Register a handler for a command type.
func handle(type: String, fn: Callable) -> void:
	_handlers[type] = fn

## Unregister a command handler.
func unregister_handler(type: String) -> void:
	_handlers.erase(type)

## Dispatch a command to its handler.
func send(cmd: Command):
	var fn = _handlers.get(cmd.type())
	if fn != null:
		return fn.call(cmd)
	return null

## Clear all handlers.
func clear() -> void:
	_handlers.clear()

## Static factory method.
static func create() -> CommandBus:
	return CommandBus.new()

