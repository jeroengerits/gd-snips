# Refactoring Opportunities: Generic Utility Functions

Analysis of the messaging package to identify code where generic utility functions would improve maintainability and reduce duplication.

## Classification Strategy

Utilities are classified into two categories:

1. **Generic Utilities** - Useful across multiple packages → Place in shared location (e.g., root `utilities/` or `common/utilities/`)
2. **Messaging-Specific Utilities** - Only needed within messaging package → Place in `messaging/utilities/`

## Proposed Structure

### Generic Utilities (Shared Across Packages)
```
utilities/  (or common/utilities/)
  collection_utils.gd    # Generic array/dictionary manipulation utilities
```

### Messaging-Specific Utilities
```
messaging/
  utilities/
    metrics_utils.gd     # Messaging-specific metrics calculations
```

All utility classes should use static methods for easy access without instantiation.

---

## 1. Time Conversion Utility

**Location**: Multiple files  
**Pattern**: Converting milliseconds to seconds  
**Frequency**: 3 occurrences  
**Classification**: ⚠️ **Borderline** - Very simple operation, could be generic but might not be worth extracting

### Current Code
```gdscript
# messaging/buses/command_bus.gd:146
var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0

# messaging/buses/event_bus.gd:151
var listener_elapsed: float = (Time.get_ticks_msec() - listener_start_time) / 1000.0

# messaging/buses/event_bus.gd:163
var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
```

### Recommendation
**Option A (Recommended)**: Keep inline - The operation is so simple (`ms / 1000.0`) that extracting it may add unnecessary abstraction. The current code is clear and readable.

**Option B (If extracting)**: If we want to extract it for consistency or future extensibility, it could go in a generic `utilities/time_utils.gd`, but this is likely overkill for such a simple operation.

**Decision**: **Skip extraction** - The operation is trivial and the current code is clear. Focus refactoring efforts on more substantial duplication.
```gdscript
extends RefCounted
## Utility functions for time conversions and calculations.

## Convert milliseconds to seconds.
## [code]milliseconds[/code]: Time in milliseconds (int)
## Returns: Time in seconds (float)
static func milliseconds_to_seconds(milliseconds: int) -> float:
    return milliseconds / 1000.0

## Calculate elapsed time in seconds from start and end timestamps.
## [code]start_ms[/code]: Start time in milliseconds
## [code]end_ms[/code]: End time in milliseconds (defaults to current time)
## Returns: Elapsed time in seconds (float)
static func elapsed_seconds(start_ms: int, end_ms: int = -1) -> float:
    if end_ms < 0:
        end_ms = Time.get_ticks_msec()
    return milliseconds_to_seconds(end_ms - start_ms)
```

---

## 2. Metrics Utilities (Average Time Calculation & Initialization)

**Location**: `messaging/internal/message_bus.gd`  
**Pattern**: Calculating average time from metrics dictionary & initializing metrics structure  
**Frequency**: 2 occurrences (average calculation) + 1 occurrence (initialization)  
**Classification**: ✅ **Messaging-Specific** - Works with messaging package's specific metrics dictionary structure

### Current Code
```gdscript
# messaging/internal/message_bus.gd:145-148 (in get_metrics)
if m.count > 0:
    result.avg_time = m.total_time / m.count
else:
    result.avg_time = 0.0

# messaging/internal/message_bus.gd:160-163 (in get_all_metrics)
if m.count > 0:
    metrics_dict.avg_time = m.total_time / m.count
else:
    metrics_dict.avg_time = 0.0

# messaging/internal/message_bus.gd:194-195 (in _record_metrics)
if not _metrics.has(key):
    _metrics[key] = {"count": 0, "total_time": 0.0, "min_time": INF, "max_time": 0.0}
```

