## Engine module - unified entry point for all gd-snips packages.
##
## This module provides a single import point to access all other packages
## in the gd-snips collection. All packages are standalone Godot addons located
## in the `addons/` directory, but this barrel file provides convenient access
## without needing to manage individual addon dependencies.
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
