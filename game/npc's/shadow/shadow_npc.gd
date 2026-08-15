class_name ShadowNPC
extends CharacterBody2D

@export var persistent_id := "shadow_npc"
@export var interaction_priority := 10.0

@export var dialogue_data: DialogueData

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group(&"persistent_objects")

	animated_sprite.play(&"idle")


func interact(player: Node) -> void:
	print("=== SHADOW INTERACT ===")
	print("Player: ", player)
	print("Dialogue data: ", dialogue_data)
	
	var dialogue_box := get_tree().get_first_node_in_group(&"dialogue_box") as DialogueBox
	
	print("Dialogue Box: ", dialogue_box)

	if dialogue_box == null:
		push_warning("DialogueBox tidak ditemukan!")
		return

	if dialogue_data == null:
		push_warning("Dialogue data Shadow belum diatur!")
		return
	
	print("Memulai dialogue..")

	dialogue_box.start_dialogue(dialogue_data, self, player)
