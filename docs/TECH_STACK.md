# Tech Stack Documentation

**Last Updated:** January 3, 2026  
**Godot Version:** 4.5.1+  
**Primary Language:** GDScript (typed)

This document gathers comprehensive documentation about the technologies used in this project, focusing on best practices, performance optimizations, and patterns relevant to our codebase.

---

## Core Technologies

### Godot Engine 4.5.1+

**Source:** Official Godot 4.5 Documentation  
**Library ID:** `/websites/godotengine_en_4_5`

Godot Engine is a free and open-source game engine that provides a comprehensive suite of tools for developing 2D and 3D games across various platforms.

**Key Features:**
- Cross-platform deployment
- GDScript, C#, and C++ support
- Built-in editor and tooling
- Reference-counted memory management

---

## GDScript Type Safety

### Type Annotations Best Practices

**Current Implementation:** ✅ We use explicit type annotations throughout the codebase.

**Best Practices from Godot Docs:**

1. **Always use type annotations for function parameters and return types:**
   ```gdscript
   # ✅ Good - explicit types
   func first(default: Variant = null) -> Variant:
       return _items[0] if not _items.is_empty() else default
   
   # ❌ Bad - untyped
   func first(default = null):
       return _items[0] if not _items.is_empty() else default
   ```

2. **Use Variant for truly dynamic types:**
   - When a parameter can accept multiple types
   - When return type depends on runtime behavior
   - Our messaging system uses `Variant` for flexible return types

3. **Type checking with `is_instance_of()`:**
   ```gdscript
   # More flexible than 'is' operator
   if is_instance_of(value, TYPE_INT):
       # Handle integer
   elif is_instance_of(value, Node):
       # Handle Node
   ```

**Our Implementation:** ✅ All messaging methods use explicit type annotations throughout.

---

## Memory Management: RefCounted vs Node

### When to Use RefCounted

**Current Usage:** ✅ We use `RefCounted` for all messaging classes (MessageBus, CommandBus, EventBus, Message, Command, Event).

**Best Practices:**

1. **RefCounted for data/logic classes:**
   - Classes that don't need scene tree integration
   - Utility classes and services
   - Data containers and value objects
   - **Our use case:** MessageBus, Message types, utilities

2. **Node for scene tree integration:**
   - Classes that need signals, groups, or scene tree access
   - Classes that need `_ready()`, `_process()`, etc.
   - **Our use case:** EventSignalAdapter (needs signals)

### Cleanup Patterns

**Critical Pattern:** ✅ We implement `_notification(NOTIFICATION_PREDELETE)` for cleanup.

**From Godot Docs:**
```gdscript
extends RefCounted
class_name SignalEventAdapter

func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        disconnect_all()  # Cleanup connections
```

**Why This Matters:**
- RefCounted objects don't automatically cleanup like Node objects
- Signal connections hold references and can cause memory leaks
- **Our implementation:** ✅ SignalEventAdapter uses this pattern

**Best Practice:** Always implement cleanup in `_notification()` for RefCounted classes that manage resources (connections, subscriptions, etc.).

---

## Async/Await Patterns

### GDScriptFunctionState and Memory Leaks

**Current Implementation:** ✅ We await async listeners to prevent memory leaks.

**From Godot Docs:**
- GDScriptFunctionState objects must be awaited or they leak memory
- Even "fire-and-forget" operations should await async results
- **Our implementation:** EventBus.publish() awaits async listeners

**Best Practice:**
```gdscript
# ✅ Good - await async results
result = sub.callable.call(evt)
if result is GDScriptFunctionState:
    result = await result  # Prevent memory leak

# ❌ Bad - leaks GDScriptFunctionState
result = sub.callable.call(evt)
# If result is GDScriptFunctionState, it leaks!
```

**Our Implementation:** ✅ EventBus correctly awaits all async listeners, even in "fire-and-forget" mode.

---

## Performance Optimization

### StringName vs String

**Current Usage:** ✅ We use `StringName` for message type keys (routing).

**Performance Characteristics:**

1. **StringName:**
   - Interned strings (shared across instances)
   - Faster dictionary lookups
   - Lower memory overhead for repeated strings
   - **Best for:** Dictionary keys, signal names, type identifiers
   - **Our use case:** Message type routing keys

2. **String:**
   - Copy-on-write semantics
   - Better for string manipulation
   - **Best for:** Text processing, user-facing strings

**Our Implementation:** ✅ MessageTypeResolver returns `StringName` for type keys, optimizing dictionary lookups.

### Dictionary vs Array Performance

**From Godot Docs:**

**Dictionary:**
- **Insert, Erase, Move:** Fastest (O(1) hash lookup)
- **Get, Set:** Fastest (O(1) hash lookup)
- **Iterate:** Fast (ordered iteration)
- **Find (by value):** Slowest (must iterate)

