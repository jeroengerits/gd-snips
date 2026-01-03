# Godot Snips

Reusable packages for **Godot 4.5.1+** with a focus on modular architecture and clean code.

## Installation

### Option 1: Install All Packages (Recommended)

This project uses a hybrid structure with standalone addons and a unified engine entry point.

1. Copy the `addons/` folder and `src/` folder into your Godot project directory
2. Import the engine module to access all functionality:
   ```gdscript
   const Engine = preload("res://src/engine.gd")
   ```

**Requirements:** Godot 4.5.1 or later

### Option 2: Install Individual Addons

You can install only the addons you need from the `addons/` directory. Each addon includes a `plugin.cfg` file for Godot addon recognition.

**Level 0 (Zero Dependencies):**
- `addons/support/` - Array/String utilities (no dependencies)
- `addons/utils/` - Metrics/Signal utilities (no dependencies)
- `addons/message/` - Message infrastructure (no dependencies, foundation for others)

**Level 1 (Depends on message):**
- `addons/middleware/` - Middleware infrastructure (requires `message`)
- `addons/subscribers/` - Subscriber management (requires `message`)

**Level 2 (Depends on multiple packages):**
- `addons/command/` - Command bus (requires `message`, `subscribers`, `middleware`, `utils`)
- `addons/event/` - Event bus (requires `message`, `subscribers`, `middleware`, `utils`)

**Important:** When installing individual addons, ensure all dependencies are also installed. For example, if you install `command` or `event`, you must also install `message`, `subscribers`, `middleware`, and `utils`.

Then use the engine module or import addons directly:
```gdscript
# Via engine (recommended - handles all dependencies)
const Engine = preload("res://src/engine.gd")

# Or directly (must install dependencies manually)
const Support = preload("res://addons/support/support.gd")
const Middleware = preload("res://addons/middleware/middleware.gd")
```

### Project Structure

```
addons/
├── support/       # Array/String utilities (standalone addon)
├── utils/         # Metrics/Signal utilities (standalone addon)
├── message/       # Base message infrastructure (standalone addon)
├── middleware/    # Middleware infrastructure (depends on message)
├── subscribers/   # Subscriber management (depends on message)
├── command/       # Command bus (depends on message, subscribers, middleware, utils)
└── event/         # Event bus (depends on message, subscribers, middleware, utils)

src/
└── engine.gd      # Unified entry point (barrel file)
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

## Addon Structure

Each addon in `addons/` is a standalone Godot addon with:
- `plugin.cfg` - Addon configuration file (enables Godot addon recognition)
- Barrel file (`[addon].gd`) - Public API entry point
- Implementation files - Core functionality

### Dependency Graph

```
Level 0 (Independent):
  support, utils, message

Level 1 (Depends on Level 0):
  middleware → message
  subscribers → message

Level 2 (Depends on Level 0 + Level 1):
  command → message, subscribers, middleware, utils
  event → message, subscribers, middleware, utils
```

### Using Individual Addons

When using individual addons (not via `Engine`), you must ensure all dependencies are available:

```gdscript
# Example: Using EventBus directly
const Message = preload("res://addons/message/message.gd")
const Subscribers = preload("res://addons/subscribers/subscribers.gd")
const Middleware = preload("res://addons/middleware/middleware.gd")
const Utils = preload("res://addons/utils/utils.gd")
const Event = preload("res://addons/event/event.gd")

var event_bus = Event.Bus.new()
```

**Recommendation:** Use `Engine` barrel file for simplicity - it handles all dependencies automatically.

## Troubleshooting

### Addons Not Recognized

If Godot doesn't recognize addons:
1. Ensure `plugin.cfg` files are present in each addon directory
2. Check that addon directories are directly under `addons/`
3. Restart Godot editor after adding addons
4. Verify Godot version is 4.5.1 or later

### Import Errors

If you see import errors:
- Ensure all required dependencies are installed
- Check that paths use `res://addons/` (not `res://src/`)
- Verify `engine.gd` is in `src/` directory if using Engine barrel file

### Missing Dependencies

When installing individual addons, remember:
- `command` and `event` require: `message`, `subscribers`, `middleware`, `utils`
- `middleware` and `subscribers` require: `message`
- `support`, `utils`, `message` have no dependencies

