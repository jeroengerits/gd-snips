# Messaging Framework Refactoring Proposal

**Goal**: Improve clarity, consistency, and maintainability through better naming while preserving all runtime behavior.

**Principles**:
- Preserve runtime semantics and public behavior
- Keep Godot 4.5+ compatibility (GDScript 2.0 style)
- Maintain priority ordering determinism
- Keep lifecycle safety (bound object cleanup)
- Keep middleware behavior (pre can cancel, post receives result)
- Keep metrics functionality stable

---

## 1. Naming Proposal Overview

### 1.1 Files/Folders

| Current | Proposed | Reason |
|---------|----------|--------|
| `internal/message_bus.gd` | `internal/subscription_registry.gd` | More accurate: it's a registry for subscriptions, middleware, and metrics, not just a "bus" |
| `rules/command_rules.gd` | `rules/command_validation.gd` | "Validation" is clearer than "rules" |
| `rules/subscription_rules.gd` | `rules/subscription_validation.gd` | Consistent with command validation naming |
| `utilities/metrics_utils.gd` | `utilities/metrics_utils.gd` | ✅ No change (utility functions, not a class) |

### 1.2 Classes/Types

| Current | Proposed | Reason |
|---------|----------|--------|
| `MessageBus` (internal) | `SubscriptionRegistry` | More descriptive: manages subscriptions, middleware, metrics |
| `CommandBus` | `CommandRouter` | "Router" emphasizes routing to single handler |
| `EventBus` | `EventBroadcaster` | "Broadcaster" emphasizes 0..N distribution |
| `CommandError` (nested) | `CommandRoutingError` | More specific: error during routing/dispatching |
| `CommandError.ErrorCode` | `CommandRoutingError.Code` | Follows nested class rename |
| `CommandRules` | `CommandValidator` | "Validator" is clearer than "rules" |
| `SubscriptionRules` | `SubscriptionValidator` | Consistent naming |
| `Middleware` (nested) | `MiddlewareEntry` | Clarifies it's a registry entry, not middleware itself |
| `Subscription` (nested) | `SubscriptionEntry` | Clarifies it's a registry entry |
| `Message` | `Message` | ✅ No change (base type, clear name) |
| `Command` | `Command` | ✅ No change (clear domain name) |
| `Event` | `Event` | ✅ No change (clear domain name) |
| `SignalEventAdapter` | `SignalEventAdapter` | ✅ No change (clear purpose) |

### 1.3 Methods

#### CommandBus/CommandRouter

| Current | Proposed | Reason |
|---------|----------|--------|
| `handle(command_type, handler)` | `register_handler(command_type, handler)` | "handle" is ambiguous (register vs process). "register_handler" is explicit |
| `unregister(command_type)` | `unregister_handler(command_type)` | Consistent with "register_handler" |
| `dispatch(cmd)` | `execute(cmd)` or `send(cmd)` | "execute" is clearer for commands. "send" is also common. **Propose: `execute()`** |
| `has_handler(command_type)` | `has_handler(command_type)` | ✅ No change (clear) |

#### EventBus/EventBroadcaster

| Current | Proposed | Reason |
|---------|----------|--------|
| `subscribe(event_type, listener, ...)` | `subscribe(event_type, listener, ...)` | ✅ No change (clear) |
| `unsubscribe(event_type, listener)` | `unsubscribe(event_type, listener)` | ✅ No change (clear) |
| `unsubscribe_by_id(event_type, sub_id)` | `unsubscribe_by_id(event_type, sub_id)` | ✅ No change (clear) |
| `publish(evt)` | `broadcast(evt)` or `emit(evt)` | "publish" is fine, but "broadcast" matches class name. **Propose: `broadcast()`** |
| `publish_async(evt)` | `broadcast_and_await(evt)` | Current name misleading (publish also awaits). New name explicit |
| `set_collect_errors(enabled)` | `set_log_listener_calls(enabled)` | "collect_errors" doesn't collect, just logs warnings |

#### SubscriptionRegistry (internal)

