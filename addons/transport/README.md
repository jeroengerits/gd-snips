# Transport

A type-safe command and event messaging framework for Godot 4.5.1+ that helps you build clean, decoupled game architectures.

## Overview

Transport provides a structured way to handle communication between different parts of your game. Instead of tightly coupling systems together, you send commands (things to do) and events (things that happened) through centralized buses.

**Who is this for?**
- Developers building medium to large Godot projects
- Teams who want clear communication patterns
- Anyone who finds Godot signals limiting for complex game logic

**What problem does it solve?**
- Decouples systems so they don't need direct references to each other
- Provides type safety at compile time
- Ensures predictable execution order
- Makes debugging easier with built-in metrics and tracing

## Features

- ✅ **Type-safe** - Compile-time type checking for commands and events
- ✅ **Commands** - Exactly one handler per command (no ambiguity)
- ✅ **Events** - Zero or more listeners (flexible broadcasting)
- ✅ **Priority-based** - Control execution order with priorities
- ✅ **Lifecycle-aware** - Automatic cleanup when objects are freed
- ✅ **Middleware** - Intercept and process messages before/after execution
- ✅ **Metrics** - Built-in performance tracking and introspection
- ✅ **Scene-tree independent** - Works with any RefCounted objects

## Installation

1. Copy the `addons/transport` directory into your Godot project's `addons/` folder
2. Open your project in Godot
3. Go to **Project → Project Settings → Plugins**
4. Enable the "Transport" plugin

**Requirements:** Godot 4.5.1 or later

## Quick Start

Here's a minimal example to get you started:

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

# Create bus instances
var command_bus = Transport.CommandBus.new()
var event_bus = Transport.EventBus.new()

# Register a command handler
command_bus.handle(MovePlayerCommand, func(command):
    player.move_to(command.target_position)
    return true
)

# Subscribe to an event
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy ", event.enemy_id, " died!")
)

# Use them
await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
```

## Core Concepts

### Commands

Commands represent actions that need to happen. Think: **"Do this."**

- **One handler only** - Each command type has exactly one handler
- **Returns a result** - Handlers can return data or errors
- **Clear ownership** - No ambiguity about who handles what

**Good for:** Moving the player, saving the game, applying damage, etc.

### Events

Events announce that something happened. Think: **"This happened."**

- **Zero or more listeners** - No listeners? Fine. Many listeners? Also fine.
- **Priority-based** - Higher priority listeners run first
- **Sequential execution** - Each listener completes before the next starts

**Good for:** Enemy died, player health changed, level completed, etc.

## Usage Guide

### Creating Commands

Commands must extend `Transport.Command`:

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

extends Transport.Command
class_name MovePlayerCommand

var target_position: Vector2
var player_id: int = 0

func _init(pos: Vector2, player: int = 0) -> void:
    target_position = pos
    player_id = player
    super._init("move_player", {"target_position": pos, "player_id": player}, "Move player to position")
```

### Creating Events

Events must extend `Transport.Event`:

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

extends Transport.Event
class_name EnemyDiedEvent

var enemy_id: int
var points: int
var position: Vector2

func _init(e_id: int, pts: int, pos: Vector2 = Vector2.ZERO) -> void:
    enemy_id = e_id
    points = pts
    position = pos
    super._init("enemy_died", {"enemy_id": e_id, "points": pts, "position": pos}, "Enemy %d died" % e_id)
```

### CommandBus

The `CommandBus` ensures exactly one handler processes each command.

**Register a handler:**
```gdscript
command_bus.handle(MovePlayerCommand, func(command):
    player.move_to(command.target_position)
    return true
)
```

**Dispatch a command:**
```gdscript
var result = await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))

# Check for errors
if result is Transport.CommandRoutingError:
    print("Command failed: ", result.message)
else:
    print("Command succeeded: ", result)
```

**Error types:**
- `NO_HANDLER` - No handler registered for this command
- `MULTIPLE_HANDLERS` - Multiple handlers registered (shouldn't happen)
- `HANDLER_FAILED` - Handler execution failed or was cancelled

### EventBus

The `EventBus` broadcasts events to all subscribers.

**Subscribe to events:**
```gdscript
# Basic subscription
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy died: ", event.enemy_id)
)

# With priority (higher numbers run first)
event_bus.on(EnemyDiedEvent, _handle_enemy_died, priority=10)

# One-shot (auto-unsubscribes after first call)
event_bus.on(EnemyDiedEvent, _on_first_enemy_death, once=true)

# Lifecycle-bound (auto-unsubscribes when owner is freed)
event_bus.on(EnemyDiedEvent, _update_ui, owner=self)
```

**Emit events:**
```gdscript
# Fire and forget
event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))

# Or await all async listeners
await event_bus.emit_and_await(event)
```

**Unsubscribe:**
```gdscript
# By callable
event_bus.unsubscribe(EnemyDiedEvent, _my_listener)

