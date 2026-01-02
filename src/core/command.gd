extends Message
class_name Command

## Command messages for imperative actions.
##
## Use for requests to perform actions like "deal_damage", "move_player", "open_inventory".
## Typically handled by a single handler and may return results.

## String representation for debugging.
func to_string() -> String:
	return "[Command id=%s type=%s desc=%s data=%s]" % [id(), type(), description(), data()]

## Static factory method.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Command:
	return Command.new(type, data, desc)