| Current | Proposed | Reason |
|---------|----------|--------|
| `subscribe(message_type, handler, ...)` | `register(message_type, handler, ...)` | "register" is internal term, "subscribe" is public API term |
| `unsubscribe(message_type, handler)` | `unregister(message_type, handler)` | Consistent with "register" |
| `unsubscribe_by_id(message_type, sub_id)` | `unregister_by_id(message_type, sub_id)` | Consistent with "register" |
| `get_subscriptions(message_type)` | `get_registrations(message_type)` | Internal consistency |
| `clear_type(message_type)` | `clear_registrations(message_type)` | More explicit |
| `get_subscription_count(message_type)` | `get_registration_count(message_type)` | Internal consistency |
| `_get_valid_subscriptions(message_type)` | `_get_valid_registrations(message_type)` | Internal consistency |
| `add_middleware_pre(...)` | `add_middleware_pre(...)` | ✅ No change (clear) |
| `add_middleware_post(...)` | `add_middleware_post(...)` | ✅ No change (clear) |
| `remove_middleware(...)` | `remove_middleware(...)` | ✅ No change (clear) |
| `set_metrics_enabled(...)` | `set_metrics_enabled(...)` | ✅ No change (clear) |
| `get_metrics(...)` | `get_metrics(...)` | ✅ No change (clear) |
| `get_all_metrics()` | `get_all_metrics()` | ✅ No change (clear) |
| `get_key(message_type)` | `resolve_type_key(message_type)` | More explicit about resolution |
| `get_key_from(message)` | `resolve_type_key_from(message)` | Consistent with "resolve_type_key" |
| `set_verbose(enabled)` | `set_verbose(enabled)` | ✅ No change (clear) |
| `set_tracing(enabled)` | `set_tracing(enabled)` | ✅ No change (clear) |

### 1.4 Parameters/Variables

| Current | Proposed | Reason |
|---------|----------|--------|
| `handler` (CommandBus.handle) | `handler` | ✅ No change |
| `listener` (EventBus.subscribe) | `listener` | ✅ No change |
| `callback` (middleware) | `callback` | ✅ No change |
| `one_shot` | `once` | Shorter, common pattern name |
| `bound_object` | `owner` | "owner" is more concise and common in Godot |
| `_subscriptions` | `_registrations` | Internal consistency |
| `_middleware_pre` | `_middleware_pre` | ✅ No change |
| `_middleware_post` | `_middleware_post` | ✅ No change |
| `_metrics` | `_metrics` | ✅ No change |
| `_collect_errors` | `_log_listener_calls` | More accurate |
| `message_type` | `message_type` | ✅ No change (clear) |
| `sub_id` | `registration_id` | Internal consistency (public API can keep `subscription_id`) |

### 1.5 Enums/Error Codes

| Current | Proposed | Reason |
|---------|----------|--------|
| `CommandError.ErrorCode.NO_HANDLER` | `CommandRoutingError.Code.NO_HANDLER` | Follows class rename |
| `CommandError.ErrorCode.MULTIPLE_HANDLERS` | `CommandRoutingError.Code.MULTIPLE_HANDLERS` | Follows class rename |
| `CommandError.ErrorCode.HANDLER_FAILED` | `CommandRoutingError.Code.HANDLER_FAILED` | Follows class rename |
| `CommandRules.ValidationResult.VALID` | `CommandValidator.Result.VALID` | Shorter, clearer enum name |
| `CommandRules.ValidationResult.NO_HANDLER` | `CommandValidator.Result.NO_HANDLER` | Shorter, clearer enum name |
| `CommandRules.ValidationResult.MULTIPLE_HANDLERS` | `CommandValidator.Result.MULTIPLE_HANDLERS` | Shorter, clearer enum name |

---

## 2. Refactor Plan (Step-by-Step)

### Phase 1: Internal Refactoring (Low Risk)

1. **Rename internal MessageBus to SubscriptionRegistry**
   - Rename file: `internal/message_bus.gd` → `internal/subscription_registry.gd`
   - Rename class: `MessageBus` → `SubscriptionRegistry`
   - Update all internal references
   - Update CommandBus and EventBus to extend SubscriptionRegistry
   - **Risk**: Low (internal only)

2. **Rename Rules classes**
   - `rules/command_rules.gd` → `rules/command_validation.gd`
   - `rules/subscription_rules.gd` → `rules/subscription_validation.gd`
   - Rename classes and update references
   - **Risk**: Low (internal only)

