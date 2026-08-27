class_name KnockbackBird
extends CharacterBody2D

const FLY_SHEET := preload("res://assets/art/enemies/knockback_bird/knockback_bird_fly_and_dive.png")

enum State { PATROL, ALERT_WAIT, TELEGRAPH, SWOOP, RECOVERY }

@export var persistent_id := "knockback_bird"
@export var spawn_group_id: StringName
@export var nest_position := Vector2.ZERO
@export_range(1.0, 1000.0, 1.0) var patrol_radius := 160.0
@export var flight_radius := 130.0
@export var flight_speed := 70.0
@export var patrol_destination_refresh_min := 1.5
@export var patrol_destination_refresh_max := 2.5
@export var patrol_min_distance := 50.0
@export var patrol_max_distance := 120.0
@export_range(0.0, 180.0, 1.0) var patrol_direction_variance_degrees := 60.0
@export_range(0.0, 1.0, 0.01) var patrol_steering_strength := 0.04
@export var max_destination_attempts := 10
@export_flags_2d_physics var flight_blocking_collision_mask := 1
@export var nest_trigger_radius := 170.0
@export var telegraph_duration := 0.6
@export var swoop_speed := 240.0
@export var swoop_max_duration := 0.8
@export var recovery_duration := 0.8
@export var recovery_distance_min := 90.0
@export var recovery_distance_max := 130.0
@export_range(0.0, 180.0, 1.0) var recovery_angle_variance_degrees := 25.0
@export var attack_cooldown := 2.0
@export var attack_group_maximum := 0
@export var attack_group_spacing := 0.8
@export var knockback_strength := 260.0
@export_range(0.0, 1.0) var horizontal_force_ratio := 0.7
@export_range(0.0, 1.0) var vertical_force_ratio := 0.3
@export var species_hit_window := 2.0
@export var species_hits_required := 2
@export var species_bonus_damage := 10.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var visual: AnimatedSprite2D = $Visual
@onready var swoop_hitbox: Area2D = $SwoopHitbox
@onready var swoop_shape: CollisionShape2D = $SwoopHitbox/CollisionShape2D

var state := State.PATROL
var _nest := Vector2.ZERO
var _target: PlayerController
var _patrol_destination := Vector2.ZERO
var _patrol_timer := 0.0
var _patrol_hover := false
var _state_timer := 0.0
var _attack_cooldown_remaining := 0.0
var _attack_target_position := Vector2.ZERO
var _recovery_destination := Vector2.ZERO
var _has_hit_this_swoop := false
var _coordinator: AttackGroupCoordinator

func _ready() -> void:
	support.persistent_id = persistent_id
	_setup_visual()
	_nest = nest_position if not nest_position.is_zero_approx() else global_position
	var group_id := spawn_group_id if not spawn_group_id.is_empty() else StringName(persistent_id)
	call_deferred(&"_setup_attack_coordinator", group_id)
	sight.target_seen.connect(_on_target_seen)
	sight.target_lost.connect(_on_target_lost)
	swoop_hitbox.body_entered.connect(_on_swoop_body_entered)
	support.health.damaged.connect(_on_damaged)
	_set_swoop_hitbox(false)
	_choose_patrol_destination()

func _physics_process(delta: float) -> void:
	_attack_cooldown_remaining = maxf(0.0, _attack_cooldown_remaining - delta)
	if support.process_disabled_flight(self, delta):
		if state in [State.TELEGRAPH, State.SWOOP]:
			_release_attack()
		state = State.PATROL
		_set_swoop_hitbox(false)
		_play_visual(&"fly")
		return
	match state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT_WAIT:
			_process_alert_wait()
		State.TELEGRAPH:
			_process_telegraph(delta)
		State.SWOOP:
			_process_swoop(delta)
		State.RECOVERY:
			_process_recovery(delta)
	if absf(velocity.x) > 0.1:
		visual.flip_h = velocity.x < 0.0
	sight.facing = velocity.normalized() if not velocity.is_zero_approx() else sight.facing

func _process_patrol(delta: float) -> void:
	_play_visual(&"fly")
	if _player_in_nest():
		_enter_alert_wait()
		return
	_patrol_timer -= delta
	if _patrol_timer <= 0.0 or (not _patrol_hover and global_position.distance_to(_patrol_destination) <= 12.0):
		_choose_patrol_destination()
	if _patrol_hover:
		velocity = velocity.lerp(Vector2.ZERO, _steering_alpha(delta))
	else:
		var desired_velocity := global_position.direction_to(_patrol_destination) * flight_speed * _flight_multiplier()
		velocity = velocity.lerp(desired_velocity, _steering_alpha(delta))
	move_and_slide()

