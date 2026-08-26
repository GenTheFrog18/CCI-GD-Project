class_name CaveSpider
extends CharacterBody2D

enum State { IDLE_PAUSE, ROAM_CRAWL, SHOT_TELEGRAPH, AWAIT_SHOT, RETRY_WAIT, MIDPOINT_APPROACH, CHASE, BITE_WINDUP, BITE_RESOLVE, SCATTER, INVESTIGATE, FLEE }
enum SurfaceState { ATTACHED, TRANSITIONING, DETACHED }

@export var persistent_id := "cave_spider"
@export var move_speed := 52.0
@export var gravity_direction := Vector2.DOWN
@export var attack_range := 240.0
@export var telegraph_seconds := 0.7
@export var miss_retry_cooldown_seconds := 2.0
@export var midpoint_arrival_tolerance := 16.0
@export var midpoint_approach_timeout_seconds := 3.0
@export var melee_range := 26.0
@export var bite_windup_seconds := 0.4
@export var bite_resolution_seconds := 0.1
@export var bite_damage := 4.0
@export var bite_poison_duration := 6.0
@export var bite_reach := 14.0
@export var chase_warning_refresh_seconds := 0.5
@export var firing_distance_min := 110.0
@export var firing_distance_max := 140.0
@export var scatter_minimum_seconds := 0.6
@export var investigate_wait_seconds := 3.0
@export var idle_pause_min_seconds := 1.0
@export var idle_pause_max_seconds := 2.5
@export var roam_crawl_min_seconds := 0.6
@export var roam_crawl_max_seconds := 1.4
@export var roam_return_buffer := 20.0
@export var projectile_speed := 170.0
@export var projectile_damage := 3.0
@export var projectile_spawn_height := 12.0
@export var spider_slow_duration := 3.0
@export var poison_duration := 10.0
@export var tracking_mark_duration := 20.0
@export var roam_distance := 90.0
@export var flee_distance := 120.0
@export var flee_light_radius := 240.0
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
@onready var bite_hitbox: Area2D = $BiteHitbox
@onready var bite_shape: CollisionShape2D = $BiteHitbox/CollisionShape2D

var state := State.IDLE_PAUSE
var surface_state := SurfaceState.ATTACHED
var _origin := Vector2.ZERO
var _direction := 1.0
var _surface_normal := Vector2.UP
var _target_surface_normal := Vector2.UP
var _detach_remaining := 0.12
var _target: PlayerController
var _last_known := Vector2.ZERO
var _aim := Vector2.ZERO
var _destination := Vector2.ZERO
var _timer := 0.0
var _warning_timer := 0.0
var _misses := 0
var _investigating := false
var _bite_direction := Vector2.RIGHT
var _bite_hit := false
var _active_projectile: Projectile
var _last_facing := Vector2.RIGHT
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	_random.randomize()
	_reset_surface()
	forward_probe.collision_mask = walkable_collision_mask
	support_probe.collision_mask = walkable_collision_mask
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(_on_lost)
	sound.sound_accepted.connect(_on_sound)
	support.health.damaged.connect(_on_damaged)
	bite_hitbox.body_entered.connect(_on_bite_body_entered)
	_set_bite_hitbox(false)
	_enter_idle()

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	_warning_timer = maxf(0.0, _warning_timer - delta)
	if support.status.has_status(&"electro_stunned"):
		_interrupt()
		velocity = Vector2.ZERO
		return
	var light := _nearest_light()
	var threat := _active_sound_threat()
	if light != null: _enter_flee(light.global_position)
	elif threat != null: _enter_flee(threat.position)
	elif state == State.FLEE: _enter_idle()
	match state:
		State.IDLE_PAUSE: _idle()
		State.ROAM_CRAWL: _roam(delta)
		State.SHOT_TELEGRAPH: _telegraph()
		State.AWAIT_SHOT: _await_shot()
		State.RETRY_WAIT: _retry()
		State.MIDPOINT_APPROACH: _midpoint(delta)
		State.CHASE: _chase(delta)
		State.BITE_WINDUP: _bite_windup()
		State.BITE_RESOLVE: _bite_resolve()
		State.SCATTER: _scatter(delta)
		State.INVESTIGATE: _investigate(delta)
		State.FLEE: _flee(delta)
	_update_facing()

