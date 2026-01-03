const EventValidator = preload("res://packages/transport/event/event_validator.gd")

extends RefCounted
class_name Subscriber

## Subscriber entry.

var callable: Callable
var priority: int = 0
var once: bool = false
var owner: Object = null  # For lifecycle safety
var id: int

static var _next_id: int = 0

func _init(callable: Callable, priority: int = 0, once: bool = false, owner: Object = null):
	self.callable = callable
	self.priority = priority
	self.once = once
	self.owner = owner
	self.id = _next_id
	_next_id += 1

func is_valid() -> bool:
	if not EventValidator.is_valid_for_lifecycle(owner):
		return false
	return callable.is_valid()

func hash() -> int:
	return id

