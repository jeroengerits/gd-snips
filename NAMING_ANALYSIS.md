# Code Analysis & Naming Recommendations

## Overview
This document analyzes the current naming conventions and suggests more human-readable, descriptive names that follow common programming idioms.

---

## Message Class (`message.gd`)

### Current vs Suggested Names

| Current | Suggested | Reasoning |
|---------|-----------|-----------|
| `desc()` | `description()` | Full word instead of abbreviation - more readable |
| `txt()` | `to_string()` | Standard naming convention for string conversion (matches common patterns like `toString()`, `__str__()`, etc.) |
| `dict()` | `to_dict()` | Standard naming convention for serialization - follows `to_*` pattern |
| `eq(other)` | `equals(other)` or `is_equal_to(other)` | Full word instead of abbreviation - more expressive and readable |

### Methods That Are Fine (No Change Needed)
- `id()` - Clear and concise, standard abbreviation
- `type()` - Clear and concise  
- `data()` - Clear and concise
- `hash()` - Standard method name (matches Godot/Object.hash())
- `create()` - Standard factory pattern name

### Rationale
- `description()` reads naturally: "message.description()" vs "message.desc()"
- `to_string()` and `to_dict()` follow the common `to_*` conversion pattern
- `equals()` is more self-documenting than `eq()`

---

## Bus Class (`bus.gd`)

### Current vs Suggested Names

| Current | Suggested | Reasoning |
|---------|-----------|-----------|
| `_subs` | `_subscribers` | Full word instead of abbreviation - clearer intent |
| `unhandle(type)` | `unregister_handler(type)` or `remove_handler(type)` | More descriptive verb - clearly states what it does |
| `handle(type, fn)` | `register_handler(type, fn)` | More explicit about the action (optional improvement) |

### Methods That Are Fine (No Change Needed)
- `on()` - Common event pattern, clear and concise
- `off()` - Common event pattern, clear and concise
- `send()` - Clear verb for command dispatch
- `emit()` - Clear verb for event publishing
- `clear()` - Clear and concise
- `_handlers` - Clear and descriptive

### Rationale
- `_subscribers` clearly indicates it's a collection of subscribers
- `unregister_handler()` is self-documenting - you immediately know it removes a handler
- `register_handler()` makes the action explicit (though `handle()` is also acceptable)

---

## Command & Event Classes

### Current vs Suggested Names

| Current | Suggested | Reasoning |
|---------|-----------|-----------|
| `txt()` | `to_string()` | Same reasoning as Message class - consistency |

### Methods That Are Fine (No Change Needed)
- `create()` - Standard factory pattern

---

## Summary of Recommended Changes

### High Priority (Most Impact)
1. `desc()` → `description()` in Message class
2. `txt()` → `to_string()` in Message, Command, and Event classes
3. `dict()` → `to_dict()` in Message class
4. `eq()` → `equals()` in Message class
5. `unhandle()` → `unregister_handler()` in Bus class
6. `_subs` → `_subscribers` in Bus class (private variable)

### Optional (Lower Impact)
1. `handle()` → `register_handler()` in Bus class (only if you want more explicit naming)
2. Consider `is_equal_to()` instead of `equals()` if you prefer more verbose naming

---

## Migration Considerations

If implementing these changes:

1. **Breaking Changes**: All of these are breaking changes that require updating calling code
2. **Documentation**: README.md will need updates to reflect new method names
3. **Backward Compatibility**: Consider keeping old methods as deprecated aliases if needed
4. **Search & Replace**: Most changes are straightforward find/replace operations

---

## Code Examples (Before → After)

### Message Usage
```gdscript
# Before
var msg = Message.create("damage", {"amount": 10})
print(msg.desc())
print(msg.txt())
var serialized = msg.dict()
if msg1.eq(msg2):
    # ...

# After
var msg = Message.create("damage", {"amount": 10})
print(msg.description())
print(msg.to_string())
var serialized = msg.to_dict()
if msg1.equals(msg2):
    # ...
```

### Bus Usage
```gdscript
# Before
bus.handle("deal_damage", handler_fn)
bus.unhandle("deal_damage")
bus.on("damage_dealt", subscriber_fn)

# After
bus.register_handler("deal_damage", handler_fn)  # or keep handle()
bus.unregister_handler("deal_damage")
bus.on("damage_dealt", subscriber_fn)  # unchanged
```

---

## Conclusion

The suggested names follow these principles:
- **Clarity**: Full words instead of abbreviations where it improves readability
- **Convention**: Follow standard naming patterns (`to_*` for conversions, `equals` for comparison)
- **Self-documentation**: Method names clearly express their purpose
- **Human-readable**: Names read naturally in English

