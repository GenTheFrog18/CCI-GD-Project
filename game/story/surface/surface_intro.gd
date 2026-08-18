extends Node

@export var dialogue_sequence: DialogueSequence

var player: PlayerController
var dialogue_box: DialogueBox

func start_intro(player_controller: PlayerController, dialogue_parent: Control) -> void:
	print("=== SURFACE INTRO START ===")

	player = player_controller

	if player == null:
		push_error("SurfaceIntro: Player tidak valid.")
		return

	print("Player ditemukan: ", player.name)

	if dialogue_sequence == null:
		push_error("SurfaceIntro: Dialogue Sequence belum diisi.")
		return

	print("Dialogue sequence ditemukan: ", dialogue_sequence.sequence_id)

	player.locks.lock(&"surface_intro")

	dialogue_box = DialogueBox.new()
	dialogue_parent.add_child(dialogue_box)
	dialogue_box.position = Vector2(60, 245)

	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

	print("Menampilkan Surface Intro...")

	dialogue_box.show_sequence(dialogue_sequence, null, player)

func _on_dialogue_finished() -> void:
	print("=== SURFACE INTRO SELESAI ===")

	if player != null:
		player.locks.unlock(&"surface_intro")

	GameSession.progression_flags["surface_intro_finished"] = true

	_show_objective()

	if is_instance_valid(dialogue_box):
		dialogue_box.queue_free()

	dialogue_box = null
	
func _show_objective() -> void:
	print("OBJECTIVE: Temui Kakek")
