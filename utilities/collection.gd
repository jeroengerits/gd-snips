extends RefCounted
class_name Collection

## A fluent, object-oriented wrapper for working with arrays.
##
## Inspired by Laravel's Collection class, providing a convenient way to work
## with arrays using method chaining and expressive syntax.
##
## Usage:
##   var collection = Collection.new([1, 2, 3, 4, 5])
##   var evens = collection.filter(func(item): return item % 2 == 0).to_array()
##   var doubled = collection.map(func(item): return item * 2).to_array()

var _items: Array = []

## Create a new Collection instance.
##
## [code]items[/code]: Array to wrap (optional, defaults to empty array)
## [code]copy[/code]: If true, creates a copy of the array; if false, uses reference (default: true)
func _init(items: Array = [], copy: bool = true) -> void:
	if copy:
		_items = items.duplicate()
	else:
		_items = items

## Get the underlying array.
func to_array() -> Array:
	return _items.duplicate()

## Get the number of items in the collection.
func count() -> int:
	return _items.size()

## Check if the collection is empty.
func is_empty() -> bool:
	return _items.is_empty()

## Check if the collection is not empty.
func is_not_empty() -> bool:
	return not _items.is_empty()

## Get the first item in the collection.
##
## [code]default[/code]: Value to return if collection is empty (optional)
func first(default = null):
	return _items[0] if not _items.is_empty() else default

## Get the last item in the collection.
##
## [code]default[/code]: Value to return if collection is empty (optional)
func last(default = null):
	return _items[_items.size() - 1] if not _items.is_empty() else default

## Get an item at a specific index.
##
## [code]index[/code]: Index to retrieve
## [code]default[/code]: Value to return if index is out of bounds (optional)
func get(index: int, default = null):
	if index >= 0 and index < _items.size():
		return _items[index]
	return default

## Check if the collection contains a value.
##
## [code]value[/code]: Value to search for
func contains(value) -> bool:
	return _items.has(value)

## Check if the collection contains any of the given values.
##
## [code]values[/code]: Array of values to check
func contains_any(values: Array) -> bool:
	for value in values:
		if _items.has(value):
			return true
	return false

## Check if the collection contains all of the given values.
##
## [code]values[/code]: Array of values to check
func contains_all(values: Array) -> bool:
	for value in values:
		if not _items.has(value):
			return false
	return true

## Filter the collection using a callback.
##
## [code]callback[/code]: Callable(item) -> bool
## Returns: New Collection instance with filtered items
func filter(callback: Callable) -> Collection:
	var filtered: Array = []
	for item in _items:
		if callback.call(item):
			filtered.append(item)
	return Collection.new(filtered)

## Map each item using a callback.
##
## [code]callback[/code]: Callable(item) -> Variant
## Returns: New Collection instance with mapped items
func map(callback: Callable) -> Collection:
	var mapped: Array = []
	for item in _items:
		mapped.append(callback.call(item))
	return Collection.new(mapped)

## Reduce the collection to a single value.
##
## [code]callback[/code]: Callable(accumulator, item) -> Variant
## [code]initial[/code]: Initial value for accumulator (optional)
## Returns: The reduced value
func reduce(callback: Callable, initial = null):
	var accumulator = initial
	for item in _items:
		accumulator = callback.call(accumulator, item)
	return accumulator

## Execute a callback for each item.
##
## [code]callback[/code]: Callable(item) -> void
## Returns: Self for method chaining
func each(callback: Callable) -> Collection:
	for item in _items:
		callback.call(item)
	return self

## Find the first item that matches the callback.
##
## [code]callback[/code]: Callable(item) -> bool
## [code]default[/code]: Value to return if no match found (optional)
func find(callback: Callable, default = null):
	for item in _items:
		if callback.call(item):
			return item
	return default

## Remove items that match the callback.
##
## [code]callback[/code]: Callable(item) -> bool
## Returns: New Collection instance with items removed
func reject(callback: Callable) -> Collection:
	var filtered: Array = []
	for item in _items:
		if not callback.call(item):
			filtered.append(item)
	return Collection.new(filtered)

## Add an item to the end of the collection.
##
## [code]item[/code]: Item to add
## Returns: Self for method chaining
func push(item) -> Collection:
	_items.append(item)
	return self

## Remove and return the last item.
func pop():
	return _items.pop_back() if not _items.is_empty() else null

