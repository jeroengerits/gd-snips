# Claude AI Context

This document provides context for AI assistants working with this codebase, including architectural decisions, patterns, and common issues.

## Project Overview

**Godot Snips** is a collection of reusable packages for Godot 4.5.1+. The project emphasizes:
- Modular architecture
- Clean code practices
- Type safety
- Domain-driven design principles

## Project Structure

All addons live under `addons/`:

```
addons/
├── engine/        # Unified entry point for all addons (Godot addon)
│   ├── plugin.cfg # Addon configuration
│   └── src/       # Source code directory
│       └── engine.gd # Public API barrel file (loads all addons)
├── event/         # Event bus system (Godot addon)
│   ├── plugin.cfg # Addon configuration
│   ├── event.gd   # Public API barrel file
│   └── src/       # Source code directory
│       ├── event_bus.gd          # EventBus class
│       ├── event.gd              # Event base class
│       ├── event_subscribers.gd  # EventSubscribers (shared infrastructure)
│       ├── event_subscriber.gd   # EventSubscriber class
│       ├── event_validator.gd    # EventValidator class
│       └── event_signal_bridge.gd # EventSignalBridge class
├── command/       # Command bus system (Godot addon)
│   ├── plugin.cfg # Addon configuration
│   ├── command.gd # Public API barrel file
│   └── src/       # Source code directory
│       ├── command_bus.gd          # CommandBus class
│       ├── command.gd              # Command base class
│       ├── command_validator.gd    # CommandValidator class
│       ├── command_signal_bridge.gd # CommandSignalBridge class
│       └── command_routing_error.gd # CommandRoutingError class
├── message/       # Message base types (Godot addon)
│   ├── plugin.cfg # Addon configuration
│   ├── message.gd # Public API barrel file
│   └── src/       # Source code directory
│       ├── message.gd              # Message base class
│       └── message_type_resolver.gd # MessageTypeResolver class
├── middleware/    # Middleware infrastructure (Godot addon)
│   ├── plugin.cfg # Addon configuration
│   ├── middleware.gd # Public API barrel file
│   └── src/       # Source code directory
│       ├── middleware.gd        # Middleware base class
│       └── middleware_entry.gd  # MiddlewareEntry class
├── utils/         # Utility functions (Godot addon)
│   ├── plugin.cfg # Addon configuration
│   ├── utils.gd   # Public API barrel file
│   └── src/       # Source code directory
│       ├── metrics_utils.gd           # MetricsUtils class
│       └── signal_connection_tracker.gd # SignalConnectionTracker class
└── support/       # Support utility functions (Godot addon)
    ├── plugin.cfg # Addon configuration
    ├── support.gd # Public API barrel file
    └── src/       # Source code directory
        ├── array.gd   # Array utility functions
        └── string.gd  # String utility functions
```

## Architectural Decisions

### Addon Organization

**Decision:** Converted packages to proper Godot addons in `addons/` directory (January 2026)

**Rationale:**
- Standard Godot addon structure enables plugin system integration
- Users can enable/disable addons through Godot's plugin interface
- Consistent with Godot ecosystem conventions
- Better discoverability and management

**Impact:**
- All preload paths use `res://addons/` prefix
- Each addon has a `plugin.cfg` configuration file
- Addons can be enabled/disabled in Project Settings → Plugins
- Documentation and examples updated accordingly
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

### Utils Addon Extraction

**Decision:** Extracted array utilities to separate `utils` addon (January 2026)

**Rationale:**
- Array utilities are generic and reusable across multiple projects
- Separating utilities from transport addon improves modularity
- Other addons can use utils without depending on transport
- Follows single responsibility principle - each addon has a focused purpose

**Implementation:**
- Created new `addons/utils/` directory with `plugin.cfg`
- Moved `array_utils.gd` from `addons/transport/utils/` to `addons/utils/` (note: transport addon was later split into separate addons)
- Updated transport addon to preload from new location
- Created README.md for utils addon

**Impact:**
- Breaking change: ArrayUtils import path changed from `res://addons/transport/utils/array_utils.gd` to `res://addons/utils/array_utils.gd`
- Transport addon now depends on utils addon (must be installed together) (note: transport addon no longer exists, replaced by separate addons)
- Array utilities can be used independently in other projects
- Better separation of concerns

**Key Insight:** Generic utilities should be in separate addons when they're reusable across projects, not just within a single addon.

