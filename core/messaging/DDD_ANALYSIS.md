# Domain-Driven Design Analysis

## Executive Summary

**Overall Assessment**: Good structural separation (Domain/Infrastructure/Application layers) with clear boundaries, but the domain model is **anemic** and there are several **leakage violations** that weaken domain protection.

**Strategic Classification**: **Generic Subdomain** (supporting infrastructure), not core domain. Current investment level is appropriate.

**Priority Issues**:
1. 🔴 **Anemic Domain Model** - Domain objects are data containers without behavior
2. 🔴 **Infrastructure Leakage** - Domain knows about script paths (`get_class_name()`)
3. 🟡 **Missing Invariants** - No validation or business rule enforcement in domain
4. 🟡 **Misplaced Domain Logic** - "Exactly one handler" rule in application layer

---

## 1. Domain Model Quality

### ✅ Strengths

- **Value Objects Identified**: `Message`, `Command`, `Event` are correctly treated as value objects (immutable, equality by value)
- **Layer Separation**: Clear physical separation with `domain/`, `infrastructure/`, `application/`
- **Dependency Direction**: Correctly flows inward (Application → Infrastructure → Domain)

### ❌ Critical Issues

#### 1.1 Anemic Domain Model

**Problem**: Domain objects have no behavior, only data accessors.

```gdscript
# domain/message.gd - Lines 20-46
var _id: String
var _type: String
var _desc: String
var _data: Dictionary

func id() -> String: return _id
func type() -> String: return _type
func description() -> String: return _desc
func data() -> Dictionary: return _data.duplicate(true)
```

**Impact**: All business logic lives in application/infrastructure layers. Domain cannot express or enforce its own rules.

**Example**: If a `Command` must have a non-empty type, this isn't enforced:

```gdscript
# This should fail but doesn't:
var bad_cmd = Command.new("", {})  # Empty type!
```

#### 1.2 Missing Invariants

**Problem**: No validation or business rule enforcement.

**Missing Invariants**:
- Message type cannot be empty
- Message data must be provided (even if empty dict)
- Command type must follow naming conventions
- Event type must be past-tense (domain convention)

**Current State**: 
```gdscript
func _init(type: String, data: Dictionary = {}, desc: String = "") -> void:
	_id = str(get_instance_id())  # Uses instance ID, not domain identity
	_type = type                  # No validation
	_data = data.duplicate(true)  # No validation
```

#### 1.3 Identity Confusion

**Problem**: `Message.id()` uses `get_instance_id()` (technical identity) rather than domain identity.

```gdscript
# Line 26: domain/message.gd
_id = str(get_instance_id())
```

**Issue**: Value objects shouldn't rely on instance identity. Should use content-based identity or explicit domain ID.

**Impact**: Two messages with identical content are not equal:
```gdscript
var m1 = Message.new("damage", {"amount": 10})
var m2 = Message.new("damage", {"amount": 10})
m1.equals(m2)  # Returns false - wrong!
```

---

## 2. Ubiquitous Language

### ✅ Strengths

- **Consistent Terminology**: `Command`, `Event`, `Message`, `Subscription` align with domain
- **Clear Semantics**: "Command" = imperative action, "Event" = notification

### ❌ Issues

#### 2.1 Technical Language Leakage

**Problem**: `get_class_name()` is a technical concern, not domain language.

```gdscript
# domain/message.gd - Line 70
func get_class_name() -> StringName:
	var script = get_script()  # Infrastructure concept!
```

**Domain Language Violation**: Messages shouldn't know about scripts/classes. They should know about message types.

**Better**: `get_message_type()` or `message_type_identifier()`

#### 2.2 Mixed Abstractions

**Problem**: Domain uses both "type" (String) and "class_name" (StringName) inconsistently.

```gdscript
# domain/message.gd
var _type: String           # Line 21 - domain concept
func get_class_name() -> StringName  # Line 70 - infrastructure concept
```

**Issue**: Domain model mixes abstraction levels (business type vs technical class name).

---

## 3. Bounded Contexts & Boundaries

### ✅ Strengths

