const Subscribers = preload("res://src/subscribers/subscribers_class.gd")
const EventValidator = preload("res://src/event/event_validator.gd")
const Event = preload("res://src/event/event_class.gd")
const MessageTypeResolver = preload("res://src/message/message_type_resolver.gd")

extends Subscribers
class_name EventBus

## EventBus: broadcasts events to 0..N subscribers.

var _log_listener_calls: bool = false

## Enable listener call logging.
func set_log_listener_calls(enabled: bool) -> void:
	_log_listener_calls = enabled

## Add before-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName) and returns bool (false to cancel)
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func before(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_before(callback, priority)

## Add after-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName, result: Variant) and returns void
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func after(callback: Callable, priority: int = 0) -> int:
	return super.add_middleware_after(callback, priority)

## Remove middleware by ID.
##
## @param middleware_id: Middleware ID returned from before() or after()
## @return: true if middleware was found and removed, false otherwise
func remove_middleware(middleware_id: int) -> bool:
	return super.remove_middleware(middleware_id)

## Clear all middleware.
func clear_middleware() -> void:
	super.clear_middleware()

## Enable metrics tracking.
func set_metrics_enabled(enabled: bool) -> void:
	super.set_metrics_enabled(enabled)

## Get metrics for an event type.
##
## @param event_type: Event class (must have class_name), instance, or StringName
## @return: Dictionary with metrics (count, total_time, min_time, max_time, avg_time) or empty dict if metrics disabled
func get_metrics(event_type: Variant) -> Dictionary:
	return super.get_metrics(event_type)

## Get all metrics.
##
## @return: Dictionary mapping event type keys to metrics dictionaries
func get_all_metrics() -> Dictionary:
	return super.get_all_metrics()

## Subscribe to an event type.
##
## @param event_type: Event class (must have class_name), instance, or StringName
## @param listener: Callable that accepts an Event instance
## @param priority: Higher priority listeners execute first (default: 0)
## @param once: If true, automatically unsubscribe after first delivery (default: false)
## @param owner: Object to bind lifecycle to - auto-unsubscribes when freed (default: null)
## @return: Subscription ID for later unsubscription
## @example:
## ```gdscript
## var sub_id = event_bus.on(EnemyDiedEvent, _on_enemy_died, priority=10, owner=self)
## ```
func on(event_type: Variant, listener: Callable, priority: int = 0, once: bool = false, owner: Object = null) -> int:
	assert(listener.is_valid(), "Listener callable must be valid")
	
	# Validate event_type for better error messages
	if not (event_type is GDScript or event_type is Object or event_type is StringName or event_type is String):
		push_error("[EventBus] Invalid event_type: %s (expected GDScript class, Object instance, StringName, or String)" % [event_type])
		return -1
	
	return register(event_type, listener, priority, once, owner)

## Unsubscribe from event type.
##
## @param event_type: Event class (must have class_name), instance, or StringName
## @param listener: Callable that was used for subscription
## @return: Number of subscriptions removed
func unsubscribe(event_type: Variant, listener: Callable) -> int:
	return unregister(event_type, listener)

## Unsubscribe by ID.
##
## @param event_type: Event class (must have class_name), instance, or StringName
## @param sub_id: Subscription ID returned from on()
## @return: true if subscription was found and removed, false otherwise
func unsubscribe_by_id(event_type: Variant, sub_id: int) -> bool:
	return unregister_by_id(event_type, sub_id)

## Emit event to all subscribers.
##
## Note: This method still awaits async listeners to prevent memory leaks,
## even though it doesn't return a value. Use emit_and_await() for explicit async behavior.
##
## @param evt: Event instance to emit
## @example:
## ```gdscript
## event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
## ```
func emit(evt: Event) -> void:
	assert(evt != null, "Event cannot be null")
	assert(evt is Event, "Event must be an instance of Event")
	await _emit_internal(evt, false)

## Emit event and await all async listeners.
##
## Same behavior as emit(), but makes the async behavior explicit in your code.
##
## @param evt: Event instance to emit
## @example:
## ```gdscript
## await event_bus.emit_and_await(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
## ```
func emit_and_await(evt: Event) -> void:
	assert(evt != null, "Event cannot be null")
	assert(evt is Event, "Event must be an instance of Event")
	await _emit_internal(evt, true)

## Internal emit implementation.
func _emit_internal(evt: Event, await_async: bool) -> void:
	var key: StringName = MessageTypeResolver.resolve_type(evt)
	
	# Execute before-middleware (can cancel delivery)
	if not _execute_middleware_before(evt, key):
		if _trace_enabled:
			print("[EventBus] Emitting ", key, " cancelled by middleware")
		return
	
	var entries: Array = _get_valid_registrations(key)
	
	if _trace_enabled:
		print("[EventBus] Emitting ", key, " -> ", entries.size(), " listener(s)")
	
	if entries.is_empty():
		# Execute after-middleware even when no listeners (consistent with CommandBus)
		_execute_middleware_after(evt, key, null)
		return
	
	var ones_to_remove: Array = []
	var start_time: int = Time.get_ticks_msec()
	
	# entries is already a snapshot from _get_valid_registrations() (safe for iteration)
	# No need to duplicate again - subscribers may unsubscribe during dispatch but we have a snapshot
	var entries_snapshot: Array = entries
	
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
			push_warning("[EventBus] Calling listener for event: %s (registration_id=%d)" % [key, entry.id])
		
		result = entry.callable.call(evt)
		
		# Handle async results
		if result is GDScriptFunctionState:
			if await_async:
				# Await async listener completion
				result = await result
			else:
				# Still await async listeners to prevent memory leaks
				# Note: This causes brief blocking, but prevents GDScriptFunctionState leaks.
				# This is why emit() may block even though it doesn't return a result.
				result = await result
		
		# Handle one-shot subscriptions (domain rule: auto-unsubscribe after first delivery)
		if EventValidator.should_remove_after_delivery(entry.once):
			ones_to_remove.append({"key": key, "entry": entry})
	
	# Remove one-shot subscriptions after iteration
	for item in ones_to_remove:
		_mark_for_removal(item.key, item.entry)
	
	# Record overall metrics for the entire broadcast operation
	var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
	_record_metrics(key, elapsed)
	
	# Execute after-middleware
	_execute_middleware_after(evt, key, null)

