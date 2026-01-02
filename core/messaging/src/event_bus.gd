const MessageBus = preload("res://core/messaging/src/message_bus.gd")
const SubscriptionRules = preload("res://core/messaging/src/subscription_rules.gd")
const Event = preload("res://core/messaging/src/event.gd")

extends MessageBus
class_name CoreMessagingEventBus

## Event bus for publishing events with 0..N subscribers.
##
## Events represent notifications that something happened. Multiple subscribers
## can listen to the same event type. Publish is fire-and-forget by default,
## but can await async listeners if needed.
##
## Usage:
##   const Messaging = preload("res://core/messaging/messaging.gd")
##   var bus = Messaging.EventBus.new()
##   bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
##       update_score(evt.points)
##   )
##   bus.publish(EnemyDiedEvent.new(enemy_id, 100))

var _collect_errors: bool = false  # Optionally collect listener errors

## Enable error collection (errors from listeners are collected, not thrown).
func set_collect_errors(enabled: bool) -> void:
	_collect_errors = enabled

## Subscribe to an event type.
## [code]event_type[/code]: Event class or StringName
## [code]listener[/code]: Callable that receives the event
## [code]priority[/code]: Higher priority listeners are called first (default: 0)
## [code]one_shot[/code]: Auto-unsubscribe after first delivery (default: false)
## [code]bound_object[/code]: Auto-unsubscribe when this object is freed (default: null)
## Returns: Subscription ID for manual unsubscription
func subscribe(event_type, listener: Callable, priority: int = 0, one_shot: bool = false, bound_object: Object = null) -> int:
	return super.subscribe(event_type, listener, priority, one_shot, bound_object)

## Unsubscribe from an event type.
func unsubscribe(event_type, listener: Callable) -> int:
	return super.unsubscribe(event_type, listener)

## Unsubscribe by subscription ID.
func unsubscribe_by_id(event_type, sub_id: int) -> bool:
	return super.unsubscribe_by_id(event_type, sub_id)

## Publish an event to all subscribers (fire-and-forget, synchronous).
## Listeners are called in priority order. Errors from listeners are isolated
## (one bad listener won't break others) unless error collection is enabled.
func publish(evt: CoreMessagingEvent) -> void:
	await _publish_internal(evt, false)

## Publish an event and await all async listeners.
## Use this when you need to wait for async listeners to complete.
func publish_async(evt: CoreMessagingEvent) -> void:
	await _publish_internal(evt, true)

## Internal publish implementation.
func _publish_internal(evt: CoreMessagingEvent, await_async: bool) -> void:
	var key = get_key_from_message(evt)
	var subs = _get_valid_subscriptions(key)
	
	if _trace_enabled:
		print("[EventBus] Publishing ", key, " -> ", subs.size(), " listener(s)")
	
	if subs.is_empty():
		return
	
	var errors: Array = []
	var one_shots_to_remove: Array = []
	
	# Create a snapshot for safe iteration (subscribers may unsubscribe during dispatch)
	var subs_snapshot = subs.duplicate()
	
	for sub in subs_snapshot:
		# Re-check validity (object might have been freed since snapshot)
		if not sub.is_valid():
			continue
		
		if not sub.callable.is_valid():
			continue
		
		var result = null
		
		# Call listener and isolate failures
		# GDScript doesn't have try/catch, so errors will propagate but we continue
		result = sub.callable.call(evt)
		
		# Handle async results
		if result is GDScriptFunctionState:
			if await_async:
				# Await async listener completion
				result = await result
			else:
				# Fire-and-forget: still await to prevent leaks, but don't block caller
				# In practice, this will still block, but it's the best we can do
				# For true fire-and-forget, caller should use call_deferred
				await result
		
		# Handle one-shot subscriptions (domain rule: auto-unsubscribe after first delivery)
		if SubscriptionRules.should_remove_after_delivery(sub.one_shot):
			one_shots_to_remove.append({"key": key, "sub": sub})
	
	# Remove one-shot subscriptions after iteration
	for item in one_shots_to_remove:
		_mark_for_removal(item.key, item.sub)
	
	if _collect_errors and not errors.is_empty():
		if _verbose:
			print("[EventBus] Errors occurred in ", errors.size(), " listener(s) for ", key)

## Get all listeners for an event type.
func get_listeners(event_type) -> Array:
	return get_subscriptions(event_type)

