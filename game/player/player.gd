class_name PlayerController
extends CharacterBody2D

signal inventory_toggled(open: bool)
signal prompt_changed(text: String)
signal whistle_slot_changed(item_id: StringName)
signal threat_warning_requested(source: Node2D, duration: float)

@export var move_speed := 120.0
@export var acceleration := 900.0
@export var deceleration := 1100.0
@export var air_acceleration := 600.0
@export var air_deceleration := 600.0
@export var jump_velocity := -280.0
@export var jump_release_multiplier := 0.65
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12
@export var gravity := 900.0
@export var driftseed_fall_speed_cap := 140.0
@export var carry_capacity := 12
@export var maximum_weight_gravity_multiplier := 1.5
@export var fall_damage_speed := 420.0
@export var maximum_fall_damage := 50.0
@export var walking_sound_distance := 32.0
@export var walking_sound_radius := 96.0
@export var jump_sound_radius := 160.0
@export var landing_sound_radius := 96.0
@export var hard_landing_speed := 420.0
@export var rope_climb_speed := 90.0
@export var rope_snap_speed := 240.0
@export var rope_jump_horizontal_speed := 120.0
@export var rope_lateral_range := 8.0
@export var rope_lateral_speed := 48.0
@export var detection_origin_offset := Vector2(0.0, -28.0)
@export var species_id: StringName = &"player"
@export var persistent_id := "player"

@onready var health: HealthComponent = $HealthComponent
@onready var status: StatusController = $StatusController
@onready var item_controller: PlayerItemController = $PlayerItemController
@onready var interaction_sensor: InteractionSensor = $InteractionSensor
@onready var camera: PlayerCamera = $Camera2D
@onready var dazzled_overlay: DazzledOverlay = $DazzledOverlay

var locks := ControlLocks.new()
var inventory_open := false
var last_safe_position := Vector2(96.0, 260.0)
var _last_air_speed := 0.0
var _knockback := Vector2.ZERO
var _coyote_remaining := 0.0
var _jump_buffer_remaining := 0.0
var _walking_distance := 0.0
var _prompt_target: Node
var _prompt_text := ""
var facing_direction := 1.0
var _nearby_ropes: Array[PlacedRope] = []
var _climbing_rope: PlacedRope
var _rope_lateral_offset := 0.0
var _rope_attach_blocked := false
var physical_whistle_id: StringName = &"whistle_red"
var _bird_hit_times: Array[float] = []
var curse_tracker: CurseTracker
var _action_animation := false
var _combat_safe_zone_count := 0
var _thorn_spike_iframe_until := 0
var _hushcap_area_count := 0
var _dazzled_remaining := 0.0

@onready var hushcap_overlay: HushcapOverlay = $HushcapOverlay
func _ready() -> void:
	add_to_group(&"persistent_objects")
	add_to_group(&"detection_producers")
	add_to_group(&"effect_receivers")
	add_to_group(&"player")
	status.tick_damage_requested.connect(_on_status_tick)
	status.tick_healing_requested.connect(heal)
	status.status_changed.connect(_on_status_changed)
	curse_tracker = CurseTracker.new()
	add_child(curse_tracker)
	curse_tracker.setup(self)
	health.died.connect(_on_died)
	$AnimatedSprite2D.animation_finished.connect(func(): _action_animation = false)
	_set_facing(facing_direction)
	if ContentCatalog.get_item(&"multitool") != null and item_controller.inventory.get_active_stack().is_empty():
		item_controller.inventory.try_add_item(&"multitool", 1, {"origin": "starting"})

func set_hushcap_area(active: bool) -> void:
	_hushcap_area_count = maxi(0, _hushcap_area_count + (1 if active else -1))
	hushcap_overlay.set_active(_hushcap_area_count > 0)

