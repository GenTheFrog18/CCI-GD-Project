class_name SettingsPopup
extends Control

signal resume_requested
signal main_action_requested

@export_range(0.01, 2.0, 0.01) var popup_animation_seconds := 0.15
@export_range(0.0, 64.0, 1.0) var popup_slide_pixels := 12.0
@export_range(0.0, 32.0, 1.0) var indicator_gap := 3.0
@export_range(-32.0, 32.0, 1.0) var indicator_vertical_offset := 2.0

var include_resume := false
var main_action_text := "Close"
var _tween: Tween
var _card_top := 0.0
var _card_bottom := 0.0
var _syncing_display_controls := false

var play_intro_dialogue_enabled: bool:
	get:
		return play_intro_toggle.button_pressed

@onready var dimmer: ColorRect = $Dimmer
@onready var card: Control = $Card
@onready var close_button: TextureButton = $Card/CloseButton
@onready var menu_page: Control = $Card/MenuPage
@onready var indicator: TextureRect = $Card/MenuPage/Indicator
@onready var entry_resume: Button = $Card/MenuPage/MenuColumn/EntryResume
@onready var entry_sound: Button = $Card/MenuPage/MenuColumn/EntrySound
@onready var entry_screen: Button = $Card/MenuPage/MenuColumn/EntryScreen
@onready var entry_how_to: Button = $Card/MenuPage/MenuColumn/EntryHowToPlay
@onready var entry_credits: Button = $Card/MenuPage/MenuColumn/EntryCredits
@onready var entry_main_action: Button = $Card/MenuPage/MenuColumn/EntryMainAction
@onready var play_intro_toggle: CheckButton = $Card/MenuPage/PlayIntro
@onready var sound_page: Control = $Card/SoundPage
@onready var volume: HSlider = $Card/SoundPage/Volume
@onready var screen_page: Control = $Card/ScreenPage
@onready var resolution: OptionButton = $Card/ScreenPage/Resolution
@onready var fullscreen: CheckButton = $Card/ScreenPage/Fullscreen
@onready var fullscreen_hint: Label = $Card/ScreenPage/FullscreenHint
@onready var info_page: Control = $Card/InfoPage
@onready var info_title: Label = $Card/InfoPage/Title
@onready var info_body: Label = $Card/InfoPage/Body
@onready var how_to_page: Control = $Card/HowToPlayPage

func configure(show_resume: bool, action_text: String) -> void:
	include_resume = show_resume
	main_action_text = action_text

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 10
	visible = false
	play_intro_toggle.button_pressed = GameSession.first_launch
	_card_top = card.offset_top
	_card_bottom = card.offset_bottom
	entry_resume.pressed.connect(func(): resume_requested.emit())
	entry_sound.pressed.connect(func(): _show_page(sound_page, volume))
	entry_screen.pressed.connect(func(): _show_page(screen_page, fullscreen))
	entry_how_to.pressed.connect(_show_how_to_page)
	entry_credits.pressed.connect(func(): _show_info("Credits", "Team Gorillaz Games\n\nFont: Perfect DOS VGA 437\nCopyright (c) Zeh Fernando\nLicensed under SIL Open Font License 1.1"))
	entry_main_action.pressed.connect(_run_main_action)
	for entry in [entry_resume, entry_sound, entry_screen, entry_how_to, entry_credits, entry_main_action]:
		entry.focus_entered.connect(_move_indicator.bind(entry))
		entry.mouse_entered.connect(entry.grab_focus)
	close_button.pressed.connect(_close_or_resume)
	volume.value_changed.connect(func(value: float): GameSession.master_volume = value; GameSession.apply_settings(); SaveManager.save_meta())
	fullscreen.toggled.connect(_on_fullscreen_toggled)
	resolution.item_selected.connect(_on_resolution_selected)
	GameSession.display_settings_changed.connect(_sync_display_controls)

