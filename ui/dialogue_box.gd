class_name DialogueBox
extends PanelContainer

@export var typing_speed := 0.03

var _sequence: DialogueSequence
var _index := 0
var _player: Node
var _typing := false
var _full_text := ""
var _visible_characters := 0.0
var _portrait: TextureRect
var _speaker_label: Label
var _text_label: Label
var _continue_label: Label

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

func show_sequence(sequence: DialogueSequence, player: Node = null) -> void:
	if sequence == null or (sequence.lines.is_empty() and sequence.entries.is_empty()):
		return
	close()
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
	_text_label.visible_characters = int(_visible_characters)
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

func _advance() -> void:
	_index += 1
	if _sequence == null or _index >= _line_count():
		close()
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
	set_process(false)
	_typing = false
	if _player != null and "locks" in _player:
		_player.locks.unlock(&"dialogue")
	_player = null
	_sequence = null

func _exit_tree() -> void:
	close()
