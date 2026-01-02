const MessageTypeResolver = preload("res://messaging/internal/message_type_resolver.gd")
const SubscriptionRules = preload("res://messaging/rules/subscription_rules.gd")

extends RefCounted
## Generic message bus core supporting different delivery semantics.
##
## Internal implementation - do not use directly. Use CommandBus or EventBus from messaging/messaging.gd.
##
## This is a foundation class that CommandBus and EventBus extend to provide
## specific messaging patterns. The core provides:
## - Type-safe message routing using StringName keys
## - Subscription management with priorities
## - Lifecycle-aware subscriptions (auto-cleanup)
## - One-shot subscriptions
## - Safe iteration during dispatch
## - Debugging and tracing support
## - Middleware/interception support
## - Performance metrics

## Middleware entry for intercepting messages
class Middleware:
	var callback: Callable
	var priority: int = 0
	var id: int
	
	static var _next_id: int = 0
	
	func _init(callback: Callable, priority: int = 0):
		self.callback = callback
		self.priority = priority
		self.id = _next_id
		_next_id += 1

## Subscription entry for tracking handlers/listeners
class Subscription:
	var callable: Callable
	var priority: int = 0
	var one_shot: bool = false
	var bound_object: Object = null  # For lifecycle safety
	var id: int
	
	static var _next_id: int = 0
	
	func _init(callable: Callable, priority: int = 0, one_shot: bool = false, bound_object: Object = null):
		self.callable = callable
		self.priority = priority
		self.one_shot = one_shot
		self.bound_object = bound_object
		self.id = _next_id
		_next_id += 1
	
	func is_valid() -> bool:
		if not SubscriptionRules.is_valid_for_lifecycle(bound_object):
			return false
		return callable.is_valid()
	
	func hash() -> int:
		return id

var _subscriptions: Dictionary = {}  # StringName -> Array[Subscription]
var _verbose: bool = false
var _trace_enabled: bool = false
var _middleware_pre: Array[Middleware] = []  # Pre-processing middleware
var _middleware_post: Array[Middleware] = []  # Post-processing middleware
var _metrics_enabled: bool = false
var _metrics: Dictionary = {}  # StringName -> {count: int, total_time: float, min_time: float, max_time: float}

## Enable verbose logging for debugging.
func set_verbose(enabled: bool) -> void:
	_verbose = enabled

## Enable tracing (logs all message deliveries).
func set_tracing(enabled: bool) -> void:
	_trace_enabled = enabled

## Add middleware for pre-processing (before message delivery).
## [code]callback[/code]: Callable(message, key) -> bool (return false to cancel delivery)
## [code]priority[/code]: Higher priority middleware runs first (default: 0)
## Returns: Middleware ID for removal
func add_middleware_pre(callback: Callable, priority: int = 0) -> int:
	var mw = Middleware.new(callback, priority)
	_middleware_pre.append(mw)
	SubscriptionRules.sort_by_priority(_middleware_pre)
	if _verbose:
		print("[MessageBus] Added pre-middleware (priority=", priority, ")")
	return mw.id

## Add middleware for post-processing (after message delivery).
## [code]callback[/code]: Callable(message, key, result) -> void
## [code]priority[/code]: Higher priority middleware runs first (default: 0)
## Returns: Middleware ID for removal
func add_middleware_post(callback: Callable, priority: int = 0) -> int:
	var mw = Middleware.new(callback, priority)
	_middleware_post.append(mw)
	SubscriptionRules.sort_by_priority(_middleware_post)
	if _verbose:
		print("[MessageBus] Added post-middleware (priority=", priority, ")")
	return mw.id