**Note (January 2026):** The transport addon was later split into separate addons (event, command, message, middleware, utils). The utils addon now contains metrics utilities and signal connection tracker, while array/string utilities were moved to the support addon.

### Utils Addon Expansion

**Decision:** Expanded utils addon with StringUtils class and additional ArrayUtils methods (January 2026)

**Rationale:**
- String utilities are commonly needed across projects
- Array utilities were minimal (only 2 methods) and could benefit from functional programming helpers
- Following the same pattern as ArrayUtils ensures consistency
- Provides a comprehensive utility library for common operations

**Implementation:**
- Created `string_utils.gd` with 10 string utility methods:
  - Validation: `is_blank()`, `is_not_blank()`
  - Formatting: `pad_left()`, `pad_right()`, `truncate()`, `capitalize()`, `to_title_case()`
  - Manipulation: `remove()`, `starts_with_any()`, `ends_with_any()`
- Added 10 new methods to `array_utils.gd`:
  - Functional: `filter()`, `map()`, `find()`, `contains()`
  - Accessors: `first()`, `last()`, `unique()`
  - Manipulation: `shuffle()`, `chunk()`, `flatten()`
- Updated README.md with comprehensive API documentation
- All methods follow consistent patterns: static functions, full documentation, type safety

**Impact:**
- Utils addon now provides 22 utility methods (12 ArrayUtils + 10 StringUtils)
- More comprehensive utility library for common operations
- Functional programming patterns available for arrays (filter, map, find)
- Better developer experience with well-documented, type-safe utilities
- No breaking changes - all additions are new methods

**Key Insight:** Utility addons should grow organically based on common needs. Starting with a focused set (array operations) and expanding to related utilities (strings) maintains cohesion while providing value.

### Utils to Support Addon Rename

**Decision:** Renamed `utils` addon to `support` and simplified file names (January 2026)

**Rationale:**
- "Support" better reflects the addon's purpose as supporting utility classes
- Simpler file names (`array.gd`, `string.gd`) are more concise than `array_utils.gd`, `string_utils.gd`
- Maintains clarity while reducing verbosity
- Class references remain `ArrayUtils` and `StringUtils` via preload constants for consistency

**Implementation:**
- Renamed `addons/utils/` → `addons/support/`
- Renamed `array_utils.gd` → `array.gd`
- Renamed `string_utils.gd` → `string.gd`
- Updated plugin name from "Utils" to "Support"
- Updated all import paths in transport addon
- Updated documentation

**Impact:**
- Breaking change: Import paths changed from `res://addons/utils/array_utils.gd` to `res://addons/support/array.gd`
- Breaking change: Import paths changed from `res://addons/utils/string_utils.gd` to `res://addons/support/string.gd`
- Class usage remains the same: `const ArrayUtils = preload("res://addons/support/array.gd")`
- Transport addon updated to use new paths
- All documentation updated to reflect new structure

**Key Insight:** File names can be simplified when class references are made via preload constants. The constant name (`ArrayUtils`) provides the context, so the file name (`array.gd`) can be more concise.

### Support Barrel File Addition

**Decision:** Added `support.gd` barrel file for unified API access (January 2026)

**Rationale:**
- Consistent with transport addon pattern (`transport.gd`)
- Provides single import point for all support utilities
- Improves developer experience with namespace organization
- Enables future additions without breaking existing code

**Implementation:**
- Created `support.gd` with preloads for `ArrayUtils` and `StringUtils`
- Updated README.md to document both barrel file and individual preload patterns
- Follows same pattern as `transport.gd` barrel file

**Impact:**
- New feature: Users can now use `const Support = preload("res://addons/support/support.gd")` and access via `Support.ArrayUtils` and `Support.StringUtils`
- Backward compatible: Individual preloads still work as before
- No breaking changes - all existing code continues to work

**Key Insight:** Barrel files provide a clean namespace and single import point, improving code organization and making it easier to discover available utilities.

### Version and Author Standardization

**Decision:** Standardized all addon versions to `0.0.1` and author to `"Jeroen Gerits"` (January 2026)

**Rationale:**
- Consistent versioning across all addons
- Proper attribution for all addons
- Starting with `0.0.1` indicates early development stage
- Author field provides clear ownership information

