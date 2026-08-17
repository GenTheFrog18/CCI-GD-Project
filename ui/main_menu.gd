extends Control

const BUTTON_NORMAL := preload("res://assets/art/ui/main_menu/button-long.png")
const BUTTON_DISABLED := preload("res://assets/art/ui/main_menu/button-long-disabled.png")
const CONTINUE_LABEL := preload("res://assets/art/ui/main_menu/continue.png")
const CONTINUE_DISABLED_LABEL := preload("res://assets/art/ui/main_menu/continue_disabled.png")
const SETTINGS_PANE := preload("res://assets/art/ui/settings/settings-pane-final.png")

@export_range(1.0, 600.0, 1.0) var background_travel_seconds := 60.0
@export_range(0.01, 2.0, 0.01) var popup_animation_seconds := 0.15
@export_range(0.0, 64.0, 1.0) var popup_slide_pixels := 12.0

@onready var background: TextureRect = $Background
@onready var new_run_button: Button = $MenuColumn/NewRun
@onready var continue_button: Button = $MenuColumn/Continue
@onready var continue_label: TextureRect = $MenuColumn/Continue/Label
@onready var settings_button: Button = $MenuColumn/Settings
@onready var quit_button: Button = $MenuColumn/Quit

var debug_panel: VBoxContainer
var seed_input: SpinBox
var settings_popup: SettingsPopup
var debug_checkbox: CheckBox
var _background_tween: Tween

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameSession.apply_settings()
	new_run_button.pressed.connect(_confirm_new)
	continue_button.pressed.connect(_continue_run)
	settings_button.pressed.connect(_show_settings)
	quit_button.pressed.connect(get_tree().quit)
	continue_button.disabled = not SaveManager.has_valid_run()
	continue_label.texture = CONTINUE_DISABLED_LABEL if continue_button.disabled else CONTINUE_LABEL
	new_run_button.tooltip_text = "Start a new run"
	continue_button.tooltip_text = "Continue the saved run"
	settings_button.tooltip_text = "Open settings"
	quit_button.tooltip_text = "Quit the game"
	_build_settings()
	_build_debug()
	resized.connect(_restart_background_animation)
	call_deferred(&"_restart_background_animation")

func _restart_background_animation() -> void:
	if background == null or background.texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	if _background_tween != null:
		_background_tween.kill()
	var texture_size := background.texture.get_size()
	var scale_factor := maxf(size.x / texture_size.x, size.y / texture_size.y)
	background.size = texture_size * scale_factor
	background.position = Vector2((size.x - background.size.x) * 0.5, 0.0)
	var bottom_y := size.y - background.size.y
	if bottom_y >= -0.5:
		return
	_background_tween = create_tween().set_loops()
	_background_tween.tween_property(background, "position:y", bottom_y, background_travel_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_background_tween.tween_property(background, "position:y", 0.0, background_travel_seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(144, 32)
	var normal := StyleBoxTexture.new()
	normal.texture = BUTTON_NORMAL
	var disabled := StyleBoxTexture.new()
	disabled.texture = BUTTON_DISABLED
	button.add_theme_stylebox_override(&"normal", normal)
	button.add_theme_stylebox_override(&"hover", normal)
	button.add_theme_stylebox_override(&"pressed", normal)
	button.add_theme_stylebox_override(&"disabled", disabled)
	button.pressed.connect(callback)
	return button

func _build_settings() -> void:
	settings_popup = SettingsPopup.new()
	settings_popup.configure(false, "Close")
	settings_popup.popup_animation_seconds = popup_animation_seconds
	settings_popup.popup_slide_pixels = popup_slide_pixels
	add_child(settings_popup)

func _build_debug() -> void:
	debug_panel = VBoxContainer.new()
	debug_panel.position = Vector2(12, 12)
	debug_panel.size = Vector2(230, 120)
	debug_panel.visible = false
	add_child(debug_panel)
	debug_checkbox = CheckBox.new()
	debug_checkbox.text = "Debug Run"
	debug_panel.add_child(debug_checkbox)
	seed_input = SpinBox.new()
	seed_input.max_value = 2147483647
	seed_input.prefix = "Seed: "
	debug_panel.add_child(seed_input)
	var room := _button("Foundation Test Room", func(): GameSession.start_new_run(int(seed_input.value), true); SaveManager.loaded_persistent_state.clear(); SceneRouter.go_to("res://game/world/foundation_test_room.tscn"))
	debug_panel.add_child(room)
	debug_checkbox.toggled.connect(func(enabled: bool): room.visible = enabled)
	room.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle"):
		debug_panel.visible = not debug_panel.visible

func _confirm_new() -> void:
	if not SaveManager.has_valid_run():
		_start_new()
		return
	_show_new_run_confirmation()

func _show_new_run_confirmation() -> void:
	var popup := Control.new()
	popup.name = "NewRunConfirmation"
	popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	popup.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.z_index = 10
	add_child(popup)
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.0)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	popup.add_child(dimmer)
	var card := Control.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.position = Vector2(-180.0, -100.0 + popup_slide_pixels)
	card.size = Vector2(360.0, 200.0)
	card.modulate.a = 0.0
	popup.add_child(card)
	var parchment := TextureRect.new()
	parchment.texture = SETTINGS_PANE
	parchment.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parchment.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	parchment.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parchment.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(parchment)
	var title := Label.new()
	title.text = "Please Confirm..."
	title.position = Vector2(42.0, 37.0)
	title.size = Vector2(276.0, 26.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 18)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title)
	var message := Label.new()
	message.text = "Start a new run and replace the current save?"
	message.position = Vector2(43.0, 70.0)
	message.size = Vector2(274.0, 54.0)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override(&"font_size", 14)
	message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(message)
	var actions := HBoxContainer.new()
	actions.position = Vector2(32.0, 140.0)
	actions.size = Vector2(296.0, 32.0)
	actions.add_theme_constant_override(&"separation", 8)
	card.add_child(actions)
	actions.add_child(_button("Cancel", popup.queue_free))
	actions.add_child(_button("Start New Run", func(): popup.queue_free(); _start_new()))
	var tween := popup.create_tween().set_parallel()
	tween.tween_property(dimmer, "color:a", 0.55, popup_animation_seconds)
	tween.tween_property(card, "modulate:a", 1.0, popup_animation_seconds)
	tween.tween_property(card, "position:y", -100.0, popup_animation_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _start_new() -> void:
	GameSession.start_new_run(int(seed_input.value), debug_checkbox.button_pressed)
	SaveManager.loaded_persistent_state.clear()
	SceneRouter.go_to("res://game/world/world_run.tscn")

func _continue_run() -> void:
	if not SaveManager.load_run().is_empty(): SceneRouter.go_to("res://game/world/world_run.tscn")

func _show_settings() -> void:
	settings_popup.show_popup()
