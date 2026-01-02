# Shared Utilities

Generic utility functions for use across multiple packages in this collection.

These utilities are domain-agnostic and designed for reuse. Package-specific utilities live in their respective `utilities/` folders.

## Collection Class

**File:** `collection.gd`

A fluent, object-oriented wrapper for working with arrays, inspired by Laravel's Collection class. Provides method chaining and expressive syntax for common array operations.

### Basic Usage

```gdscript
const Collection = preload("res://utilities/collection.gd")

# Create a collection
var collection = Collection.new([1, 2, 3, 4, 5])

# Filter items
var evens = collection.filter(func(item): return item % 2 == 0).to_array()

# Map items
var doubled = collection.map(func(item): return item * 2).to_array()

# Chain operations
var result = collection.filter(func(x): return x > 2).map(func(x): return x * 2).to_array()
```

### Common Methods

**Querying:**
- `count()` - Get the number of items
- `is_empty()` / `is_not_empty()` - Check if collection is empty
- `first(default)` / `last(default)` - Get first/last item
- `get(index, default)` - Get item at index
- `contains(value)` - Check if collection contains value
- `find(callback, default)` - Find first item matching callback

**Transformation:**
- `filter(callback)` - Filter items (returns new Collection)
- `map(callback)` - Transform items (returns new Collection)
- `reduce(callback, initial)` - Reduce to single value
- `reject(callback)` - Remove items matching callback
- `unique()` - Get unique items
- `reverse()` - Reverse the collection
- `sort(reverse)` - Sort the collection
- `slice(start, end)` - Get a slice
- `take(count)` - Take first N items
- `skip(count)` - Skip first N items
- `chunk(size)` - Split into chunks

**Modification:**
- `push(item)` - Add item to end
- `pop()` - Remove and return last item
- `unshift(item)` - Add item to beginning
- `shift()` - Remove and return first item
- `remove(value)` - Remove item by value
- `remove_at_indices(indices)` - Remove items at indices
- `clear()` - Clear all items
- `merge(other)` - Merge with another collection or array

**Dictionary Cleanup:**
- `cleanup_empty_key(dict, key)` - Erase dict key if collection is empty
- `remove_and_cleanup_key(indices, dict, key)` - Remove items and cleanup if empty

### Working with References

By default, Collection creates a copy of the array. To work with the original array reference:

```gdscript
var my_array: Array = [1, 2, 3]
var collection = Collection.new(my_array, false)  # false = use reference
collection.push(4)  # Modifies my_array directly
```

## Collection Utilities (Legacy)

**File:** `collection_utils.gd`

Static utility functions for backward compatibility. These now use the Collection class internally.

### `cleanup_empty_key(array: Array, dict: Dictionary, key) -> void`

Erase a dictionary key when its associated array becomes empty.

**Use when:** You remove items from an array and want to automatically clean up the dictionary key if the array is now empty.

```gdscript
const CollectionUtils = preload("res://utilities/collection_utils.gd")

var subscriptions: Dictionary = {}
var listeners: Array = []

listeners.erase(listener)
CollectionUtils.cleanup_empty_key(listeners, subscriptions, "my_event")
```

### `remove_from_array_and_cleanup_key(array: Array, indices: Array, dict: Dictionary, key) -> void`

Remove multiple items from an array by index, then clean up the dictionary key if the array becomes empty.

**Use when:** You need to remove several items at once and want safe, automatic cleanup.

```gdscript
const CollectionUtils = preload("res://utilities/collection_utils.gd")

var subscriptions: Dictionary = {}
var listeners: Array = [listener1, listener2, listener3]

var to_remove: Array = [0, 2]  # Indices to remove
CollectionUtils.remove_from_array_and_cleanup_key(
    listeners, 
    to_remove, 
    subscriptions, 
    "my_event"
)
```

**Note:** For new code, prefer using the Collection class directly for a more expressive API.

## Design Principles

- **Generic over specific:** These utilities work with any domain logic
- **Fluent API:** Collection class supports method chaining
- **Type-safe:** Explicit type annotations throughout
- **Godot conventions:** Follows `snake_case` and static method patterns
- **Backward compatible:** Legacy utilities still work

## When to Use

**Use Collection class for:**
- Complex array operations with method chaining
- Functional programming patterns (map, filter, reduce)
- Expressive, readable code

**Use static utilities for:**
- Simple one-off operations
- Backward compatibility with existing code
- Minimal overhead scenarios

## See Also

- [Messaging Package](../messaging/README.md) - Uses Collection internally
- [Developer Diary: Utility Extraction](../docs/developer-diary/2026-01-03-utility-extraction-refactoring.md) - Background on utility design
