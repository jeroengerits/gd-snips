const SignalConnectionTracker = preload("res://addons/utils/signal_connection_tracker.gd")

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
##
## @param source: The object emitting the signal
## @param signal_name: Name of the signal to connect
## @param event_type: Event class (must have class_name) to create when signal fires
## @param mapper: Optional callable to map signal arguments to event data (default: auto-map by position)
## @example:
## ```gdscript
## bridge.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)
## bridge.connect_signal_to_event($Area2D, "body_entered", AreaEnteredEvent, func(body): return {"body_name": body.name})
## ```
func connect_signal_to_event(source: Object, signal_name: StringName, event_type: Variant, mapper: Callable = Callable()) -> void:
	assert(source != null, "Signal source cannot be null")
	assert(not signal_name.is_empty(), "Signal name cannot be empty")
	assert(event_type != null, "Event type cannot be null")
	
	@warning_ignore("unused_parameter")
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

