const MessageTypeResolver = preload("res://addons/message/src/message_type_resolver.gd")
const MetricsUtils = preload("res://addons/utils/src/metrics_utils.gd")
const Array = preload("res://addons/support/src/array.gd")
const MiddlewareEntry = preload("res://addons/middleware/src/middleware_entry.gd")
const EventSubscriber = preload("res://addons/event/src/event_subscriber.gd")

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

## Insert middleware entry into array in sorted position (higher priority first).
##
## @param middleware_array: Array to insert into
## @param entry: MiddlewareEntry to insert
## @param priority: Priority of the entry
## @param log_type: Type name for logging ("before-middleware" or "after-middleware")
func _insert_middleware_entry(middleware_array: Array, entry: MiddlewareEntry, priority: int, log_type: String) -> void:
	# Insert in sorted position (higher priority first) - O(n) insertion sort
	var insert_pos: int = middleware_array.size()
	for i in range(middleware_array.size() - 1, -1, -1):
		if middleware_array[i].priority >= priority:
			insert_pos = i + 1
			break
	middleware_array.insert(insert_pos, entry)
	if _verbose:
		print("[EventSubscribers] Added ", log_type, " (priority=", priority, ")")

## Add before-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName) and returns bool (false to cancel)
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func add_middleware_before(callback: Callable, priority: int = 0) -> int:
	assert(callback.is_valid(), "Middleware callback must be valid")
	var mw = MiddlewareEntry.new(callback, priority)
	_insert_middleware_entry(_middleware_before, mw, priority, "before-middleware")
	return mw.id

## Add after-execution middleware.
##
## @param callback: Callable that accepts (message: Message, key: StringName, result: Variant) and returns void
## @param priority: Higher priority middleware executes first (default: 0)
## @return: Middleware ID for later removal
func add_middleware_after(callback: Callable, priority: int = 0) -> int:
	assert(callback.is_valid(), "Middleware callback must be valid")
	var mw = MiddlewareEntry.new(callback, priority)
	_insert_middleware_entry(_middleware_after, mw, priority, "after-middleware")
	return mw.id

## Remove middleware.
func remove_middleware(middleware_id: int) -> bool:
	assert(middleware_id >= 0, "Middleware ID must be non-negative")
	
	# Find and remove from before-middleware (single pass)
	for i in range(_middleware_before.size()):
		if _middleware_before[i].id == middleware_id:
			_middleware_before.remove_at(i)
			if _verbose:
				print("[EventSubscribers] Removed before-middleware (id=", middleware_id, ")")
			return true
	
	# Find and remove from after-middleware (single pass)
	for i in range(_middleware_after.size()):
		if _middleware_after[i].id == middleware_id:
			_middleware_after.remove_at(i)
			if _verbose:
				print("[EventSubscribers] Removed after-middleware (id=", middleware_id, ")")
			return true
	
	return false

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
##
## @param message_type: Message class (must have class_name), instance, or StringName
## @return: Dictionary with metrics (count, total_time, min_time, max_time, avg_time) or empty dict if metrics disabled
func get_metrics(message_type: Variant) -> Dictionary:
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
		Array.remove_indices(entries, [index])
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
		Array.remove_indices(entries, to_remove)
		removed = to_remove.size()
		if entries.is_empty():
			_registrations.erase(key)
	
	if _verbose and removed > 0:
		print("[EventSubscribers] Unregistered ", removed, " registration(s) from ", key)
	
	return removed

## Clean up invalid registrations.
##
## @param key: Registration key
## @param entries: Array of EventSubscriber entries (modified in place if cleanup needed)
## @return: true if any entries were removed, false otherwise
func _cleanup_invalid_registrations(key: StringName, entries: Array) -> bool:
	var to_remove: Array = []
	for i in range(entries.size() - 1, -1, -1):
		if not entries[i].is_valid():
			to_remove.append(i)
	
	if to_remove.size() > 0:
		Array.remove_indices(entries, to_remove)
		if entries.is_empty():
			_registrations.erase(key)
		return true
	return false

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
##
## Returns a snapshot array that can be safely iterated even if registrations
## change during iteration. Only duplicates if cleanup was needed.
##
## @param message_type: Message type to get registrations for
## @return: Array of valid EventSubscriber entries (snapshot, safe for iteration)
func _get_valid_registrations(message_type) -> Array[EventSubscriber]:
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	if not _registrations.has(key):
		return []
	
	var entries: Array = _registrations[key]
	var had_cleanup: bool = _cleanup_invalid_registrations(key, entries)
	
	# Always return a snapshot for safe iteration (callers may modify during iteration)
	# This is necessary because EventBus creates its own snapshot anyway,
	# and CommandBus needs a safe copy for validation
	return entries.duplicate()

## Mark registration for removal.
func _mark_for_removal(key: StringName, entry: EventSubscriber) -> void:
	var entries: Array = _registrations.get(key, [])
	var index: int = entries.find(entry)
	if index >= 0:
		Array.remove_indices(entries, [index])
		if entries.is_empty():
			_registrations.erase(key)

