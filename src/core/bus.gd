extends Node
class_name Bus

## Message bus for dispatching commands and events.
##
## Register handlers for commands and subscribers for events, then dispatch/publish messages.
## Can be used as an autoload singleton or instantiated as needed.

var _command_handlers: Dictionary = {}  # type -> Callable
var _event_subscribers: Dictionary = {}   # type -> Array[Callable]

## Register a handler for a command type.
##
## Only one handler per command type. Registering again replaces the previous handler.
func register_command_handler(type: String, handler: Callable) -> void:
	_command_handlers[type] = handler

## Unregister a command handler.
func unregister_command_handler(type: String) -> void:
	_command_handlers.erase(type)

## Register a subscriber for an event type.
##
## Multiple subscribers can be registered for the same event type.
func subscribe(type: String, subscriber: Callable) -> void:
	if not _event_subscribers.has(type):
		_event_subscribers[type] = []
	_event_subscribers[type].append(subscriber)

## Unregister an event subscriber.
func unsubscribe(type: String, subscriber: Callable) -> void:
	if _event_subscribers.has(type):
		_event_subscribers[type].erase(subscriber)
		if _event_subscribers[type].is_empty():
			_event_subscribers.erase(type)

## Dispatch a command to its handler.
##
## Returns the result from the handler, or null if no handler is registered.
func dispatch(command: Command):
	var handler = _command_handlers.get(command.get_type())
	if handler != null:
		return handler.call(command)
	return null

## Publish an event to all subscribers.
##
## All registered subscribers for the event type will be called.
func publish(event: Event) -> void:
	var subscribers = _event_subscribers.get(event.get_type(), [])
	for subscriber in subscribers:
		subscriber.call(event)

## Clear all handlers and subscribers.
func clear() -> void:
	_command_handlers.clear()
	_event_subscribers.clear()

