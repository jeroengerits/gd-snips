extends RefCounted
## Utility functions for array operations.

## Remove items at given indices from array (safe removal from highest to lowest index).
##
## @param array: The array to remove items from (modified in place)
## @param indices: Array of integer indices to remove (can be unsorted)
##
## Example:
## ```gdscript
## var arr = [1, 2, 3, 4, 5]
## ArrayUtils.remove_indices(arr, [1, 3])
## # arr is now [1, 3, 5]
## ```
static func remove_indices(array: Array, indices: Array) -> void:
	if indices.is_empty() or array.is_empty():
		return
	
	# Sort indices in descending order for safe removal
	var sorted_indices: Array = indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	
	# Remove items (from highest index to lowest to avoid index shifting issues)
	for i in sorted_indices:
		if i >= 0 and i < array.size():
			array.remove_at(i)

## Sort array of items by priority property (higher priority first).
##
## Items must have a `priority` property (int).
##
## @param items: Array of items with priority property (modified in place)
##
## Example:
## ```gdscript
## var entries = [Entry.new(priority=5), Entry.new(priority=10), Entry.new(priority=3)]
## ArrayUtils.sort_by_priority(entries)
## # entries are now sorted: priority 10, 5, 3
## ```
static func sort_by_priority(items: Array) -> void:
	items.sort_custom(func(a, b): return a.priority > b.priority)

