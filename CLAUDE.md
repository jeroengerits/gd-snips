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
└── transport/     # Command/Event transport framework
    ├── type/      # Message, Command, Event base classes
    ├── utils/     # Metrics utilities
    ├── event/     # EventBus, Subscribers, Validator, EventSignalBridge
    └── command/   # CommandBus, Validator
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

### Collection Package Removal

**Decision:** Removed Collection package and replaced with direct array/dictionary operations (January 2026)

**Rationale:**
- Collection was only used internally in the transport package
- Direct GDScript array/dictionary operations are simpler and more idiomatic
- Reduces package dependencies and complexity
- No external API impact (Collection was never part of public transport API)

**Implementation:**
- Replaced `Collection.remove_at()` with `_remove_indices_from_array()` helper function
- Replaced `Collection.cleanup()` with direct dictionary `erase()` checks
- Replaced `Collection.each()` with simple `for` loops
- All functionality preserved using native GDScript operations

**Impact:**
- Transport package no longer depends on Collection package
- Code is more straightforward and easier to understand
- No breaking changes to transport API


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
- Organized subdirectories by functionality
- Flat structure with no nested folders

**Rationale:**
- Consistency makes packages easier to navigate
- Predictable structure reduces cognitive load
- Easier to add new packages following the same pattern

**Examples:**
- `transport/transport.gd` → `type/message.gd`, `command/command_bus.gd`

### Transport Package Architecture

**Layered Design:**
```
Public API (CommandBus/EventBus)
    ↓
Foundation (Subscribers)
    ↓
Domain Rules (Validator classes)
    ↓
Infrastructure (MessageTypeResolver)
```

**Key Patterns:**
- **Barrel Files:** Each package has a main entry point (e.g., `transport.gd`)
- **Domain Rules:** Business logic separated into validation classes (Validator in command/, Validator in event/)
- **Lifecycle Binding:** Subscriptions auto-cleanup when bound objects are freed
- **Type Resolution:** Handles Godot's type system complexity transparently (prioritizes `class_name`)
- **Organized Structure:** Functionality-based organization (messages, routing, pubsub, validation, observability, adapters)

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
- `EventSignalBridge` and `CommandSignalBridge` automatically disconnect signal connections when freed (uses `_notification(NOTIFICATION_PREDELETE)`)
- No manual cleanup needed for scene-bound subscriptions and adapters

### Signal Integration

**Decision:** Provide adapter utilities for bridging Godot signals and transport (January 2026)

**Rationale:**
- Transport system is designed as alternative to signals, but integration is sometimes needed
- UI interactions, scene tree events, and third-party plugins often use signals
- Adapters enable gradual migration from signals to transport

**Adapters:**
- **Bridge:** Bridges Node signals → EventBus (RefCounted utility)

**Usage Guidelines:**
- Use transport for game logic and domain events
- Use signals for UI interactions and Godot-specific events
- Use EventSignalBridge/CommandSignalBridge when bridging signals to transport
- Keep adapters thin—only convert formats, no business logic

**Pattern:**
```gdscript
# Signal → Event
var adapter = Transport.EventSignalBridge.new(event_bus)
adapter.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Signal → Command
var command_adapter = Transport.CommandSignalBridge.new(command_bus)
command_adapter.connect_signal_to_command($SaveButton, "pressed", SaveGameCommand, func(): return SaveGameCommand.new())
```

## Development Patterns

### Import Patterns

**Package Import (Barrel Files):**
```gdscript
const Transport = preload("res://packages/transport/transport.gd")

# Use via barrel file
var command_bus = Transport.CommandBus.new()
var event_bus = Transport.EventBus.new()
```

**Direct Import (for internal files):**
```gdscript
const Subscribers = preload("res://packages/transport/event/subscribers.gd")
```

**Note:** Collection package was removed (January 2026). Use direct GDScript array/dictionary operations instead.

### Transport Patterns

**Command Pattern:**
- Exactly one handler per command type
- Returns result or CommandRoutingError
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
- ✅ `res://packages/transport/transport.gd`
- ❌ `res://transport/transport.gd`

### Issue: Multiple Command Handlers

**Symptom:** `CommandRoutingError: Multiple handlers registered`

**Solution:** Commands must have exactly one handler. Clear existing handler first:
```gdscript
command_router.clear_registrations(MyCommand)
command_router.register_handler(MyCommand, my_handler)
```

### Issue: Signal Bridge Connection Leaks

**Symptom:** Signal connections remain after adapter is freed, causing errors

**Solution:** Adapter automatically cleans up connections on free (uses `_notification`). If manually managing, call `disconnect_all()`:
```gdscript
event_signal_bridge.disconnect_all()  # Manual cleanup (auto-cleanup on free)
```

### Issue: Type Resolution Inconsistency

**Symptom:** Same message type resolves to different keys when passing class vs instance

**Solution:** Use `class_name` for all message types. The resolver prioritizes `class_name` over script paths for consistency:
```gdscript
extends Message
class_name MyCommand  # Required for consistent resolution
```

### Issue: EventBus.emit() Blocks

**Symptom:** `broadcast()` appears to block even though it's "fire-and-forget"

**Solution:** `broadcast()` awaits async listeners to prevent memory leaks. This is intentional. For non-blocking behavior from Node context, use `call_deferred()`:
```gdscript
call_deferred("_broadcast_event", event_broadcaster, evt)
```

