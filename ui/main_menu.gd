extends Control

var debug_checkbox: CheckBox
var seed_input: SpinBox
var test_room_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.035, 0.045, 0.065)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 260.0
	column.add_theme_constant_override("separation", 10)
	center.add_child(column)
	var title := Label.new()
	title.text = "CCI GD Project\nDemo Build"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var new_game := Button.new()
	new_game.text = "New Run"
	new_game.pressed.connect(_start_new)
	column.add_child(new_game)
	var continue_button := Button.new()
	continue_button.text = "Continue"
	continue_button.disabled = not SaveManager.has_valid_run()
	continue_button.pressed.connect(_continue_run)
	column.add_child(continue_button)
	if SaveManager.has_run_file() and continue_button.disabled:
		var incompatible := Label.new()
		incompatible.text = "Saved run is incompatible. Start a New Run."
		incompatible.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(incompatible)
	debug_checkbox = CheckBox.new()
	debug_checkbox.text = "Debug Run (custom seed + world log)"
	debug_checkbox.toggled.connect(func(enabled: bool): seed_input.visible = enabled; test_room_button.visible = enabled)
	column.add_child(debug_checkbox)
	seed_input = SpinBox.new()
	seed_input.min_value = 0
	seed_input.max_value = 2147483647
	seed_input.step = 1
	seed_input.value = 0
	seed_input.prefix = "Seed (0 = random): "
	seed_input.visible = false
	column.add_child(seed_input)
	test_room_button = Button.new()
	test_room_button.text = "Foundation Test Room"
	test_room_button.visible = false
	test_room_button.pressed.connect(_start_test_room)
	column.add_child(test_room_button)
	var controls := Label.new()
	controls.text = "A/D gerak | Space lompat | E interact\n1/2 hotbar  LMB primary  RMB secondary\nTab inventory  Esc pause  F3 debug"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(controls)
	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(get_tree().quit)
	column.add_child(quit)

func _start_new() -> void:
	GameSession.start_new_run(int(seed_input.value), debug_checkbox.button_pressed)
	SaveManager.loaded_persistent_state.clear()
	SceneRouter.go_to("res://game/world/world_run.tscn")

func _continue_run() -> void:
	if SaveManager.load_run().is_empty():
		return
	SceneRouter.go_to("res://game/world/world_run.tscn")

func _start_test_room() -> void:
	GameSession.start_new_run(int(seed_input.value), true)
	SaveManager.loaded_persistent_state.clear()
	SceneRouter.go_to("res://game/world/foundation_test_room.tscn")
