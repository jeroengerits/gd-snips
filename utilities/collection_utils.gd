extends RefCounted
## Generic utility functions for array and dictionary manipulation.
##
## These utilities are shared across packages and can be used anywhere
## array/dictionary cleanup patterns are needed (caching, registries, collections).
##
## Note: These functions are now thin wrappers around the Collection class.
## For new code, consider using Collection directly for a fluent API.

const Collection = preload("res://utilities/collection.gd")

## Erase dictionary key if array is empty (helper for cleanup pattern).
##
## Common pattern: Remove items from an array, then clean up the dictionary
## key if the array becomes empty. This utility handles the cleanup step.
##
## [code]array[/code]: Array to check
## [code]dict[/code]: Dictionary that may need key erased
## [code]key[/code]: Key to erase from dict if array is empty
static func cleanup_empty_key(array: Array, dict: Dictionary, key) -> void:
	Collection.new(array, false).cleanup_empty_key(dict, key)

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
	Collection.new(array, false).remove_and_cleanup_key(indices, dict, key)

