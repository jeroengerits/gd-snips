const Message = preload("res://core/messaging/object/message.gd")

extends Message
class_name CoreMessagingEvent

## Event messages for declarative notifications.
##
## Use for notifications that something happened like "damage_dealt", "player_died", "inventory_opened".
## Typically handled by multiple subscribers and do not return results.

## String representation for debugging.
func to_string() -> String:
	return "[Event id=%s type=%s desc=%s data=%s]" % [id(), type(), description(), data()]

## Static factory method.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> CoreMessagingEvent:
	return CoreMessagingEvent.new(type, data, desc)

