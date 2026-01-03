const MessageTypeResolver = preload("res://packages/transport/type/message_type_resolver.gd")
const Validator = preload("res://packages/transport/event/validator.gd")
const MetricsUtils = preload("res://packages/transport/utils/metrics_utils.gd")

extends RefCounted
## Internal subscription registry. Manages subscriptions, middleware, and metrics.
## Use CommandBus or EventBus instead.

## Middleware registry entry.
class MiddlewareEntry:
	var callback: Callable
	var priority: int = 0
	var id: int
	
	static var _next_id: int = 0
	
	func _init(callback: Callable, priority: int = 0):
		self.callback = callback
		self.priority = priority
		self.id = _next_id
		_next_id += 1

## Subscription registry entry.
class SubscriptionEntry:
	var callable: Callable
	var priority: int = 0
	var once: bool = false
	var owner: Object = null  # For lifecycle safety
	var id: int
	
	static var _next_id: int = 0
	
	func _init(callable: Callable, priority: int = 0, once: bool = false, owner: Object = null):
		self.callable = callable
		self.priority = priority
		self.once = once
		self.owner = owner
		self.id = _next_id
		_next_id += 1
	
	func is_valid() -> bool:
		if not Validator.is_valid_for_lifecycle(owner):
			return false
		return callable.is_valid()
	
	func hash() -> int:
		return id

var _registrations: Dictionary = {}  # StringName -> Array[SubscriptionEntry]
var _verbose: bool = false
var _trace_enabled: bool = false
var _middleware_pre: Array[MiddlewareEntry] = []  # Pre-processing middleware
var _middleware_post: Array[MiddlewareEntry] = []  # Post-processing middleware
var _metrics_enabled: bool = false
var _metrics: Dictionary = {}  # StringName -> {count: int, total_time: float, min_time: float, max_time: float}

## Enable verbose logging.
func set_verbose(enabled: bool) -> void:
	_verbose = enabled

## Enable tracing.
func set_trace_enabled(enabled: bool) -> void:
	_trace_enabled = enabled

## Add pre-processing middleware.
func add_middleware_pre(callback: Callable, priority: int = 0) -> int:
	var mw = MiddlewareEntry.new(callback, priority)
	_middleware_pre.append(mw)
	Validator.sort_by_priority(_middleware_pre)
	if _verbose:
		print("[SubscriptionRegistry] Added pre-middleware (priority=", priority, ")")
	return mw.id

## Add post-processing middleware.
func add_middleware_post(callback: Callable, priority: int = 0) -> int:
	var mw = MiddlewareEntry.new(callback, priority)
	_middleware_post.append(mw)
	Validator.sort_by_priority(_middleware_post)
	if _verbose:
		print("[SubscriptionRegistry] Added post-middleware (priority=", priority, ")")
	return mw.id

## Remove middleware.
func remove_middleware(middleware_id: int) -> bool:
	assert(middleware_id >= 0, "Middleware ID must be non-negative")
	var removed: bool = false
	
	# Find and remove from pre-middleware
	var pre_to_remove: Array = []
	for i in range(_middleware_pre.size()):
		if _middleware_pre[i].id == middleware_id:
			pre_to_remove.append(i)
	
	if pre_to_remove.size() > 0:
		_remove_indices_from_array(_middleware_pre, pre_to_remove)
		removed = true
		if _verbose:
			print("[SubscriptionRegistry] Removed pre-middleware (id=", middleware_id, ")")
	
	# Find and remove from post-middleware
	var post_to_remove: Array = []
	for i in range(_middleware_post.size()):
		if _middleware_post[i].id == middleware_id:
			post_to_remove.append(i)
	
	if post_to_remove.size() > 0:
		_remove_indices_from_array(_middleware_post, post_to_remove)
		removed = true
		if _verbose:
			print("[SubscriptionRegistry] Removed post-middleware (id=", middleware_id, ")")
	
	return removed

## Clear all middleware.
func clear_middleware() -> void:
	_middleware_pre.clear()
	_middleware_post.clear()
	if _verbose:
		print("[SubscriptionRegistry] Cleared all middleware")

## Enable metrics tracking.
func set_metrics_enabled(enabled: bool) -> void:
	_metrics_enabled = enabled
	if not enabled:
		_metrics.clear()

## Get metrics for a message type.
func get_metrics(message_type) -> Dictionary:
	if not _metrics_enabled:
		return {}
	
	var key: StringName = resolve_type_key(message_type)
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

## Execute pre-middleware.
func _execute_middleware_pre(message: Object, key: StringName) -> bool:
	for mw in _middleware_pre:
		if not mw.callback.is_valid():
			continue
		var result: Variant = mw.callback.call(message, key)
		if result == false:  # Middleware can cancel delivery
			return false
	return true

