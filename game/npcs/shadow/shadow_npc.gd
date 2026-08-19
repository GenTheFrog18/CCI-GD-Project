class_name ShadowNPC
extends Area2D

@export var interaction_priority := 10.0
@export var dialogue_sequence: DialogueSequence

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_indicator: Label = $InteractionIndicator

var default_flip_h := false

func _ready() -> void:
	animated_sprite.play(&"idle")
	
	default_flip_h = animated_sprite.flip_h
	
	interaction_indicator.visible = false

func get_interaction_prompt(_actor: Node) -> String:
	return "Talk to Shadow"
	
func set_interaction_indicator(enabled: bool) -> void:
	interaction_indicator.visible = enabled

func interact(player: Node) -> bool:
	var dialogue_box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if dialogue_box == null or dialogue_sequence == null:
		return false
	if player is Node2D:
		face_player(player)
	dialogue_box.show_sequence(dialogue_sequence, self, player)
	return true
	
func face_player(player: Node2D) -> void:
	var direction := player.global_position - global_position
	
	if direction.x > 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
		
func reset_facing() -> void:
	animated_sprite.flip_h = default_flip_h
