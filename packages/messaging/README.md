# Godot Messaging System

A simple and type-safe messaging framework for Godot 4.5.1+ designed to support modular game architecture, precise execution order, and debugging tools.

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
  - [Command Bus](#command-bus)
  - [Event Bus](#event-bus)
  - [Middleware](#middleware)
  - [Metrics](#metrics)
- [Signal Integration](#signal-integration)
- [Architecture](#architecture)
- [Best Practices](#best-practices)
- [Design Principles](#design-principles)

## Features

✅ **Type-safe messaging** - Compile-time type checking for commands and events  
✅ **Explicit commands** - Guaranteed exactly one handler per command  
✅ **Broadcast events** - Zero or more listeners, no assumptions  
✅ **Deterministic execution** - Priority-based, sequential processing  
✅ **Lifecycle-aware** - Automatic subscription cleanup  
✅ **Middleware support** - Pre/post-processing hooks  
✅ **Metrics & tracing** - Built-in introspection tools  
✅ **Scene-tree independent** - Works with RefCounted objects  

## Installation

Copy the `packages/messaging` directory into your Godot project.

**Requirements:** Godot 4.5.1 or later

## Quick Start

```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

# Create bus instances
var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()

# Register a command handler
command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    print("Moving player to ", cmd.target_position)
    return true
)

# Subscribe to events
event_bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    print("Enemy ", evt.enemy_id, " died!")
)

# Dispatch commands
await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))

# Publish events
event_bus.publish(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
```

## Core Concepts

### Commands

Commands represent requests that expect a single authoritative handler. Think: **"Do this."**

**Characteristics:**
- Exactly one handler (errors if ambiguous or unhandled)
- Returns a result or propagates an error
- Clear boundaries and responsibility

**Use cases:**
- `MovePlayerCommand` - Move the player to a position
- `SaveGameCommand` - Save game state
- `DealDamageCommand` - Apply damage to a target

### Events

Events signal that something has already occurred in the game domain. Think: **"This happened."**

**Characteristics:**
- Any number of listeners (including zero)
- Ordered by priority, processed sequentially
- No return value (listeners execute sequentially, async listeners are awaited)

**Use cases:**
- `EnemyDiedEvent` - Enemy was defeated
- `PlayerHealthChangedEvent` - Player health changed
- `LevelCompletedEvent` - Level was completed

## Usage Guide

### Creating Commands

Commands must extend `Messaging.Command`:

```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

extends Messaging.Command
class_name MovePlayerCommand

var target_position: Vector2
var player_id: int = 0

func _init(pos: Vector2, player: int = 0) -> void:
    target_position = pos
    player_id = player
    super._init("move_player", {"target_position": pos, "player_id": player}, "Move player to position")
```

### Creating Events

Events must extend `Messaging.Event`:

```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

extends Messaging.Event
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

### Command Bus

#### Registering Handlers

```gdscript
# Register a handler for a command type
command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    # Handle the command
    player.move_to(cmd.target_position)
    return true
)
```

#### Dispatching Commands

```gdscript
# Dispatch a command (returns result or throws CommandError)
var cmd = MovePlayerCommand.new(Vector2(100, 200))
var result = await command_bus.dispatch(cmd)
```

#### Error Handling

Commands can throw `CommandBus.CommandError`:
- `NO_HANDLER` - No handler registered for command type
- `MULTIPLE_HANDLERS` - Multiple handlers registered (invalid state)
- `HANDLER_FAILED` - Handler execution failed

### Event Bus

#### Subscribing to Events

```gdscript
# Basic subscription
event_bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    print("Enemy died: ", evt.enemy_id)
)

# With priority (higher = executed first)
event_bus.subscribe(EnemyDiedEvent, _handle_enemy_died, priority=10)

# One-shot subscription (automatically unsubscribes after first call)
event_bus.subscribe(EnemyDiedEvent, _on_first_enemy_death, one_shot=true)

# Lifecycle-bound subscription (auto-unsubscribes when object exits tree)
event_bus.subscribe(EnemyDiedEvent, _update_ui, bound_object=self)
```

#### Publishing Events

```gdscript
# Publish an event (non-blocking, listeners execute sequentially)
var evt = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
event_bus.publish(evt)
```

#### Unsubscribing

```gdscript
# Unsubscribe by callable
event_bus.unsubscribe(EnemyDiedEvent, _my_listener)

# Unsubscribe by subscription ID
var sub_id = event_bus.subscribe(EnemyDiedEvent, _my_listener)
event_bus.unsubscribe_by_id(EnemyDiedEvent, sub_id)
```

### Middleware

Middleware allows pre and post-processing of messages:

```gdscript
# Pre-processing middleware (runs before handlers/listeners)
command_bus.add_middleware_pre(func(cmd: Command):
    print("Pre-processing: ", cmd)
, priority=0)

# Post-processing middleware (runs after handlers/listeners)
command_bus.add_middleware_post(func(cmd: Command, result):
    print("Post-processing result: ", result)
, priority=0)

# Remove middleware
var middleware_id = command_bus.add_middleware_pre(my_callback)
command_bus.remove_middleware(middleware_id)
```

### Metrics

Enable metrics tracking for performance monitoring:

```gdscript
# Enable metrics
command_bus.set_metrics_enabled(true)
event_bus.set_metrics_enabled(true)

# Get metrics for a specific type
var cmd_metrics = command_bus.get_metrics(MovePlayerCommand)
# Returns: {"count": 42, "total_time_ms": 123.4, "avg_time_ms": 2.94, ...}

# Get all metrics
var all_metrics = command_bus.get_all_metrics()
```

## Signal Integration

While this messaging system is designed as an alternative to Godot signals, bridging between signals and messaging is useful for:

- UI interactions (button clicks, input events)
- Scene tree events (`area_entered`, `body_entered`)
- Third-party plugins that emit signals
- Legacy code migration from signals to messaging

### SignalEventAdapter

Bridge Node signals to EventBus:

```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

var event_bus = Messaging.EventBus.new()
var adapter = Messaging.SignalEventAdapter.new(event_bus)

# Bridge button signal to event
adapter.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Custom data mapping
adapter.connect_signal_to_event(
    $Area2D,
    "body_entered",
    AreaEnteredEvent,
    func(body): return {"body_name": body.name}
)
```

### When to Use What

**Use messaging (preferred for game logic):**
- Business logic and domain events
- Cross-system communication
- Commands requiring single handler
- Priority ordering and middleware needs

**Use signals (preferred for UI/Godot-specific):**
- UI interactions (button clicks, input)
- Scene tree lifecycle events
- Godot built-in events (`area_entered`, etc.)
- Third-party plugin integrations

**Use SignalEventAdapter when:**
- Migrating from signals to messaging
- Integrating legacy signal-based code
- Connecting UI signals to game logic

## Architecture

### Command Flow

```
Validate Input → Dispatch Command → CommandBus → Single Handler → Result or Error
```

### Event Flow

```
Publish Event → EventBus → Listener 1 (priority 10) → Listener 2 (priority 5) → ... → Listener N (priority 0)
```

### Component Overview

- **CommandBus** - Handles command dispatch with single-handler guarantee
- **EventBus** - Handles event publishing to multiple subscribers
- **Message** - Base class for all messages
- **Command** - Base class for commands
- **Event** - Base class for events
- **SignalEventAdapter** - Bridges Godot signals to events
- **MessageBus** - Internal implementation shared by both buses

## Best Practices

### Command Design

- Use commands for actions requiring ownership and a single response
- Keep command handlers small and focused
- Return meaningful results or propagate errors clearly

### Event Design

- Use events for notifications, side effects, and observability
- Write small, deterministic listeners
- Avoid side effects in event listeners that modify shared state unpredictably

### Subscription Management

- Bind subscriptions to object lifecycles to prevent leaks
- Use `bound_object` parameter for automatic cleanup
- Prefer explicit unsubscription for long-lived objects

### Development & Debugging

- Enable tracing and metrics during development for deep diagnostics
- Use middleware for cross-cutting concerns (logging, validation, timing)
- Monitor metrics in production for performance insights

## Design Principles

- **Explicitness over "magic"** - Clear, explicit APIs over implicit behavior
- **Deterministic behavior** - Predictable execution order over convenience
- **Debuggability first** - Optimize for transparency and maintainability
- **Type safety** - Leverage Godot's type system for compile-time checks
