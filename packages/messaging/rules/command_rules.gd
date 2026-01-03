extends RefCounted
class_name CommandRules

## Domain rules for command routing: exactly one handler required.

enum ValidationResult {
	VALID,
	NO_HANDLER,
	MULTIPLE_HANDLERS
}

## Validate handler count.
static func validate_count(count: int) -> ValidationResult:
	assert(count >= 0, "Handler count must be non-negative")
	if count == 0:
		return ValidationResult.NO_HANDLER
	if count > 1:
		return ValidationResult.MULTIPLE_HANDLERS
	return ValidationResult.VALID

## Check if handler count is valid.
static func is_valid_handler_count(handler_count: int) -> bool:
	assert(handler_count >= 0, "Handler count must be non-negative")
	return validate_count(handler_count) == ValidationResult.VALID

