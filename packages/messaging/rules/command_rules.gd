extends RefCounted
class_name CommandRules

## Domain service defining business rules for command routing.
##
## Encapsulates the domain invariant that commands must have exactly one handler.
## This separation of domain rules from infrastructure concerns follows Domain-Driven
## Design (DDD) principles and clean architecture.
##
## **Domain Rule:** Commands represent imperative actions that must be handled by
## exactly one handler. This ensures deterministic behavior and makes it clear
## which handler is responsible for processing each command type.
##
## **Separation of Concerns:** This class contains domain knowledge (business rules),
## while [CommandBus] handles infrastructure concerns (routing, subscription management).
##
## @note This class extends [RefCounted] and is automatically memory-managed.

enum ValidationResult {
	VALID,
	NO_HANDLER,
	MULTIPLE_HANDLERS
}

## Validate count against command routing rules.
##
## Domain rule: Commands must have exactly one handler.
##
## [code]count[/code]: Number of registered handlers
## Returns: ValidationResult indicating if routing rules are satisfied
static func validate_count(count: int) -> ValidationResult:
	assert(count >= 0, "Handler count must be non-negative")
	if count == 0:
		return ValidationResult.NO_HANDLER
	if count > 1:
		return ValidationResult.MULTIPLE_HANDLERS
	return ValidationResult.VALID

## Check if handler count satisfies command routing rules.
## [code]handler_count[/code]: Number of registered handlers
## Returns: true if handler count is valid (exactly one)
static func is_valid_handler_count(handler_count: int) -> bool:
	assert(handler_count >= 0, "Handler count must be non-negative")
	return validate_count(handler_count) == ValidationResult.VALID