## Testing Insights

### Message Bus Testing

- Test priority ordering with multiple subscribers
- Verify lifecycle binding cleanup (freed objects)
- Test one-shot subscriptions auto-remove
- Validate middleware cancellation


## Code Style Guidelines

### Naming Conventions

- **Classes:** PascalCase (`CommandBus`, `EventBus`, `Message`)
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
- Flat folder structure (no nested subdirectories)
- Organized by functionality (types, utils, events, commands)

## Recent Improvements (January 2026)

### Folder Structure Refactoring

**Decision:** Reorganized transport package structure for better clarity and organization (January 2026)

**Rationale:**
- More semantic organization that reflects functionality
- Clearer separation of concerns
- Better discoverability for developers
- Flatter structure with no nested subdirectories

**Evolution:**
1. Initial: `types/`, `buses/`, `routers/`, `rules/`, `internal/`, `utilities/` (plural)
2. First refactor: `messages/`, `pubsub/`, `routing/`, `validation/`, `observability/`, `adapters/`
3. Flattened: Removed nested `internal/` folders
4. Final structure: `type/`, `utils/`, `event/`, `command/` (singular folder names)

**Current Structure:**
- `type/` - Message, Command, Event base classes and MessageTypeResolver
- `utils/` - Metrics utilities
- `middleware/` - Middleware base class (middleware.gd), MiddlewareEntry (middleware_entry.gd)
- `event/` - EventBus (event_bus.gd), Subscribers (subscribers.gd), Validator (event_validator.gd), EventSignalBridge (event_signal_bridge.gd)
- `command/` - CommandBus (command_bus.gd), Validator (command_validator.gd), CommandSignalBridge (command_signal_bridge.gd)

**File Naming:**
- Files match class names: `command_bus.gd`, `event_bus.gd`, `subscribers.gd`, `event_signal_bridge.gd`, `command_signal_bridge.gd`, `validator.gd`
- Class names match filenames (CommandBus, EventBus, etc.)
- All files are at most one level deep from package root

**Impact:**
- All preload paths updated automatically
- Public API unchanged (all exports through `transport.gd` barrel file)
- No breaking changes for external code using the public API
- Improved code organization and maintainability
- Flatter structure makes navigation easier

### Performance Optimizations

1. **Subscription Sorting:** Changed from O(n log n) full sort to O(n) insertion sort when subscribing. Subscriptions are now inserted in priority order directly, improving performance for frequent subscription/unsubscription patterns.

2. **Type Resolution:** Improved consistency by prioritizing `class_name` across all resolution paths (instances, class references, GDScript scripts). Instantiates GDScript classes only when needed to extract `class_name`, improving determinism.

### Bug Fixes

1. **Metrics Recording:** Fixed double-recording bug in EventBus where metrics were recorded per-listener and again for overall operation. Now correctly records overall operation time once.

2. **Resource Cleanup:** Added automatic cleanup for `EventSignalBridge` and `CommandSignalBridge` connections via `_notification()` to prevent memory leaks when adapters are freed.

3. **Validation Logic:** Simplified Message._init() validation by removing redundant checks after assertions, improving clarity and maintainability.

4. **Middleware Consistency:** Fixed EventBus to ensure after-middleware is executed even when no listeners are registered, matching CommandBus behavior. Both buses now guarantee consistent middleware execution across all execution paths (success, errors, empty handlers/listeners).

### Type Safety Improvements

1. **Documentation:** Enhanced all code files with comprehensive GDScript documentation following best practices. Added `@param`, `@return`, and `@example` tags throughout the codebase.

2. **Documentation:** Clarified async behavior in EventBus.emit() - documented that async listeners are awaited to prevent memory leaks, even though the method doesn't return a value.

### Code Simplification

1. **Collection Package Removal:** Removed Collection package dependency from transport system. Replaced with direct array/dictionary operations using helper functions (`_remove_indices_from_array()`). Simplifies codebase and reduces dependencies.

2. **Obsolete Code Cleanup:** Removed unused `listener_start_time` variable from EventBus that was never used (leftover from planned per-listener metrics).

### API Naming Improvements

1. **Middleware Terminology:** Renamed all middleware methods from "pre/post" to "before/after" for better clarity (January 2026).

   **Changed methods:**
   - `add_middleware_pre()` → `add_middleware_before()`
   - `add_middleware_post()` → `add_middleware_after()`
   - `process_pre()` → `process_before()` (Middleware base class)
   - `process_post()` → `process_after()` (Middleware base class)
   - `as_pre_callable()` → `as_before_callable()` (Middleware base class)
   - `as_post_callable()` → `as_after_callable()` (Middleware base class)
   
   **Rationale:**
   - "Before/after" is more descriptive and self-documenting
   - Reduces confusion with "pre" potentially meaning "prefix" or other contexts
   - Better aligns with common middleware terminology in other frameworks
   - More consistent with "before-execution" and "after-execution" phrasing
   
   **Impact:**
   - Breaking change: All middleware code must be updated
   - Internal variables and methods also renamed (`_middleware_pre` → `_middleware_before`, etc.)
   - Documentation and examples updated accordingly

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

- [Transport Package README](packages/transport/README.md)
- [Developer Diary](docs/developer-diary/)
- [Tech Stack Documentation](docs/TECH_STACK.md)
- [Godot Documentation](https://docs.godotengine.org/)