**Array:**
- **Append, Access by index:** Fast (O(1))
- **Insert/Remove at index:** Slower (O(n) shift)
- **Find:** O(n) linear search

**Our Implementation:**
- ✅ Use Dictionary for subscriptions (StringName → Array[Subscription])
- ✅ Use Array for ordered lists (subscriptions, middleware)
- ✅ Direct array operations with helper functions for safe removal

### Subscription Sorting Optimization

**Our Implementation:** ✅ Changed from O(n log n) sort to O(n) insertion.

**Before:**
```gdscript
subs.append(sub)
SubscriptionRules.sort_by_priority(subs)  # O(n log n)
```

**After:**
```gdscript
# Insert in sorted position - O(n)
var insert_pos: int = subs.size()
for i in range(subs.size() - 1, -1, -1):
    if subs[i].priority >= priority:
        insert_pos = i + 1
        break
subs.insert(insert_pos, sub)
```

**Performance Impact:** Significant improvement for high-frequency subscription/unsubscription patterns.

---

## Type Resolution and class_name

### Best Practices

**From Godot Docs:**
- `class_name` provides deterministic type identification
- `get_class()` returns the class_name if defined
- Script paths can vary across machines (not deterministic)

**Our Implementation:** ✅ MessageTypeResolver prioritizes `class_name` for consistency.

**Best Practice:**
```gdscript
# ✅ Good - use class_name
extends Message
class_name MovePlayerCommand

# ❌ Bad - relies on script path
extends Message
# No class_name - resolution depends on file path
```

**Our Recommendation:** Always use `class_name` for message types to ensure consistent routing.

---

## Memory Management Patterns

### Reference Counting in GDScript

**From Godot Docs:**
- GDScript uses reference counting (not garbage collection)
- Objects are freed when reference count reaches zero
- No garbage collection pauses (unlike C# or Lua)
- **No need for object pooling** in most cases

**Our Implementation:**
- ✅ All classes extend RefCounted (automatic memory management)
- ✅ Lifecycle binding uses `is_instance_valid()` for cleanup
- ✅ No manual memory management needed

### Weak References

**From Godot Docs:**
```gdscript
var weak_ref = weakref(my_object)
if weak_ref.get_ref() != null:
    # Object still exists
```

**Potential Use Case:** If we need to track objects without preventing garbage collection, but currently we use lifecycle binding which is simpler.

---

## Performance Considerations

### Dictionary Operations

**Our Usage Patterns:**
1. **Subscriptions Dictionary:** `StringName → Array[Subscription]`
   - Fast lookups by message type
   - Ordered arrays for priority-based iteration
   - ✅ Optimal pattern

2. **Metrics Dictionary:** `StringName → Dictionary{count, total_time, ...}`
   - Fast lookups by message type
   - ✅ Efficient for metrics tracking

### Array Operations

**Our Usage:**
- Subscription arrays (sorted by priority)
- Middleware arrays (sorted by priority)
- One-shot removal tracking

**Optimizations Applied:**
- ✅ Insertion sort instead of full sort (O(n) vs O(n log n))
- ✅ Safe removal using helper function that removes indices in descending order (handles index shifting)

---

## Testing and Debugging

### Type Checking

**Available Tools:**
```gdscript
typeof(variable)  # Returns Variant.Type enum
is_instance_of(value, type)  # More flexible than 'is'
```

**Our Usage:** ✅ We use `is` operator for type checks in assertions and validation.

### Performance Profiling

**From Godot Docs:**
- Use `Time.get_ticks_msec()` for timing (as we do)
- Consider `Performance` singleton for engine-level metrics
- **Our implementation:** ✅ Custom metrics tracking in MessageBus

---

## Best Practices Summary

### ✅ What We're Doing Right

1. **Type Safety:** Explicit type annotations throughout
2. **Memory Management:** Proper cleanup in `_notification()`
3. **Async Handling:** Awaiting GDScriptFunctionState to prevent leaks
4. **Performance:** Using StringName for dictionary keys
5. **Type Resolution:** Prioritizing class_name for consistency
6. **Optimization:** O(n) insertion sort instead of O(n log n) full sort

### 🔄 Potential Improvements

1. **Weak References:** Consider for tracking without preventing GC (if needed)
2. **Performance Monitoring:** Could add slow handler warnings
3. **Type Validation:** Could add runtime validation for class_name requirement

---

## References

- [Godot 4.5 Official Documentation](https://docs.godotengine.org/en/4.5/)
- [GDScript Advanced Topics](https://docs.godotengine.org/en/4.5/tutorials/scripting/gdscript/gdscript_advanced.html)
- [Best Practices Guide](https://docs.godotengine.org/en/4.5/tutorials/best_practices/index.html)
- [Performance Optimization](https://docs.godotengine.org/en/4.5/tutorials/performance/index.html)

---

**Note:** This documentation is based on official Godot 4.5 documentation gathered via Context7. It reflects best practices relevant to our codebase and validates our current implementation patterns.

