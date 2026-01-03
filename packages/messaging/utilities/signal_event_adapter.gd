extends RefCounted
class_name SignalEventAdapter

## Utility for bridging Godot signals to messaging events.
##
## Connects Node signals to EventBus, automatically converting signal emissions
## into event publications. Useful for integrating UI interactions, scene tree
## events, and third-party plugins with the messaging system.
##
## Usage:
##   const Messaging = preload("res://packages/messaging/messaging.gd")
##   var adapter = SignalEventAdapter.new(event_bus)
##   adapter.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)
##
## For custom data mapping:
##   adapter.connect_signal_to_event(
##       $Area2D,
##       "body_entered",
##       AreaEnteredEvent,
##       func(body): return {"body_name": body.name}
##   )

var _event_bus: EventBus
var _connections: Array = []

## Create a new SignalEventAdapter.
##
## [code]event_bus[/code]: EventBus instance to publish events to
func _init(event_bus: EventBus) -> void:
	assert(event_bus != null, "EventBus cannot be null")
	_event_bus = event_bus

## Connect a signal to an event type.
##
## When the signal is emitted, an event of the specified type will be published
## to the EventBus. Signal arguments can be mapped to event data using the
## optional mapper callback.
##
## [code]source[/code]: Object emitting the signal (typically a Node)
## [code]signal_name[/code]: Name of the signal to connect
## [code]event_type[/code]: Event class to instantiate
## [code]mapper[/code]: Optional callback to map signal args to event data
##   If not provided, signal args are mapped by position (arg0, arg1, etc.)
##   Mapper signature: func(...args) -> Dictionary
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

## Disconnect all signal bridges.
##
## Call this when the adapter is no longer needed to prevent memory leaks.
## This is automatically called when the adapter is freed.
func disconnect_all() -> void:
	for conn in _connections:
		if is_instance_valid(conn.source):
			conn.source.disconnect(conn.signal, conn.callback)
	_connections.clear()

## Get the number of active signal connections.
func get_connection_count() -> int:
	return _connections.size()

## Internal: Cleanup connections when adapter is freed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		disconnect_all()

