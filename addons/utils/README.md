# Utils

Utility functions in Godot 4.5.1+.

## Installation

1. Copy the `addons/utils` directory into your Godot project's `addons/` folder
2. Open your project in Godot
3. Go to **Project → Project Settings → Plugins**
4. Enable the "Utils" plugin

**Requirements:** Godot 4.5.1 or later

## Usage

```gdscript
const ArrayUtils = preload("res://addons/utils/array_utils.gd")

# Remove items at specific indices
var arr = [1, 2, 3, 4, 5]
ArrayUtils.remove_indices(arr, [1, 3])
# arr is now [1, 3, 5]

# Sort by priority property
var entries = [Entry.new(priority=5), Entry.new(priority=10), Entry.new(priority=3)]
ArrayUtils.sort_by_priority(entries)
# entries are now sorted: priority 10, 5, 3
```

## API Reference

### `remove_indices(array: Array, indices: Array) -> void`

Safely removes items from an array at the specified indices. Indices are sorted and removed from highest to lowest to avoid index shifting issues.

**Parameters:**
- `array`: The array to remove items from (modified in place)
- `indices`: Array of integer indices to remove (can be unsorted)

### `sort_by_priority(items: Array) -> void`

Sorts an array of items by their `priority` property in descending order (higher priority first).

**Parameters:**
- `items`: Array of items with a `priority` property (modified in place)

**Note:** Items must have a `priority` property (int) for this function to work correctly.

## License

[Add license information here]

