class_name DialogueBox
extends PanelContainer

var _sequence: DialogueSequence
var _player: PlayerController
var _index := 0
var _speaker_label: Label
var _text_label: Label

func _ready() -> void:
	visible = false
	custom_minimum_size = Vector2(520.0, 90.0)
	var column := VBoxContainer.new()
	add_child(column)
	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 16)
	column.add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_text_label)
	var advance := Button.new()
	advance.text = "Continue"
	advance.pressed.connect(_advance)
	column.add_child(advance)

func show_sequence(sequence: DialogueSequence, player: PlayerController) -> void:
	if sequence == null or sequence.lines.is_empty():
		return
	_close()
	_sequence = sequence
	_player = player
	_index = 0
	if sequence.pauses_gameplay:
		_player.locks.lock(&"dialogue")
	visible = true
	_show_line()

func _advance() -> void:
	_index += 1
	if _sequence == null or _index >= _sequence.lines.size():
		_close()
	else:
		_show_line()

func _show_line() -> void:
	_speaker_label.text = _sequence.speaker
	_text_label.text = _sequence.lines[_index]

func _close() -> void:
	if _player != null:
		_player.locks.unlock(&"dialogue")
	visible = false
	_sequence = null
	_player = null

func _exit_tree() -> void:
	_close()