**Implementation:**
- Updated `addons/transport/plugin.cfg`: version `1.0.0` → `0.0.1`, author `""` → `"Jeroen Gerits"` (note: transport addon was later split)
- Updated `addons/support/plugin.cfg`: version `1.0.0` → `0.0.1`, author `""` → `"Jeroen Gerits"`
- All new addons (event, command, message, middleware, utils, engine) use version `0.0.1` and author `"Jeroen Gerits"`

**Impact:**
- All addons now have consistent versioning
- Author information properly attributed
- Version `0.0.1` indicates early development stage (pre-1.0.0 release)
- No functional changes - metadata only

**Key Insight:** Consistent metadata across addons improves project professionalism and makes version management easier as the project grows.

**Note (January 2026):** The transport addon was later split into separate addons (event, command, message, middleware, utils). All addons follow the same versioning and author conventions.

### Engine Addon Creation

**Decision:** Created `engine` addon as unified entry point for all gd-snips addons (January 2026)

**Rationale:**
- Provides single import point to access all addons
- Simplifies usage: `const Engine = preload("res://addons/engine/src/engine.gd")` loads everything
- Better developer experience - one import instead of multiple
- Maintains flexibility - individual addons can still be imported separately
- Follows common pattern of meta-packages in package ecosystems

**Implementation:**
- Created `addons/engine/` directory with `plugin.cfg` (renamed from `core/` addon)
- Created `engine.gd` barrel file that preloads all addons (Event, Command, Message, Middleware, Utils, Support)
- Created README.md with usage examples
- Updated main README.md to list Engine addon first
- Updated CLAUDE.md project structure diagram

**Impact:**
- New feature: Users can now use `const Engine = preload("res://addons/engine/src/engine.gd")` to access all addons
- Access pattern: `Engine.Command.Bus`, `Engine.Event.Bus`, `Engine.Support.Array`, etc.
- Backward compatible: Individual addon imports still work
- No breaking changes - all existing code continues to work (after migration from transport addon)
- Engine addon depends on all other addons (must be installed together)

**Key Insight:** A meta-addon provides convenience without forcing a specific usage pattern. Users can choose between the unified Engine import or individual addon imports based on their needs.

**Note (January 2026):** The transport addon was later split into separate addons (event, command, message, middleware, utils). The engine addon now loads these separate addons instead of a single transport addon.

### Source Directory Reorganization

**Decision:** Moved all source code into `src/` subdirectories within each addon (January 2026)

**Rationale:**
- Separates source code from configuration and documentation files
- Cleaner addon root directory (only plugin.cfg, barrel file)
- Follows common project structure patterns
- Makes it clear which files are source code vs. metadata
- Easier to exclude source from certain operations if needed

**Implementation:**
- Created `addons/transport/src/` and moved all source files into it (note: transport addon was later split)
- Created `addons/support/src/` and moved array.gd and string.gd into it
- Updated all preload paths in source files to include `src/` prefix
- Updated barrel files (transport.gd, support.gd) to reference new paths
- Updated plugin.cfg script paths to `./src/transport.gd` and `./src/support.gd`
- Barrel files remain at addon root for public API access

**Impact:**
- Breaking change: All direct source file imports now require `src/` prefix
  - Old: `res://addons/transport/command/command_bus.gd`
  - New: `res://addons/transport/src/command/command_bus.gd` (note: transport addon no longer exists)
- Barrel file imports unchanged: `res://addons/transport/transport.gd` still works (at the time)
- Internal preload paths updated throughout codebase
- Cleaner addon structure with clear separation of concerns

**Key Insight:** Using `src/` directories provides better organization and makes the addon structure more professional. Barrel files at the root maintain backward compatibility for public API access while internal structure is organized.

**Note (January 2026):** The transport addon was later split into separate addons (event, command, message, middleware, utils), each with their own `src/` directory structure.

### Subscribers Architecture Refactoring

**Decision:** Moved Subscribers from `event/` to `core/` directory and removed EventValidator dependency (January 2026)

**Rationale:**
- Subscribers is shared infrastructure used by both CommandBus and EventBus, not event-specific code
- Location in `event/` folder was misleading and created false dependency impression
- Removing EventValidator dependency from Subscribers improves separation of concerns (priority sorting is generic logic, not event-specific validation)

