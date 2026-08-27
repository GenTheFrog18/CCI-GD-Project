@tool
class_name EditorRangePreview
extends Node2D

@export var radius_property: StringName
@export var center_property: StringName
@export var preview_color := Color(1.0, 0.45, 0.2, 0.85)
@export var show_editor_preview := true

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and show_editor_preview:
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_preview or radius_property.is_empty():
		return
	var owner_node := get_parent()
	if owner_node == null:
		return
	var radius_value: Variant = owner_node.get(radius_property)
	if not (radius_value is float or radius_value is int):
		return
	var radius := maxf(float(radius_value), 0.0)
	if radius <= 0.0:
		return
	var center := Vector2.ZERO
	if not center_property.is_empty():
		var center_value: Variant = owner_node.get(center_property)
		if center_value is Vector2:
			center = to_local(center_value)
	draw_circle(center, radius, Color(preview_color, 0.08))
	draw_arc(center, radius, 0.0, TAU, 48, preview_color, 2.0)
	draw_line(center - Vector2(4.0, 0.0), center + Vector2(4.0, 0.0), preview_color, 1.0)
	draw_line(center - Vector2(0.0, 4.0), center + Vector2(0.0, 4.0), preview_color, 1.0)
