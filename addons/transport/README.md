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
  - [CommandBus](#commandbus)
  - [EventBus](#eventbus)
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
✅ **Middleware support** - Before/after-processing hooks  
✅ **Metrics & tracing** - Built-in introspection tools  
✅ **Scene-tree independent** - Works with RefCounted objects  

## Installation

1. Copy the `addons/transport` directory into your Godot project's `addons/` folder
2. In Godot, go to **Project → Project Settings → Plugins**
3. Enable the "Transport" plugin

**Requirements:** Godot 4.5.1 or later

## Quick Start

Here's everything you need to get started in 30 seconds:

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

# Create your command and event bus instances
var command_bus = Transport.CommandBus.new()
var event_bus = Transport.EventBus.new()

# Register a command handler (one handler per command type)
command_bus.handle(MovePlayerCommand, func(command):
    print("Moving player to ", command.target_position)
    return true
)

# Subscribe to events (zero or more listeners per event type)
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy ", event.enemy_id, " died!")
)

# Dispatch a command (returns result or error)
await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))

# Emit an event (notifies all subscribers)
event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
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

The `CommandBus` handles command execution. It ensures exactly one handler processes each command.

#### Registering Handlers

```gdscript
# Register a handler for a command type
command_bus.handle(MovePlayerCommand, func(command):
    # Handle the command
    player.move_to(command.target_position)
    return true
)
```

**Note:** If you register a handler for a command type that already has one, the old handler is replaced. This prevents accidental duplicate handlers.

#### Dispatching Commands

```gdscript
# Dispatch a command (returns result or CommandRoutingError)
var cmd = MovePlayerCommand.new(Vector2(100, 200))
var result = await command_bus.dispatch(cmd)

# Check for errors
if result is Transport.CommandRoutingError:
    print("Command failed: ", result.message)
else:
    print("Command succeeded: ", result)
```

#### Error Handling

Commands return `Transport.CommandRoutingError` when something goes wrong:
- `NO_HANDLER` - No handler registered for this command type
- `MULTIPLE_HANDLERS` - Multiple handlers registered (should never happen, but we check)
- `HANDLER_FAILED` - Handler execution failed or was cancelled by middleware

### EventBus

The `EventBus` handles event broadcasting. It notifies all subscribers when an event occurs.

#### Subscribing to Events

```gdscript
# Basic subscription
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy died: ", event.enemy_id)
)

# With priority (higher numbers run first)
event_bus.on(EnemyDiedEvent, _handle_enemy_died, priority=10)

# One-shot subscription (automatically unsubscribes after first call)
event_bus.on(EnemyDiedEvent, _on_first_enemy_death, once=true)

# Lifecycle-bound subscription (auto-unsubscribes when owner is freed)
event_bus.on(EnemyDiedEvent, _update_ui, owner=self)
```

**Priority ordering:** Listeners with higher priority values execute first. If two listeners have the same priority, they execute in registration order.

#### Emitting Events

```gdscript
# Emit an event (listeners execute sequentially)
var event = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
event_bus.emit(event)

# Or await all async listeners to complete
await event_bus.emit_and_await(event)
```

**Note:** Even though `emit()` doesn't return a value, it still awaits async listeners to prevent memory leaks. This means it may briefly block, but it's necessary for proper cleanup.

#### Unsubscribing

```gdscript
# Unsubscribe by callable
event_bus.unsubscribe(EnemyDiedEvent, _my_listener)

# Unsubscribe by subscription ID (useful for anonymous functions)
var sub_id = event_bus.on(EnemyDiedEvent, func(event): print("Event!"))
event_bus.unsubscribe_by_id(EnemyDiedEvent, sub_id)
```

### Middleware

Middleware lets you intercept and process messages before and after they reach their handlers or listeners. Perfect for logging, validation, timing, and other cross-cutting concerns.

Middleware works the same way for both commands and events. You can use callables directly or extend the `Middleware` base class for reusable middleware implementations.

**Execution guarantees:**
- Before-middleware runs before any handler/listener execution (can cancel delivery by returning `false`)
- After-middleware runs after execution completes, even when:
  - No handlers/listeners are registered
  - Errors occur during execution
  - Before-middleware cancels delivery (after-middleware is not called in this case)
- Both CommandBus and EventBus guarantee consistent middleware execution behavior

#### Using Callables (Simple)

```gdscript
# Before-execution middleware (runs before handlers/listeners)
# Can cancel delivery by returning false
command_bus.add_middleware_before(func(cmd: Command):
    print("Before-execution: ", cmd)
    return true  # Return false to cancel delivery
, priority=0)

# After-execution middleware (runs after handlers/listeners)
# Receives the message and the result
command_bus.add_middleware_after(func(cmd: Command, result):
    print("After-execution result: ", result)
, priority=0)

# Same for events
event_bus.add_middleware_before(func(evt: Event):
    print("Before-execution event: ", evt)
    return true
, priority=0)

event_bus.add_middleware_after(func(evt: Event, result):
    # Note: result is always null for events (events broadcast to multiple listeners)
    print("After-execution event: ", evt)
, priority=0)

# Remove middleware when you're done
var middleware_id = command_bus.add_middleware_before(my_callback)
command_bus.remove_middleware(middleware_id)
```

