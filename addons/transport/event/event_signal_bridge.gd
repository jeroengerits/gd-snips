const SignalConnectionTracker = preload("res://addons/transport/utils/signal_connection_tracker.gd")

extends RefCounted
class_name EventSignalBridge

## Bridges Godot signals to EventBus events.

var _event_bus: EventBus
var _connection_tracker: SignalConnectionTracker = SignalConnectionTracker.new()

## Create adapter.
func _init(event_bus: EventBus) -> void:
	assert(event_bus != null, "EventBus cannot be null")
	_event_bus = event_bus

## Connect signal to event type.
func connect_signal_to_event(source: Object, signal_name: StringName, event_type, mapper: Callable = Callable()) -> void:
	assert(source != null, "Signal source cannot be null")
	assert(not signal_name.is_empty(), "Signal name cannot be empty")
	assert(event_type != null, "Event type cannot be null")
	
	var callback = func(...args):
		var event_data: Dictionary = {}
		
		if mapper.is_valid():
			# Use custom mapper
			event_data = mapper.callv(args)
		else:
			# Default: map signal args by position
			var arg_names = ["arg0", "arg1", "arg2", "arg3", "arg4"]
			for i in range(min(args.size(), arg_names.size())):
				event_data[arg_names[i]] = args[i]
		
		# Create and emit event
		var event = event_type.new(signal_name, event_data)
		_event_bus.emit(event)
	
	# Connect signal to callback and track for cleanup
	if not _connection_tracker.connect_and_track(source, signal_name, callback, "EventSignalBridge"):
		return

## Disconnect all signals.
func disconnect_all() -> void:
	_connection_tracker.disconnect_all()

## Get connection count.
func get_connection_count() -> int:
	return _connection_tracker.get_connection_count()

## Cleanup on free.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_connection_tracker.disconnect_all()

