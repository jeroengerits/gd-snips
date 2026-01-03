extends RefCounted
## Infrastructure service for resolving message types from various sources.
##
## Handles the technical concern of extracting type identifiers from GDScript/Godot-specific
## constructs (scripts, class names, instances). This isolates infrastructure details
## from the domain layer, following clean architecture principles.
##
## **Type Resolution Strategy:**
## 1. StringName/String literals: Used directly
## 2. Object instances: Prefer [code]class_name[/code] via [method Object.get_class],
##    fallback to script path if class_name not available
## 3. GDScript class references: Instantiate temporarily to get class_name,
##    fallback to script filename
##
## **Best Practice:** Always use [code]class_name[/code] for message types to ensure
## consistent and deterministic type resolution across different contexts.
##
## @note This class extends [RefCounted] and is automatically memory-managed.
## @note Internal implementation - use via [MessageBus] static methods, not directly.

## Resolve message type identifier from a message instance or type.
##
## Converts various type representations into a [StringName] identifier that can
## be used for message routing in the bus system. This method handles the complexity
## of GDScript's type system to provide consistent type identification.
##
## **Supported Input Types:**
## - [StringName] or [String] literals: Used directly as the type identifier
## - [Object] instances: Extracts type via [method Object.get_class] (prefers [code]class_name[/code]),
##   falls back to script path if class_name not available
## - [GDScript] class references: Temporarily instantiates to get class_name,
##   falls back to script filename
##
## **Type Resolution Priority:**
## 1. [code]class_name[/code] (most deterministic and preferred)
## 2. Script resource path filename (if class_name not available)
## 3. [code]get_class()[/code] result (may be generic like "Object")
##
## @param message_or_type The message instance, class, or type identifier to resolve.
##   Can be an [Object], [GDScript], [StringName], [String], or other type.
##
## @return A [StringName] type identifier for routing. This identifier is used as
##   a dictionary key in the bus system.
##
## @note For consistent type resolution, always use [code]class_name[/code] for
##   message types. Without class_name, resolution may differ between class references
##   and instances, or across different machines with different file paths.
##
## @example With class_name (recommended):
##   extends Message
##   class_name MyCommand  # Type resolves to "MyCommand"
##
## @example Without class_name:
##   extends Message
##   # Type resolves to script filename (e.g., "my_command")
##   # Less deterministic across different machines
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
	
	# Handle GDScript class references - try to get class_name from instance
	elif message_or_type is GDScript:
		var script: GDScript = message_or_type
		
		# Try to instantiate and get class_name (preferred method)
		var instance = script.new()
		if instance != null:
			var class_name_str: String = instance.get_class()
			if class_name_str != "" and class_name_str != "Object":
				# Instance will be cleaned up when it goes out of scope
				return StringName(class_name_str)
		
		# Fallback: use script filename
		var path: String = script.resource_path
		if path != "":
			return StringName(path.get_file().get_basename())
		
		return StringName("UnknownScript")
	
	# Last resort: convert to string
	return StringName(str(message_or_type))

