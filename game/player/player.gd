class_name PlayerController
extends CharacterBody2D

signal inventory_toggled(open: bool)
signal prompt_changed(text: String)

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
@export var carry_capacity := 12
@export var maximum_weight_gravity_multiplier := 1.5
@export var fall_damage_speed := 420.0
@export var maximum_fall_damage := 50.0
@export var walking_sound_distance := 32.0
@export var walking_sound_radius := 96.0
@export var jump_sound_radius := 160.0
@export var landing_sound_radius := 96.0
@export var hard_landing_speed := 420.0
@export var species_id: StringName = &"player"
@export var persistent_id := "player"

@onready var health: HealthComponent = $HealthComponent
@onready var status: StatusController = $StatusController
@onready var item_controller: PlayerItemController = $PlayerItemController
@onready var interaction_sensor: InteractionSensor = $InteractionSensor
@onready var camera: PlayerCamera = $Camera2D

var locks := ControlLocks.new()
var inventory_open := false
var last_safe_position := Vector2(96.0, 260.0)
var _last_air_speed := 0.0
var _knockback := Vector2.ZERO
var _coyote_remaining := 0.0
var _jump_buffer_remaining := 0.0
var _walking_distance := 0.0

func _ready() -> void:
	add_to_group(&"persistent_objects")
	add_to_group(&"detection_producers")
	status.tick_damage_requested.connect(func(amount: float): apply_damage(DamageInfo.new(amount)))
	health.died.connect(_on_died)
	if ContentCatalog.get_item(&"multitool") != null and item_controller.inventory.get_active_stack().is_empty():
		item_controller.inventory.try_add_item(&"multitool")

func _physics_process(delta: float) -> void:
	if not is_alive():
		velocity = Vector2.ZERO
		_knockback = Vector2.ZERO
		return

	var was_on_floor := is_on_floor()
	var before_move := global_position
	var can_control := not locks.is_locked()
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
	var target_speed := axis * move_speed * speed_multiplier
	var rate := _horizontal_rate(axis, was_on_floor)
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)

	if not was_on_floor:
		var fall_multiplier := lerpf(1.0, maximum_weight_gravity_multiplier, encumbrance) if velocity.y >= 0.0 else 1.0
		velocity.y += gravity * fall_multiplier * status.get_multiplier(&"gravity") * delta
		_last_air_speed = maxf(_last_air_speed, velocity.y)
	if _jump_buffer_remaining > 0.0 and _coyote_remaining > 0.0 and can_control and movement_strength > 0.0:
		velocity.y = jump_velocity * movement_strength
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
	var target := interaction_sensor.best_target()
	if event.is_action_pressed(&"interact") and target != null:
		target.interact(self)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"primary_action"):
		item_controller.primary(self, get_parent(), get_global_mouse_position(), target)
	elif event.is_action_pressed(&"secondary_action"):
		item_controller.secondary(self, get_parent(), get_global_mouse_position(), target)

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
	if not is_on_floor():
		$AnimatedSprite2D.play(&"jump" if velocity.y < 0.0 else &"fall")
	elif absf(velocity.x) > 1.0:
		$AnimatedSprite2D.play(&"walk")
	else:
		$AnimatedSprite2D.play(&"idle")
	if velocity.x != 0.0:
		$AnimatedSprite2D.flip_h = velocity.x < 0.0

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
		SoundBus.emit_sound(get_tree(), SoundEvent.new(global_position, radius, type, priority, self))

func set_inventory_open(open: bool) -> void:
	if inventory_open == open:
		return
	inventory_open = open
	camera.ui_active = open
	inventory_toggled.emit(inventory_open)

func toggle_inventory() -> void:
	set_inventory_open(not inventory_open)

func try_pickup_item(item_id: StringName, quantity: int, state: Dictionary) -> bool:
	return item_controller.inventory.try_add_item(item_id, quantity, state)

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

func apply_force(force: Vector2) -> void:
	if is_alive():
		_knockback += force

func is_alive() -> bool:
	return not health.is_dead

func apply_status(effect_id: StringName, data: Dictionary = {}) -> bool:
	return status.apply_status(effect_id, data)

func set_last_safe_position(value: Vector2) -> void:
	last_safe_position = value

func recover_from_out_of_bounds() -> void:
	global_position = last_safe_position
	health.set_health(health.max_health if GameSession.debug_unlimited_health else 1.0)
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO

func set_camera_bounds(bounds: Rect2) -> void:
	camera.set_world_bounds(bounds)

func capture_state() -> Dictionary:
	return {
		"position": [global_position.x, global_position.y],
		"last_safe_position": [last_safe_position.x, last_safe_position.y],
		"health": health.capture_state(),
		"inventory": item_controller.inventory.capture_state(),
		"status": status.capture_state(),
	}

func restore_state(data: Dictionary) -> void:
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
	velocity = Vector2.ZERO
	_coyote_remaining = 0.0
	_jump_buffer_remaining = 0.0

func _update_prompt() -> void:
	var target := interaction_sensor.best_target()
	var text := ""
	if target != null and target.has_method("get_interaction_prompt"):
		text = target.get_interaction_prompt(self)
	prompt_changed.emit(text)

func _on_died(_source: Node) -> void:
	locks.lock(&"death")
	item_controller.cancel_prepared()