func _process_alert_wait() -> void:
	_play_visual(&"fly")
	velocity = Vector2.ZERO
	if not _player_in_nest():
		_enter_patrol()
		return
	_face_target()
	if _coordinator != null and _attack_cooldown_remaining <= 0.0 and _coordinator.request_attack(self):
		_enter_telegraph()

func _process_telegraph(delta: float) -> void:
	_play_visual(&"dive")
	_state_timer -= delta
	velocity = Vector2.ZERO
	_face_target()
	if _state_timer <= 0.0:
		_enter_swoop()

func _process_swoop(delta: float) -> void:
	_play_visual(&"dive")
	_state_timer -= delta
	var direction := global_position.direction_to(_attack_target_position)
	velocity = direction * swoop_speed * _flight_multiplier()
	move_and_slide()
	if _state_timer <= 0.0 or global_position.distance_to(_attack_target_position) <= 12.0:
		_enter_recovery()

func _process_recovery(delta: float) -> void:
	_play_visual(&"fly")
	_state_timer -= delta
	var direction := global_position.direction_to(_recovery_destination)
	velocity = direction * flight_speed * _flight_multiplier()
	move_and_slide()
	if _state_timer <= 0.0 or global_position.distance_to(_recovery_destination) <= 12.0:
		_attack_cooldown_remaining = attack_cooldown
		if _player_in_nest():
			_enter_alert_wait()
		else:
			_enter_patrol()

func _enter_patrol() -> void:
	_release_attack()
	_set_swoop_hitbox(false)
	state = State.PATROL
	_play_visual(&"fly")
	if is_instance_valid(_target) and not sight.can_see(_target):
		_target = null
	_choose_patrol_destination()

func _enter_alert_wait() -> void:
	_release_attack()
	_set_swoop_hitbox(false)
	state = State.ALERT_WAIT
	_play_visual(&"fly")
	velocity = Vector2.ZERO

func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	_play_visual(&"dive")
	_state_timer = telegraph_duration
	velocity = Vector2.ZERO
	if is_instance_valid(_target) and _target.has_method("warn_attack"):
		_target.warn_attack(self, telegraph_duration)

func _enter_swoop() -> void:
	state = State.SWOOP
	_play_visual(&"dive")
	_state_timer = swoop_max_duration
	_attack_target_position = _target.global_position if is_instance_valid(_target) else global_position
	_has_hit_this_swoop = false
	_set_swoop_hitbox(true)

func _enter_recovery() -> void:
	_release_attack()
	_set_swoop_hitbox(false)
	state = State.RECOVERY
	_play_visual(&"fly")
	_state_timer = recovery_duration
	_recovery_destination = _choose_recovery_destination()
	_has_hit_this_swoop = false

func _release_attack() -> void:
	if _coordinator != null:
		_coordinator.release_attack(self)

func _setup_attack_coordinator(group_id: StringName) -> void:
	if is_inside_tree():
		_coordinator = AttackGroupCoordinator.find_or_create(get_parent(), group_id, attack_group_maximum, attack_group_spacing)

func _choose_patrol_destination() -> void:
	_patrol_hover = false
	for _attempt in max_destination_attempts:
		var candidate := _generate_patrol_candidate()
		if _valid_patrol_candidate(candidate):
			_patrol_destination = candidate
			_patrol_timer = randf_range(patrol_destination_refresh_min, patrol_destination_refresh_max)
			return
	var center := _patrol_area_center()
	if _valid_patrol_candidate(center):
		_patrol_destination = center
		_patrol_timer = randf_range(patrol_destination_refresh_min, patrol_destination_refresh_max)
		return
	if _is_destination_path_clear(_patrol_destination):
		_patrol_timer = 0.25
		return
	_patrol_destination = global_position
	_patrol_hover = true
	_patrol_timer = 0.25

func _generate_patrol_candidate() -> Vector2:
	var forward := velocity.normalized()
	if velocity.length_squared() < 1.0:
		forward = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	var angle := deg_to_rad(randf_range(-patrol_direction_variance_degrees, patrol_direction_variance_degrees))
	return global_position + forward.rotated(angle) * randf_range(patrol_min_distance, patrol_max_distance)

func _valid_patrol_candidate(candidate: Vector2) -> bool:
	if candidate.distance_to(global_position) < patrol_min_distance:
		return false
	if candidate.distance_to(_nest) > patrol_radius:
		return false
	var direction := global_position.direction_to(candidate)
	if velocity.length_squared() >= 1.0 and velocity.normalized().dot(direction) < -0.25:
		return false
	return _is_destination_path_clear(candidate)

