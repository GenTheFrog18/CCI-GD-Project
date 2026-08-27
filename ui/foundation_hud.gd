class_name FoundationHUD
extends CanvasLayer

const FIRE_FULL := preload("res://assets/art/ui/hud/fire-hp-bar.png")
const FIRE_LOW := preload("res://assets/art/ui/hud/fire-low-hp-bar.png")
const FIRE_DEAD := preload("res://assets/art/ui/hud/fire-dead-hp-bar.png")
const HOTBAR_MAIN := preload("res://assets/art/ui/hud/hotbar-main.png")
const HOTBAR_SECONDARY := preload("res://assets/art/ui/hud/hotbar-sec.png")
const HOTBAR_ARROW := preload("res://assets/art/ui/hud/arrow-hotbar.png")
const WARNING_ICON := preload("res://assets/art/characters/player/warning.png")
const ENEMY_POINTER_ICON := preload("res://assets/art/characters/player/enemy_pointer.png")
const SETTINGS_POPUP_SCENE := preload("res://ui/settings_popup.tscn")
const INVENTORY_MENU_SCENE := preload("res://ui/inventory_menu.tscn")
const SHOP_UI_SCENE := preload("res://ui/shop_ui.tscn")
const DIALOGUE_BOX_SCENE := preload("res://ui/dialogue_box.tscn")

signal world_debug_action_requested(action: StringName)

var player: PlayerController
var health_label: Label
var status_label: Label
var money_label: Label
var weight_label: Label
var prompt_label: Label
var feedback_label: Label
var inventory_menu: InventoryMenu
var shop_ui: ShopUI
var inventory_buttons: Array[Button] = []
var hotbar_labels: Array[Label] = []
var whistle_button: BaseButton
var whistle_icon: TextureRect
var health_value_tooltip: Label
var debug_panel: PanelContainer
var pause_panel: SettingsPopup
var death_panel: PanelContainer
var dialogue_box: DialogueBox
var dialogue_controller: DialogueController
var crosshair: Node2D
var performance_label: Label
var world_debug_label: Label
var world_log_panel: PanelContainer
var world_log_label: Label
var unlimited_health_toggle: CheckButton
var location_label: Label
var warning_layer: Control
var warning_icon: Sprite2D
var _selected_container: StringName
var _selected_index := -1
var _performance_elapsed := 0.0
var _status_elapsed := 0.0
var _threats: Dictionary = {}
var effect_overlay: ColorRect
var health_flames: Array[TextureRect] = []
var _health_flash_tween: Tween
var _health_flash_normal_materials: Array[Material] = []
var _health_flash_material: ShaderMaterial
var hotbar_icons: Array[TextureRect] = []
var hotbar_slots: Array[Control] = []
var hotbar_indices: Array[int] = []
var hotbar_arrow: TextureRect
var _hotbar_layout_ready := false
var debug_text_nodes: Array[CanvasItem] = []

@export_range(1.0, 2.0, 0.01) var selected_hotbar_scale := 1.25
@export_range(1.0, 2.0, 0.01) var hotbar_bounce_scale := 1.35
@export_range(0.01, 1.0, 0.01) var hotbar_animation_seconds := 0.18
@export_range(16.0, 96.0, 1.0) var hotbar_slot_size := 32.0
@export var warning_icon_offset := Vector2(0.0, -30.0)
@export_range(0.0, 128.0, 1.0) var warning_pointer_orbit_distance := 24.0

@onready var logical_ui: Control = $LogicalUI

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"foundation_hud")
	GameSession.use_game_cursor()
	GameSession.configure_design_root(logical_ui)
	GameSession.display_settings_changed.connect(func(): GameSession.configure_design_root(logical_ui))
	_build_ui()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(delta: float) -> void:
	crosshair.position = GameSession.screen_to_design(get_viewport().get_mouse_position())
	_update_cursor_appearance()
	_update_location()
	_update_threat(delta)
	_status_elapsed += delta
	if _status_elapsed >= 0.1:
		_status_elapsed = 0.0
		_refresh_status()
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
	player.health.damaged.connect(_flash_health_flames)
	player.health.died.connect(_on_player_died)
	player.item_controller.inventory.changed.connect(_refresh_inventory)
	player.item_controller.feedback_requested.connect(_show_feedback)
	player.whistle_slot_changed.connect(_refresh_whistle)
	player.threat_warning_requested.connect(_show_threat)
	player.status.status_changed.connect(_refresh_status)
	GameSession.money_changed.connect(func(value: int): money_label.text = "%dg" % value)
	_set_health_text(player.health.health, player.health.max_health)
	money_label.text = "%dg" % GameSession.money
	_refresh_inventory()
	call_deferred("_finish_hotbar_layout")
	_refresh_whistle(player.physical_whistle_id)
	_refresh_status()