func show_popup() -> void:
	_show_main_page()
	visible = true
	dimmer.color.a = 0.0
	card.modulate.a = 0.0
	card.offset_top = _card_top + popup_slide_pixels
	card.offset_bottom = _card_bottom + popup_slide_pixels
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(dimmer, "color:a", 0.55, popup_animation_seconds)
	_tween.tween_property(card, "modulate:a", 1.0, popup_animation_seconds)
	_tween.tween_property(card, "offset_top", _card_top, popup_animation_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(card, "offset_bottom", _card_bottom, popup_animation_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func close_popup() -> void:
	if _tween != null:
		_tween.kill()
	visible = false

func _show_main_page() -> void:
	menu_page.visible = true
	sound_page.visible = false
	screen_page.visible = false
	info_page.visible = false
	how_to_page.visible = false
	entry_resume.visible = include_resume
	entry_main_action.visible = include_resume
	entry_main_action.tooltip_text = main_action_text
	call_deferred("_focus_first_entry")

func _focus_first_entry() -> void:
	(entry_resume if include_resume else entry_sound).grab_focus()

func _show_page(page: Control, focus: Control) -> void:
	menu_page.visible = false
	sound_page.visible = page == sound_page
	screen_page.visible = page == screen_page
	info_page.visible = false
	how_to_page.visible = false
	if page == sound_page:
		volume.value = GameSession.master_volume
	if page == screen_page:
		_sync_display_controls()
	focus.grab_focus()

func _sync_display_controls() -> void:
	if resolution == null:
		return
	_syncing_display_controls = true
	resolution.clear()
	var selected := -1
	for size in GameSession.get_windowed_size_options():
		var index := resolution.item_count
		resolution.add_item(GameSession.windowed_size_label(size))
		resolution.set_item_metadata(index, size)
		if size == GameSession.windowed_size:
			selected = index
	if selected < 0:
		selected = resolution.item_count
		resolution.add_item("Custom: %s" % GameSession.windowed_size_label(GameSession.windowed_size))
		resolution.set_item_metadata(selected, GameSession.windowed_size)
	resolution.select(selected)
	resolution.disabled = GameSession.fullscreen
	fullscreen.button_pressed = GameSession.fullscreen
	fullscreen_hint.visible = GameSession.fullscreen
	_syncing_display_controls = false

func _on_fullscreen_toggled(enabled: bool) -> void:
	if not _syncing_display_controls:
		GameSession.set_fullscreen(enabled)

func _on_resolution_selected(index: int) -> void:
	if _syncing_display_controls or GameSession.fullscreen:
		return
	GameSession.set_windowed_size(resolution.get_item_metadata(index) as Vector2i)

func _show_info(title: String, body: String) -> void:
	menu_page.visible = false
	sound_page.visible = false
	screen_page.visible = false
	info_page.visible = true
	how_to_page.visible = false
	info_title.text = title
	info_body.text = body
	close_button.grab_focus()

func _show_how_to_page() -> void:
	menu_page.visible = false
	sound_page.visible = false
	screen_page.visible = false
	info_page.visible = false
	how_to_page.visible = true
	close_button.grab_focus()

func show_how_to_page() -> void:
	_show_how_to_page()

func _run_main_action() -> void:
	if include_resume:
		main_action_requested.emit()
	else:
		close_popup()

func _move_indicator(entry: Control) -> void:
	indicator.global_position = Vector2(_label_left(entry) - indicator.size.x - indicator_gap, entry.global_position.y + indicator_vertical_offset)

func _label_left(entry: Control) -> float:
	var image_label := entry.get_node_or_null("Label") as TextureRect
	if image_label != null and image_label.texture != null:
		var texture_size := image_label.texture.get_size()
		var scale_factor := minf(image_label.size.x / texture_size.x, image_label.size.y / texture_size.y)
		return image_label.global_position.x + (image_label.size.x - texture_size.x * scale_factor) * 0.5
	var font := entry.get_theme_font(&"font")
	var font_size := entry.get_theme_font_size(&"font_size")
	var text_width := font.get_string_size((entry as Button).text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	return entry.global_position.x + (entry.size.x - text_width) * 0.5

func _close_or_resume() -> void:
	if include_resume:
		resume_requested.emit()
	else:
		close_popup()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_close_or_resume()
		get_viewport().set_input_as_handled()