func _is_destination_path_clear(candidate: Vector2) -> bool:
	if candidate.is_equal_approx(global_position):
		return true
	var query := PhysicsRayQueryParameters2D.create(global_position, candidate, flight_blocking_collision_mask)
	query.exclude = [self]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _choose_recovery_destination() -> Vector2:
	var player := _target if is_instance_valid(_target) else null
	if player == null:
		return _nest
	var away_angle := player.global_position.direction_to(_nest).angle()
	if player.global_position.is_equal_approx(_nest):
		away_angle = randf_range(0.0, TAU)
	for _attempt in max_destination_attempts:
		var distance := randf_range(minf(recovery_distance_min, recovery_distance_max), maxf(recovery_distance_min, recovery_distance_max))
		var angle := away_angle + deg_to_rad(randf_range(-recovery_angle_variance_degrees, recovery_angle_variance_degrees))
		var candidate := player.global_position + Vector2.RIGHT.rotated(angle) * distance
		if candidate.distance_to(_nest) <= patrol_radius and _is_destination_path_clear(candidate):
			return candidate
	return _nest

func _patrol_area_center() -> Vector2:
	return _nest

func _steering_alpha(delta: float) -> float:
	return clampf(patrol_steering_strength * delta * 60.0, 0.0, 1.0)

func _player_in_nest() -> bool:
	return is_instance_valid(_target) and _nest.distance_to(_target.global_position) <= nest_trigger_radius

func _face_target() -> void:
	if is_instance_valid(_target):
		sight.facing = global_position.direction_to(_target.global_position)

func _flight_multiplier() -> float:
	return support.status.get_multiplier(&"flight_speed")

func _set_swoop_hitbox(active: bool) -> void:
	swoop_hitbox.set_deferred(&"monitoring", active)
	swoop_shape.set_deferred(&"disabled", not active)

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"fly", 5, 8.0, true)
	var dive := AtlasTexture.new()
	dive.atlas = FLY_SHEET
	dive.region = Rect2(4 * 48, 0, 48, 48)
	frames.add_animation(&"dive")
	frames.set_animation_speed(&"dive", 1.0)
	frames.set_animation_loop(&"dive", true)
	frames.add_frame(&"dive", dive)
	visual.sprite_frames = frames
	visual.play(&"fly")

func _add_animation(frames: SpriteFrames, animation: StringName, count: int, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = FLY_SHEET
		frame.region = Rect2(index * 48, 0, 48, 48)
		frames.add_frame(animation, frame)

func _play_visual(animation: StringName) -> void:
	if visual.animation != animation:
		visual.play(animation)

func _on_target_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController:
		_target = target

func _on_target_lost(target: Node2D) -> void:
	if target == _target and state in [State.PATROL, State.ALERT_WAIT]:
		_target = null

func _on_swoop_body_entered(body: Node) -> void:
	if state != State.SWOOP or _has_hit_this_swoop or not body is PlayerController:
		return
	var player := body as PlayerController
	if not player.is_alive():
		return
	_has_hit_this_swoop = true
	var away := global_position.direction_to(player.global_position)
	if away.is_zero_approx():
		away = Vector2.RIGHT
	player.apply_force(Vector2(
		away.x * knockback_strength * horizontal_force_ratio,
		-knockback_strength * vertical_force_ratio
	))
	player.register_bird_hit(species_hit_window, species_hits_required, species_bonus_damage)
	_enter_recovery()

func _on_damaged(info: DamageInfo) -> void:
	if state == State.SWOOP and info.causes_hit_reaction:
		_enter_recovery()

func apply_damage(info: DamageInfo) -> bool:
	return support.apply_damage(info)

func apply_force(_force: Vector2) -> void:
	pass

func apply_status(id: StringName, data: Dictionary = {}) -> bool:
	return support.apply_status(id, data)

func capture_state() -> Dictionary:
	var data := support.capture_state()
	data["state"] = state
	data["nest"] = [_nest.x, _nest.y]
	return data

func restore_state(data: Dictionary) -> void:
	if not support.restore_state(data):
		return
	var saved_nest: Array = data.get("nest", [])
	if saved_nest.size() >= 2:
		_nest = Vector2(float(saved_nest[0]), float(saved_nest[1]))
	global_position = _nest
	velocity = Vector2.ZERO
	state = State.PATROL
	_choose_patrol_destination()

func handle_world_out_of_bounds() -> void:
	global_position = _nest
	velocity = Vector2.ZERO
	_enter_patrol()
