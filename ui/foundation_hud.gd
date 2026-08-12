class_name FoundationHUD
extends CanvasLayer

signal world_debug_action_requested(action: StringName)

var player: PlayerController
var health_label: Label
var money_label: Label
var prompt_label: Label
var feedback_label: Label
var inventory_panel: PanelContainer
var inventory_buttons: Array[Button] = []
var hotbar_labels: Array[Label] = []
var debug_panel: PanelContainer
var pause_panel: PanelContainer
var death_panel: PanelContainer
var dialogue_box: DialogueBox
var crosshair: Node2D
var performance_label: Label
var world_debug_label: Label
var world_log_panel: PanelContainer
var world_log_label: Label
var unlimited_health_toggle: CheckButton
var location_label: Label
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
	_update_location()
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
	player.health.health_changed.connect(_set_health_text)
	player.health.died.connect(_on_player_died)
	player.item_controller.inventory.changed.connect(_refresh_inventory)
	player.item_controller.feedback_requested.connect(_show_feedback)
	GameSession.money_changed.connect(func(value: int): money_label.text = "%dg" % value)
	_set_health_text(player.health.health, player.health.max_health)
	money_label.text = "%dg" % GameSession.money
	_refresh_inventory()

func show_dialogue(sequence: DialogueSequence) -> void:
	dialogue_box.show_sequence(sequence)

func _input(event: InputEvent) -> void:
	if player == null:
		return
	if death_panel.visible:
		if event.is_action_pressed(&"inventory") or event.is_action_pressed(&"pause"):
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"inventory"):
		if player.inventory_open or (not get_tree().paused and not player.locks.is_locked()):
			player.toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pause"):
		if world_log_panel.visible:
			world_log_panel.visible = false
		elif player.inventory_open:
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
	location_label = Label.new()
	location_label.anchor_left = 1.0
	location_label.anchor_right = 1.0
	location_label.offset_left = -300.0
	location_label.offset_top = 8.0
	location_label.offset_right = -10.0
	location_label.offset_bottom = 42.0
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(location_label)
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
	var hotbar := HBoxContainer.new()
	hotbar.position = Vector2(10, 292)
	add_child(hotbar)
	for index in 2:
		var label := Label.new()
		label.custom_minimum_size = Vector2(125, 28)
		hotbar.add_child(label)
		hotbar_labels.append(label)
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
	var seed_label := Label.new()
	seed_label.text = "Seed: %d" % GameSession.run_seed
	pause_panel.get_child(0).add_child(seed_label)
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(func(): get_tree().paused = false; pause_panel.visible = false)
	pause_panel.get_child(0).add_child(resume)
	var new_run := Button.new()
	new_run.text = "New Run"
	new_run.pressed.connect(start_new_run)
	pause_panel.get_child(0).add_child(new_run)
	var menu := Button.new()
	menu.text = "Save & Menu"
	menu.pressed.connect(func(): SaveManager.save_run(); get_tree().paused = false; SceneRouter.go_to("res://ui/main_menu.tscn"))
	pause_panel.get_child(0).add_child(menu)
	if GameSession.debug_enabled:
		var world_log := Button.new()
		world_log.text = "World Gen Log"
		world_log.pressed.connect(func(): world_log_panel.visible = not world_log_panel.visible)
		pause_panel.get_child(0).add_child(world_log)
	death_panel = _make_panel("You Died", Vector2(240, 125))
	death_panel.visible = false
	var retry := Button.new()
	retry.text = "New Run"
	retry.pressed.connect(start_new_run)
	death_panel.get_child(0).add_child(retry)
	var death_menu := Button.new()
	death_menu.text = "Main Menu"
	death_menu.pressed.connect(_return_to_menu)
	death_panel.get_child(0).add_child(death_menu)
	debug_panel = PanelContainer.new()
	debug_panel.anchor_left = 1.0
	debug_panel.anchor_right = 1.0
	debug_panel.anchor_bottom = 1.0
	debug_panel.offset_left = -300.0
	debug_panel.offset_top = 44.0
	debug_panel.offset_right = -10.0
	debug_panel.offset_bottom = -10.0
	add_child(debug_panel)
	debug_panel.visible = false
	var debug_scroll := ScrollContainer.new()
	debug_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	debug_panel.add_child(debug_scroll)
	var debug_column := VBoxContainer.new()
	debug_column.custom_minimum_size.x = 260
	debug_scroll.add_child(debug_column)
	var debug_title := Label.new()
	debug_title.text = "Debug"
	debug_column.add_child(debug_title)
	performance_label = Label.new()
	debug_column.add_child(performance_label)
	world_debug_label = Label.new()
	debug_column.add_child(world_debug_label)
	for spec in [
		["Give Rock", _debug_give_rock],
		["Give Heavy Pack", _debug_give_heavy_pack],
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
	unlimited_health_toggle = CheckButton.new()
	unlimited_health_toggle.text = "Unlimited Health"
	unlimited_health_toggle.button_pressed = GameSession.debug_unlimited_health
	unlimited_health_toggle.toggled.connect(_set_unlimited_health)
	debug_column.add_child(unlimited_health_toggle)
	for spec in [
		["Toggle World Bounds", &"toggle_bounds"],
		["Teleport Next Slot", &"teleport_next"],
		["Teleport Layer 2 Shop", &"teleport_shop"],
		["Teleport Layer 3 Entrance", &"teleport_ending"],
		["Teleport Surface", &"teleport_surface"],
		["Validate World", &"validate_world"],
		["Dump Manifest", &"dump_manifest"],
	]:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(_emit_world_debug_action.bind(spec[1]))
		debug_column.add_child(button)
	world_log_panel = PanelContainer.new()
	world_log_panel.position = Vector2(40, 30)
	world_log_panel.size = Vector2(560, 300)
	add_child(world_log_panel)
	world_log_panel.visible = false
	var log_column := VBoxContainer.new()
	world_log_panel.add_child(log_column)
	var log_header := HBoxContainer.new()
	log_column.add_child(log_header)
	var log_title := Label.new()
	log_title.text = "World Gen Log"
	log_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_header.add_child(log_title)
	var close_log := Button.new()
	close_log.text = "Close"
	close_log.pressed.connect(func(): world_log_panel.visible = false)
	log_header.add_child(close_log)
	var log_scroll := ScrollContainer.new()
	log_scroll.custom_minimum_size = Vector2(540, 250)
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	log_column.add_child(log_scroll)
	world_log_label = Label.new()
	world_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	world_log_label.custom_minimum_size.x = 515
	log_scroll.add_child(world_log_label)
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
	for index in hotbar_labels.size():
		var stack := player.item_controller.inventory.hotbar[index]
		var item_name := "—"
		if not stack.is_empty():
			var definition := ContentCatalog.get_item(stack.item_id)
			item_name = "%s x%d" % [definition.display_name if definition != null else stack.item_id, stack.quantity]
		hotbar_labels[index].text = "%s%d: %s" % ["▶ " if index == player.item_controller.inventory.active_hotbar_index else "", index + 1, item_name]

func _set_health_text(current: float, maximum: float) -> void:
	health_label.text = "HP ∞" if GameSession.debug_unlimited_health else "HP %d/%d" % [ceili(current), ceili(maximum)]

func _set_unlimited_health(enabled: bool) -> void:
	GameSession.debug_unlimited_health = enabled
	if enabled and player != null and player.is_alive():
		player.health.set_health(player.health.max_health)
	elif player != null:
		_set_health_text(player.health.health, player.health.max_health)

func _update_location() -> void:
	if location_label == null or player == null:
		return
	var slot := String(GameSession.current_slot_id)
	location_label.text = "%s / %s / %s\nX %d  Y %d" % [
		GameSession.current_layer_id,
		GameSession.current_route_id,
		slot if not slot.is_empty() else "-",
		roundi(player.global_position.x),
		roundi(player.global_position.y),
	]

func _on_player_died(_source: Node) -> void:
	player.set_inventory_open(false)
	dialogue_box.close()
	GameSession.run_active = false
	SaveManager.delete_run()
	SaveManager.save_meta()
	pause_panel.visible = false
	death_panel.visible = true
	get_tree().paused = false

func start_new_run() -> void:
	get_tree().paused = false
	SaveManager.delete_run()
	GameSession.start_new_run()
	SceneRouter.go_to("res://game/world/world_run.tscn")

func _return_to_menu() -> void:
	get_tree().paused = false
	SceneRouter.go_to("res://ui/main_menu.tscn")

func _show_feedback(message: String) -> void:
	feedback_label.text = message
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func(): feedback_label.text = "")

