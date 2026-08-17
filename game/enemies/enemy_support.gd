class_name EnemySupport
extends Node

@export var persistent_id := ""
@export var species_id: StringName
@export var max_health := 20.0
@export var tags: Array[StringName] = []
@export var fall_damage := 100.0
@export var fall_immune := false
@export var register_persistence := true
@export var interrupt_resistance := 0.0
@export var electric_stun_duration_multiplier := 1.0
@export var detector_suppression_duration_multiplier := 1.0

var health: HealthComponent
var status: StatusController
var _flight_fall_speed := 0.0

func _ready() -> void:
	var definition := ContentCatalog.get_enemy(species_id)
	if definition != null:
		max_health = definition.max_health
		tags = definition.tags.duplicate()
	health = HealthComponent.new()
	health.max_health = max_health
	add_child(health)
	status = StatusController.new()
	add_child(status)
	var actor := get_parent()
	if actor != null:
		if register_persistence:
			actor.add_to_group(&"persistent_objects")
		actor.add_to_group(&"effect_receivers")
		for tag in tags:
			actor.add_to_group(tag)
	health.damaged.connect(_on_damaged)
	health.died.connect(_on_died)
	status.tick_damage_requested.connect(_on_status_damage)
	status.tick_healing_requested.connect(func(amount: float): health.heal(amount))

func apply_damage(info: DamageInfo) -> bool:
	return health.apply_damage(info, species_id)

func apply_force(force: Vector2) -> Vector2:
	return force * status.get_multiplier(&"knockback_received")

func apply_status(effect_id: StringName, data: Dictionary = {}) -> bool:
	if get_parent().is_in_group(&"flying") and effect_id in [&"spider_slow", &"resin_bound"]:
		return false
	return status.apply_status(effect_id, data)

func detectors_enabled() -> bool:
	return not status.has_status(&"detector_suppressed")

func apply_detector_suppression(duration: float) -> bool:
	return status.apply_status(&"detector_suppressed", {"duration": duration * detector_suppression_duration_multiplier})

func apply_electric_effects(stun_duration: float, suppression_duration: float, shock_duration: float) -> bool:
	var applied := status.apply_status(&"electrocuted", {"duration": shock_duration})
	status.apply_status(&"electro_stunned", {"duration": stun_duration * electric_stun_duration_multiplier})
	apply_detector_suppression(suppression_duration)
	request_interrupt(INF, &"electric")
	return applied

func request_interrupt(strength: float, reason: StringName = &"impact") -> bool:
	if strength < interrupt_resistance:
		return false
	var actor := get_parent()
	return bool(actor.interrupt_action(reason)) if actor != null and actor.has_method("interrupt_action") else false

func process_disabled_flight(actor: CharacterBody2D, delta: float, gravity := 900.0) -> bool:
	if actor == null or not actor.is_in_group(&"flying") or not status.has_status(&"electro_stunned"):
		_flight_fall_speed = 0.0
		return false
	actor.velocity.x = move_toward(actor.velocity.x, 0.0, gravity * delta)
	actor.velocity.y += gravity * delta
	_flight_fall_speed = maxf(_flight_fall_speed, actor.velocity.y)
	actor.move_and_slide()
	if actor.is_on_floor() and _flight_fall_speed > 0.0:
		var info := DamageInfo.new(fall_damage)
		info.tags = [&"fall"]
		health.apply_damage(info, species_id)
		_flight_fall_speed = 0.0
	return true

func capture_state() -> Dictionary:
	var actor := get_parent() as Node2D
	return {
		"alive": not health.is_dead,
		"health": health.capture_state(),
		"status": status.capture_state(),
		"position": [actor.global_position.x, actor.global_position.y] if actor != null else [0.0, 0.0],
	}

func restore_state(data: Dictionary) -> bool:
	if not bool(data.get("alive", true)):
		get_parent().queue_free()
		return false
	health.restore_state(data.get("health", {}))
	status.restore_state(data.get("status", {}))
	var position_data: Array = data.get("position", [])
	var actor := get_parent() as Node2D
	if actor != null and position_data.size() == 2:
		actor.global_position = Vector2(float(position_data[0]), float(position_data[1]))
	return true

func _on_damaged(info: DamageInfo) -> void:
	if not info.causes_hit_reaction:
		return
	var actor := get_parent() as CanvasItem
	if actor != null:
		actor.modulate = Color(1.0, 0.55, 0.55, 1.0)
		actor.create_tween().tween_property(actor, "modulate", Color(1, 1, 1, 1), 0.12)

func _on_status_damage(amount: float) -> void:
	var info := DamageInfo.new(amount)
	info.bypass_invulnerability = true
	info.causes_hit_reaction = false
	info.tags = [&"status_tick"]
	health.apply_damage(info, species_id)

func _on_died(_source: Node) -> void:
	if not persistent_id.is_empty():
		SaveManager.mark_destroyed(persistent_id)
	get_parent().queue_free()
