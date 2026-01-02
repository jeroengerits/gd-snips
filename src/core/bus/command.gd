extends Message
class_name Command

## Concrete value object for command messages.
##
## Commands represent requests to perform an action. They are typically handled
## by a single handler and may return a result. Use commands for imperative
## operations like "deal damage", "move player", or "open inventory".
##
## Can be instantiated directly or extended for specialized types.
##
## @example Direct instantiation:
##   var cmd = Command.new("deal_damage", {"amount": 10, "target": enemy})
##   var cmd2 = Command.create("move_player", {"direction": Vector2.UP})
##
## @example Subclassing:
##   extends Command
##   class_name DealDamageCommand
##
##   func _init(amount: int, target: Node) -> void:
##       super._init("deal_damage", {"amount": amount, "target": target})

## String representation for debugging.
func to_string() -> String:
	return "[Command id=%s type=%s desc=%s data=%s]" % [get_id(), get_type(), get_description(), get_data()]

## Static factory method for convenient instantiation.
static func create(type: String, data: Dictionary = {}, description: String = "") -> Command:
	return Command.new(type, data, description)

