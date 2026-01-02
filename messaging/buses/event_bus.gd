const MessageBus = preload("res://messaging/internal/message_bus.gd")
const SubscriptionRules = preload("res://messaging/rules/subscription_rules.gd")
const Event = preload("res://messaging/types/event.gd")

extends MessageBus
class_name EventBus

## Event bus for publishing events with 0..N subscribers.
##
## Events represent notifications that something happened. Multiple subscribers
## can listen to the same event type. Publish is fire-and-forget by default,
## but can await async listeners if needed.
##
## Usage:
##   const Messaging = preload("res://messaging/messaging.gd")
##   var bus = Messaging.EventBus.new()
##   bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
##       update_score(evt.points)
##   )
##   bus.publish(EnemyDiedEvent.new(enemy_id, 100))

var _collect_errors: bool = false  # Optionally enable error logging

## Enable error collection (logs error context before crashes).
## Note: GDScript has no try/catch, so errors will still crash, but error
## collection logs context information before the crash occurs.
func set_collect_errors(enabled: bool) -> void:
	_collect_errors = enabled

## Add pre-processing middleware (before event delivery).
## [code]callback[/code]: Callable(event: Event, key: StringName) -> bool (return false to cancel)
## [code]priority[/code]: Higher priority runs first (default: 0)
## Returns: Middleware ID for removal
func add_middleware_pre(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_pre(callback, priority)

## Add post-processing middleware (after event delivery).
## [code]callback[/code]: Callable(event: Event, key: StringName, result: Variant) -> void
## [code]priority[/code]: Higher priority runs first (default: 0)
## Returns: Middleware ID for removal
func add_middleware_post(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_post(callback, priority)

## Remove middleware by ID.
func remove_middleware(middleware_id: int) -> bool:
	return super.remove_middleware(middleware_id)

## Enable performance metrics tracking.
func set_metrics_enabled(enabled: bool) -> void:
	super.set_metrics_enabled(enabled)

## Get performance metrics for an event type.
func get_metrics(event_type) -> Dictionary:
	return super.get_metrics(event_type)

## Get all performance metrics.
func get_all_metrics() -> Dictionary:
	return super.get_all_metrics()

## Subscribe to an event type.
## [code]event_type[/code]: Event class or StringName
## [code]listener[/code]: Callable that receives the event
## [code]priority[/code]: Higher priority listeners are called first (default: 0)
## [code]one_shot[/code]: Auto-unsubscribe after first delivery (default: false)
## [code]bound_object[/code]: Auto-unsubscribe when this object is freed (default: null)
## Returns: Subscription ID for manual unsubscription
func subscribe(event_type, listener: Callable, priority: int = 0, one_shot: bool = false, bound_object: Object = null) -> int:
	assert(listener.is_valid(), "Listener callable must be valid")
	return super.subscribe(event_type, listener, priority, one_shot, bound_object)

## Unsubscribe from an event type.
func unsubscribe(event_type, listener: Callable) -> int:
	return super.unsubscribe(event_type, listener)

## Unsubscribe by subscription ID.
func unsubscribe_by_id(event_type, sub_id: int) -> bool:
	return super.unsubscribe_by_id(event_type, sub_id)

## Publish an event to all subscribers (fire-and-forget).
## Listeners are called in priority order.
## 
## Note: Async listeners are still awaited to prevent memory leaks. This means
## publish() may block briefly if listeners are async. For truly non-blocking
## behavior, wrap the call: call_deferred("publish", evt) from a Node context.
func publish(evt: Event) -> void:
	assert(evt != null, "Event cannot be null")
	assert(evt is Event, "Event must be an instance of Event")
	await _publish_internal(evt, false)

## Publish an event and await all async listeners.
## Use this when you need to wait for async listeners to complete.
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
		var listener_start_time: int = Time.get_ticks_msec()
		
		# Call listener - errors will propagate (GDScript has no try/catch)
		# Error collection logs context before errors crash
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
				# Fire-and-forget: still await to prevent memory leaks
				# Note: This causes brief blocking, but prevents GDScriptFunctionState leaks
				result = await result
		
		# Record metrics for this listener (if enabled)
		var listener_elapsed: float = (Time.get_ticks_msec() - listener_start_time) / 1000.0
		super._record_metrics(key, listener_elapsed)
		
		# Handle one-shot subscriptions (domain rule: auto-unsubscribe after first delivery)
		if SubscriptionRules.should_remove_after_delivery(sub.one_shot):
			one_shots_to_remove.append({"key": key, "sub": sub})
	
	# Remove one-shot subscriptions after iteration
	for item in one_shots_to_remove:
		super._mark_for_removal(item.key, item.sub)
	
	# Record overall metrics (if enabled, already recorded per-listener above)
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	super._record_metrics(key, elapsed)
	
	# Execute post-middleware
	super._execute_middleware_post(evt, key, null)

## Get all listeners for an event type.
func get_listeners(event_type) -> Array:
	return get_subscriptions(event_type)
