const Message = preload("res://addons/transport/message/message.gd")

extends RefCounted
class_name Middleware

## Base class for middleware implementations.
##
## Middleware intercepts messages (commands/events) before and after they reach
## their handlers or listeners. Use this as a base class for reusable middleware
## implementations, or use callables directly via add_middleware_before/after().

var priority: int = 0

func _init(middleware_priority: int = 0) -> void:
	priority = middleware_priority

## Process message before handler/listener execution.
## Return false to cancel delivery, true to continue.
func process_before(message: Message, message_key: StringName) -> bool:
	return true

## Process message after handler/listener execution.
func process_after(message: Message, message_key: StringName, result: Variant) -> void:
	pass

## Convert middleware instance to before-middleware callable.
func as_before_callable() -> Callable:
	return func(msg: Message, key: StringName) -> bool:
		return process_before(msg, key)

## Convert middleware instance to after-middleware callable.
func as_after_callable() -> Callable:
	return func(msg: Message, key: StringName, res: Variant) -> void:
		process_after(msg, key, res)

