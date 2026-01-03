const MessageTypeResolver = preload("res://addons/transport/message/message_type_resolver.gd")
const MetricsUtils = preload("res://addons/transport/utils/metrics_utils.gd")
const ArrayUtils = preload("res://addons/transport/utils/array_utils.gd")
const MiddlewareEntry = preload("res://addons/transport/middleware/middleware_entry.gd")
const EventSubscriber = preload("res://addons/transport/event/event_subscriber.gd")

extends RefCounted
## Internal subscribers registry. Manages subscriptions, middleware, and metrics.
## Shared infrastructure used by both CommandBus and EventBus.
## Use CommandBus or EventBus instead.

var _registrations: Dictionary = {}  # StringName -> Array[EventSubscriber]
var _verbose: bool = false
var _trace_enabled: bool = false
var _middleware_before: Array[MiddlewareEntry] = []  # Before-execution middleware
var _middleware_after: Array[MiddlewareEntry] = []  # After-execution middleware
var _metrics_enabled: bool = false
var _metrics: Dictionary = {}  # StringName -> {count: int, total_time: float, min_time: float, max_time: float}

## Enable verbose logging.
func set_verbose(enabled: bool) -> void:
	_verbose = enabled

## Enable trace logging.
func set_trace_enabled(enabled: bool) -> void:
	_trace_enabled = enabled

## Add before-execution middleware.
func add_middleware_before(callback: Callable, priority: int = 0) -> int:
	var mw = MiddlewareEntry.new(callback, priority)
	_middleware_before.append(mw)
	ArrayUtils.sort_by_priority(_middleware_before)
	if _verbose:
		print("[EventSubscribers] Added before-middleware (priority=", priority, ")")
	return mw.id

## Add after-execution middleware.
func add_middleware_after(callback: Callable, priority: int = 0) -> int:
	var mw = MiddlewareEntry.new(callback, priority)
	_middleware_after.append(mw)
	ArrayUtils.sort_by_priority(_middleware_after)
	if _verbose:
		print("[EventSubscribers] Added after-middleware (priority=", priority, ")")
	return mw.id

## Remove middleware.
func remove_middleware(middleware_id: int) -> bool:
	assert(middleware_id >= 0, "Middleware ID must be non-negative")
	var removed: bool = false
	
	# Find and remove from before-middleware
	var before_to_remove: Array = []
	for i in range(_middleware_before.size()):
		if _middleware_before[i].id == middleware_id:
			before_to_remove.append(i)
	
	if before_to_remove.size() > 0:
		ArrayUtils.remove_indices(_middleware_before, before_to_remove)
		removed = true
		if _verbose:
			print("[EventSubscribers] Removed before-middleware (id=", middleware_id, ")")
	
	# Find and remove from after-middleware
	var after_to_remove: Array = []
	for i in range(_middleware_after.size()):
		if _middleware_after[i].id == middleware_id:
			after_to_remove.append(i)
	
	if after_to_remove.size() > 0:
		ArrayUtils.remove_indices(_middleware_after, after_to_remove)
		removed = true
		if _verbose:
			print("[EventSubscribers] Removed after-middleware (id=", middleware_id, ")")
	
	return removed

## Clear all middleware.
func clear_middleware() -> void:
	_middleware_before.clear()
	_middleware_after.clear()
	if _verbose:
		print("[EventSubscribers] Cleared all middleware")

## Enable metrics tracking.
func set_metrics_enabled(enabled: bool) -> void:
	_metrics_enabled = enabled
	if not enabled:
		_metrics.clear()

## Get metrics for a message type.
func get_metrics(message_type) -> Dictionary:
	if not _metrics_enabled:
		return {}
	
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	if not _metrics.has(key):
		return {}
	
	var m: Dictionary = _metrics[key]
	var result: Dictionary = m.duplicate()
	result.avg_time = MetricsUtils.calculate_average_time(m)
	return result

## Get all metrics.
func get_all_metrics() -> Dictionary:
	if not _metrics_enabled:
		return {}
	
	var result: Dictionary = {}
	for key in _metrics.keys():
		var m: Dictionary = _metrics[key]
		var metrics_dict: Dictionary = m.duplicate()
		metrics_dict.avg_time = MetricsUtils.calculate_average_time(m)
		result[key] = metrics_dict
	return result

## Clear all metrics.
func clear_metrics() -> void:
	_metrics.clear()

## Execute before-middleware.
func _execute_middleware_before(message: Object, key: StringName) -> bool:
	for mw in _middleware_before:
		if not mw.callback.is_valid():
			continue
		var result: Variant = mw.callback.call(message, key)
		if result == false:  # Middleware can cancel delivery
			return false
	return true

