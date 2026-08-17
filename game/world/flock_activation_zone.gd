class_name FlockActivationZone
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is not PlayerController:
		return
	var flock := get_tree().get_first_node_in_group(&"sky_hunter_flock") as SkyHunterFlock
	if flock != null:
		flock.activate_near(body.global_position)
