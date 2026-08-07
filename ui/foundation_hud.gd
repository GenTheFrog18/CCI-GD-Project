class_name FoundationHUD
extends CanvasLayer

var player: PlayerController
var health_label: Label
var money_label: Label
var prompt_label: Label
var feedback_label: Label
var inventory_panel: PanelContainer
var inventory_buttons: Array[Button] = []
var debug_panel: PanelContainer
var pause_panel: PanelContainer
var dialogue_box: DialogueBox
var crosshair: Node2D
var performance_label: Label
var _selected_container: StringName
var _selected_index := -1
var _performance_elapsed := 0.0

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta: float) -> void:
	crosshair.position = get_viewport().get_mouse_position()
	if not debug_panel.visible:
		_performance_elapsed = 0.0
		return
	_performance_elapsed += delta
	if _performance_elapsed >= 0.25:
		_performance_elapsed = 0.0
		_update_performance()

func set_player(value: PlayerController) -> void:
	player = value
	player.inventory_toggled.connect(_on_inventory_toggled)
	player.prompt_changed.connect(func(text: String): prompt_label.text = text)
	player.health.health_changed.connect(func(current: float, maximum: float): health_label.text = "HP %d/%d" % [current, maximum])
	player.item_controller.inventory.changed.connect(_refresh_inventory)
	player.item_controller.feedback_requested.connect(_show_feedback)
	GameSession.money_changed.connect(func(value: int): money_label.text = "%dg" % value)
	health_label.text = "HP %d/%d" % [player.health.health, player.health.max_health]
	money_label.text = "%dg" % GameSession.money
	_refresh_inventory()

func show_dialogue(sequence: DialogueSequence) -> void:
	dialogue_box.show_sequence(sequence, player)

func _input(event: InputEvent) -> void:
	if player == null:
		return
	if event.is_action_pressed(&"inventory"):
		if player.inventory_open or (not get_tree().paused and not player.locks.is_locked()):
			player.toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pause"):
		if player.inventory_open:
			player.set_inventory_open(false)
		else:
			get_tree().paused = not get_tree().paused
			pause_panel.visible = get_tree().paused
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_toggle"):
		debug_panel.visible = not debug_panel.visible
		if debug_panel.visible:
			_update_performance()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var top := HBoxContainer.new()
	top.position = Vector2(10, 8)
	add_child(top)
	health_label = Label.new()
	health_label.custom_minimum_size.x = 110
	top.add_child(health_label)
	money_label = Label.new()
	top.add_child(money_label)
	prompt_label = Label.new()
	prompt_label.position = Vector2(230, 320)
	prompt_label.size = Vector2(180, 28)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(prompt_label)
	feedback_label = Label.new()
	feedback_label.position = Vector2(220, 40)
	feedback_label.size = Vector2(200, 25)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(feedback_label)
	inventory_panel = PanelContainer.new()
	inventory_panel.position = Vector2(180, 105)
	inventory_panel.custom_minimum_size = Vector2(280, 130)
	inventory_panel.visible = false
	add_child(inventory_panel)
	var inventory_column := VBoxContainer.new()
	inventory_panel.add_child(inventory_column)
	var title := Label.new()
	title.text = "Hotbar / Backpack — click to swap, RMB to drop"
	inventory_column.add_child(title)
	var grid := GridContainer.new()
	grid.columns = 5
	inventory_column.add_child(grid)
	for index in 7:
		var button := Button.new()
		button.custom_minimum_size = Vector2(50, 42)
		button.pressed.connect(_slot_pressed.bind(index))
		button.gui_input.connect(_slot_gui_input.bind(index))
		grid.add_child(button)
		inventory_buttons.append(button)
	dialogue_box = DialogueBox.new()
	dialogue_box.position = Vector2(60, 245)
	add_child(dialogue_box)
	pause_panel = _make_panel("Paused", Vector2(240, 135))
	pause_panel.visible = false
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(func(): get_tree().paused = false; pause_panel.visible = false)
	pause_panel.get_child(0).add_child(resume)
	var menu := Button.new()
	menu.text = "Save & Menu"
	menu.pressed.connect(func(): SaveManager.save_run(); get_tree().paused = false; SceneRouter.go_to("res://ui/main_menu.tscn"))
	pause_panel.get_child(0).add_child(menu)
	debug_panel = _make_panel("Debug", Vector2(470, 55))
	debug_panel.visible = false
	var debug_column := debug_panel.get_child(0) as VBoxContainer
	performance_label = Label.new()
	debug_column.add_child(performance_label)
	for spec in [
		["Give Rock", _debug_give_rock],
		["Emit Sound", _debug_emit_sound],
		["Apply Slow", _debug_apply_slow],
		["Damage 10", _debug_damage],
		["Save", _debug_save],
		["Load", _debug_load],
	]:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(spec[1])
		debug_column.add_child(button)
	_build_crosshair()

