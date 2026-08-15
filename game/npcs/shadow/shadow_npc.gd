class_name ShadowNPC
extends Area2D

@export var interaction_priority := 10.0
@export var dialogue_sequence: DialogueSequence

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	animated_sprite.play(&"idle")

func get_interaction_prompt(_actor: Node) -> String:
	return "Talk to Shadow"

func interact(player: Node) -> bool:
	var dialogue_box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	if dialogue_box == null or dialogue_sequence == null:
		return false
	dialogue_box.show_sequence(dialogue_sequence, player)
	return true
