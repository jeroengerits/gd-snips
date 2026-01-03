const MessageBus = preload("res://packages/messaging/internal/message_bus.gd")
const SubscriptionRules = preload("res://packages/messaging/rules/subscription_rules.gd")
const Event = preload("res://packages/messaging/types/event.gd")

extends MessageBus
class_name EventBus

## Event bus: publishes events to 0..N subscribers.

var _collect_errors: bool = false  # Optionally enable error logging

## Enable error logging.
func set_collect_errors(enabled: bool) -> void:
	_collect_errors = enabled

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

## Get metrics for an event type.
func get_metrics(event_type) -> Dictionary:
	return super.get_metrics(event_type)

## Get all performance metrics.
func get_all_metrics() -> Dictionary:
	return super.get_all_metrics()

## Subscribe to an event type.
func subscribe(event_type, listener: Callable, priority: int = 0, one_shot: bool = false, bound_object: Object = null) -> int:
	assert(listener.is_valid(), "Listener callable must be valid")
	return super.subscribe(event_type, listener, priority, one_shot, bound_object)

## Unsubscribe from event type.
func unsubscribe(event_type, listener: Callable) -> int:
	return super.unsubscribe(event_type, listener)

## Unsubscribe by ID.
func unsubscribe_by_id(event_type, sub_id: int) -> bool:
	return super.unsubscribe_by_id(event_type, sub_id)

## Publish event to all subscribers.
func publish(evt: Event) -> void:
	assert(evt != null, "Event cannot be null")
	assert(evt is Event, "Event must be an instance of Event")
	await _publish_internal(evt, false)

## Publish event and await all async listeners.
func publish_async(evt: Event) -> void:
	assert(evt != null, "Event cannot be null")
	assert(evt is Event, "Event must be an instance of Event")
	await _publish_internal(evt, true)

## Internal publish implementation.
func _publish_internal(evt: Event, await_async: bool) -> void:
	var key: StringName = get_key_from(evt)
	
	# Execute pre-middleware (can cancel delivery)
	if not super._execute_middleware_pre(evt, key):
		if super._trace_enabled:
			print("[EventBus] Publishing ", key, " cancelled by middleware")
		return
	
	var subs: Array = super._get_valid_subscriptions(key)
	
	if super._trace_enabled:
		print("[EventBus] Publishing ", key, " -> ", subs.size(), " listener(s)")
	
	if subs.is_empty():
		return
	
	var one_shots_to_remove: Array = []
	var start_time: int = Time.get_ticks_msec()
	
	# Create a snapshot for safe iteration (subscribers may unsubscribe during dispatch)
	var subs_snapshot: Array = subs.duplicate()
	
	for sub in subs_snapshot:
		# Re-check validity (object might have been freed since snapshot)
		if not sub.is_valid():
			continue
		
		if not sub.callable.is_valid():
			continue
		
		var result: Variant = null
		
		# Call listener - errors will propagate (GDScript has no try/catch)
		# Error logging provides context before errors crash (if enabled)
		if _collect_errors:
			# Log context before calling (helps debug if error occurs)
			push_warning("[EventBus] Calling listener for event: %s (sub_id=%d)" % [key, sub.id])
		
		result = sub.callable.call(evt)
		
		# Handle async results
		if result is GDScriptFunctionState:
			if await_async:
				# Await async listener completion
				result = await result
			else:
				# Still await async listeners to prevent memory leaks
				# Note: This causes brief blocking, but prevents GDScriptFunctionState leaks.
				# This is why publish() may block even though it doesn't return a result.
				result = await result
		
		# Handle one-shot subscriptions (domain rule: auto-unsubscribe after first delivery)
		if SubscriptionRules.should_remove_after_delivery(sub.one_shot):
			one_shots_to_remove.append({"key": key, "sub": sub})
	
	# Remove one-shot subscriptions after iteration
	for item in one_shots_to_remove:
		super._mark_for_removal(item.key, item.sub)
	
	# Record overall metrics for the entire publish operation
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	super._record_metrics(key, elapsed)
	
	# Execute post-middleware
	super._execute_middleware_post(evt, key, null)

## Get all listeners for event type.
func get_listeners(event_type) -> Array:
	return get_subscriptions(event_type)
