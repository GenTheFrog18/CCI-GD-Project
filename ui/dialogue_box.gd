class_name DialogueBox
extends PanelContainer

@export var typing_speed := 0.03
@export var typing_sfx_every_characters := 3

signal dialogue_finished

const TYPING_SFX := preload("res://assets/audio/dialogue/dialogue_blip.wav")

var _sequence: DialogueSequence
var _index := 0
var _player: Node
var _typing := false
var _full_text := ""
var _visible_characters := 0.0
var _portrait: TextureRect
var _speaker_label: Label
var current_speaker: Node = null
var _text_label: Label
var _continue_label: Label
var _typing_sfx: AudioStreamPlayer
var _sfx_visible_characters := 0
var _sfx_character_count := 0

func _ready() -> void:
	add_to_group(&"dialogue_box")
	visible = false
	custom_minimum_size = Vector2(520.0, 90.0)
	var row := HBoxContainer.new()
	add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(72.0, 72.0)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_portrait)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 16)
	column.add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_text_label)
	_continue_label = Label.new()
	_continue_label.text = "[E]"
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_continue_label)
	_typing_sfx = AudioStreamPlayer.new()
	_typing_sfx.stream = TYPING_SFX
	add_child(_typing_sfx)

func show_sequence(sequence: DialogueSequence, speaker: Node = null, player: Node = null) -> void:
	if sequence == null or (sequence.lines.is_empty() and sequence.entries.is_empty()):
		push_warning("DialougeData NULL")
		return
	close()
	current_speaker = speaker
	_sequence = sequence
	_player = player
	if sequence.locks_gameplay and _player != null and "locks" in _player:
		_player.locks.lock(&"dialogue")
	_index = 0
	visible = true
	_show_line()
	set_process(true)

func _process(delta: float) -> void:
	if not _typing:
		return
	_visible_characters += delta / maxf(typing_speed, 0.001)
	var visible_characters := mini(int(_visible_characters), _full_text.length())
	_play_typing_sfx(visible_characters)
	_text_label.visible_characters = visible_characters
	if _text_label.visible_characters >= _full_text.length():
		_finish_typing()

func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused or not event.is_action_pressed(&"interact"):
		return
	if event is InputEventKey and event.echo:
		return
	if _typing:
		_text_label.visible_characters = -1
		_finish_typing()
	else:
		_advance()
	get_viewport().set_input_as_handled()
	
func _finish_dialogue() -> void:
	close()
	dialogue_finished.emit()

func _advance() -> void:
	_index += 1

	if _sequence == null or _index >= _line_count():
		_finish_dialogue()
	else:
		_show_line()

func _show_line() -> void:
	var portrait: Texture2D
	if not _sequence.entries.is_empty():
		var entry := _sequence.entries[_index]
		_speaker_label.text = entry.speaker_name
		_full_text = entry.text
		portrait = entry.portrait
	else:
		_speaker_label.text = _sequence.speaker
		_full_text = _sequence.lines[_index]
	_portrait.texture = portrait
	_portrait.visible = portrait != null
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_visible_characters = 0.0
	_sfx_visible_characters = 0
	_sfx_character_count = 0
	_typing = true
	_continue_label.visible = false

func _finish_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	_continue_label.visible = true

func _line_count() -> int:
	return _sequence.entries.size() if not _sequence.entries.is_empty() else _sequence.lines.size()

func close() -> void:
	visible = false

	if current_speaker != null and current_speaker.has_method("reset_facing"):
		current_speaker.reset_facing()

	set_process(false)
	_typing = false
	current_speaker = null

	if _player != null and "locks" in _player:
		_player.locks.unlock(&"dialogue")

	_player = null
	_sequence = null

func _play_typing_sfx(visible_characters: int) -> void:
	if visible_characters <= _sfx_visible_characters:
		return
	for character_index in range(_sfx_visible_characters, visible_characters):
		if not _full_text[character_index].strip_edges().is_empty():
			_sfx_character_count += 1
			if _sfx_character_count >= maxi(typing_sfx_every_characters, 1):
				_typing_sfx.play()
				_sfx_character_count = 0
	_sfx_visible_characters = visible_characters

func _exit_tree() -> void:
	close()