func _physics_process(delta: float) -> void:
	if not is_alive():
		velocity = Vector2.ZERO
		_knockback = Vector2.ZERO
		return

	var was_on_floor := is_on_floor()
	var before_move := global_position
	var can_control := not locks.is_locked()
	_try_begin_climb(can_control)
	if is_instance_valid(_climbing_rope):
		if can_control and Input.is_action_just_pressed(&"jump"):
			_jump_from_rope()
		else:
			_physics_climb(delta, can_control)
			return
	_coyote_remaining = coyote_time if was_on_floor else maxf(0.0, _coyote_remaining - delta)
	_jump_buffer_remaining = maxf(0.0, _jump_buffer_remaining - delta)
	if can_control and Input.is_action_just_pressed(&"jump"):
		_jump_buffer_remaining = jump_buffer_time
	if can_control and Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= jump_release_multiplier

	var encumbrance := get_encumbrance_ratio()
	var movement_strength := 1.0 - encumbrance
	var speed_multiplier := status.get_multiplier(&"move_speed") * movement_strength
	if inventory_open:
		speed_multiplier *= 0.35
	var axis := Input.get_axis(&"move_left", &"move_right") if can_control else 0.0
	var target_speed := axis * move_speed * speed_multiplier * item_controller.get_movement_multiplier()
	var rate := _horizontal_rate(axis, was_on_floor)
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)

	if not was_on_floor:
		var fall_multiplier := lerpf(1.0, maximum_weight_gravity_multiplier, encumbrance) if velocity.y >= 0.0 else 1.0
		var status_gravity := status.get_multiplier(&"gravity") if velocity.y >= 0.0 else 1.0
		velocity.y += gravity * fall_multiplier * status_gravity * delta
		if velocity.y > 0.0 and status.has_status(&"driftseed"):
			velocity.y = minf(velocity.y, driftseed_fall_speed_cap)
		_last_air_speed = maxf(_last_air_speed, velocity.y)
	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0 and can_control and movement_strength > 0.0:
		velocity.y = jump_velocity * movement_strength * status.get_multiplier(&"jump_strength") * item_controller.get_jump_multiplier()
		_jump_buffer_remaining = 0.0
		_coyote_remaining = 0.0
		_emit_sound(&"jump", 3, jump_sound_radius)

	velocity += _knockback
	_knockback = Vector2.ZERO
	move_and_slide()

	if not was_on_floor and is_on_floor():
		_on_landed(_last_air_speed)
		_last_air_speed = 0.0
	_update_walking_sound(global_position.x - before_move.x)
	_update_animation()
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive():
		return
	if event.is_action_pressed(&"hotbar_1"):
		item_controller.inventory.select_hotbar(0)
	if event.is_action_pressed(&"hotbar_2"):
		item_controller.inventory.select_hotbar(1)
	if event.is_action_pressed(&"hotbar_next"):
		item_controller.inventory.select_hotbar(item_controller.inventory.active_hotbar_index + 1)
	if event.is_action_pressed(&"hotbar_previous"):
		item_controller.inventory.select_hotbar(item_controller.inventory.active_hotbar_index - 1)
	if inventory_open or locks.is_locked():
		return
	var target := interaction_sensor.best_target(self, get_global_mouse_position())
	if event.is_action_pressed(&"interact") and target != null:
		target.interact(self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"primary_action"):
		_face_toward(get_global_mouse_position())
		var active_id := item_controller.inventory.get_active_stack().item_id
		if item_controller.primary(self, get_parent(), get_global_mouse_position(), target) and active_id == &"multitool":
			_play_action_animation(&"attack")
	elif event.is_action_pressed(&"secondary_action"):
		_face_toward(get_global_mouse_position())
		if item_controller.secondary(self, get_parent(), get_global_mouse_position(), target):
			_play_action_animation(&"throw")

func get_encumbrance_ratio() -> float:
	if carry_capacity <= 0:
		return 1.0 if item_controller.inventory.get_total_weight() > 0 else 0.0
	return clampf(
		float(item_controller.inventory.get_total_weight() - carry_capacity) / float(carry_capacity),
		0.0,
		1.0
	)

func _horizontal_rate(axis: float, grounded: bool) -> float:
	if grounded:
		return acceleration if axis != 0.0 else deceleration
	return air_acceleration if axis != 0.0 else air_deceleration

func _update_animation() -> void:
	if _action_animation:
		return
	if not is_on_floor():
		$AnimatedSprite2D.play(&"jump" if velocity.y < 0.0 else &"fall")
	elif absf(velocity.x) > 1.0:
		$AnimatedSprite2D.play(&"walk")
	else:
		$AnimatedSprite2D.play(&"idle")
	if velocity.x != 0.0:
		_set_facing(signf(velocity.x))

func _play_action_animation(animation: StringName) -> void:
	_action_animation = true
	$AnimatedSprite2D.play(animation)

