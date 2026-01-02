extends Node

## Example usage of CommandBus and EventBus in gameplay code.
##
## This demonstrates:
## - Registering command handlers
## - Subscribing to events
## - Dispatching commands and publishing events
## - Using priorities, one-shot subscriptions, and lifecycle binding

var command_bus: CommandBus
var event_bus: EventBus

func _ready() -> void:
	# Create bus instances
	command_bus = CommandBus.create()
	event_bus = EventBus.create()
	
	# Enable verbose logging for this example
	command_bus.set_verbose(true)
	event_bus.set_verbose(true)
	
	_setup_command_handlers()
	_setup_event_listeners()
	
	# Run example scenarios
	await _run_examples()

func _setup_command_handlers() -> void:
	# Register handler for MovePlayerCommand
	command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
		print("Command handler: Moving player to ", cmd.target_position)
		# Simulate movement logic
		return true
	)

func _setup_event_listeners() -> void:
	# Subscribe to EnemyDiedEvent with different priorities
	event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_score, priority=10)
	event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_sound, priority=5)
	event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_cleanup, priority=0)
	
	# One-shot subscription example
	event_bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
		print("One-shot: First enemy death detected!")
	, one_shot=true)
	
	# Lifecycle-bound subscription (auto-unsubscribes when this node exits tree)
	event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_ui, bound_object=self)

func _on_enemy_died_score(evt: EnemyDiedEvent) -> void:
	print("Score system: Enemy ", evt.enemy_id, " died, adding ", evt.points, " points")

func _on_enemy_died_sound(evt: EnemyDiedEvent) -> void:
	print("Audio system: Playing death sound for enemy ", evt.enemy_id)

func _on_enemy_died_cleanup(evt: EnemyDiedEvent) -> void:
	print("Cleanup: Removing enemy ", evt.enemy_id, " from scene")

func _on_enemy_died_ui(evt: EnemyDiedEvent) -> void:
	print("UI: Updating enemy death counter")

func _run_examples() -> void:
	print("\n=== Command Bus Example ===")
	
	# Dispatch a command
	var cmd = MovePlayerCommand.new(Vector2(100, 200))
	var result = await command_bus.dispatch(cmd)
	print("Command result: ", result)
	
	print("\n=== Event Bus Example ===")
	
	# Publish an event (multiple listeners will be called)
	var evt = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
	event_bus.publish(evt)
	
	# Publish another event (one-shot listener won't fire again)
	print("\nSecond enemy death:")
	event_bus.publish(EnemyDiedEvent.new(43, 150, Vector2(70, 80)))
	
	print("\n=== Subscription Info ===")
	var listeners = event_bus.get_listeners(EnemyDiedEvent)
	print("EnemyDiedEvent has ", listeners.size(), " active listener(s)")

