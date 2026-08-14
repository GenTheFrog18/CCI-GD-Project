class_name CurseSafeZone
extends Area2D

func _ready() -> void:
	body_entered.connect(func(body: Node2D):
		if body is PlayerController:
			body.curse_tracker.reset_reference(false)
	)
