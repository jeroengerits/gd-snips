extends Event
class_name EnemyDiedEvent

## Example event: Enemy died notification.
##
## Usage:
##   var evt = EnemyDiedEvent.new(42, 100, Vector2(50, 60))
##   event_bus.publish(evt)

var enemy_id: int
var points: int
var position: Vector2

func _init(e_id: int, pts: int, pos: Vector2 = Vector2.ZERO) -> void:
	enemy_id = e_id
	points = pts
	position = pos
	super._init("enemy_died", {"enemy_id": e_id, "points": pts, "position": pos}, "Enemy %d died (worth %d points)" % [e_id, pts])

func get_class_name() -> StringName:
	return StringName("EnemyDiedEvent")

func to_string() -> String:
	return "[EnemyDiedEvent enemy_id=%d points=%d position=%s]" % [enemy_id, points, position]

