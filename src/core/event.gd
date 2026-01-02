extends Message
class_name Event

## Concrete value object for event messages.
##
## Events represent notifications that something has happened. They are typically
## handled by multiple subscribers and do not return results. Use events for
## declarative notifications like "damage_dealt", "player_died", or "inventory_opened".
##
## Can be instantiated directly or extended for specialized types.
##
## @example Direct instantiation:
##   var evt = Event.new("damage_dealt", {"amount": 10, "target": enemy})
##   var evt2 = Event.create("player_died", {"player": player_node})
##
## @example Subclassing:
##   extends Event
##   class_name DamageDealtEvent
##
##   func _init(amount: int, target: Node) -> void:
##       super._init("damage_dealt", {"amount": amount, "target": target})

## String representation for debugging.
func to_string() -> String:
	return "[Event id=%s type=%s desc=%s data=%s]" % [get_id(), get_type(), get_description(), get_data()]

## Static factory method for convenient instantiation.
static func create(type: String, data: Dictionary = {}, description: String = "") -> Event:
	return Event.new(type, data, description)

