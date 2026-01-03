## Public API entry point for the messaging system.
##
## Barrel file that exports all public types and classes used in the messaging
## package. This provides a convenient single import point for all messaging
## functionality including command and event buses, message types, and utilities.
##
## The messaging system implements the Command and Event patterns, providing
## decoupled communication between game systems. Commands represent imperative
## actions with exactly one handler, while Events represent notifications that
## can have zero or more subscribers.
##
## @example Import via barrel file:
##   const Messaging = preload("res://packages/messaging/messaging.gd")
##   var command_bus = Messaging.CommandBus.new()
##   var event_bus = Messaging.EventBus.new()
##
## @example Import specific types directly:
##   const CommandBus = preload("res://packages/messaging/messaging.gd").CommandBus
##   const Message = preload("res://packages/messaging/messaging.gd").Message
##
## @example Complete usage example:
##   const Messaging = preload("res://packages/messaging/messaging.gd")
##   
##   # Create buses
##   var command_bus = Messaging.CommandBus.new()
##   var event_bus = Messaging.EventBus.new()
##   
##   # Register command handler
##   command_bus.handle(MovePlayerCommand, func(cmd): return move_player(cmd.target_position))
##   
##   # Subscribe to events
##   event_bus.subscribe(EnemyDiedEvent, func(evt): update_score(evt.points))
##   
##   # Dispatch commands
##   await command_bus.dispatch(MovePlayerCommand.new(Vector2(10, 20)))
##   
##   # Publish events
##   event_bus.publish(EnemyDiedEvent.new(42, 100))

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

## Public API: Signal-to-Event adapter utility
const SignalEventAdapter = preload("res://packages/messaging/utilities/signal_event_adapter.gd")

## Public API: Event-to-Signal adapter utility
const EventSignalAdapter = preload("res://packages/messaging/utilities/event_signal_adapter.gd")