3. **Rename nested classes in SubscriptionRegistry**
   - `Middleware` → `MiddlewareEntry`
   - `Subscription` → `SubscriptionEntry`
   - Update all internal references
   - **Risk**: Low (internal only)

4. **Rename internal methods and variables**
   - `subscribe` → `register` (internal)
   - `_subscriptions` → `_registrations`
   - `get_subscription_count` → `get_registration_count` (internal)
   - `_get_valid_subscriptions` → `_get_valid_registrations`
   - `clear_type` → `clear_registrations` (internal)
   - `get_key` → `resolve_type_key`
   - `get_key_from` → `resolve_type_key_from`
   - **Risk**: Low (internal only)

### Phase 2: Public API Refactoring (Medium Risk)

5. **Rename CommandBus to CommandRouter**
   - Rename file: `buses/command_bus.gd` → `routers/command_router.gd` (or keep in buses/)
   - Rename class: `CommandBus` → `CommandRouter`
   - Update all references in codebase
   - **Risk**: Medium (public API change)

6. **Rename EventBus to EventBroadcaster**
   - Rename file: `buses/event_bus.gd` → `buses/event_broadcaster.gd`
   - Rename class: `EventBus` → `EventBroadcaster`
   - Update all references in codebase
   - **Risk**: Medium (public API change)

7. **Rename CommandError to CommandRoutingError**
   - Rename nested class in CommandRouter
   - Update all references
   - **Risk**: Medium (public API, error types are rarely directly referenced)

8. **Rename CommandBus methods**
   - `handle` → `register_handler`
   - `unregister` → `unregister_handler`
   - `dispatch` → `execute`
   - Update all call sites
   - **Risk**: Medium (public API change)

9. **Rename EventBus methods**
   - `publish` → `broadcast`
   - `publish_async` → `broadcast_and_await`
   - `set_collect_errors` → `set_log_listener_calls`
   - Update all call sites
   - **Risk**: Medium (public API change)

### Phase 3: Parameter Renaming (Low Risk)

10. **Rename subscription parameters**
    - `one_shot` → `once`
    - `bound_object` → `owner`
    - Update all call sites
    - **Risk**: Low (parameter name changes, easy to find/replace)

---

## 3. Key Code Changes by File

### 3.1 internal/subscription_registry.gd (was message_bus.gd)

**Key Changes**:
- Rename class: `MessageBus` → `SubscriptionRegistry`
- Rename nested classes: `Middleware` → `MiddlewareEntry`, `Subscription` → `SubscriptionEntry`
- Rename variables: `_subscriptions` → `_registrations`
- Rename methods: `subscribe` → `register`, `unsubscribe` → `unregister`, etc.
- Rename: `get_key` → `resolve_type_key`, `get_key_from` → `resolve_type_key_from`

**Key Snippets**:

```gdscript
extends RefCounted
## Internal subscription registry. Manages subscriptions, middleware, and metrics.
## Use CommandRouter or EventBroadcaster instead.

## Middleware registry entry.
class MiddlewareEntry:
    var callback: Callable
    var priority: int = 0
    var id: int
    
    static var _next_id: int = 0
    
    func _init(callback: Callable, priority: int = 0):
        self.callback = callback
        self.priority = priority
        self.id = _next_id
        _next_id += 1

## Subscription registry entry.
class SubscriptionEntry:
    var callable: Callable
    var priority: int = 0
    var once: bool = false  # Renamed from one_shot
    var owner: Object = null  # Renamed from bound_object
    var id: int
    
    static var _next_id: int = 0
    
    func _init(callable: Callable, priority: int = 0, once: bool = false, owner: Object = null):
        self.callable = callable
        self.priority = priority
        self.once = once
        self.owner = owner
        self.id = _next_id
        _next_id += 1
    
    func is_valid() -> bool:
        if not SubscriptionValidator.is_valid_for_lifecycle(owner):
            return false
        return callable.is_valid()
    
    func hash() -> int:
        return id

var _registrations: Dictionary = {}  # StringName -> Array[SubscriptionEntry]
var _middleware_pre: Array[MiddlewareEntry] = []
var _middleware_post: Array[MiddlewareEntry] = []
# ... rest of variables ...

## Register a subscription (internal).
func register(message_type, handler: Callable, priority: int = 0, once: bool = false, owner: Object = null) -> int:
    assert(handler.is_valid(), "Handler callable must be valid")
    var key: StringName = resolve_type_key(message_type)
    var entry: SubscriptionEntry = SubscriptionEntry.new(handler, priority, once, owner)
    
    if not _registrations.has(key):
        _registrations[key] = []
    
    var entries: Array = _registrations[key]
    # Insert in sorted position (higher priority first)
    var insert_pos: int = entries.size()
    for i in range(entries.size() - 1, -1, -1):
        if entries[i].priority >= priority:
            insert_pos = i + 1
            break
    entries.insert(insert_pos, entry)
    
    if _verbose:
        print("[SubscriptionRegistry] Registered to ", key, " (priority=", priority, ", once=", once, ")")
    
    return entry.id

## Resolve type key from message type.
static func resolve_type_key(message_type) -> StringName:
    return MessageTypeResolver.resolve_type(message_type)

## Resolve type key from message instance.
static func resolve_type_key_from(message: Object) -> StringName:
    return MessageTypeResolver.resolve_type(message)
```