func _update_walking_sound(horizontal_distance: float) -> void:
	if not is_on_floor() or absf(horizontal_distance) <= 0.001:
		return
	_walking_distance += absf(horizontal_distance)
	while _walking_distance >= walking_sound_distance:
		_walking_distance -= walking_sound_distance
		_emit_sound(&"walk", 1, walking_sound_radius)

func _on_landed(speed: float) -> void:
	if speed > fall_damage_speed:
		var fall_damage := minf((speed - fall_damage_speed) * 0.2, maximum_fall_damage)
		apply_damage(DamageInfo.new(fall_damage))
	var landing_priority := 1 if speed < hard_landing_speed else 3
	_emit_sound(&"land", landing_priority, landing_sound_radius)

func _emit_sound(type: StringName, priority: int, radius: float) -> void:
	if radius > 0.0:
		SoundBus.emit_sound(get_tree(), SoundEvent.new(get_detection_origin(), radius, type, priority, self))

func get_detection_origin() -> Vector2:
	return global_position + detection_origin_offset

func set_inventory_open(open: bool) -> void:
	if inventory_open == open:
		return
	if open and is_instance_valid(item_controller.prepared_item):
		item_controller.cancel_prepared(&"inventory")
	inventory_open = open
	camera.ui_active = open
	inventory_toggled.emit(inventory_open)

func toggle_inventory() -> void:
	set_inventory_open(not inventory_open)

func try_pickup_item(item_id: StringName, quantity: int, state: Dictionary) -> bool:
	var definition := ContentCatalog.get_item(item_id)
	if definition != null and definition.category == &"whistle":
		if quantity != 1 or not physical_whistle_id.is_empty():
			return false
		physical_whistle_id = item_id
		whistle_slot_changed.emit(physical_whistle_id)
		return true
	var item_state := state.duplicate(true)
	if not item_state.has("origin"):
		item_state.origin = "map"
	return item_controller.inventory.try_add_item(item_id, quantity, item_state)

func take_item_for_theft(can_take_multitool := true) -> ItemStack:
	return item_controller.inventory.take_for_theft(can_take_multitool)

func confiscate_map_items() -> Array[ItemStack]:
	return item_controller.inventory.remove_origin(&"map")

func use_whistle() -> bool:
	if physical_whistle_id.is_empty() or inventory_open or locks.is_locked():
		return false
	_emit_sound(&"whistle", 10, 600.0)
	return true

func take_physical_whistle() -> ItemStack:
	if physical_whistle_id.is_empty():
		return ItemStack.new()
	var result := ItemStack.new(physical_whistle_id, 1, {"origin": "progression"})
	physical_whistle_id = &""
	whistle_slot_changed.emit(physical_whistle_id)
	return result

func warn_attack(source: Node2D, duration := 0.6) -> void:
	threat_warning_requested.emit(source, duration)

func register_bird_hit(window_seconds := 2.0, threshold := 2, threshold_damage := 10.0) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	_bird_hit_times = _bird_hit_times.filter(func(stamp: float): return now - stamp <= window_seconds)
	_bird_hit_times.append(now)
	if _bird_hit_times.size() < threshold:
		return false
	_bird_hit_times.clear()
	apply_damage(DamageInfo.new(threshold_damage))
	return true

func drop_inventory_slot(container: StringName, index: int) -> bool:
	var stack := item_controller.inventory.take_one(container, index)
	if stack.is_empty():
		return false
	var definition := ContentCatalog.get_item(stack.item_id)
	if definition == null:
		item_controller.inventory.try_add_item(stack.item_id, 1, stack.state)
		return false
	var dropped := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	dropped.configure(definition, stack.state, self, global_position + Vector2(20.0, -4.0), Vector2.ZERO)
	get_parent().add_child(dropped)
	return true

func apply_damage(info: DamageInfo) -> bool:
	if GameSession.debug_unlimited_health:
		return false
	return health.apply_damage(info, species_id)

func apply_thorn_spike_damage(info: DamageInfo, iframe_seconds: float) -> bool:
	if Time.get_ticks_msec() < _thorn_spike_iframe_until:
		return false
	if not apply_damage(info):
		return false
	_thorn_spike_iframe_until = Time.get_ticks_msec() + int(maxf(iframe_seconds, 0.0) * 1000.0)
	return true

