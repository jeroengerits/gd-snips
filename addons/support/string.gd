extends RefCounted
## Utility functions for string operations.

## Check if string is empty or contains only whitespace.
##
## @param str: The string to check
## @return: true if string is empty or whitespace-only, false otherwise
##
## Example:
## ```gdscript
## StringUtils.is_blank("")  # true
## StringUtils.is_blank("   ")  # true
## StringUtils.is_blank("hello")  # false
## ```
static func is_blank(str: String) -> bool:
	return str.strip_edges().is_empty()

## Check if string is not empty and contains non-whitespace characters.
##
## @param str: The string to check
## @return: true if string has content (non-whitespace), false otherwise
##
## Example:
## ```gdscript
## StringUtils.is_not_blank("hello")  # true
## StringUtils.is_not_blank("")  # false
## StringUtils.is_not_blank("   ")  # false
## ```
static func is_not_blank(str: String) -> bool:
	return not is_blank(str)

## Pad string to specified length with character (left-pad).
##
## @param str: The string to pad
## @param length: Target length
## @param pad_char: Character to use for padding (default: space)
## @return: Padded string
##
## Example:
## ```gdscript
## StringUtils.pad_left("42", 5)  # "   42"
## StringUtils.pad_left("42", 5, "0")  # "00042"
## ```
static func pad_left(str: String, length: int, pad_char: String = " ") -> String:
	if str.length() >= length:
		return str
	return pad_char.repeat(length - str.length()) + str

## Pad string to specified length with character (right-pad).
##
## @param str: The string to pad
## @param length: Target length
## @param pad_char: Character to use for padding (default: space)
## @return: Padded string
##
## Example:
## ```gdscript
## StringUtils.pad_right("42", 5)  # "42   "
## StringUtils.pad_right("42", 5, "0")  # "42000"
## ```
static func pad_right(str: String, length: int, pad_char: String = " ") -> String:
	if str.length() >= length:
		return str
	return str + pad_char.repeat(length - str.length())

## Truncate string to maximum length with optional ellipsis.
##
## @param str: The string to truncate
## @param max_length: Maximum length (including ellipsis if used)
## @param ellipsis: String to append when truncated (default: "...")
## @return: Truncated string
##
## Example:
## ```gdscript
## StringUtils.truncate("Hello World", 8)  # "Hello..."
## StringUtils.truncate("Hello World", 8, "…")  # "Hello W…"
## ```
static func truncate(str: String, max_length: int, ellipsis: String = "...") -> String:
	if str.length() <= max_length:
		return str
	if max_length <= ellipsis.length():
		return ellipsis.substr(0, max_length)
	return str.substr(0, max_length - ellipsis.length()) + ellipsis

## Capitalize first character of string.
##
## @param str: The string to capitalize
## @return: String with first character capitalized
##
## Example:
## ```gdscript
## StringUtils.capitalize("hello")  # "Hello"
## StringUtils.capitalize("HELLO")  # "HELLO"
## ```
static func capitalize(str: String) -> String:
	if str.is_empty():
		return str
	return str[0].to_upper() + str.substr(1)

## Convert string to title case (capitalize first letter of each word).
##
## @param str: The string to convert
## @return: String in title case
##
## Example:
## ```gdscript
## StringUtils.to_title_case("hello world")  # "Hello World"
## StringUtils.to_title_case("HELLO WORLD")  # "Hello World"
## ```
static func to_title_case(str: String) -> String:
	if str.is_empty():
		return str
	var words: Array = str.split(" ", false)
	var result: Array = []
	for word in words:
		if word.is_empty():
			continue
		result.append(capitalize(word.to_lower()))
	return " ".join(result)

## Remove all occurrences of substring from string.
##
## @param str: The string to modify
## @param substring: The substring to remove
## @return: String with all occurrences of substring removed
##
## Example:
## ```gdscript
## StringUtils.remove("hello world", "l")  # "heo word"
## StringUtils.remove("banana", "na")  # "ba"
## ```
static func remove(str: String, substring: String) -> String:
	return str.replace(substring, "")

## Check if string starts with any of the given prefixes.
##
## @param str: The string to check
## @param prefixes: Array of prefix strings to check
## @return: true if string starts with any prefix, false otherwise
##
## Example:
## ```gdscript
## StringUtils.starts_with_any("hello", ["he", "hi"])  # true
## StringUtils.starts_with_any("world", ["he", "hi"])  # false
## ```
static func starts_with_any(str: String, prefixes: Array) -> bool:
	for prefix in prefixes:
		if str.begins_with(prefix):
			return true
	return false

## Check if string ends with any of the given suffixes.
##
## @param str: The string to check
## @param suffixes: Array of suffix strings to check
## @return: true if string ends with any suffix, false otherwise
##
## Example:
## ```gdscript
## StringUtils.ends_with_any("hello.txt", [".txt", ".md"])  # true
## StringUtils.ends_with_any("hello.txt", [".md", ".json"])  # false
## ```
static func ends_with_any(str: String, suffixes: Array) -> bool:
	for suffix in suffixes:
		if str.ends_with(suffix):
			return true
	return false

