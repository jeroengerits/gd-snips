extends RefCounted
class_name Message

## Base class for all messages.

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

## Generate ID from message content.
func _generate_domain_id(type: String, data: Dictionary) -> String:
	var data_hash: int = hash(data)
	return "%s_%d" % [type, data_hash]

## Get unique identifier.
func id() -> String:
	return _id

## Get message type.
func type() -> String:
	return _type

## Get description.
func description() -> String:
	return _desc

## Get message data.
func data() -> Dictionary:
	return _data.duplicate(true)

## String representation.
func to_string() -> String:
	return "[Message id=%s type=%s desc=%s data=%s]" % [_id, _type, _desc, _data]

## Serialize to dictionary.
func to_dict() -> Dictionary:
	return {
		"id": _id,
		"type": _type,
		"desc": _desc,
		"data": _data.duplicate(true)
	}

## Check if message equals another (content-based).
func equals(other: Message) -> bool:
	if other == null or not other is Message:
		return false
	return _type == other._type and _data == other._data

## Get hash value.
func hash() -> int:
	var type_hash: int = _type.hash()
	var data_hash: int = _data.hash()
	return type_hash ^ data_hash

## Check if message is valid.
func is_valid() -> bool:
	return not _type.is_empty()

## Check if message has data.
func has_data() -> bool:
	return not _data.is_empty()

## Get data value by key.
func get_data_value(key: String, default = null) -> Variant:
	return _data.get(key, default)

## Check if message has data key.
func has_data_key(key: String) -> bool:
	return _data.has(key)

## Create message.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Message:
	return Message.new(type, data, desc)

