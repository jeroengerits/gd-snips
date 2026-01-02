# Shared Utilities

Generic utility functions that can be used across multiple packages in this collection.

These utilities are designed to be reusable and are not tied to any specific package's implementation details.

## Collection Utilities

**File:** `collection_utils.gd`

Generic array and dictionary manipulation utilities for managing collections, caches, registries, and similar data structures.

### `cleanup_empty_key(array: Array, dict: Dictionary, key) -> void`

Erase a dictionary key if the associated array is empty.

This is a helper function for a common cleanup pattern: after removing items from an array stored in a dictionary, you often want to remove the dictionary key if the array becomes empty.

**Parameters:**
- `array` - Array to check for emptiness
- `dict` - Dictionary that may need the key erased
- `key` - Key to erase from dict if array is empty

**Example:**

```gdscript
const CollectionUtils = preload("res://utilities/collection_utils.gd")

var subscriptions: Dictionary = {}
var listeners: Array = []

# Remove a listener
listeners.erase(listener)

# Clean up the dictionary key if array is now empty
CollectionUtils.cleanup_empty_key(listeners, subscriptions, "my_event")
```

### `remove_from_array_and_cleanup_key(array: Array, indices: Array, dict: Dictionary, key) -> void`

Remove items from an array at given indices, then erase the dictionary key if the array becomes empty.

This function handles the common pattern of removing multiple items from an array and cleaning up the dictionary key if needed. Indices are automatically sorted in descending order for safe removal (to avoid index shifting issues).

**Parameters:**
- `array` - Array to remove items from
- `indices` - Array of indices to remove (will be sorted if needed)
- `dict` - Dictionary that may need key erased
- `key` - Key to erase from dict if array becomes empty after removal

**Example:**

```gdscript
const CollectionUtils = preload("res://utilities/collection_utils.gd")

var subscriptions: Dictionary = {}
var listeners: Array = [listener1, listener2, listener3]

# Find indices to remove
var to_remove: Array = []
for i in range(listeners.size()):
    if should_remove(listeners[i]):
        to_remove.append(i)

# Remove items and clean up if needed
CollectionUtils.remove_from_array_and_cleanup_key(
    listeners, 
    to_remove, 
    subscriptions, 
    "my_event"
)
```

**Note:** The indices don't need to be in descending order - the function will sort them automatically for safe removal.

## Usage Guidelines

- These utilities are **generic** and can be used by any package
- They follow Godot conventions: `snake_case` for functions, static methods
- All functions are pure (no side effects beyond their parameters)
- Functions use explicit type annotations for clarity

## When to Use

Use these utilities when you have:
- Collections stored in dictionaries (caches, registries, subscriptions)
- Need to clean up empty collections automatically
- Multiple items to remove from arrays safely

## Design Philosophy

These utilities were extracted from common patterns found across the codebase. They represent generic operations that aren't tied to any specific domain logic. If a utility is specific to a package's domain (like messaging metrics), it belongs in that package's `utilities/` folder instead.

## See Also

- [Messaging Package](../messaging/README.md) - Uses these utilities internally
- [Developer Diary: Utility Extraction](../docs/developer-diary/2026-01-03-utility-extraction-refactoring.md) - Background on why these utilities were created

