# Messaging System

A lightweight, type-safe messaging system with commands and events for decoupling game components.

## Quick Start

```gdscript
# Import the messaging API
const Messaging = preload("res://messaging/messaging.gd")

# Create buses (instantiate directly)
var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()

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

## Self-Check Example

```gdscript
# Quick verification script (no scenes required)
const Messaging = preload("res://messaging/messaging.gd")

# Create test command class
extends Messaging.Command
class_name TestCommand

var value: int

func _init(v: int) -> void:
    value = v
    super._init("test_command", {"value": v})

# Create test event class
extends Messaging.Event
class_name TestEvent

var id: int

func _init(i: int) -> void:
    id = i
    super._init("test_event", {"id": i})

# Usage
func _ready():
    var cmd_bus = Messaging.CommandBus.new()
    var evt_bus = Messaging.EventBus.new()

    # Command handler
    cmd_bus.handle(TestCommand, func(cmd: TestCommand) -> bool:
        print("Command received: ", cmd.value)
        return true
    )

    # Event listener
    evt_bus.subscribe(TestEvent, func(evt: TestEvent):
        print("Event received: ", evt.id)
    )

    # Dispatch and publish
    var result = await cmd_bus.dispatch(TestCommand.new(42))
    evt_bus.publish(TestEvent.new(100))

    print("Self-check complete! Messaging system working.")
```

## Commands vs Events

**Commands** — Imperative actions with a single handler:

- Use for: `MovePlayerCommand`, `OpenInventoryCommand`, `SaveGameCommand`
- Exactly one handler processes each command
- Return a result (or error)

**Events** — Notifications with multiple subscribers:

- Use for: `EnemyDiedEvent`, `PlayerHealthChangedEvent`, `LevelCompletedEvent`
- Zero or more listeners can subscribe
- Fire-and-forget (no return values)

## Creating Your Own Messages

**Custom Command:**

```gdscript
const Messaging = preload("res://messaging/messaging.gd")

extends Messaging.Command
class_name DealDamageCommand

var target: Node
var amount: int

func _init(target_node: Node, damage: int) -> void:
    target = target_node
    amount = damage
    super._init("deal_damage", {"target": target_node, "amount": damage})

# Type identification is handled automatically from class_name
```

**Custom Event:**

```gdscript
const Messaging = preload("res://messaging/messaging.gd")

extends Messaging.Event
class_name PlayerDiedEvent

var player_id: int
var cause: String

func _init(id: int, death_cause: String) -> void:
    player_id = id
    cause = death_cause
    super._init("player_died", {"player_id": id, "cause": death_cause})

# Type identification is handled automatically from class_name
```

## Usage Examples

**Command Bus - Handling Actions:**

```gdscript
const Messaging = preload("res://messaging/messaging.gd")

# Setup (typically in _ready() or initialization)
var command_bus: Messaging.CommandBus

func _ready():
    command_bus = Messaging.CommandBus.new()
    command_bus.handle(DealDamageCommand, _handle_damage)

func _handle_damage(cmd: DealDamageCommand) -> bool:
    if cmd.target.has_method("take_damage"):
        cmd.target.take_damage(cmd.amount)
        return true
    return false

# Dispatch from anywhere
var result = await command_bus.dispatch(DealDamageCommand.new(enemy, 25))
if result is Messaging.CommandBus.CommandError:
    print("Failed to deal damage: ", result.message)
```

**Event Bus - Subscribing to Notifications:**

```gdscript
const Messaging = preload("res://messaging/messaging.gd")

# Setup with priorities (higher priority listeners called first)
var event_bus: Messaging.EventBus

func _ready():
    event_bus = Messaging.EventBus.new()
    event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_score, priority=10)
    event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_sound, priority=5)
    event_bus.subscribe(EnemyDiedEvent, _on_enemy_died_cleanup, priority=0)

func _on_enemy_died_score(evt: EnemyDiedEvent) -> void:
    score += evt.points

func _on_enemy_died_sound(evt: EnemyDiedEvent) -> void:
    audio_player.play("enemy_death")

