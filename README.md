# Godot Snips

Reusable packages for **Godot 4.5.1+** with a focus on modular architecture and clean code.

## Installation

### Game Project Structure

This project uses a game project structure with all packages in the `src/` folder.

1. Copy the `src/` folder into your Godot project directory
2. Import the engine module to access all functionality:
   ```gdscript
   const Engine = preload("res://src/engine.gd")
   ```

**Requirements:** Godot 4.5.1 or later

### Project Structure

```
src/
├── command/      # Command bus (one-to-one messaging)
├── event/        # Event bus (one-to-many messaging)
├── message/      # Base message infrastructure
├── middleware/   # Middleware infrastructure
├── subscribers/  # Subscriber management
├── support/      # Array/String utilities
├── utils/        # Metrics/Signal utilities
└── engine.gd     # Unified entry point
```

## Quick Start

Load all packages with a single import:

```gdscript
const Engine = preload("res://src/engine.gd")

# Access Command package
var command_bus = Engine.Command.Bus.new()

# Access Event package
var event_bus = Engine.Event.Bus.new()

# Access Support package
Engine.Support.Array.remove_indices(arr, [1, 3])
Engine.Support.String.is_blank("   ")
```

## Usage Examples

### Event Bus

Subscribe to events and emit them for one-to-many communication:

```gdscript
const Engine = preload("res://src/engine.gd")

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
const Engine = preload("res://src/engine.gd")

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
const Engine = preload("res://src/engine.gd")

var event_bus = Engine.Event.Bus.new()
var command_bus = Engine.Command.Bus.new()

# Add before-middleware (can cancel delivery by returning false)
var log_middleware_id = event_bus.before(func(message, key):
    print("Before processing: ", key)
    return true  # Return false to cancel delivery
, priority=5)

# Add after-middleware (runs after handler/listener execution)
event_bus.after(func(message, key, result):
    print("After processing: ", key, " (result: ", result, ")")
, priority=5)

# Middleware also works with CommandBus
command_bus.before(func(message, key):
    print("Logging command: ", key)
    return true
)

# Remove middleware using the returned ID
event_bus.remove_middleware(log_middleware_id)

# Clear all middleware
event_bus.clear_middleware()
```