### 3.2 routers/command_router.gd (was buses/command_bus.gd)

**Key Changes**:
- Rename class: `CommandBus` → `CommandRouter`
- Rename nested class: `CommandError` → `CommandRoutingError`
- Rename methods: `handle` → `register_handler`, `dispatch` → `execute`
- Update to extend `SubscriptionRegistry`
- Use `CommandValidator` instead of `CommandRules`

**Key Snippets**:

```gdscript
const SubscriptionRegistry = preload("res://packages/messaging/internal/subscription_registry.gd")
const CommandValidator = preload("res://packages/messaging/rules/command_validation.gd")
const Command = preload("res://packages/messaging/types/command.gd")

extends SubscriptionRegistry
class_name CommandRouter

## Command router: routes commands to exactly one handler.

## Error raised during command routing/execution.
class CommandRoutingError extends RefCounted:
    var message: String
    var code: int
    
    enum Code {
        NO_HANDLER,
        MULTIPLE_HANDLERS,
        HANDLER_FAILED
    }
    
    func _init(msg: String, err_code: int) -> void:
        assert(not msg.is_empty(), "CommandRoutingError message cannot be empty")
        assert(err_code >= 0, "CommandRoutingError code must be non-negative")
        message = msg
        code = err_code
    
    func to_string() -> String:
        return "[CommandRoutingError: %s (code=%d)]" % [message, code]

## Register handler for a command type (replaces existing).
func register_handler(command_type, handler: Callable) -> void:
    assert(handler.is_valid(), "Handler callable must be valid")
    var key: StringName = resolve_type_key(command_type)
    var existing: int = get_registration_count(command_type)
    
    if existing > 0:
        clear_registrations(command_type)
        if _verbose:
            print("[CommandRouter] Replaced existing handler for ", key)
    
    register(command_type, handler, 0, false, null)

## Execute command. Returns handler result or CommandRoutingError.
func execute(cmd: Command) -> Variant:
    assert(cmd != null, "Command cannot be null")
    assert(cmd is Command, "Command must be an instance of Command")
    var key: StringName = resolve_type_key_from(cmd)
    var start_time: int = Time.get_ticks_msec()
    
    # Execute pre-middleware (can cancel delivery)
    if not _execute_middleware_pre(cmd, key):
        if _trace_enabled:
            print("[CommandRouter] Executing ", key, " cancelled by middleware")
        return CommandRoutingError.new("Command execution cancelled by middleware", CommandRoutingError.Code.HANDLER_FAILED)
    
    var entries: Array = _get_valid_registrations(key)
    
    # Validate routing rules
    var validation: CommandValidator.Result = CommandValidator.validate_count(entries.size())
    
    match validation:
        CommandValidator.Result.NO_HANDLER:
            var err: CommandRoutingError = CommandRoutingError.new("No handler registered for command type: %s" % key, CommandRoutingError.Code.NO_HANDLER)
            push_error(err.to_string())
            _execute_middleware_post(cmd, key, err)
            return err
        
        CommandValidator.Result.MULTIPLE_HANDLERS:
            var err: CommandRoutingError = CommandRoutingError.new("Multiple handlers registered for command type: %s (expected exactly one)" % key, CommandRoutingError.Code.MULTIPLE_HANDLERS)
            push_error(err.to_string())
            _execute_middleware_post(cmd, key, err)
            return err
        
        _:
            pass
    
    var entry = entries[0]
    
    if _trace_enabled:
        print("[CommandRouter] Executing ", key, " -> handler (priority=", entry.priority, ")")
    
    if not entry.is_valid():
        var err: CommandRoutingError = CommandRoutingError.new("Handler is invalid (freed object) for command type: %s" % key, CommandRoutingError.Code.HANDLER_FAILED)
        push_error(err.to_string())
        _execute_middleware_post(cmd, key, err)
        return err
    
    var result: Variant = entry.callable.call(cmd)
    
    if result is GDScriptFunctionState:
        result = await result
    
    var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
    _record_metrics(key, elapsed)
    
    _execute_middleware_post(cmd, key, result)
    
    return result
```