func _on_enemy_died_cleanup(evt: EnemyDiedEvent) -> void:
    remove_enemy_from_scene(evt.enemy_id)
```

**Advanced Features:**

```gdscript
const Messaging = preload("res://messaging/messaging.gd")

var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()

# One-shot subscription (auto-unsubscribes after first event)
event_bus.subscribe(TutorialCompletedEvent, func(evt):
    show_celebration()
, one_shot=true)

# Lifecycle-bound subscription (auto-unsubscribes when node exits tree)
event_bus.subscribe(PlayerHealthChangedEvent, _update_health_bar, bound_object=self)

# Unsubscribe manually
event_bus.unsubscribe(EnemyDiedEvent, _on_enemy_died_score)

# Check if handler exists
if command_bus.has_handler(MovePlayerCommand):
    command_bus.dispatch(MovePlayerCommand.new(new_position))

# Async support
command_bus.handle(SaveGameCommand, func(cmd: SaveGameCommand):
    await save_game_data()
    return true
)

# Error handling: GDScript has no try/catch, so listener errors will propagate
# Enable error logging to log context before crashes occur
event_bus.set_collect_errors(true)
event_bus.publish(EnemyDiedEvent.new(enemy_id, 100))

# Middleware: Intercept messages before/after delivery
var log_middleware_id = event_bus.add_middleware_pre(func(evt: Event, key: StringName) -> bool:
    print("Event published: ", key)
    return true  # Return false to cancel delivery
)

# Performance metrics: Track message delivery performance
event_bus.set_metrics_enabled(true)
event_bus.publish(EnemyDiedEvent.new(enemy_id, 100))
var metrics = event_bus.get_metrics(EnemyDiedEvent)
print("Event metrics: ", metrics)  # {count: int, avg_time: float, min_time: float, max_time: float}
```

## API Reference

**Import:**

```gdscript
const Messaging = preload("res://messaging/messaging.gd")
```

**CommandBus** (`Messaging.CommandBus`):

- `handle(command_type, handler: Callable)` - Register handler (replaces existing)
- `dispatch(command: Command) -> Variant` - Dispatch command, returns result
- `unregister(command_type)` - Remove handler
- `has_handler(command_type) -> bool` - Check if handler exists
- `get_subscription_count(command_type) -> int` - Get number of handlers (should be 0 or 1)
- `add_middleware_pre(callback: Callable, priority=0) -> int` - Add pre-processing middleware (before dispatch)
- `add_middleware_post(callback: Callable, priority=0) -> int` - Add post-processing middleware (after dispatch)
- `remove_middleware(middleware_id: int) -> bool` - Remove middleware by ID
- `set_metrics_enabled(enabled: bool)` - Enable/disable performance metrics tracking
- `get_metrics(command_type) -> Dictionary` - Get performance metrics for a command type
- `get_all_metrics() -> Dictionary` - Get all performance metrics
- `set_verbose(enabled: bool)` - Enable/disable verbose logging
- `set_tracing(enabled: bool)` - Enable/disable message delivery tracing
- `clear()` - Clear all handlers

**EventBus** (`Messaging.EventBus`):

- `subscribe(event_type, listener: Callable, priority=0, one_shot=false, bound_object=null) -> int` - Subscribe to events
- `publish(event: Event)` - Publish event (fire-and-forget, may block briefly for async listeners)
- `publish_async(event: Event)` - Publish and await all async listeners
- `unsubscribe(event_type, listener: Callable)` - Unsubscribe
- `unsubscribe_by_id(event_type, sub_id: int)` - Unsubscribe by subscription ID
- `get_listeners(event_type) -> Array` - Get all listeners for an event type
- `get_subscription_count(event_type) -> int` - Get number of listeners for an event type
- `get_types() -> Array[StringName]` - Get all registered event types
- `add_middleware_pre(callback: Callable, priority=0) -> int` - Add pre-processing middleware (before publish)
- `add_middleware_post(callback: Callable, priority=0) -> int` - Add post-processing middleware (after publish)
- `remove_middleware(middleware_id: int) -> bool` - Remove middleware by ID
- `set_metrics_enabled(enabled: bool)` - Enable/disable performance metrics tracking
- `get_metrics(event_type) -> Dictionary` - Get performance metrics for an event type
- `get_all_metrics() -> Dictionary` - Get all performance metrics
- `set_collect_errors(enabled: bool)` - Enable/disable error logging (logs context before crashes)
- `set_verbose(enabled: bool)` - Enable/disable verbose logging
- `set_tracing(enabled: bool)` - Enable/disable message delivery tracing
- `clear()` - Clear all subscribers

**Message Base Classes** (`Messaging.Message`, `Messaging.Command`, `Messaging.Event`):

- `id() -> String` - Unique message identifier (content-based)
- `type() -> String` - Message type string
- `data() -> Dictionary` - Message payload (deep copy)
- `is_valid() -> bool` - Check if message satisfies validation rules
- `has_data() -> bool` - Check if message has data payload
- `get_data_value(key: String, default) -> Variant` - Get data value by key
- `has_data_key(key: String) -> bool` - Check if data contains key
- `to_string() -> String` - Debug representation
- `equals(other: Message) -> bool` - Content-based equality comparison

**Command-Specific Methods** (`Messaging.Command`):

- `is_executable() -> bool` - Check if command can be executed
- `has_required_data() -> bool` - Validate required fields (override in subclasses)

**Rules Classes** (`Messaging.CommandRules`, `Messaging.SubscriptionRules`):

- These are domain services that encapsulate business rules
- Used internally by the buses but can be accessed directly for testing or custom validation
- `CommandRules.validate_count(count: int) -> CommandRules.ValidationResult` - Validate handler count
- `CommandRules.is_valid_handler_count(count: int) -> bool` - Check if handler count is valid
- `SubscriptionRules.should_process_before(a_priority: int, b_priority: int) -> bool` - Compare priorities
- `SubscriptionRules.should_remove_after_delivery(one_shot: bool) -> bool` - Check if subscription should be removed
- `SubscriptionRules.is_valid_for_lifecycle(bound_object: Object) -> bool` - Validate lifecycle binding
- `SubscriptionRules.sort_by_priority(subscriptions: Array) -> void` - Sort subscriptions by priority

## Debugging & Inspection

```gdscript
const Messaging = preload("res://messaging/messaging.gd")

