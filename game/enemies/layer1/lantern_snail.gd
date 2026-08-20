class_name LanternSnail
extends CharacterBody2D

const IDLE_SHEET := preload("res://assets/art/enemies/snail/snail_idle.png")
const WALK_SHEET := preload("res://assets/art/enemies/snail/snail_walking.png")
const HIT_SHEET := preload("res://assets/art/enemies/snail/snail_hit.png")

enum State { MOVE, FLEE, ATTACK }
enum SurfaceState { ATTACHED, TRANSITIONING, DETACHED }

@export var persistent_id := "lantern_snail"
@export var move_speed := 18.0
@export var roam_distance := 90.0
@export var trigger_radius := 42.0
@export var telegraph_seconds := 0.8
@export var scream_cooldown := 8.0
@export var scream_radius := 220.0
@export var scream_priority := 9
@export var flash_duration := 4.0
@export var sound_trigger_radius := 72.0
@export_range(0.1, 2.0, 0.05) var sprite_scale := 0.65
@export var adhesion_speed := 60.0
@export var surface_probe_distance := 10.0
@export var surface_probe_radius := 8.0
@export var surface_offset := 1.0
@export var normal_turn_speed := 12.0
@export_range(0.0, 45.0, 1.0) var normal_change_epsilon_degrees := 5.0
@export var detach_grace_seconds := 0.12
@export var flee_speed_multiplier := 1.5
@export_flags_2d_physics var walkable_collision_mask := 1

@onready var support: EnemySupport = $EnemySupport
@onready var sound: SoundListener = $SoundListener
@onready var sight: SightSensor = $SightSensor
@onready var light: LightSource2D = $LightSource2D
@onready var visual: AnimatedSprite2D = $Visual
@onready var forward_probe: ShapeCast2D = $ForwardSurfaceProbe
@onready var support_probe: ShapeCast2D = $SupportSurfaceProbe
var state := State.MOVE
var surface_state := SurfaceState.ATTACHED
var _origin := Vector2.ZERO
var _direction := 1.0
var _timer := 0.0
var _cooldown := 0.0
var _surface_normal := Vector2.UP
var _target_surface_normal := Vector2.UP
var _detach_remaining := 0.12
var _last_surface_position := Vector2.ZERO
var _hit_remaining := 0.0
var _flee_target: Node2D

func _ready() -> void:
	support.persistent_id = persistent_id
	_setup_visual()
	visual.scale = Vector2.ONE * sprite_scale
	_play_animation(&"walk")
	add_to_group(&"light_sources")
	light.light_radius = 128.0
	light.light_intensity = 0.65
	light.source_type = &"lantern_snail"
	_origin = global_position
	_reset_surface()
	forward_probe.collision_mask = walkable_collision_mask
	support_probe.collision_mask = walkable_collision_mask
	sight.normal_angle_degrees = 360.0
	sight.aggravated_angle_degrees = 360.0
	sight.target_seen.connect(func(target: Node2D, _position: Vector2): _start_flee(target))
	sight.target_lost.connect(func(target: Node2D):
		if target == _flee_target:
			_flee_target = null
			if state == State.FLEE: state = State.MOVE
	)
	sound.sound_accepted.connect(func(event: SoundEvent, _direct: bool):
		if global_position.distance_to(event.position) <= sound_trigger_radius:
			receive_agitation({"kind": "sound"})
	)
	support.health.died.connect(_on_died)
	support.health.damaged.connect(func(_info: DamageInfo):
		_hit_remaining = 0.5
		_play_animation(&"hit")
	)

func _on_died(source: Node) -> void:
	light.enabled = false
	_drop_crystal(source)

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_hit_remaining = maxf(0.0, _hit_remaining - delta)
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and _cooldown <= 0.0 and global_position.distance_to(player.global_position) <= trigger_radius and state != State.ATTACK:
		receive_agitation({"kind": "proximity"})
	if state == State.ATTACK:
		velocity = Vector2.ZERO
		_play_animation(&"hit")
		if _timer <= 0.0: _scream()
		return
	_move_on_surface(delta)

