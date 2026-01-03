const Messaging = preload("res://packages/messaging/messaging.gd")

extends Messaging.Command
class_name MovePlayerCommand

## Example command: Move player to a target position.
##
## Usage:
##   var cmd = MovePlayerCommand.new(Vector2(100, 200))
##   var result = await command_router.execute(cmd)

## Target position for player movement
var target_position: Vector2

## ID of the player to move (0 = default player)
var player_id: int = 0

func _init(pos: Vector2, player: int = 0) -> void:
	target_position = pos
	player_id = player
	super._init("move_player", {"target_position": pos, "player_id": player}, "Move player to position")

# Type identification handled automatically by MessageTypeResolver from class_name

func to_string() -> String:
	return "[MovePlayerCommand position=%s player_id=%d]" % [target_position, player_id]

