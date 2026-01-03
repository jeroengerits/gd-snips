# Claude AI Context

This document provides context for AI assistants working with this codebase, including architectural decisions, patterns, and common issues.

## Project Overview

**Godot Snips** is a collection of reusable packages for Godot 4.5.1+. The project emphasizes:
- Modular architecture
- Clean code practices
- Type safety
- Domain-driven design principles

## Project Structure

All packages live under `packages/`:

```
packages/
├── messaging/     # Command/Event messaging framework
│   ├── buses/     # CommandBus, EventBus
│   ├── types/     # Message, Command, Event base classes
│   ├── rules/     # Domain rules (CommandRules, SubscriptionRules)
│   ├── internal/   # MessageBus foundation class
│   └── utilities/  # Package-specific utilities
└── collection/     # Fluent array wrapper
    ├── types/      # Collection class
    └── collection.gd  # Barrel file
```

## Architectural Decisions

### Package Organization

**Decision:** All packages moved to `packages/` directory (January 2026)

**Rationale:**
- Clear separation between packages and project-level files
- Consistent import paths: `res://packages/{package}/...`
- Easier to understand project structure at a glance

**Impact:**
- All preload paths use `res://packages/` prefix
- Documentation links updated accordingly
- No breaking changes to API, only path changes

### Collection Package Evolution

**Timeline:**
1. Initially in `utilities/collection_utils.gd` as static functions
2. Refactored to `utilities/collection.gd` as a class
3. Moved to `packages/collection/` as standalone package
4. Method names shortened (e.g., `is_empty()` → `empty()`)
5. Restructured to match messaging package (January 2026)

**Rationale:**
- Collection is substantial enough to be its own package
- Better discoverability and documentation
- Consistent structure across all packages improves maintainability

**Current Structure:**
- `collection.gd` - Barrel file (public API entry point)
- `types/collection.gd` - Main Collection class
- Matches messaging package structure for consistency

### Method Naming Convention

**Decision:** Short, single-word method names where possible

**Examples:**
- `is_empty()` → `empty()`
- `to_array()` → `array()`
- `remove_at_indices()` → `remove_at()`
- `cleanup_empty_key()` → `cleanup()`

**Rationale:**
- More concise and readable
- Consistent with modern API design
- Context makes meaning clear

### Package Structure Consistency

**Decision:** All packages follow the same structural pattern (January 2026)

**Pattern:**
- Barrel file at root (`{package}.gd`) - Public API entry point
- `types/` subdirectory - Core classes/types
- Additional subdirectories as needed (e.g., `buses/`, `rules/`, `internal/`)

**Rationale:**
- Consistency makes packages easier to navigate
- Predictable structure reduces cognitive load
- Easier to add new packages following the same pattern

**Examples:**
- `messaging/messaging.gd` → `types/message.gd`, `buses/command_bus.gd`
- `collection/collection.gd` → `types/collection.gd`

### Messaging Package Architecture

**Layered Design:**
```
Public API (CommandBus/EventBus)
    ↓
Foundation (MessageBus)
    ↓
Domain Rules (CommandRules/SubscriptionRules)
    ↓
Infrastructure (MessageTypeResolver)
```

**Key Patterns:**
- **Barrel Files:** Each package has a main entry point (e.g., `messaging.gd`)
- **Domain Rules:** Business logic separated into Rules classes
- **Lifecycle Binding:** Subscriptions auto-cleanup when bound objects are freed
- **Type Resolution:** Handles Godot's type system complexity transparently (prioritizes `class_name`)

### Type Resolution and Lifecycle Management

**Type Resolution:**
The `MessageTypeResolver` handles Godot's type system complexity:
- Prioritizes `class_name` when available (most deterministic across machines)
- Falls back to script path for instances without `class_name`
- Handles GDScript class references by instantiating to extract `class_name`
- **Best Practice:** Always use `class_name` for message types to ensure consistent routing

