extends Node
class_name EventBus

## Event bus for publishing events.
##
## Register subscribers for events, then publish messages.
## Can be used as an autoload singleton or instantiated as needed.

var _subscribers: Dictionary = {}

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

## Publish an event to all subscribers.
func emit(evt: Event) -> void:
	var subs = _subscribers.get(evt.type(), [])
	for sub in subs:
		sub.call(evt)

## Clear all subscribers.
func clear() -> void:
	_subscribers.clear()

## Static factory method.
static func create() -> EventBus:
	return EventBus.new()

