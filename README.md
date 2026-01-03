# Godot Snips

Reusable packages for **Godot 4.5.1+** with a focus on modular architecture and clean code.

## Packages

### Messaging

Type-safe command/event messaging framework.

```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()

await command_bus.dispatch(MyCommand.new())
event_bus.publish(MyEvent.new())
```

**[Documentation →](packages/messaging/README.md)**

### Collection

Fluent array wrapper with method chaining.

```gdscript
const Collection = preload("res://packages/collection/collection.gd")

var numbers = Collection.Collection.new([1, 2, 3, 4, 5])
var evens = numbers.filter(func(n): return n % 2 == 0).array()
```

**[Documentation →](packages/collection/README.md)**

## Requirements

Godot 4.5.1+