func _update_performance() -> void:
	var fps := Engine.get_frames_per_second()
	var frame_ms := 1000.0 / maxf(float(fps), 1.0)
	performance_label.text = "FPS: %d\nFrame: %.1f ms" % [fps, frame_ms]

func set_world_debug_text(text: String) -> void:
	if world_debug_label != null:
		world_debug_label.text = text

func set_world_generation_log(entries: Array[Dictionary], manifest: Dictionary = {}) -> void:
	if world_log_label == null:
		return
	var lines := PackedStringArray()
	for entry in entries:
		lines.append("%s: %.2f ms" % [entry.get("stage", "Unknown"), float(entry.get("duration_ms", 0.0))])
	var sections: Dictionary = manifest.get("sections", {})
	if not sections.is_empty():
		lines.append("\nSections:")
		var slot_ids := sections.keys()
		slot_ids.sort()
		for slot_id in slot_ids:
			lines.append("%s = %s" % [slot_id, sections[slot_id].get("variation_id", "missing")])
	var placers: Dictionary = manifest.get("placers", {})
	if not placers.is_empty():
		lines.append("\nPlacers:")
		var placer_ids := placers.keys()
		placer_ids.sort()
		for placer_id in placer_ids:
			lines.append("%s = %d result(s)" % [placer_id, placers[placer_id].size()])
	world_log_label.text = "No generation log" if lines.is_empty() else "\n".join(lines)

func _emit_world_debug_action(action: StringName) -> void:
	world_debug_action_requested.emit(action)

func _debug_give_rock() -> void:
	player.try_pickup_item(&"throwable_rock", 1, {})

func _debug_give_heavy_pack() -> void:
	player.try_pickup_item(&"debug_heavy_pack", 1, {})

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
