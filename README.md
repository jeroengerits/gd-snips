# Godot Snips

Reusable addons for **Godot 4.5.1+** with a focus on modular architecture and clean code.

## Installation

### Install All Addons

To install all gd-snips addons at once:

1. Copy the entire `addons/` directory from this repository into your Godot project's `addons/` folder
2. Open your project in Godot
3. Go to **Project → Project Settings → Plugins**
4. Enable the "Core" plugin

When you install the Core addon, all addons (Transport, Support) are automatically available. The Core addon provides a unified entry point to access all functionality.

**Requirements:** Godot 4.5.1 or later

## Quick Start

Load all addons with a single import:

```gdscript
const Core = preload("res://addons/core/src/core.gd")

# Access Transport addon
var command_bus = Core.CommandBus.new()
var event_bus = Core.EventBus.new()

# Access Support addon
Core.Support.Array.remove_indices(arr, [1, 3])
Core.Support.String.is_blank("   ")
```

Or import addons individually:

```gdscript
const Transport = preload("res://addons/transport/transport.gd")
const Support = preload("res://addons/support/support.gd")
```

---

## Core Addon

Unified entry point for all gd-snips addons. Load all addons with a single import.

### Usage

```gdscript
const Core = preload("res://addons/core/src/core.gd")

# Access Transport addon
var command_bus = Core.CommandBus.new()
var event_bus = Core.EventBus.new()

# Access Support addon
Core.Support.Array.remove_indices(arr, [1, 3])
Core.Support.String.is_blank("   ")
```

### Available Addons

- **Transport** - Type-safe command/event transport framework
- **Support** - Utility functions for array and string operations

---

## Transport Addon

A message transport framework for Godot 4.5.1+ that helps you build clean, decoupled game architectures.

### Overview

Transport provides a centralized messaging system for communication between different parts of your game. Instead of tightly coupling systems together, you send **commands** (actions to perform) and **events** (notifications of things that occurred) through centralized buses.

This approach decouples systems by removing direct dependencies while preserving compile-time type safety, predictable execution order, and easier debugging through built-in metrics and tracing.

### Features

- ✅ **Type-safe** - Compile-time type checking for commands and events
- ✅ **Commands** - Exactly one handler per command (no ambiguity)
- ✅ **Events** - Zero or more listeners (flexible broadcasting)
- ✅ **Priority-based** - Control execution order with priorities
- ✅ **Lifecycle-aware** - Automatic cleanup when objects are freed
- ✅ **Middleware** - Intercept and process messages before/after execution
- ✅ **Metrics** - Built-in performance tracking and introspection
- ✅ **Scene-tree independent** - Works with any `RefCounted` objects

### Quick Start

Here's a minimal example to get you started:

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

# Create bus instances
var command_bus = Transport.CommandBus.new()
var event_bus = Transport.EventBus.new()

# Register a command handler
command_bus.handle(MovePlayerCommand, func(command):
    player.move_to(command.target_position)
    return true
)

# Subscribe to an event
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy ", event.enemy_id, " died!")
)

# Use them
await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
```

### Core Concepts

#### Commands

Commands represent actions that need to happen. Think: **"Do this."**

- **One handler only** - Each command type has exactly one handler
- **Returns a result** - Handlers can return data or errors
- **Clear ownership** - No ambiguity about who handles what

**Good for:** Moving the player, saving the game, applying damage, etc.

#### Events

Events announce that something happened. Think: **"This happened."**

- **Zero or more listeners** - No listeners? Fine. Many listeners? Also fine.
- **Priority-based** - Higher priority listeners run first
- **Sequential execution** - Each listener completes before the next starts

**Good for:** Enemy died, player health changed, level completed, etc.

### Usage Guide

#### Creating Commands

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

#### Creating Events

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

#### CommandBus

The `CommandBus` ensures exactly one handler processes each command.

**Register a handler:**

```gdscript
command_bus.handle(MovePlayerCommand, func(command):
    player.move_to(command.target_position)
    return true
)
```

**Dispatch a command:**

```gdscript
var result = await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))

# Check for errors
if result is Transport.CommandRoutingError:
    print("Command failed: ", result.message)
else:
    print("Command succeeded: ", result)
