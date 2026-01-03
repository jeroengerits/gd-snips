extends RefCounted
class_name SignalEventAdapter

## Bridges Godot signals to EventBus events.

var _event_bus: EventBus
var _connections: Array = []

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
		
		# Create and publish event
		var event = event_type.new(signal_name, event_data)
		_event_bus.publish(event)
	
	# Connect signal to callback
	if not source.connect(signal_name, callback):
		push_error("[SignalEventAdapter] Failed to connect signal: %s" % signal_name)
		return
	
	# Store connection for cleanup
	_connections.append({
		"source": source,
		"signal": signal_name,
		"callback": callback
	})

## Disconnect all signals.
func disconnect_all() -> void:
	for conn in _connections:
		if is_instance_valid(conn.source):
			conn.source.disconnect(conn.signal, conn.callback)
	_connections.clear()

## Get connection count.
func get_connection_count() -> int:
	return _connections.size()

## Cleanup on free.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		disconnect_all()