func open_shop(service: ShopService, shop_player: PlayerController) -> void:
	shop_ui.open_shop(service, shop_player)

func show_dialogue(sequence: DialogueSequence, actor: Node = null) -> void:
	dialogue_controller.start_sequence(sequence, actor, player)

func open_how_to_from_dialogue() -> void:
	get_tree().paused = true
	pause_panel.show_popup()
	pause_panel.show_how_to_page()

func _input(event: InputEvent) -> void:
	if player == null:
		return
	if dialogue_box != null and dialogue_box.visible:
		if event.is_action_pressed(&"ui_cancel"):
			dialogue_controller.close()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed(&"inventory") or event.is_action_pressed(&"pause"):
			get_viewport().set_input_as_handled()
		return
	if shop_ui != null and shop_ui.visible:
		if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"inventory") or event.is_action_pressed(&"pause"):
			shop_ui.close_shop()
			get_viewport().set_input_as_handled()
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
		elif pause_panel.visible:
			_resume_pause_menu()
		else:
			get_tree().paused = true
			pause_panel.show_popup()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"debug_toggle"):
		debug_panel.visible = not debug_panel.visible
		_set_debug_text_visible(debug_panel.visible)
		if debug_panel.visible:
			_update_performance()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	health_flames.clear()
	for flame in $LogicalUI/HealthFlames.get_children(): health_flames.append(flame as TextureRect)
	$LogicalUI/HealthFlames.mouse_filter = Control.MOUSE_FILTER_STOP
	for flame in health_flames: flame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var white_shader := Shader.new()
	white_shader.code = HitFlash.WHITE_SHADER
	_health_flash_material = ShaderMaterial.new()
	_health_flash_material.shader = white_shader
	health_value_tooltip = $LogicalUI/HealthValueTooltip
	$LogicalUI/HealthFlames.mouse_entered.connect(func(): health_value_tooltip.show())
	$LogicalUI/HealthFlames.mouse_exited.connect(func(): health_value_tooltip.hide())
	health_label = $LogicalUI/TopStats/Health
	status_label = $LogicalUI/Status
	money_label = $LogicalUI/TopStats/Money
	weight_label = $LogicalUI/TopStats/Weight
	location_label = $LogicalUI/Location
	prompt_label = $LogicalUI/Prompt
	feedback_label = $LogicalUI/Feedback
	warning_layer = $LogicalUI/Threat
	warning_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning_icon = Sprite2D.new()
	warning_icon.texture = WARNING_ICON
	warning_icon.z_index = 1
	warning_layer.add_child(warning_icon)
	warning_icon.hide()
	effect_overlay = $LogicalUI/EffectOverlay
	hotbar_slots.clear()
	hotbar_indices.clear()
	for child in $LogicalUI/Hotbar.get_children():
		if child is TextureRect:
			hotbar_slots.append(child)
			hotbar_indices.append(int(String(child.name).trim_prefix("Slot")))
	hotbar_icons = []
	for slot in hotbar_slots:
		hotbar_icons.append(slot.get_node("Icon") as TextureRect)
	hotbar_labels = [$LogicalUI/HotbarLabel0, $LogicalUI/HotbarLabel1]
	hotbar_arrow = $LogicalUI/Arrow
	hotbar_arrow.hide()
	whistle_button = $LogicalUI/Hotbar/Whistle
	whistle_icon = $LogicalUI/Hotbar/Whistle/Icon
	whistle_button.custom_minimum_size = Vector2.ONE * hotbar_slot_size
	whistle_button.pressed.connect(func(): player.use_whistle() if player != null else false)
	for display_index in hotbar_slots.size():
		var slot := hotbar_slots[display_index]
		slot.custom_minimum_size = Vector2.ONE * hotbar_slot_size
		slot.pivot_offset = Vector2.ONE * hotbar_slot_size * 0.5
		var click_target := slot.get_node("ClickTarget") as Button
		click_target.pressed.connect(_select_hotbar.bind(hotbar_indices[display_index]))
	debug_text_nodes.append(health_label)
	debug_text_nodes.append(money_label)
	debug_text_nodes.append(weight_label)
	debug_text_nodes.append(location_label)
	inventory_menu = INVENTORY_MENU_SCENE.instantiate() as InventoryMenu
	logical_ui.add_child(inventory_menu)
	shop_ui = SHOP_UI_SCENE.instantiate() as ShopUI
	logical_ui.add_child(shop_ui)
	inventory_menu.close_requested.connect(func(): player.set_inventory_open(false) if player != null else false)
	for index in inventory_menu.slot_buttons.size():
		var button := inventory_menu.slot_buttons[index]
		button.hud = self
		button.flat_index = index
		button.pressed.connect(_slot_pressed.bind(index))
		button.gui_input.connect(_slot_gui_input.bind(index))
		inventory_buttons.append(button)
	(inventory_menu.get_node("BookContent/Whistle") as TextureButton).pressed.connect(func(): player.use_whistle() if player != null else false)
	dialogue_box = DIALOGUE_BOX_SCENE.instantiate() as DialogueBox
	dialogue_box.position = Vector2(60, 245)
	logical_ui.add_child(dialogue_box)
	dialogue_controller = DialogueController.new()
	logical_ui.add_child(dialogue_controller)
	dialogue_controller.setup(dialogue_box)
	pause_panel = SETTINGS_POPUP_SCENE.instantiate() as SettingsPopup
	pause_panel.configure(true, "Save & Menu")
	pause_panel.resume_requested.connect(_resume_pause_menu)
	pause_panel.main_action_requested.connect(_save_and_return_to_menu)
	logical_ui.add_child(pause_panel)
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
	logical_ui.add_child(debug_panel)
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
		["Give Rope", _debug_give_rope],
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
	for item_id in [&"bandage", &"info_book", &"numbing_pill", &"sun_sphere", &"lantern_crystal", &"rattlepod", &"hushcap", &"cling_resin", &"driftseed", &"silver_weight", &"plate_umbrella", &"lacerator", &"resonance_core", &"bolt_shock"]:
		var definition := ContentCatalog.get_item(item_id)
		var button := Button.new()
		button.text = "Give %s" % (definition.display_name if definition != null else String(item_id))
		button.pressed.connect(_debug_give_item.bind(item_id))
		debug_column.add_child(button)
	var blue_whistle := Button.new()
	blue_whistle.text = "Grant Blue Whistle"
	blue_whistle.pressed.connect(_debug_grant_blue_whistle)
	debug_column.add_child(blue_whistle)
	var moon_whistle := Button.new()
	moon_whistle.text = "Grant Moon Whistle"
	moon_whistle.pressed.connect(_debug_grant_moon_whistle)
	debug_column.add_child(moon_whistle)
	unlimited_health_toggle = CheckButton.new()
	unlimited_health_toggle.text = "Unlimited Health"
	unlimited_health_toggle.button_pressed = GameSession.debug_unlimited_health
	unlimited_health_toggle.toggled.connect(_set_unlimited_health)
	debug_column.add_child(unlimited_health_toggle)
	var gameplay_draw_toggle := CheckButton.new()
	gameplay_draw_toggle.text = "Show Gameplay Ranges"
	gameplay_draw_toggle.button_pressed = GameSession.debug_gameplay_draw
	gameplay_draw_toggle.toggled.connect(func(enabled: bool): GameSession.debug_gameplay_draw = enabled)
	debug_column.add_child(gameplay_draw_toggle)
	for spec in [
		["Toggle World Bounds", &"toggle_bounds"],
		["Teleport Next Slot", &"teleport_next"],
		["Teleport Layer 2 Shop", &"teleport_shop"],
		["Teleport Layer 3 Entrance", &"teleport_ending"],
		["Teleport Surface", &"teleport_surface"],
		["Spawn Layer 2 Enemies", &"spawn_layer2_enemies"],
		["Validate World", &"validate_world"],
		["Dump Manifest", &"dump_manifest"],
		["Reset Curse Height", &"curse_reset"],
		["Clear Effects", &"curse_clear"],
		["Add Healing", &"curse_heal"],
		["Apply Layer Curse", &"curse_apply"],
	]:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(_emit_world_debug_action.bind(spec[1]))
		debug_column.add_child(button)
	world_log_panel = PanelContainer.new()
	world_log_panel.position = Vector2(40, 30)
	world_log_panel.size = Vector2(560, 300)
	logical_ui.add_child(world_log_panel)
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
	_set_debug_text_visible(false)
	_build_crosshair()