func _idle() -> void:
	velocity = Vector2.ZERO; sprite.play(&"idle")
	if _timer <= 0.0:
		state = State.ROAM_CRAWL
		_direction = _surface_direction(_origin) if _outside_leash() else (-1.0 if _random.randf() < 0.5 else 1.0)
		_timer = _random.randf_range(minf(roam_crawl_min_seconds, roam_crawl_max_seconds), maxf(roam_crawl_min_seconds, roam_crawl_max_seconds))

func _roam(delta: float) -> void:
	sprite.play(&"walk"); _move_on_surface(delta, global_position, _direction)
	if _timer <= 0.0 or global_position.distance_to(_origin) > roam_distance:
		_enter_idle()

func _telegraph() -> void:
	velocity = Vector2.ZERO; sprite.play(&"shoot")
	if not _can_see_target(): _enter_investigate()
	elif _timer <= 0.0: _fire()

func _await_shot() -> void:
	velocity = Vector2.ZERO
	if not _can_see_target(): _enter_investigate()

func _retry() -> void:
	velocity = Vector2.ZERO; sprite.play(&"idle")
	if _timer <= 0.0:
		if _can_see_target(): _begin_shot()
		else: _enter_investigate()

func _midpoint(delta: float) -> void:
	sprite.play(&"walk"); _move_on_surface(delta, _destination)
	if global_position.distance_to(_destination) <= midpoint_arrival_tolerance or _timer <= 0.0:
		if _can_see_target(): _begin_shot()
		else: _enter_investigate()

func _chase(delta: float) -> void:
	if not _can_see_target(): _enter_investigate(); return
	_last_known = _target.global_position
	if _warning_timer <= 0.0:
		_target.warn_attack(self, chase_warning_refresh_seconds)
		_warning_timer = chase_warning_refresh_seconds
	if global_position.distance_to(_target.global_position) <= melee_range: _begin_bite(); return
	sprite.play(&"walk"); _move_on_surface(delta, _target.global_position)

func _bite_windup() -> void:
	velocity = Vector2.ZERO; sprite.play(&"shoot")
	if not _can_see_target(): _enter_investigate()
	elif _timer <= 0.0:
		_bite_hit = false
		bite_hitbox.position = _bite_direction * bite_reach
		_set_bite_hitbox(true)
		state = State.BITE_RESOLVE; _timer = bite_resolution_seconds
		for body in bite_hitbox.get_overlapping_bodies(): _apply_bite(body)

func _bite_resolve() -> void:
	velocity = Vector2.ZERO
	if _timer <= 0.0: _set_bite_hitbox(false); _enter_scatter()

func _scatter(delta: float) -> void:
	if not _can_see_target(): _enter_investigate(); return
	var distance := global_position.distance_to(_target.global_position)
	if _timer <= 0.0 and distance >= firing_distance_min and distance <= firing_distance_max: _begin_shot(); return
	sprite.play(&"walk"); _move_on_surface(delta, _destination)
	if _timer <= 0.0: _set_scatter_destination()

func _investigate(delta: float) -> void:
	if _can_see_target(): _begin_shot(); return
	if not _investigating:
		sprite.play(&"walk"); _move_on_surface(delta, _last_known)
		if global_position.distance_to(_last_known) <= midpoint_arrival_tolerance:
			_investigating = true; _timer = investigate_wait_seconds
	elif _timer <= 0.0:
		_clear_target(); _enter_idle()

func _flee(delta: float) -> void:
	sprite.play(&"walk"); _move_on_surface(delta, _destination)

func _begin_shot() -> void:
	if not _can_see_target(): _enter_investigate(); return
	state = State.SHOT_TELEGRAPH
	_aim = sight.last_ray_end; _last_known = _aim; _timer = telegraph_seconds
	_target.warn_attack(self, telegraph_seconds)

