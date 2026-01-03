# Support

Utility functions in Godot 4.5.1+.

## Installation

1. Copy the `addons/support` directory into your Godot project's `addons/` folder
2. Open your project in Godot
3. Go to **Project → Project Settings → Plugins**
4. Enable the "Support" plugin

**Requirements:** Godot 4.5.1 or later

## Usage

You can use the barrel file to load all support utilities at once:

```gdscript
const Support = preload("res://addons/support/support.gd")

# Access utilities via Support namespace
Support.ArrayUtils.remove_indices(arr, [1, 3])
Support.StringUtils.is_blank("   ")
```

Or preload individual utilities:

```gdscript
const ArrayUtils = preload("res://addons/support/array.gd")
const StringUtils = preload("res://addons/support/string.gd")

# Array operations
var arr = [1, 2, 3, 4, 5]
ArrayUtils.remove_indices(arr, [1, 3])
# arr is now [1, 3, 5]

var entries = [Entry.new(priority=5), Entry.new(priority=10), Entry.new(priority=3)]
ArrayUtils.sort_by_priority(entries)
# entries are now sorted: priority 10, 5, 3

var numbers = [1, 2, 3, 4, 5]
var evens = ArrayUtils.filter(numbers, func(n): return n % 2 == 0)  # [2, 4]
var doubled = ArrayUtils.map(numbers, func(n): return n * 2)  # [2, 4, 6, 8, 10]
var found = ArrayUtils.find(numbers, func(n): return n > 3)  # 4
var unique = ArrayUtils.unique([1, 2, 2, 3, 1])  # [1, 2, 3]

# String operations
StringUtils.is_blank("   ")  # true
StringUtils.pad_left("42", 5, "0")  # "00042"
StringUtils.truncate("Hello World", 8)  # "Hello..."
StringUtils.to_title_case("hello world")  # "Hello World"
```

## API Reference

### ArrayUtils

#### `remove_indices(array: Array, indices: Array) -> void`

Safely removes items from an array at the specified indices. Indices are sorted and removed from highest to lowest to avoid index shifting issues.

**Parameters:**
- `array`: The array to remove items from (modified in place)
- `indices`: Array of integer indices to remove (can be unsorted)

#### `sort_by_priority(items: Array) -> void`

Sorts an array of items by their `priority` property in descending order (higher priority first).

**Parameters:**
- `items`: Array of items with a `priority` property (modified in place)

**Note:** Items must have a `priority` property (int) for this function to work correctly.

#### `filter(array: Array, predicate: Callable) -> Array`

Filters array elements matching predicate. Returns a new array containing only elements where the predicate returns `true`.

**Parameters:**
- `array`: The array to filter
- `predicate`: Callable that takes `(item)` and returns `bool`

#### `map(array: Array, mapper: Callable) -> Array`

Transforms array elements using mapper function. Returns a new array with transformed elements.

**Parameters:**
- `array`: The array to transform
- `mapper`: Callable that takes `(item)` and returns transformed value

#### `find(array: Array, predicate: Callable) -> Variant`

Finds first element matching predicate. Returns the first matching element, or `null` if not found.

**Parameters:**
- `array`: The array to search
- `predicate`: Callable that takes `(item)` and returns `bool`

#### `contains(array: Array, predicate: Callable) -> bool`

Checks if array contains element matching predicate. Returns `true` if any element matches, `false` otherwise.

**Parameters:**
- `array`: The array to check
- `predicate`: Callable that takes `(item)` and returns `bool`

#### `unique(array: Array) -> Array`

Removes duplicate elements from array. Returns a new array with duplicates removed, preserving order of first occurrence.

**Parameters:**
- `array`: The array to deduplicate

#### `first(array: Array) -> Variant`

Gets first element of array. Returns the first element, or `null` if array is empty.

**Parameters:**
- `array`: The array to get first element from

#### `last(array: Array) -> Variant`

Gets last element of array. Returns the last element, or `null` if array is empty.

**Parameters:**
- `array`: The array to get last element from

#### `shuffle(array: Array) -> void`

Shuffles array elements randomly using Fisher-Yates algorithm. Modifies the array in place.

**Parameters:**
- `array`: The array to shuffle (modified in place)

#### `chunk(array: Array, chunk_size: int) -> Array`

Splits array into chunks of specified size. Returns an array of arrays, each containing up to `chunk_size` elements.

**Parameters:**
- `array`: The array to chunk
- `chunk_size`: Size of each chunk

#### `flatten(array: Array, depth: int = -1) -> Array`

Flattens nested arrays into single array. Returns a new flattened array.

**Parameters:**
- `array`: Array that may contain nested arrays
- `depth`: Maximum depth to flatten (default: -1 for unlimited)

### StringUtils

#### `is_blank(str: String) -> bool`

Checks if string is empty or contains only whitespace.

#### `is_not_blank(str: String) -> bool`

Checks if string is not empty and contains non-whitespace characters.

#### `pad_left(str: String, length: int, pad_char: String = " ") -> String`

Pads string to specified length with character (left-pad).

#### `pad_right(str: String, length: int, pad_char: String = " ") -> String`

Pads string to specified length with character (right-pad).

#### `truncate(str: String, max_length: int, ellipsis: String = "...") -> String`

Truncates string to maximum length with optional ellipsis.

#### `capitalize(str: String) -> String`

Capitalizes first character of string.

#### `to_title_case(str: String) -> String`

Converts string to title case (capitalize first letter of each word).

#### `remove(str: String, substring: String) -> String`

Removes all occurrences of substring from string.

#### `starts_with_any(str: String, prefixes: Array) -> bool`

Checks if string starts with any of the given prefixes.

#### `ends_with_any(str: String, suffixes: Array) -> bool`

Checks if string ends with any of the given suffixes.

## License

[Add license information here]

