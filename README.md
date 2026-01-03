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

## Usage Examples

### Event Bus

Subscribe to events and emit them for one-to-many communication:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

var event_bus = Engine.Event.Bus.new()

# Subscribe to events (multiple listeners can subscribe)
event_bus.on(EnemyDiedEvent, func(event):
    print("Enemy died: ", event.enemy_id)
)

# Subscribe with priority (higher priority executes first)
event_bus.on(EnemyDiedEvent, _handle_enemy_died_score, priority=10)

# One-shot subscription (fires once, then auto-unsubscribes)
event_bus.on(EnemyDiedEvent, func(event):
    print("First enemy death detected!")
, once=true)

# Lifecycle-bound subscription (auto-unsubscribes when node exits)
event_bus.on(EnemyDiedEvent, _handle_enemy_died_ui, owner=self)

# Emit events (all listeners are notified)
var event = EnemyDiedEvent.new(42, 100)
event_bus.emit(event)
```

### Command Bus

Register command handlers and dispatch commands for one-to-one communication:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

var command_bus = Engine.Command.Bus.new()

# Register a command handler (exactly one handler per command type)
command_bus.handle(MovePlayerCommand, func(command):
    print("Moving player to ", command.target_position)
    # Execute movement logic
    return true  # Return success/failure
)

# Dispatch a command (returns result or RoutingError)
var cmd = MovePlayerCommand.new(Vector2(100, 200))
var result = await command_bus.dispatch(cmd)

if result is Engine.Command.RoutingError:
    print("Command failed: ", result.message)
else:
    print("Command succeeded: ", result)
```

### Middleware

Add middleware to intercept messages before and after they reach handlers/listeners:

```gdscript
const Engine = preload("res://addons/engine/src/engine.gd")

var event_bus = Engine.Event.Bus.new()
var command_bus = Engine.Command.Bus.new()

# Add before-middleware (can cancel delivery by returning false)
var log_middleware_id = event_bus.add_middleware_before(func(message, key):
    print("Before processing: ", key)
    return true  # Return false to cancel delivery
, priority=5)

# Add after-middleware (runs after handler/listener execution)
event_bus.add_middleware_after(func(message, key, result):
    print("After processing: ", key, " (result: ", result, ")")
, priority=5)

# Middleware also works with CommandBus
command_bus.add_middleware_before(func(message, key):
    print("Logging command: ", key)
    return true
)

# Remove middleware using the returned ID
event_bus.remove_middleware(log_middleware_id)
```