**Implementation:**
- Moved `event/subscribers.gd` → `core/subscribers.gd` (later moved to `event/event_subscribers.gd`)
- Extracted priority sorting logic to `_sort_by_priority()` method in Subscribers class (later moved to ArrayUtils, then extracted to separate support addon, originally named `utils`)
- Removed EventValidator dependency from Subscribers (was only used for sorting middleware)
- Inlined lifecycle validation in EventSubscriber class (removed EventValidator dependency)
- Updated imports in command_bus.gd and event_bus.gd to use new path
- Later renamed `Subscriber` to `EventSubscriber` for clarity (distinguishes from `Subscribers` infrastructure class)
- Final reorganization: Moved to `event/event_subscribers.gd` when `core/` directory was removed

**Impact:**
- Better architectural clarity - shared infrastructure explicitly separated
- Reduced coupling - Subscribers no longer depends on event-specific validators
- No breaking changes - public API unchanged (Subscribers is internal implementation)
- Improved maintainability - clearer separation between shared and domain-specific code
- Final structure: EventSubscribers in `event/` directory (organizes by functional domain)

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
- `engine/engine.gd` → `event/event.gd`, `command/command.gd`, `message/message.gd`, `middleware/middleware.gd`, `utils/utils.gd`, `support/support.gd`
- `event/event.gd` → `event_bus.gd`, `event.gd`, `event_signal_bridge.gd`
- `command/command.gd` → `command_bus.gd`, `command.gd`, `command_signal_bridge.gd`
- `support/support.gd` → `array.gd`, `string.gd`

### Addon Architecture

**Layered Design:**
```
Public API (CommandBus/EventBus via Engine addon)
    ↓
Shared Infrastructure (EventSubscribers in event/, Message/MessageTypeResolver in message/, Middleware in middleware/)
    ↓
Domain Rules (Validator classes in command/ and event/)
    ↓
Base Types (Command, Event in their respective addons)
```

**Key Patterns:**
- **Barrel Files:** Each addon has a main entry point (e.g., `engine.gd`, `event.gd`, `command.gd`, `support.gd`)
- **Unified Entry Point:** Engine addon provides single import for all addons (`Engine.Command.Bus`, `Engine.Event.Bus`)
- **Shared Infrastructure:** EventSubscribers in event addon (used by both CommandBus and EventBus), Message infrastructure in message addon, middleware in middleware addon
- **Domain Rules:** Business logic separated into validation classes (Validator in command/, Validator in event/)
- **Lifecycle Binding:** Subscriptions auto-cleanup when bound objects are freed
- **Type Resolution:** Handles Godot's type system complexity transparently (prioritizes `class_name`) via MessageTypeResolver in message addon
- **Organized Structure:** Each addon is a separate module with clear separation by domain (event/, command/, message/, middleware/, utils/, support/)
- **Utilities:** Generic helper functions in `utils/` addon (MetricsUtils, SignalConnectionTracker) and `support/` addon (Array, String)
- **Modular Design:** Addons can be used independently or through the unified Engine entry point

**Note (January 2026):** The transport addon was split into separate addons (event, command, message, middleware, utils) for better modularity and separation of concerns.

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

**Addon Import (Barrel Files):**
```gdscript
# Engine addon (unified entry point)
const Engine = preload("res://addons/engine/src/engine.gd")
var command_bus = Engine.Command.Bus.new()
var event_bus = Engine.Event.Bus.new()

# Support addon
const Support = preload("res://addons/support/support.gd")
Support.Array.remove_indices(arr, [1, 3])
Support.String.is_blank("   ")
```

**Direct Import (for internal files):**
```gdscript
const EventSubscribers = preload("res://addons/event/src/event_subscribers.gd")
const MessageTypeResolver = preload("res://addons/message/src/message_type_resolver.gd")
const Array = preload("res://addons/support/src/array.gd")
```

**Note:** Collection package was removed (January 2026). Array utilities were extracted to separate `support` addon (January 2026, renamed from `utils`). The support addon includes both `Array` (12 methods) and `String` (10 methods) for common operations. Use direct GDScript array/dictionary operations or utilities from the support addon.

**Note (January 2026):** The transport addon was split into separate addons. EventSubscribers is now in the event addon, MessageTypeResolver is in the message addon.

### Transport Patterns

**Command Pattern:**
- Exactly one handler per command type
- Returns result or CommandRoutingError
- Use for imperative actions
- Handler registration via `handle()`, removal via `unregister_handler()`

