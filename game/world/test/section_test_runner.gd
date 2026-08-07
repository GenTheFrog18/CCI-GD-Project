extends Node2D

@export var section_scene: PackedScene

func _ready() -> void:
	if section_scene == null:
		push_error("Section test runner needs a section_scene")
		return
	var section := section_scene.instantiate() as WorldSection
	if section == null:
		push_error("Section test scene root must be WorldSection")
		return
	add_child(section)
	var errors := section.validate()
	if not errors.is_empty():
		push_error("\n".join(errors))
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	add_child(player)
	player.global_position = section.entry_anchor.global_position + Vector2(0.0, -20.0)
	player.set_last_safe_position(player.global_position)
	player.set_camera_bounds(Rect2(section.global_position, section.section_size))
