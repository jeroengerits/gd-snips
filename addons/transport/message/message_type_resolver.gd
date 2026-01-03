extends RefCounted
## Resolves message types from various sources.

# Internal flag for verbose warnings (only used in development)
static var _verbose: bool = false

## Enable verbose warning messages for type resolution issues.
static func set_verbose(enabled: bool) -> void:
	_verbose = enabled

## Resolve message type from various sources.
##
## @param message_or_type: Message instance, GDScript class, StringName, or String
## @return: StringName representing the resolved type
## @example:
## ```gdscript
## var key = MessageTypeResolver.resolve_type(MyCommand)  # GDScript class
## var key2 = MessageTypeResolver.resolve_type(my_command_instance)  # Object instance
## ```
static func resolve_type(message_or_type: Variant) -> StringName:
	assert(message_or_type != null, "Message or type cannot be null")
	
	# Handle StringName/String directly
	if message_or_type is StringName:
		return message_or_type
	elif message_or_type is String:
		return StringName(message_or_type)
	
	# Handle Object instances - prefer class_name (most deterministic)
	elif message_or_type is Object:
		var obj: Object = message_or_type
		var class_name_str: String = obj.get_class()
		
		# If class_name exists and is not "Object", use it
		if class_name_str != "" and class_name_str != "Object":
			return StringName(class_name_str)
		
		# Fallback: extract from script path
		var script: Script = obj.get_script()
		if script != null and script.resource_path != "":
			var resolved: StringName = StringName(script.resource_path.get_file().get_basename())
			if _verbose:
				push_warning("[MessageTypeResolver] Resolved Object type from script path: %s (class_name not set, consider adding class_name for better type resolution)" % resolved)
			return resolved
		
		# Last resort: use get_class() result (will be "Object" for plain objects)
		if _verbose and class_name_str == "Object":
			push_warning("[MessageTypeResolver] Could not resolve Object type - no class_name and no script path. Using 'Object' as fallback.")
		return StringName(class_name_str)
	
	# Handle GDScript class references - get class_name without instantiation
	elif message_or_type is GDScript:
		var script: GDScript = message_or_type
		
		# Prefer get_global_name() to avoid instantiation (no side effects, faster)
		var global_name: String = script.get_global_name()
		if global_name != "":
			return StringName(global_name)
		
		# Fallback: use script filename
		var path: String = script.resource_path
		if path != "":
			var resolved: StringName = StringName(path.get_file().get_basename())
			if _verbose:
				push_warning("[MessageTypeResolver] Resolved GDScript type from path: %s (class_name not set, consider adding class_name for better type resolution)" % resolved)
			return resolved
		
		# Better error message for debugging
		push_warning("[MessageTypeResolver] Could not resolve GDScript type. Script path: %s. Consider adding class_name to the script for reliable type resolution." % path)
		return StringName("UnknownScript")
	
	# Last resort: convert to string with warning
	push_warning("[MessageTypeResolver] Unexpected type for resolution: %s (type: %s). Converting to string." % [message_or_type, typeof(message_or_type)])
	return StringName(str(message_or_type))

