extends Node

signal run_started
signal money_changed(value: int)
signal whistle_changed(tier: StringName)
signal delivery_changed(value: int)

const STARTING_MONEY := 50

var run_active := false
var run_seed := 0
var money := STARTING_MONEY
var whistle_tier: StringName = &"red"
var delivery := 0
var known_items: Array[StringName] = []
var progression_flags: Dictionary = {}
var world_manifest: Dictionary = {}
var current_layer_id: StringName = &"surface"
var current_route_id: StringName = &"west"
var current_slot_id: StringName = &""
var debug_enabled := false
var debug_unlimited_health := false
var runtime_id_counter := 0
var world_generation_log: Array[Dictionary] = []

func _ready() -> void:
	_setup_input_map()

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
	return {"known_items": known}

func restore_meta(data: Dictionary) -> void:
	known_items.clear()
	for id in data.get("known_items", []):
		known_items.append(StringName(id))

func _setup_input_map() -> void:
	_add_keys(&"move_left", [KEY_A, KEY_LEFT])
	_add_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_add_keys(&"jump", [KEY_SPACE, KEY_W])
	_add_keys(&"interact", [KEY_E])
	_add_keys(&"inventory", [KEY_TAB])
	_add_keys(&"hotbar_1", [KEY_1])
	_add_keys(&"hotbar_2", [KEY_2])
	_add_keys(&"pause", [KEY_ESCAPE])
	_add_keys(&"debug_toggle", [KEY_F3])
	_add_mouse(&"primary_action", MOUSE_BUTTON_LEFT)
	_add_mouse(&"secondary_action", MOUSE_BUTTON_RIGHT)
	_add_mouse(&"hotbar_next", MOUSE_BUTTON_WHEEL_DOWN)
	_add_mouse(&"hotbar_previous", MOUSE_BUTTON_WHEEL_UP)

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
