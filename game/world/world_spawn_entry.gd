class_name WorldSpawnEntry
extends Resource

@export var content_id: StringName
@export var scene: PackedScene
@export_range(1, 1000, 1) var weight := 1

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if content_id.is_empty():
		errors.append("WorldSpawnEntry content_id is blank")
	if scene == null:
		errors.append("WorldSpawnEntry %s scene is missing" % content_id)
	if weight <= 0:
		errors.append("WorldSpawnEntry %s weight must be positive" % content_id)
	return errors