**Event Pattern:**
- Zero or more listeners
- Sequential delivery in priority order
- Async listeners are awaited to prevent memory leaks (may block briefly)
- Use for notifications
- Both `emit()` and `emit_and_await()` await async listeners (difference is explicitness)

**Debugging:**
- `set_verbose(true)` - Enable detailed operation logging
- `set_trace_enabled(true)` - Enable execution flow tracing
- `set_log_listener_calls(true)` - Log each listener call (EventBus only)
- `set_metrics_enabled(true)` - Enable performance metrics tracking
- `MessageTypeResolver.set_verbose(true)` - Enable verbose warnings for type resolution issues (development only)

## Common Issues and Solutions

### Issue: Preload Path Errors

**Symptom:** `preload()` fails with "Resource not found"

**Solution:** Ensure all paths use `res://addons/` prefix:
- ✅ `res://addons/engine/src/engine.gd` (unified entry point)
- ✅ `res://addons/event/event.gd` (individual addon)
- ✅ `res://addons/command/command.gd` (individual addon)
- ❌ `res://transport/transport.gd` (missing addons/ prefix)
- ❌ `res://packages/transport/transport.gd` (old path, no longer valid)
- ❌ `res://addons/transport/transport.gd` (transport addon no longer exists, split into separate addons)

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

### Issue: SignalBridge Connection Handling (Fixed)

**Symptom:** Signal connections not being cleaned up, memory leaks, duplicate callbacks

**Solution:** In Godot 4, `Object.connect()` returns an `Error` code (OK == 0), not a boolean. Always check the return value correctly:
```gdscript
# ✅ Correct pattern
var err: int = source.connect(signal_name, callback)
if err != OK:
    push_error("Failed to connect signal: %s (error: %d)" % [signal_name, err])
    return

# ❌ Incorrect pattern (treats success as failure)
if not source.connect(signal_name, callback):
    # This executes on SUCCESS, which is wrong!
```

**Note:** This was fixed in `CommandSignalBridge` and `EventSignalBridge` (January 2026). Both now properly track connections for cleanup via `disconnect_all()`.

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

### Addon Conversion

**Decision:** Converted from `packages/` to `addons/` structure (January 2026)

**Rationale:**
- Proper Godot addon structure enables plugin system integration
- Users can enable/disable addons through Project Settings → Plugins
- Standard Godot ecosystem convention
- Better integration with Godot's plugin management

**Implementation:**
- Moved all files from `packages/transport/` to `addons/transport/` (note: transport addon was later split)
- Created `plugin.cfg` configuration file for each addon
- Updated all preload paths from `res://packages/transport/` to `res://addons/transport/`
- Updated documentation and examples with new paths
- Removed obsolete `packages/` directory

**Impact:**
- Breaking change: All import paths changed from `res://packages/` to `res://addons/`
- Users must update their code to use new paths
- Addons can now be enabled/disabled through Godot's plugin interface
- Better alignment with Godot ecosystem standards

**Note (January 2026):** The transport addon was later split into separate addons (event, command, message, middleware, utils). All addons now follow the same `addons/{name}/` structure.

### Middleware Directory Organization

**Decision:** Organized Middleware and MiddlewareEntry in dedicated `middleware/` directory (January 2026)

**Rationale:**
- Middleware is a distinct functional domain with its own concerns
- Clear separation of middleware infrastructure from other domains
- Better organization by functional area rather than generic "core" folder
- Easier to locate and understand middleware-related code

**Implementation:**
- Middleware base class in `middleware/middleware.gd`
- MiddlewareEntry in `middleware/middleware_entry.gd`
- Updated preload paths in all files using middleware
- Part of broader reorganization that removed `core/` directory

**Impact:**
- Internal change only (Middleware is exported via barrel file, path change is transparent)
- No breaking changes to public API
- Improved organizational clarity - functional domains clearly separated
- Cleaner, more intuitive folder structure

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
4. Consolidated: `type/`, `utils/`, `event/`, `command/` (singular folder names)
5. Reorganized: Removed `type/` directory, moved files to domain-specific directories (January 2026)
6. Further refined: Removed `core/` directory, organized by functional domain (January 2026)

