@tool
class_name DarknessRegion2D
extends Node2D

@export var region_id: StringName
@export_range(0.0, 1.0, 0.01) var darkness_strength := 0.85
@export_range(0.0, 256.0, 1.0) var edge_falloff_pixels := 32.0
@export var enabled := true
@export var region_rect := Rect2(0.0, 0.0, 1280.0, 800.0)

func _ready() -> void:
	add_to_group(&"darkness_regions")
	queue_redraw()

func world_rect() -> Rect2:
	return Rect2(global_position + region_rect.position, region_rect.size)

func validate_against(bounds: Rect2) -> PackedStringArray:
	var errors := PackedStringArray()
	if region_id.is_empty():
		errors.append("DarknessRegion2D has blank region_id")
	if region_rect.size.x <= 0.0 or region_rect.size.y <= 0.0:
		errors.append("DarknessRegion2D %s has empty region_rect" % region_id)
	if darkness_strength < 0.0 or darkness_strength > 1.0:
		errors.append("DarknessRegion2D %s has invalid darkness_strength" % region_id)
	if edge_falloff_pixels < 0.0:
		errors.append("DarknessRegion2D %s has negative edge_falloff_pixels" % region_id)
	if not bounds.encloses(world_rect()):
		errors.append("DarknessRegion2D %s is outside layer bounds" % region_id)
	return errors

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var fill := Color(0.12, 0.16, 0.24, clampf(darkness_strength * 0.35, 0.08, 0.35))
	draw_rect(region_rect, fill, true)
	draw_rect(region_rect, Color(0.35, 0.65, 1.0, 0.9), false, 2.0)
	if edge_falloff_pixels > 0.0:
		var falloff := region_rect.grow(edge_falloff_pixels)
		draw_rect(falloff, Color(0.35, 0.65, 1.0, 0.35), false, 1.0)
	draw_string(ThemeDB.fallback_font, region_rect.position + Vector2(4.0, 16.0), String(region_id), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
