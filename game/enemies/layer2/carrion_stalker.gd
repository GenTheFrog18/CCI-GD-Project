class_name CarrionStalker
extends CharacterBody2D

enum State { ROAM, SHADOW, PREPARE, BITE, RETREAT }

@export var persistent_id := ""
@export var patrol_radius := 140.0
@export var gravity := 900.0
@export var patrol_speed := 36.0
@export var shadow_speed := 62.0
@export var bite_speed := 185.0
@export var prey_scan_interval := 0.5
@export var prey_scan_radius := 230.0
@export var target_switch_score_margin := 20.0
@export var minimum_target_commitment_time := 2.0
@export var bleeding_score_bonus := 100.0
@export var critical_health_threshold := 0.5
@export var critical_health_score_bonus := 70.0
@export var poison_score_bonus := 45.0
@export var bite_prepare_duration := 0.45
@export var bite_duration := 0.35
@export var bite_damage := 8.0
@export var bite_force := 70.0
@export var bite_bleed_duration := 8.0
@export var retreat_duration := 1.2

@onready var support: EnemySupport = $EnemySupport

var state := State.ROAM
var _origin := Vector2.ZERO
var _target: Node2D
var _target_score := -INF
var _scan_remaining := 0.0
var _commitment_remaining := 0.0
var _timer := 0.0
var _attack_direction := Vector2.RIGHT
var _hit_target := false

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	support.health.damaged.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	if support.status.has_status(&"electro_stunned"):
		velocity.x = 0.0
		velocity.y += gravity * delta
		move_and_slide()
		return
	_timer = maxf(0.0, _timer - delta)
	_scan_remaining -= delta
	_commitment_remaining = maxf(0.0, _commitment_remaining - delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	if _scan_remaining <= 0.0:
		_scan_remaining = prey_scan_interval
		_scan_prey()
	match state:
		State.PREPARE:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.BITE
				_timer = bite_duration
				_hit_target = false
				velocity.x = _attack_direction.x * bite_speed
		State.BITE:
			if not _hit_target:
				_try_bite()
			if _timer <= 0.0:
				_begin_retreat()
		State.RETREAT:
			velocity.x = -_attack_direction.x * shadow_speed
			if _timer <= 0.0:
				state = State.SHADOW if is_instance_valid(_target) else State.ROAM
		_:
			_move_and_consider_attack()
	move_and_slide()

func _scan_prey() -> void:
	var best: Node2D
	var best_score := -INF
	for candidate in get_tree().get_nodes_in_group(&"effect_receivers"):
		if candidate is not Node2D or candidate == self or not candidate.is_inside_tree():
			continue
		var actor := candidate as Node2D
		if actor.has_method("is_combat_protected") and actor.is_combat_protected():
			continue
		var actor_support := actor.get_node_or_null("EnemySupport") as EnemySupport
		if actor_support != null and actor_support.species_id == support.species_id:
			continue
		var distance := global_position.distance_to(actor.global_position)
		if distance > prey_scan_radius:
			continue
		var score := _prey_score(actor, actor_support, distance)
		if score > best_score:
			best = actor
			best_score = score
	if best == null:
		_target = null
		_target_score = -INF
		if state in [State.SHADOW, State.ROAM]:
			state = State.ROAM
	elif _target == null or _commitment_remaining <= 0.0 and best_score >= _target_score + target_switch_score_margin:
		_target = best
		_target_score = best_score
		_commitment_remaining = minimum_target_commitment_time
		if state == State.ROAM:
			state = State.SHADOW

func _prey_score(actor: Node2D, actor_support: EnemySupport, distance: float) -> float:
	var actor_status: StatusController = actor_support.status if actor_support != null else actor.status if actor is PlayerController else null
	var actor_health: HealthComponent = actor_support.health if actor_support != null else actor.health if actor is PlayerController else null
	if actor_status == null or actor_health == null or actor_health.is_dead:
		return -INF
	var score := -distance * 0.2
	if actor_status.has_status(&"bleed"):
		score += bleeding_score_bonus
	if actor_status.has_status(&"poison"):
		score += poison_score_bonus
	var ratio := actor_health.health / maxf(actor_health.max_health, 1.0)
	if ratio < critical_health_threshold:
		score += critical_health_score_bonus * (1.0 - ratio)
	# Healthy prey is not valid until it attacks the Stalker.
	return score if score > 0.0 or actor == _target else -INF

func _move_and_consider_attack() -> void:
	if not is_instance_valid(_target):
		var left := _origin.x - patrol_radius
		var right := _origin.x + patrol_radius
		velocity.x = patrol_speed if global_position.x <= left else -patrol_speed if global_position.x >= right else velocity.x
		if is_zero_approx(velocity.x):
			velocity.x = patrol_speed
		return
	var offset := _target.global_position - global_position
	velocity.x = signf(offset.x) * shadow_speed
	if offset.length() <= 48.0:
		state = State.PREPARE
		_attack_direction = offset.normalized()
		_timer = bite_prepare_duration
		if _target.has_method("warn_attack"):
			_target.warn_attack(self, bite_prepare_duration)

func _try_bite() -> void:
	if not is_instance_valid(_target) or global_position.distance_to(_target.global_position) > 42.0:
		return
	var impact := ImpactData.new()
	impact.source_actor = self
	impact.source_species_id = support.species_id
	impact.base_damage = bite_damage
	impact.damage_multiplier_min = 1.0
	impact.damage_multiplier_max = 1.0
	impact.force = _attack_direction * bite_force
	impact.attack_kind = &"stalker_bite"
	impact.status_effects = [{"effect_id": &"bleed", "duration": bite_bleed_duration}]
	impact.apply_to(_target)
	_hit_target = true

func _begin_retreat() -> void:
	state = State.RETREAT
	_timer = retreat_duration

func _on_damaged(info: DamageInfo) -> void:
	if info.source is Node2D and info.source != self:
		_target = info.source as Node2D
		_target_score = 0.0
		_commitment_remaining = minimum_target_commitment_time
		if state == State.ROAM:
			state = State.SHADOW

func interrupt_action(_reason: StringName) -> bool:
	if state != State.PREPARE:
		return false
	_begin_retreat()
	return true

func request_interrupt(strength: float, reason: StringName = &"impact") -> bool: return support.request_interrupt(strength, reason)
func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		state = State.ROAM
		_target = null
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
