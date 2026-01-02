extends RefCounted
## Infrastructure service for resolving message types from various sources.
##
## This handles the technical concern of extracting type identifiers from
## GDScript/Godot-specific constructs (scripts, class names, instances).
## Domain layer should not know about these implementation details.
##
## Internal implementation - do not use directly. Use via MessageBus.

## Resolve message type identifier from a message instance or type.
## 
## Accepts:
## - Script resources (GDScript class references)
## - StringName/String literals
## - Object instances (extracts from script path or class name)
##
## [code]message_or_type[/code]: Message instance, class, or type identifier
## Returns: StringName type identifier for routing
static func resolve_type(message_or_type) -> StringName:
	assert(message_or_type != null, "Message or type cannot be null")
	
	if message_or_type is StringName:
		return message_or_type
	elif message_or_type is String:
		return StringName(message_or_type)
	elif message_or_type is GDScript:
		# Handle Script resource (e.g., when passing MovePlayerCommand class directly)
		var path: String = message_or_type.resource_path
		if path != "":
			return StringName(path.get_file().get_basename())
		return StringName("UnknownScript")
	elif message_or_type is Object:
		# Prefer class_name if it exists (deterministic across machines)
		if message_or_type.has_method("get_class"):
			var class_name_str: String = message_or_type.get_class()
			if class_name_str != "" and class_name_str != "Object":
				return StringName(class_name_str)
		
		# Extract from script path (GDScript/Godot specific)
		var script: Script = message_or_type.get_script()
		if script != null:
			var path: String = script.resource_path
			if path != "":
				return StringName(path.get_file().get_basename())
		
		# Fallback to GDScript class name
		return StringName(message_or_type.get_class())
	
	# Last resort: convert to string
	return StringName(str(message_or_type))