## Execute after-middleware.
func _execute_middleware_after(message: Object, key: StringName, delivery_result) -> void:
	for mw in _middleware_after:
		if not mw.callback.is_valid():
			continue
		mw.callback.call(message, key, delivery_result)

## Record metrics.
func _record_metrics(key: StringName, elapsed_time: float) -> void:
	assert(elapsed_time >= 0.0, "Elapsed time must be non-negative")
	if not _metrics_enabled:
		return
	
	if not _metrics.has(key):
		_metrics[key] = MetricsUtils.create_empty_metrics()
	
	var m: Dictionary = _metrics[key]
	m.count += 1
	m.total_time += elapsed_time
	m.min_time = min(m.min_time, elapsed_time)
	m.max_time = max(m.max_time, elapsed_time)

## Register a subscription (internal).
func register(message_type, handler: Callable, priority: int = 0, once: bool = false, owner: Object = null) -> int:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	var entry: EventSubscriber = EventSubscriber.new(handler, priority, once, owner)
	
	if not _registrations.has(key):
		_registrations[key] = []
	
	var entries: Array = _registrations[key]
	# Insert in sorted position (higher priority first) - O(n) insertion
	# Find insertion point: registrations are sorted descending by priority
	var insert_pos: int = entries.size()
	for i in range(entries.size() - 1, -1, -1):
		if entries[i].priority >= priority:
			insert_pos = i + 1
			break
	entries.insert(insert_pos, entry)
	
	if _verbose:
		print("[EventSubscribers] Registered to ", key, " (priority=", priority, ", once=", once, ")")
	
	return entry.id

## Unregister by ID (internal).
func unregister_by_id(message_type, registration_id: int) -> bool:
	assert(registration_id >= 0, "Registration ID must be non-negative")
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	if not _registrations.has(key):
		return false
	
	var entries: Array = _registrations[key]
	var index: int = entries.find(func(e): return e.id == registration_id)
	if index >= 0:
		ArrayUtils.remove_indices(entries, [index])
		if entries.is_empty():
			_registrations.erase(key)
		if _verbose:
			print("[EventSubscribers] Unregistered from ", key, " (id=", registration_id, ")")
		return true
	return false

## Unregister by callable (internal).
func unregister(message_type, handler: Callable) -> int:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	if not _registrations.has(key):
		return 0
	
	var entries: Array = _registrations[key]
	var removed: int = 0
	var to_remove: Array = []
	
	for i in range(entries.size() - 1, -1, -1):
		var entry: EventSubscriber = entries[i]
		if entry.callable == handler:
			to_remove.append(i)
	
	if to_remove.size() > 0:
		ArrayUtils.remove_indices(entries, to_remove)
		removed = to_remove.size()
		if entries.is_empty():
			_registrations.erase(key)
	
	if _verbose and removed > 0:
		print("[EventSubscribers] Unregistered ", removed, " registration(s) from ", key)
	
	return removed

## Clean up invalid registrations.
func _cleanup_invalid_registrations(key: StringName, entries: Array) -> void:
	var to_remove: Array = []
	for i in range(entries.size() - 1, -1, -1):
		if not entries[i].is_valid():
			to_remove.append(i)
	
	if to_remove.size() > 0:
		ArrayUtils.remove_indices(entries, to_remove)
		if entries.is_empty():
			_registrations.erase(key)

## Clear registrations for a message type (internal).
func clear_registrations(message_type) -> void:
	var key = MessageTypeResolver.resolve_type(message_type)
	_registrations.erase(key)
	if _verbose:
		print("[EventSubscribers] Cleared registrations for ", key)

## Clear all registrations.
func clear() -> void:
	_registrations.clear()
	if _verbose:
		print("[EventSubscribers] Cleared all registrations")

## Get registration count (internal).
func get_registration_count(message_type) -> int:
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	if not _registrations.has(key):
		return 0
	var entries: Array = _registrations[key]
	_cleanup_invalid_registrations(key, entries)
	return entries.size()

## Get valid registrations for a message type (internal).
func _get_valid_registrations(message_type) -> Array[EventSubscriber]:
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	if not _registrations.has(key):
		return []
	
	var entries: Array = _registrations[key]
	_cleanup_invalid_registrations(key, entries)
	return entries.duplicate()

## Mark registration for removal.
func _mark_for_removal(key: StringName, entry: EventSubscriber) -> void:
	var entries: Array = _registrations.get(key, [])
	var index: int = entries.find(entry)
	if index >= 0:
		ArrayUtils.remove_indices(entries, [index])
		if entries.is_empty():
			_registrations.erase(key)

