extends Node
class_name EventSignalAdapter

## Utility for bridging messaging events to Godot signals.
##
## Subscribes to [EventBus] events and automatically emits signals when events
## are published. This adapter is useful for exposing messaging events to
## signal-based systems (UI, plugins, Node-based code) that expect Godot's
## native signal system.
##
## **Use Cases:**
## - Integrating messaging system with UI that uses signals
## - Exposing events to plugins that expect signals
## - Connecting messaging events to existing signal-based code
## - Creating signal-based APIs on top of messaging events
##
## **Architecture:** This adapter acts as a bridge between the messaging system
## (event-driven) and Godot's signal system (signal-driven), allowing both
## patterns to coexist in the same codebase.
##
## **Lifecycle:** This extends [Node], so it should be added to the scene tree
## or kept as a child of a Node to ensure proper lifecycle management.
##
## @example Basic usage:
##   extends Node
##   
##   signal enemy_died(enemy_id: int, points: int)
##   
##   func _ready():
##       var adapter = EventSignalAdapter.new()
##       adapter.set_event_bus(event_bus)
##       adapter.connect_event_to_signal(EnemyDiedEvent, "enemy_died")
##       add_child(adapter)
##
## @note This extends [Node] (not [RefCounted]) because it needs to emit signals
##   and manage signal connections.
##
## Usage:
##   extends Node
##   const Messaging = preload("res://packages/messaging/messaging.gd")
##   
##   # Declare signals on your Node
##   signal enemy_died(enemy_id: int, points: int)
##   
##   var adapter = Messaging.EventSignalAdapter.new()
##   adapter.set_event_bus(event_bus)
##   adapter.connect_event_to_signal(EnemyDiedEvent, "enemy_died")
##   
##   # Listen to the signal (declared on this Node)
##   enemy_died.connect(_on_enemy_died)
##
## For custom data extraction:
##   adapter.connect_event_to_signal(
##       PlayerHealthChangedEvent,
##       "health_changed",
##       func(evt): return [evt.current_health, evt.max_health]
##   )

var _event_bus: EventBus
var _subscriptions: Dictionary = {}  # event_type -> subscription_id

## Create a new EventSignalAdapter.
##
## [code]event_bus[/code]: EventBus instance to subscribe to (optional, can be set later)
func _init(event_bus: EventBus = null) -> void:
	_event_bus = event_bus

## Set the EventBus to subscribe to.
##
## [code]event_bus[/code]: EventBus instance
func set_event_bus(event_bus: EventBus) -> void:
	assert(event_bus != null, "EventBus cannot be null")
	# Unsubscribe from old bus if exists
	_unsubscribe_all()
	_event_bus = event_bus

## Connect an event type to a signal.
##
## When the event is published, the signal will be emitted with the event data.
## Signal arguments can be extracted from event data using the optional extractor.
##
## [code]event_type[/code]: Event class to subscribe to
## [code]signal_name[/code]: Name of the signal to emit (must be declared in script)
## [code]extractor[/code]: Optional callback to extract signal args from event
##   If not provided, signal is emitted with the event as first argument
##   Extractor signature: func(event: Event) -> Array
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

## Disconnect an event type from its signal.
##
## [code]event_type[/code]: Event class to unsubscribe from
func disconnect_event_from_signal(event_type) -> void:
	if not _subscriptions.has(event_type):
		return
	
	if _event_bus != null:
		_event_bus.unsubscribe_by_id(event_type, _subscriptions[event_type])
	_subscriptions.erase(event_type)

## Disconnect all event-to-signal bridges.
func disconnect_all() -> void:
	_unsubscribe_all()

## Get the number of active event subscriptions.
func get_subscription_count() -> int:
	return _subscriptions.size()

## Internal: Unsubscribe from all events.
func _unsubscribe_all() -> void:
	if _event_bus == null:
		return
	
	for event_type in _subscriptions.keys():
		_event_bus.unsubscribe_by_id(event_type, _subscriptions[event_type])
	_subscriptions.clear()

## Internal: Emit signal with variable arguments from array.
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

