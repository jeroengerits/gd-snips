# Godot Snips

Reusable addons for **Godot 4.5.1+** with a focus on modular architecture and clean code.

## Installation

### Install All Addons

To install all gd-snips addons at once:

1. Copy the entire `addons/` directory from this repository into your Godot project's `addons/` folder
2. Open your project in Godot
3. Go to **Project → Project Settings → Plugins**
4. Enable the **"Engine"** plugin (this is the only plugin that needs to be enabled)

When you enable the Engine plugin, all addons (Message, Middleware, Utils, Event, Command, Support) are automatically loaded and available. The Engine addon is the single entry point that loads all other addons as libraries. You should not enable any other plugins - only Engine.

**Requirements:** Godot 4.5.1 or later

## Quick Start

Load all addons with a single import:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

# Access Command addon
var command_bus = Engine.Command.Bus.new()

# Access Event addon
var event_bus = Engine.Event.Bus.new()

# Access Support addon
Engine.Support.Array.remove_indices(arr, [1, 3])
Engine.Support.String.is_blank("   ")
```

---

## Engine Addon

Unified entry point for all gd-snips addons. Load all addons with a single import.

### Usage

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

# Access Command addon
var command_bus = Engine.Command.Bus.new()

# Access Event addon
var event_bus = Engine.Event.Bus.new()

# Access Support addon
Engine.Support.Array.remove_indices(arr, [1, 3])
Engine.Support.String.is_blank("   ")
```

### Available Addons

- **Message** - Base message types for command/event systems
- **Middleware** - Middleware infrastructure for message processing
- **Utils** - Utility functions for transport systems
- **Event** - Event bus and event message types
- **Command** - Command bus and command message types
- **Support** - Utility functions for array and string operations

---

## Event Addon

Event bus system for Godot 4.5.1+ that helps you build clean, decoupled game architectures through event-driven communication.

### Overview

The Event addon provides a centralized event broadcasting system for communication between different parts of your game. Instead of tightly coupling systems together, you emit **events** (notifications of things that occurred) through a centralized bus, and multiple listeners can subscribe to react to those events.

This approach decouples systems by removing direct dependencies while preserving compile-time type safety, predictable execution order, and easier debugging through built-in metrics and tracing.

### Features

- ✅ **Type-safe** - Compile-time type checking for events
- ✅ **Zero or more listeners** - Flexible broadcasting
- ✅ **Priority-based** - Control execution order with priorities
- ✅ **Lifecycle-aware** - Automatic cleanup when objects are freed
- ✅ **Middleware** - Intercept and process events before/after execution
- ✅ **Metrics** - Built-in performance tracking and introspection
- ✅ **Scene-tree independent** - Works with any `RefCounted` objects

### Quick Start

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

# Create event bus instance
var event_bus = Engine.Event.Bus.new()

# Subscribe to an event
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy ", event.enemy_id, " died!")
)

# Emit events
event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
```

### Creating Events

Events must extend `Engine.Event.Event`:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

extends Engine.Event.Event
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

### EventBus API

#### Subscribe to events

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

#### Emit events

```gdscript
# Fire and forget (still awaits async listeners to prevent memory leaks)
event_bus.emit(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))

# Explicitly await all async listeners (same behavior, but more explicit)
await event_bus.emit_and_await(EnemyDiedEvent.new(42, 100, Vector2(50, 60)))
```

**Note:** Both `emit()` and `emit_and_await()` await async listeners to prevent memory leaks. The difference is that `emit_and_await()` makes the async behavior explicit in your code.

#### Unsubscribe

```gdscript
# By callable
event_bus.unsubscribe(EnemyDiedEvent, _my_listener)

# By subscription ID (for anonymous functions)
var sub_id = event_bus.on(EnemyDiedEvent, func(event): print("Event!"))
event_bus.unsubscribe_by_id(EnemyDiedEvent, sub_id)
```

#### Middleware

Middleware lets you intercept events before and after they're processed:

```gdscript
# Before-execution middleware (can cancel by returning false)
event_bus.add_middleware_before(func(evt: Engine.Event.Event):
    print("Before: ", evt)
    return true  # Return false to cancel
, priority=0)

# After-execution middleware
event_bus.add_middleware_after(func(evt: Engine.Event.Event, result):
    print("After: ", result)
, priority=0)

# Remove middleware
var mw_id = event_bus.add_middleware_before(my_callback)
event_bus.remove_middleware(mw_id)
```

#### Metrics

Track performance and usage patterns:

```gdscript
# Enable metrics
event_bus.set_metrics_enabled(true)

# Get metrics for a specific type
var metrics = event_bus.get_metrics(EnemyDiedEvent)
# Returns: {
#   "count": 42,
#   "total_time": 123.4,
#   "min_time": 0.5,
#   "max_time": 5.2,
#   "avg_time": 2.94
# }

# Get all metrics
var all_metrics = event_bus.get_all_metrics()
```

#### Debugging & Logging

```gdscript
# Enable verbose logging (detailed operation logs)
event_bus.set_verbose(true)

# Enable trace logging (execution flow details)
event_bus.set_trace_enabled(true)

# Enable listener call logging (logs each listener invocation)
event_bus.set_log_listener_calls(true)
```

#### Signal Integration

Bridge Godot signals to events:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

var event_bus = Engine.Event.Bus.new()
var bridge = Engine.Event.SignalBridge.new(event_bus)
bridge.connect_signal_to_event($Button, "pressed", ButtonPressedEvent)

# Clean up (happens automatically when bridge is freed)
bridge.disconnect_all()
```

