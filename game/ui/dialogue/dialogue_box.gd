class_name DialogueBox
extends Control

signal dialogue_finished

@onready var portrait: TextureRect = $Background/Portrait
@onready var name_label: Label = $Background/NameLabel
@onready var dialogue_label: Label = $Background/DialogueLabel
@onready var continue_label: Label = $Background/ContinueLabel
@onready var dialogue_sfx: AudioStreamPlayer = $TextSFX

@export var sfx_every_characters := 3
@export var sfx_enabled := true

var _sfx_counter := 0

var dialogue_data: DialogueData
var current_index := 0

var current_speaker: Node = null
var player: Node = null

var typing := false
var full_text := ""
var typing_speed := 0.03


func _ready() -> void:
	add_to_group(&"dialogue_box")

	visible = false
	continue_label.visible = false

func start_dialogue(
	data: DialogueData,
	speaker: Node,
	player_node: Node
) -> void:

	if data == null:
		push_warning("DialogueData NULL!")
		return

	dialogue_data = data
	current_speaker = speaker
	player = player_node
	current_index = 0

	visible = true

	if player != null and "locks" in player:
		player.locks.lock(&"dialogue")

	_show_current_line()


func _show_current_line() -> void:
	if dialogue_data == null:
		print("dialogue_data NULL")
		finish_dialogue()
		return

	if current_index >= dialogue_data.lines.size():
		print("Tidak ada line.")
		finish_dialogue()
		return

	var line := dialogue_data.lines[current_index]

	name_label.text = line.speaker_name
	portrait.texture = line.portrait

	full_text = line.text

	dialogue_label.text = ""
	continue_label.visible = false

	typing = true
	_sfx_counter = 0

	for character in full_text:
		if not typing:
			break

		dialogue_label.text += character

		if character != " ":
			_sfx_counter += 1

			if _sfx_counter >= sfx_every_characters:
				_play_dialogue_sfx()
				_sfx_counter = 0

		await get_tree().create_timer(typing_speed).timeout

	typing = false
	continue_label.visible = true

func _play_dialogue_sfx() -> void:
	if not sfx_enabled:
		return

	if dialogue_sfx == null:
		return

	dialogue_sfx.stop()
	dialogue_sfx.play()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if not event.is_action_pressed(&"interact"):
		return

	get_viewport().set_input_as_handled()

	if typing:
		typing = false
		dialogue_label.text = full_text
		continue_label.visible = true
		return

	current_index += 1
	_show_current_line()


func finish_dialogue() -> void:
	visible = false
	
	if current_speaker != null and current_speaker.has_method("reset_facing"):
		current_speaker.reset_facing()

	dialogue_data = null
	current_index = 0
	current_speaker = null

	if player != null and "locks" in player:
		player.locks.unlock(&"dialogue")

	player = null

	dialogue_finished.emit()
	
func close() -> void:
	finish_dialogue()