- **Single Bounded Context**: Messaging is a cohesive context (appropriate for a subdomain)
- **Clear Boundaries**: No coupling to external systems

### ⚠️ Observations

**No Explicit Context Map**: For a generic subdomain, this is acceptable. If this becomes a shared kernel, explicit context mapping would be needed.

**Integration Points**: Currently none (pure messaging). Good for a subdomain.

---

## 4. Aggregate Design

### ⚠️ Assessment

**No Aggregates Defined**: This is actually **correct** for this domain.

**Why**: 
- Messages are value objects (immutable, no identity lifecycle)
- MessageBus is a domain service/infrastructure service (stateless routing)
- No transaction boundaries needed (messages are fire-and-forget or request-response)

**Verdict**: Not applicable - this is a messaging infrastructure, not a domain with aggregates.

**Note**: If message persistence/ordering were added, you might need a `MessageStream` aggregate.

---

## 5. Application vs Domain Responsibilities

### 🔴 Critical Issues

#### 5.1 Domain Logic in Application Layer

**Problem**: The business rule "Commands have exactly one handler" is enforced in `CommandBus.dispatch()` (application layer).

```gdscript
# application/command_bus.gd - Lines 61-69
if subs.is_empty():
	var err = CommandBusError.new("No handler registered...")
	return err

if subs.size() > 1:
	var err = CommandBusError.new("Multiple handlers registered...")
	return err
```

**Issue**: This is a **domain invariant** (command semantics require single handler) but it's checked at runtime in application code.

**Better**: Domain should express this constraint, application enforces it. Could be:
- Domain validation in Command construction
- Domain service that validates command routing rules
- Explicit domain rule: `CommandRoutingRule.validate(subs)`

#### 5.2 Infrastructure Leakage in Domain

**Problem**: Domain objects use infrastructure concepts.

```gdscript
# domain/message.gd - Lines 70-76
func get_class_name() -> StringName:
	var script = get_script()           # Infrastructure!
	var path = script.resource_path     # File system!
	return StringName(path.get_file().get_basename())  # File parsing!
```

**Violation**: Domain should be framework-agnostic. Script paths are a GDScript/Godot concern.

**Impact**: Domain cannot be tested without Godot engine. Cannot be reused in different contexts.

**Solution**: Extract type identification to infrastructure layer. Domain should only know about message types as strings/names.

#### 5.3 MessageBus: Domain Service or Infrastructure?

**Current Classification**: Infrastructure (`infrastructure/message_bus.gd`)

**Analysis**: `MessageBus` has **domain knowledge**:
- Subscription priorities (domain concept: order matters)
- One-shot subscriptions (domain concept: fire-once semantics)
- Lifecycle binding (domain concept: object lifecycle)

**Question**: Should this be a Domain Service that Infrastructure implements?

**Current Design**: MessageBus in infrastructure, which is acceptable but blurs boundaries.