func _move_on_surface(delta: float) -> void:
	var tangent := Vector2(-_surface_normal.y, _surface_normal.x).normalized()
	var travel_direction := _direction
	var speed_multiplier := support.status.get_multiplier(&"move_speed")
	if is_instance_valid(_flee_target):
		state = State.FLEE
		var away := global_position - _flee_target.global_position
		travel_direction = signf(tangent.dot(away))
		if is_zero_approx(travel_direction): travel_direction = _direction
		_direction = travel_direction
		speed_multiplier *= flee_speed_multiplier
	else:
		state = State.MOVE
	var walk_direction := tangent * travel_direction
	_update_probes(walk_direction)
	var next_normal := _forward_surface_normal(walk_direction)
	if not next_normal.is_zero_approx() and _surface_angle(next_normal) > deg_to_rad(normal_change_epsilon_degrees):
		_target_surface_normal = next_normal
		surface_state = SurfaceState.TRANSITIONING

	var support_normal := _support_surface_normal()
	if not support_normal.is_zero_approx():
		_last_surface_position = global_position
		_detach_remaining = detach_grace_seconds
		if surface_state == SurfaceState.DETACHED:
			_target_surface_normal = support_normal
			surface_state = SurfaceState.TRANSITIONING
	else:
		_detach_remaining = maxf(0.0, _detach_remaining - delta)
		if _detach_remaining <= 0.0:
			surface_state = SurfaceState.DETACHED

	if surface_state == SurfaceState.TRANSITIONING:
		_surface_normal = _rotate_normal_toward(_surface_normal, _target_surface_normal, normal_turn_speed * delta)
		if _surface_angle(_target_surface_normal) <= deg_to_rad(normal_change_epsilon_degrees):
			_surface_normal = _target_surface_normal
			surface_state = SurfaceState.ATTACHED

	if surface_state == SurfaceState.DETACHED:
		up_direction = Vector2.UP
		velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * delta
		move_and_slide()
		_play_animation(&"hit" if _hit_remaining > 0.0 else &"walk")
		return

	up_direction = _surface_normal
	tangent = Vector2(-_surface_normal.y, _surface_normal.x).normalized()
	_play_animation(&"hit" if _hit_remaining > 0.0 else &"walk")
	var walk_velocity := tangent * travel_direction * move_speed * speed_multiplier
	velocity = walk_velocity - _surface_normal * adhesion_speed
	sight.facing = walk_velocity.normalized()
	move_and_slide()
	_update_surface_from_collision(walk_velocity)
	visual.flip_h = _direction > 0.0
	rotation = _surface_normal.angle() + PI * 0.5
	var from_origin := global_position - _origin
	var moving_away := not from_origin.is_zero_approx() and from_origin.normalized().dot(walk_velocity) > 0.0
	if from_origin.length() >= roam_distance and moving_away:
		_direction *= -1.0

func _update_surface_from_collision(walk_velocity: Vector2) -> void:
	if surface_state != SurfaceState.ATTACHED:
		return
	for index in get_slide_collision_count():
		var normal := get_slide_collision(index).get_normal().normalized()
		if normal.is_zero_approx() or normal.dot(walk_velocity) > -0.1:
			continue
		if _surface_angle(normal) <= deg_to_rad(normal_change_epsilon_degrees):
			continue
		_target_surface_normal = normal
		surface_state = SurfaceState.TRANSITIONING
		return

func _update_probes(walk_direction: Vector2) -> void:
	var probe_origin := global_position + _surface_normal * (surface_probe_radius + surface_offset)
	forward_probe.global_position = probe_origin
	forward_probe.global_rotation = 0.0
	forward_probe.target_position = walk_direction * surface_probe_distance
	forward_probe.force_shapecast_update()
	support_probe.global_position = probe_origin
	support_probe.global_rotation = 0.0
	support_probe.target_position = -_surface_normal * (surface_probe_radius * 2.0 + surface_offset + 2.0)
	support_probe.force_shapecast_update()

