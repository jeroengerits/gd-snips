extends Node

## Example usage of Commander and Publisher in gameplay code.
##
## This demonstrates:
## - Registering command handlers
## - Subscribing to events
## - Executing commands and broadcasting events
## - Using priorities, one-shot subscriptions, and lifecycle binding

const Transport = preload("res://packages/transport/transport.gd")

var command_router: Transport.Commander
var event_broadcaster: Transport.Publisher

func _ready() -> void:
	# Create router and broadcaster instances
	command_router = Transport.Commander.new()
	event_broadcaster = Transport.Publisher.new()
	
	# Enable verbose logging for this example
	command_router.set_verbose(true)
	event_broadcaster.set_verbose(true)
	
	_setup_command_handlers()
	_setup_event_listeners()
	
	# Run example scenarios
	await _run_examples()

func _setup_command_handlers() -> void:
	# Register handler for MovePlayerCommand
	command_router.register_handler(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
		print("Command handler: Moving player to ", cmd.target_position)
		# Simulate movement logic
		return true
	)

func _setup_event_listeners() -> void:
	# Subscribe to EnemyDiedEvent with different priorities
	event_broadcaster.subscribe(EnemyDiedEvent, _on_enemy_died_score, priority=10)
	event_broadcaster.subscribe(EnemyDiedEvent, _on_enemy_died_sound, priority=5)
	event_broadcaster.subscribe(EnemyDiedEvent, _on_enemy_died_cleanup, priority=0)
	
	# One-shot subscription example
	event_broadcaster.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
		print("One-shot: First enemy death detected!")
	, once=true)
	
	# Lifecycle-bound subscription (auto-unsubscribes when this node exits tree)
	event_broadcaster.subscribe(EnemyDiedEvent, _on_enemy_died_ui, owner=self)

func _on_enemy_died_score(evt: EnemyDiedEvent) -> void:
	print("Score system: Enemy ", evt.enemy_id, " died, adding ", evt.points, " points")

func _on_enemy_died_sound(evt: EnemyDiedEvent) -> void:
	print("Audio system: Playing death sound for enemy ", evt.enemy_id)

func _on_enemy_died_cleanup(evt: EnemyDiedEvent) -> void:
	print("Cleanup: Removing enemy ", evt.enemy_id, " from scene")

func _on_enemy_died_ui(evt: EnemyDiedEvent) -> void:
	print("UI: Updating enemy death counter")

func _run_examples() -> void:
	print("\n=== Command Router Example ===")
	
	# Execute a command
	var cmd = MovePlayerCommand.new(Vector2(100, 200))
	var result = await command_router.execute(cmd)
	print("Command result: ", result)
	
	print("\n=== Event Broadcaster Example ===")
	
	# Broadcast an event (multiple listeners will be called)
	var evt = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
	event_broadcaster.broadcast(evt)
	
	# Broadcast another event (one-shot listener won't fire again)
	print("\nSecond enemy death:")
	event_broadcaster.broadcast(EnemyDiedEvent.new(43, 150, Vector2(70, 80)))

