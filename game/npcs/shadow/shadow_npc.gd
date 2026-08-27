class_name ShadowNPC
extends Area2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_indicator: Label = $InteractionIndicator

var default_flip_h := false

func _ready() -> void:
	animated_sprite.play(&"idle")
	
	default_flip_h = animated_sprite.flip_h
	
	interaction_indicator.visible = false

func reset_facing() -> void:
	animated_sprite.flip_h = default_flip_h
