extends Node

signal run_started
signal money_changed(value: int)
signal whistle_changed(tier: StringName)
signal delivery_changed(value: int)
signal display_settings_changed

const STARTING_MONEY := 50
const DESIGN_SIZE := Vector2(640.0, 360.0)
const MENU_CURSOR := preload("res://assets/art/ui/cursors/cursor-1.png")
const GAME_CURSOR := preload("res://assets/art/ui/cursors/cursor-2.png")
const DEFAULT_WINDOWED_SIZE := Vector2i(1280, 720)
const WINDOWED_SIZE_PRESETS: Array[Vector2i] = [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1440)]

var run_active := false
var run_seed := 0
var money := STARTING_MONEY
var whistle_tier: StringName = &"red"
var delivery := 0
var known_items: Array[StringName] = []
var item_use_counts: Dictionary = {}
var progression_flags: Dictionary = {}
var world_manifest: Dictionary = {}
var current_layer_id: StringName = &"surface"
var current_route_id: StringName = &"west"
var current_slot_id: StringName = &""
var debug_enabled := false
var debug_unlimited_health := false
var debug_gameplay_draw := false
var debug_custom_layer_id: StringName = &""
var debug_custom_section_overrides: Dictionary = {}
var runtime_id_counter := 0
var world_generation_log: Array[Dictionary] = []
var master_volume := 1.0
var fullscreen := false
var windowed_size := DEFAULT_WINDOWED_SIZE
var first_launch := false
var _resize_save_timer: Timer
var _applying_display := false

func _ready() -> void:
	_setup_input_map()
	first_launch = not SaveManager.load_meta()
	if first_launch:
		SaveManager.save_meta()
	get_window().size_changed.connect(_on_window_size_changed)
	get_window().unresizable = false
	apply_settings()
	_resize_save_timer = Timer.new()
	_resize_save_timer.one_shot = true
	_resize_save_timer.wait_time = 0.4
	_resize_save_timer.timeout.connect(SaveManager.save_meta)
	add_child(_resize_save_timer)

func start_new_run(seed_value := 0, enable_debug := false) -> void:
	run_active = true
	run_seed = seed_value if seed_value != 0 else randi()
	money = STARTING_MONEY
	whistle_tier = &"red"
	delivery = 0
	progression_flags = {"free_multitool_replacement_used": false}
	world_manifest.clear()
	current_layer_id = &"surface"
	current_route_id = &"west"
	current_slot_id = &""
	debug_enabled = enable_debug
	debug_unlimited_health = false
	debug_gameplay_draw = false
	debug_custom_layer_id = &""
	debug_custom_section_overrides.clear()
	runtime_id_counter = 0
	world_generation_log.clear()
	run_started.emit()
	money_changed.emit(money)
	whistle_changed.emit(whistle_tier)
	delivery_changed.emit(delivery)

func try_spend(amount: int) -> bool:
	if amount < 0 or money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true

func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	money_changed.emit(money)

func add_delivery(amount: int) -> void:
	delivery = maxi(0, delivery + amount)
	delivery_changed.emit(delivery)

func capture_state() -> Dictionary:
	return {
		"run_active": run_active,
		"run_seed": run_seed,
		"money": money,
		"whistle_tier": String(whistle_tier),
		"delivery": delivery,
		"progression_flags": progression_flags.duplicate(true),
		"world_manifest": world_manifest.duplicate(true),
		"current_layer_id": String(current_layer_id),
		"current_route_id": String(current_route_id),
		"current_slot_id": String(current_slot_id),
		"debug_enabled": debug_enabled,
		"debug_unlimited_health": debug_unlimited_health,
		"debug_gameplay_draw": debug_gameplay_draw,
		"runtime_id_counter": runtime_id_counter,
		"world_generation_log": world_generation_log.duplicate(true),
	}

func restore_state(data: Dictionary) -> void:
	run_active = bool(data.get("run_active", false))
	run_seed = int(data.get("run_seed", 0))
	money = int(data.get("money", STARTING_MONEY))
	whistle_tier = StringName(data.get("whistle_tier", "red"))
	delivery = int(data.get("delivery", 0))
	progression_flags = data.get("progression_flags", {}).duplicate(true)
	world_manifest = data.get("world_manifest", {}).duplicate(true)
	current_layer_id = StringName(data.get("current_layer_id", "surface"))
	current_route_id = StringName(data.get("current_route_id", "west"))
	current_slot_id = StringName(data.get("current_slot_id", ""))
	debug_enabled = bool(data.get("debug_enabled", false))
	debug_unlimited_health = bool(data.get("debug_unlimited_health", false))
	debug_gameplay_draw = bool(data.get("debug_gameplay_draw", false))
	runtime_id_counter = int(data.get("runtime_id_counter", 0))
	world_generation_log.assign(data.get("world_generation_log", []))
	money_changed.emit(money)
	whistle_changed.emit(whistle_tier)
	delivery_changed.emit(delivery)

func next_runtime_id(prefix: StringName, layer_id: StringName) -> String:
	runtime_id_counter += 1
	return "%s:%s:%d" % [layer_id, prefix, runtime_id_counter]

