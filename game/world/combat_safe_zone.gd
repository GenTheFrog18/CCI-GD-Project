class_name CombatSafeZone
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("enter_combat_safe_zone"):
		body.enter_combat_safe_zone()

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("exit_combat_safe_zone"):
		body.exit_combat_safe_zone()
