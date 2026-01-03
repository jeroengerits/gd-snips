const Message = preload("res://packages/messaging/types/message.gd")

extends Message
class_name Command

## Base class for command messages representing imperative actions.
##
## Commands represent requests to perform actions. They are dispatched through
## a [CommandBus] and must have exactly one handler. Commands can return values,
## making them suitable for request-response patterns.
##
## **Command Pattern:** Commands encapsulate action requests as objects, allowing
## you to parameterize objects with different requests, queue operations, and
## support undo/redo functionality if needed.
##
## **Key Characteristics:**
## - Must have exactly one handler
## - Can return values
## - Represent "do something" actions
## - Should be named with imperative verbs (e.g., "MovePlayer", "DealDamage")
##
## **Usage:** Extend this class to create domain-specific commands. Always define
## a [code]class_name[/code] for proper type resolution in the messaging system.
##
## @example Creating a command:
##   extends Command
##   class_name MovePlayerCommand
##
##   var target_position: Vector2
##
##   func _init(pos: Vector2) -> void:
##       target_position = pos
##       super._init("move_player", {"target_position": pos})
##
## @example Using a command:
##   var cmd = MovePlayerCommand.new(Vector2(100, 200))
##   var result = await command_bus.dispatch(cmd)

## Check if this command can be executed (has required data).
## Override in subclasses to add specific validation.
func is_executable() -> bool:
	return is_valid()

## Check if this command has all required data for execution.
## Override in subclasses to enforce required fields.
func has_required_data() -> bool:
	return true

## String representation for debugging.
func to_string() -> String:
	return "[Command id=%s type=%s desc=%s data=%s]" % [id(), type(), description(), data()]

## Static factory method.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Command:
	return Command.new(type, data, desc)

