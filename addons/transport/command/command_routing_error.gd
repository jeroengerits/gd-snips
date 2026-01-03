extends RefCounted
class_name CommandRoutingError

## Error raised during command routing/execution.

var message: String
var code: int

enum Code {
	NO_HANDLER,
	MULTIPLE_HANDLERS,
	HANDLER_FAILED
}

func _init(msg: String, err_code: int) -> void:
	assert(not msg.is_empty(), "CommandRoutingError message cannot be empty")
	assert(err_code >= 0, "CommandRoutingError code must be non-negative")
	message = msg
	code = err_code

func to_string() -> String:
	return "[CommandRoutingError: %s (code=%d)]" % [message, code]

