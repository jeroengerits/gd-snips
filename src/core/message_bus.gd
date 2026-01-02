extends Node
class_name MessageBus

## Base class for message buses.
##
## Provides common interface for command and event buses.
## Can be used as an autoload singleton or instantiated as needed.

## Clear all handlers/subscribers.
## Must be implemented by subclasses.
func clear() -> void:
	push_error("MessageBus.clear() must be implemented by subclass")

