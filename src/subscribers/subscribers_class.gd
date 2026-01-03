const MessageTypeResolver = preload("res://src/message/message_type_resolver.gd")
const MiddlewareEntry = preload("res://src/middleware/middleware_entry.gd")
const Subscriber = preload("res://src/subscribers/subscriber.gd")

extends RefCounted
## Internal subscribers registry. Manages subscriptions, middleware, and metrics.
## Shared infrastructure used by both CommandBus and EventBus.
## Use CommandBus or EventBus instead.

var _registrations: Dictionary = {}  # StringName -> Array[Subscriber]
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

## Remove items at given indices from array (safe removal from highest to lowest index).
## Inlined from support/array.gd to avoid dependency.
func _remove_indices(array: Array, indices: Array) -> void:
	if indices.is_empty() or array.is_empty():
		return
	
	# Sort indices in descending order for safe removal
	var sorted_indices: Array = indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	
	# Remove items (from highest index to lowest to avoid index shifting issues)
	for i in sorted_indices:
		if i >= 0 and i < array.size():
			array.remove_at(i)

## Find insertion position for priority-sorted array (higher priority first).
##
## Uses O(n) insertion sort algorithm to find the correct position.
##
## @param array: Array of objects with `priority` property (sorted descending by priority)
## @param priority: Priority value to find insertion point for
## @return: Index position where item should be inserted
func _find_priority_insertion_position(array: Array, priority: int) -> int:
	var insert_pos: int = array.size()
	for i in range(array.size() - 1, -1, -1):
		if array[i].priority >= priority:
			insert_pos = i + 1
			break
	return insert_pos

## Insert middleware entry into array in sorted position (higher priority first).
##
## @param middleware_array: Array to insert into
## @param entry: MiddlewareEntry to insert
## @param priority: Priority of the entry
## @param log_type: Type name for logging ("before-middleware" or "after-middleware")
func _insert_middleware_entry(middleware_array: Array, entry: MiddlewareEntry, priority: int, log_type: String) -> void:
	var insert_pos: int = _find_priority_insertion_position(middleware_array, priority)
	middleware_array.insert(insert_pos, entry)
	if _verbose:
		print("[Subscribers] Added ", log_type, " (priority=", priority, ")")

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

## Remove middleware entry from array by ID (single pass).
##
## @param middleware_array: Array to search and remove from
## @param middleware_id: ID of middleware to remove
## @param log_type: Type name for logging ("before-middleware" or "after-middleware")
## @return: true if found and removed, false otherwise
func _remove_middleware_from_array(middleware_array: Array, middleware_id: int, log_type: String) -> bool:
	for i in range(middleware_array.size()):
		if middleware_array[i].id == middleware_id:
			middleware_array.remove_at(i)
			if _verbose:
				print("[Subscribers] Removed ", log_type, " (id=", middleware_id, ")")
			return true
	return false

## Remove middleware.
func remove_middleware(middleware_id: int) -> bool:
	assert(middleware_id >= 0, "Middleware ID must be non-negative")
	
	# Find and remove from before-middleware (single pass)
	if _remove_middleware_from_array(_middleware_before, middleware_id, "before-middleware"):
		return true
	
	# Find and remove from after-middleware (single pass)
	if _remove_middleware_from_array(_middleware_after, middleware_id, "after-middleware"):
		return true
	
	return false

## Clear all middleware.
func clear_middleware() -> void:
	_middleware_before.clear()
	_middleware_after.clear()
	if _verbose:
		print("[Subscribers] Cleared all middleware")

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
	var count: int = m.get("count", 0)
	result.avg_time = m.get("total_time", 0.0) / count if count > 0 else 0.0
	return result

