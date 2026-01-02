# Godot Messaging System

A high-performance, type-safe messaging framework for Godot that rigorously separates actions (commands) from notifications (events).

Designed to support modular game architecture, precise execution order, and powerful debugging tools—all without relying on Godot signals, scenes, or tight coupling.

## Why Use This Library?

Godot’s built-in signals often lead to:

- Systems being tightly bound together
- Hidden or unpredictable execution order
- Difficult-to-track side effects
- “Signal spaghetti” scattered across scenes

**This messaging system offers a modern alternative:**

- ✅ Explicit commands (guaranteed exactly one handler)
- ✅ Broadcast events (zero or more listeners, no assumptions)
- ✅ Deterministic, priority-based execution order
- ✅ Lifecycle-aware subscriptions (automatic clean-up)
- ✅ Middleware, metrics, and tracing for introspection
- ✅ No reliance on the scene tree (works with RefCounted only)

## Core Concepts

### Commands

Commands represent requests that expect a single authoritative handler.

> "Do this."

- Exactly one handler (errors if ambiguous or unhandled)
- Returns a result or propagates an error
- Clear boundaries and responsibility

**Examples:**
- `MovePlayerCommand`
- `SaveGameCommand`
- `DealDamageCommand`

### Events

Events signal that something has already occurred in the game domain.

> "This happened."

- Any number of listeners (including zero)
- Ordered by priority, processed sequentially
- “Fire-and-forget” by default—no return value

**Examples:**
- `EnemyDiedEvent`
- `PlayerHealthChangedEvent`
- `LevelCompletedEvent`

## Architecture Overview

### Command Flow

```text
Validate Input → Dispatch Command → CommandBus → Single Handler → Result or Error
```

### Event Flow

```text
Publish Event → EventBus → Listener 1 → Listener 2 → ... → Listener N
```

## Quick Start

**Import the messaging library:**

```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")
```

**Create Instances of CommandBus and EventBus:**

```gdscript
var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()
```

**Dispatch Commands & Publish Events:**

```gdscript
await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
event_bus.publish(EnemyDiedEvent.new(enemy_id, 100))
```

## Best Practices

- Use commands for actions requiring ownership and a single response
- Use events for notifications, side effects, and observability
- Write small, deterministic handlers and listeners
- Bind subscriptions to object lifecycles to prevent leaks
- Enable tracing and metrics during development for deep diagnostics

## Design Principles

- Prefer explicitness over “magic”
- Value deterministic behavior over convenience
- Optimize for debuggability, transparency, and maintainability
