class_name SkyHunter
extends CharacterBody2D

enum State { ROAM, CHASE, TELEGRAPH, ATTACK, RECOVER }

@export var member_id := ""
@export var roam_speed := 70.0
@export var chase_speed := 105.0
@export var attack_speed := 260.0
@export var attack_telegraph_duration := 0.7
@export var attack_duration := 0.7
@export var attack_damage := 25.0
@export var attack_force := 160.0
@export var recovery_duration := 1.5
@export var preferred_member_separation := 44.0
@export var preferred_flyer_separation := 180.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener

var state := State.ROAM
var coordinator: AttackGroupCoordinator
var flock: Node
var _origin := Vector2.ZERO
var _target: Node2D
var _aim := Vector2.ZERO
var _timer := 0.0
var _hit := false

func _ready() -> void:
	_origin = global_position
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(_on_lost)
	sound.sound_accepted.connect(_on_sound)
	support.health.died.connect(func(_source: Node):
		if flock != null and flock.has_method("notify_member_died"):
			flock.notify_member_died(member_id))

func setup(owner_flock: Node, shared_coordinator: AttackGroupCoordinator, stable_id: String) -> void:
	flock = owner_flock
	coordinator = shared_coordinator
	member_id = stable_id
	_origin = global_position

func _physics_process(delta: float) -> void:
	if support.process_disabled_flight(self, delta):
		_release_attack()
		_target = null
		state = State.ROAM
		return
	_timer = maxf(0.0, _timer - delta)
	match state:
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if _timer <= 0.0:
				state = State.ATTACK
				_timer = attack_duration
				_hit = false
				velocity = global_position.direction_to(_aim) * attack_speed
		State.ATTACK:
			if not _hit:
				_try_hit()
			if _timer <= 0.0:
				_recover()
		State.RECOVER:
			velocity = global_position.direction_to(_origin) * roam_speed
			if _timer <= 0.0:
				state = State.CHASE if is_instance_valid(_target) else State.ROAM
		_:
			_update_flight()
	move_and_slide()
	if state == State.ATTACK and get_slide_collision_count() > 0:
		_recover()
	sight.facing = velocity.normalized() if not velocity.is_zero_approx() else sight.facing

func _update_flight() -> void:
	if is_instance_valid(_target):
		state = State.CHASE
		if coordinator != null:
			coordinator.broadcast_alert(_target.global_position, 4.0)
		velocity = global_position.direction_to(_target.global_position) * chase_speed
		velocity += _separation_velocity()
		if coordinator == null or coordinator.request_attack(self):
			state = State.TELEGRAPH
			_aim = _target.global_position
			_timer = attack_telegraph_duration
			if _target.has_method("warn_attack"):
				_target.warn_attack(self, attack_telegraph_duration)
	else:
		state = State.ROAM
		var destination := coordinator.alert_position if coordinator != null and coordinator.has_alert() else _origin
		velocity = global_position.direction_to(destination) * roam_speed + _separation_velocity()

func _separation_velocity() -> Vector2:
	var result := Vector2.ZERO
	if flock == null:
		return result
	for sibling in flock.get_children():
		if sibling is SkyHunter and sibling != self:
			var distance := global_position.distance_to(sibling.global_position)
			if distance > 0.0 and distance < preferred_member_separation:
				result += sibling.global_position.direction_to(global_position) * (preferred_member_separation - distance)
	for flyer in get_tree().get_nodes_in_group(&"large_flyer"):
		if not flyer is Node2D or not is_instance_valid(flyer) or not flyer.is_inside_tree():
			continue
		var distance := global_position.distance_to(flyer.global_position)
		if distance > 0.0 and distance < preferred_flyer_separation:
			result += flyer.global_position.direction_to(global_position) * (preferred_flyer_separation - distance)
	return result

func _try_hit() -> void:
	if not is_instance_valid(_target) or global_position.distance_to(_target.global_position) > 34.0:
		return
	var impact := ImpactData.new()
	impact.source_actor = self
	impact.source_species_id = support.species_id
	impact.base_damage = attack_damage
	impact.damage_multiplier_min = 1.0
	impact.damage_multiplier_max = 1.0
	impact.force = velocity.normalized() * attack_force
	impact.attack_kind = &"sky_hunter_strike"
	impact.apply_to(_target)
	_hit = true

func _recover() -> void:
	_release_attack()
	state = State.RECOVER
	_timer = recovery_duration
	_target = null

func _release_attack() -> void:
	if coordinator != null:
		coordinator.release_attack(self)

func _on_seen(target: Node2D, position: Vector2) -> void:
	if not support.detectors_enabled():
		return
	_target = target
	if coordinator != null:
		coordinator.broadcast_alert(position, 4.0)

func _on_lost(_target_lost: Node2D) -> void:
	if state not in [State.TELEGRAPH, State.ATTACK]:
		_target = null

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if state in [State.TELEGRAPH, State.ATTACK] or not support.detectors_enabled():
		return
	if coordinator != null:
		coordinator.broadcast_alert(event.position, 3.0)

func interrupt_action(_reason: StringName) -> bool:
	if state not in [State.TELEGRAPH, State.ATTACK]:
		return false
	_recover()
	return true

func request_interrupt(strength: float, reason: StringName = &"impact") -> bool: return support.request_interrupt(strength, reason)
func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		_origin = global_position
		state = State.ROAM
		_target = null
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