var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()

# Enable verbose logging (logs subscriptions/unsubscriptions)
command_bus.set_verbose(true)
event_bus.set_verbose(true)

# Enable tracing (logs all message deliveries)
command_bus.set_tracing(true)
event_bus.set_tracing(true)

# Check subscription counts
print("EnemyDiedEvent has ", event_bus.get_subscription_count(EnemyDiedEvent), " listeners")
print("MovePlayerCommand handler exists: ", command_bus.has_handler(MovePlayerCommand))

# Get all registered message types
var event_types = event_bus.get_types()
print("Registered event types: ", event_types)

# Get all listeners for an event type
var listeners = event_bus.get_listeners(EnemyDiedEvent)
for listener in listeners:
    print("Listener: ", listener)

# Enable error logging (logs context before crashes)
# Note: GDScript has no try/catch, so listener errors will still crash
event_bus.set_collect_errors(true)
```

## Async & Error Handling Notes

**Async Event Handling:**

The `publish()` method is fire-and-forget for synchronous listeners, but async listeners are still awaited to prevent memory leaks. This means `publish()` may block briefly if listeners are async. For truly non-blocking behavior from a Node context, you can wrap the call:

```gdscript
# From a Node: truly non-blocking publish
call_deferred("_publish_event", event_bus, my_event)

func _publish_event(bus: Messaging.EventBus, evt: Event) -> void:
    bus.publish(evt)
