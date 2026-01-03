const CommandBus = preload("res://addons/transport/command/command_bus.gd")
const CommandRoutingError = preload("res://addons/transport/command/command_routing_error.gd")
const Command = preload("res://addons/transport/command/command.gd")
const SignalConnectionTracker = preload("res://addons/transport/utils/signal_connection_tracker.gd")

extends RefCounted
class_name CommandSignalBridge

## Bridges Godot signals to CommandBus commands.

var _command_bus: CommandBus
var _connection_tracker: SignalConnectionTracker = SignalConnectionTracker.new()

## Create bridge.
func _init(command_bus: CommandBus) -> void:
	assert(command_bus != null, "CommandBus cannot be null")
	_command_bus = command_bus

## Connect signal to command type.
func connect_signal_to_command(source: Object, signal_name: StringName, command_type, mapper: Callable = Callable()) -> void:
	assert(source != null, "Signal source cannot be null")
	assert(not signal_name.is_empty(), "Signal name cannot be empty")
	assert(command_type != null, "Command type cannot be null")
	
	var callback = func(...args):
		var command = null
		
		if mapper.is_valid():
			# Use custom mapper - mapper should construct and return a command instance
			# Example: func(): return SaveGameCommand.new()
			# Or with signal args: func(button): return SaveGameCommand.new()
			var mapped_result = mapper.callv(args)
			if mapped_result is Command:
				command = mapped_result
			else:
				push_error("[CommandSignalBridge] Mapper must return a Command instance, got: %s" % mapped_result)
				return
		else:
			# Default: create command using command_type constructor with signal name and data
			# Note: This assumes command_type.new(type: String, data: Dictionary) signature
			# Most commands have custom constructors, so provide a mapper for proper usage
			var command_data: Dictionary = {}
			var arg_names = ["arg0", "arg1", "arg2", "arg3", "arg4"]
			for i in range(min(args.size(), arg_names.size())):
				command_data[arg_names[i]] = args[i]
			command = command_type.new(signal_name, command_data)
		
		if command == null:
			push_error("[CommandSignalBridge] Failed to create command instance")
			return
		
		var result = await _command_bus.dispatch(command)
		
		# Log errors if command dispatch failed
		if result is CommandRoutingError:
			push_error("[CommandSignalBridge] Command dispatch failed: %s" % result.message)
	
	# Connect signal to callback and track for cleanup
	if not _connection_tracker.connect_and_track(source, signal_name, callback, "CommandSignalBridge"):
		return

## Disconnect all signals.
func disconnect_all() -> void:
	_connection_tracker.disconnect_all()

## Get connection count.
func get_connection_count() -> int:
	return _connection_tracker.get_connection_count()

## Cleanup on free.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_connection_tracker.disconnect_all()

