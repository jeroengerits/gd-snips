extends Node

## Example demonstrating signal integration with the messaging system.
##
## This shows how to bridge Godot signals to messaging events
## using the SignalEventAdapter utility.

const Messaging = preload("res://packages/messaging/messaging.gd")

# Example event types
class ButtonPressedEvent extends Messaging.Event:
	var button_name: String
	
	func _init(name: String) -> void:
		button_name = name
		super._init("button_pressed", {"button_name": name})

class AreaEnteredEvent extends Messaging.Event:
	var body_name: String
	var body_type: String
	
	func _init(body: Node2D) -> void:
		body_name = body.name
		body_type = body.get_class()
		super._init("area_entered", {"body_name": body_name, "body_type": body_type})

class EnemyDiedEvent extends Messaging.Event:
	var enemy_id: int
	var points: int
	
	func _init(id: int, pts: int) -> void:
		enemy_id = id
		points = pts
		super._init("enemy_died", {"enemy_id": id, "points": pts})

var event_broadcaster: Messaging.EventBroadcaster
var signal_adapter: Messaging.SignalEventAdapter

func _ready() -> void:
	# Create bus instance
	event_broadcaster = Messaging.EventBroadcaster.new()
	
	# Enable verbose logging
	event_broadcaster.set_verbose(true)
	
	_setup_signal_to_event_bridge()
	_setup_event_listeners()
	
	# Run example scenarios
	await _run_examples()

## Example 1: Bridge signals to events
func _setup_signal_to_event_bridge() -> void:
	signal_adapter = Messaging.SignalEventAdapter.new(event_broadcaster)
	
	# Simple signal → event bridge
	# When button is pressed, ButtonPressedEvent is published
	if has_node("Button"):
		signal_adapter.connect_signal_to_event(
			$Button,
			"pressed",
			ButtonPressedEvent,
			func(): return {"button_name": $Button.name}
		)
	
	# Custom data mapping for area signals
	# When body enters area, AreaEnteredEvent is published with body info
	if has_node("Area2D"):
		signal_adapter.connect_signal_to_event(
			$Area2D,
			"body_entered",
			AreaEnteredEvent,
			func(body: Node2D): return {"body_name": body.name, "body_type": body.get_class()}
		)

## Example 2: Subscribe to events (normal messaging usage)
func _setup_event_listeners() -> void:
	# Subscribe to events published via signal bridge
	event_broadcaster.subscribe(ButtonPressedEvent, func(evt: ButtonPressedEvent):
		print("[Event Listener] Button pressed: ", evt.button_name)
	)
	
	event_broadcaster.subscribe(AreaEnteredEvent, func(evt: AreaEnteredEvent):
		print("[Event Listener] Area entered by: ", evt.body_name, " (", evt.body_type, ")")
	)
	
	event_broadcaster.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
		print("[Event Listener] Enemy died: ", evt.enemy_id, " (+", evt.points, " points)")
	)

## Run example scenarios
func _run_examples() -> void:
	print("\n=== Signal Integration Examples ===\n")
	
	# Simulate button press (triggers signal → event)
	if has_node("Button"):
		print("1. Simulating button press...")
		$Button.pressed.emit()
		await get_tree().process_frame
	
	# Simulate area entry
	if has_node("Area2D"):
		print("\n2. Simulating area entry...")
		var test_body = Node2D.new()
		test_body.name = "TestPlayer"
		$Area2D.body_entered.emit(test_body)
		await get_tree().process_frame
		test_body.queue_free()
	
	# Publish event directly
	print("\n3. Publishing EnemyDiedEvent directly...")
	event_broadcaster.broadcast(EnemyDiedEvent.new(42, 100))
	await get_tree().process_frame
	
	print("\n=== Examples Complete ===\n")

func _exit_tree() -> void:
	# Cleanup adapter
	if signal_adapter:
		signal_adapter.disconnect_all()