---

## Command Addon

Command bus system for Godot 4.5.1+ that helps you build clean, decoupled game architectures through command-driven communication.

### Overview

The Command addon provides a centralized command dispatching system for communication between different parts of your game. Instead of tightly coupling systems together, you dispatch **commands** (actions to perform) through a centralized bus, and exactly one handler processes each command.

This approach decouples systems by removing direct dependencies while preserving compile-time type safety, predictable execution order, and easier debugging through built-in metrics and tracing.

### Features

- ✅ **Type-safe** - Compile-time type checking for commands
- ✅ **Exactly one handler** - No ambiguity about who handles what
- ✅ **Returns results** - Handlers can return data or errors
- ✅ **Lifecycle-aware** - Automatic cleanup when objects are freed
- ✅ **Middleware** - Intercept and process commands before/after execution
- ✅ **Metrics** - Built-in performance tracking and introspection
- ✅ **Scene-tree independent** - Works with any `RefCounted` objects

### Quick Start

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

# Create command bus instance
var command_bus = Engine.Command.Bus.new()

# Register a command handler
command_bus.handle(MovePlayerCommand, func(command):
    player.move_to(command.target_position)
    return true
)

# Dispatch commands
await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
```

### Creating Commands

Commands must extend `Engine.Command.Command`:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

extends Engine.Command.Command
class_name MovePlayerCommand

var target_position: Vector2
var player_id: int = 0

func _init(pos: Vector2, player: int = 0) -> void:
    target_position = pos
    player_id = player
    super._init("move_player", {"target_position": pos, "player_id": player}, "Move player to position")
```

### CommandBus API

#### Register a handler

```gdscript
command_bus.handle(MovePlayerCommand, func(command):
    player.move_to(command.target_position)
    return true
)
```

#### Dispatch a command

```gdscript
var result = await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))

# Check for errors
if result is Engine.Command.RoutingError:
    print("Command failed: ", result.message)
else:
    print("Command succeeded: ", result)
```

**Error types:**

- `NO_HANDLER` - No handler registered for this command
- `MULTIPLE_HANDLERS` - Multiple handlers registered (shouldn't happen)
- `HANDLER_FAILED` - Handler execution failed or was cancelled

#### Unregister handler

```gdscript
# Remove handler for a command type
command_bus.unregister_handler(MovePlayerCommand)
```

#### Middleware

Middleware lets you intercept commands before and after they're processed:

```gdscript
# Before-execution middleware (can cancel by returning false)
command_bus.add_middleware_before(func(cmd: Engine.Command.Command):
    print("Before: ", cmd)
    return true  # Return false to cancel
, priority=0)

# After-execution middleware
command_bus.add_middleware_after(func(cmd: Engine.Command.Command, result):
    print("After: ", result)
, priority=0)

# Remove middleware
var mw_id = command_bus.add_middleware_before(my_callback)
command_bus.remove_middleware(mw_id)
```

#### Metrics

Track performance and usage patterns:

```gdscript
# Enable metrics
command_bus.set_metrics_enabled(true)

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

```gdscript
# Enable verbose logging (detailed operation logs)
command_bus.set_verbose(true)

# Enable trace logging (execution flow details)
command_bus.set_trace_enabled(true)

# Enable type resolution verbose warnings (for debugging type resolution issues)
Engine.Message.TypeResolver.set_verbose(true)
```

#### Signal Integration

Bridge Godot signals to commands:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

var command_bus = Engine.Command.Bus.new()
var cmd_bridge = Engine.Command.SignalBridge.new(command_bus)
cmd_bridge.connect_signal_to_command(
    $SaveButton,
    "pressed",
    SaveGameCommand,
    func(): return SaveGameCommand.new()
)

# Clean up (happens automatically when bridge is freed)
cmd_bridge.disconnect_all()
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

- Use `owner=self` for automatic cleanup (EventBus)
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
- `Middleware` - Intercepts messages before/after processing (via Middleware addon)
- `CommandSignalBridge` / `EventSignalBridge` - Bridge Godot signals to buses

### Design Principles

- **Explicitness over "magic"** - Clear, explicit APIs over hidden behavior
- **Deterministic behavior** - Predictable execution order
- **Debuggability first** - Metrics, tracing, and clear error messages
- **Type safety** - Leverage Godot's type system for compile-time checks

---

## Support Addon

Support functions for Godot 4.5.1+.

### Usage

Access support utilities through the Engine addon:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

# Array operations
var arr = [1, 2, 3, 4, 5]
Engine.Support.Array.remove_indices(arr, [1, 3])
# arr is now [1, 3, 5]

var entries = [Entry.new(priority=5), Entry.new(priority=10), Entry.new(priority=3)]
Engine.Support.Array.sort_by_priority(entries)
# entries are now sorted: priority 10, 5, 3

var numbers = [1, 2, 3, 4, 5]
var evens = Engine.Support.Array.filter(numbers, func(n): return n % 2 == 0)  # [2, 4]
var doubled = Engine.Support.Array.map(numbers, func(n): return n * 2)  # [2, 4, 6, 8, 10]
var found = Engine.Support.Array.find(numbers, func(n): return n > 3)  # 4
var unique = Engine.Support.Array.unique([1, 2, 2, 3, 1])  # [1, 2, 3]

# String operations
Engine.Support.String.is_blank("   ")  # true
Engine.Support.String.pad_left("42", 5, "0")  # "00042"
Engine.Support.String.truncate("Hello World", 8)  # "Hello..."
Engine.Support.String.to_title_case("hello world")  # "Hello World"
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