### Recommendation
Create `messaging/utilities/metrics_utils.gd` (messaging-specific):
```gdscript
extends RefCounted
## Utility functions for metrics calculations and operations.

## Calculate average time from metrics dictionary.
## [code]metrics[/code]: Dictionary with 'count' and 'total_time' keys
## Returns: Average time in seconds (float), or 0.0 if count is 0
static func calculate_average_time(metrics: Dictionary) -> float:
    var count: int = metrics.get("count", 0)
    if count > 0:
        return metrics.get("total_time", 0.0) / count
    return 0.0

## Create an empty metrics dictionary structure.
## Returns: Dictionary with default metrics structure
static func create_empty_metrics() -> Dictionary:
    return {
        "count": 0,
        "total_time": 0.0,
        "min_time": INF,
        "max_time": 0.0
    }
```

**Usage**:
```gdscript
const MetricsUtils = preload("res://messaging/utilities/metrics_utils.gd")

# In get_metrics and get_all_metrics:
result.avg_time = MetricsUtils.calculate_average_time(m)

# In _record_metrics:
if not _metrics.has(key):
    _metrics[key] = MetricsUtils.create_empty_metrics()
```

**Benefits**:
- Eliminates duplication
- Single place to update if calculation logic changes
- More testable
- Metrics structure initialization also extracted (addresses item #4)

**Note**: These utilities are messaging-specific because they work with the messaging package's metrics dictionary structure (`count`, `total_time`, `min_time`, `max_time`). Other packages would have different metrics structures.

---

## 3. Array Cleanup with Dictionary Erasure Pattern

**Location**: `messaging/internal/message_bus.gd`  
**Pattern**: Removing items from array, then erasing dictionary key if array becomes empty  
**Frequency**: 4 occurrences with slight variations  
**Classification**: ✅ **Generic** - Useful pattern for any package dealing with arrays and dictionaries (caching, registries, collections)

### Current Code Patterns

**Pattern A** (in `unsubscribe_by_id` and `_mark_for_removal`):
```gdscript
subs.remove_at(index)
if subs.is_empty():
    _subscriptions.erase(key)
```

**Pattern B** (in `unsubscribe`):
```gdscript
for i in to_remove:
    subs.remove_at(i)
    removed += 1

if subs.is_empty():
    _subscriptions.erase(key)
```

**Pattern C** (in `_cleanup_invalid_subscriptions`):
```gdscript
for i in to_remove:
    subs.remove_at(i)

if subs.is_empty() and to_remove.size() > 0:
    _subscriptions.erase(key)
```

### Recommendation
Create `utilities/collection_utils.gd` (generic, shared across packages):
```gdscript
extends RefCounted
## Utility functions for array and dictionary manipulation.

## Remove items from array at given indices, then erase dictionary key if array becomes empty.
## 
## Note: Indices should be in descending order for safe removal during iteration.
## 
## [code]array[/code]: Array to remove items from
## [code]indices[/code]: Array of indices to remove (should be sorted descending)
## [code]dict[/code]: Dictionary that may need key erased
## [code]key[/code]: Key to erase from dict if array becomes empty after removal
static func remove_from_array_and_cleanup_key(array: Array, indices: Array, dict: Dictionary, key) -> void:
    for i in indices:
        if i >= 0 and i < array.size():
            array.remove_at(i)
    
    if array.is_empty():
        dict.erase(key)

## Erase dictionary key if array is empty (helper for cleanup pattern).
## [code]array[/code]: Array to check
## [code]dict[/code]: Dictionary that may need key erased
## [code]key[/code]: Key to erase from dict if array is empty
static func cleanup_empty_key(array: Array, dict: Dictionary, key) -> void:
    if array.is_empty():
        dict.erase(key)
```

**Usage**:
```gdscript
const CollectionUtils = preload("res://utilities/collection_utils.gd")

# Pattern A (single index removal):
subs.remove_at(index)
CollectionUtils.cleanup_empty_key(subs, _subscriptions, key)

# Pattern B (multiple indices):
for i in to_remove:
    subs.remove_at(i)
    removed += 1
CollectionUtils.cleanup_empty_key(subs, _subscriptions, key)
```

**Benefits**:
- Consistent cleanup behavior
- Reduces risk of forgetting to clean up empty arrays
- Easier to change cleanup logic in the future
- Generic and reusable across packages (caching, registries, collections, etc.)

**Note**: The `remove_from_array_and_cleanup_key` function provides a more comprehensive solution, but `cleanup_empty_key` is simpler and may be sufficient for most cases.

---

## 4. Metrics Dictionary Initialization

**Location**: `messaging/internal/message_bus.gd`  
**Pattern**: Initializing metrics dictionary structure  
**Frequency**: 1 occurrence  
**Classification**: ✅ **Messaging-Specific** - Creates messaging package's specific metrics structure

### Current Code
```gdscript
# messaging/internal/message_bus.gd:194-195
if not _metrics.has(key):
    _metrics[key] = {"count": 0, "total_time": 0.0, "min_time": INF, "max_time": 0.0}
```

### Recommendation
This is already addressed in **Item #2** above as part of `MetricsUtils.create_empty_metrics()`. See the metrics_utils.gd implementation in section 2.

---

## Implementation Plan

### Step 1: Create utilities folder structure
1. Create root `utilities/` directory (for generic utilities)
2. Create `messaging/utilities/` directory (for messaging-specific utilities)
3. Create utility files:
   - `utilities/collection_utils.gd` (generic)
   - `messaging/utilities/metrics_utils.gd` (messaging-specific)

### Step 2: Implement utility classes
Implement each utility class with static methods as outlined above.

### Step 3: Update imports and usage
1. Add `const` declarations at the top of files that need utilities:
   ```gdscript
   const CollectionUtils = preload("res://utilities/collection_utils.gd")
   const MetricsUtils = preload("res://messaging/utilities/metrics_utils.gd")
   ```
2. Replace inline code with utility function calls
3. Test to ensure behavior is unchanged

### Step 4: Update documentation
- Utilities are internal implementation details (not exported via `messaging.gd`)
- Note in code comments that `utilities/` contains generic utilities shared across packages
- Note in code comments that `messaging/utilities/` contains messaging-specific utilities

---

## Summary

### Generic Utilities (Shared Across Packages)
- ✅ **Array cleanup with dictionary erasure** (4 occurrences) → `utilities/collection_utils.gd`
  - Useful for any package dealing with arrays and dictionaries

### Messaging-Specific Utilities
- ✅ **Metrics utilities** (average calculation + initialization, 3 total occurrences) → `messaging/utilities/metrics_utils.gd`
  - Works with messaging package's specific metrics dictionary structure

### Not Recommended for Extraction
- ❌ **Time conversion** (3 occurrences) → Keep inline
  - Operation is too simple (`ms / 1000.0`) to warrant extraction
  - Current code is clear and readable
  - Focus refactoring efforts on more substantial duplication

## File Structure After Refactoring

```
gd-snips/
  utilities/                    # Generic utilities (shared across packages)
    collection_utils.gd
  messaging/
    utilities/                  # Messaging-specific utilities
      metrics_utils.gd
    buses/
      command_bus.gd            # Uses: MetricsUtils
      event_bus.gd              # Uses: MetricsUtils
    internal/
      message_bus.gd            # Uses: CollectionUtils, MetricsUtils
    ...
```

## Implementation Notes

- All utility classes use `extends RefCounted` with static methods for easy access
- Utility functions are pure functions (no side effects, no state)
- Utilities can be tested independently
- Utilities are internal implementation details (not exported via `messaging.gd`)
- Consider adding unit tests for utility functions
- Generic utilities in `utilities/` can be reused by other packages
- Messaging-specific utilities in `messaging/utilities/` are only for the messaging package
- Classification rationale:
  - **Generic**: Patterns that are useful across different domains/packages (e.g., array/dictionary manipulation)
  - **Package-specific**: Patterns tied to specific data structures or domain concepts (e.g., messaging metrics structure)

## Not Recommended for Refactoring

**Error Creation Pattern** (CommandBus.dispatch):
- While there's repetition in creating CommandError + push_error + _execute_middleware_post, this is domain-specific error handling logic that's better left explicit for clarity and maintainability
- The pattern includes domain-specific error codes and messages that vary significantly
- Error handling is tightly coupled to the CommandBus domain logic

