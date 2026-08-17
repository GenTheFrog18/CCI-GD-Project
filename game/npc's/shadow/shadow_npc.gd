class_name ShadowNPC
extends CharacterBody2D

@export var persistent_id := "elenara_arden"
@export var interaction_priority := 10.0

@export var dialogue_data: DialogueData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_indicator: Label = $InteractionIndicator

var default_flip_h := false

func _ready() -> void:
	add_to_group(&"persistent_objects")

	animated_sprite.play(&"idle")

	default_flip_h = animated_sprite.flip_h
	
	interaction_indicator.visible = false

func interact(player: Node) -> void:
	var dialogue_box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox

	if dialogue_box == null:
		push_warning("DialogueBox tidak ditemukan!")
		return

	if dialogue_data == null:
		push_warning("Dialogue data Elenara belum diatur!")
		return

	if player is Node2D:
		face_player(player)

	dialogue_box.start_dialogue(dialogue_data, self, player)
	
func set_interaction_indicator(enabled: bool) -> void:
	interaction_indicator.visible = enabled

func face_player(player: Node2D) -> void:
	var direction := player.global_position - global_position

	if direction.x > 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
		
func reset_facing() -> void:
	animated_sprite.flip_h = default_flip_h
