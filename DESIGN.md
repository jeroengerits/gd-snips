# MessageBus System Design

## Overview

This messaging system provides a clean, type-safe way to decouple components in Godot games. It consists of three layers:

1. **MessageBus** (core) - Generic subscription and routing infrastructure
2. **CommandBus** - Single-handler command pattern implementation
3. **EventBus** - Multi-subscriber event pattern implementation

## Architecture

### MessageBus Core

The `MessageBus` class is the foundation that provides:

- **Generic subscription management**: Stores callables keyed by message type (StringName)
- **Priority-based ordering**: Subscriptions are sorted by priority (higher first)
- **Lifecycle safety**: Subscriptions can be bound to Objects and auto-unsubscribe when objects are freed
- **One-shot subscriptions**: Subscriptions that automatically unsubscribe after first delivery
- **Safe iteration**: Subscriptions can be safely removed during dispatch
- **Debugging support**: Verbose logging, tracing, and inspection capabilities

**Design Decision: StringName Type Keys**

We use `StringName` for type identifiers because:
- Excellent performance (interned strings, fast comparisons)
- Works seamlessly with GDScript's type system
- Supports both class-based typing (via script paths) and string-based typing
- Minimal allocations during dispatch/publish

The system accepts:
- Script resources (e.g., `MovePlayerCommand` class reference)
- Class instances (extracts class_name via `get_class_name()` method)
- StringName/String literals

### CommandBus

Extends `MessageBus` to enforce single-handler semantics:

- **Exactly one handler**: `handle()` replaces any existing handler
- **Result return**: `dispatch()` returns the handler's result (supports async)
- **Error handling**: Returns `CommandBusError` if no handler or multiple handlers exist
- **Type safety**: Strongly typed command instances

**Use Case**: Imperative actions that should have a single, authoritative handler:
- Player movement commands
- Inventory operations
- Save/load operations
- UI actions

### EventBus

Extends `MessageBus` to support multi-subscriber semantics:

- **0..N subscribers**: Multiple listeners can subscribe to the same event type
- **Priority ordering**: Listeners called in priority order (higher first)
- **Fire-and-forget**: `publish()` is synchronous, but supports async listeners
- **Error isolation**: One failing listener doesn't break others
- **Optional error collection**: Can collect errors from listeners for debugging

**Use Case**: Notifications that multiple systems care about:
- Enemy death events
- Player health changes
- Achievement unlocks
- UI state changes

## Key Features

### Lifecycle Safety

Subscriptions can be bound to Objects:
```gdscript
event_bus.subscribe(EnemyDiedEvent, listener, bound_object=self)
```

When the bound object is freed, the subscription is automatically cleaned up. This prevents:
- Calling freed objects
- Memory leaks from orphaned subscriptions
- Stale references

### One-Shot Subscriptions

Subscriptions that auto-unsubscribe after first delivery:
```gdscript
event_bus.subscribe(EnemyDiedEvent, listener, one_shot=true)
```

Useful for:
- Initialization code that should only run once
- Tutorial triggers
- First-time event handlers

### Priority Ordering

Listeners are called in priority order (higher priority first):
```gdscript
event_bus.subscribe(Event, high_priority_handler, priority=10)
event_bus.subscribe(Event, low_priority_handler, priority=0)
```

Useful for:
- Ensuring core systems process events before UI
- Dependency ordering
- Critical vs. cosmetic handlers

### Async Support

Both buses support async handlers:
```gdscript
command_bus.handle(Command, func(cmd: Command):
    await some_async_operation()
    return result
)

var result = await command_bus.dispatch(command)
```

EventBus supports async listeners, though `publish()` is fire-and-forget by default.

### Error Handling

**CommandBus**:
- Returns `CommandBusError` objects on failure
- Errors include error codes (NO_HANDLER, MULTIPLE_HANDLERS, HANDLER_FAILED)
- Can be checked: `if result is CommandBus.CommandBusError`

**EventBus**:
- Errors from listeners are isolated (one failure doesn't break others)
- Optional error collection mode for debugging (`set_collect_errors()`)
- Uses `push_error()` for logging failures

### Debugging & Inspection

Both buses inherit debugging capabilities from `MessageBus`:

- **Verbose logging** (`set_verbose()`): Logs all subscription/unsubscription operations
- **Tracing** (`set_tracing()`): Logs every message delivery with details
- **Subscription inspection**:
  - `get_subscription_count(message_type)` - Count active subscriptions
  - `get_registered_types()` - List all registered message types
  - `get_listeners(event_type)` - Get all listeners for an event type
- **EventBus-specific**: `set_collect_errors()` to collect and log listener errors without breaking execution

## Why This Abstraction is Reusable

1. **Separation of Concerns**: MessageBus handles routing/subscription logic; CommandBus/EventBus handle delivery semantics
2. **Composable**: Both buses share the same core infrastructure
3. **Extensible**: Easy to add new bus types (e.g., QueryBus) by extending MessageBus
4. **Type-Safe**: Uses GDScript's type system for compile-time safety
5. **Performance**: StringName keys, minimal allocations, efficient iteration
6. **Ergonomic**: Clean API designed for gameplay code

## Performance Considerations

- **StringName keys**: Fast hash lookups, minimal memory overhead
- **Sorted subscriptions**: Priority sorting happens on subscribe (not dispatch)
- **Safe iteration**: Snapshots created only when needed (events with multiple subscribers)
- **No deep copies**: Messages are passed by reference (immutability is convention)
- **Cleanup on-demand**: Invalid subscriptions cleaned during dispatch (not proactively)

## Usage Patterns

### Commands (Single Handler)
```gdscript
# Setup
command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    return player.move_to(cmd.target_position)
)

# Dispatch
var result = await command_bus.dispatch(MovePlayerCommand.new(target_pos))
if result is CommandBus.CommandBusError:
    handle_error(result)
```

### Events (Multiple Subscribers)
```gdscript
# Setup
event_bus.subscribe(EnemyDiedEvent, update_score, priority=10)
event_bus.subscribe(EnemyDiedEvent, play_sound, priority=5)
event_bus.subscribe(EnemyDiedEvent, cleanup_enemy, bound_object=enemy_node)

# Publish
event_bus.publish(EnemyDiedEvent.new(enemy_id, points))
```

