extends Command
class_name MovePlayerCommand

## Example command: Move player to a target position.
##
## Usage:
##   var cmd = MovePlayerCommand.new(Vector2(100, 200))
##   var result = await command_bus.dispatch(cmd)

var target_position: Vector2
var player_id: int = 0

func _init(pos: Vector2, player: int = 0) -> void:
	target_position = pos
	player_id = player
	super._init("move_player", {"target_position": pos, "player_id": player}, "Move player to position")

func get_class_name() -> StringName:
	return StringName("MovePlayerCommand")

func to_string() -> String:
	return "[MovePlayerCommand position=%s player_id=%d]" % [target_position, player_id]

