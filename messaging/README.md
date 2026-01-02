# Godot Messaging System

A lightweight, type-safe messaging system for Godot that cleanly separates actions (commands) from notifications (events).

Built for decoupled game architecture, predictable execution, and serious debugging—without signals, scenes, or tight coupling.

## Why This Library?

Godot's signal-based workflows often lead to:

- Tight coupling between systems
- Implicit execution order
- Hard-to-trace side effects
- Signal spaghetti across scenes

This library provides a clear alternative:

- ✅ Explicit commands (exactly one handler)
- ✅ Broadcast events (zero or more listeners)
- ✅ Deterministic ordering via priorities
- ✅ Lifecycle-safe subscriptions
- ✅ Middleware, metrics, and tracing
- ✅ No scene tree dependency (RefCounted only)

## Core Concepts

### Commands

Imperative requests that expect a single handler.

- "Do this."
- Exactly one handler
- Returns a result or error
- Enforces clear ownership

**Examples:**
- `MovePlayerCommand`
- `SaveGameCommand`
- `DealDamageCommand`

### Events

Notifications describing something that already happened.

- "This happened."
- Zero or more listeners
- Ordered by priority
- Fire-and-forget semantics

**Examples:**
- `EnemyDiedEvent`
- `PlayerHealthChangedEvent`
- `LevelCompletedEvent`

## Architecture Overview

### Command Flow

```
validate → Dispatch Command → CommandBus → Single Handler → Result / Error
```

### Event Flow

```
Publish Event → EventBus → Listener 1, Listener 2, ... Listener N
```

## Quick Start

**Import:**

```gdscript
const Messaging = preload("res://messaging/messaging.gd")
```

**Create Buses:**

```gdscript
var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()
```

**Dispatch & Publish:**

```gdscript
await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
event_bus.publish(EnemyDiedEvent.new(enemy_id, 100))
```

## Best Practices

- Commands for actions with ownership
- Events for side effects & notifications
- Keep handlers small and deterministic
- Use lifecycle-bound subscriptions
- Enable tracing during development

## Design Philosophy

- Explicit over magical.
- Deterministic over convenient.
- Debuggable over clever.
