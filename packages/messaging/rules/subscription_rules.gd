extends RefCounted
class_name SubscriptionRules

## Domain service defining business rules for subscription behavior.
##
## Encapsulates domain concepts about subscription semantics, separating domain
## rules from infrastructure implementation. This follows Domain-Driven Design
## (DDD) principles and clean architecture.
##
## **Domain Rules:**
## - Priority ordering: Higher priority subscribers are processed before lower priority ones
## - One-shot subscriptions: Fire-once semantics - subscription is removed after first delivery
## - Lifecycle binding: Subscriptions tied to object lifecycle are invalidated when objects are freed
##
## **Separation of Concerns:** This class contains domain knowledge (subscription
## semantics), while [MessageBus] handles infrastructure concerns (subscription
## storage, iteration, cleanup).
##
## @note This class extends [RefCounted] and is automatically memory-managed.

## Compare two subscription priorities.
## Domain rule: Higher priority subscribers are processed first.
##
## [code]a_priority[/code]: Priority of first subscription
## [code]b_priority[/code]: Priority of second subscription
## Returns: true if subscription a should be processed before subscription b
static func should_process_before(a_priority: int, b_priority: int) -> bool:
	return a_priority > b_priority

## Check if a subscription should be removed after delivery.
## Domain rule: One-shot subscriptions are auto-unsubscribed after first delivery.
##
## [code]one_shot[/code]: Whether this is a one-shot subscription
## Returns: true if subscription should be removed after delivery
static func should_remove_after_delivery(one_shot: bool) -> bool:
	return one_shot

## Check if a subscription is still valid based on lifecycle binding.
## Domain rule: Subscriptions bound to objects are invalid when the object is freed.
##
## [code]bound_object[/code]: Object this subscription is bound to (null if not bound)
## Returns: true if subscription is still valid
static func is_valid_for_lifecycle(bound_object: Object) -> bool:
	if bound_object == null:
		return true  # Not bound to object, always valid
	
	return is_instance_valid(bound_object)

## Sort subscriptions by priority (higher priority first).
## Domain rule: Subscriptions are ordered by priority descending.
##
## [code]subscriptions[/code]: Array of subscriptions with priority property
static func sort_by_priority(subscriptions: Array) -> void:
	subscriptions.sort_custom(func(a, b): 
		return should_process_before(a.priority, b.priority)
	)