## Remove middleware by ID.
func remove_middleware(middleware_id: int) -> bool:
	var removed = false
	for i in range(_middleware_pre.size() - 1, -1, -1):
		if _middleware_pre[i].id == middleware_id:
			_middleware_pre.remove_at(i)
			removed = true
			if _verbose:
				print("[MessageBus] Removed pre-middleware (id=", middleware_id, ")")
	
	for i in range(_middleware_post.size() - 1, -1, -1):
		if _middleware_post[i].id == middleware_id:
			_middleware_post.remove_at(i)
			removed = true
			if _verbose:
				print("[MessageBus] Removed post-middleware (id=", middleware_id, ")")
	
	return removed

## Clear all middleware.
func clear_middleware() -> void:
	_middleware_pre.clear()
	_middleware_post.clear()
	if _verbose:
		print("[MessageBus] Cleared all middleware")

## Enable performance metrics tracking.
func set_metrics_enabled(enabled: bool) -> void:
	_metrics_enabled = enabled
	if not enabled:
		_metrics.clear()

## Get performance metrics for a message type.
## Returns: Dictionary with {count: int, total_time: float, avg_time: float, min_time: float, max_time: float} or null
func get_metrics(message_type) -> Dictionary:
	if not _metrics_enabled:
		return {}
	
	var key = get_key(message_type)
	if not _metrics.has(key):
		return {}
	
	var m = _metrics[key]
	var result = m.duplicate()
	if m.count > 0:
		result.avg_time = m.total_time / m.count
	else:
		result.avg_time = 0.0
	return result

## Get all performance metrics.
func get_all_metrics() -> Dictionary:
	if not _metrics_enabled:
		return {}
	
	var result = {}
	for key in _metrics.keys():
		var m = _metrics[key]
		var metrics_dict = m.duplicate()
		if m.count > 0:
			metrics_dict.avg_time = m.total_time / m.count
		else:
			metrics_dict.avg_time = 0.0
		result[key] = metrics_dict
	return result

## Clear all performance metrics.
func clear_metrics() -> void:
	_metrics.clear()

## Internal: Execute pre-middleware, return false if delivery should be cancelled.
func _execute_middleware_pre(message: Object, key: StringName) -> bool:
	for mw in _middleware_pre:
		if not mw.callback.is_valid():
			continue
		var result = mw.callback.call(message, key)
		if result == false:  # Middleware can cancel delivery
			return false
	return true

## Internal: Execute post-middleware.
func _execute_middleware_post(message: Object, key: StringName, delivery_result) -> void:
	for mw in _middleware_post:
		if not mw.callback.is_valid():
			continue
		mw.callback.call(message, key, delivery_result)

## Internal: Record performance metrics.
func _record_metrics(key: StringName, elapsed_time: float) -> void:
	if not _metrics_enabled:
		return
	
	if not _metrics.has(key):
		_metrics[key] = {"count": 0, "total_time": 0.0, "min_time": INF, "max_time": 0.0}
	
	var m = _metrics[key]
	m.count += 1
	m.total_time += elapsed_time
	m.min_time = min(m.min_time, elapsed_time)
	m.max_time = max(m.max_time, elapsed_time)

## Extract StringName key from a message type.
## Delegates to MessageTypeResolver for infrastructure concerns.
static func get_key(message_type) -> StringName:
	return MessageTypeResolver.resolve_type(message_type)

## Get key from a message instance.
## Delegates to MessageTypeResolver for infrastructure concerns.
static func get_key_from(message: Object) -> StringName:
	return MessageTypeResolver.resolve_type(message)

## Subscribe to a message type.
## [code]handler[/code]: Callable to invoke
## [code]priority[/code]: Higher priority subscribers are called first (default: 0)
## [code]one_shot[/code]: Auto-unsubscribe after first delivery (default: false)
## [code]bound_object[/code]: Auto-unsubscribe when this object is freed (default: null)
## Returns: Subscription ID for manual unsubscription
func subscribe(message_type, handler: Callable, priority: int = 0, one_shot: bool = false, bound_object: Object = null) -> int:
	var key = get_key(message_type)
	var sub = Subscription.new(handler, priority, one_shot, bound_object)
	
	if not _subscriptions.has(key):
		_subscriptions[key] = []
	
	_subscriptions[key].append(sub)
	SubscriptionRules.sort_by_priority(_subscriptions[key])
	
	if _verbose:
		print("[MessageBus] Subscribed to ", key, " (priority=", priority, ", one_shot=", one_shot, ")")
	
	return sub.id

