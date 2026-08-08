class_name PlayerController
extends CharacterBody2D

signal inventory_toggled(open: bool)
signal prompt_changed(text: String)

@export var move_speed := 120.0
@export var acceleration := 900.0
@export var deceleration := 1100.0
@export var jump_velocity := -280.0
@export var gravity := 900.0
@export var fall_damage_speed := 420.0
@export var maximum_fall_damage := 50.0
@export var camera_base_offset := Vector2(0.0, -40.0)
@export var camera_max_cursor_offset := Vector2(56.0, 28.0)
@export_range(0.0, 30.0, 0.1) var camera_smoothing := 8.0
@export var species_id: StringName = &"player"
@export var persistent_id := "player"

@onready var health: HealthComponent = $HealthComponent
@onready var status: StatusController = $StatusController
@onready var item_controller: PlayerItemController = $PlayerItemController
@onready var interaction_sensor: InteractionSensor = $InteractionSensor
@onready var camera: Camera2D = $Camera2D
@onready var sword_hitbox: SwordHitbox = $SwordHitbox

var locks := ControlLocks.new()
var inventory_open := false
var last_safe_position := Vector2(96.0, 260.0)
var _last_air_speed := 0.0
var _knockback := Vector2.ZERO
var _camera_target_position := Vector2(0.0, -40.0)
var is_attacking := false

func _ready() -> void:
	add_to_group(&"persistent_objects")
	status.tick_damage_requested.connect(func(amount: float): apply_damage(DamageInfo.new(amount)))
	health.died.connect(_on_died)
	_camera_target_position = camera_base_offset 
	if ContentCatalog.get_item(&"multitool") != null and item_controller.inventory.get_active_stack().is_empty():
		item_controller.inventory.try_add_item(&"multitool")

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseMotion:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	_camera_target_position = _camera_target(event.position, viewport_size)
	
func _update_animation() -> void:
	if is_attacking:
		return

	if not is_on_floor():
		if(velocity.x) < 0:
			$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")
	elif abs(velocity.x) > 1.0:
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.play("idle")

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0
		
func attack() -> void:
	if is_attacking:
		return

	is_attacking = true

	velocity.x = 0

	$AnimatedSprite2D.play("combat")

	await get_tree().create_timer(0.15).timeout

	sword_hitbox.start_attack()

	await get_tree().create_timer(0.15).timeout

	sword_hitbox.end_attack()
	
	$AnimatedSprite2D.play("combat_end")

	await $AnimatedSprite2D.animation_finished

	is_attacking = false
	
	velocity.x = 0
	
	_update_animation()

func _camera_target(cursor_position: Vector2, viewport_size: Vector2) -> Vector2:
	var cursor_ratio := (cursor_position - viewport_size * 0.5) / (viewport_size * 0.5)
	cursor_ratio.x = clampf(cursor_ratio.x, -1.0, 1.0)
	cursor_ratio.y = clampf(cursor_ratio.y, -1.0, 1.0)
	return camera_base_offset + cursor_ratio * camera_max_cursor_offset

func _physics_process(delta: float) -> void:
	var weight := 1.0 - exp(-camera_smoothing * delta) if camera_smoothing > 0.0 else 1.0
	
	camera.position = camera.position.lerp(_camera_target_position, weight)
	
	if camera.position.distance_squared_to(_camera_target_position) < 0.01:
		camera.position = _camera_target_position
		
	if not is_alive():
		velocity = Vector2.ZERO
		_knockback = Vector2.ZERO
		return
		
	var can_control := not locks.is_locked()
		
	var speed_multiplier := status.get_multiplier(&"move_speed")
	
	if inventory_open:
		speed_multiplier *= 0.35
		
	var axis := Input.get_axis(&"move_left", &"move_right") if can_control else 0.0
	var target_speed := axis * move_speed * speed_multiplier
	var rate := acceleration if axis != 0.0 else deceleration
	
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)
	
	if not is_on_floor():
		velocity.y += gravity * status.get_multiplier(&"gravity") * delta
		_last_air_speed = maxf(_last_air_speed, velocity.y)
	elif _last_air_speed > fall_damage_speed:
		var fall_damage := minf((_last_air_speed - fall_damage_speed) * 0.2, maximum_fall_damage)
		apply_damage(DamageInfo.new(fall_damage))
		_last_air_speed = 0.0
	if can_control and Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = jump_velocity
		
	velocity += _knockback
	_knockback = Vector2.ZERO
	
	move_and_slide()
	_update_animation()
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not is_alive():
		return
	if event.is_action_pressed(&"attack"):
		attack()
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

func set_inventory_open(open: bool) -> void:
	if inventory_open == open:
		return
	inventory_open = open
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
	camera.limit_left = floori(bounds.position.x)
	camera.limit_top = floori(bounds.position.y)
	camera.limit_right = ceili(bounds.end.x)
	camera.limit_bottom = ceili(bounds.end.y)
	camera.limit_smoothed = true

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

func _update_prompt() -> void:
	var target := interaction_sensor.best_target()
	var text := ""
	if target != null and target.has_method("get_interaction_prompt"):
		text = target.get_interaction_prompt(self)
	prompt_changed.emit(text)

func _on_died(_source: Node) -> void:
	locks.lock(&"death")
