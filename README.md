# Godot Snips

Personal code snippets for **Godot 4.5.1+** game projects—reusable patterns for prototyping and gameplay development.

## Messaging System

A lightweight, type-safe messaging system with commands and events for decoupling game components.

> 📖 **Full Documentation**: See [core/messaging/README.md](core/messaging/README.md) for complete usage guide, API reference, and examples.

### Quick Start

```gdscript
# Create buses (use as autoload singletons or instantiate as needed)
var command_bus = CommandBus.create()
var event_bus = EventBus.create()

# Register a command handler
command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    return player.move_to(cmd.target_position)
)

# Subscribe to events
event_bus.subscribe(EnemyDiedEvent, func(evt: EnemyDiedEvent):
    update_score(evt.points)
    play_sound("enemy_death")
)

# Dispatch commands and publish events
var result = await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
event_bus.publish(EnemyDiedEvent.new(enemy_id, 100))
```

For complete documentation, examples, and API reference, see [core/messaging/README.md](core/messaging/README.md).
