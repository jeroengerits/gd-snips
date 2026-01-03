const Message = preload("res://addons/transport/src/message/message.gd")

extends Message
class_name Command

## Base class for command messages.

## Check if command can be executed.
func is_executable() -> bool:
	return is_valid()

## Check if command has required data.
func has_required_data() -> bool:
	return true

## String representation.
func to_string() -> String:
	return "[Command id=%s type=%s desc=%s data=%s]" % [id(), type(), description(), data()]

## Create command.
static func create(type: String, data: Dictionary = {}, desc: String = "") -> Command:
	return Command.new(type, data, desc)