func _build_health_flames() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(8, 6)
	row.add_theme_constant_override(&"separation", 0)
	logical_ui.add_child(row)
	for index in 10:
		var flame := TextureRect.new()
		flame.texture = FIRE_FULL
		flame.custom_minimum_size = Vector2(16, 16)
		flame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		row.add_child(flame)
		health_flames.append(flame)

func _build_crosshair() -> void:
	var cursor_sprite := Sprite2D.new()
	cursor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	crosshair = cursor_sprite
	crosshair.z_index = 100
	logical_ui.add_child(crosshair)
	_update_cursor_appearance()

func _update_cursor_appearance() -> void:
	var cursor_sprite := crosshair as Sprite2D
	if cursor_sprite == null:
		return
	var menu_cursor := _menu_cursor_active()
	var wanted_texture := GameSession.MENU_CURSOR if menu_cursor else GameSession.GAME_CURSOR
	if cursor_sprite.texture != wanted_texture:
		cursor_sprite.texture = wanted_texture
		cursor_sprite.centered = not menu_cursor

func _menu_cursor_active() -> bool:
	return (player != null and player.inventory_open) \
		or (shop_ui != null and shop_ui.visible) \
		or (pause_panel != null and pause_panel.visible) \
		or (dialogue_box != null and dialogue_box.visible) \
		or (death_panel != null and death_panel.visible) \
		or (debug_panel != null and debug_panel.visible) \
		or (world_log_panel != null and world_log_panel.visible)

