const Message = preload("res://src/message/message_class.gd")

extends Message
class_name Event

## Base class for event messages.

## String representation.
func to_string() -> String:
	return "[Event id=%s type=%s desc=%s data=%s]" % [id(), type(), description(), data()]

## Create event.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Event:
	return Event.new(type, data, desc)

