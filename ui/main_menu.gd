extends Control

const BUTTON_NORMAL := preload("res://assets/art/ui/main_menu/button-long.png")
const BUTTON_DISABLED := preload("res://assets/art/ui/main_menu/button-long-disabled.png")
const CONTINUE_LABEL := preload("res://assets/art/ui/main_menu/continue.png")
const CONTINUE_DISABLED_LABEL := preload("res://assets/art/ui/main_menu/continue_disabled.png")
const SETTINGS_PANE := preload("res://assets/art/ui/settings/settings-pane-final.png")

@export_range(1.0, 600.0, 1.0) var background_travel_seconds := 60.0

@onready var background: TextureRect = $Background
@onready var new_run_button: Button = $MenuColumn/NewRun
@onready var continue_button: Button = $MenuColumn/Continue
@onready var continue_label: TextureRect = $MenuColumn/Continue/Label
@onready var settings_button: Button = $MenuColumn/Settings
@onready var quit_button: Button = $MenuColumn/Quit

var debug_panel: VBoxContainer
var seed_input: SpinBox
var settings_panel: PanelContainer
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
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(140, 70)
	settings_panel.size = Vector2(360, 220)
	settings_panel.visible = false
	var pane := StyleBoxTexture.new()
	pane.texture = SETTINGS_PANE
	settings_panel.add_theme_stylebox_override(&"panel", pane)
	add_child(settings_panel)
	var column := VBoxContainer.new()
	settings_panel.add_child(column)
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var volume := HSlider.new()
	volume.min_value = 0.0
	volume.max_value = 1.0
	volume.step = 0.05
	volume.value = GameSession.master_volume
	volume.tooltip_text = "Master volume"
	volume.value_changed.connect(func(value: float): GameSession.master_volume = value; GameSession.apply_settings(); SaveManager.save_meta())
	column.add_child(volume)
	var screen := CheckButton.new()
	screen.text = "Fullscreen"
	screen.button_pressed = GameSession.fullscreen
	screen.toggled.connect(func(enabled: bool): GameSession.fullscreen = enabled; GameSession.apply_settings(); SaveManager.save_meta())
	column.add_child(screen)
	column.add_child(_button("How to Play", _show_how_to))
	column.add_child(_button("Credits", _show_credits))
	column.add_child(_button("Close", func(): settings_panel.visible = false))

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
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Start a new run and replace the current save?"
	dialog.confirmed.connect(_start_new)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _start_new() -> void:
	GameSession.start_new_run(int(seed_input.value), debug_checkbox.button_pressed)
	SaveManager.loaded_persistent_state.clear()
	SceneRouter.go_to("res://game/world/world_run.tscn")

func _continue_run() -> void:
	if not SaveManager.load_run().is_empty(): SceneRouter.go_to("res://game/world/world_run.tscn")

func _show_settings() -> void:
	settings_panel.visible = true

func _show_how_to() -> void:
	_show_text("How to Play", "A/D or arrows: move\nSpace: jump\nE: interact\n1/2 or mouse wheel: hotbar\nLeft click: use\nRight click: throw / secondary\nTab: inventory\nEsc: pause\nW/S: climb rope")

func _show_credits() -> void:
	_show_text("Credits", "Team Gorillaz Games\n\nFont: Perfect DOS VGA 437\nCopyright (c) Zeh Fernando\nLicensed under SIL Open Font License 1.1")

func _show_text(title: String, body: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = body
	dialog.confirmed.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered(Vector2i(390, 230))
