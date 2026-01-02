# Godot Snips

A curated collection of packages and utilities for **Godot 4.5.1+**, designed for modular game architecture and clean code practices.

## Project Structure

All packages are organized under the `packages/` directory:

```
packages/
├── messaging/    # Command/Event messaging framework
├── collection/   # Fluent array wrapper
└── utilities/    # Shared utility functions
```

Each package is self-contained with its own documentation and can be used independently.

## Packages

### Messaging

A high-performance, type-safe messaging framework that rigorously separates actions (commands) from notifications (events).

**Import:**
```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")
```

**[Documentation →](packages/messaging/README.md)**

### Collection

A fluent, object-oriented wrapper for working with arrays, inspired by Laravel's Collection class. Provides method chaining and expressive syntax for common array operations.

**Import:**
```gdscript
const Collection = preload("res://packages/collection/collection.gd")
```

**[Documentation →](packages/collection/README.md)**

## Utilities

Domain-agnostic helper utilities for common patterns.

**[Documentation →](packages/utilities/README.md)**

## Quick Start

**Using Messaging:**
```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()

# Dispatch a command
await command_bus.dispatch(MyCommand.new())

# Publish an event
event_bus.publish(MyEvent.new())
```

**Using Collection:**
```gdscript
const Collection = preload("res://packages/collection/collection.gd")

var numbers = Collection.new([1, 2, 3, 4, 5])
var evens = numbers.filter(func(n): return n % 2 == 0).array()
```

## Developer Diary

Development insights, architectural decisions, and design rationale documented over time.

**[Developer Diary →](docs/developer-diary/)**

## Requirements

- **Godot 4.5.1+** - All packages are tested and designed for Godot 4.5.1 and later versions
