const Subscribers = preload("res://addons/event/src/event_subscribers.gd")

extends RefCounted
## Middleware API wrapper for EventBus and CommandBus.
##
## Provides a cleaner API for middleware operations:
##   event_bus.middleware.before(...)
##   event_bus.middleware.after(...)
##   event_bus.middleware.remove(...)
##   event_bus.middleware.clear()

var _subscribers: Subscribers

func _init(subscribers: Subscribers) -> void:
	_subscribers = subscribers

## Add before-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName) and returns bool (false to cancel)
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func before(callback: Callable, priority: int = 0) -> int:
	return _subscribers.add_middleware_before(callback, priority)

## Add after-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName, result: Variant) and returns void
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func after(callback: Callable, priority: int = 0) -> int:
	return _subscribers.add_middleware_after(callback, priority)

## Remove middleware by ID.
##
## @param middleware_id: Middleware ID returned from before() or after()
## @return: true if middleware was found and removed, false otherwise
func remove(middleware_id: int) -> bool:
	return _subscribers.remove_middleware(middleware_id)

## Clear all middleware.
func clear() -> void:
	_subscribers.clear_middleware()