# By subscription ID (for anonymous functions)
var sub_id = event_bus.on(EnemyDiedEvent, func(event): print("Event!"))
event_bus.unsubscribe_by_id(EnemyDiedEvent, sub_id)
```

### Middleware

Middleware lets you intercept messages before and after they're processed. Useful for logging, validation, timing, and other cross-cutting concerns.

**Using callables:**
```gdscript
# Before-execution middleware (can cancel by returning false)
command_bus.add_middleware_before(func(cmd: Command):
    print("Before: ", cmd)
    return true  # Return false to cancel
, priority=0)

# After-execution middleware
command_bus.add_middleware_after(func(cmd: Command, result):
    print("After: ", result)
, priority=0)

# Remove middleware
var mw_id = command_bus.add_middleware_before(my_callback)
command_bus.remove_middleware(mw_id)
```

**Using the Middleware class:**
```gdscript
const Transport = preload("res://addons/transport/transport.gd")

class LoggingMiddleware extends Transport.Middleware:
    func process_before(message: Transport.Message, message_key: StringName) -> bool:
        print("[Middleware] Before: ", message_key, " - ", message)
        return true
    
    func process_after(message: Transport.Message, message_key: StringName, result: Variant) -> void:
        print("[Middleware] After: ", message_key, " - Result: ", result)

# Use it
var logging_mw = LoggingMiddleware.new(priority=10)
command_bus.add_middleware_before(logging_mw.as_before_callable(), logging_mw.priority)
command_bus.add_middleware_after(logging_mw.as_after_callable(), logging_mw.priority)
```

### Metrics

Track performance and usage patterns:

```gdscript
# Enable metrics
command_bus.set_metrics_enabled(true)
event_bus.set_metrics_enabled(true)

# Get metrics for a specific type
var metrics = command_bus.get_metrics(MovePlayerCommand)
# Returns: {
#   "count": 42,
#   "total_time": 123.4,
#   "min_time": 0.5,
#   "max_time": 5.2,
#   "avg_time": 2.94
# }

# Get all metrics
var all_metrics = command_bus.get_all_metrics()
```

## Signal Integration

Transport is designed as an alternative to Godot signals, but you can bridge between them when needed.

**When to use Transport:**
- Business logic and domain events
- Cross-system communication
- Commands that need exactly one handler
- Situations requiring priority ordering or middleware

**When to use signals:**
- UI interactions (button clicks, input)
- Scene tree lifecycle events
- Godot's built-in events (`area_entered`, `body_entered`, etc.)
- Third-party plugin integrations

**Bridging signals to Transport:**
```gdscript
const Transport = preload("res://addons/transport/transport.gd")

# Event bridge
var event_bus = Transport.EventBus.new()
var bridge = Transport.EventSignalBridge.new(event_bus)
bridge.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Command bridge
var command_bus = Transport.CommandBus.new()
var cmd_bridge = Transport.CommandSignalBridge.new(command_bus)
cmd_bridge.connect_signal_to_command(
    $SaveButton,
    "pressed",
    SaveGameCommand,
    func(): return SaveGameCommand.new()
)

# Clean up (happens automatically when bridge is freed)
bridge.disconnect_all()
```

## Best Practices

### Command Design
- Use commands for actions that need to happen
- Keep handlers focused on one responsibility
- Return meaningful results
- Handle errors gracefully

### Event Design
- Use events for notifications about things that already happened
- Keep listeners small and focused
- Avoid side effects in listeners
- Consider priority when order matters

### Subscription Management
- Use `owner=self` for automatic cleanup
- Explicitly unsubscribe for long-lived objects
- Watch for memory leaks if not using lifecycle binding

### Development & Debugging
- Enable metrics in development
- Use middleware for logging during development
- Monitor performance in production
- Use trace logging to understand execution flow

## Architecture

**Command Flow:**
```
Input → CommandBus → Validation → Single Handler → Result/Error
```

**Event Flow:**
```
Emit → EventBus → Middleware → Listeners (priority order) → Done
```

**Key Components:**
- `CommandBus` - Dispatches commands with single-handler guarantee
- `EventBus` - Broadcasts events to zero or more subscribers
- `Middleware` - Intercepts messages before/after processing
- `CommandSignalBridge` / `EventSignalBridge` - Bridge Godot signals to Transport

## Design Principles

- **Explicitness over "magic"** - Clear, explicit APIs over hidden behavior
- **Deterministic behavior** - Predictable execution order
- **Debuggability first** - Metrics, tracing, and clear error messages
- **Type safety** - Leverage Godot's type system for compile-time checks

## Contributing

Contributions are welcome! Here's how you can help:

- **Report bugs** - Open an issue if you find a bug
- **Suggest features** - Share your ideas for improvements
- **Submit pull requests** - Code contributions are appreciated
- **Improve documentation** - Help make the docs clearer

When contributing:
- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Be respectful and constructive in discussions

## License

[Add license information here]

---

**Need help?** Open an issue on GitHub or check the [developer documentation](../CLAUDE.md).
