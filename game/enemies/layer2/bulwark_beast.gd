class_name BulwarkBeast
extends CharacterBody2D

enum State { PATROL, TELEGRAPH, CHARGE, RECOVER }

@export var persistent_id := ""
@export var patrol_radius := 120.0
@export var gravity := 900.0
@export var patrol_speed := 28.0
@export var charge_telegraph_duration := 1.0
@export var charge_speed := 300.0
@export var maximum_charge_duration := 2.5
@export var charge_damage := 50.0
@export var charge_force := 420.0
@export var player_incapacitation_duration := 1.0
@export var natural_deceleration := 85.0
@export var collision_recovery_duration := 2.0
@export var resin_deceleration_multiplier := 2.0
@export var strong_sound_priority := 8

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener

var state := State.PATROL
var _origin := Vector2.ZERO
var _target: Node2D
var _timer := 0.0
var _charge_direction := Vector2.RIGHT
var _hit_ids: Dictionary = {}

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	sight.target_seen.connect(_on_seen)
	sound.sound_accepted.connect(_on_sound)
	support.health.damaged.connect(_on_damaged)

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	if not is_on_floor():
		velocity.y += gravity * delta
	if support.status.has_status(&"electro_stunned"):
		velocity.x = move_toward(velocity.x, 0.0, natural_deceleration * delta)
		move_and_slide()
		return
	match state:
		State.TELEGRAPH:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.CHARGE
				_timer = maximum_charge_duration
				_hit_ids.clear()
				velocity.x = _charge_direction.x * charge_speed
		State.CHARGE:
			var deceleration := natural_deceleration
			if support.status.has_status(&"resin_bound"):
				deceleration *= resin_deceleration_multiplier
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
			if _timer <= 0.0 or absf(velocity.x) < patrol_speed:
				_begin_recovery()
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, natural_deceleration * 3.0 * delta)
			if _timer <= 0.0:
				state = State.PATROL
		State.PATROL:
			var left := _origin.x - patrol_radius
			var right := _origin.x + patrol_radius
			velocity.x = patrol_speed if global_position.x <= left else -patrol_speed if global_position.x >= right else velocity.x
			if is_zero_approx(velocity.x):
				velocity.x = patrol_speed
	move_and_slide()
	if state == State.CHARGE:
		_handle_charge_collisions()
	sight.facing = Vector2(signf(velocity.x), 0.0) if absf(velocity.x) > 1.0 else sight.facing

func _begin_telegraph(position: Vector2) -> void:
	if state != State.PATROL:
		return
	_charge_direction = Vector2(signf(position.x - global_position.x), 0.0)
	if is_zero_approx(_charge_direction.x):
		_charge_direction = Vector2.RIGHT
	state = State.TELEGRAPH
	_timer = charge_telegraph_duration
	if is_instance_valid(_target) and _target.has_method("warn_attack"):
		_target.warn_attack(self, charge_telegraph_duration)

func _handle_charge_collisions() -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var body := collision.get_collider() as Node
		if body == null or body == self:
			continue
		if body is StaticBody2D or body is TileMapLayer:
			_begin_recovery()
			return
		var id := body.get_instance_id()
		if _hit_ids.has(id):
			continue
		_hit_ids[id] = true
		var impact := ImpactData.new()
		impact.source_actor = self
		impact.source_species_id = support.species_id
		impact.base_damage = charge_damage
		impact.damage_multiplier_min = 1.0
		impact.damage_multiplier_max = 1.0
		impact.force = _charge_direction * charge_force
		impact.attack_kind = &"bulwark_charge"
		impact.status_effects = [{"effect_id": &"incapacitated", "duration": player_incapacitation_duration}]
		impact.apply_to(body)

func _begin_recovery() -> void:
	state = State.RECOVER
	_timer = collision_recovery_duration

func _on_seen(target: Node2D, position: Vector2) -> void:
	if not support.detectors_enabled():
		return
	_target = target
	_begin_telegraph(position)

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if support.detectors_enabled() and event.priority >= strong_sound_priority:
		_begin_telegraph(event.position)

func _on_damaged(info: DamageInfo) -> void:
	if info.source is Node2D:
		_target = info.source as Node2D
		_begin_telegraph(_target.global_position)

func interrupt_action(reason: StringName) -> bool:
	if state == State.CHARGE and reason != &"electric":
		return false
	if state not in [State.TELEGRAPH, State.CHARGE]:
		return false
	_begin_recovery()
	return true

func request_interrupt(strength: float, reason: StringName = &"impact") -> bool: return support.request_interrupt(strength, reason)
func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void:
	if state != State.CHARGE:
		velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		state = State.PATROL
		_target = null
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
