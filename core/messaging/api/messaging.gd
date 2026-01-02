## Public API entry point for the messaging system.
##
## Barrel file that exports all public types and classes.
## Use this to import the messaging system:
##
##   const Messaging = preload("res://core/messaging/api/messaging.gd")
##   var command_bus = Messaging.CommandBus.new()
##   var event_bus = Messaging.EventBus.new()
##
## Or import specific types:
##   const CommandBus = preload("res://core/messaging/api/messaging.gd").CommandBus
##   const Message = preload("res://core/messaging/api/messaging.gd").Message

## Public API: Command bus for dispatching commands with exactly one handler
const CommandBus = preload("res://core/messaging/api/command_bus.gd")

## Public API: Event bus for publishing events with 0..N subscribers
const EventBus = preload("res://core/messaging/api/event_bus.gd")

## Public API: Base message class
const Message = preload("res://core/messaging/messages/message.gd")

## Public API: Command base class (extends Message)
const Command = preload("res://core/messaging/messages/command.gd")

## Public API: Event base class (extends Message)
const Event = preload("res://core/messaging/messages/event.gd")

## Public API: Command rules domain service
const CommandRules = preload("res://core/messaging/rules/command_rules.gd")

## Public API: Subscription rules domain service
const SubscriptionRules = preload("res://core/messaging/rules/subscription_rules.gd")

