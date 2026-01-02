extends Message
class_name Event

## Event messages for declarative notifications.
##
## Use for notifications that something happened like "damage_dealt", "player_died", "inventory_opened".
## Typically handled by multiple subscribers and do not return results.

## String representation for debugging.
func to_string() -> String:
	return "[Event id=%s type=%s desc=%s data=%s]" % [id(), type(), description(), data()]

## Static factory method.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Event:
	return Event.new(type, data, desc)

