const Message = preload("res://packages/transport/type/message.gd")

extends RefCounted
class_name Middleware

## Base class for middleware implementations.
##
## Middleware intercepts messages (commands/events) before and after they reach
## their handlers or listeners. Use this as a base class for reusable middleware
## implementations, or use callables directly via add_middleware_pre/post().

var priority: int = 0

func _init(middleware_priority: int = 0) -> void:
	priority = middleware_priority

## Process message before handler/listener execution.
## Return false to cancel delivery, true to continue.
func process_pre(message: Message, message_key: StringName) -> bool:
	return true

## Process message after handler/listener execution.
func process_post(message: Message, message_key: StringName, result: Variant) -> void:
	pass

## Convert middleware instance to pre-middleware callable.
func as_pre_callable() -> Callable:
	return func(msg: Message, key: StringName) -> bool:
		return process_pre(msg, key)

## Convert middleware instance to post-middleware callable.
func as_post_callable() -> Callable:
	return func(msg: Message, key: StringName, res: Variant) -> void:
		process_post(msg, key, res)