**Lifecycle Management:**
Subscriptions and adapters automatically clean up to prevent memory leaks:
- Subscriptions bound to objects auto-unsubscribe when object is freed (uses `is_instance_valid()`)
- `SignalEventAdapter` automatically disconnects signal connections when freed (uses `_notification(NOTIFICATION_PREDELETE)`)
- No manual cleanup needed for scene-bound subscriptions and adapters

### Signal Integration

**Decision:** Provide adapter utilities for bridging Godot signals and messaging (January 2026)

**Rationale:**
- Messaging system is designed as alternative to signals, but integration is sometimes needed
- UI interactions, scene tree events, and third-party plugins often use signals
- Adapters enable gradual migration from signals to messaging
- Bridges allow exposing messaging events to signal-based systems

**Adapters:**
- **SignalEventAdapter:** Bridges Node signals → EventBus (RefCounted utility)
- **EventSignalAdapter:** Bridges EventBus → Node signals (Node-based utility)

**Usage Guidelines:**
- Use messaging for game logic and domain events
- Use signals for UI interactions and Godot-specific events
- Use adapters when bridging between the two systems
- Keep adapters thin—only convert formats, no business logic

**Pattern:**
```gdscript
# Signal → Event
var adapter = Messaging.SignalEventAdapter.new(event_bus)
adapter.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Event → Signal
var adapter = Messaging.EventSignalAdapter.new()
adapter.set_event_bus(event_bus)
adapter.connect_event_to_signal(EnemyDiedEvent, "enemy_died")
```

## Development Patterns

### Import Patterns

**Package Import (Barrel Files):**
```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")
const Collection = preload("res://packages/collection/collection.gd")

# Use via barrel file
var bus = Messaging.CommandBus.new()
var coll = Collection.Collection.new([1, 2, 3])
```

**Direct Class Import:**
```gdscript
const Collection = preload("res://packages/collection/types/collection.gd")
var coll = Collection.new([1, 2, 3])
```

**Direct Import (for internal files):**
```gdscript
const MessageBus = preload("res://packages/messaging/internal/message_bus.gd")
```

### Collection Usage Patterns

**Working with References:**
```gdscript
const Collection = preload("res://packages/collection/types/collection.gd")

var my_array: Array = [1, 2, 3]
var collection = Collection.new(my_array, false)  # false = use reference
collection.push(4)  # Modifies my_array directly
```

**Dictionary Cleanup Pattern:**
```gdscript
var subscriptions: Dictionary = {}
var listeners: Array = []

# Remove and cleanup if empty
Collection.new(listeners, false).remove_at([0, 2]).cleanup(subscriptions, "key")
```

### Messaging Patterns

**Command Pattern:**
- Exactly one handler per command type
- Returns result or CommandError
- Use for imperative actions

**Event Pattern:**
- Zero or more listeners
- Sequential delivery in priority order
- Async listeners are awaited to prevent memory leaks (may block briefly)
- Use for notifications

## Common Issues and Solutions

### Issue: Preload Path Errors

**Symptom:** `preload()` fails with "Resource not found"

**Solution:** Ensure all paths use `res://packages/` prefix:
- ✅ `res://packages/messaging/messaging.gd`
- ❌ `res://messaging/messaging.gd`

### Issue: Collection Not Modifying Array

**Symptom:** Collection operations don't affect original array

**Solution:** Pass `false` for `copy` parameter when you need reference:
```gdscript
Collection.new(my_array, false)  # Uses reference
```

### Issue: Multiple Command Handlers

**Symptom:** `CommandError: Multiple handlers registered`

**Solution:** Commands must have exactly one handler. Clear existing handler first:
```gdscript
command_bus.clear_type(MyCommand)
command_bus.handle(MyCommand, my_handler)
```

### Issue: SignalEventAdapter Connection Leaks

**Symptom:** Signal connections remain after adapter is freed, causing errors

**Solution:** Adapter automatically cleans up connections on free (uses `_notification`). If manually managing, call `disconnect_all()`:
```gdscript
adapter.disconnect_all()  # Manual cleanup (auto-cleanup on free)
```

### Issue: Type Resolution Inconsistency

