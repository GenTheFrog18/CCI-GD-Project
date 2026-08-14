class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal damaged(info: DamageInfo)
signal died(source: Node)

@export var max_health := 100.0
@export var killable := true
@export var invulnerability_seconds := 0.2

var health := 100.0
var is_dead := false
var _invulnerable_until := 0

func _ready() -> void:
	health = max_health

func apply_damage(info: DamageInfo, receiver_species_id: StringName = &"") -> bool:
	if is_dead or info.amount <= 0.0:
		return false
	if not receiver_species_id.is_empty() and receiver_species_id == info.source_species_id:
		return false
	if not info.bypass_invulnerability and Time.get_ticks_msec() < _invulnerable_until:
		return false
	health = maxf(0.0, health - info.amount)
	if not info.bypass_invulnerability:
		_invulnerable_until = Time.get_ticks_msec() + int(invulnerability_seconds * 1000.0)
	damaged.emit(info)
	health_changed.emit(health, max_health)
	if health == 0.0 and killable:
		is_dead = true
		died.emit(info.source)
	return true

func heal(amount: float, multiplier := 1.0, health_cap := INF) -> float:
	if is_dead or amount <= 0.0:
		return 0.0
	var before := health
	var cap := minf(max_health, health_cap)
	if health >= cap:
		return 0.0
	health = minf(health + amount * multiplier, cap)
	if health != before:
		health_changed.emit(health, max_health)
	return health - before

func set_health(value: float) -> void:
	var was_dead := is_dead
	health = clampf(value, 0.0, max_health)
	is_dead = health == 0.0 and killable
	health_changed.emit(health, max_health)
	if is_dead and not was_dead:
		died.emit(null)

func capture_state() -> Dictionary:
	return {"health": health, "is_dead": is_dead}

func restore_state(data: Dictionary) -> void:
	health = clampf(float(data.get("health", max_health)), 0.0, max_health)
	is_dead = bool(data.get("is_dead", false))
	health_changed.emit(health, max_health)
