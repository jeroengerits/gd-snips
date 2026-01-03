## Core addon - unified entry point for all gd-snips addons.
##
## This addon provides a single import point to access all other addons
## in the gd-snips collection.

# Transport addon exports
const CommandBus = preload("res://addons/transport/src/command/command_bus.gd")
const EventBus = preload("res://addons/transport/src/event/event_bus.gd")

# Support addon exports
const Support = preload("res://addons/support/support.gd")
const Array = Support.Array
const String = Support.String

# Full addon access (for advanced usage)
const Transport = preload("res://addons/transport/transport.gd")