## Add an item to the beginning of the collection.
##
## [code]item[/code]: Item to add
## Returns: Self for method chaining
func unshift(item) -> Collection:
	_items.insert(0, item)
	return self

## Remove and return the first item.
func shift():
	return _items.pop_front() if not _items.is_empty() else null

## Remove an item by value.
##
## [code]value[/code]: Value to remove
## Returns: Self for method chaining
func remove(value) -> Collection:
	var index: int = _items.find(value)
	if index >= 0:
		_items.remove_at(index)
	return self

## Remove items at given indices.
##
## [code]indices[/code]: Array of indices to remove
## Returns: Self for method chaining
func remove_at_indices(indices: Array) -> Collection:
	if indices.is_empty():
		return self
	
	# Sort indices in descending order for safe removal
	var sorted_indices: Array = indices.duplicate()
	sorted_indices.sort()
	sorted_indices.reverse()
	
	# Remove items (from highest index to lowest to avoid index shifting issues)
	for i in sorted_indices:
		if i >= 0 and i < _items.size():
			_items.remove_at(i)
	
	return self

## Clear all items from the collection.
## Returns: Self for method chaining
func clear() -> Collection:
	_items.clear()
	return self

## Merge another collection or array into this one.
##
## [code]other[/code]: Collection or Array to merge
## Returns: New Collection instance with merged items
func merge(other) -> Collection:
	var merged: Array = _items.duplicate()
	if other is Collection:
		merged.append_array(other.to_array())
	elif other is Array:
		merged.append_array(other)
	return Collection.new(merged)

## Get unique items from the collection.
## Returns: New Collection instance with unique items
func unique() -> Collection:
	var seen: Dictionary = {}
	var unique_items: Array = []
	for item in _items:
		if not seen.has(item):
			seen[item] = true
			unique_items.append(item)
	return Collection.new(unique_items)

## Reverse the collection.
## Returns: New Collection instance with reversed items
func reverse() -> Collection:
	var reversed: Array = _items.duplicate()
	reversed.reverse()
	return Collection.new(reversed)

## Sort the collection.
##
## [code]reverse[/code]: Sort in reverse order (default: false)
## Returns: New Collection instance with sorted items
func sort(reverse: bool = false) -> Collection:
	var sorted_items: Array = _items.duplicate()
	sorted_items.sort()
	if reverse:
		sorted_items.reverse()
	return Collection.new(sorted_items)

## Slice the collection.
##
## [code]start[/code]: Start index (inclusive)
## [code]end[/code]: End index (exclusive, optional)
## Returns: New Collection instance with sliced items
func slice(start: int, end: int = -1) -> Collection:
	var end_index: int = end if end >= 0 else _items.size()
	var sliced: Array = []
	for i in range(start, end_index):
		if i >= 0 and i < _items.size():
			sliced.append(_items[i])
	return Collection.new(sliced)

## Take the first N items.
##
## [code]count[/code]: Number of items to take
## Returns: New Collection instance
func take(count: int) -> Collection:
	return slice(0, count)

## Skip the first N items.
##
## [code]count[/code]: Number of items to skip
## Returns: New Collection instance
func skip(count: int) -> Collection:
	return slice(count)

## Chunk the collection into groups of specified size.
##
## [code]size[/code]: Size of each chunk
## Returns: New Collection instance containing arrays of chunks
func chunk(size: int) -> Collection:
	var chunks: Array = []
	for i in range(0, _items.size(), size):
		chunks.append(_items.slice(i, i + size))
	return Collection.new(chunks)

## Clean up a dictionary key if this collection becomes empty.
##
## [code]dict[/code]: Dictionary that may need key erased
## [code]key[/code]: Key to erase from dict if collection is empty
## Returns: Self for method chaining
func cleanup_empty_key(dict: Dictionary, key) -> Collection:
	if _items.is_empty():
		dict.erase(key)
	return self

## Remove items at indices and clean up dictionary key if collection becomes empty.
##
## [code]indices[/code]: Array of indices to remove
## [code]dict[/code]: Dictionary that may need key erased
## [code]key[/code]: Key to erase from dict if collection becomes empty
## Returns: Self for method chaining
func remove_and_cleanup_key(indices: Array, dict: Dictionary, key) -> Collection:
	remove_at_indices(indices)
	cleanup_empty_key(dict, key)
	return self

## Convert collection to string representation.
func _to_string() -> String:
	return "Collection(%s)" % _items

