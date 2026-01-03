# Transport Package - Refactoring Proposals

**Date:** January 2026  
**Status:** Analysis & Recommendations  
**Approach:** Preserve behavior, improve maintainability, safety, and clarity

---

## 🔍 Problems Identified

### 1. **Documentation Type Reference Inconsistency** (Minor)
- **Location:** `packages/transport/README.md:170`
- **Issue:** References `CommandBus.CommandRoutingError` but type is exported as `CommandRoutingError` via `transport.gd`
- **Impact:** Confusing for users, incorrect import pattern
- **Priority:** Low

### 2. **EventBus Internal Method Naming** (Minor)
- **Location:** `event/event_bus.gd:66` - `_broadcast_internal()`
- **Issue:** Method named "broadcast" but public API uses "emit"
- **Impact:** Minor cognitive load when reading code
- **Priority:** Low

### 3. **Error Recovery in Event Listeners** (Medium)
- **Location:** `event/event_bus.gd:99-116`
- **Issue:** No error recovery mechanism. Listener errors crash entire system
- **Impact:** One bad listener can break entire event system
- **Current Behavior:** Errors propagate and crash (by design, documented)
- **Priority:** Medium (consider adding optional error callback/handler)

### 4. **Middleware Priority Sorting Performance** (Low)
- **Location:** `event/registry.gd:24-39`
- **Issue:** Full sort O(n log n) after each middleware addition
- **Impact:** Negligible for typical middleware counts (< 10), but could be optimized
- **Current Behavior:** Works correctly, performance is acceptable
- **Priority:** Low (premature optimization)

### 5. **ID Generation Overflow Risk** (Theoretical)
- **Location:** `middleware/middleware_entry.gd:10`, `event/subscription_entry.gd:14`
- **Issue:** `static var _next_id` could theoretically overflow (unlikely in practice)
- **Impact:** Theoretical only - would require 2^31+ entries
- **Priority:** Very Low (document if needed)

### 6. **Type Resolution Performance** (Low)
- **Location:** `type/message_type_resolver.gd:30-39`
- **Issue:** Instantiates GDScript classes to extract class_name
- **Impact:** Minor performance cost, but necessary for correctness
- **Current Behavior:** Correct and necessary
- **Priority:** Low (could cache but adds complexity)

### 7. **CommandBus Missing Error Export** (Minor)
- **Location:** `transport.gd`
- **Issue:** `CommandRoutingError` not exported in barrel file
- **Impact:** Users must import directly or use incorrect pattern
- **Priority:** Low

---

## 🧭 Refactoring Strategy

### Phase 1: Documentation & Clarity (Low Risk)
- Fix type reference in README
- Export CommandRoutingError in transport.gd
- Consider renaming `_broadcast_internal` to `_emit_internal` for consistency

### Phase 2: Error Handling Enhancement (Medium Risk)
- Add optional error callback to EventBus for listener errors
- Consider error recovery modes (continue/stop)
- Document error handling strategy clearly

### Phase 3: Performance Optimizations (If Needed)
- Only optimize if profiling shows bottlenecks
- Current performance appears acceptable

---

## 🛠️ Specific Recommendations

### Recommendation 1: Fix Documentation Type Reference
**File:** `packages/transport/README.md:170`

**Change:**
```gdscript
# Current (incorrect):
if result is CommandBus.CommandRoutingError:

# Proposed:
if result is Transport.CommandRoutingError:
# OR
if result is CommandRoutingError:  # If exported via transport.gd
```

**Rationale:** Matches actual export pattern and user expectations.

---

### Recommendation 2: Export CommandRoutingError
**File:** `packages/transport/transport.gd`

**Change:**
```gdscript
# Add:
const CommandRoutingError = preload("res://packages/transport/command/command_routing_error.gd")
```

**Rationale:** Makes error type accessible via barrel file, consistent with other exports.

---

### Recommendation 3: Rename Internal Method (Optional)
**File:** `event/event_bus.gd`

**Change:**
```gdscript
# Current:
func _broadcast_internal(evt: Event, await_async: bool) -> void:

# Proposed:
func _emit_internal(evt: Event, await_async: bool) -> void:
```

**Rationale:** Consistency with public API naming (`emit`, `emit_and_await`).

---

### Recommendation 4: Consider Error Callback (Future Enhancement)
**File:** `event/event_bus.gd`

**Concept:**
```gdscript
# Add optional error handler:
func set_listener_error_handler(callback: Callable) -> void:
    _listener_error_handler = callback

# In _broadcast_internal, wrap listener calls:
if _listener_error_handler.is_valid():
    # Wrap in error handler (GDScript limitation: no try/catch)
    # Would require Godot 4.x error handling features
```

**Rationale:** Allows applications to handle listener errors gracefully.  
**Trade-off:** Adds complexity, GDScript limitations make this difficult.

**Note:** Current behavior (errors propagate) is acceptable for most use cases and matches Godot conventions.

---

## 📌 Key Improvements & Trade-offs

### High-Value, Low-Risk Changes
1. ✅ **Export CommandRoutingError** - Simple, improves usability
2. ✅ **Fix README type reference** - Prevents confusion
3. ✅ **Rename `_broadcast_internal`** - Improves consistency (optional)

### Medium-Value, Medium-Risk Changes
4. ⚠️ **Error handling enhancement** - Adds complexity, but improves robustness
   - Consider only if users request it
   - GDScript limitations make this challenging

### Low-Value Changes (Premature Optimization)
5. ❌ **Middleware sorting optimization** - Not needed unless profiling shows issues
6. ❌ **Type resolution caching** - Adds complexity, current performance is fine
7. ❌ **ID overflow protection** - Theoretical only, not a practical concern

---

## ⚠️ Notes / Risks / Follow-ups

### Risks
- **Error handling changes** could break existing error propagation behavior
- **Method renames** require careful testing to ensure no hidden dependencies
- **Export additions** are safe but should be documented

### Follow-ups
1. **Consider error handling strategy** - Survey users on error handling needs
2. **Performance profiling** - Profile real-world usage before optimizing
3. **Type safety** - Consider if additional type hints would help

### What NOT to Change
- ✅ Current error propagation behavior (matches Godot conventions)
- ✅ Performance characteristics (acceptable for use case)
- ✅ Architecture (well-designed, clear separation of concerns)
- ✅ ID generation (works correctly, overflow is theoretical)

---

## Summary

The transport package is **well-architected and maintainable**. The identified issues are primarily:
- **Documentation clarifications** (easy fixes)
- **Minor naming inconsistencies** (optional improvements)
- **Potential enhancements** (future considerations)

**Recommended Action:** Implement Phase 1 (documentation fixes) immediately. Phase 2 (error handling) only if users request it. Skip Phase 3 (optimizations) unless profiling indicates need.

**Overall Assessment:** The codebase demonstrates good practices:
- Clear separation of concerns
- Appropriate use of assertions
- Good error messages
- Lifecycle-aware design
- Performance considerations (snapshots, cleanup)
- Clean API design

**Grade: A-** (Excellent, with minor polish opportunities)

