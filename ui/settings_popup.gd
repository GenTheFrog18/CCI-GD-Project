class_name SettingsPopup
extends Control

const PARCHMENT := preload("res://assets/art/ui/settings/settings-pane-final.png")
const TITLE := preload("res://assets/art/ui/settings/settings.png")
const INDICATOR := preload("res://assets/art/ui/settings/indicator.png")
const LABELS := {
	&"Resume": preload("res://assets/art/ui/settings/resume.png"),
	&"Sound": preload("res://assets/art/ui/settings/sound.png"),
	&"Screen": preload("res://assets/art/ui/settings/screen.png"),
	&"How to Play": preload("res://assets/art/ui/settings/how_to_play.png"),
	&"Credits": preload("res://assets/art/ui/settings/credits.png"),
}

signal resume_requested
signal main_action_requested

@export_range(0.01, 2.0, 0.01) var popup_animation_seconds := 0.15
@export_range(0.0, 64.0, 1.0) var popup_slide_pixels := 12.0

var include_resume := false
var main_action_text := "Close"
var _dimmer: ColorRect
var _card: Control
var _content: Control
var _indicator: TextureRect
var _tween: Tween

func configure(show_resume: bool, action_text: String) -> void:
	include_resume = show_resume
	main_action_text = action_text

func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	anchor_right = 1.0
	anchor_bottom = 1.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10
	visible = false
	_build_shell()

func show_popup() -> void:
	_build_main_page()
	visible = true
	_dimmer.color.a = 0.0
	_card.modulate.a = 0.0
	_card.position = Vector2(-180.0, -100.0 + popup_slide_pixels)
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(_dimmer, "color:a", 0.55, popup_animation_seconds)
	_tween.tween_property(_card, "modulate:a", 1.0, popup_animation_seconds)
	_tween.tween_property(_card, "position:y", -100.0, popup_animation_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func close_popup() -> void:
	if _tween != null:
		_tween.kill()
	visible = false

func _build_shell() -> void:
	_dimmer = ColorRect.new()
	_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dimmer.color = Color(0.0, 0.0, 0.0, 0.55)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dimmer)
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.position = Vector2(-180.0, -100.0)
	_card.size = Vector2(360.0, 200.0)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_card)
	var parchment := TextureRect.new()
	parchment.texture = PARCHMENT
	parchment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parchment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parchment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(parchment)
	_content = Control.new()
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.add_child(_content)

func _clear_page() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_indicator = null

func _build_main_page() -> void:
	_clear_page()
	_add_title("Settings")
	var entries: Array[String] = []
	if include_resume:
		entries.append("Resume")
	entries.append_array(["Sound", "Screen", "How to Play", "Credits", main_action_text])
	var column := VBoxContainer.new()
	column.position = Vector2(68.0, 48.0)
	column.size = Vector2(224.0, 132.0)
	column.add_theme_constant_override(&"separation", 1)
	_content.add_child(column)
	for entry in entries:
		var callback := _entry_callback(entry)
		var button := _menu_entry(entry, callback)
		column.add_child(button)
	call_deferred("_focus_first_entry", column)

func _entry_callback(entry: String) -> Callable:
	match entry:
		"Resume":
			return func(): resume_requested.emit()
		"Sound":
			return _build_sound_page
		"Screen":
			return _build_screen_page
		"How to Play":
			return func(): _build_info_page("How to Play", "A/D or arrows: move\nSpace: jump\nE: interact\n1/2 or mouse wheel: hotbar\nLeft click: use\nRight click: throw / secondary\nTab: inventory\nEsc: pause\nW/S: climb rope")
		"Credits":
			return func(): _build_info_page("Credits", "Team Gorillaz Games\n\nFont: Perfect DOS VGA 437\nCopyright (c) Zeh Fernando\nLicensed under SIL Open Font License 1.1")
		_:
			return func():
				if include_resume:
					main_action_requested.emit()
				else:
					close_popup()

func _menu_entry(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = "Entry%s" % text.replace(" ", "")
	button.custom_minimum_size = Vector2(224.0, 20.0)
	button.focus_mode = Control.FOCUS_ALL
	button.flat = true
	button.add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())
	button.pressed.connect(callback)
	button.focus_entered.connect(func(): _show_indicator(button))
	button.mouse_entered.connect(func(): button.grab_focus())
	var texture := LABELS.get(StringName(text)) as Texture2D
	if texture == null:
		var label := Label.new()
		label.text = text
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override(&"font_size", 16)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
	else:
		var label := TextureRect.new()
		label.texture = texture
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		label.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(label)
	return button

func _focus_first_entry(column: VBoxContainer) -> void:
	if column.get_child_count() > 0:
		(column.get_child(0) as Control).grab_focus()

func _show_indicator(button: Button) -> void:
	if _indicator == null:
		_indicator = TextureRect.new()
		_indicator.texture = INDICATOR
		_indicator.size = Vector2(16.0, 16.0)
		_indicator.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_indicator.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(_indicator)
	_indicator.global_position = button.global_position + Vector2(-18.0, 2.0)

func _add_title(text: String) -> void:
	if text == "Settings":
		var title_art := TextureRect.new()
		title_art.texture = TITLE
		title_art.position = Vector2(105.0, 10.0)
		title_art.size = Vector2(150.0, 34.0)
		title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_content.add_child(title_art)
		return
	var title := Label.new()
	title.text = text
	title.position = Vector2(48.0, 13.0)
	title.size = Vector2(264.0, 28.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(title)

func _build_sound_page() -> void:
	_clear_page()
	_add_title("Sound")
	var label := Label.new()
	label.text = "Master Volume"
	label.position = Vector2(72.0, 65.0)
	label.size = Vector2(216.0, 20.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(label)
	var volume := HSlider.new()
	volume.position = Vector2(78.0, 91.0)
	volume.size = Vector2(204.0, 20.0)
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = GameSession.master_volume
	volume.tooltip_text = "Master volume"
	volume.value_changed.connect(func(value: float): GameSession.master_volume = value; GameSession.apply_settings(); SaveManager.save_meta())
	_content.add_child(volume)
	_add_back_button()
	volume.grab_focus()

func _build_screen_page() -> void:
	_clear_page()
	_add_title("Screen")
	var fullscreen := CheckButton.new()
	fullscreen.text = "Fullscreen"
	fullscreen.position = Vector2(103.0, 78.0)
	fullscreen.size = Vector2(154.0, 26.0)
	fullscreen.button_pressed = GameSession.fullscreen
	fullscreen.toggled.connect(func(enabled: bool): GameSession.fullscreen = enabled; GameSession.apply_settings(); SaveManager.save_meta())
	_content.add_child(fullscreen)
	_add_back_button()
	fullscreen.grab_focus()

func _build_info_page(title: String, body: String) -> void:
	_clear_page()
	_add_title(title)
	var text := Label.new()
	text.text = body
	text.position = Vector2(55.0, 51.0)
	text.size = Vector2(250.0, 98.0)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override(&"font_size", 11)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(text)
	_add_back_button()

func _add_back_button() -> void:
	var back := _menu_entry("Back", _build_main_page)
	back.position = Vector2(104.0, 158.0)
	back.size = Vector2(152.0, 22.0)
	_content.add_child(back)
	back.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		if include_resume:
			resume_requested.emit()
		else:
			close_popup()
		get_viewport().set_input_as_handled()