func _fire() -> void:
	var projectile := preload("res://game/projectiles/projectile.tscn").instantiate() as Projectile
	var impact := ImpactData.new()
	impact.source_actor = self; impact.source_species_id = support.species_id
	impact.base_damage = projectile_damage; impact.reference_speed = projectile_speed
	impact.attack_kind = &"projectile"; impact.max_hits = 1
	impact.status_effects = [{"effect_id": &"spider_slow", "duration": spider_slow_duration}, {"effect_id": &"poison", "duration": poison_duration}, {"effect_id": &"tracking_mark", "duration": tracking_mark_duration}]
	var spawn_position := global_position + Vector2.UP.rotated(rotation) * projectile_spawn_height
	var launch_velocity := spawn_position.direction_to(_aim) * projectile_speed
	projectile.configure(impact, launch_velocity, preload("res://assets/art/enemies/cave_spider/projectile.png"))
	projectile.terminal_resolved.connect(_on_projectile_result.bind(projectile))
	get_parent().add_child(projectile)
	projectile.global_position = spawn_position
	_active_projectile = projectile; state = State.AWAIT_SHOT
	if _misses >= 2: _misses = 0

func _on_projectile_result(result: StringName, body: Node, projectile: Projectile) -> void:
	if projectile != _active_projectile: return
	_active_projectile = null
	if state != State.AWAIT_SHOT: return
	if result == &"hit_player":
		_misses = 0; _target = body as PlayerController if body is PlayerController else _target; state = State.CHASE; _warning_timer = 0.0; return
	_misses += 1
	if _misses == 1:
		state = State.RETRY_WAIT; _timer = miss_retry_cooldown_seconds; return
	_destination = global_position.lerp(_last_known, 0.5)
	state = State.MIDPOINT_APPROACH; _timer = midpoint_approach_timeout_seconds

func _begin_bite() -> void:
	state = State.BITE_WINDUP
	_bite_direction = global_position.direction_to(_target.global_position)
	if _bite_direction.is_zero_approx(): _bite_direction = _last_facing
	_timer = bite_windup_seconds; _target.warn_attack(self, bite_windup_seconds)

func _on_bite_body_entered(body: Node) -> void: _apply_bite(body)
func _apply_bite(body: Node) -> void:
	if state != State.BITE_RESOLVE or _bite_hit or body is not PlayerController: return
	var impact := ImpactData.new()
	impact.source_actor = self; impact.source_species_id = support.species_id
	impact.base_damage = bite_damage; impact.damage_multiplier_min = 1.0; impact.damage_multiplier_max = 1.0
	impact.attack_kind = &"spider_bite"; impact.status_effects = [{"effect_id": &"poison", "duration": bite_poison_duration}]
	impact.apply_to(body); _bite_hit = true

func _enter_scatter() -> void:
	_clear_projectile(); _set_bite_hitbox(false)
	if not is_instance_valid(_target): _enter_investigate(); return
	state = State.SCATTER; _set_scatter_destination()
func _set_scatter_destination() -> void:
	var away := _target.global_position.direction_to(global_position)
	if away.is_zero_approx(): away = _last_facing
	_destination = _target.global_position + away * ((firing_distance_min + firing_distance_max) * 0.5); _timer = scatter_minimum_seconds
func _enter_investigate() -> void:
	_clear_projectile(); _set_bite_hitbox(false)
	if is_instance_valid(_target): _last_known = _target.global_position
	state = State.INVESTIGATE; _investigating = false; _timer = 0.0
func _enter_flee(source: Vector2) -> void:
	if state != State.FLEE:
		var away := source.direction_to(global_position)
		if away.is_zero_approx(): away = _last_facing
		_destination = global_position + away * flee_distance
	_clear_target(); _clear_projectile(); _set_bite_hitbox(false); state = State.FLEE