**Symptom:** Same message type resolves to different keys when passing class vs instance

**Solution:** Use `class_name` for all message types. The resolver prioritizes `class_name` over script paths for consistency:
```gdscript
extends Message
class_name MyCommand  # Required for consistent resolution
```

### Issue: EventBus.publish() Blocks

**Symptom:** `publish()` appears to block even though it's "fire-and-forget"

**Solution:** `publish()` awaits async listeners to prevent memory leaks. This is intentional. For non-blocking behavior from Node context, use `call_deferred()`:
```gdscript
call_deferred("_publish_event", event_bus, evt)
```

## Testing Insights

### Message Bus Testing

- Test priority ordering with multiple subscribers
- Verify lifecycle binding cleanup (freed objects)
- Test one-shot subscriptions auto-remove
- Validate middleware cancellation

### Collection Testing

- Test reference vs copy behavior
- Verify dictionary cleanup pattern
- Test safe multi-item removal (`remove_at()`)
- Validate method chaining

## Code Style Guidelines

### Naming Conventions

- **Classes:** PascalCase (`CommandBus`, `Collection`)
- **Methods:** snake_case (`get_key()`, `remove_at()`)
- **Variables:** snake_case (`command_bus`, `subscriptions`)
- **Constants:** UPPER_SNAKE_CASE (not used in this project)

### Documentation

- All public APIs have GDScript-style doc comments
- README files in each package directory
- Developer diary for architectural decisions
- This file (CLAUDE.md) for AI context

**Documentation Philosophy:**
- **YAGNI:** Only document what's needed
- **Brevity:** Short, clear, practical examples
- **Scannable:** Easy to find what you need quickly
- **Actionable:** Code examples show usage immediately

### File Organization

- One class per file (when possible)
- Barrel files for package entry points
- Internal implementation in `internal/` folders
- Domain rules in `rules/` folders
- Package-specific utilities in `utilities/` folders

## Recent Improvements (January 2026)

### Performance Optimizations

1. **Subscription Sorting:** Changed from O(n log n) full sort to O(n) insertion sort when subscribing. Subscriptions are now inserted in priority order directly, improving performance for frequent subscription/unsubscription patterns.

2. **Type Resolution:** Improved consistency by prioritizing `class_name` across all resolution paths (instances, class references, GDScript scripts). Instantiates GDScript classes only when needed to extract `class_name`, improving determinism.

### Bug Fixes

1. **Metrics Recording:** Fixed double-recording bug in EventBus where metrics were recorded per-listener and again for overall operation. Now correctly records overall operation time once.

2. **Resource Cleanup:** Added automatic cleanup for `SignalEventAdapter` connections via `_notification()` to prevent memory leaks when adapters are freed.

3. **Validation Logic:** Simplified Message._init() validation by removing redundant checks after assertions, improving clarity and maintainability.

### Type Safety Improvements

1. **Type Annotations:** Added explicit `Variant` type annotations to all Collection methods for better type safety and IDE support (`first()`, `last()`, `get()`, `pop()`, `shift()`, `find()`, `reduce()`, etc.).

2. **Documentation:** Clarified async behavior in EventBus.publish() - removed misleading "fire-and-forget" terminology, documented that async listeners are awaited to prevent memory leaks.

## Future Considerations

### Potential Improvements

1. **Batch Operations:** For high-frequency event publishing (multiple events in one operation)
2. **Type Safety:** More compile-time checks for message types (require class_name validation)
3. **Performance Metrics:** Enhanced profiling options (per-listener breakdown, slow handler warnings)
4. **Thread Safety:** Document thread-safety assumptions (currently single-threaded)

### Breaking Changes Policy

- Major refactors documented in developer diary
- Path changes (like packages/ move) are breaking but documented
- Method renames maintain backward compatibility where possible
- API changes follow semantic versioning principles

## References

- [Messaging Package README](packages/messaging/README.md)
- [Collection Package README](packages/collection/README.md)
- [Developer Diary](docs/developer-diary/)
- [Godot Documentation](https://docs.godotengine.org/)