func _make_panel(title_text: String, at: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = at
	panel.custom_minimum_size = Vector2(165, 80)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.027, 0.04, 0.92)
	style.border_color = Color(0.65, 0.52, 0.32)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override(&"panel", style)
	logical_ui.add_child(panel)
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

func swap_inventory_slots(from_flat: int, to_flat: int) -> void:
	var from_container: StringName = &"hotbar" if from_flat < 2 else &"backpack"
	var to_container: StringName = &"hotbar" if to_flat < 2 else &"backpack"
	player.item_controller.inventory.swap_slots(from_container, from_flat if from_flat < 2 else from_flat - 2, to_container, to_flat if to_flat < 2 else to_flat - 2)
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
	if open:
		inventory_menu.open_menu()
	else:
		inventory_menu.close_menu()
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
		var tooltip := "Empty slot"
		var icon: Texture2D
		var quantity := 0
		if not stack.is_empty():
			var definition := ContentCatalog.get_item(stack.item_id)
			icon = definition.texture_for_instance(stack.state) if definition != null else null
			quantity = stack.quantity
			tooltip = (definition.display_name + "\n" + (definition.known_description if stack.item_id in GameSession.known_items else definition.unknown_description)) if definition != null else String(stack.item_id)
		var selected_flat := -1
		if _selected_index >= 0:
			selected_flat = _selected_index if _selected_container == &"hotbar" else _selected_index + 2
		inventory_menu.set_slot(index, icon, quantity, tooltip, index == selected_flat)
	if _selected_index >= 0:
		var selected_stack := slots[_selected_index if _selected_container == &"hotbar" else _selected_index + 2]
		var selected_definition := ContentCatalog.get_item(selected_stack.item_id)
		inventory_menu.set_details(
			selected_definition.display_name if selected_definition != null else "Select an item",
			(selected_definition.known_description if selected_stack.item_id in GameSession.known_items else selected_definition.unknown_description) if selected_definition != null else "",
			player.item_controller.inventory.get_total_weight(),
			player.carry_capacity,
		)
	else:
		inventory_menu.set_details("Select an item", "", player.item_controller.inventory.get_total_weight(), player.carry_capacity)
	for display_index in hotbar_slots.size():
		var index := hotbar_indices[display_index]
		var stack := player.item_controller.inventory.hotbar[index]
		var item_name := "—"
		if not stack.is_empty():
			var definition := ContentCatalog.get_item(stack.item_id)
			item_name = "%s x%d" % [definition.display_name if definition != null else stack.item_id, stack.quantity]
			hotbar_icons[display_index].texture = definition.texture_for_instance(stack.state) if definition != null else null
		else:
			hotbar_icons[display_index].texture = null
		hotbar_labels[index].text = "%s%d: %s" % ["▶ " if index == player.item_controller.inventory.active_hotbar_index else "", index + 1, item_name]
	var active_display := hotbar_indices.find(player.item_controller.inventory.active_hotbar_index)
	if active_display < 0:
		return
	var active_slot := hotbar_slots[active_display]
	if not _hotbar_layout_ready:
		return
	hotbar_arrow.global_position = active_slot.global_position + Vector2((active_slot.size.x - hotbar_arrow.size.x) * 0.5, -hotbar_arrow.size.y)
	hotbar_arrow.show()
	for display_index in hotbar_slots.size(): _animate_hotbar_slot(hotbar_slots[display_index], display_index == active_display)
	weight_label.text = "Weight %d/%d" % [player.item_controller.inventory.get_total_weight(), player.carry_capacity]

