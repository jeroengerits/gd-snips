## Engine addon - unified entry point for all gd-snips addons.
##
## This addon provides a single import point to access all other addons
## in the gd-snips collection.

# Message addon exports
const Message = preload("res://addons/message/message.gd")

# Subscribers addon exports
const Subscribers = preload("res://addons/subscribers/subscribers.gd")

# Middleware addon exports
const Middleware = preload("res://addons/middleware/middleware.gd")

# Utils addon exports
const Utils = preload("res://addons/utils/utils.gd")

# Event addon exports
const Event = preload("res://addons/event/event.gd")

# Command addon exports
const Command = preload("res://addons/command/command.gd")

# Support addon exports
const Support = preload("res://addons/support/support.gd")