```

**Error Handling:**

GDScript has no try/catch mechanism, so errors in event listeners will always propagate and crash. The `set_collect_errors()` method enables logging of context information before errors occur (helps with debugging). Ensure your listeners handle errors internally, or use defensive programming techniques.

**Middleware:**

Both CommandBus and EventBus support middleware for intercepting messages before and after delivery. Pre-middleware can cancel delivery by returning `false`. Middleware runs in priority order (higher priority first).

```gdscript
# Logging middleware
var log_id = event_bus.add_middleware_pre(func(evt: Event, key: StringName) -> bool:
    print("Publishing event: ", key)
    return true  # Continue delivery
)

# Validation middleware (can cancel delivery)
var validate_id = event_bus.add_middleware_pre(func(evt: Event, key: StringName) -> bool:
    if not evt.is_valid():
        print("Invalid event: ", key)
        return false  # Cancel delivery
    return true
)

# Post-processing middleware
event_bus.add_middleware_post(func(evt: Event, key: StringName, result):
    print("Event delivered: ", key)
)

# Remove middleware
event_bus.remove_middleware(log_id)
```

**Performance Metrics:**

Enable performance tracking to monitor message delivery times. Metrics track count, total time, average time, minimum time, and maximum time per message type.

```gdscript
# Enable metrics
command_bus.set_metrics_enabled(true)

# Dispatch commands (metrics are tracked automatically)
await command_bus.dispatch(SaveGameCommand.new())

# Get metrics
var metrics = command_bus.get_metrics(SaveGameCommand)
# Returns: {count: 5, total_time: 0.123, avg_time: 0.0246, min_time: 0.01, max_time: 0.05}

# Get all metrics
var all_metrics = command_bus.get_all_metrics()
# Returns: Dictionary mapping message types to their metrics
```
```

## Rules

The messaging system includes rules classes that encapsulate business rules:

**CommandRules** (`Messaging.CommandRules`) - Validates command routing rules:

- Commands must have exactly one handler (invariant)
- Used internally by `CommandBus` to enforce routing semantics
- Can be accessed directly for testing or custom validation logic

**SubscriptionRules** (`Messaging.SubscriptionRules`) - Defines subscription behavior rules:

- Priority ordering (higher priority subscribers processed first)
- One-shot subscription semantics (auto-unsubscribe after delivery)
- Lifecycle binding validation (subscriptions invalid when bound object freed)

These rules make business rules explicit and testable. They're used internally by the buses but can be accessed directly if needed:

```gdscript
const Messaging = preload("res://messaging/messaging.gd")

# Access rules directly for testing or custom logic
var validation = Messaging.CommandRules.validate_count(handler_count)
if validation == Messaging.CommandRules.ValidationResult.VALID:
    # Proceed with dispatch
    pass
```

## Tips

- Use commands for actions that need a response or error handling
- Use events for notifications that multiple systems care about
- Higher priority listeners are called first (useful for core systems before UI)
- Bound subscriptions automatically clean up when objects are freed
- Enable verbose logging and tracing during development for debugging
- Use `get_subscription_count()` to verify listeners are registered correctly
- Messages use content-based equality - two messages with same type and data are equal
- Message constructors enforce validation rules (type cannot be empty, data cannot be null)

## Files

**Entry Point**:

- `messaging.gd` - Barrel entrypoint (import this to use the system)

**Types** (`types/`):

- `message.gd` - Base message class (class: `Message`)
- `command.gd` - Command base class (class: `Command`)
- `event.gd` - Event base class (class: `Event`)

**Buses** (`buses/`):

- `command_bus.gd` - Command bus (class: `CommandBus`)
- `event_bus.gd` - Event bus (class: `EventBus`)

**Internal** (`internal/`):

- `message_bus.gd` - Internal message bus implementation (no class_name)
- `message_type_resolver.gd` - Internal type resolution (no class_name)

**Rules** (`rules/`):

- `command_rules.gd` - Command routing rules (class: `CommandRules`)
- `subscription_rules.gd` - Subscription behavior rules (class: `SubscriptionRules`)

> **Note**:
>
> - Only import from `messaging.gd` in your code
> - `types/`, `buses/`, `internal/`, and `rules/` files are implementation details and should not be imported directly

## See Also

- [Examples](examples/) - Usage examples and tests