func resolve_impact(impact: ImpactData) -> Dictionary:
	if is_combat_protected() and not impact.source_species_id.is_empty() and impact.source_species_id != species_id:
		return {"handled": true, "damage": false, "force": false, "statuses": 0, "agitation": false, "protected": true}
	var prepared := item_controller.prepared_item
	if is_instance_valid(prepared) and prepared.has_method("resolve_impact"):
		return prepared.resolve_impact(impact)
	return {}

func enter_combat_safe_zone() -> void:
	_combat_safe_zone_count += 1

func exit_combat_safe_zone() -> void:
	_combat_safe_zone_count = maxi(0, _combat_safe_zone_count - 1)

func is_combat_protected() -> bool:
	return _combat_safe_zone_count > 0

func apply_force(force: Vector2) -> void:
	if is_alive():
		if not force.is_zero_approx():
			_detach_rope(true)
		_knockback += force * status.get_multiplier(&"knockback_received")

func is_alive() -> bool:
	return not health.is_dead

func apply_status(effect_id: StringName, data: Dictionary = {}) -> bool:
	return status.apply_status(effect_id, data)

func heal(amount: float) -> float:
	var cap_stacks := status.get_stack_count(&"curse_layer_2_health_cap")
	var cap := health.max_health * (1.0 - 0.1 * cap_stacks)
	return health.heal(amount, status.get_multiplier(&"healing_received"), cap)

func get_throw_range_multiplier() -> float:
	return status.get_multiplier(&"throw_range")

func _on_status_tick(amount: float) -> void:
	var info := DamageInfo.new(amount)
	info.bypass_invulnerability = true
	info.causes_hit_reaction = false
	info.tags = [&"status_tick"]
	apply_damage(info)

func _on_status_changed() -> void:
	var dazzled_remaining := status.get_remaining(&"dazzled")
	if dazzled_remaining > _dazzled_remaining + 0.01:
		dazzled_overlay.start_flash(dazzled_remaining)
	elif dazzled_remaining <= 0.0 and _dazzled_remaining > 0.0:
		dazzled_overlay.stop_flash()
	_dazzled_remaining = dazzled_remaining
	if status.has_status(&"incapacitated"):
		locks.lock(&"status_incapacitated")
		_detach_rope(true)
	else:
		locks.unlock(&"status_incapacitated")

func set_last_safe_position(value: Vector2) -> void:
	last_safe_position = value

func recover_from_out_of_bounds() -> void:
	_detach_rope()
	global_position = last_safe_position
	health.set_health(health.max_health if GameSession.debug_unlimited_health else 1.0)
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	curse_tracker.reset_reference(true)

func set_camera_bounds(bounds: Rect2) -> void:
	camera.set_world_bounds(bounds)

func capture_state() -> Dictionary:
	var saved_position := last_safe_position if is_climbing() else global_position
	return {
		"position": [saved_position.x, saved_position.y],
		"last_safe_position": [last_safe_position.x, last_safe_position.y],
		"health": health.capture_state(),
		"inventory": item_controller.inventory.capture_state(),
		"status": status.capture_state(),
		"physical_whistle_id": String(physical_whistle_id),
		"curse": curse_tracker.capture_state(),
	}

func restore_state(data: Dictionary) -> void:
	_detach_rope()
	var saved_safe: Array = data.get("last_safe_position", [96.0, 260.0])
	if saved_safe.size() >= 2:
		last_safe_position = Vector2(float(saved_safe[0]), float(saved_safe[1]))
	var saved_position: Array = data.get("position", [])
	var candidate := last_safe_position
	if saved_position.size() >= 2:
		candidate = Vector2(float(saved_position[0]), float(saved_position[1]))
	if not candidate.is_finite():
		candidate = last_safe_position
	global_position = candidate
	health.restore_state(data.get("health", {}))
	item_controller.inventory.restore_state(data.get("inventory", {}))
	status.restore_state(data.get("status", {}))
	physical_whistle_id = StringName(data.get("physical_whistle_id", "whistle_red"))
	whistle_slot_changed.emit(physical_whistle_id)
	curse_tracker.restore_state(data.get("curse", {}))
	velocity = Vector2.ZERO
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0

func _update_prompt() -> void:
	var target := interaction_sensor.best_target(self, get_global_mouse_position())
	var text := ""
	if target != null and target.has_method("get_interaction_prompt"):
		text = target.get_interaction_prompt(self)
	if target != _prompt_target or text != _prompt_text:
		if is_instance_valid(_prompt_target):
			if _prompt_target.has_method("set_interaction_indicator"):
				_prompt_target.set_interaction_indicator(false)

		if is_instance_valid(target):
			if target.has_method("set_interaction_indicator"):
				target.set_interaction_indicator(true)
		_prompt_target = target
		_prompt_text = text
		prompt_changed.emit(text)