func _enter_idle() -> void:
	state = State.IDLE_PAUSE; _timer = _random.randf_range(minf(idle_pause_min_seconds, idle_pause_max_seconds), maxf(idle_pause_min_seconds, idle_pause_max_seconds)); velocity = Vector2.ZERO; _set_bite_hitbox(false)
func _interrupt() -> void:
	_clear_target(); _clear_projectile(); _set_bite_hitbox(false); state = State.IDLE_PAUSE; _timer = 0.0
func _clear_target() -> void:
	_target = null; _misses = 0; _investigating = false; _warning_timer = 0.0
func _clear_projectile() -> void:
	var projectile := _active_projectile; _active_projectile = null
	if is_instance_valid(projectile): projectile.cancel()
func _can_see_target() -> bool: return is_instance_valid(_target) and sight.can_see(_target)
func _outside_leash() -> bool: return global_position.distance_to(_origin) > maxf(0.0, roam_distance - roam_return_buffer)
func _surface_direction(destination: Vector2) -> float:
	var direction := signf(Vector2(-_surface_normal.y, _surface_normal.x).normalized().dot(destination - global_position))
	return direction if not is_zero_approx(direction) else _direction

func _move_on_surface(delta: float, destination: Vector2, committed_direction := 0.0) -> void:
	var travel := committed_direction if not is_zero_approx(committed_direction) else _surface_direction(destination)
	_direction = travel
	var walk := Vector2(-_surface_normal.y, _surface_normal.x).normalized() * travel
	_update_probes(walk)
	var next := _forward_surface_normal(walk)
	if not next.is_zero_approx() and _surface_angle(next) > deg_to_rad(normal_change_epsilon_degrees): _target_surface_normal = next; surface_state = SurfaceState.TRANSITIONING
	var support_normal := _support_surface_normal()
	if not support_normal.is_zero_approx():
		_detach_remaining = detach_grace_seconds
		if surface_state == SurfaceState.DETACHED: _target_surface_normal = support_normal; surface_state = SurfaceState.TRANSITIONING
	else:
		_detach_remaining = maxf(0.0, _detach_remaining - delta)
		if _detach_remaining <= 0.0: surface_state = SurfaceState.DETACHED
	if surface_state == SurfaceState.TRANSITIONING:
		_surface_normal = _rotate_normal_toward(_surface_normal, _target_surface_normal, normal_turn_speed * delta)
		if _surface_angle(_target_surface_normal) <= deg_to_rad(normal_change_epsilon_degrees): _surface_normal = _target_surface_normal; surface_state = SurfaceState.ATTACHED
	if surface_state == SurfaceState.DETACHED:
		up_direction = Vector2.UP; velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * delta; move_and_slide(); return
	up_direction = _surface_normal
	var walk_velocity := Vector2(-_surface_normal.y, _surface_normal.x).normalized() * travel * move_speed * support.status.get_multiplier(&"move_speed")
	velocity = walk_velocity - _surface_normal * adhesion_speed
	_last_facing = walk; move_and_slide(); _update_surface_from_collision(walk_velocity)
	rotation = _surface_normal.angle() + PI * 0.5

func _update_probes(walk: Vector2) -> void:
	var origin := global_position + _surface_normal * (surface_probe_radius + surface_offset)
	forward_probe.global_position = origin; forward_probe.global_rotation = 0.0; forward_probe.target_position = walk * surface_probe_distance; forward_probe.force_shapecast_update()
	support_probe.global_position = origin; support_probe.global_rotation = 0.0; support_probe.target_position = -_surface_normal * (surface_probe_radius * 2.0 + surface_offset + 2.0); support_probe.force_shapecast_update()
func _forward_surface_normal(walk: Vector2) -> Vector2:
	var best := Vector2.ZERO; var angle_best := INF
	for index in forward_probe.get_collision_count():
		var normal := forward_probe.get_collision_normal(index).normalized(); var angle := _surface_angle(normal)
		if not normal.is_zero_approx() and normal.dot(walk) <= -0.1 and angle > deg_to_rad(45.0) and angle < angle_best: best = normal; angle_best = angle
	return best
