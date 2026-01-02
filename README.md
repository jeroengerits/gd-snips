# Godot Snips

Personal code snippets for **Godot 4.5.1+** game projects—reusable patterns for prototyping and gameplay development.

## Messaging System

A lightweight, type-safe messaging system with commands and events for decoupling game components.

### Quick Start

```gdscript
# Create buses (use as autoload singletons or instantiate as needed)
var command_bus = CommandBus.create()
var event_bus = EventBus.create()

# Register a command handler
command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    return player.move_to(cmd.target_position)
)

# Subscribe to events
event_bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    update_score(evt.points)
    play_sound("enemy_death")
)

# Dispatch commands and publish events
var result = await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
event_bus.publish(EnemyDiedEvent.new(enemy_id, 100))
```

### Commands vs Events

**Commands** — Imperative actions with a single handler:
- Use for: `MovePlayerCommand`, `OpenInventoryCommand`, `SaveGameCommand`
- Exactly one handler processes each command
- Return a result (or error)

**Events** — Notifications with multiple subscribers:
- Use for: `EnemyDiedEvent`, `PlayerHealthChangedEvent`, `LevelCompletedEvent`
- Zero or more listeners can subscribe
- Fire-and-forget (no return values)

### Creating Your Own Messages

**Custom Command:**
```gdscript
extends Command
class_name DealDamageCommand

var target: Node
var amount: int

func _init(target_node: Node, damage: int) -> void:
    target = target_node
    amount = damage
    super._init("deal_damage", {"target": target_node, "amount": damage})

func get_class_name() -> StringName:
    return StringName("DealDamageCommand")
```

**Custom Event:**
```gdscript
extends Event
class_name PlayerDiedEvent

var player_id: int
var cause: String

func _init(id: int, death_cause: String) -> void:
    player_id = id
    cause = death_cause
    super._init("player_died", {"player_id": id, "cause": death_cause})

func get_class_name() -> StringName:
    return StringName("PlayerDiedEvent")
```

### Usage Examples

**Command Bus - Handling Actions:**
```gdscript
# Setup (typically in _ready() or initialization)
func _ready():
    command_bus.handle(DealDamageCommand, _handle_damage)

func _handle_damage(cmd: DealDamageCommand) -> bool:
    if cmd.target.has_method("take_damage"):
        cmd.target.take_damage(cmd.amount)
        return true
    return false

# Dispatch from anywhere
var result = await command_bus.dispatch(DealDamageCommand.new(enemy, 25))
if result is CommandBus.CommandBusError:
    print("Failed to deal damage")
```

**Event Bus - Subscribing to Notifications:**
```gdscript
# Setup with priorities (higher priority listeners called first)
func _ready():
    event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_score, priority=10)
    event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_sound, priority=5)
    event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_cleanup, priority=0)

func _on_enemy_died_score(evt: EnemyDiedEvent) -> void:
    score += evt.points

func _on_enemy_died_sound(evt: EnemyDiedEvent) -> void:
    audio_player.play("enemy_death")

func _on_enemy_died_cleanup(evt: EnemyDiedEvent) -> void:
    remove_enemy_from_scene(evt.enemy_id)
```

**Advanced Features:**

```gdscript
# One-shot subscription (auto-unsubscribes after first event)
event_bus.subscribe(TutorialCompletedEvent, func(evt):
    show_celebration()
, one_shot=true)

# Lifecycle-bound subscription (auto-unsubscribes when node exits tree)
event_bus.subscribe(PlayerHealthChangedEvent, _update_health_bar, bound_object=self)

# Unsubscribe manually
event_bus.unsubscribe(EnemyDiedEvent, _on_enemy_died_score)

# Check if handler exists
if command_bus.has_handler(MovePlayerCommand):
    command_bus.dispatch(MovePlayerCommand.new(new_position))

# Async support
command_bus.handle(SaveGameCommand, func(cmd: SaveGameCommand):
    await save_game_data()
    return true
)
```

### API Reference

**CommandBus:**
- `handle(command_type, handler: Callable)` - Register handler (replaces existing)
- `dispatch(command: Command) -> Variant` - Dispatch command, returns result
- `unregister_handler(command_type)` - Remove handler
- `has_handler(command_type) -> bool` - Check if handler exists
- `get_subscription_count(command_type) -> int` - Get number of handlers (should be 0 or 1)
- `set_verbose(enabled: bool)` - Enable/disable verbose logging
- `set_tracing(enabled: bool)` - Enable/disable message delivery tracing
- `clear()` - Clear all handlers

**EventBus:**
- `subscribe(event_type, listener: Callable, priority=0, one_shot=false, bound_object=null) -> int` - Subscribe to events
- `publish(event: Event)` - Publish event (fire-and-forget)
- `publish_async(event: Event)` - Publish and await async listeners
- `unsubscribe(event_type, listener: Callable)` - Unsubscribe
- `unsubscribe_by_id(event_type, sub_id: int)` - Unsubscribe by subscription ID
- `get_listeners(event_type) -> Array` - Get all listeners for an event type
- `get_subscription_count(event_type) -> int` - Get number of listeners for an event type
- `get_registered_types() -> Array[StringName]` - Get all registered event types
- `set_collect_errors(enabled: bool)` - Enable/disable error collection for debugging
- `set_verbose(enabled: bool)` - Enable/disable verbose logging
- `set_tracing(enabled: bool)` - Enable/disable message delivery tracing
- `clear()` - Clear all subscribers

**Message Base Classes:**
- `Message`, `Command`, `Event` - Base classes for creating your own messages
- `id() -> String` - Unique message identifier
- `type() -> String` - Message type string
- `data() -> Dictionary` - Message payload (deep copy)
- `to_string() -> String` - Debug representation

### Debugging & Inspection

```gdscript
# Enable verbose logging (logs subscriptions/unsubscriptions)
command_bus.set_verbose(true)
event_bus.set_verbose(true)

# Enable tracing (logs all message deliveries)
command_bus.set_tracing(true)
event_bus.set_tracing(true)

# Check subscription counts
print("EnemyDiedEvent has ", event_bus.get_subscription_count(EnemyDiedEvent), " listeners")
print("MovePlayerCommand handler exists: ", command_bus.has_handler(MovePlayerCommand))

# Get all registered message types
var event_types = event_bus.get_registered_types()
print("Registered event types: ", event_types)

# Get all listeners for an event type
var listeners = event_bus.get_listeners(EnemyDiedEvent)
for listener in listeners:
    print("Listener: ", listener)

# Enable error collection in EventBus (for debugging listener failures)
event_bus.set_collect_errors(true)
```

### Tips

- Use commands for actions that need a response or error handling
- Use events for notifications that multiple systems care about
- Higher priority listeners are called first (useful for core systems before UI)
- Bound subscriptions automatically clean up when objects are freed
- Enable verbose logging and tracing during development for debugging
- Use `get_subscription_count()` to verify listeners are registered correctly
