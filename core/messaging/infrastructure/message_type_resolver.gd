extends RefCounted
class_name MessageTypeResolver

## Infrastructure service for resolving message types from various sources.
##
## This handles the technical concern of extracting type identifiers from
## GDScript/Godot-specific constructs (scripts, class names, instances).
## Domain layer should not know about these implementation details.

## Resolve message type identifier from a message instance or type.
## 
## Accepts:
## - Message instances (with optional get_class_name() method)
## - Script resources (GDScript class references)
## - StringName/String literals
## - Object instances (fallback to script path or class name)
##
## Returns: StringName type identifier for routing
static func resolve_type(message_or_type) -> StringName:
	if message_or_type is StringName:
		return message_or_type
	elif message_or_type is String:
		return StringName(message_or_type)
	elif message_or_type is GDScript:
		# Handle Script resource (e.g., when passing MovePlayerCommand class directly)
		var path = message_or_type.resource_path
		if path != "":
			return StringName(path.get_file().get_basename())
		return StringName("UnknownScript")
	elif message_or_type is Object:
		# For instances, prefer get_class_name() if available (legacy support)
		if message_or_type.has_method("get_class_name"):
			var class_name = message_or_type.get_class_name()
			if class_name is StringName:
				return class_name
			elif class_name is String:
				return StringName(class_name)
		
		# Extract from script path (GDScript/Godot specific)
		var script = message_or_type.get_script()
		if script != null:
			var path = script.resource_path
			if path != "":
				return StringName(path.get_file().get_basename())
		
		# Fallback to GDScript class name
		return StringName(message_or_type.get_class())
	
	# Last resort: convert to string
	return StringName(str(message_or_type))

## Legacy alias for get_message_key compatibility.
## Use resolve_type() for new code.
static func get_message_key(message_type) -> StringName:
	return resolve_type(message_type)

## Legacy alias for get_key_from_message compatibility.
## Use resolve_type() for new code.
static func get_key_from_message(message: Object) -> StringName:
	return resolve_type(message)
