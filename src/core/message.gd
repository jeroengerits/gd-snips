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
	_id = str(get_instance_id())
	_type = type
	_desc = desc
	_data = data.duplicate(true)

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

## Check if this message equals another (by ID).
func equals(other: Message) -> bool:
	return other != null and other.id() == _id

## Hash value for use in dictionaries/sets.
func hash() -> int:
	return _id.hash()

## Static factory method.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Message:
	return Message.new(type, data, desc)
