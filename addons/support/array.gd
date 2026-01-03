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

## Filter array elements matching predicate.
##
## @param array: The array to filter
## @param predicate: Callable that takes (item) and returns bool
## @return: New array containing only matching elements
##
## Example:
## ```gdscript
## var numbers = [1, 2, 3, 4, 5]
## var evens = ArrayUtils.filter(numbers, func(n): return n % 2 == 0)
## # evens is [2, 4]
## ```
static func filter(array: Array, predicate: Callable) -> Array:
	var result: Array = []
	for item in array:
		if predicate.call(item):
			result.append(item)
	return result

## Transform array elements using mapper function.
##
## @param array: The array to transform
## @param mapper: Callable that takes (item) and returns transformed value
## @return: New array with transformed elements
##
## Example:
## ```gdscript
## var numbers = [1, 2, 3]
## var doubled = ArrayUtils.map(numbers, func(n): return n * 2)
## # doubled is [2, 4, 6]
## ```
static func map(array: Array, mapper: Callable) -> Array:
	var result: Array = []
	for item in array:
		result.append(mapper.call(item))
	return result

## Find first element matching predicate.
##
## @param array: The array to search
## @param predicate: Callable that takes (item) and returns bool
## @return: First matching element, or null if not found
##
## Example:
## ```gdscript
## var items = [{"id": 1}, {"id": 2}, {"id": 3}]
## var found = ArrayUtils.find(items, func(item): return item.id == 2)
## # found is {"id": 2}
## ```
static func find(array: Array, predicate: Callable) -> Variant:
	for item in array:
		if predicate.call(item):
			return item
	return null

## Check if array contains element matching predicate.
##
## @param array: The array to check
## @param predicate: Callable that takes (item) and returns bool
## @return: true if any element matches, false otherwise
##
## Example:
## ```gdscript
## var numbers = [1, 2, 3, 4, 5]
## var has_even = ArrayUtils.contains(numbers, func(n): return n % 2 == 0)
## # has_even is true
## ```
static func contains(array: Array, predicate: Callable) -> bool:
	return find(array, predicate) != null

## Remove duplicate elements from array.
##
## @param array: The array to deduplicate
## @return: New array with duplicates removed (preserves order of first occurrence)
##
## Example:
## ```gdscript
## var arr = [1, 2, 2, 3, 1, 4]
## var unique = ArrayUtils.unique(arr)
## # unique is [1, 2, 3, 4]
## ```
static func unique(array: Array) -> Array:
	var seen: Dictionary = {}
	var result: Array = []
	for item in array:
		var key = item
		if not seen.has(key):
			seen[key] = true
			result.append(item)
	return result

## Get first element of array.
##
## @param array: The array to get first element from
## @return: First element, or null if array is empty
##
## Example:
## ```gdscript
## var arr = [1, 2, 3]
## var first = ArrayUtils.first(arr)  # 1
## ```
static func first(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[0]

## Get last element of array.
##
## @param array: The array to get last element from
## @return: Last element, or null if array is empty
##
## Example:
## ```gdscript
## var arr = [1, 2, 3]
## var last = ArrayUtils.last(arr)  # 3
## ```
static func last(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[array.size() - 1]

## Shuffle array elements randomly (Fisher-Yates algorithm).
##
## @param array: The array to shuffle (modified in place)
##
## Example:
## ```gdscript
## var arr = [1, 2, 3, 4, 5]
## ArrayUtils.shuffle(arr)
## # arr is now randomly shuffled
## ```
static func shuffle(array: Array) -> void:
	if array.size() <= 1:
		return
	for i in range(array.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp

## Split array into chunks of specified size.
##
## @param array: The array to chunk
## @param chunk_size: Size of each chunk
## @return: Array of arrays, each containing up to chunk_size elements
##
## Example:
## ```gdscript
## var arr = [1, 2, 3, 4, 5, 6, 7]
## var chunks = ArrayUtils.chunk(arr, 3)
## # chunks is [[1, 2, 3], [4, 5, 6], [7]]
## ```
static func chunk(array: Array, chunk_size: int) -> Array:
	if chunk_size <= 0:
		return []
	var result: Array = []
	for i in range(0, array.size(), chunk_size):
		result.append(array.slice(i, min(i + chunk_size, array.size())))
	return result

## Flatten nested arrays into single array.
##
## @param array: Array that may contain nested arrays
## @param depth: Maximum depth to flatten (default: -1 for unlimited)
## @return: New flattened array
##
## Example:
## ```gdscript
## var nested = [[1, 2], [3, [4, 5]]]
## var flat = ArrayUtils.flatten(nested)
## # flat is [1, 2, 3, 4, 5]
## ```
static func flatten(array: Array, depth: int = -1) -> Array:
	var result: Array = []
	_flatten_recursive(array, result, depth)
	return result

## Internal recursive helper for flatten.
static func _flatten_recursive(array: Array, result: Array, depth: int) -> void:
	if depth == 0:
		result.append_array(array)
		return
	for item in array:
		if item is Array:
			_flatten_recursive(item, result, depth - 1 if depth > 0 else -1)
		else:
			result.append(item)

