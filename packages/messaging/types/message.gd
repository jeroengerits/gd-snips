extends RefCounted
class_name Message

## Concrete value object for messages sent through messaging systems.
##
## Can be instantiated directly or extended for specialized types.
## Messages are immutable data carriers configured via constructor.
##
## @example Direct instantiation:
##   var msg = Message.new("damage", {"amount": 10, "target": player})
##   var msg2 = Message.create("heal", {"amount": 5}, "Heal")
##
## @example Subclassing:
##   extends Message
##   class_name DamageMessage
##
##   func _init(amount: int, target: Node) -> void:
##       super._init("damage", {"amount": amount, "target": target})

var _id: String
var _type: String
var _desc: String
var _data: Dictionary

func _init(type: String, data: Dictionary = {}, desc: String = "") -> void:
	# Domain invariants: enforce message type is not empty
	assert(not type.is_empty(), "Message type cannot be empty")
	if type.is_empty():
		push_error("Message type cannot be empty")
		type = "unknown"
	
	# Domain invariants: ensure data is not null
	assert(data != null, "Message data cannot be null")
	if data == null:
		push_error("Message data cannot be null")
		data = {}
	
	# Generate domain identity (content-based for value object equality)
	_id = _generate_domain_id(type, data)
	_type = type
	_desc = desc
	_data = data.duplicate(true)

## Generate domain identity based on message content (value object pattern).
## Two messages with identical type and data should have the same identity.
func _generate_domain_id(type: String, data: Dictionary) -> String:
	var data_hash: int = hash(data)
	return "%s_%d" % [type, data_hash]

## Unique identifier for this message instance.
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

## Check if this message equals another (content-based equality for value objects).
## Two messages are equal if they have the same type and data.
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

