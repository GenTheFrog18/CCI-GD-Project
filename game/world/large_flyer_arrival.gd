class_name LargeFlyerArrival
extends Area2D

const FLYER_SCENE_PATH := "res://game/enemies/layer1/large_flyer.tscn"

@onready var spawn: Marker2D = $Spawn

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body is PlayerController or GameSession.progression_flags.get("large_flyer_arrived_layer2", false):
		return
	var id := SaveManager.transfer_first_scene(FLYER_SCENE_PATH, &"layer_2", spawn.global_position)
	if id.is_empty():
		return
	GameSession.progression_flags["large_flyer_arrived_layer2"] = true
	SaveManager.restore_registered_objects(&"layer_2")