### 3.3 buses/event_broadcaster.gd (was buses/event_bus.gd)

**Key Changes**:
- Rename class: `EventBus` → `EventBroadcaster`
- Rename methods: `publish` → `broadcast`, `publish_async` → `broadcast_and_await`
- Rename variable: `_collect_errors` → `_log_listener_calls`
- Update to extend `SubscriptionRegistry`
- Use `SubscriptionValidator` instead of `SubscriptionRules`
- Parameter: `one_shot` → `once`, `bound_object` → `owner`

**Key Snippets**:

```gdscript
const SubscriptionRegistry = preload("res://packages/messaging/internal/subscription_registry.gd")
const SubscriptionValidator = preload("res://packages/messaging/rules/subscription_validation.gd")
const Event = preload("res://packages/messaging/types/event.gd")

extends SubscriptionRegistry
class_name EventBroadcaster

## Event broadcaster: broadcasts events to 0..N subscribers.

var _log_listener_calls: bool = false  # Renamed from _collect_errors

## Enable listener call logging.
func set_log_listener_calls(enabled: bool) -> void:
    _log_listener_calls = enabled

## Subscribe to an event type.
func subscribe(event_type, listener: Callable, priority: int = 0, once: bool = false, owner: Object = null) -> int:
    assert(listener.is_valid(), "Listener callable must be valid")
    return register(event_type, listener, priority, once, owner)

## Broadcast event to all subscribers.
func broadcast(evt: Event) -> void:
    assert(evt != null, "Event cannot be null")
    assert(evt is Event, "Event must be an instance of Event")
    await _broadcast_internal(evt, false)

## Broadcast event and await all async listeners.
func broadcast_and_await(evt: Event) -> void:
    assert(evt != null, "Event cannot be null")
    assert(evt is Event, "Event must be an instance of Event")
    await _broadcast_internal(evt, true)

## Internal broadcast implementation.
func _broadcast_internal(evt: Event, await_async: bool) -> void:
    var key: StringName = resolve_type_key_from(evt)
    
    if not _execute_middleware_pre(evt, key):
        if _trace_enabled:
            print("[EventBroadcaster] Broadcasting ", key, " cancelled by middleware")
        return
    
    var entries: Array = _get_valid_registrations(key)
    
    if _trace_enabled:
        print("[EventBroadcaster] Broadcasting ", key, " -> ", entries.size(), " listener(s)")
    
    if entries.is_empty():
        return
    
    var ones_to_remove: Array = []
    var start_time: int = Time.get_ticks_msec()
    
    var entries_snapshot: Array = entries.duplicate()
    
    for entry in entries_snapshot:
        if not entry.is_valid():
            continue
        
        if not entry.callable.is_valid():
            continue
        
        if _log_listener_calls:
            push_warning("[EventBroadcaster] Calling listener for event: %s (registration_id=%d)" % [key, entry.id])
        
        var result: Variant = entry.callable.call(evt)
        
        if result is GDScriptFunctionState:
            result = await result
        
        if SubscriptionValidator.should_remove_after_delivery(entry.once):
            ones_to_remove.append({"key": key, "entry": entry})
    
    for item in ones_to_remove:
        _mark_for_removal(item.key, item.entry)
    
    var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
    _record_metrics(key, elapsed)
    
    _execute_middleware_post(evt, key, null)
```

### 3.4 rules/command_validation.gd (was rules/command_rules.gd)

**Key Changes**:
- Rename file and class: `CommandRules` → `CommandValidator`
- Rename enum: `ValidationResult` → `Result`

