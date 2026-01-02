extends Node
class_name Bus

## Message bus for dispatching commands and events.
##
## Register handlers for commands and subscribers for events, then dispatch/publish messages.
## Can be used as an autoload singleton or instantiated as needed.

var _handlers: Dictionary = {}
var _subs: Dictionary = {}

## Register a handler for a command type.
func handle(type: String, fn: Callable) -> void:
	_handlers[type] = fn

## Unregister a command handler.
func unhandle(type: String) -> void:
	_handlers.erase(type)

## Register a subscriber for an event type.
func on(type: String, fn: Callable) -> void:
	if not _subs.has(type):
		_subs[type] = []
	_subs[type].append(fn)

## Unregister an event subscriber.
func off(type: String, fn: Callable) -> void:
	if _subs.has(type):
		_subs[type].erase(fn)
		if _subs[type].is_empty():
			_subs.erase(type)

## Dispatch a command to its handler.
func send(cmd: Command):
	var fn = _handlers.get(cmd.type())
	if fn != null:
		return fn.call(cmd)
	return null

## Publish an event to all subscribers.
func emit(evt: Event) -> void:
	var subs = _subs.get(evt.type(), [])
	for sub in subs:
		sub.call(evt)

## Clear all handlers and subscribers.
func clear() -> void:
	_handlers.clear()
	_subs.clear()

## Static factory method.
static func create() -> Bus:
	return Bus.new()

