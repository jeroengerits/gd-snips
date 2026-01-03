# Godot Transport System

A simple, type-safe messaging framework for Godot 4.5.1+ that helps you build modular game architectures with clear communication patterns, predictable execution order, and powerful debugging tools.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
  - [Commands](#commands)
  - [Events](#events)
- [Usage Guide](#usage-guide)
  - [Creating Commands](#creating-commands)
  - [Creating Events](#creating-events)
  - [Commander](#commander)
  - [Publisher](#publisher)
  - [Middleware](#middleware)
  - [Metrics](#metrics)
- [Signal Integration](#signal-integration)
- [Architecture](#architecture)
- [Best Practices](#best-practices)
- [Design Principles](#design-principles)

## Features

✅ **Type-safe transport** - Compile-time type checking for commands and events  
✅ **Explicit commands** - Guaranteed exactly one handler per command  
✅ **Broadcast events** - Zero or more listeners, no assumptions  
✅ **Deterministic execution** - Priority-based, sequential processing  
✅ **Lifecycle-aware** - Automatic subscription cleanup  
✅ **Middleware support** - Pre/post-processing hooks  
✅ **Metrics & tracing** - Built-in introspection tools  
✅ **Scene-tree independent** - Works with RefCounted objects  

## Installation

Copy the `packages/transport` directory into your Godot project.

**Requirements:** Godot 4.5.1 or later

## Quick Start

Here's everything you need to get started in 30 seconds:

```gdscript
const Transport = preload("res://packages/transport/transport.gd")

# Create your commander and publisher instances
var commander = Transport.Commander.new()
var publisher = Transport.Publisher.new()

# Register a command handler (one handler per command type)
commander.register_handler(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    print("Moving player to ", cmd.target_position)
    return true
)

# Subscribe to events (zero or more listeners per event type)
publisher.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    print("Enemy ", evt.enemy_id, " died!")
)

# Execute a command (returns result or error)
await commander.execute(MovePlayerCommand.new(Vector2(100, 200)))

# Broadcast an event (notifies all subscribers)
publisher.broadcast(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
```

That's it! You're ready to build a clean, decoupled architecture.

## Core Concepts

### Commands

Commands are requests that need to be handled by exactly one handler. Think of them as instructions: **"Do this."**

**Key characteristics:**
- **One handler only** - If there's no handler or multiple handlers, you get an error
- **Returns a result** - The handler can return data or propagate errors
- **Clear ownership** - There's no ambiguity about who handles what

**Perfect for:**
- `MovePlayerCommand` - Move the player to a specific position
- `SaveGameCommand` - Save the current game state
- `DealDamageCommand` - Apply damage to a target entity

### Events

Events announce that something has already happened in your game. Think of them as notifications: **"This happened."**

**Key characteristics:**
- **Zero or more listeners** - No one listening? That's fine. Ten listeners? Also fine.
- **Priority-based ordering** - Listeners run in priority order (higher first)
- **Sequential execution** - Each listener completes before the next starts (async listeners are awaited)

**Perfect for:**
- `EnemyDiedEvent` - An enemy was defeated
- `PlayerHealthChangedEvent` - Player's health changed
- `LevelCompletedEvent` - The level was completed

## Usage Guide

### Creating Commands

Commands must extend `Transport.Command`:

```gdscript
const Transport = preload("res://packages/transport/transport.gd")

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
const Transport = preload("res://packages/transport/transport.gd")

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

### Commander

The `Commander` handles command execution. It ensures exactly one handler processes each command.

#### Registering Handlers

```gdscript
# Register a handler for a command type
commander.register_handler(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    # Handle the command
    player.move_to(cmd.target_position)
    return true
)
```

**Note:** If you register a handler for a command type that already has one, the old handler is replaced. This prevents accidental duplicate handlers.

#### Executing Commands

```gdscript
# Execute a command (returns result or CommandRoutingError)
var cmd = MovePlayerCommand.new(Vector2(100, 200))
var result = await commander.execute(cmd)

# Check for errors
if result is Commander.CommandRoutingError:
    print("Command failed: ", result.message)
else:
    print("Command succeeded: ", result)
```

#### Error Handling

Commands return `Commander.CommandRoutingError` when something goes wrong:
- `NO_HANDLER` - No handler registered for this command type
- `MULTIPLE_HANDLERS` - Multiple handlers registered (should never happen, but we check)
- `HANDLER_FAILED` - Handler execution failed or was cancelled by middleware

### Publisher

The `Publisher` handles event broadcasting. It notifies all subscribers when an event occurs.

#### Subscribing to Events

```gdscript
# Basic subscription
publisher.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    print("Enemy died: ", evt.enemy_id)
)

# With priority (higher numbers run first)
publisher.subscribe(EnemyDiedEvent, _handle_enemy_died, priority=10)

# One-shot subscription (automatically unsubscribes after first call)
publisher.subscribe(EnemyDiedEvent, _on_first_enemy_death, once=true)

# Lifecycle-bound subscription (auto-unsubscribes when owner is freed)
publisher.subscribe(EnemyDiedEvent, _update_ui, owner=self)
```

**Priority ordering:** Listeners with higher priority values execute first. If two listeners have the same priority, they execute in registration order.

#### Broadcasting Events

```gdscript
# Broadcast an event (listeners execute sequentially)
var evt = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
publisher.broadcast(evt)

# Or await all async listeners to complete
await publisher.broadcast_and_await(evt)
```

**Note:** Even though `broadcast()` doesn't return a value, it still awaits async listeners to prevent memory leaks. This means it may briefly block, but it's necessary for proper cleanup.

#### Unsubscribing

```gdscript
# Unsubscribe by callable
publisher.unsubscribe(EnemyDiedEvent, _my_listener)

# Unsubscribe by subscription ID (useful for anonymous functions)
var sub_id = publisher.subscribe(EnemyDiedEvent, func(evt): print("Event!"))
publisher.unsubscribe_by_id(EnemyDiedEvent, sub_id)
```

### Middleware

Middleware lets you intercept and process messages before and after they reach their handlers or listeners. Perfect for logging, validation, timing, and other cross-cutting concerns.

```gdscript
# Pre-processing middleware (runs before handlers/listeners)
# Can cancel delivery by returning false
commander.add_middleware_pre(func(cmd: Command):
    print("Pre-processing: ", cmd)
    return true  # Return false to cancel delivery
, priority=0)

# Post-processing middleware (runs after handlers/listeners)
# Receives the message and the result
commander.add_middleware_post(func(cmd: Command, result):
    print("Post-processing result: ", result)
, priority=0)

# Remove middleware when you're done
var middleware_id = commander.add_middleware_pre(my_callback)
commander.remove_middleware(middleware_id)
```

**Use cases:**
- Logging all commands/events
- Performance timing
- Validation and authorization
- Error handling and recovery

### Metrics

Track performance and usage patterns with built-in metrics:

```gdscript
# Enable metrics tracking
commander.set_metrics_enabled(true)
publisher.set_metrics_enabled(true)

# Get metrics for a specific command/event type
var cmd_metrics = commander.get_metrics(MovePlayerCommand)
# Returns: {
#   "count": 42,
#   "total_time": 123.4,
#   "min_time": 0.5,
#   "max_time": 5.2,
#   "avg_time": 2.94
# }

# Get all metrics at once
var all_metrics = commander.get_all_metrics()
```

**Metrics include:**
- `count` - How many times this type was processed
- `total_time` - Total time spent (in seconds)
- `min_time` - Fastest execution time
- `max_time` - Slowest execution time
- `avg_time` - Average execution time

## Signal Integration

The transport system is designed as an alternative to Godot signals, but sometimes you need to bridge between them. The `Bridge` utility makes this easy.

### When You Need Bridging

- **UI interactions** - Button clicks, input events from Godot's UI system
- **Scene tree events** - `area_entered`, `body_entered`, and other built-in signals
- **Third-party plugins** - Libraries that emit signals you can't control
- **Legacy code** - Gradually migrating from signals to transport

### Using the Bridge

```gdscript
const Transport = preload("res://packages/transport/transport.gd")

var publisher = Transport.Publisher.new()
var bridge = Transport.Bridge.new(publisher)

# Simple bridge: button press → event
bridge.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Custom data mapping: extract what you need from signal args
bridge.connect_signal_to_event(
    $Area2D,
    "body_entered",
    AreaEnteredEvent,
    func(body): return {"body_name": body.name, "body_type": body.get_class()}
)

# Clean up when done (automatically happens when bridge is freed)
bridge.disconnect_all()
```

The bridge automatically cleans up connections when it's freed, so you don't need to worry about memory leaks.

### When to Use What

**Use transport for:**
- Business logic and domain events
- Cross-system communication
- Commands that need exactly one handler
- Situations requiring priority ordering or middleware

**Use signals for:**
- UI interactions (button clicks, input)
- Scene tree lifecycle events
- Godot's built-in events (`area_entered`, `body_entered`, etc.)
- Third-party plugin integrations

**Use Bridge when:**
- Migrating gradually from signals to transport
- Integrating legacy signal-based code
- Connecting UI signals to your game logic

## Architecture

### How It Works

**Command Flow:**
```
Input → Commander → Validation → Single Handler → Result/Error
```

Commands are validated to ensure exactly one handler exists, then executed. The result (or error) is returned to the caller.

**Event Flow:**
```
Broadcast → Publisher → Middleware → Listeners (priority order) → Done
```

Events are broadcast to all subscribers in priority order. Each listener completes before the next starts, ensuring predictable execution.

### Component Overview

- **Commander** - Executes commands with a single-handler guarantee
- **Publisher** - Broadcasts events to zero or more subscribers
- **Message** - Base class for all messages (commands and events extend this)
- **Command** - Base class for commands
- **Event** - Base class for events
- **Bridge** - Connects Godot signals to the transport system
- **SubscriptionRegistry** - Internal implementation (you don't use this directly)

## Best Practices

### Command Design

- **Use commands for actions** - Things that need to happen, not things that already happened
- **Keep handlers focused** - One handler, one responsibility
- **Return meaningful results** - Make it clear whether the command succeeded or failed
- **Handle errors gracefully** - Check for `CommandRoutingError` and handle appropriately

### Event Design

- **Use events for notifications** - Things that already happened that others might care about
- **Keep listeners small** - Each listener should do one thing well
- **Avoid side effects** - Listeners shouldn't modify shared state in unpredictable ways
- **Think about priority** - Order matters. Higher priority listeners run first.

### Subscription Management

- **Use lifecycle binding** - Pass `owner=self` for automatic cleanup when objects are freed
- **Unsubscribe explicitly** - For long-lived objects, explicitly unsubscribe when done
- **Watch for leaks** - If you're not using lifecycle binding, make sure you clean up

### Development & Debugging

- **Enable metrics in development** - See what's slow, what's called frequently
- **Use middleware for logging** - Log all commands/events during development
- **Monitor in production** - Keep metrics enabled to catch performance issues
- **Use tracing** - Enable trace logging to see the execution flow

## Design Principles

This framework is built on a few core principles:

- **Explicitness over "magic"** - We prefer clear, explicit APIs over hidden behavior. You should always know what's happening.
- **Deterministic behavior** - Execution order is predictable. Higher priority always runs first. No surprises.
- **Debuggability first** - We optimize for transparency and maintainability. Metrics, tracing, and clear error messages help you understand what's happening.
- **Type safety** - We leverage Godot's type system for compile-time checks. If it compiles, it's probably correct.

These principles guide every design decision. If something feels magical or unpredictable, we've probably made a mistake.
