## Engine module - unified entry point for all gd-snips packages.
##
## This module provides a single import point to access all other packages
## in the gd-snips collection. All packages are located in the `src/` directory,
## and this barrel file provides convenient access without needing to manage
## individual package dependencies.
##
## Usage:
## ```gdscript
## const Engine = preload("res://src/engine.gd")
## var command_bus = Engine.Command.Bus.new()
## var event_bus = Engine.Event.Bus.new()
## ```
##
## All packages are available through this module:
## - Engine.Message - Message infrastructure
## - Engine.Subscribers - Subscriber management
## - Engine.Middleware - Middleware infrastructure
## - Engine.Utils - Metrics and signal utilities
## - Engine.Event - Event bus (one-to-many messaging)
## - Engine.Command - Command bus (one-to-one messaging)
## - Engine.Support - Array and string utilities

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
