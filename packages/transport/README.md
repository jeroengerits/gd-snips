# Godot Transport System

A simple and type-safe transport framework for Godot 4.5.1+ designed to support modular game architecture, precise execution order, and debugging tools.

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
  - [Command Router](#command-router)
  - [Event Broadcaster](#event-broadcaster)
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

```gdscript
const Transport = preload("res://packages/transport/transport.gd")

# Create router and broadcaster instances
var command_router = Transport.Commander.new()
var event_broadcaster = Transport.Publisher.new()

# Register a command handler
command_router.register_handler(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    print("Moving player to ", cmd.target_position)
    return true
)

# Subscribe to events
event_broadcaster.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    print("Enemy ", evt.enemy_id, " died!")
)

# Execute commands
await command_router.execute(MovePlayerCommand.new(Vector2(100, 200)))

# Broadcast events
event_broadcaster.broadcast(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
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

### Command Router

#### Registering Handlers

```gdscript
# Register a handler for a command type
command_router.register_handler(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    # Handle the command
    player.move_to(cmd.target_position)
    return true
)
```

#### Executing Commands

```gdscript
# Execute a command (returns result or throws CommandRoutingError)
var cmd = MovePlayerCommand.new(Vector2(100, 200))
var result = await command_router.execute(cmd)
```

#### Error Handling

Commands can throw `Commander.CommandRoutingError`:
- `NO_HANDLER` - No handler registered for command type
- `MULTIPLE_HANDLERS` - Multiple handlers registered (invalid state)
- `HANDLER_FAILED` - Handler execution failed

### Event Broadcaster

#### Subscribing to Events

```gdscript
# Basic subscription
event_broadcaster.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    print("Enemy died: ", evt.enemy_id)
)

# With priority (higher = executed first)
event_broadcaster.subscribe(EnemyDiedEvent, _handle_enemy_died, priority=10)

# One-shot subscription (automatically unsubscribes after first call)
event_broadcaster.subscribe(EnemyDiedEvent, _on_first_enemy_death, once=true)

# Lifecycle-bound subscription (auto-unsubscribes when object exits tree)
event_broadcaster.subscribe(EnemyDiedEvent, _update_ui, owner=self)
```

#### Broadcasting Events

```gdscript
# Broadcast an event (non-blocking, listeners execute sequentially)
var evt = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
event_broadcaster.broadcast(evt)
```

#### Unsubscribing

```gdscript
# Unsubscribe by callable
event_broadcaster.unsubscribe(EnemyDiedEvent, _my_listener)

# Unsubscribe by subscription ID
var sub_id = event_broadcaster.subscribe(EnemyDiedEvent, _my_listener)
event_broadcaster.unsubscribe_by_id(EnemyDiedEvent, sub_id)
```

### Middleware

Middleware allows pre and post-processing of messages:

```gdscript
# Pre-processing middleware (runs before handlers/listeners)
command_router.add_middleware_pre(func(cmd: Command):
    print("Pre-processing: ", cmd)
, priority=0)

# Post-processing middleware (runs after handlers/listeners)
command_router.add_middleware_post(func(cmd: Command, result):
    print("Post-processing result: ", result)
, priority=0)

# Remove middleware
var middleware_id = command_router.add_middleware_pre(my_callback)
command_router.remove_middleware(middleware_id)
```

### Metrics

Enable metrics tracking for performance monitoring:

```gdscript
# Enable metrics
command_router.set_metrics_enabled(true)
event_broadcaster.set_metrics_enabled(true)

# Get metrics for a specific type
var cmd_metrics = command_router.get_metrics(MovePlayerCommand)
# Returns: {"count": 42, "total_time_ms": 123.4, "avg_time_ms": 2.94, ...}

# Get all metrics
var all_metrics = command_router.get_all_metrics()
```

## Signal Integration

While this transport system is designed as an alternative to Godot signals, bridging between signals and transport is useful for:

- UI interactions (button clicks, input events)
- Scene tree events (`area_entered`, `body_entered`)
- Third-party plugins that emit signals
- Legacy code migration from signals to transport

### Bridge

Bridge Node signals to Publisher:

```gdscript
const Transport = preload("res://packages/transport/transport.gd")

var event_broadcaster = Transport.Publisher.new()
var adapter = Transport.Bridge.new(event_broadcaster)

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

**Use transport (preferred for game logic):**
- Business logic and domain events
- Cross-system communication
- Commands requiring single handler
- Priority ordering and middleware needs

**Use signals (preferred for UI/Godot-specific):**
- UI interactions (button clicks, input)
- Scene tree lifecycle events
- Godot built-in events (`area_entered`, etc.)
- Third-party plugin integrations

**Use Bridge when:**
- Migrating from signals to transport
- Integrating legacy signal-based code
- Connecting UI signals to game logic

## Architecture

### Command Flow

```
Validate Input → Execute Command → Commander → Single Handler → Result or Error
```

### Event Flow

```
Broadcast Event → Publisher → Listener 1 (priority 10) → Listener 2 (priority 5) → ... → Listener N (priority 0)
```

### Component Overview

- **Commander** - Handles command execution with single-handler guarantee
- **Publisher** - Handles event broadcasting to multiple subscribers
- **Message** - Base class for all messages
- **Command** - Base class for commands
- **Event** - Base class for events
- **Bridge** - Bridges Godot signals to events
- **SubscriptionRegistry** - Internal implementation shared by both router and broadcaster

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
- Use `owner` parameter for automatic cleanup
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
