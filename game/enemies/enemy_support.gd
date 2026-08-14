class_name EnemySupport
extends Node

@export var persistent_id := ""
@export var species_id: StringName
@export var max_health := 20.0
@export var tags: Array[StringName] = []
@export var fall_damage := 100.0
@export var fall_immune := false

var health: HealthComponent
var status: StatusController

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
