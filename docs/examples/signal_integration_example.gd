extends Node

## Example demonstrating signal integration with the transport system.
##
## This shows how to bridge Godot signals to transport events
## using the Bridge utility.

const Transport = preload("res://packages/transport/transport.gd")

# Example event types
class ButtonPressedEvent extends Transport.Event:
	var button_name: String
	
	func _init(name: String) -> void:
		button_name = name
		super._init("button_pressed", {"button_name": name})

class AreaEnteredEvent extends Transport.Event:
	var body_name: String
	var body_type: String
	
	func _init(body: Node2D) -> void:
		body_name = body.name
		body_type = body.get_class()
		super._init("area_entered", {"body_name": body_name, "body_type": body_type})

class EnemyDiedEvent extends Transport.Event:
	var enemy_id: int
	var points: int
	
	func _init(id: int, pts: int) -> void:
		enemy_id = id
		points = pts
		super._init("enemy_died", {"enemy_id": id, "points": pts})

var event_bus: Transport.EventBus
var signal_adapter: Transport.SignalBridge

func _ready() -> void:
	# Create event bus instance
	event_bus = Transport.EventBus.new()
	
	# Enable verbose logging
	event_bus.set_verbose(true)
	
	_setup_signal_to_event_bridge()
	_setup_event_listeners()
	
	# Run example scenarios
	await _run_examples()

## Example 1: Bridge signals to events
func _setup_signal_to_event_bridge() -> void:
	signal_adapter = Transport.SignalBridge.new(event_bus)
	
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

## Example 2: Subscribe to events (normal transport usage)
func _setup_event_listeners() -> void:
	# Subscribe to events published via signal bridge
	event_bus.on(ButtonPressedEvent, func(event):
		print("[Event Listener] Button pressed: ", event.button_name)
	)
	
	event_bus.on(AreaEnteredEvent, func(event):
		print("[Event Listener] Area entered by: ", event.body_name, " (", event.body_type, ")")
	)
	
	event_bus.on(EnemyDiedEvent, func(event):
		print("[Event Listener] Enemy died: ", event.enemy_id, " (+", event.points, " points)")
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
	
	# Emit event directly
	print("\n3. Emitting EnemyDiedEvent directly...")
	event_bus.emit(EnemyDiedEvent.new(42, 100))
	await get_tree().process_frame
	
	print("\n=== Examples Complete ===\n")

func _exit_tree() -> void:
	# Cleanup adapter
	if signal_adapter:
		signal_adapter.disconnect_all()

