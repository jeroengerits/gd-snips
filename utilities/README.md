# Shared Utilities

Generic utility functions for use across multiple packages in this collection.

These utilities are domain-agnostic and designed for reuse. Package-specific utilities live in their respective `utilities/` folders.

## Collection Utilities

**File:** `collection_utils.gd`

Utilities for managing arrays stored in dictionaries—common patterns for caches, registries, and subscription systems.

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

**Note:** Indices are automatically sorted in descending order for safe removal—no need to pre-sort.

## Design Principles

- **Generic over specific:** These utilities work with any domain logic
- **Pure functions:** No side effects beyond their parameters
- **Type-safe:** Explicit type annotations throughout
- **Godot conventions:** Follows `snake_case` and static method patterns

## When to Use

Use these utilities for:
- Managing collections in dictionaries (caches, registries, subscriptions)
- Automatic cleanup of empty collections
- Safe removal of multiple array items

For package-specific utilities (e.g., messaging metrics), place them in that package's `utilities/` folder.

## See Also

- [Messaging Package](../messaging/README.md) - Uses these utilities internally
- [Developer Diary: Utility Extraction](../docs/developer-diary/2026-01-03-utility-extraction-refactoring.md) - Background on utility design
