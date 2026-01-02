## Public API entry point for the messaging system.
##
## Barrel file that exports all public types and classes.
## Use this to import the messaging system:
##
##   const Messaging = preload("res://packages/messaging/messaging.gd")
##   var command_bus = Messaging.CommandBus.new()
##   var event_bus = Messaging.EventBus.new()
##
## Or import specific types:
##   const CommandBus = preload("res://packages/messaging/messaging.gd").CommandBus
##   const Message = preload("res://packages/messaging/messaging.gd").Message

## Public API: Command bus for dispatching commands with exactly one handler
const CommandBus = preload("res://packages/messaging/buses/command_bus.gd")

## Public API: Event bus for publishing events with 0..N subscribers
const EventBus = preload("res://packages/messaging/buses/event_bus.gd")

## Public API: Base message class
const Message = preload("res://packages/messaging/types/message.gd")

## Public API: Command base class (extends Message)
const Command = preload("res://packages/messaging/types/command.gd")

## Public API: Event base class (extends Message)
const Event = preload("res://packages/messaging/types/event.gd")

## Public API: Command rules domain service
const CommandRules = preload("res://packages/messaging/rules/command_rules.gd")

## Public API: Subscription rules domain service
const SubscriptionRules = preload("res://packages/messaging/rules/subscription_rules.gd")

