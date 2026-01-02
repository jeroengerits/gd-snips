extends RefCounted
## Generic utility functions for array and dictionary manipulation.
##
## These utilities are shared across packages and can be used anywhere
## array/dictionary cleanup patterns are needed (caching, registries, collections).

## Erase dictionary key if array is empty (helper for cleanup pattern).
##
## Common pattern: Remove items from an array, then clean up the dictionary
## key if the array becomes empty. This utility handles the cleanup step.
##
## [code]array[/code]: Array to check
## [code]dict[/code]: Dictionary that may need key erased
## [code]key[/code]: Key to erase from dict if array is empty
static func cleanup_empty_key(array: Array, dict: Dictionary, key) -> void:
	if array.is_empty():
		dict.erase(key)

## Remove items from array at given indices, then erase dictionary key if array becomes empty.
##
## Note: Indices should be in descending order for safe removal during iteration.
## If indices are not in descending order, they will be sorted before removal.
##
## [code]array[/code]: Array to remove items from
## [code]indices[/code]: Array of indices to remove
## [code]dict[/code]: Dictionary that may need key erased
## [code]key[/code]: Key to erase from dict if array becomes empty after removal
static func remove_from_array_and_cleanup_key(array: Array, indices: Array, dict: Dictionary, key) -> void:
	if indices.is_empty():
		return
	
	# Sort indices in descending order for safe removal
	var sorted_indices: Array = indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	
	# Remove items (from highest index to lowest to avoid index shifting issues)
	for i in sorted_indices:
		if i >= 0 and i < array.size():
			array.remove_at(i)
	
	# Clean up dictionary key if array is now empty
	cleanup_empty_key(array, dict, key)

