class_name DialogueBox
extends PanelContainer

signal advance_requested
signal choice_requested(index: int)
signal closed

const TYPING_SFX := preload("res://assets/audio/dialogue/dialogue_blip.wav")
const BUBBLE_SHEET := preload("res://assets/art/ui/shopkeeper/bubble-speech.png")
const CHOICE_BUTTON := preload("res://assets/art/ui/main_menu/button-long.png")

@export_range(0.005, 0.2, 0.005) var typing_speed := 0.03
@export_range(0.1, 3.0, 0.1) var hold_to_fast_forward_seconds := 1.0
@export_range(0.03, 1.0, 0.01) var fast_forward_advance_seconds := 0.15
@export_range(1, 12, 1) var typing_sfx_every_characters := 3

var _typing := false
var _full_text := ""
var _visible_characters := 0.0
var _hold_seconds := 0.0
var _auto_advance_seconds := 0.0
var _portrait: TextureRect
var _speaker_label: Label
var _text_label: Label
var _continue_label: Label
var _choices: VBoxContainer
var _typing_sfx: AudioStreamPlayer
var _sfx_visible_characters := 0
var _sfx_character_count := 0

func _ready() -> void:
	add_to_group(&"dialogue_box")
	visible = false
	custom_minimum_size = Vector2(520.0, 104.0)
	var bubble := TextureRect.new()
	var frame := AtlasTexture.new()
	frame.atlas = BUBBLE_SHEET
	frame.region = Rect2(0.0, 0.0, 128.0, 64.0)
	bubble.texture = frame
	bubble.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble.stretch_mode = TextureRect.STRETCH_SCALE
	bubble.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_speaker_label.add_theme_font_size_override(&"font_size", 16)
	column.add_child(_speaker_label)
	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_text_label)
	_choices = VBoxContainer.new()
	column.add_child(_choices)
	_continue_label = Label.new()
	_continue_label.text = "[E]"
	_continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(_continue_label)
	_typing_sfx = AudioStreamPlayer.new()
	_typing_sfx.stream = TYPING_SFX
	add_child(_typing_sfx)

func open_dialogue(_speaker: Node = null) -> void:
	_hold_seconds = 0.0
	_auto_advance_seconds = 0.0
	visible = true

func show_line(line: DialogueLine) -> void:
	_clear_choices()
	_portrait.texture = line.portrait
	_portrait.visible = line.portrait != null
	_speaker_label.text = line.speaker_name
	_full_text = line.text
	_text_label.text = _full_text
	_text_label.visible_characters = 0
	_visible_characters = 0.0
	_sfx_visible_characters = 0
	_sfx_character_count = 0
	_typing = not _full_text.is_empty()
	_continue_label.visible = not _typing

func show_choices(choices: Array[DialogueChoice], available: Array[bool]) -> void:
	_typing = false
	_continue_label.visible = false
	_text_label.visible_characters = -1
	_clear_choices()
	for index in choices.size():
		var choice := choices[index]
		var button := Button.new()
		button.text = choice.label if available[index] else "%s — %s" % [choice.label, choice.disabled_reason]
		button.disabled = not available[index]
		button.custom_minimum_size = Vector2(144.0, 32.0)
		var style := StyleBoxTexture.new()
		style.texture = CHOICE_BUTTON
		button.add_theme_stylebox_override(&"normal", style)
		button.add_theme_stylebox_override(&"hover", style)
		button.add_theme_stylebox_override(&"pressed", style)
		button.pressed.connect(func(): choice_requested.emit(index))
		_choices.add_child(button)
		if index == 0 and not button.disabled:
			button.call_deferred(&"grab_focus")

func set_choices_enabled(enabled: bool) -> void:
	for child in _choices.get_children():
		(child as BaseButton).disabled = not enabled

func _process(delta: float) -> void:
	if not visible:
		return
	if _typing:
		_visible_characters += delta / maxf(typing_speed, 0.001)
		var shown := mini(int(_visible_characters), _full_text.length())
		_play_typing_sfx(shown)
		_text_label.visible_characters = shown
		if shown >= _full_text.length():
			_finish_typing()
	if _typing and Input.is_action_pressed(&"interact"):
		_hold_seconds += delta
		if _hold_seconds >= hold_to_fast_forward_seconds:
			_text_label.visible_characters = -1
			_finish_typing()
			_auto_advance_seconds = fast_forward_advance_seconds
	elif Input.is_action_just_released(&"interact"):
		_hold_seconds = 0.0
	if not _typing and _auto_advance_seconds > 0.0 and Input.is_action_pressed(&"interact") and _choices.get_child_count() == 0:
		_auto_advance_seconds -= delta
		if _auto_advance_seconds <= 0.0:
			_auto_advance_seconds = fast_forward_advance_seconds
			advance_requested.emit()

func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	if event.is_action_pressed(&"ui_cancel"):
		hide()
		closed.emit()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed(&"interact") or (event is InputEventKey and event.echo):
		return
	if _typing:
		_text_label.visible_characters = -1
		_finish_typing()
	elif _choices.get_child_count() == 0:
		advance_requested.emit()
	get_viewport().set_input_as_handled()

func _finish_typing() -> void:
	_typing = false
	_continue_label.visible = true

func _play_typing_sfx(visible_characters: int) -> void:
	if visible_characters <= _sfx_visible_characters:
		return
	for index in range(_sfx_visible_characters, visible_characters):
		if not _full_text[index].strip_edges().is_empty():
			_sfx_character_count += 1
			if _sfx_character_count % typing_sfx_every_characters == 0:
				_typing_sfx.play()
	_sfx_visible_characters = visible_characters

func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()
