## Engine module - unified entry point for all gd-snips packages.
##
## This module provides a single import point to access all other packages
## in the gd-snips collection.

# Message package exports
const Message = preload("res://src/message/message.gd")

# Subscribers package exports
const Subscribers = preload("res://src/subscribers/subscribers.gd")

# Middleware package exports
const Middleware = preload("res://src/middleware/middleware.gd")

# Utils package exports
const Utils = preload("res://src/utils/utils.gd")

# Event package exports
const Event = preload("res://src/event/event.gd")

# Command package exports
const Command = preload("res://src/command/command.gd")

# Support package exports
const Support = preload("res://src/support/support.gd")
