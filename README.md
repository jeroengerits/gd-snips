# Godot Snips

Personal code snippets for **Godot 4.5.1+** game projects—reusable patterns and contracts for prototyping and gameplay development.

## Requirements

- Godot Engine **4.5.1** or later
- GDScript knowledge

## Features

This repository contains reusable code snippets and patterns for Godot projects. More features will be added over time.

### Message Bus System

A lightweight messaging system with concrete value objects for commands and events. All messages are immutable, reference-counted, and can be instantiated directly or extended for type safety.

### Quick Start

```gdscript
# Commands
var cmd = Command.create("deal_damage", {"amount": 10, "target": enemy})

# Events
var evt = Event.create("damage_dealt", {"amount": 10, "target": enemy})
```

### Architecture

- **`Message`** - Base class for all messages (immutable value objects)
- **`Command`** - Requests to perform actions (typically handled by single handler)
- **`Event`** - Notifications that something happened (typically handled by multiple subscribers)

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

### Project Structure

```
src/
  core/
    message.gd    # Base message class
    command.gd    # Command messages
    event.gd      # Event messages
```

_More features coming soon..._

## Usage

Copy, modify, and adapt snippets to fit your project needs. These are personal notes and experiments—use as inspiration or starting points.

## License

Personal use—adapt as needed. 
