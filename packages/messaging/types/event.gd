const Message = preload("res://packages/messaging/types/message.gd")

extends Message
class_name Event

## Base class for event messages representing declarative notifications.
##
## Events represent notifications that something has happened. They are published
## through an [EventBus] and can have zero or more subscribers. Events do not
## return values - they are fire-and-forget notifications.
##
## **Event Pattern:** Events decouple event producers from consumers, allowing
## multiple systems to react to the same occurrence without tight coupling.
##
## **Key Characteristics:**
## - Can have zero or more subscribers
## - Do not return values (fire-and-forget)
## - Represent "something happened" notifications
## - Should be named with past-tense verbs (e.g., "PlayerDied", "DamageDealt")
##
## **Usage:** Extend this class to create domain-specific events. Always define
## a [code]class_name[/code] for proper type resolution in the messaging system.
##
## @example Creating an event:
##   extends Event
##   class_name EnemyDiedEvent
##
##   var enemy_id: int
##   var points: int
##
##   func _init(e_id: int, pts: int) -> void:
##       enemy_id = e_id
##       points = pts
##       super._init("enemy_died", {"enemy_id": e_id, "points": pts})
##
## @example Using an event:
##   var evt = EnemyDiedEvent.new(42, 100)
##   await event_bus.publish(evt)

## String representation for debugging.
func to_string() -> String:
	return "[Event id=%s type=%s desc=%s data=%s]" % [id(), type(), description(), data()]

## Static factory method.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Event:
	return Event.new(type, data, desc)

