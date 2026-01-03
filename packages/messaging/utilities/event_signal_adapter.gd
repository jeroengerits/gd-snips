extends Node
class_name EventSignalAdapter

## Bridges EventBus events to Godot signals.

var _event_bus: EventBus
var _subscriptions: Dictionary = {}  # event_type -> subscription_id

## Create adapter.
func _init(event_bus: EventBus = null) -> void:
	_event_bus = event_bus

## Set EventBus to subscribe to.
func set_event_bus(event_bus: EventBus) -> void:
	assert(event_bus != null, "EventBus cannot be null")
	# Unsubscribe from old bus if exists
	_unsubscribe_all()
	_event_bus = event_bus

## Connect event type to signal.
func connect_event_to_signal(event_type, signal_name: StringName, extractor: Callable = Callable()) -> void:
	assert(_event_bus != null, "EventBus must be set before connecting events")
	assert(event_type != null, "Event type cannot be null")
	assert(not signal_name.is_empty(), "Signal name cannot be empty")
	
	# Check if signal exists
	if not has_signal(signal_name):
		push_error("[EventSignalAdapter] Signal '%s' not found. Declare it in your script." % signal_name)
		return
	
	var listener = func(evt: Event):
		if extractor.is_valid():
			# Use custom extractor
			var args = extractor.call(evt)
			if args is Array:
				# Emit signal with array arguments
				_emit_signal_with_args(signal_name, args)
			else:
				emit_signal(signal_name, args)
		else:
			# Default: emit with event as first argument
			emit_signal(signal_name, evt)
	
	# Subscribe to event (bound to this node for auto-cleanup)
	var sub_id = _event_bus.subscribe(event_type, listener, 0, false, self)
	_subscriptions[event_type] = sub_id

## Disconnect event type from signal.
func disconnect_event_from_signal(event_type) -> void:
	if not _subscriptions.has(event_type):
		return
	
	if _event_bus != null:
		_event_bus.unsubscribe_by_id(event_type, _subscriptions[event_type])
	_subscriptions.erase(event_type)

## Disconnect all events.
func disconnect_all() -> void:
	_unsubscribe_all()

## Get subscription count.
func get_subscription_count() -> int:
	return _subscriptions.size()

## Unsubscribe from all events.
func _unsubscribe_all() -> void:
	if _event_bus == null:
		return
	
	for event_type in _subscriptions.keys():
		_event_bus.unsubscribe_by_id(event_type, _subscriptions[event_type])
	_subscriptions.clear()

## Emit signal with variable arguments.
func _emit_signal_with_args(signal_name: StringName, args: Array) -> void:
	match args.size():
		0:
			emit_signal(signal_name)
		1:
			emit_signal(signal_name, args[0])
		2:
			emit_signal(signal_name, args[0], args[1])
		3:
			emit_signal(signal_name, args[0], args[1], args[2])
		4:
			emit_signal(signal_name, args[0], args[1], args[2], args[3])
		5:
			emit_signal(signal_name, args[0], args[1], args[2], args[3], args[4])
		_:
			# For more than 5 args, emit with first 5
			push_warning("[EventSignalAdapter] Signal '%s' has more than 5 arguments, truncating" % signal_name)
			emit_signal(signal_name, args[0], args[1], args[2], args[3], args[4])

