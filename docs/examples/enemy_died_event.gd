const Messaging = preload("res://packages/messaging/messaging.gd")

extends Messaging.Event
class_name EnemyDiedEvent

## Example event: Enemy died notification.
##
## Usage:
##   var evt = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
##   event_broadcaster.broadcast(evt)

## Unique identifier of the enemy that died
var enemy_id: int

## Points awarded for defeating this enemy
var points: int

## Position where the enemy died (for effects, loot, etc.)
var position: Vector2

func _init(e_id: int, pts: int, pos: Vector2 = Vector2.ZERO) -> void:
	enemy_id = e_id
	points = pts
	position = pos
	super._init("enemy_died", {"enemy_id": e_id, "points": pts, "position": pos}, "Enemy %d died (worth %d points)" % [e_id, pts])

# Type identification handled automatically by MessageTypeResolver from class_name

func to_string() -> String:
	return "[EnemyDiedEvent enemy_id=%d points=%d position=%s]" % [enemy_id, points, position]

