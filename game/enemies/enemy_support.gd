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
@export var hit_flash_duration := 0.15

var health: HealthComponent
var status: StatusController
var effect_label: Label
var hit_flash: HitFlash
var _flight_fall_speed := 0.0
var _was_airborne_during_disabled_flight := false
var _label_refresh_elapsed := 0.0

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
	hit_flash = HitFlash.new()
	add_child(hit_flash)
	hit_flash.setup(actor)
	if actor != null:
		if actor is Node2D:
			effect_label = Label.new()
			effect_label.name = "EnemyEffects"
			effect_label.position = Vector2(-70.0, -24.0)
			effect_label.size = Vector2(140.0, 24.0)
			effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			effect_label.z_index = 20
			effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			effect_label.add_theme_font_size_override("font_size", 8)
			effect_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 1.0))
			effect_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
			effect_label.add_theme_constant_override("outline_size", 3)
			actor.call_deferred(&"add_child", effect_label)
		if register_persistence:
			actor.add_to_group(&"persistent_objects")
		actor.add_to_group(&"effect_receivers")
		for tag in tags:
			actor.add_to_group(tag)
	health.damaged.connect(_on_damaged)
	health.health_changed.connect(func(_current: float, _maximum: float): _refresh_effect_label())
	health.died.connect(_on_died)
	status.tick_damage_requested.connect(_on_status_damage)
	status.tick_healing_requested.connect(func(amount: float): health.heal(amount))
	status.status_changed.connect(_refresh_effect_label)
	_refresh_effect_label()

func _process(delta: float) -> void:
	_label_refresh_elapsed += delta
	if _label_refresh_elapsed < 0.25:
		return
	_label_refresh_elapsed = 0.0
	if GameSession.is_debug_draw_enabled(&"enemy_labels") or not status.active.is_empty() or (effect_label != null and effect_label.visible):
		_refresh_effect_label()

func _refresh_effect_label() -> void:
	if effect_label == null or status == null:
		return
	var lines := PackedStringArray()
	if GameSession.is_debug_draw_enabled(&"enemy_labels"):
		lines.append("%d/%d" % [int(health.health), int(health.max_health)])
	for id: StringName in status.active:
		var definition := ContentCatalog.get_effect(id)
		var name := definition.display_name if definition != null else String(id)
		var stacks := status.get_stack_count(id)
		var stack_text := " x%d" % stacks if stacks > 1 else ""
		lines.append("%s%s %ds" % [name, stack_text, ceili(status.get_remaining(id))])
	effect_label.text = "\n".join(lines)
	effect_label.visible = not lines.is_empty()

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
		_was_airborne_during_disabled_flight = false
		return false
	if actor.is_on_floor():
		actor.velocity.y = 0.0
		actor.move_and_slide()
		_flight_fall_speed = 0.0
		_was_airborne_during_disabled_flight = false
		return true
	_was_airborne_during_disabled_flight = true
	actor.velocity.x = move_toward(actor.velocity.x, 0.0, gravity * delta)
	actor.velocity.y += gravity * delta
	_flight_fall_speed = maxf(_flight_fall_speed, actor.velocity.y)
	actor.move_and_slide()
	if actor.is_on_floor() and _was_airborne_during_disabled_flight and _flight_fall_speed > 0.0:
		var info := DamageInfo.new(fall_damage)
		info.tags = [&"fall"]
		if not fall_immune: health.apply_damage(info, species_id)
		_flight_fall_speed = 0.0
		_was_airborne_during_disabled_flight = false
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

func _on_damaged(_info: DamageInfo) -> void:
	hit_flash.play(1, hit_flash_duration)

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
