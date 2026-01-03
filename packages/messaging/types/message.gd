extends RefCounted
class_name Message

## Base class for all messages in the messaging system.
##
## Messages are immutable value objects that carry data between systems. They
## represent both commands (imperative actions) and events (notifications).
## Messages are configured via their constructor and cannot be modified after
## creation, ensuring thread-safety and predictable behavior.
##
## **Key Features:**
## - Immutable data carrier
## - Content-based identity (value object pattern)
## - Unique ID generated from type and data
## - Type-safe routing support
## - Dictionary-based payload storage
##
## **Identity:** Messages use content-based identity - two messages with the
## same type and data will have the same identity (ID). This makes them suitable
## for value object patterns and allows for deduplication if needed.
##
## **Extensibility:** You can extend this class directly for generic messages,
## or extend [Command] or [Event] for domain-specific message types.
##
## @example Direct instantiation:
##   var msg = Message.new("damage", {"amount": 10, "target": player})
##   var msg2 = Message.create("heal", {"amount": 5}, "Heal message")
##
## @example Subclassing for type safety:
##   extends Message
##   class_name DamageMessage
##
##   var amount: int
##   var target: Node
##
##   func _init(damage_amount: int, target_node: Node) -> void:
##       amount = damage_amount
##       target = target_node
##       super._init("damage", {"amount": amount, "target": target})
##
## @note All messages extend [RefCounted] and are automatically memory-managed.

var _id: String
var _type: String
var _desc: String
var _data: Dictionary

func _init(type: String, data: Dictionary = {}, desc: String = "") -> void:
	# Domain invariants: enforce message type is not empty
	assert(not type.is_empty(), "Message type cannot be empty")
	
	# Domain invariants: ensure data is not null (handle gracefully in release builds)
	var message_data: Dictionary = data if data != null else {}
	
	# Generate domain identity (content-based for value object equality)
	_id = _generate_domain_id(type, message_data)
	_type = type
	_desc = desc
	_data = message_data.duplicate(true)

## Generate domain identity based on message content (value object pattern).
## Two messages with identical type and data should have the same identity.
func _generate_domain_id(type: String, data: Dictionary) -> String:
	var data_hash: int = hash(data)
	return "%s_%d" % [type, data_hash]

## Get the unique identifier for this message instance.
##
## The ID is generated from the message type and data hash, ensuring that
## messages with identical type and data will have the same ID (content-based
## identity for value objects).
##
## @return The unique identifier as a [String]. Format: [code]"type_hash"[/code]
##
## @note This ID is generated at construction time and cannot be changed.
func id() -> String:
	return _id

## Message type identifier.
func type() -> String:
	return _type

## Human-readable description for debugging.
func description() -> String:
	return _desc

## Message payload data as a dictionary.
func data() -> Dictionary:
	return _data.duplicate(true)

## String representation for debugging.
func to_string() -> String:
	return "[Message id=%s type=%s desc=%s data=%s]" % [_id, _type, _desc, _data]

## Serialize message to dictionary.
func to_dict() -> Dictionary:
	return {
		"id": _id,
		"type": _type,
		"desc": _desc,
		"data": _data.duplicate(true)
	}

## Check if this message equals another message (content-based equality).
##
## Implements value object equality - two messages are considered equal if they
## have the same type and data, regardless of their instance identity.
##
## @param other The [Message] to compare against. Can be [code]null[/code].
##
## @return [code]true[/code] if messages have the same type and data, [code]false[/code] otherwise.
##
## @example:
##   var msg1 = Message.new("test", {"value": 10})
##   var msg2 = Message.new("test", {"value": 10})
##   print(msg1.equals(msg2))  # Prints: true (same type and data)
##
## @note This is different from reference equality ([code]==[/code] in GDScript).
##   Two different Message instances with the same content will be equal.
func equals(other: Message) -> bool:
	if other == null or not other is Message:
		return false
	return _type == other._type and _data == other._data

## Hash value for use in dictionaries/sets (content-based).
func hash() -> int:
	var type_hash: int = _type.hash()
	var data_hash: int = _data.hash()
	return type_hash ^ data_hash

## Check if this message is valid (has required domain invariants).
func is_valid() -> bool:
	return not _type.is_empty()

## Check if this message has data payload.
func has_data() -> bool:
	return not _data.is_empty()

## Get a specific data value by key.
## Returns default value if key doesn't exist.
func get_data_value(key: String, default = null) -> Variant:
	return _data.get(key, default)

## Check if this message has a specific data key.
func has_data_key(key: String) -> bool:
	return _data.has(key)

## Static factory method.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Message:
	return Message.new(type, data, desc)

