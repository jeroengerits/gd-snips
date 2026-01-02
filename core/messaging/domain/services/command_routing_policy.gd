extends RefCounted
class_name CommandRoutingPolicy

## Domain service defining business rules for command routing.
##
## Encapsulates the domain invariant that commands must have exactly one handler.
## This is a domain rule, not an infrastructure or application concern.

enum ValidationResult {
	VALID,
	NO_HANDLER,
	MULTIPLE_HANDLERS
}

## Validate handler count against command routing rules.
##
## Domain rule: Commands must have exactly one handler.
##
## [code]handler_count[/code]: Number of registered handlers
## Returns: ValidationResult indicating if routing rules are satisfied
static func validate_handler_count(handler_count: int) -> ValidationResult:
	if handler_count == 0:
		return ValidationResult.NO_HANDLER
	if handler_count > 1:
		return ValidationResult.MULTIPLE_HANDLERS
	return ValidationResult.VALID

## Check if handler count satisfies command routing rules.
static func is_valid_handler_count(handler_count: int) -> bool:
	return validate_handler_count(handler_count) == ValidationResult.VALID