func _build_crosshair() -> void:
	crosshair = Node2D.new()
	crosshair.z_index = 100
	add_child(crosshair)
	var ring := Line2D.new()
	ring.width = 1.0
	ring.default_color = Color.WHITE
	for index in 17:
		var angle := TAU * float(index) / 16.0
		ring.add_point(Vector2.from_angle(angle) * 6.0)
	crosshair.add_child(ring)
	for points in [
		PackedVector2Array([Vector2(-10, 0), Vector2(10, 0)]),
		PackedVector2Array([Vector2(0, -10), Vector2(0, 10)]),
	]:
		var line := Line2D.new()
		line.width = 1.0
		line.default_color = Color.WHITE
		line.points = points
		crosshair.add_child(line)

func _make_panel(title_text: String, at: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = at
	panel.custom_minimum_size = Vector2(165, 80)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	var title := Label.new()
	title.text = title_text
	column.add_child(title)
	return panel

func _slot_pressed(flat_index: int) -> void:
	var container: StringName = &"hotbar" if flat_index < 2 else &"backpack"
	var index := flat_index if flat_index < 2 else flat_index - 2
	if _selected_index < 0:
		_selected_container = container
		_selected_index = index
	else:
		player.item_controller.inventory.swap_slots(_selected_container, _selected_index, container, index)
		_selected_index = -1
	_refresh_inventory()

func _slot_gui_input(event: InputEvent, flat_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var container: StringName = &"hotbar" if flat_index < 2 else &"backpack"
		var index := flat_index if flat_index < 2 else flat_index - 2
		player.drop_inventory_slot(container, index)
		_selected_index = -1
		_refresh_inventory()

func _on_inventory_toggled(open: bool) -> void:
	inventory_panel.visible = open
	if not open:
		_selected_index = -1
	_refresh_inventory()

func _refresh_inventory() -> void:
	if player == null:
		return
	var slots: Array[ItemStack] = []
	slots.append_array(player.item_controller.inventory.hotbar)
	slots.append_array(player.item_controller.inventory.backpack)
	for index in inventory_buttons.size():
		var stack := slots[index]
		var label := "—"
		if not stack.is_empty():
			var definition := ContentCatalog.get_item(stack.item_id)
			label = "%s\nx%d" % [definition.display_name if definition != null else stack.item_id, stack.quantity]
		if index < 2 and index == player.item_controller.inventory.active_hotbar_index:
			label = "[%s]" % label
		inventory_buttons[index].text = label

func _show_feedback(message: String) -> void:
	feedback_label.text = message
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func(): feedback_label.text = "")

func _update_performance() -> void:
	var fps := Engine.get_frames_per_second()
	var frame_ms := 1000.0 / maxf(float(fps), 1.0)
	performance_label.text = "FPS: %d\nFrame: %.1f ms" % [fps, frame_ms]

func _debug_give_rock() -> void:
	player.try_pickup_item(&"throwable_rock", 1, {})

func _debug_emit_sound() -> void:
	SoundBus.emit_sound(get_tree(), SoundEvent.new(player.global_position, 300.0, &"debug", 1, player))

func _debug_apply_slow() -> void:
	player.apply_status(&"test_slow")

func _debug_damage() -> void:
	player.apply_damage(DamageInfo.new(10.0))

func _debug_save() -> void:
	SaveManager.save_run()

func _debug_load() -> void:
	if not SaveManager.load_run().is_empty():
		SaveManager.restore_registered_objects()

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
