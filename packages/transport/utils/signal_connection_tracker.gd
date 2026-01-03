extends RefCounted
## Tracks and manages Godot signal connections for cleanup.
##
## Provides centralized connection management logic for components that bridge
## signals to other systems. Ensures all connections are properly tracked and
## can be cleaned up to prevent memory leaks.

var _connections: Array = []  # Array of {source: Object, signal: StringName, callback: Callable}

## Connect a signal and track the connection for later cleanup.
##
## @param source: The object emitting the signal
## @param signal_name: Name of the signal to connect
## @param callback: Callable to connect to the signal
## @param context_name: Optional context name for error messages (e.g., class name)
## @return: true if connection succeeded, false otherwise
func connect_and_track(source: Object, signal_name: StringName, callback: Callable, context_name: String = "") -> bool:
	assert(source != null, "Signal source cannot be null")
	assert(not signal_name.is_empty(), "Signal name cannot be empty")
	assert(callback.is_valid(), "Callback must be valid")
	
	var err: int = source.connect(signal_name, callback)
	if err != OK:
		var error_context: String = "[%s] " % context_name if not context_name.is_empty() else ""
		push_error("%sFailed to connect signal: %s (error: %d)" % [error_context, signal_name, err])
		return false
	
	# Store connection for cleanup
	_connections.append({
		"source": source,
		"signal": signal_name,
		"callback": callback
	})
	return true

## Disconnect all tracked connections.
##
## Safely disconnects all connections, checking for validity before disconnecting.
## Clears the internal connection list after cleanup.
func disconnect_all() -> void:
	for conn in _connections:
		if is_instance_valid(conn.source) and conn.source.is_connected(conn.signal, conn.callback):
			conn.source.disconnect(conn.signal, conn.callback)
	_connections.clear()

## Get the number of tracked connections.
func get_connection_count() -> int:
	return _connections.size()

## Check if any connections are tracked.
func has_connections() -> bool:
	return _connections.size() > 0

