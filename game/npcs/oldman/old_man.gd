class_name OldMan
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var default_flip_h := false

func _ready() -> void:
	animated_sprite.play(&"idle")
	
	default_flip_h = animated_sprite.flip_h
	

func reset_facing() -> void:
	animated_sprite.flip_h = default_flip_h
