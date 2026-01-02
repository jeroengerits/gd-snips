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

# Register a command handler
command_bus.handle("deal_damage", func(cmd: Command):
    print("Dealt ", cmd.data()["amount"], " damage")
)

# Subscribe to events
event_bus.on("damage_dealt", func(evt: Event):
    print("Damage was dealt: ", evt.description())
)

# Send commands and emit events
var cmd = Command.create("deal_damage", {"amount": 10})
var evt = Event.create("damage_dealt", {"amount": 10}, "Player took damage")

command_bus.send(cmd)
event_bus.emit(evt)
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
- `handle(type, fn)` - Register command handler
- `unregister_handler(type)` - Remove command handler
- `send(cmd)` - Dispatch command (returns result)
- `clear()` - Clear all handlers
- `static create()` - Factory method

**EventBus class**:
- `on(type, fn)` - Subscribe to event type
- `off(type, fn)` - Unsubscribe from event type
- `emit(evt)` - Publish event to all subscribers
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