**Key Snippets**:

```gdscript
extends RefCounted
class_name CommandValidator

## Validation logic for command routing: exactly one handler required.

enum Result {
    VALID,
    NO_HANDLER,
    MULTIPLE_HANDLERS
}

## Validate handler count.
static func validate_count(count: int) -> Result:
    assert(count >= 0, "Handler count must be non-negative")
    if count == 0:
        return Result.NO_HANDLER
    if count > 1:
        return Result.MULTIPLE_HANDLERS
    return Result.VALID

## Check if handler count is valid.
static func is_valid_handler_count(handler_count: int) -> bool:
    assert(handler_count >= 0, "Handler count must be non-negative")
    return validate_count(handler_count) == Result.VALID
```

### 3.5 rules/subscription_validation.gd (was rules/subscription_rules.gd)

**Key Changes**:
- Rename file and class: `SubscriptionRules` → `SubscriptionValidator`
- Update method to use `once` instead of `one_shot`

**Key Snippets**:

```gdscript
extends RefCounted
class_name SubscriptionValidator

## Validation logic for subscription behavior.

## Check if subscription a should process before b.
static func should_process_before(a_priority: int, b_priority: int) -> bool:
    return a_priority > b_priority

## Check if subscription should be removed after delivery.
static func should_remove_after_delivery(once: bool) -> bool:
    return once

## Check if subscription is valid for lifecycle.
static func is_valid_for_lifecycle(owner: Object) -> bool:
    if owner == null:
        return true  # Not bound to object, always valid
    
    return is_instance_valid(owner)

## Sort subscriptions by priority.
static func sort_by_priority(subscriptions: Array) -> void:
    subscriptions.sort_custom(func(a, b): 
        return should_process_before(a.priority, b.priority)
    )
```

### 3.6 messaging.gd (Public API)

**Key Changes**:
- Update preload paths to new file locations and class names

**Key Snippets**:

```gdscript
## Messaging system public API.

const CommandRouter = preload("res://packages/messaging/routers/command_router.gd")
const EventBroadcaster = preload("res://packages/messaging/buses/event_broadcaster.gd")
const Message = preload("res://packages/messaging/types/message.gd")
const Command = preload("res://packages/messaging/types/command.gd")
const Event = preload("res://packages/messaging/types/event.gd")
const CommandValidator = preload("res://packages/messaging/rules/command_validation.gd")
const SubscriptionValidator = preload("res://packages/messaging/rules/subscription_validation.gd")
const SignalEventAdapter = preload("res://packages/messaging/adapters/signal_event_adapter.gd")
```

---

## 4. Migration Guide

### 4.1 Quick Migration Checklist

- [ ] Replace `CommandBus` → `CommandRouter`
- [ ] Replace `EventBus` → `EventBroadcaster`
- [ ] Replace `command_bus.handle()` → `command_router.register_handler()`
- [ ] Replace `command_bus.dispatch()` → `command_router.execute()`
- [ ] Replace `event_bus.publish()` → `event_broadcaster.broadcast()`
- [ ] Replace `event_bus.publish_async()` → `event_broadcaster.broadcast_and_await()`
- [ ] Replace `one_shot=true` → `once=true` in subscribe calls
- [ ] Replace `bound_object=obj` → `owner=obj` in subscribe calls
- [ ] Update error handling: `CommandBus.CommandError` → `CommandRouter.CommandRoutingError`
- [ ] Update error codes: `CommandError.ErrorCode` → `CommandRoutingError.Code`
- [ ] Update validation: `CommandRules.ValidationResult` → `CommandValidator.Result`

### 4.2 Example Migration

**Before**:
```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

var command_bus = Messaging.CommandBus.new()
var event_bus = Messaging.EventBus.new()

command_bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    return true
)

event_bus.subscribe(EnemyDiedEvent, _on_enemy_died, one_shot=true, bound_object=self)

var result = await command_bus.dispatch(MovePlayerCommand.new(Vector2(100, 200)))
event_bus.publish(EnemyDiedEvent.new(42, 100))
```