## Execute post-middleware.
func _execute_middleware_post(message: Object, key: StringName, delivery_result) -> void:
	for mw in _middleware_post:
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

## Resolve type key from message type.
static func resolve_type_key(message_type) -> StringName:
	return MessageTypeResolver.resolve_type(message_type)

## Resolve type key from message instance.
static func resolve_type_key_from(message: Object) -> StringName:
	return MessageTypeResolver.resolve_type(message)

## Register a subscription (internal).
func register(message_type, handler: Callable, priority: int = 0, once: bool = false, owner: Object = null) -> int:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = resolve_type_key(message_type)
	var entry: SubscriptionEntry = SubscriptionEntry.new(handler, priority, once, owner)
	
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
		print("[SubscriptionRegistry] Registered to ", key, " (priority=", priority, ", once=", once, ")")
	
	return entry.id

## Unregister by ID (internal).
func unregister_by_id(message_type, registration_id: int) -> bool:
	assert(registration_id >= 0, "Registration ID must be non-negative")
	var key: StringName = resolve_type_key(message_type)
	if not _registrations.has(key):
		return false
	
	var entries: Array = _registrations[key]
	var index: int = entries.find(func(e): return e.id == registration_id)
	if index >= 0:
		_remove_indices_from_array(entries, [index])
		if entries.is_empty():
			_registrations.erase(key)
		if _verbose:
			print("[SubscriptionRegistry] Unregistered from ", key, " (id=", registration_id, ")")
		return true
	return false

## Unregister by callable (internal).
func unregister(message_type, handler: Callable) -> int:
	assert(handler.is_valid(), "Handler callable must be valid")
	var key: StringName = resolve_type_key(message_type)
	if not _registrations.has(key):
		return 0
	
	var entries: Array = _registrations[key]
	var removed: int = 0
	var to_remove: Array = []
	
	for i in range(entries.size() - 1, -1, -1):
		var entry: SubscriptionEntry = entries[i]
		if entry.callable == handler:
			to_remove.append(i)
	
	if to_remove.size() > 0:
		_remove_indices_from_array(entries, to_remove)
		removed = to_remove.size()
		if entries.is_empty():
			_registrations.erase(key)
	
	if _verbose and removed > 0:
		print("[SubscriptionRegistry] Unregistered ", removed, " registration(s) from ", key)
	
	return removed

## Get all registrations for a message type (internal).
func get_registrations(message_type) -> Array:
	var key = resolve_type_key(message_type)
	if not _registrations.has(key):
		return []
	
	var entries = _registrations[key]
	_cleanup_invalid_registrations(key, entries)
	return entries.duplicate()

## Clean up invalid registrations.
func _cleanup_invalid_registrations(key: StringName, entries: Array) -> void:
	var to_remove: Array = []
	for i in range(entries.size() - 1, -1, -1):
		if not entries[i].is_valid():
			to_remove.append(i)
	
	if to_remove.size() > 0:
		_remove_indices_from_array(entries, to_remove)
		if entries.is_empty():
			_registrations.erase(key)

## Clear registrations for a message type (internal).
func clear_registrations(message_type) -> void:
	var key = resolve_type_key(message_type)
	_registrations.erase(key)
	if _verbose:
		print("[SubscriptionRegistry] Cleared registrations for ", key)

## Clear all registrations.
func clear() -> void:
	_registrations.clear()
	if _verbose:
		print("[SubscriptionRegistry] Cleared all registrations")

## Get all registered message types.
func get_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in _registrations.keys():
		var entries = _registrations[key]
		_cleanup_invalid_registrations(key, entries)
		if not entries.is_empty():
			types.append(key)
	return types

## Get registration count (internal).
func get_registration_count(message_type) -> int:
	var key: StringName = resolve_type_key(message_type)
	if not _registrations.has(key):
		return 0
	var entries: Array = _registrations[key]
	_cleanup_invalid_registrations(key, entries)
	return entries.size()

## Get valid registrations for a message type (internal).
func _get_valid_registrations(message_type) -> Array[SubscriptionEntry]:
	var key: StringName = resolve_type_key(message_type)
	if not _registrations.has(key):
		return []
	
	var entries: Array = _registrations[key]
	_cleanup_invalid_registrations(key, entries)
	return entries.duplicate()

## Mark registration for removal.
func _mark_for_removal(key: StringName, entry: SubscriptionEntry) -> void:
	var entries: Array = _registrations.get(key, [])
	var index: int = entries.find(entry)
	if index >= 0:
		_remove_indices_from_array(entries, [index])
		if entries.is_empty():
			_registrations.erase(key)

## Remove items at given indices from array.
func _remove_indices_from_array(array: Array, indices: Array) -> void:
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

