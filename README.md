# Godot Snips

Personal code snippets for **Godot 4.5.1+** game projects—reusable patterns for prototyping and gameplay development.

## Requirements

- Godot Engine **4.5.1** or later
- GDScript knowledge

## Messaging System

A lightweight messaging system with commands and events. All messages are immutable value objects that can be extended for type safety.

### Quick Start

```gdscript
# Create command and event buses
var command_bus = CommandBus.create()
var event_bus = EventBus.create()

# Register a command handler (using typed command classes)
command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    return player.move_to(cmd.target_position)
)

# Subscribe to events
event_bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    update_score(evt.points)
)

# Dispatch commands and publish events
var cmd = MovePlayerCommand.new(Vector2(100, 200))
var result = await command_bus.dispatch(cmd)

var evt = EnemyDiedEvent.new(enemy_id, 100)
event_bus.publish(evt)
```

### Commands vs Events

**Commands** — requests to perform actions (typically handled by one handler):
- `"deal_damage"`, `"move_player"`, `"open_inventory"`
- May return results

**Events** — notifications that something happened (typically handled by multiple subscribers):
- `"damage_dealt"`, `"player_died"`, `"inventory_opened"`
- No return values

### API

**Message classes** (`Message`, `Command`, `Event`):
- `id() -> String` - Unique identifier
- `type() -> String` - Message type
- `description() -> String` - Optional description
- `data() -> Dictionary` - Message payload (returns deep copy)
- `to_string() -> String` - Debug representation
- `to_dict() -> Dictionary` - Serialization
- `equals(other: Message) -> bool` - Equality by ID
- `static create(type, data, desc)` - Factory method

**CommandBus class**:
- `handle(command_type, handler)` - Register command handler (replaces existing)
- `unregister_handler(command_type)` - Remove command handler
- `dispatch(command)` - Dispatch command (returns result, supports async)
- `has_handler(command_type)` - Check if handler exists
- `clear()` - Clear all handlers
- `static create()` - Factory method

**EventBus class**:
- `subscribe(event_type, listener, priority, one_shot, bound_object)` - Subscribe to event type
- `unsubscribe(event_type, listener)` - Unsubscribe from event type
- `unsubscribe_by_id(event_type, sub_id)` - Unsubscribe by subscription ID
- `publish(event)` - Publish event to all subscribers (fire-and-forget)
- `publish_async(event)` - Publish event and await async listeners
- `get_listeners(event_type)` - Get all listeners for an event type
- `clear()` - Clear all subscribers
- `static create()` - Factory method

### Project Structure

```
src/core/
  message.gd       # Base message class
  command.gd       # Command messages
  event.gd         # Event messages
  message_bus.gd   # Base message bus class
  command_bus.gd   # Command bus (extends MessageBus)
  event_bus.gd     # Event bus (extends MessageBus)
```

## Usage

Copy, modify, and adapt snippets to fit your project needs. These are personal notes and experiments—use as inspiration or starting points.

## License

Personal use—adapt as needed.
