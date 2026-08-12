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
	if preview.get("kind", &"") != &"trajectory":
		return
	for point in preview.get("points", PackedVector2Array()):
		draw_circle(to_local(point), dot_radius, trajectory_color)
