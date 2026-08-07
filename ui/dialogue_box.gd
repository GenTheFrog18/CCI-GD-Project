class_name DialogueBox
extends PanelContainer

var _sequence: DialogueSequence
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

func show_sequence(sequence: DialogueSequence) -> void:
	if sequence == null or sequence.lines.is_empty():
		return
	close()
	_sequence = sequence
	_index = 0
	visible = true
	_show_line()

func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused or not event.is_action_pressed(&"interact"):
		return
	if event is InputEventKey and event.echo:
		return
	_advance()
	get_viewport().set_input_as_handled()

func _advance() -> void:
	_index += 1
	if _sequence == null or _index >= _sequence.lines.size():
		close()
	else:
		_show_line()

func _show_line() -> void:
	_speaker_label.text = _sequence.speaker
	_text_label.text = _sequence.lines[_index]

func close() -> void:
	visible = false
	_sequence = null

func _exit_tree() -> void:
	close()
