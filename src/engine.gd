## Engine module - unified entry point for all gd-snips packages.
##
## This module provides a single import point to access all other packages
## in the gd-snips collection.

# Message package exports
const Message = preload("res://addons/message/message.gd")

# Subscribers package exports
const Subscribers = preload("res://addons/subscribers/subscribers.gd")

# Middleware package exports
const Middleware = preload("res://addons/middleware/middleware.gd")

# Utils package exports
const Utils = preload("res://addons/utils/utils.gd")

# Event package exports
const Event = preload("res://addons/event/event.gd")

# Command package exports
const Command = preload("res://addons/command/command.gd")

# Support package exports
const Support = preload("res://addons/support/support.gd")
