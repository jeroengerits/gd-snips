extends RefCounted
class_name Message

## Concrete value object for messages sent through messaging systems.
##
## Can be instantiated directly or extended for specialized types.
## Messages are immutable data carriers configured via constructor.
##
## @example Direct instantiation:
##   var msg = Message.new("damage", {"amount": 10, "target": player})
##   var msg2 = Message.create("heal", {"amount": 5}, "Heal player")
##
## @example Subclassing:
##   extends Message
##   class_name DamageMessage
##
##   func _init(amount: int, target: Node) -> void:
##       super._init("damage", {"amount": amount, "target": target})

var _id: String
var _type: String
var _description: String
var _data: Dictionary

func _init(type: String, data: Dictionary = {}, description: String = "") -> void:
	_id = str(get_instance_id())
	_type = type
	_description = description
	_data = data.duplicate(true) # deep copy to discourage external mutation

## Unique identifier for this message instance.
##
## Used for tracking, logging, or preventing duplicate processing.
func get_id() -> String:
	return _id

## Message type identifier (e.g., "damage", "ui_notification").
##
## Used by handlers to determine processing logic.
func get_type() -> String:
	return _type

## Human-readable description for debugging and logging.
##
## Optional metadata. Defaults to empty string if not provided.
func get_description() -> String:
	return _description

## Message payload data as a dictionary.
##
## Returns a deep copy to prevent external mutation.
## Structure depends on message type. Common keys: "amount", "source", "target".
func get_data() -> Dictionary:
	return _data.duplicate(true)

## String representation for debugging.
func to_string() -> String:
	return "[Message id=%s type=%s desc=%s data=%s]" % [_id, _type, _description, _data]

## Serialize message to dictionary.
func to_dict() -> Dictionary:
	return {
		"id": _id,
		"type": _type,
		"description": _description,
		"data": _data.duplicate(true)
	}

## Check if this message equals another (by ID).
func equals(other: Message) -> bool:
	return other != null and other.get_id() == _id

## Hash value for use in dictionaries/sets (based on ID).
func hash() -> int:
	return _id.hash()

## Static factory method for convenient instantiation.
static func create(type: String, data: Dictionary = {}, description: String = "") -> Message:
	return Message.new(type, data, description)
