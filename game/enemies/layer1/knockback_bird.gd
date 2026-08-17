class_name KnockbackBird
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }

@export var persistent_id := "knockback_bird"
@export var flight_radius := 130.0
@export var flight_speed := 70.0
@export var swoop_speed := 240.0
@export var nest_trigger_radius := 170.0
@export var telegraph_seconds := 0.6
@export var attack_cooldown := 2.0
@export var knockback := 260.0
@export var threshold_damage := 10.0
@export var patrol_bounds := Rect2()

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
var state := State.IDLE
var _nest := Vector2.ZERO
var _target: PlayerController
var _aim := Vector2.ZERO
var _timer := 0.0

func _ready() -> void:
	support.persistent_id = persistent_id
	_nest = global_position
	sight.target_seen.connect(_on_target_seen)
	support.health.damaged.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	if support.process_disabled_flight(self, delta):
		_target = null
		state = State.MOVE
		return
	_timer = maxf(0.0, _timer - delta)
	if _target != null and _nest.distance_to(_target.global_position) <= nest_trigger_radius:
		if state == State.ATTACK:
			velocity = Vector2.ZERO if _timer > 0.0 else global_position.direction_to(_aim) * swoop_speed * support.status.get_multiplier(&"flight_speed")
			if global_position.distance_to(_target.global_position) < 22.0:
				var direction := global_position.direction_to(_target.global_position)
				_target.apply_force(Vector2(direction.x * knockback * 0.7, -knockback * 0.3))
				_target.register_bird_hit(2.0, 2, threshold_damage)
				_recover()
		elif _timer <= 0.0:
			state = State.ATTACK
			_aim = _target.global_position
			_timer = telegraph_seconds
			_target.warn_attack(self, telegraph_seconds)
		else:
			velocity = global_position.direction_to(_nest) * flight_speed
	else:
		state = State.MOVE
		var phase := Time.get_ticks_msec() / 1400.0 + get_instance_id()
		var orbit := _nest + Vector2.from_angle(phase) * flight_radius
		if patrol_bounds.has_area():
			orbit = _nest + patrol_bounds.get_center() + Vector2(cos(phase) * patrol_bounds.size.x, sin(phase) * patrol_bounds.size.y) * 0.5
		velocity = global_position.direction_to(orbit) * flight_speed * support.status.get_multiplier(&"flight_speed")
	move_and_slide()
	sight.facing = velocity.normalized()

func _recover() -> void:
	state = State.MOVE
	_timer = attack_cooldown
	velocity = global_position.direction_to(_nest) * flight_speed

func _on_target_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController:
		_target = target

func _on_damaged(_info: DamageInfo) -> void:
	if state == State.ATTACK:
		_recover()

func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(_force: Vector2) -> void: pass
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data): global_position = _nest; state = State.IDLE
func handle_world_out_of_bounds() -> void: global_position = _nest; velocity = Vector2.ZERO
