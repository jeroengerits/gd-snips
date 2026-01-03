extends RefCounted
class_name MiddlewareEntry

## Middleware registry entry.

var callback: Callable
var priority: int = 0
var id: int

static var _next_id: int = 0

func _init(callback: Callable, priority: int = 0):
	self.callback = callback
	self.priority = priority
	self.id = _next_id
	_next_id += 1

