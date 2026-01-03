const SubscriptionRegistry = preload("res://packages/transport/events/registry.gd")
const SubscriptionValidator = preload("res://packages/transport/events/validator.gd")
const Event = preload("res://packages/transport/types/event.gd")

extends SubscriptionRegistry
class_name EventBroadcaster

## Event broadcaster: broadcasts events to 0..N subscribers.

var _log_listener_calls: bool = false

## Enable listener call logging.
func set_log_listener_calls(enabled: bool) -> void:
	_log_listener_calls = enabled

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

## Get all metrics.
func get_all_metrics() -> Dictionary:
	return super.get_all_metrics()

## Subscribe to an event type.
func subscribe(event_type, listener: Callable, priority: int = 0, once: bool = false, owner: Object = null) -> int:
	assert(listener.is_valid(), "Listener callable must be valid")
	return register(event_type, listener, priority, once, owner)

## Unsubscribe from event type.
func unsubscribe(event_type, listener: Callable) -> int:
	return unregister(event_type, listener)

## Unsubscribe by ID.
func unsubscribe_by_id(event_type, sub_id: int) -> bool:
	return unregister_by_id(event_type, sub_id)

## Broadcast event to all subscribers.
func broadcast(evt: Event) -> void:
	assert(evt != null, "Event cannot be null")
	assert(evt is Event, "Event must be an instance of Event")
	await _broadcast_internal(evt, false)

## Broadcast event and await all async listeners.
func broadcast_and_await(evt: Event) -> void:
	assert(evt != null, "Event cannot be null")
	assert(evt is Event, "Event must be an instance of Event")
	await _broadcast_internal(evt, true)

## Internal broadcast implementation.
func _broadcast_internal(evt: Event, await_async: bool) -> void:
	var key: StringName = resolve_type_key_from(evt)
	
	# Execute pre-middleware (can cancel delivery)
	if not _execute_middleware_pre(evt, key):
		if _trace_enabled:
			print("[EventBroadcaster] Broadcasting ", key, " cancelled by middleware")
		return
	
	var entries: Array = _get_valid_registrations(key)
	
	if _trace_enabled:
		print("[EventBroadcaster] Broadcasting ", key, " -> ", entries.size(), " listener(s)")
	
	if entries.is_empty():
		return
	
	var ones_to_remove: Array = []
	var start_time: int = Time.get_ticks_msec()
	
	# Create a snapshot for safe iteration (subscribers may unsubscribe during dispatch)
	var entries_snapshot: Array = entries.duplicate()
	
	for entry in entries_snapshot:
		# Re-check validity (object might have been freed since snapshot)
		if not entry.is_valid():
			continue
		
		if not entry.callable.is_valid():
			continue
		
		var result: Variant = null
		
		# Call listener - errors will propagate (GDScript has no try/catch)
		# Error logging provides context before errors crash (if enabled)
		if _log_listener_calls:
			# Log context before calling (helps debug if error occurs)
			push_warning("[EventBroadcaster] Calling listener for event: %s (registration_id=%d)" % [key, entry.id])
		
		result = entry.callable.call(evt)
		
		# Handle async results
		if result is GDScriptFunctionState:
			if await_async:
				# Await async listener completion
				result = await result
			else:
				# Still await async listeners to prevent memory leaks
				# Note: This causes brief blocking, but prevents GDScriptFunctionState leaks.
				# This is why broadcast() may block even though it doesn't return a result.
				result = await result
		
		# Handle one-shot subscriptions (domain rule: auto-unsubscribe after first delivery)
		if SubscriptionValidator.should_remove_after_delivery(entry.once):
			ones_to_remove.append({"key": key, "entry": entry})
	
	# Remove one-shot subscriptions after iteration
	for item in ones_to_remove:
		_mark_for_removal(item.key, item.entry)
	
	# Record overall metrics for the entire broadcast operation
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	_record_metrics(key, elapsed)
	
	# Execute post-middleware
	_execute_middleware_post(evt, key, null)

