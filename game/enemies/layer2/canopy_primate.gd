class_name CanopyPrimate
extends CharacterBody2D

enum State { ROAM, AIM, RECOVER }

@export var persistent_id := ""
@export var spawn_group_id: StringName
@export var patrol_bounds := Rect2(-120, -20, 240, 40)
@export var gravity := 900.0
@export var jump_speed := 210.0
@export var move_speed := 80.0
@export var preferred_distance_min := 90.0
@export var attack_range := 260.0
@export var aim_duration := 0.8
@export var attack_cooldown := 2.2
@export var group_alert_duration := 4.0
@export var projectile_speed := 220.0
@export var rock_damage := 5.0
@export var rock_force := 180.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor

var state := State.ROAM
var _origin := Vector2.ZERO
var _target: Node2D
var _aim := Vector2.ZERO
var _timer := 0.0
var _hop_timer := 0.0
var _coordinator: AttackGroupCoordinator

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	if spawn_group_id.is_empty(): spawn_group_id = StringName(persistent_id)
	_coordinator = AttackGroupCoordinator.find_or_create(get_parent(), spawn_group_id, 1, 0.8)
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(func(_lost: Node2D): _target = null)

func _physics_process(delta: float) -> void:
	if support.status.has_status(&"electro_stunned"):
		velocity.x = move_toward(velocity.x, 0.0, gravity * delta)
		velocity.y += gravity * delta
		move_and_slide()
		return
	_timer = maxf(0.0, _timer - delta)
	_hop_timer = maxf(0.0, _hop_timer - delta)
	if not is_on_floor(): velocity.y += gravity * delta
	if state == State.AIM:
		velocity.x = move_toward(velocity.x, 0.0, gravity * delta)
		if _timer <= 0.0:
			_fire()
	elif state == State.RECOVER:
		if _timer <= 0.0: state = State.ROAM
	else:
		var destination := _origin
		if is_instance_valid(_target) and sight.can_see(_target):
			_coordinator.broadcast_alert(_target.global_position, group_alert_duration)
			var distance := global_position.distance_to(_target.global_position)
			if distance <= attack_range and _timer <= 0.0 and _coordinator.request_attack(self):
				state = State.AIM
				_aim = _target.global_position
				_timer = aim_duration
				if _target.has_method("warn_attack"): _target.warn_attack(self, aim_duration)
			else:
				destination = global_position - global_position.direction_to(_target.global_position) * 90.0 if distance < preferred_distance_min else _target.global_position
		elif _coordinator.has_alert():
			destination = _coordinator.alert_position
		if is_on_floor() and _hop_timer <= 0.0:
			var direction := signf(destination.x - global_position.x)
			if is_zero_approx(direction): direction = -1.0 if randf() < 0.5 else 1.0
			velocity = Vector2(direction * move_speed, -jump_speed)
			_hop_timer = 0.9
	move_and_slide()
	sight.facing = Vector2(signf(velocity.x), 0.0) if absf(velocity.x) > 1.0 else sight.facing

func _on_seen(target: Node2D, position: Vector2) -> void:
	if support.detectors_enabled():
		_target = target
		_coordinator.broadcast_alert(position, group_alert_duration)

func _fire() -> void:
	var projectile := preload("res://game/projectiles/projectile.tscn").instantiate() as Projectile
	var impact := ImpactData.new()
	impact.source_actor = self
	impact.source_species_id = support.species_id
	impact.base_damage = rock_damage
	impact.mass = 1.0
	impact.attack_kind = &"primate_rock"
	impact.force = global_position.direction_to(_aim) * rock_force
	projectile.configure(impact, global_position.direction_to(_aim) * projectile_speed)
	projectile.gravity_scale = 1.0
	get_parent().add_child(projectile)
	projectile.global_position = global_position + Vector2(0, -12)
	_coordinator.release_attack(self)
	state = State.RECOVER
	_timer = attack_cooldown

func interrupt_action(_reason: StringName) -> bool:
	if state != State.AIM: return false
	_coordinator.release_attack(self)
	state = State.RECOVER
	_timer = attack_cooldown
	return true

func request_interrupt(strength: float, reason: StringName = &"impact") -> bool: return support.request_interrupt(strength, reason)
func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary:
	var data := support.capture_state(); data["spawn_group_id"] = String(spawn_group_id); return data
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data): state = State.ROAM; _target = null
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
