class_name WorldSection
extends Node2D

@export var slot_id: StringName
@export var variation_id: StringName
@export var section_size := Vector2(640.0, 1600.0)
@export var entry_anchor: Marker2D
@export var exit_anchor: Marker2D
@export var placer_root: Node
@export var dynamic_root: Node

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if slot_id.is_empty():
		errors.append("WorldSection slot_id is blank")
	if variation_id.is_empty():
		errors.append("WorldSection %s variation_id is blank" % slot_id)
	if entry_anchor == null or exit_anchor == null:
		errors.append("WorldSection %s seam anchor missing" % slot_id)
	if section_size != Vector2(640.0, 1600.0):
		errors.append("WorldSection %s must be 640x1600" % slot_id)
	return errors
