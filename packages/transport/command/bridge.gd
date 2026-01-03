const CommandBus = preload("res://packages/transport/command/command_bus.gd")
const CommandRoutingError = preload("res://packages/transport/command/command_routing_error.gd")

extends RefCounted
class_name CommandBridge

## Bridges Godot signals to CommandBus commands.

var _command_bus: CommandBus
var _connections: Array = []

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
		var command_data: Dictionary = {}
		
		if mapper.is_valid():
			# Use custom mapper
			command_data = mapper.callv(args)
		else:
			# Default: map signal args by position
			var arg_names = ["arg0", "arg1", "arg2", "arg3", "arg4"]
			for i in range(min(args.size(), arg_names.size())):
				command_data[arg_names[i]] = args[i]
		
		# Create and dispatch command
		var command = command_type.new(signal_name, command_data)
		var result = await _command_bus.dispatch(command)
		
		# Log errors if command dispatch failed
		if result is CommandRoutingError:
			push_error("[CommandBridge] Command dispatch failed: %s" % result.message)
	
	# Connect signal to callback
	if not source.connect(signal_name, callback):
		push_error("[CommandBridge] Failed to connect signal: %s" % signal_name)
		return
	
	# Store connection for cleanup
	_connections.append({
		"source": source,
		"signal": signal_name,
		"callback": callback
	})

## Disconnect all signals.
func disconnect_all() -> void:
	for conn in _connections:
		if is_instance_valid(conn.source) and conn.source.is_connected(conn.signal, conn.callback):
			conn.source.disconnect(conn.signal, conn.callback)
	_connections.clear()

## Get connection count.
func get_connection_count() -> int:
	return _connections.size()

## Cleanup on free.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		disconnect_all()