**Recommendation**: Keep as-is (it's routing infrastructure) but extract subscription rules to domain.

---

## 6. Strategic Design Observations

### Classification: Generic Subdomain ✅

**Rationale**:
- Messaging is reusable infrastructure (many games need it)
- Not differentiating business value (not competitive advantage)
- Well-understood patterns (command/event bus is standard)

**Investment Level**: ✅ **Appropriate**

**Justification**:
- Clean layer separation (good enough)
- No over-modeling (no unnecessary abstractions)
- Pragmatic implementation (works for use case)

**Signs of Appropriate Modeling**:
- ✅ Simple domain model (value objects only, no aggregates)
- ✅ Focus on infrastructure concerns (routing, subscriptions)
- ✅ No domain events or complex workflows

**If This Were Core Domain**: Would need:
- Rich domain model with invariants
- Domain events for messaging lifecycle
- Complex business rules about message ordering, delivery guarantees
- Saga/process managers for complex message flows

---

## 7. Anti-Patterns & Smells

### 🔴 Anemic Domain Model

**Severity**: High

**Evidence**: 
```gdscript
# domain/message.gd - All methods are getters
func id() -> String: return _id
func type() -> String: return _type
func description() -> String: return _desc
func data() -> Dictionary: return _data.duplicate(true)
```

**Impact**: 
- Business logic scattered in application layer
- Cannot enforce invariants
- Domain cannot express its own rules

**Example of Missing Behavior**:
```gdscript
# Should exist but doesn't:
func is_valid() -> bool:
	return _type != "" and _type.is_valid_identifier()

func with_type(new_type: String) -> Message:
	# Value object should support immutability patterns
	if new_type.is_empty():
		push_error("Message type cannot be empty")
		return self
	return Message.new(new_type, _data, _desc)
```

### 🟡 Transaction Script

**Severity**: Medium

**Evidence**: `CommandBus.dispatch()` is procedural:
```gdscript
func dispatch(command: Command) -> Variant:
	# 1. Lookup subscriptions
	var subs = _get_valid_subscriptions(key)
	# 2. Validate count
	if subs.is_empty(): return error
	if subs.size() > 1: return error
	# 3. Execute handler
	var result = sub.callable.call(command)
	# 4. Return result
	return result
```

**Impact**: All orchestration logic in one method. Hard to test, extend, or reason about.

**Better**: Extract to domain service:
```gdscript
# domain/services/command_routing_service.gd
func route_command(command: Command, handlers: Array[Callable]) -> RoutingResult:
	if handlers.is_empty():
		return RoutingResult.no_handler()
	if handlers.size() > 1:
		return RoutingResult.multiple_handlers()
	return RoutingResult.single_handler(handlers[0])
```

### 🟡 Infrastructure Leakage

**Severity**: Medium

**Evidence**: Domain uses script paths:
```gdscript
# domain/message.gd - Line 71
var script = get_script()  # GDScript/Godot specific
var path = script.resource_path  # File system
```

**Impact**: Domain tied to Godot engine. Cannot test without engine. Cannot reuse.

### ⚠️ Missing Domain Services

**Severity**: Low (acceptable for generic subdomain)

**Observation**: No explicit domain services for:
- Message validation
- Routing rule evaluation
- Subscription policy enforcement

**Note**: For a generic subdomain, this is acceptable. For core domain, would be needed.

---

## 8. Recommendations

### 🔴 High Impact (Do Now)

#### 8.1 Fix Infrastructure Leakage in Domain

**Action**: Remove `get_class_name()` from domain, move to infrastructure.

**Implementation**:
```gdscript
# domain/message.gd - REMOVE get_class_name()
# Remove lines 68-76

# infrastructure/message_type_resolver.gd - NEW
class_name MessageTypeResolver
static func resolve_type(message: Message) -> StringName:
	# Infrastructure knows about scripts/classes
	var script = message.get_script()
	# ... existing logic

# application/command_bus.gd - UPDATE
func dispatch(command: Command) -> Variant:
	var key = MessageTypeResolver.resolve_type(command)  # Use resolver
	# ...
```

**ROI**: High - Makes domain testable, reusable, framework-agnostic.

#### 8.2 Add Domain Invariants

**Action**: Enforce basic validation in domain constructors.

**Implementation**:
```gdscript
# domain/message.gd
func _init(type: String, data: Dictionary = {}, desc: String = "") -> void:
	if type.is_empty():
		push_error("Message type cannot be empty")
		type = "unknown"
	
	if data == null:
		push_error("Message data cannot be null")
		data = {}
	
	_id = _generate_domain_id(type, data)  # Domain identity, not instance ID
	_type = type
	_desc = desc
	_data = data.duplicate(true)

func _generate_domain_id(type: String, data: Dictionary) -> String:
	# Content-based ID for value object equality
	return "%s_%s" % [type, hash(data)]
```

**ROI**: High - Prevents invalid states, catches bugs early.

#### 8.3 Fix Value Object Equality

**Action**: Make equality content-based, not instance-based.

**Implementation**:
```gdscript
# domain/message.gd
func equals(other: Message) -> bool:
	if other == null:
		return false
	return _type == other._type and _data == other._data

func hash() -> int:
	return _type.hash() ^ _data.hash()
```

**ROI**: Medium - Correct value object semantics.

### 🟡 Medium Impact (Do Soon)

#### 8.4 Extract Domain Rules to Domain Service

**Action**: Move "exactly one handler" rule to domain.

**Implementation**:
```gdscript
# domain/services/command_routing_policy.gd
class_name CommandRoutingPolicy
extends RefCounted

enum ValidationResult {
	VALID,
	NO_HANDLER,
	MULTIPLE_HANDLERS
}

static func validate_handler_count(count: int) -> ValidationResult:
	if count == 0:
		return ValidationResult.NO_HANDLER
	if count > 1:
		return ValidationResult.MULTIPLE_HANDLERS
	return ValidationResult.VALID

# application/command_bus.gd
func dispatch(command: Command) -> Variant:
	var subs = _get_valid_subscriptions(key)
	var validation = CommandRoutingPolicy.validate_handler_count(subs.size())
	
	match validation:
		CommandRoutingPolicy.ValidationResult.NO_HANDLER:
			return CommandBusError.new(...)
		CommandRoutingPolicy.ValidationResult.MULTIPLE_HANDLERS:
			return CommandBusError.new(...)
		# VALID - continue
```

**ROI**: Medium - Makes domain rules explicit, testable.

#### 8.5 Add Rich Domain Methods

**Action**: Give domain objects behavior (even if simple).

**Implementation**:
```gdscript
# domain/message.gd
func is_valid() -> bool:
	return not _type.is_empty()

func has_data() -> bool:
	return not _data.is_empty()

func get_data_value(key: String, default = null):
	return _data.get(key, default)

# domain/command.gd
func is_executable() -> bool:
	return is_valid() and has_required_data()

func has_required_data() -> bool:
	# Domain-specific validation
	return true  # Override in subclasses
```

**ROI**: Medium - Reduces anemic model, centralizes logic.

### 🟢 Low Impact (Nice to Have)

#### 8.6 Add Domain Events for Messaging Lifecycle

**Action**: If messaging becomes core domain, add events like `CommandDispatched`, `EventPublished`.

**Implementation**: Only if this becomes core domain.

**ROI**: Low (for generic subdomain) - Over-engineering for current needs.

---

## Summary: What to Change vs. What to Keep

### ✅ Keep (Good Design)

1. **Layer Structure** - Domain/Infrastructure/Application separation is solid
2. **Dependency Direction** - Correct inward flow
3. **Value Object Pattern** - Messages as immutable value objects is correct
4. **Strategic Classification** - Generic subdomain, appropriate investment level
5. **Simple Domain Model** - For a subdomain, simplicity is correct

### 🔧 Fix (Critical Issues)

1. **Remove Infrastructure Leakage** - `get_class_name()` out of domain
2. **Add Invariants** - Validate in constructors
3. **Fix Equality** - Content-based, not instance-based
4. **Extract Domain Rules** - Command routing policy to domain service

### 📈 Improve (Quality)

1. **Reduce Anemic Model** - Add behavior methods
2. **Extract Domain Services** - Routing policy, validation rules
3. **Better Error Types** - Domain errors, not application errors

### ❌ Don't Change (Over-Engineering)

1. **No Aggregates** - Correct for this domain
2. **No Domain Events** - Not needed for generic subdomain
3. **No Repository Pattern** - Messages are transient, no persistence
4. **Keep It Simple** - Don't add complexity for hypothetical needs

---

## Conclusion

**Verdict**: **Good foundation with fixable violations**. The structure is solid (DDD layers), but the domain model is anemic and has infrastructure leakage.

**Priority**: Fix infrastructure leakage and add invariants (high ROI, low effort). Improve domain behavior incrementally.

**Strategic Fit**: Correctly classified as generic subdomain. Investment level is appropriate - don't over-model.

**Evolution Path**: 
1. Fix leaks (1-2 days)
2. Add invariants (1 day)
3. Extract domain services (2-3 days)
4. Rich domain methods (ongoing, as needed)

This aligns with "experienced team under delivery pressure" - pragmatic improvements, not academic rewrites.
