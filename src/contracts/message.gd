# imessage.gd
@interface
class_name Message

## Interface for message objects that can be sent through messaging systems
## Implement this interface to create custom message types

## Returns the message type identifier
func get_message_type() -> String:
	pass

## Returns the message data/payload
func get_data() -> Dictionary:
	pass

## Returns true if the message should be processed immediately
func is_urgent() -> bool:
	pass

## Optional: Get a human-readable description of the message
func get_description() -> String:
	return ""

