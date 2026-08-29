class_name CurseProfile
extends Resource

@export var profile_id: StringName
@export var trigger_distance := 360.0
@export var stillness_reset_seconds := 6.0
@export var modifiers: Dictionary = {}
@export_range(0.0, 0.5, 0.1) var health_cap_reduction := 0.0
@export var screen_color := Color(0.7, 0.2, 0.3, 0.2)
