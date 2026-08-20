class_name CaveSpider
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }
enum SurfaceState { ATTACHED, TRANSITIONING, DETACHED }

@export var persistent_id := "cave_spider"
@export var move_speed := 52.0
@export var gravity_direction := Vector2.DOWN
@export var attack_range := 240.0
@export var telegraph_seconds := 0.7
@export var cooldown_seconds := 4.0
@export var projectile_speed := 170.0
@export var projectile_damage := 3.0
@export var roam_distance := 90.0
@export var adhesion_speed := 80.0
@export var surface_probe_distance := 10.0
@export var surface_probe_radius := 8.0
@export var surface_offset := 1.0
@export var normal_turn_speed := 12.0
@export_range(0.0, 45.0, 1.0) var normal_change_epsilon_degrees := 5.0
@export var detach_grace_seconds := 0.12
@export_flags_2d_physics var walkable_collision_mask := 1

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var forward_probe: ShapeCast2D = $ForwardSurfaceProbe
@onready var support_probe: ShapeCast2D = $SupportSurfaceProbe
var state := State.IDLE
var surface_state := SurfaceState.ATTACHED
var _origin := Vector2.ZERO
var _direction := 1.0
var _surface_normal := Vector2.UP
var _target_surface_normal := Vector2.UP
var _detach_remaining := 0.12
var _target: PlayerController
var _aim := Vector2.ZERO
var _timer := 0.0
var _flee_position := Vector2.ZERO
var _fleeing := false
var _last_facing := Vector2.RIGHT

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	_surface_normal = -gravity_direction.normalized()
	_reset_surface()
	forward_probe.collision_mask = walkable_collision_mask
	support_probe.collision_mask = walkable_collision_mask
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(_on_target_lost)
	sound.sound_accepted.connect(_on_sound)

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	var light := _nearest_light()
	var sound_event := _active_sound_threat()
	if light != null:
		_target = null
		_begin_flee(light.global_position)
		_cancel_attack()
	elif sound_event != null:
		_target = null
		_begin_flee(sound_event.position)
		_cancel_attack()
	else:
		_fleeing = false
	if state == State.ATTACK:
		velocity = Vector2.ZERO
		sprite.play(&"shoot")
		if _timer <= 0.0: _fire()
		return
	if not _fleeing and _target != null and _timer <= 0.0 and global_position.distance_to(_target.global_position) <= attack_range and sight.can_see(_target):
		state = State.ATTACK
		_aim = _target.global_position
		_timer = telegraph_seconds
		_target.warn_attack(self, telegraph_seconds)
	else:
		state = State.MOVE
		sprite.play(&"walk")
		var destination := _flee_position if _fleeing else (_target.global_position if _target != null else _origin)
		_move_on_surface(delta, destination)
	if not is_zero_approx(velocity.x): sprite.flip_h = velocity.x < 0.0
	if velocity.length_squared() > 1.0:
		_last_facing = velocity.normalized()
	sight.facing = _last_facing
	if _fleeing and global_position.distance_to(_flee_position) <= 12.0:
		_fleeing = false

func _move_on_surface(delta: float, destination: Vector2) -> void:
	var tangent := Vector2(-_surface_normal.y, _surface_normal.x).normalized()
	var travel_direction := _direction
	if _fleeing or _target != null:
		travel_direction = signf(tangent.dot(destination - global_position))
		if is_zero_approx(travel_direction): travel_direction = _direction
		_direction = travel_direction
	var walk_direction := tangent * travel_direction
	_update_probes(walk_direction)
	var next_normal := _forward_surface_normal(walk_direction)
	if not next_normal.is_zero_approx() and _surface_angle(next_normal) > deg_to_rad(normal_change_epsilon_degrees):
		_target_surface_normal = next_normal
		surface_state = SurfaceState.TRANSITIONING

	var support_normal := _support_surface_normal()
	if not support_normal.is_zero_approx():
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
		return

	up_direction = _surface_normal
	tangent = Vector2(-_surface_normal.y, _surface_normal.x).normalized()
	var speed := move_speed * support.status.get_multiplier(&"move_speed")
	var walk_velocity := tangent * travel_direction * speed
	velocity = walk_velocity - _surface_normal * adhesion_speed
	_last_facing = walk_direction
	move_and_slide()
	_update_surface_from_collision(walk_velocity)
	rotation = _surface_normal.angle() + PI * 0.5
	if not _fleeing and _target == null:
		var from_origin := global_position - _origin
		if from_origin.length() >= roam_distance and from_origin.normalized().dot(walk_velocity) > 0.0:
			_direction *= -1.0

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

func _surface_angle(normal: Vector2) -> float:
	return absf(_surface_normal.angle_to(normal.normalized()))

func _rotate_normal_toward(from: Vector2, to: Vector2, max_angle: float) -> Vector2:
	var angle := from.angle_to(to)
	if absf(angle) <= max_angle:
		return to.normalized()
	return from.rotated(signf(angle) * max_angle).normalized()

func _reset_surface() -> void:
	_surface_normal = -gravity_direction.normalized()
	_target_surface_normal = _surface_normal
	surface_state = SurfaceState.ATTACHED
	_detach_remaining = detach_grace_seconds
	up_direction = _surface_normal
	rotation = _surface_normal.angle() + PI * 0.5

func _nearest_light() -> Node2D:
	var best: Node2D
	var best_distance := attack_range
	for node in get_tree().get_nodes_in_group(&"light_sources"):
		if node is not Node2D or node == self or (node is CanvasItem and not node.visible): continue
		var source := node as LightSource2D
		if source != null and (not source.enabled or source.light_intensity <= 0.001): continue
		var distance := global_position.distance_to(node.global_position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best

func _active_sound_threat() -> SoundEvent:
	var event := sound.current_event
	return event if event != null and event.priority >= 8 else null

func _on_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController and state != State.ATTACK and not _fleeing:
		_target = target

func _on_target_lost(target: Node2D) -> void:
	if target == _target and state != State.ATTACK:
		_target = null

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if event.priority >= 8:
		_target = null
		_begin_flee(event.position)
		_cancel_attack()

func _begin_flee(source_position: Vector2) -> void:
	var away := source_position.direction_to(global_position)
	if away.is_zero_approx():
		away = _last_facing
	_flee_position = global_position + away * 120.0
	_fleeing = true

func _cancel_attack() -> void:
	if state == State.ATTACK:
		state = State.IDLE
		_timer = 0.0

func _fire() -> void:
	var projectile := preload("res://game/projectiles/projectile.tscn").instantiate() as Projectile
	var impact := ImpactData.new()
	impact.source_actor = self
	impact.source_species_id = support.species_id
	impact.base_damage = projectile_damage
	impact.reference_speed = projectile_speed
	impact.attack_kind = &"projectile"
	impact.max_hits = 1
	impact.status_effects = [
		{"effect_id": &"spider_slow", "duration": 3.0},
		{"effect_id": &"poison", "duration": 10.0},
		{"effect_id": &"tracking_mark", "duration": 20.0},
	]
	projectile.configure(impact, global_position.direction_to(_aim) * projectile_speed, preload("res://assets/art/enemies/cave_spider/projectile.png"))
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	state = State.IDLE
	_target = null
	_timer = cooldown_seconds

func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		global_position = _origin
		state = State.IDLE
		_fleeing = false
		_reset_surface()

func handle_world_out_of_bounds() -> void:
	global_position = _origin
	velocity = Vector2.ZERO
	_reset_surface()