func _on_died(_source: Node) -> void:
	_detach_rope()
	locks.lock(&"death")
	item_controller.cancel_prepared()
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	$AnimatedSprite2D.animation = &"idle"
	$AnimatedSprite2D.frame = 0
	$AnimatedSprite2D.stop()

func register_climbable(rope: PlacedRope) -> void:
	if rope != null and rope not in _nearby_ropes:
		_nearby_ropes.append(rope)

func unregister_climbable(rope: PlacedRope) -> void:
	_nearby_ropes.erase(rope)

func is_climbing() -> bool:
	return is_instance_valid(_climbing_rope)

func _try_begin_climb(can_control: bool) -> void:
	_nearby_ropes = _nearby_ropes.filter(func(rope: PlacedRope): return is_instance_valid(rope))
	if is_instance_valid(_climbing_rope) or not can_control:
		return
	if not Input.is_action_pressed(&"move_up") and not Input.is_action_pressed(&"move_down"):
		_rope_attach_blocked = false
		return
	if _rope_attach_blocked:
		return
	try_attach_nearby_rope()

func try_attach_nearby_rope() -> bool:
	var closest: PlacedRope
	var distance := INF
	for rope in _nearby_ropes:
		var candidate_distance := absf(global_position.x - rope.global_position.x)
		if candidate_distance < distance:
			closest = rope
			distance = candidate_distance
	if closest == null:
		return false
	_climbing_rope = closest.get_chain_root()
	_rope_lateral_offset = 0.0
	velocity = Vector2.ZERO
	return true

func _physics_climb(delta: float, can_control: bool) -> void:
	var vertical := Input.get_axis(&"move_up", &"move_down") if can_control else 0.0
	var horizontal := Input.get_axis(&"move_left", &"move_right") if can_control else 0.0
	_rope_lateral_offset = move_toward(_rope_lateral_offset, horizontal * rope_lateral_range, rope_lateral_speed * delta)
	var chain_top := _climbing_rope.get_chain_top()
	var chain_bottom := _climbing_rope.get_chain_bottom()
	if (vertical < 0.0 and global_position.y <= chain_top) or (vertical > 0.0 and global_position.y >= chain_bottom):
		vertical = 0.0
	var target_x := _climbing_rope.global_position.x + _rope_lateral_offset
	velocity = Vector2(clampf((target_x - global_position.x) / maxf(delta, 0.001), -rope_snap_speed, rope_snap_speed), vertical * rope_climb_speed * item_controller.get_climb_multiplier())
	move_and_slide()
	global_position.y = clampf(global_position.y, chain_top, chain_bottom)
	_update_animation()
	_update_prompt()

func _jump_from_rope() -> void:
	var horizontal := Input.get_axis(&"move_left", &"move_right")
	_detach_rope(true)
	velocity = Vector2(horizontal * rope_jump_horizontal_speed, jump_velocity * (1.0 - get_encumbrance_ratio()) * item_controller.get_jump_multiplier())
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0
	_emit_sound(&"jump", 3, jump_sound_radius)

func _detach_rope(block_attach := false) -> void:
	_climbing_rope = null
	_rope_lateral_offset = 0.0
	_rope_attach_blocked = block_attach
	
func face_toward_position(world_position: Vector2) -> void:
	_face_toward(world_position)

func _face_toward(world_position: Vector2) -> void:
	if not is_equal_approx(world_position.x, global_position.x):
		_set_facing(signf(world_position.x - global_position.x))

func _set_facing(direction: float) -> void:
	facing_direction = -1.0 if direction < 0.0 else 1.0
	$AnimatedSprite2D.flip_h = facing_direction < 0.0
	$HeldItemAnchor.position.x = absf($HeldItemAnchor.position.x) * facing_direction
	$HeldItemAnchor/HeldItemIcon.flip_h = facing_direction < 0.0

func _draw() -> void:
	if GameSession.debug_gameplay_draw and curse_tracker != null:
		draw_line(Vector2(-1000.0, curse_tracker.reference_y - global_position.y), Vector2(1000.0, curse_tracker.reference_y - global_position.y), Color(0.8, 0.2, 0.8, 0.8), 2.0)
