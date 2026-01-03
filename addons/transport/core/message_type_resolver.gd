extends RefCounted
## Resolves message types from various sources.
static func resolve_type(message_or_type) -> StringName:
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
			return StringName(script.resource_path.get_file().get_basename())
		
		# Last resort: use get_class() result (will be "Object" for plain objects)
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
			return StringName(path.get_file().get_basename())
		
		return StringName("UnknownScript")
	
	# Last resort: convert to string
	return StringName(str(message_or_type))

