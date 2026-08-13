class_name PlayerItemPreview
extends Node2D

@export var dot_radius := 1.5
@export var trajectory_color := Color(0.9, 0.95, 1.0, 0.9)

var player: PlayerController
var preview: Dictionary = {}

func _ready() -> void:
	player = get_parent() as PlayerController

func _process(_delta: float) -> void:
	preview = {}
	if player != null and not player.inventory_open and player.is_alive():
		var target := player.interaction_sensor.best_target(player, player.get_global_mouse_position())
		preview = player.item_controller.get_preview(player, player.get_parent(), player.get_global_mouse_position(), target)
	queue_redraw()

func _draw() -> void:
	if GameSession.debug_gameplay_draw and player != null:
		var origin := to_local(player.interaction_sensor.last_query_origin)
		var end := to_local(player.interaction_sensor.last_query_point)
		var direction := end - origin
		var side := direction.normalized().orthogonal() * player.interaction_sensor.query_width * 0.5 if not direction.is_zero_approx() else Vector2.UP * player.interaction_sensor.query_width * 0.5
		draw_polyline(PackedVector2Array([origin + side, end + side, end - side, origin - side, origin + side]), Color.CYAN, 1.0)
	var points: PackedVector2Array = preview.get("points", preview.get("trajectory", PackedVector2Array()))
	for point in points:
		draw_circle(to_local(point), dot_radius, trajectory_color)
	if preview.get("kind", &"") == &"rope":
		var anchor := to_local(preview.get("anchor", global_position))
		var end := to_local(preview.get("anchor", global_position) + Vector2.DOWN * float(preview.get("length", 160.0)))
		var color := Color(0.35, 1.0, 0.45, 0.9) if preview.get("valid", false) else Color(1.0, 0.3, 0.3, 0.9)
		draw_line(anchor, end, color, 2.0)
		draw_circle(anchor, 3.0, color)
