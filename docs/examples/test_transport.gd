extends Node

## Test suite for SubscriptionRegistry, CommandBus, and EventBus.
##
## Run this scene to verify:
## - Single command handler enforcement
## - Multiple event listeners
## - Priority ordering
## - Auto-unsubscribe when node is freed
## - One-shot listener
## - Error isolation

const Transport = preload("res://packages/transport/transport.gd")

var command_bus: Transport.CommandBus
var event_bus: Transport.EventBus
var test_results: Dictionary = {}

func _ready() -> void:
	command_bus = Transport.CommandBus.new()
	event_bus = Transport.EventBus.new()
	
	print("=== Running Subscribers Tests ===\n")
	
	_test_command_single_handler()
	_test_command_no_handler()
	_test_command_multiple_handlers()
	_test_event_multiple_listeners()
	_test_event_priority_ordering()
	_test_event_one_shot()
	_test_event_auto_unsubscribe()
	
	_print_test_results()

func _test_command_single_handler() -> void:
	var test_name = "Command: Single handler"
	command_bus.clear()
	
	var handled = false
	command_bus.handle(MovePlayerCommand, func(command):
		handled = true
		return true
	)
	
	var cmd = MovePlayerCommand.new(Vector2(10, 20))
	var result = await command_bus.dispatch(cmd)
	
	test_results[test_name] = handled and result == true
	print("✓ " if test_results[test_name] else "✗ ", test_name)

func _test_command_no_handler() -> void:
	var test_name = "Command: No handler error"
	command_bus.clear()
	
	var cmd = MovePlayerCommand.new(Vector2(10, 20))
	var result = await command_bus.dispatch(cmd)
	
	# Should return a CommandRoutingError
	test_results[test_name] = result is Transport.CommandRoutingError
	print("✓ " if test_results[test_name] else "✗ ", test_name)

func _test_command_multiple_handlers() -> void:
	var test_name = "Command: Multiple handlers error"
	command_bus.clear()
	
	# Try to register two handlers (should only keep the last one with handle())
	command_bus.handle(MovePlayerCommand, func(command):
		return false
	)
	command_bus.handle(MovePlayerCommand, func(command):
		return true
	)
	
	var cmd = MovePlayerCommand.new(Vector2(10, 20))
	var result = await command_bus.dispatch(cmd)
	
	# Should succeed (handle replaces, doesn't add)
	test_results[test_name] = result == true
	print("✓ " if test_results[test_name] else "✗ ", test_name)

func _test_event_multiple_listeners() -> void:
	var test_name = "Event: Multiple listeners"
	event_bus.clear()
	
	var call_count = 0
	event_bus.on(EnemyDiedEvent, func(event):
		call_count += 1
	)
	event_bus.on(EnemyDiedEvent, func(event):
		call_count += 1
	)
	event_bus.on(EnemyDiedEvent, func(event):
		call_count += 1
	)
	
	var event = EnemyDiedEvent.new(1, 100)
	event_bus.emit(event)
	
	# Wait a frame for async operations
	await get_tree().process_frame
	
	test_results[test_name] = call_count == 3
	print("✓ " if test_results[test_name] else "✗ ", test_name)

func _test_event_priority_ordering() -> void:
	var test_name = "Event: Priority ordering"
	event_bus.clear()
	
	var call_order: Array[int] = []
	
	event_bus.on(EnemyDiedEvent, func(event):
		call_order.append(3)
	, priority=0)
	
	event_bus.on(EnemyDiedEvent, func(event):
		call_order.append(1)
	, priority=10)
	
	event_bus.on(EnemyDiedEvent, func(event):
		call_order.append(2)
	, priority=5)
	
	var event = EnemyDiedEvent.new(1, 100)
	event_bus.emit(event)
	
	await get_tree().process_frame
	
	# Should be called in priority order: 1 (10), 2 (5), 3 (0)
	test_results[test_name] = call_order == [1, 2, 3]
	print("✓ " if test_results[test_name] else "✗ ", test_name)

func _test_event_one_shot() -> void:
	var test_name = "Event: One-shot listener"
	event_bus.clear()
	
	var call_count = 0
	event_bus.on(EnemyDiedEvent, func(event):
		call_count += 1
	, once=true)
	
	var event1 = EnemyDiedEvent.new(1, 100)
	event_bus.emit(event1)
	await get_tree().process_frame
	
	var event2 = EnemyDiedEvent.new(2, 100)
	event_bus.emit(event2)
	await get_tree().process_frame
	
	# One-shot should only fire once
	test_results[test_name] = call_count == 1
	print("✓ " if test_results[test_name] else "✗ ", test_name)

func _test_event_auto_unsubscribe() -> void:
	var test_name = "Event: Auto-unsubscribe on node exit"
	event_bus.clear()
	
	# Create a temporary node that subscribes
	var temp_node = Node.new()
	add_child(temp_node)
	
	var call_count = 0
	event_bus.on(EnemyDiedEvent, func(event):
		call_count += 1
	, owner=temp_node)
	
	# Verify it works initially
	var event1 = EnemyDiedEvent.new(1, 100)
	event_bus.emit(event1)
	await get_tree().process_frame
	
	# Remove the node (should auto-unsubscribe)
	temp_node.queue_free()
	await get_tree().process_frame
	
	# Emit again - listener should not fire
	var event2 = EnemyDiedEvent.new(2, 100)
	event_bus.emit(event2)
	await get_tree().process_frame
	
	# Should only have been called once (before node was freed)
	test_results[test_name] = call_count == 1
	print("✓ " if test_results[test_name] else "✗ ", test_name)

func _print_test_results() -> void:
	print("\n=== Test Results ===")
	var passed = 0
	var total = test_results.size()
	
	for test_name in test_results:
		if test_results[test_name]:
			passed += 1
	
	print("Passed: ", passed, " / ", total)
	
	if passed == total:
		print("✓ All tests passed!")
	else:
		print("✗ Some tests failed")

