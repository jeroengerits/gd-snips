# Godot Snips

Personal code snippets for **Godot 4.5.1+** game projects—reusable patterns and contracts for prototyping and gameplay development.

## Requirements

- Godot Engine **4.5.1** or later
- GDScript knowledge

## Features

This repository contains reusable code snippets and patterns for Godot projects. More features will be added over time.

### Messaging

A lightweight messaging system with concrete value objects for commands and events. All messages are immutable, reference-counted, and can be instantiated directly or extended for type safety.

### Quick Start

```gdscript
# Create messages
var cmd = Command.create("deal_damage", {"amount": 10, "target": enemy})
var evt = Event.create("damage_dealt", {"amount": 10, "target": enemy})

# Setup bus
var bus = Bus.new()
bus.register_command_handler("deal_damage", func(command: Command): print("Dealt damage"))
bus.subscribe("damage_dealt", func(event: Event): print("Damage was dealt"))

# Dispatch and publish
bus.dispatch(cmd)
bus.publish(evt)
```

### Architecture

- **`Message`** - Base class for all messages (immutable value objects)
    - **`Command`** - Requests to perform actions (typically handled by single handler)
    - **`Event`** - Notifications that something happened (typically handled by multiple subscribers)
- **`Bus`** - Message bus for dispatching commands and publishing events

### When to Use Commands vs Events

**Commands** - Imperative actions ("do this"):
- `"deal_damage"`, `"move_player"`, `"open_inventory"`
- Typically handled by one handler
- May return results
- Represent requests to perform actions

**Events** - Declarative notifications ("this happened"):
- `"damage_dealt"`, `"player_died"`, `"inventory_opened"`
- Typically handled by multiple subscribers
- No return values
- Represent state changes or occurrences

### API Reference

All message classes provide:

- `get_id() -> String` - Unique identifier
- `get_type() -> String` - Message type
- `get_description() -> String` - Optional description
- `get_data() -> Dictionary` - Message payload (returns deep copy)
- `to_string() -> String` - Debug representation
- `to_dict() -> Dictionary` - Serialization
- `equals(other: Message) -> bool` - Equality by ID
- `hash() -> int` - Hash for dictionaries/sets
- `static create(type, data, description)` - Factory method (returns Message/Command/Event based on class)

### Bus API

- `register_command_handler(type, handler)` - Register handler for command type
- `unregister_command_handler(type)` - Remove command handler
- `subscribe(type, subscriber)` - Subscribe to event type
- `unsubscribe(type, subscriber)` - Unsubscribe from event type
- `dispatch(command)` - Dispatch command to handler (returns result)
- `publish(event)` - Publish event to all subscribers
- `clear()` - Clear all handlers and subscribers

### Project Structure

```
src/
  core/
    message.gd    # Base message class
    command.gd    # Command messages
    event.gd      # Event messages
    bus.gd        # Message bus for dispatching
```

_More features coming soon..._

## Usage

Copy, modify, and adapt snippets to fit your project needs. These are personal notes and experiments—use as inspiration or starting points.

## License

Personal use—adapt as needed. 