**Current Structure (as separate addons):**
- `addons/event/` - EventBus, Event, EventSubscribers, EventSubscriber, Validator, EventSignalBridge
- `addons/command/` - CommandBus, Command, Validator, CommandSignalBridge, CommandRoutingError
- `addons/message/` - Message base class, MessageTypeResolver
- `addons/middleware/` - Middleware base class, MiddlewareEntry
- `addons/utils/` - Metrics utilities, SignalConnectionTracker

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

5. **SignalBridge Connect/Disconnect Bug Fix:** Fixed critical bug in both `CommandSignalBridge` and `EventSignalBridge` where `Object.connect()` return value was incorrectly handled (January 2026).
   - **Issue:** `connect()` returns `Error` code (OK == 0), but code checked `if not source.connect(...)` which treated success (0) as failure
   - **Impact:** Connections were made but not tracked, causing:
     - Memory leaks (connections couldn't be cleaned up via `disconnect_all()`)
     - Potential duplicate callbacks if reconnected
     - Errors logged even on successful connections
   - **Fix:** Changed to `var err: int = source.connect(...); if err != OK:` pattern
   - **Additional:** Added `is_connected()` check before disconnecting in `disconnect_all()` for safety

6. **CommandSignalBridge Missing Import:** Added missing `Command` preload in `CommandSignalBridge` to fix type check compilation issue (January 2026).

7. **MessageTypeResolver Performance Optimization:** Refactored to avoid script instantiation when resolving GDScript class references (January 2026).
   - **Issue:** Previous implementation called `script.new()` to get `class_name`, which:
     - Could cause side effects (constructor execution)
     - Allocated unnecessary objects
     - Was slow in hot paths
   - **Fix:** Use `script.get_global_name()` instead, which returns `class_name` without instantiation
   - **Impact:** Faster type resolution, no side effects, no unnecessary allocations

### Type Safety Improvements

1. **Documentation:** Enhanced all code files with comprehensive GDScript documentation following best practices. Added `@param`, `@return`, and `@example` tags throughout the codebase.

2. **Documentation:** Clarified async behavior in EventBus.emit() - documented that async listeners are awaited to prevent memory leaks, even though the method doesn't return a value.

3. **Phase 1 Refactoring (January 2026):** Comprehensive type safety and developer experience improvements.
   - **Type Annotations:** Added `Variant` type annotations to `CommandBus.handle()`, `EventBus.on()`, and related methods with runtime type validation
   - **Error Messages:** Enhanced `MessageTypeResolver` with verbose warnings and better error context, added `MessageTypeResolver.set_verbose()` for development debugging
   - **Warning Suppression:** Added `@warning_ignore("unused_parameter")` annotations for intentional patterns in signal bridge callbacks
   - **Documentation:** Enhanced all public APIs with complete `@param`, `@return`, and `@example` annotations for better IDE support
   - **Impact:** Improved type safety, better error messages for debugging, cleaner compiler output, enhanced IDE autocomplete and documentation
   - **No Breaking Changes:** All improvements are additive and maintain backward compatibility

4. **Phase 2 Refactoring (January 2026):** Performance optimizations and enhanced error handling.
   - **Registration Lookup Optimization:** Removed redundant array duplication in `EventBus.emit()` - `_get_valid_registrations()` already returns a snapshot, eliminating double duplication
   - **Cleanup Tracking:** `_cleanup_invalid_registrations()` now returns bool indicating if cleanup occurred (enables future optimizations)
   - **Type Resolution Enhancement:** Improved error messages for edge cases (missing script paths, no class_name) with better context for debugging
   - **Impact:** Reduced memory allocations in hot paths (event emission), better debugging information for type resolution issues
   - **No Breaking Changes:** All optimizations are internal and maintain backward compatibility

### Code Simplification

1. **Collection Package Removal:** Removed Collection package dependency from transport system. Replaced with direct array/dictionary operations using helper functions (`_remove_indices_from_array()`). Simplifies codebase and reduces dependencies.

2. **Obsolete Code Cleanup:** Removed unused `listener_start_time` variable from EventBus that was never used (leftover from planned per-listener metrics).

### Architecture Improvements

1. **Subscribers Refactoring:** Reorganized Subscribers (now EventSubscribers) and removed EventValidator dependency (January 2026).
   - Moved to `event/event_subscribers.gd` as part of domain-based organization
   - Better architectural clarity - shared infrastructure explicitly separated
   - Reduced coupling between shared code and domain-specific validators
   - Improved maintainability with clearer separation of concerns

2. **SignalBridge Connection Management Extraction:** Extracted shared connection management logic to `SignalConnectionTracker` utility class (January 2026).
   - Eliminated code duplication between `CommandSignalBridge` and `EventSignalBridge`
   - Single source of truth for connection tracking and cleanup
   - Consistent behavior across both bridge classes
   - Easier to extend with new connection management features

3. **Type Resolution API Cleanup:** Removed unnecessary wrapper methods from `Subscribers` class (January 2026).
   - Direct use of `MessageTypeResolver.resolve_type()` throughout codebase
   - Clearer API surface (one way to resolve types)
   - Reduced indirection and improved code clarity
   - Updated `CommandBus`, `EventBus`, and `Subscribers` to use direct resolver calls

4. **Utility Function Organization:** Moved generic array utilities to `utils/array_utils.gd` (January 2026), later extracted to separate addon (January 2026). Expanded with StringUtils (10 methods) and additional ArrayUtils methods (10 new methods, 12 total) in January 2026.
   - `_remove_indices_from_array()` and `_sort_by_priority()` extracted to reusable utility
   - Added functional programming helpers: `filter()`, `map()`, `find()`, `contains()`
   - Added convenience methods: `first()`, `last()`, `unique()`, `shuffle()`, `chunk()`, `flatten()`
   - Added string utilities: validation, formatting, manipulation methods
   - Better organization - utilities belong in utils/ not domain classes
   - Reusable across codebase without coupling to Subscribers
   - Improved Single Responsibility Principle adherence
   - **Later:** Extracted to separate `utils` addon for better modularity and reusability

### API Naming Improvements

1. **EventSubscriber Class Rename:** Renamed `Subscriber` to `EventSubscriber` (class and filename) (January 2026).
   - **Rationale:** Makes it explicit that this class is event-specific (used by EventBus)
   - **Benefit:** Avoids confusion with the `Subscribers` class (shared infrastructure)
   - **Changed:** `subscriber.gd` → `event_subscriber.gd`, `class_name Subscriber` → `class_name EventSubscriber`
   - **Impact:** Internal change only (EventSubscriber is not part of public API), improves code clarity

2. **Middleware Terminology:** Renamed all middleware methods from "pre/post" to "before/after" for better clarity (January 2026).

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
2. **Type Safety:** More compile-time checks for message types (require class_name validation) - *Partially addressed in Phase 1 with runtime validation*
3. **Performance Metrics:** Enhanced profiling options (per-listener breakdown, slow handler warnings)
4. **Thread Safety:** Document thread-safety assumptions (currently single-threaded)
5. **Phase 2 Refactoring:** Performance optimizations (reduce array duplication, cache cleaned registrations) - *Completed (January 2026)*

### Breaking Changes Policy

- Major refactors documented in developer diary
- Path changes (like packages/ move) are breaking but documented
- Method renames maintain backward compatibility where possible
- API changes follow semantic versioning principles

## Code Quality & Architecture

### Code Review (January 2026)

A comprehensive code review was performed analyzing the transport package against CLEAN Code and SOLID principles. Key findings:

- **Single Responsibility Principle:** Some classes manage multiple concerns (addressed through refactoring)
- **DRY Violations:** Duplicated connection management logic in SignalBridge classes (addressed - extracted to SignalConnectionTracker)
- **API Consistency:** Unnecessary wrapper methods for type resolution (addressed - direct MessageTypeResolver usage)
- **Utility Organization:** Generic utilities placed in domain classes (addressed - moved to utils/)

**Refactoring Results:** High-priority improvements have been implemented:
- SignalBridge connection management extracted to reusable utility
- Type resolution API cleaned up (removed wrapper methods)
- Array utilities moved to utils/ for better organization, later extracted to separate support addon (renamed from `utils` in January 2026)
- Support addon expanded with StringUtils (10 methods) and additional ArrayUtils methods (10 new methods, 12 total) in January 2026

The codebase demonstrates solid architectural thinking with good separation of concerns. Remaining recommendations focus on incremental refactoring for better maintainability rather than correctness issues.

## References

- [Main README](README.md) - Consolidated documentation for all addons
- [Developer Diary](docs/developer-diary/)
- [Tech Stack Documentation](docs/TECH_STACK.md)
- [Code Review](CODE_REVIEW.md) - CLEAN Code and SOLID principles analysis
- [Godot Documentation](https://docs.godotengine.org/)