**After**:
```gdscript
const Messaging = preload("res://packages/messaging/messaging.gd")

var command_router = Messaging.CommandRouter.new()
var event_broadcaster = Messaging.EventBroadcaster.new()

command_router.register_handler(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
    return true
)

event_broadcaster.subscribe(EnemyDiedEvent, _on_enemy_died, once=true, owner=self)

var result = await command_router.execute(MovePlayerCommand.new(Vector2(100, 200)))
event_broadcaster.broadcast(EnemyDiedEvent.new(42, 100))
```

---

## 5. Behavioral Invariants (Must Remain True)

### 5.1 Command Routing

- ✅ Exactly one handler required (errors if 0 or 2+)
- ✅ Handler replacement: `register_handler()` replaces existing handler
- ✅ Pre-middleware can cancel execution (returns false)
- ✅ Post-middleware receives handler result
- ✅ Async handlers are awaited
- ✅ Metrics record execution time
- ✅ Error types: `NO_HANDLER`, `MULTIPLE_HANDLERS`, `HANDLER_FAILED`

### 5.2 Event Broadcasting

- ✅ 0..N listeners allowed
- ✅ Priority ordering: higher priority executes first
- ✅ Sequential execution (listeners called one after another)
- ✅ Async listeners are always awaited (prevents leaks)
- ✅ One-shot listeners auto-unsubscribe after first delivery
- ✅ Lifecycle-bound subscriptions auto-unsubscribe when owner is freed
- ✅ Pre-middleware can cancel broadcast (returns false)
- ✅ Post-middleware receives null (events don't return values)
- ✅ Metrics record total broadcast time

### 5.3 Subscription Management

- ✅ Subscriptions sorted by priority (descending)
- ✅ Invalid subscriptions cleaned up automatically
- ✅ Unsubscribe by callable removes all matching subscriptions
- ✅ Unsubscribe by ID removes specific subscription

### 5.4 Middleware

- ✅ Pre-middleware: receives (message, key), can cancel by returning false
- ✅ Post-middleware: receives (message, key, result)
- ✅ Middleware sorted by priority (descending)
- ✅ Middleware can be removed by ID

### 5.5 Metrics

- ✅ Metrics keys: `count`, `total_time`, `min_time`, `max_time`, `avg_time`
- ✅ Metrics enabled/disabled via `set_metrics_enabled()`
- ✅ Metrics cleared when disabled
- ✅ Metrics calculated per message type key

---

## 6. Implementation Notes

### 6.1 Directory Structure

Consider renaming `buses/` to `routers/` for CommandRouter, or keep both buses in `buses/`:

```
packages/messaging/
  buses/
    command_router.gd  (was command_bus.gd)
    event_broadcaster.gd  (was event_bus.gd)
  internal/
    subscription_registry.gd  (was message_bus.gd)
    message_type_resolver.gd
  rules/  (or rename to validation/?)
    command_validation.gd  (was command_rules.gd)
    subscription_validation.gd  (was subscription_rules.gd)
  types/
    message.gd
    command.gd
    event.gd
  adapters/
    signal_event_adapter.gd
  utilities/
    metrics_utils.gd
```

**Recommendation**: Keep `buses/` directory (EventBroadcaster is still a "bus" conceptually).

---

## 7. Testing Strategy

1. **Unit Tests**: Verify all renamed methods work identically to old methods
2. **Integration Tests**: Verify examples still work with new API
3. **Migration Tests**: Verify code using old API can be migrated to new API
4. **Regression Tests**: Verify behavioral invariants remain unchanged

---

## 8. Summary of Proposed Changes

### High-Impact (Public API)
- `CommandBus` → `CommandRouter`
- `EventBus` → `EventBroadcaster`
- `handle()` → `register_handler()`
- `dispatch()` → `execute()`
- `publish()` → `broadcast()`
- `publish_async()` → `broadcast_and_await()`

### Medium-Impact (Internal, but affects structure)
- `MessageBus` → `SubscriptionRegistry`
- `CommandRules` → `CommandValidator`
- `SubscriptionRules` → `SubscriptionValidator`
- `CommandError` → `CommandRoutingError`

### Low-Impact (Internal only)
- `Middleware` → `MiddlewareEntry`
- `Subscription` → `SubscriptionEntry`
- Internal method renames (`subscribe` → `register`, etc.)
- Variable renames (`_subscriptions` → `_registrations`, etc.)

### Parameter Names
- `one_shot` → `once`
- `bound_object` → `owner`

