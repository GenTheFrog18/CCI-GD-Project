@tool
class_name LargeFlyerPOI
extends Marker2D
func _ready() -> void: add_to_group(&"large_flyer_poi")
func _draw() -> void:
	if Engine.is_editor_hint(): draw_circle(Vector2.ZERO, 8.0, Color(0.9, 0.2, 0.2, 0.8), false, 2.0)
