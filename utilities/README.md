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
- `contains_any(values)` - Check if collection contains any of the given values
- `contains_all(values)` - Check if collection contains all of the given values
- `find(callback, default)` - Find first item matching callback
- `to_array()` - Get the underlying array (returns a copy)

**Transformation:**
- `filter(callback)` - Filter items (returns new Collection)
- `map(callback)` - Transform items (returns new Collection)
- `reduce(callback, initial)` - Reduce to single value
- `reject(callback)` - Remove items matching callback
- `each(callback)` - Execute callback for each item (returns self for chaining)
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

### Dictionary Cleanup Pattern

Common pattern for managing arrays in dictionaries (caches, registries, subscriptions):

```gdscript
const Collection = preload("res://utilities/collection.gd")

var subscriptions: Dictionary = {}
var listeners: Array = []

# Remove a single item and cleanup if empty
listeners.erase(listener)
Collection.new(listeners, false).cleanup_empty_key(subscriptions, "my_event")

# Remove multiple items and cleanup if empty
var to_remove: Array = [0, 2]  # Indices to remove
Collection.new(listeners, false).remove_and_cleanup_key(to_remove, subscriptions, "my_event")
```

## Design Principles

- **Generic over specific:** These utilities work with any domain logic
- **Fluent API:** Collection class supports method chaining
- **Type-safe:** Explicit type annotations throughout
- **Godot conventions:** Follows `snake_case` and static method patterns

## When to Use

Use the Collection class for:
- Complex array operations with method chaining
- Functional programming patterns (map, filter, reduce)
- Expressive, readable code
- Managing collections in dictionaries with automatic cleanup

## See Also

- [Messaging Package](../messaging/README.md) - Uses Collection internally
- [Developer Diary: Utility Extraction](../docs/developer-diary/2026-01-03-utility-extraction-refactoring.md) - Background on utility design
