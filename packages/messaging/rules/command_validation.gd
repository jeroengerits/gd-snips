extends RefCounted
class_name CommandValidator

## Validation logic for command routing: exactly one handler required.

enum Result {
	VALID,
	NO_HANDLER,
	MULTIPLE_HANDLERS
}

## Validate handler count.
static func validate_count(count: int) -> Result:
	assert(count >= 0, "Handler count must be non-negative")
	if count == 0:
		return Result.NO_HANDLER
	if count > 1:
		return Result.MULTIPLE_HANDLERS
	return Result.VALID

## Check if handler count is valid.
static func is_valid_handler_count(handler_count: int) -> bool:
	assert(handler_count >= 0, "Handler count must be non-negative")
	return validate_count(handler_count) == Result.VALID