func _support_surface_normal() -> Vector2:
	var best := Vector2.ZERO; var angle_best := INF
	for index in support_probe.get_collision_count():
		var normal := support_probe.get_collision_normal(index).normalized(); var angle := _surface_angle(normal)
		if not normal.is_zero_approx() and angle < angle_best: best = normal; angle_best = angle
	return best
func _update_surface_from_collision(walk: Vector2) -> void:
	if surface_state != SurfaceState.ATTACHED: return
	for index in get_slide_collision_count():
		var normal := get_slide_collision(index).get_normal().normalized()
		if not normal.is_zero_approx() and normal.dot(walk) <= -0.1 and _surface_angle(normal) > deg_to_rad(normal_change_epsilon_degrees): _target_surface_normal = normal; surface_state = SurfaceState.TRANSITIONING; return
func _surface_angle(normal: Vector2) -> float: return absf(_surface_normal.angle_to(normal.normalized()))
func _rotate_normal_toward(from: Vector2, to: Vector2, amount: float) -> Vector2:
	var angle := from.angle_to(to); return to.normalized() if absf(angle) <= amount else from.rotated(signf(angle) * amount).normalized()
func _reset_surface() -> void:
	_surface_normal = -gravity_direction.normalized(); _target_surface_normal = _surface_normal; surface_state = SurfaceState.ATTACHED; _detach_remaining = detach_grace_seconds; up_direction = _surface_normal; rotation = _surface_normal.angle() + PI * 0.5
func _nearest_light() -> Node2D:
	var best: Node2D; var distance_best := flee_light_radius
	for node in get_tree().get_nodes_in_group(&"light_sources"):
		if node is not Node2D or node == self or (node is CanvasItem and not node.visible): continue
		var source := node as LightSource2D
		if source != null and (not source.enabled or source.light_intensity <= 0.001): continue
		var distance := global_position.distance_to(node.global_position)
		if distance < distance_best: best = node; distance_best = distance
	return best
func _active_sound_threat() -> SoundEvent:
	var event := sound.current_event; return event if event != null and event.priority >= 8 else null
func _on_seen(target: Node2D, position: Vector2) -> void:
	if target is PlayerController and state != State.FLEE:
		_target = target as PlayerController; _last_known = position
		if state in [State.IDLE_PAUSE, State.ROAM_CRAWL, State.INVESTIGATE]: _begin_shot()
func _on_lost(target: Node2D) -> void:
	if target == _target and state in [State.SHOT_TELEGRAPH, State.AWAIT_SHOT, State.MIDPOINT_APPROACH, State.CHASE, State.BITE_WINDUP, State.BITE_RESOLVE, State.SCATTER]: _enter_investigate()
func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if event.priority >= 8: _enter_flee(event.position)
func _on_damaged(info: DamageInfo) -> void:
	var attacker := info.source as PlayerController
	if attacker != null:
		_target = attacker
	if is_instance_valid(_target):
		_last_known = _target.global_position
		_enter_scatter()
	else:
		_clear_projectile(); _set_bite_hitbox(false); _enter_idle()
func _set_bite_hitbox(active: bool) -> void:
	bite_hitbox.set_deferred(&"monitoring", active); bite_shape.set_deferred(&"disabled", not active)
func _update_facing() -> void:
	if velocity.length_squared() > 1.0: _last_facing = velocity.normalized()
	if not is_zero_approx(velocity.x): sprite.flip_h = velocity.x < 0.0
	sight.facing = _last_facing
func interrupt_action(_reason: StringName) -> bool:
	if state in [State.IDLE_PAUSE, State.ROAM_CRAWL, State.FLEE]: return false
	_enter_scatter(); return true
func request_interrupt(strength: float, reason: StringName = &"impact") -> bool: return support.request_interrupt(strength, reason)
func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data): global_position = _origin; velocity = Vector2.ZERO; _interrupt(); _reset_surface()
func handle_world_out_of_bounds() -> void:
	global_position = _origin; velocity = Vector2.ZERO; _interrupt(); _reset_surface()
