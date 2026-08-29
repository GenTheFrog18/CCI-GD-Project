extends Control

const BUTTON_NORMAL := preload("res://assets/art/ui/main_menu/button-long.png")
const BUTTON_DISABLED := preload("res://assets/art/ui/main_menu/button-long-disabled.png")
const CONTINUE_LABEL := preload("res://assets/art/ui/main_menu/continue.png")
const CONTINUE_DISABLED_LABEL := preload("res://assets/art/ui/main_menu/continue_disabled.png")
const SETTINGS_POPUP_SCENE := preload("res://ui/settings_popup.tscn")
const NEW_RUN_CONFIRMATION_SCENE := preload("res://ui/new_run_confirmation.tscn")
const DEBUG_LAYER_SCENES: Dictionary = {
	&"layer_1": preload("res://game/world/layers/layer_1.tscn"),
	&"layer_2": preload("res://game/world/layers/layer_2.tscn"),
}

@export_range(1.0, 600.0, 1.0) var background_travel_seconds := 60.0
@export_range(0.01, 2.0, 0.01) var popup_animation_seconds := 0.15
@export_range(0.0, 64.0, 1.0) var popup_slide_pixels := 12.0

@onready var background: TextureRect = $Background
@onready var design_ui: Control = $DesignUI
@onready var new_run_button: Button = $DesignUI/MenuColumn/NewRun
@onready var continue_button: Button = $DesignUI/MenuColumn/Continue
@onready var continue_label: TextureRect = $DesignUI/MenuColumn/Continue/Label
@onready var settings_button: Button = $DesignUI/MenuColumn/Settings
@onready var quit_button: Button = $DesignUI/MenuColumn/Quit

var debug_panel: VBoxContainer
var seed_input: SpinBox
var settings_popup: SettingsPopup
var confirmation_popup: NewRunConfirmation
var debug_checkbox: CheckBox
var custom_layer_option: OptionButton
var custom_slot_scroll: ScrollContainer
var custom_slot_column: VBoxContainer
var custom_slot_ids: Array[StringName] = []
var custom_slot_options: Array[OptionButton] = []
var menu_cursor: Sprite2D
var _background_tween: Tween

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameSession.use_menu_cursor()
	GameSession.configure_design_root(design_ui)
	GameSession.display_settings_changed.connect(func(): GameSession.configure_design_root(design_ui))
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
	_build_menu_cursor()
	resized.connect(_restart_background_animation)
	call_deferred(&"_restart_background_animation")

func _process(_delta: float) -> void:
	if menu_cursor != null:
		menu_cursor.position = GameSession.screen_to_design(get_viewport().get_mouse_position())

func _build_menu_cursor() -> void:
	menu_cursor = Sprite2D.new()
	menu_cursor.texture = GameSession.MENU_CURSOR
	menu_cursor.centered = false
	menu_cursor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	menu_cursor.z_index = 1000
	design_ui.add_child(menu_cursor)

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
	settings_popup = SETTINGS_POPUP_SCENE.instantiate() as SettingsPopup
	settings_popup.configure(false, "Close")
	settings_popup.popup_animation_seconds = popup_animation_seconds
	settings_popup.popup_slide_pixels = popup_slide_pixels
	design_ui.add_child(settings_popup)
	confirmation_popup = NEW_RUN_CONFIRMATION_SCENE.instantiate() as NewRunConfirmation
	confirmation_popup.popup_animation_seconds = popup_animation_seconds
	confirmation_popup.popup_slide_pixels = popup_slide_pixels
	confirmation_popup.confirmed.connect(_start_new)
	design_ui.add_child(confirmation_popup)

func _build_debug() -> void:
	debug_panel = VBoxContainer.new()
	debug_panel.position = Vector2(12, 12)
	debug_panel.size = Vector2(310, 340)
	debug_panel.visible = false
	design_ui.add_child(debug_panel)
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
	_build_custom_world_menu()

func _build_custom_world_menu() -> void:
	var title := Label.new()
	title.text = "Custom World"
	debug_panel.add_child(title)
	custom_layer_option = OptionButton.new()
	custom_layer_option.add_item("Layer 1")
	custom_layer_option.set_item_metadata(0, &"layer_1")
	custom_layer_option.add_item("Layer 2")
	custom_layer_option.set_item_metadata(1, &"layer_2")
	custom_layer_option.select(0)
	custom_layer_option.item_selected.connect(_on_custom_layer_selected)
	debug_panel.add_child(custom_layer_option)
	custom_slot_scroll = ScrollContainer.new()
	custom_slot_scroll.custom_minimum_size = Vector2(0, 130)
	custom_slot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	debug_panel.add_child(custom_slot_scroll)
	custom_slot_column = VBoxContainer.new()
	custom_slot_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	custom_slot_scroll.add_child(custom_slot_column)
	_load_custom_layer(&"layer_1")
	var launch := _button("Launch Custom World", _launch_custom_world)
	debug_panel.add_child(launch)

func _on_custom_layer_selected(index: int) -> void:
	_load_custom_layer(StringName(custom_layer_option.get_item_metadata(index)))

func _load_custom_layer(layer_id: StringName) -> void:
	for child in custom_slot_column.get_children():
		child.free()
	custom_slot_ids.clear()
	custom_slot_options.clear()
	var layer_scene: PackedScene = DEBUG_LAYER_SCENES.get(layer_id) as PackedScene
	var layer: WorldLayer = null
	if layer_scene != null:
		layer = layer_scene.instantiate() as WorldLayer
	if layer == null:
		return
	for slot in layer.get_slots():
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = String(slot.slot_id)
		label.custom_minimum_size.x = 122.0
		row.add_child(label)
		var option := OptionButton.new()
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for variation in slot.variations:
			var section: WorldSection = null
			if variation != null:
				section = variation.instantiate() as WorldSection
			if section == null:
				continue
			option.add_item(String(section.variation_id))
			section.free()
		if option.item_count > 0:
			option.select(0)
		row.add_child(option)
		custom_slot_column.add_child(row)
		custom_slot_ids.append(slot.slot_id)
		custom_slot_options.append(option)
	layer.free()

func _launch_custom_world() -> void:
	var layer_id := StringName(custom_layer_option.get_item_metadata(custom_layer_option.selected))
	var overrides: Dictionary = {}
	for index in custom_slot_options.size():
		var option: OptionButton = custom_slot_options[index]
		if option.item_count > 0:
			overrides[String(custom_slot_ids[index])] = String(option.get_item_text(option.selected))
	GameSession.start_new_run(int(seed_input.value), true)
	GameSession.debug_custom_layer_id = layer_id
	GameSession.debug_custom_section_overrides = overrides
	SaveManager.loaded_persistent_state.clear()
	SceneRouter.go_to("res://game/world/world_run.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_toggle"):
		debug_panel.visible = not debug_panel.visible

func _confirm_new() -> void:
	if not SaveManager.has_valid_run():
		_start_new()
		return
	_show_new_run_confirmation()

func _show_new_run_confirmation() -> void:
	confirmation_popup.show_popup()

func _start_new() -> void:
	GameSession.start_new_run(int(seed_input.value), debug_checkbox.button_pressed)
	SaveManager.loaded_persistent_state.clear()
	if settings_popup.play_intro_dialogue_enabled:
		SceneRouter.go_to("res://game/story/prologue/prologue.tscn")
	else:
		SceneRouter.go_to("res://game/world/world_run.tscn")

func _continue_run() -> void:
	if not SaveManager.load_run().is_empty(): SceneRouter.go_to("res://game/world/world_run.tscn")

func _show_settings() -> void:
	settings_popup.show_popup()
