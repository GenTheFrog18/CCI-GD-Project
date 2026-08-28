class_name PlayerCamera
extends Camera2D

@export var base_offset := Vector2(0.0, -40.0)
@export var max_cursor_offset := Vector2(56.0, 28.0)
@export var cursor_deadzone := 24.0
@export_range(0.0, 30.0, 0.1) var smoothing := 8.0
@export var ui_zoom := Vector2(1.1, 1.1)
@export_range(0.0, 30.0, 0.1) var zoom_smoothing := 8.0

var target: Node2D
var ui_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	target = get_parent() as Node2D
	position = base_offset

func _process(delta: float) -> void:
	if target == null:
		return
	var owns_cursor := ui_active or get_tree().paused
	var wanted_position := base_offset if owns_cursor else target_offset_for(GameSession.screen_to_design(get_viewport().get_mouse_position()), GameSession.DESIGN_SIZE)
	var position_weight := 1.0 - exp(-smoothing * delta) if smoothing > 0.0 else 1.0
	position = position.lerp(wanted_position, position_weight)
	var wanted_zoom := ui_zoom if owns_cursor else Vector2.ONE
	var zoom_weight := 1.0 - exp(-zoom_smoothing * delta) if zoom_smoothing > 0.0 else 1.0
	zoom = zoom.lerp(wanted_zoom, zoom_weight)

func target_offset_for(cursor_screen: Vector2, viewport_size := get_viewport_rect().size) -> Vector2:
	var offset := cursor_screen - viewport_size * 0.5
	if offset.length() <= cursor_deadzone:
		return base_offset
	offset -= offset.normalized() * cursor_deadzone
	var available := Vector2(
		maxf(viewport_size.x * 0.5 - cursor_deadzone, 1.0),
		maxf(viewport_size.y * 0.5 - cursor_deadzone, 1.0)
	)
	var normalized := Vector2(
		offset.x / available.x,
		offset.y / available.y
	)
	if normalized.length_squared() > 1.0:
		normalized = normalized.normalized()
	return base_offset + normalized * max_cursor_offset

func set_world_bounds(bounds: Rect2) -> void:
	limit_left = floori(bounds.position.x)
	limit_top = floori(bounds.position.y)
	limit_right = ceili(bounds.end.x)
	limit_bottom = ceili(bounds.end.y)
	limit_smoothed = true