func _forward_surface_normal(walk_direction: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var best_angle := INF
	for index in forward_probe.get_collision_count():
		var normal := forward_probe.get_collision_normal(index).normalized()
		if normal.is_zero_approx() or normal.dot(walk_direction) > -0.1:
			continue
		var angle := _surface_angle(normal)
		if angle > deg_to_rad(45.0) and angle < best_angle:
			best = normal
			best_angle = angle
	return best

func _support_surface_normal() -> Vector2:
	if not support_probe.is_colliding():
		return Vector2.ZERO
	var best := Vector2.ZERO
	var best_angle := INF
	for index in support_probe.get_collision_count():
		var normal := support_probe.get_collision_normal(index).normalized()
		if normal.is_zero_approx():
			continue
		var angle := _surface_angle(normal)
		if angle < best_angle:
			best = normal
			best_angle = angle
	return best

func _surface_angle(normal: Vector2) -> float:
	return absf(_surface_normal.angle_to(normal.normalized()))

func _rotate_normal_toward(from: Vector2, to: Vector2, max_angle: float) -> Vector2:
	var angle := from.angle_to(to)
	if absf(angle) <= max_angle:
		return to.normalized()
	return from.rotated(signf(angle) * max_angle).normalized()

func _reset_surface() -> void:
	_surface_normal = Vector2.UP
	_target_surface_normal = Vector2.UP
	surface_state = SurfaceState.ATTACHED
	_detach_remaining = detach_grace_seconds
	up_direction = _surface_normal
	rotation = _surface_normal.angle() + PI * 0.5

func receive_agitation(_data: Dictionary = {}) -> void:
	if _cooldown > 0.0 or state == State.ATTACK: return
	state = State.ATTACK
	_timer = telegraph_seconds
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method("warn_attack"): player.warn_attack(self, telegraph_seconds)

func _start_flee(target: Node2D) -> void:
	if target == null or not target.is_in_group(&"player"):
		return
	_flee_target = target
	state = State.FLEE

func _scream() -> void:
	var flash := WorldEffectArea.new()
	var shape := CircleShape2D.new()
	shape.radius = scream_radius
	flash.configure(&"crystal", &"dazzled", flash_duration, shape, self, scream_priority, scream_radius * 2.0)
	flash.global_position = global_position
	get_parent().call_deferred(&"add_child", flash)
	state = State.MOVE
	_cooldown = scream_cooldown

func _drop_crystal(_source: Node) -> void:
	var definition := ContentCatalog.get_item(&"lantern_crystal")
	if definition == null: return
	var drop := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	drop.persistent_id = "%s:crystal" % persistent_id
	drop.configure(definition, {"origin": "enemy_drop"}, self, global_position + _surface_normal * 12.0, _surface_normal * 80.0)
	drop.set_meta(&"effect_deployed", true)
	get_parent().add_child(drop)

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"idle", IDLE_SHEET, 1, 4.0, true)
	_add_animation(frames, &"walk", WALK_SHEET, 8, 10.0, true)
	_add_animation(frames, &"hit", HIT_SHEET, 7, 10.0, false)
	visual.sprite_frames = frames

func _add_animation(frames: SpriteFrames, animation: StringName, sheet: Texture2D, count: int, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(index * 32, 0, 32, 32)
		frames.add_frame(animation, frame)

func _play_animation(animation: StringName) -> void:
	if visual.animation != animation:
		visual.play(animation)

func apply_damage(info: DamageInfo) -> bool:
	var accepted := support.apply_damage(info)
	if accepted: receive_agitation({"kind": "damage"})
	return accepted
func apply_force(force: Vector2) -> void:
	if force.length() > 40.0: receive_agitation({"kind": "impact"})
func apply_status(id: StringName, data: Dictionary = {}) -> bool:
	if id == &"dazzled":
		return false
	return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		global_position = _origin
		_reset_surface()
		state = State.MOVE
func handle_world_out_of_bounds() -> void:
	global_position = _origin
	_surface_normal = Vector2.UP
	_reset_surface()
