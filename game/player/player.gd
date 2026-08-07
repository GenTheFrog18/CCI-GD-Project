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
@export var species_id: StringName = &"player"
@export var persistent_id := "player"

@onready var health: HealthComponent = $HealthComponent
@onready var status: StatusController = $StatusController
@onready var item_controller: PlayerItemController = $PlayerItemController
@onready var interaction_sensor: InteractionSensor = $InteractionSensor

var locks := ControlLocks.new()
var inventory_open := false
var last_safe_position := Vector2(96.0, 260.0)
var _last_air_speed := 0.0
var _knockback := Vector2.ZERO

func _ready() -> void:
	add_to_group(&"persistent_objects")
	status.tick_damage_requested.connect(func(amount: float): apply_damage(DamageInfo.new(amount)))
	health.died.connect(_on_died)
	if ContentCatalog.get_item(&"multitool") != null and item_controller.inventory.get_active_stack().is_empty():
		item_controller.inventory.try_add_item(&"multitool")

func _physics_process(delta: float) -> void:
	if global_position.y > 1900.0:
		global_position = Vector2(96.0, 260.0)
		health.set_health(1.0)
		velocity = Vector2.ZERO
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
	if is_on_floor() and global_position.y < 1900.0:
		last_safe_position = global_position
	if can_control and Input.is_action_just_pressed(&"jump") and is_on_floor():
		velocity.y = jump_velocity
	velocity += _knockback
	_knockback = _knockback.move_toward(Vector2.ZERO, 800.0 * delta)
	move_and_slide()
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"inventory"):
		inventory_open = not inventory_open
		inventory_toggled.emit(inventory_open)
		get_viewport().set_input_as_handled()
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

func try_pickup_item(item_id: StringName, quantity: int, state: Dictionary) -> bool:
	return item_controller.inventory.try_add_item(item_id, quantity, state)

func drop_inventory_slot(container: StringName, index: int) -> bool:
	var stack := item_controller.inventory.take_one(container, index)
	if stack.is_empty():
		return false
	var world_item := preload("res://game/items/world/world_item.tscn").instantiate() as WorldItem
	world_item.item_id = stack.item_id
	world_item.quantity = 1
	world_item.instance_state = stack.state
	get_parent().add_child(world_item)
	world_item.global_position = global_position + Vector2(20.0, -4.0)
	return true

func apply_damage(info: DamageInfo) -> bool:
	return health.apply_damage(info, species_id)

func apply_force(force: Vector2) -> void:
	_knockback += force

func apply_status(effect_id: StringName, data: Dictionary = {}) -> bool:
	return status.apply_status(effect_id, data)

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
	if not candidate.is_finite() or candidate.y > 1900.0:
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
