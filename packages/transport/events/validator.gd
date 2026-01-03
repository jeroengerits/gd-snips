extends RefCounted
class_name Validator

## Validation logic for subscription behavior.

## Check if subscription a should process before b.
static func should_process_before(a_priority: int, b_priority: int) -> bool:
	return a_priority > b_priority

## Check if subscription should be removed after delivery.
static func should_remove_after_delivery(once: bool) -> bool:
	return once

## Check if subscription is valid for lifecycle.
static func is_valid_for_lifecycle(owner: Object) -> bool:
	if owner == null:
		return true  # Not bound to object, always valid
	
	return is_instance_valid(owner)

## Sort subscriptions by priority.
static func sort_by_priority(subscriptions: Array) -> void:
	subscriptions.sort_custom(func(a, b): 
		return should_process_before(a.priority, b.priority)
	)