## Get all metrics.
func get_all_metrics() -> Dictionary:
	if not _metrics_enabled:
		return {}
	
	var result: Dictionary = {}
	for key in _metrics.keys():
		var m: Dictionary = _metrics[key]
		var metrics_dict: Dictionary = m.duplicate()
		var count: int = m.get("count", 0)
		metrics_dict.avg_time = m.get("total_time", 0.0) / count if count > 0 else 0.0
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
		_metrics[key] = {
			"count": 0,
			"total_time": 0.0,
			"min_time": INF,
			"max_time": 0.0
		}
	
	var m: Dictionary = _metrics[key]
	m.count += 1
	m.total_time += elapsed_time
	m.min_time = min(m.min_time, elapsed_time)
	m.max_time = max(m.max_time, elapsed_time)

## Register a subscription (internal).
func register(message_type, handler: Callable, priority: int = 0, once: bool = false, owner: Object = null) -> int:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	var entry: Subscriber = Subscriber.new(handler, priority, once, owner)
	
	if not _registrations.has(key):
		_registrations[key] = []
	
	var entries: Array = _registrations[key]
	# Insert in sorted position (higher priority first) - O(n) insertion
	var insert_pos: int = _find_priority_insertion_position(entries, priority)
	entries.insert(insert_pos, entry)
	
	if _verbose:
		print("[Subscribers] Registered to ", key, " (priority=", priority, ", once=", once, ")")
	
	return entry.id

## Erase registration key if entries array is empty.
##
## @param key: Registration key to check
## @param entries: Array of entries to check
func _erase_empty_key_if_needed(key: StringName, entries: Array) -> void:
	if entries.is_empty():
		_registrations.erase(key)

## Unregister by ID (internal).
func unregister_by_id(message_type, registration_id: int) -> bool:
	assert(registration_id >= 0, "Registration ID must be non-negative")
	var key: StringName = MessageTypeResolver.resolve_type(message_type)
	if not _registrations.has(key):
		return false
	
	var entries: Array = _registrations[key]
	var index: int = entries.find(func(e): return e.id == registration_id)
	if index >= 0:
		_remove_indices(entries, [index])
		_erase_empty_key_if_needed(key, entries)
		if _verbose:
			print("[Subscribers] Unregistered from ", key, " (id=", registration_id, ")")
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
		var entry: Subscriber = entries[i]
		if entry.callable == handler:
			to_remove.append(i)
	
	if to_remove.size() > 0:
		_remove_indices(entries, to_remove)
		removed = to_remove.size()
		_erase_empty_key_if_needed(key, entries)
	
	if _verbose and removed > 0:
		print("[Subscribers] Unregistered ", removed, " registration(s) from ", key)
	
	return removed

## Clean up invalid registrations.
##
## @param key: Registration key
## @param entries: Array of Subscriber entries (modified in place if cleanup needed)
## @return: true if any entries were removed, false otherwise
func _cleanup_invalid_registrations(key: StringName, entries: Array) -> bool:
	var to_remove: Array = []
	for i in range(entries.size() - 1, -1, -1):
		if not entries[i].is_valid():
			to_remove.append(i)
	
	if to_remove.size() > 0:
		_remove_indices(entries, to_remove)
		_erase_empty_key_if_needed(key, entries)
		return true
	return false

## Clear registrations for a message type (internal).
func clear_registrations(message_type) -> void:
	var key = MessageTypeResolver.resolve_type(message_type)
	_registrations.erase(key)
	if _verbose:
		print("[Subscribers] Cleared registrations for ", key)

## Clear all registrations.
func clear() -> void:
	_registrations.clear()
	if _verbose:
		print("[Subscribers] Cleared all registrations")

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
## @return: Array of valid Subscriber entries (snapshot, safe for iteration)
func _get_valid_registrations(message_type) -> Array[Subscriber]:
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
func _mark_for_removal(key: StringName, entry: Subscriber) -> void:
	var entries: Array = _registrations.get(key, [])
	var index: int = entries.find(entry)
	if index >= 0:
		_remove_indices(entries, [index])
		_erase_empty_key_if_needed(key, entries)

