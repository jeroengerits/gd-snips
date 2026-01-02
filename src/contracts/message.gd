@interface
class_name Message

## Interface for message objects sent through messaging systems.
##
## Implement this interface to create message types that can be dispatched through
## a message bus or event system. Messages are immutable data carriers.
##
## @example
##   extends RefCounted
##   implements Message
##   class_name DamageMessage
##
##   var damage_amount: int
##   var target: Node
##
##   func get_id() -> String:
##       return str(get_instance_id())
##
##   func get_type() -> String:
##       return "damage"
##
##   func get_data() -> Dictionary:
##       return {"amount": damage_amount, "target": target}
##
##   func is_urgent() -> bool:
##       return true
##
##   func is_valid() -> bool:
##       return damage_amount > 0 and is_instance_valid(target)
##
##   func is_expired() -> bool:
##       return false

## Unique identifier for this message instance.
##
## Used for tracking, logging, or preventing duplicate processing.
func get_id() -> String:
	pass

## Message type identifier (e.g., "damage", "ui_notification").
##
## Used by handlers to determine processing logic.
func get_type() -> String:
	pass

## Human-readable description for debugging and logging.
##
## Optional metadata. Defaults to empty string if not implemented.
func get_description() -> String:
	return ""

## Message payload data as a dictionary.
##
## Structure depends on message type. Common keys: "amount", "source", "target".
func get_data() -> Dictionary:
	pass

## Whether the message should be processed immediately.
##
## Urgent messages are processed synchronously or with higher priority.
## Use for time-sensitive events like damage or critical state changes.
func is_urgent() -> bool:
	pass

## Whether the message is valid and can be processed.
##
## Invalid messages are ignored by handlers. Use to validate data or prerequisites.
func is_valid() -> bool:
	pass

## Whether the message has expired and should be ignored.
##
## Useful for time-sensitive messages that become irrelevant after a condition.
## Expired messages are typically discarded by the message bus.
func is_expired() -> bool:
	pass
