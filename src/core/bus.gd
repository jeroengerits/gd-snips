extends Node
class_name Bus

## Message bus for dispatching commands and events.
##
## Register handlers for commands and subscribers for events, then dispatch/publish messages.
## Can be used as an autoload singleton or instantiated as needed.

var _handlers: Dictionary = {}
var _subscribers: Dictionary = {}

## Register a handler for a command type.
func handle(type: String, fn: Callable) -> void:
	_handlers[type] = fn

## Unregister a command handler.
func unregister_handler(type: String) -> void:
	_handlers.erase(type)

## Register a subscriber for an event type.
func on(type: String, fn: Callable) -> void:
	if not _subscribers.has(type):
		_subscribers[type] = []
	_subscribers[type].append(fn)

## Unregister an event subscriber.
func off(type: String, fn: Callable) -> void:
	if _subscribers.has(type):
		_subscribers[type].erase(fn)
		if _subscribers[type].is_empty():
			_subscribers.erase(type)

## Dispatch a command to its handler.
func send(cmd: Command):
	var fn = _handlers.get(cmd.type())
	if fn != null:
		return fn.call(cmd)
	return null

## Publish an event to all subscribers.
func emit(evt: Event) -> void:
	var subs = _subscribers.get(evt.type(), [])
	for sub in subs:
		sub.call(evt)

## Clear all handlers and subscribers.
func clear() -> void:
	_handlers.clear()
	_subscribers.clear()

## Static factory method.
static func create() -> Bus:
	return Bus.new()