func _finish_hotbar_layout() -> void:
	_hotbar_layout_ready = true
	_refresh_inventory()

func _refresh_whistle(item_id: StringName) -> void:
	if whistle_button == null:
		return
	var definition := ContentCatalog.get_item(item_id)
	whistle_icon.texture = definition.icon if definition != null else null
	whistle_button.tooltip_text = "Use %s" % (definition.display_name if definition != null else "whistle")
	whistle_button.disabled = item_id.is_empty()
	if inventory_menu != null:
		inventory_menu.set_whistle(definition.icon if definition != null else null, whistle_button.tooltip_text)

func _set_debug_text_visible(visible: bool) -> void:
	for node in debug_text_nodes:
		node.visible = visible

func _show_threat(source: Node2D, duration: float) -> void:
	if not is_instance_valid(source):
		return
	var id := source.get_instance_id()
	if _threats.has(id):
		_threats[id].remaining = maxf(float(_threats[id].remaining), duration)
		return
	var pointer := Sprite2D.new()
	pointer.texture = ENEMY_POINTER_ICON
	warning_layer.add_child(pointer)
	_threats[id] = {"source": source, "remaining": duration, "pointer": pointer}

func _update_threat(delta: float) -> void:
	if warning_icon == null or player == null:
		return
	if _threats.is_empty():
		warning_icon.hide()
		return
	var warning_position := GameSession.screen_to_design(player.get_global_transform_with_canvas().origin) + warning_icon_offset
	warning_icon.position = warning_position
	warning_icon.show()
	for id in _threats.keys():
		var threat: Dictionary = _threats[id]
		var source_value: Variant = threat.get("source")
		threat.remaining = float(threat.remaining) - delta
		if not is_instance_valid(source_value) or not source_value.is_inside_tree() or threat.remaining <= 0.0:
			var expired_pointer := threat.get("pointer") as Sprite2D
			if is_instance_valid(expired_pointer): expired_pointer.queue_free()
			_threats.erase(id)
			continue
		var source := source_value as Node2D
		var direction := GameSession.screen_to_design(source.get_global_transform_with_canvas().origin) - warning_position
		if direction.length_squared() < 0.001:
			direction = Vector2.RIGHT
		else:
			direction = direction.normalized()
		var pointer := threat.pointer as Sprite2D
		pointer.position = warning_position + direction * warning_pointer_orbit_distance
		pointer.rotation = direction.angle()

func _refresh_status() -> void:
	if player == null or status_label == null: return
	var lines := PackedStringArray()
	for id: StringName in player.status.active:
		var definition := ContentCatalog.get_effect(id)
		var stacks := player.status.get_stack_count(id)
		var name := definition.display_name if definition != null else String(id)
		var stack_text := " x%d" % stacks if stacks > 1 else ""
		var timer_text := " %ds" % ceili(player.status.get_remaining(id)) if definition == null or definition.show_timer else " — active"
		lines.append("%s%s%s" % [name, stack_text, timer_text])
	status_label.text = "\n".join(lines)
	if player.status.has_status(&"dazzled"):
		effect_overlay.color = Color(1, 1, 1, 0.35)
	elif player.status.has_status(&"curse_layer_2_penalty"):
		effect_overlay.color = Color(0.35, 0.1, 0.45, 0.2)
	elif player.status.has_status(&"curse_layer_1"):
		effect_overlay.color = Color(0.45, 0.1, 0.1, 0.18)
	else:
		effect_overlay.color = Color.TRANSPARENT

