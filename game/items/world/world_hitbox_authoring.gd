@tool
extends Area2D

@export var preview_texture: Texture2D:
	set(value):
		preview_texture = value
		queue_redraw()
@export var preview_scale := Vector2.ONE:
	set(value):
		preview_scale = value
		queue_redraw()
@export_range(0.0, 1.0, 0.05) var preview_alpha := 0.35:
	set(value):
		preview_alpha = value
		queue_redraw()

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or preview_texture == null:
		return
	var size := preview_texture.get_size() * preview_scale
	draw_texture_rect(preview_texture, Rect2(-size * 0.5, size), false, Color(1.0, 1.0, 1.0, preview_alpha))