func capture_meta() -> Dictionary:
	var known: Array[String] = []
	for id in known_items:
		known.append(String(id))
	return {"known_items": known, "item_use_counts": item_use_counts.duplicate(true), "master_volume": master_volume, "fullscreen": fullscreen, "windowed_size": [windowed_size.x, windowed_size.y]}

func restore_meta(data: Dictionary) -> void:
	known_items.clear()
	for id in data.get("known_items", []):
		known_items.append(StringName(id))
	item_use_counts = data.get("item_use_counts", {}).duplicate(true)
	master_volume = clampf(float(data.get("master_volume", 1.0)), 0.0, 1.0)
	fullscreen = bool(data.get("fullscreen", false))
	windowed_size = sanitize_windowed_size(_size_from_meta(data.get("windowed_size", [])))
	apply_settings()
	display_settings_changed.emit()

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(master_volume))
	_applying_display = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not fullscreen and get_window().size != windowed_size:
		DisplayServer.window_set_size(windowed_size)
	_applying_display = false

func set_fullscreen(enabled: bool) -> void:
	if fullscreen == enabled:
		return
	fullscreen = enabled
	apply_settings()
	SaveManager.save_meta()
	display_settings_changed.emit()

func set_windowed_size(value: Vector2i) -> void:
	var sanitized := sanitize_windowed_size(value)
	if windowed_size == sanitized:
		return
	windowed_size = sanitized
	if not fullscreen:
		apply_settings()
	SaveManager.save_meta()
	display_settings_changed.emit()

func get_windowed_size_options(_available_size := Vector2i()) -> Array[Vector2i]:
	var options: Array[Vector2i] = []
	for preset in WINDOWED_SIZE_PRESETS:
		options.append(preset)
	return options

func windowed_size_label(value: Vector2i) -> String:
	return "%d × %d" % [value.x, value.y]

func display_scale() -> float:
	return 1.0

func display_origin() -> Vector2:
	return Vector2.ZERO

func configure_design_root(root: Control) -> void:
	if root == null:
		return
	root.position = Vector2.ZERO
	root.size = DESIGN_SIZE
	root.scale = Vector2.ONE

func screen_to_design(screen_position: Vector2) -> Vector2:
	return screen_position

func use_menu_cursor() -> void:
	Input.set_custom_mouse_cursor(MENU_CURSOR, Input.CURSOR_ARROW, Vector2.ZERO)

func use_game_cursor() -> void:
	Input.set_custom_mouse_cursor(GAME_CURSOR, Input.CURSOR_ARROW, Vector2(8.0, 8.0))

func sanitize_windowed_size(value: Vector2i) -> Vector2i:
	return Vector2i(maxi(value.x, 640), maxi(value.y, 360))

func _size_from_meta(raw_size: Variant) -> Vector2i:
	if raw_size is Array and raw_size.size() == 2:
		return Vector2i(int(raw_size[0]), int(raw_size[1]))
	return DEFAULT_WINDOWED_SIZE

func _on_window_size_changed() -> void:
	if fullscreen or _applying_display:
		return
	windowed_size = sanitize_windowed_size(get_window().size)
	if _resize_save_timer != null:
		_resize_save_timer.start()
	display_settings_changed.emit()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_fullscreen"):
		set_fullscreen(not fullscreen)
		get_viewport().set_input_as_handled()

func record_signature_use(item_id: StringName) -> bool:
	var definition := ContentCatalog.get_item(item_id)
	if definition == null or not definition.discoverable or item_id in known_items:
		return false
	var key := String(item_id)
	item_use_counts[key] = int(item_use_counts.get(key, 0)) + 1
	if int(item_use_counts[key]) < maxi(definition.discovery_threshold, 1):
		return false
	known_items.append(item_id)
	SaveManager.save_meta()
	return true

func _setup_input_map() -> void:
	_add_keys(&"move_left", [KEY_A, KEY_LEFT])
	_add_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_set_keys(&"jump", [KEY_SPACE])
	_add_keys(&"move_up", [KEY_W, KEY_UP])
	_add_keys(&"move_down", [KEY_S, KEY_DOWN])
	_add_keys(&"interact", [KEY_E])
	_add_keys(&"inventory", [KEY_TAB])
	_add_keys(&"hotbar_1", [KEY_1])
	_add_keys(&"hotbar_2", [KEY_2])
	_add_keys(&"pause", [KEY_ESCAPE])
	_add_keys(&"debug_toggle", [KEY_F3])
	_set_keys(&"toggle_fullscreen", [KEY_F11])
	_add_mouse(&"primary_action", MOUSE_BUTTON_LEFT)
	_add_mouse(&"secondary_action", MOUSE_BUTTON_RIGHT)
	_add_mouse(&"hotbar_next", MOUSE_BUTTON_WHEEL_DOWN)
	_add_mouse(&"hotbar_previous", MOUSE_BUTTON_WHEEL_UP)

func _set_keys(action: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_erase_events(action)
	_add_keys(action, keys)

func _add_keys(action: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func _add_mouse(action: StringName, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)