func _set_health_text(current: float, maximum: float) -> void:
	health_label.text = "HP ∞" if GameSession.debug_unlimited_health else "HP %d/%d" % [ceili(current), ceili(maximum)]
	$LogicalUI/HealthFlames.tooltip_text = health_label.text
	health_value_tooltip.text = health_label.text
	for index in health_flames.size():
		var threshold := maximum * float(index + 1) / float(health_flames.size())
		health_flames[index].texture = FIRE_FULL if current >= threshold else (FIRE_LOW if current > threshold - maximum / health_flames.size() else FIRE_DEAD)

func _flash_health_flames(info: DamageInfo) -> void:
	if health_flames.is_empty() or _health_flash_material == null:
		return
	if _health_flash_tween != null and _health_flash_tween.is_valid():
		_health_flash_tween.kill()
	_restore_health_flames()
	_health_flash_normal_materials.clear()
	for flame in health_flames:
		_health_flash_normal_materials.append(flame.material)
	_apply_health_flash_material()
	var flash_duration: float = player.hit_flash_duration if player != null else HitFlash.FLASH_SECONDS
	var flash_gap: float = player.hit_flash_gap if player != null else HitFlash.GAP_SECONDS
	var pulses: int = 2 if info.causes_hit_reaction else 1
	_health_flash_tween = create_tween()
	for index in pulses:
		_health_flash_tween.tween_interval(flash_duration)
		_health_flash_tween.tween_callback(_restore_health_flames)
		if index + 1 < pulses:
			_health_flash_tween.tween_interval(flash_gap)
			_health_flash_tween.tween_callback(_apply_health_flash_material)

func _apply_health_flash_material() -> void:
	for flame in health_flames:
		flame.material = _health_flash_material

func _restore_health_flames() -> void:
	for index in mini(health_flames.size(), _health_flash_normal_materials.size()):
		health_flames[index].material = _health_flash_normal_materials[index]

func _select_hotbar(index: int) -> void:
	if player != null:
		player.item_controller.inventory.select_hotbar(index)

func _animate_hotbar_slot(slot: Control, selected: bool) -> void:
	var tween := slot.get_meta("hotbar_tween") as Tween if slot.has_meta("hotbar_tween") else null
	if tween != null: tween.kill()
	tween = create_tween()
	slot.set_meta("hotbar_tween", tween)
	if not selected:
		tween.tween_property(slot, "scale", Vector2.ONE, hotbar_animation_seconds * 0.5)
		return
	tween.tween_property(slot, "scale", Vector2.ONE * hotbar_bounce_scale, hotbar_animation_seconds * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(slot, "scale", Vector2.ONE * selected_hotbar_scale, hotbar_animation_seconds * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
	if dialogue_controller != null:
		dialogue_controller.close()
	GameSession.run_active = false
	SaveManager.delete_run()
	SaveManager.save_meta()
	pause_panel.visible = false
	death_panel.visible = true
	get_tree().paused = false

func _resume_pause_menu() -> void:
	pause_panel.close_popup()
	get_tree().paused = false

func _save_and_return_to_menu() -> void:
	player.item_controller.prepare_for_save()
	SaveManager.save_run()
	get_tree().paused = false
	SceneRouter.go_to("res://ui/main_menu.tscn")

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

func _debug_give_rope() -> void:
	player.try_pickup_item(&"rope", 1, {})

func _debug_give_item(item_id: StringName) -> void:
	if not player.try_pickup_item(item_id, 1, {"origin": "debug"}):
		_show_feedback("No inventory space")

func _debug_grant_blue_whistle() -> void:
	GameSession.whistle_tier = &"blue"
	player.physical_whistle_id = &"whistle_blue"
	player.whistle_slot_changed.emit(player.physical_whistle_id)

func _debug_grant_moon_whistle() -> void:
	GameSession.whistle_tier = &"moon"
	GameSession.whistle_changed.emit(GameSession.whistle_tier)
	player.physical_whistle_id = &"whistle_moon"
	player.whistle_slot_changed.emit(player.physical_whistle_id)

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