## Unsubscribe by subscription ID.
func unsubscribe_by_id(message_type, sub_id: int) -> bool:
	var key = get_key(message_type)
	if not _subscriptions.has(key):
		return false
	
	var subs = _subscriptions[key]
	var index = subs.find(func(s): return s.id == sub_id)
	if index >= 0:
		subs.remove_at(index)
		if subs.is_empty():
			_subscriptions.erase(key)
		if _verbose:
			print("[MessageBus] Unsubscribed from ", key, " (id=", sub_id, ")")
		return true
	return false

## Unsubscribe by callable (removes all matching subscriptions).
func unsubscribe(message_type, handler: Callable) -> int:
	var key = get_key(message_type)
	if not _subscriptions.has(key):
		return 0
	
	var subs = _subscriptions[key]
	var removed = 0
	var to_remove = []
	
	for i in range(subs.size() - 1, -1, -1):
		var sub = subs[i]
		if sub.callable == handler:
			to_remove.append(i)
	
	for i in to_remove:
		subs.remove_at(i)
		removed += 1
	
	if subs.is_empty():
		_subscriptions.erase(key)
	
	if _verbose and removed > 0:
		print("[MessageBus] Unsubscribed ", removed, " subscription(s) from ", key)
	
	return removed

## Get all subscriptions for a message type (cleaned of invalid entries).
func get_subscriptions(message_type) -> Array:
	var key = get_key(message_type)
	if not _subscriptions.has(key):
		return []
	
	var subs = _subscriptions[key]
	_cleanup_invalid_subscriptions(key, subs)
	return subs.duplicate()

## Clean up invalid subscriptions (freed objects, invalid callables).
func _cleanup_invalid_subscriptions(key: StringName, subs: Array) -> void:
	var to_remove = []
	for i in range(subs.size() - 1, -1, -1):
		if not subs[i].is_valid():
			to_remove.append(i)
	
	for i in to_remove:
		subs.remove_at(i)
	
	if subs.is_empty() and to_remove.size() > 0:
		_subscriptions.erase(key)

## Clear all subscriptions for a message type.
func clear_type(message_type) -> void:
	var key = get_key(message_type)
	_subscriptions.erase(key)
	if _verbose:
		print("[MessageBus] Cleared subscriptions for ", key)

## Clear all subscriptions.
func clear() -> void:
	_subscriptions.clear()
	if _verbose:
		print("[MessageBus] Cleared all subscriptions")

## Get all registered message types.
func get_types() -> Array[StringName]:
	var types: Array[StringName] = []
	for key in _subscriptions.keys():
		var subs = _subscriptions[key]
		_cleanup_invalid_subscriptions(key, subs)
		if not subs.is_empty():
			types.append(key)
	return types

## Get subscription count for a message type.
func get_subscription_count(message_type) -> int:
	var key = get_key(message_type)
	if not _subscriptions.has(key):
		return 0
	var subs = _subscriptions[key]
	_cleanup_invalid_subscriptions(key, subs)
	return subs.size()

## Internal: Get valid subscriptions for a message type, sorted by priority.
func _get_valid_subscriptions(message_type) -> Array[Subscription]:
	var key = get_key(message_type)
	if not _subscriptions.has(key):
		return []
	
	var subs = _subscriptions[key]
	_cleanup_invalid_subscriptions(key, subs)
	return subs.duplicate()

## Internal: Mark subscription for removal (one-shot or invalid).
func _mark_for_removal(key: StringName, sub: Subscription) -> void:
	var subs = _subscriptions.get(key, [])
	var index = subs.find(sub)
	if index >= 0:
		subs.remove_at(index)
		if subs.is_empty():
			_subscriptions.erase(key)