#### Using Middleware Class (Reusable)

For reusable middleware, extend the `Middleware` base class:

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

# Create a logging middleware
class LoggingMiddleware extends Transport.Middleware:
    func process_before(message: Transport.Message, message_key: StringName) -> bool:
        print("[Middleware] Before: ", message_key, " - ", message)
        return true  # Continue delivery
    
    func process_after(message: Transport.Message, message_key: StringName, result: Variant) -> void:
        print("[Middleware] After: ", message_key, " - Result: ", result)

# Use it
var logging_mw = LoggingMiddleware.new(priority=10)
command_bus.add_middleware_before(logging_mw.as_before_callable(), logging_mw.priority)
command_bus.add_middleware_after(logging_mw.as_after_callable(), logging_mw.priority)

# Also works with events
event_bus.add_middleware_before(logging_mw.as_before_callable(), logging_mw.priority)
event_bus.add_middleware_after(logging_mw.as_after_callable(), logging_mw.priority)
```

**Use cases:**
- Logging all commands/events
- Performance timing
- Validation and authorization
- Error handling and recovery
- Cross-cutting concerns that apply to both commands and events

### Metrics

Track performance and usage patterns with built-in metrics:

```gdscript
# Enable metrics tracking
command_bus.set_metrics_enabled(true)
event_bus.set_metrics_enabled(true)

# Get metrics for a specific command/event type
var cmd_metrics = command_bus.get_metrics(MovePlayerCommand)
# Returns: {
#   "count": 42,
#   "total_time": 123.4,
#   "min_time": 0.5,
#   "max_time": 5.2,
#   "avg_time": 2.94
# }

# Get all metrics at once
var all_metrics = command_bus.get_all_metrics()
```

**Metrics include:**
- `count` - How many times this type was processed
- `total_time` - Total time spent (in seconds)
- `min_time` - Fastest execution time
- `max_time` - Slowest execution time
- `avg_time` - Average execution time

## Signal Integration

The transport system is designed as an alternative to Godot signals, but sometimes you need to bridge between them. The `EventSignalBridge` and `CommandSignalBridge` utilities make this easy.

### When You Need Bridging

- **UI interactions** - Button clicks, input events from Godot's UI system
- **Scene tree events** - `area_entered`, `body_entered`, and other built-in signals
- **Third-party plugins** - Libraries that emit signals you can't control
- **Legacy code** - Gradually migrating from signals to transport

### Using Signal Bridges

**Event Signal Bridge:**
```gdscript
const Transport = preload("res://addons/transport/transport.gd")

var event_bus = Transport.EventBus.new()
var event_signal_bridge = Transport.EventSignalBridge.new(event_bus)

# Simple bridge: button press → event
event_signal_bridge.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Custom data mapping: extract what you need from signal args
event_signal_bridge.connect_signal_to_event(
    $Area2D,
    "body_entered",
    AreaEnteredEvent,
    func(body): return {"body_name": body.name, "body_type": body.get_class()}
)

# Clean up when done (automatically happens when bridge is freed)
event_signal_bridge.disconnect_all()
```

**Command Signal Bridge:**
```gdscript
const Transport = preload("res://addons/transport/transport.gd")

var command_bus = Transport.CommandBus.new()
var command_signal_bridge = Transport.CommandSignalBridge.new(command_bus)

# Bridge button click → command (use mapper to construct command properly)
command_signal_bridge.connect_signal_to_command(
    $SaveButton,
    "pressed",
    SaveGameCommand,
    func(): return SaveGameCommand.new()
)

# Bridge with signal arguments
command_signal_bridge.connect_signal_to_command(
    $MenuItem,
    "selected",
    OpenMenuCommand,
    func(menu_id: int): return OpenMenuCommand.new(menu_id)
)

# Clean up when done (automatically happens when bridge is freed)
command_signal_bridge.disconnect_all()
```

The bridges automatically clean up connections when they're freed, so you don't need to worry about memory leaks.

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

**Use EventSignalBridge/CommandSignalBridge when:**
- Migrating gradually from signals to transport
- Integrating legacy signal-based code
- Connecting UI signals to your game logic

## Architecture

### How It Works

**Command Flow:**
```
Input → CommandBus → Validation → Single Handler → Result/Error
```

Commands are validated to ensure exactly one handler exists, then dispatched. The result (or error) is returned to the caller.

**Event Flow:**
```
Emit → EventBus → Middleware → Listeners (priority order) → Done
```

Events are emitted to all subscribers in priority order. Each listener completes before the next starts, ensuring predictable execution.

### Component Overview

- **CommandBus** - Dispatches commands with a single-handler guarantee
- **EventBus** - Emits events to zero or more subscribers
- **Message** - Base class for all messages (commands and events extend this)
- **Command** - Base class for commands
- **Event** - Base class for events
- **Middleware** - Base class for middleware implementations (works with both commands and events)
- **CommandSignalBridge** - Connects Godot signals to CommandBus commands
- **EventSignalBridge** - Connects Godot signals to EventBus events
- **Subscribers** - Shared internal infrastructure used by both CommandBus and EventBus (you don't use this directly)

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