```

**Error types:**

- `NO_HANDLER` - No handler registered for this command
- `MULTIPLE_HANDLERS` - Multiple handlers registered (shouldn't happen)
- `HANDLER_FAILED` - Handler execution failed or was cancelled

**Unregister handler:**

```gdscript
# Remove handler for a command type
command_bus.unregister_handler(MovePlayerCommand)
```

#### EventBus

The `EventBus` broadcasts events to all subscribers.

**Subscribe to events:**

```gdscript
# Basic subscription
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy died: ", event.enemy_id)
)

# With priority (higher numbers run first)
event_bus.on(EnemyDiedEvent, _handle_enemy_died, priority=10)

# One-shot (auto-unsubscribes after first call)
event_bus.on(EnemyDiedEvent, _on_first_enemy_death, once=true)

# Lifecycle-bound (auto-unsubscribes when owner is freed)
event_bus.on(EnemyDiedEvent, _update_ui, owner=self)
```

**Emit events:**

```gdscript
# Fire and forget (still awaits async listeners to prevent memory leaks)
event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))

# Explicitly await all async listeners (same behavior, but more explicit)
await event_bus.emit_and_await(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
```

**Note:** Both `emit()` and `emit_and_await()` await async listeners to prevent memory leaks. The difference is that `emit_and_await()` makes the async behavior explicit in your code.

**Unsubscribe:**

```gdscript
# By callable
event_bus.unsubscribe(EnemyDiedEvent, _my_listener)

# By subscription ID (for anonymous functions)
var sub_id = event_bus.on(EnemyDiedEvent, func(event): print("Event!"))
event_bus.unsubscribe_by_id(EnemyDiedEvent, sub_id)
```

#### Middleware

Middleware lets you intercept messages before and after they're processed. Useful for logging, validation, timing, and other cross-cutting concerns.

**Using callables:**

```gdscript
# Before-execution middleware (can cancel by returning false)
command_bus.add_middleware_before(func(cmd: Command):
    print("Before: ", cmd)
    return true  # Return false to cancel
, priority=0)

# After-execution middleware
command_bus.add_middleware_after(func(cmd: Command, result):
    print("After: ", result)
, priority=0)

# Remove middleware
var mw_id = command_bus.add_middleware_before(my_callback)
command_bus.remove_middleware(mw_id)
```

**Using the Middleware class:**

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

class LoggingMiddleware extends Transport.Middleware:
    func process_before(message: Transport.Message, message_key: StringName) -> bool:
        print("[Middleware] Before: ", message_key, " - ", message)
        return true
    
    func process_after(message: Transport.Message, message_key: StringName, result: Variant) -> void:
        print("[Middleware] After: ", message_key, " - Result: ", result)

# Use it
var logging_mw = LoggingMiddleware.new(priority=10)
command_bus.add_middleware_before(logging_mw.as_before_callable(), logging_mw.priority)
command_bus.add_middleware_after(logging_mw.as_after_callable(), logging_mw.priority)
```

#### Metrics

Track performance and usage patterns:

```gdscript
# Enable metrics
command_bus.set_metrics_enabled(true)
event_bus.set_metrics_enabled(true)

# Get metrics for a specific type
var metrics = command_bus.get_metrics(MovePlayerCommand)
# Returns: {
#   "count": 42,
#   "total_time": 123.4,
#   "min_time": 0.5,
#   "max_time": 5.2,
#   "avg_time": 2.94
# }

# Get all metrics
var all_metrics = command_bus.get_all_metrics()
```

#### Debugging & Logging

Enable verbose logging and tracing for development:

```gdscript
# Enable verbose logging (detailed operation logs)
command_bus.set_verbose(true)
event_bus.set_verbose(true)

# Enable trace logging (execution flow details)
command_bus.set_trace_enabled(true)
event_bus.set_trace_enabled(true)

# Enable listener call logging (EventBus only - logs each listener invocation)
event_bus.set_log_listener_calls(true)

# Enable type resolution verbose warnings (for debugging type resolution issues)
Transport.MessageTypeResolver.set_verbose(true)
```

**Verbose logging** shows detailed information about operations (handler registration, middleware execution, etc.).  
**Trace logging** shows execution flow (dispatch/emit operations, listener counts, etc.).  
**Listener call logging** logs each individual listener call, useful for debugging listener execution order and errors.  
**Type resolution verbose mode** shows warnings when types are resolved from script paths instead of `class_name`, helping identify missing `class_name` declarations.

#### Signal Integration

Transport is designed as an alternative to Godot signals, but you can bridge between them when needed.

**When to use Transport:**

- Business logic and domain events
- Cross-system communication
- Commands that need exactly one handler
- Situations requiring priority ordering or middleware

**When to use signals:**

- UI interactions (button clicks, input)
- Scene tree lifecycle events
- Godot's built-in events (`area_entered`, `body_entered`, etc.)
- Third-party plugin integrations

**Bridging signals to Transport:**

```gdscript
const Transport = preload("res://addons/transport/transport.gd")

# Event bridge
var event_bus = Transport.EventBus.new()
var bridge = Transport.EventSignalBridge.new(event_bus)
bridge.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Command bridge
var command_bus = Transport.CommandBus.new()
var cmd_bridge = Transport.CommandSignalBridge.new(command_bus)
cmd_bridge.connect_signal_to_command(
    $SaveButton,
    "pressed",
    SaveGameCommand,
    func(): return SaveGameCommand.new()
)

# Clean up (happens automatically when bridge is freed)
bridge.disconnect_all()
```

### Best Practices

#### Command Design

- Use commands for actions that need to happen
- Keep handlers focused on one responsibility
- Return meaningful results
- Handle errors gracefully

#### Event Design

- Use events for notifications about things that already happened
- Keep listeners small and focused
- Avoid side effects in listeners
- Consider priority when order matters

#### Subscription Management

- Use `owner=self` for automatic cleanup
- Explicitly unsubscribe for long-lived objects
- Watch for memory leaks if not using lifecycle binding

#### Development & Debugging

- Enable metrics in development
- Use middleware for logging during development
- Monitor performance in production
- Use trace logging to understand execution flow

### Architecture

**Command Flow:**

```
Input → CommandBus → Validation → Single Handler → Result/Error
```

**Event Flow:**

```
Emit → EventBus → Middleware → Listeners (priority order) → Done
```

**Key Components:**

- `CommandBus` - Dispatches commands with single-handler guarantee
- `EventBus` - Broadcasts events to zero or more subscribers
- `Middleware` - Intercepts messages before/after processing
- `CommandSignalBridge` / `EventSignalBridge` - Bridge Godot signals to Transport

### Design Principles

- **Explicitness over "magic"** - Clear, explicit APIs over hidden behavior
- **Deterministic behavior** - Predictable execution order
- **Debuggability first** - Metrics, tracing, and clear error messages
- **Type safety** - Leverage Godot's type system for compile-time checks

---

## Support Addon

Support functions for Godot 4.5.1+.

### Usage

You can use the barrel file to load all support utilities at once:

```gdscript
const Support = preload("res://addons/support/support.gd")

# Access utilities via Support namespace
Support.Array.remove_indices(arr, [1, 3])
Support.String.is_blank("   ")
```

Or preload individual utilities:

```gdscript
const Array = preload("res://addons/support/src/array.gd")
const String = preload("res://addons/support/src/string.gd")

# Array operations
var arr = [1, 2, 3, 4, 5]
Array.remove_indices(arr, [1, 3])
# arr is now [1, 3, 5]

var entries = [Entry.new(priority=5), Entry.new(priority=10), Entry.new(priority=3)]
Array.sort_by_priority(entries)
# entries are now sorted: priority 10, 5, 3

var numbers = [1, 2, 3, 4, 5]
var evens = Array.filter(numbers, func(n): return n % 2 == 0)  # [2, 4]
var doubled = Array.map(numbers, func(n): return n * 2)  # [2, 4, 6, 8, 10]
var found = Array.find(numbers, func(n): return n > 3)  # 4
var unique = Array.unique([1, 2, 2, 3, 1])  # [1, 2, 3]

# String operations
String.is_blank("   ")  # true
String.pad_left("42", 5, "0")  # "00042"
String.truncate("Hello World", 8)  # "Hello..."
String.to_title_case("hello world")  # "Hello World"
```

### API Reference

#### Array

##### `remove_indices(array: Array, indices: Array) -> void`

Safely removes items from an array at the specified indices. Indices are sorted and removed from highest to lowest to avoid index shifting issues.

**Parameters:**
- `array`: The array to remove items from (modified in place)
- `indices`: Array of integer indices to remove (can be unsorted)

##### `sort_by_priority(items: Array) -> void`

Sorts an array of items by their `priority` property in descending order (higher priority first).

**Parameters:**
- `items`: Array of items with a `priority` property (modified in place)

**Note:** Items must have a `priority` property (int) for this function to work correctly.

##### `filter(array: Array, predicate: Callable) -> Array`

Filters array elements matching predicate. Returns a new array containing only elements where the predicate returns `true`.

**Parameters:**
- `array`: The array to filter
- `predicate`: Callable that takes `(item)` and returns `bool`

##### `map(array: Array, mapper: Callable) -> Array`

Transforms array elements using mapper function. Returns a new array with transformed elements.

**Parameters:**
- `array`: The array to transform
- `mapper`: Callable that takes `(item)` and returns transformed value

##### `find(array: Array, predicate: Callable) -> Variant`

Finds first element matching predicate. Returns the first matching element, or `null` if not found.

**Parameters:**
- `array`: The array to search
- `predicate`: Callable that takes `(item)` and returns `bool`

##### `contains(array: Array, predicate: Callable) -> bool`

Checks if array contains element matching predicate. Returns `true` if any element matches, `false` otherwise.

**Parameters:**
- `array`: The array to check
- `predicate`: Callable that takes `(item)` and returns `bool`

##### `unique(array: Array) -> Array`

Removes duplicate elements from array. Returns a new array with duplicates removed, preserving order of first occurrence.

**Parameters:**
- `array`: The array to deduplicate

##### `first(array: Array) -> Variant`

Gets first element of array. Returns the first element, or `null` if array is empty.

**Parameters:**
- `array`: The array to get first element from

##### `last(array: Array) -> Variant`

Gets last element of array. Returns the last element, or `null` if array is empty.

**Parameters:**
- `array`: The array to get last element from

##### `shuffle(array: Array) -> void`

Shuffles array elements randomly using Fisher-Yates algorithm. Modifies the array in place.

**Parameters:**
- `array`: The array to shuffle (modified in place)

##### `chunk(array: Array, chunk_size: int) -> Array`

Splits array into chunks of specified size. Returns an array of arrays, each containing up to `chunk_size` elements.

**Parameters:**
- `array`: The array to chunk
- `chunk_size`: Size of each chunk

##### `flatten(array: Array, depth: int = -1) -> Array`

Flattens nested arrays into single array. Returns a new flattened array.

**Parameters:**
- `array`: Array that may contain nested arrays
- `depth`: Maximum depth to flatten (default: -1 for unlimited)

#### String

##### `is_blank(str: String) -> bool`

Checks if string is empty or contains only whitespace.

##### `is_not_blank(str: String) -> bool`

Checks if string is not empty and contains non-whitespace characters.

##### `pad_left(str: String, length: int, pad_char: String = " ") -> String`

Pads string to specified length with character (left-pad).

##### `pad_right(str: String, length: int, pad_char: String = " ") -> String`

Pads string to specified length with character (right-pad).

##### `truncate(str: String, max_length: int, ellipsis: String = "...") -> String`

Truncates string to maximum length with optional ellipsis.

##### `capitalize(str: String) -> String`

Capitalizes first character of string.

##### `to_title_case(str: String) -> String`

Converts string to title case (capitalize first letter of each word).

##### `remove(str: String, substring: String) -> String`

Removes all occurrences of substring from string.

##### `starts_with_any(str: String, prefixes: Array) -> bool`

Checks if string starts with any of the given prefixes.

##### `ends_with_any(str: String, suffixes: Array) -> bool`

Checks if string ends with any of the given suffixes.

---

## Contributing

Contributions are welcome! Here's how you can help:

- **Report bugs** - Open an issue if you find a bug
- **Suggest features** - Share your ideas for improvements
- **Submit pull requests** - Code contributions are appreciated
- **Improve documentation** - Help make the docs clearer

When contributing:

- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Be respectful and constructive in discussions

## License

[Add license information here]

---

**Need help?** Check the [developer documentation](CLAUDE.md) for architectural decisions and patterns.
