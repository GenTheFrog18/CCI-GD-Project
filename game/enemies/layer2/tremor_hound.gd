class_name TremorHound
extends CharacterBody2D

const IDLE_SHEET := preload("res://assets/art/enemies/tremor_hound/tremor_hound_idle.png")
const RUN_SHEET := preload("res://assets/art/enemies/tremor_hound/tremor_hound_run.png")
const ATTACK_SHEET := preload("res://assets/art/enemies/tremor_hound/tremor_hound_attaack.png")

enum State { SPAWN, ROAM, INVESTIGATE, SEARCH, CONFIRMED_TARGET, PREPARE_POUNCE, POUNCE, RECOVER, RETALIATION_WAIT, STUNNED }

@export var persistent_id := "tremor_hound"
@export var gravity := 900.0
@export var roam_speed := 42.0
@export var investigation_speed := 76.0
@export var confirmed_chase_speed := 92.0
@export var ground_acceleration := 700.0
@export var jump_velocity := 240.0
@export var horizontal_jump_speed := 150.0
@export var max_jump_time := 1.2
@export var roam_burst_min_seconds := 0.8
@export var roam_burst_max_seconds := 2.0
@export var roam_pause_min_seconds := 0.4
@export var roam_pause_max_seconds := 1.4
@export var proximity_detection_radius := 52.0
@export var sight_range := 300.0
@export var hearing_radius := 600.0
@export var sound_queue_capacity := 4
@export var sound_memory_seconds := 10.0
@export var sound_retarget_margin := 12.0
@export var sound_retarget_cooldown := 0.25
@export var sound_distance_penalty := 0.2
@export var sound_age_decay := 1.0
@export var investigation_arrival_tolerance := 18.0
@export var search_radius := 64.0
@export var search_duration := 2.5
@export var pounce_engagement_distance := 42.0
@export var pounce_prepare_duration := 0.75
@export var pounce_speed := 250.0
@export var pounce_vertical_velocity := 210.0
@export var pounce_duration := 0.8
@export var pounce_damage := 15.0
@export var pounce_force := 210.0
@export var recovery_duration := 1.2
@export var retaliation_wait_duration := 0.5
@export var incapacitated_duration := 0.35
@export var direct_hit_priority := 100.0
@export var max_walkable_slope_degrees := 50.0
@export_flags_2d_physics var terrain_collision_mask := 1

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener
@onready var proximity: Area2D = $PlayerProximityDetector
@onready var traversal: GroundTraversal2D = $GroundTraversal2D
@onready var pounce_hitbox: Area2D = $PounceHitbox
@onready var pounce_shape: CollisionShape2D = $PounceHitbox/CollisionShape2D
@onready var visual: AnimatedSprite2D = $AnimatedSprite2D

var state := State.SPAWN
var _target: Node2D
var _last_known_position := Vector2.ZERO
var _investigation := Vector2.ZERO
var _retaliation_target: Node2D
var _current_event: Dictionary = {}
var _sound_queue: Array[Dictionary] = []
var _state_timer := 0.0
var _roam_timer := 0.0
var _pause_timer := 0.0
var _roam_direction := 1.0
var _search_center := Vector2.ZERO
var _search_ignored_target: Node2D
var _movement_speed := 0.0
var _pounce_direction := Vector2.RIGHT
var _recovery_direction := Vector2.LEFT
var _pounce_hit := false
var _warned := false
var _sound_retarget_remaining := 0.0
var _random := RandomNumberGenerator.new()

func _ready() -> void:
	support.persistent_id = persistent_id
	_random.randomize()
	_setup_visual()
	sight.normal_range = sight_range
	sight.normal_angle_degrees = 360.0
	sight.proximity_range = 0.0
	sight.obstruction_mask = terrain_collision_mask
	sound.hearing_radius = hearing_radius
	sound.forward_all_events = true
	proximity.collision_mask = 2
	var proximity_shape := proximity.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if proximity_shape != null and proximity_shape.shape is CircleShape2D:
		(proximity_shape.shape as CircleShape2D).radius = proximity_detection_radius
	sight.target_seen.connect(_on_sight_seen)
	sight.target_lost.connect(_on_sight_lost)
	sound.sound_heard.connect(_on_sound_heard)
	support.health.damaged.connect(_on_damaged)
	traversal.route_completed.connect(_on_route_completed)
	traversal.route_failed.connect(_on_route_failed)
	pounce_hitbox.body_entered.connect(_on_pounce_body_entered)
	_set_pounce_hitbox(false)
	state = State.ROAM
	_pause_timer = _random_pause()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if support.health.is_dead:
		return
	_state_timer = maxf(0.0, _state_timer - delta)
	_sound_retarget_remaining = maxf(0.0, _sound_retarget_remaining - delta)
	if support.status.has_status(&"electro_stunned"):
		_enter_stunned()
		_ground_motion(delta)
		return
	if state == State.STUNNED:
		_enter_roam()
	_refresh_detection()
	_process_sound_priority()
	match state:
		State.ROAM:
			_process_roam(delta)
		State.INVESTIGATE:
			_process_investigate(delta)
		State.SEARCH:
			_process_search(delta)
		State.CONFIRMED_TARGET:
			_process_confirmed(delta)
		State.PREPARE_POUNCE:
			_process_prepare(delta)
		State.POUNCE:
			_process_pounce(delta)
		State.RECOVER:
			_process_recover(delta)
		State.RETALIATION_WAIT:
			_process_retaliation_wait(delta)
		State.SPAWN:
			_enter_roam()
	_update_facing()
	if GameSession.debug_gameplay_draw:
		queue_redraw()

func _process_roam(delta: float) -> void:
	_process_flat_roam(delta, roam_speed)

func _process_flat_roam(delta: float, speed: float, boundary_center: Vector2 = Vector2.ZERO, boundary_radius: float = -1.0) -> void:
	if _pause_timer > 0.0:
		visual.play(&"idle")
		velocity.x = move_toward(velocity.x, 0.0, ground_acceleration * delta)
		_pause_timer -= delta
		_ground_motion(delta)
		return
	if _roam_timer <= 0.0:
		_roam_direction = _random_direction()
		_roam_timer = _random.randf_range(roam_burst_min_seconds, roam_burst_max_seconds)
	if boundary_radius > 0.0:
		var horizontal_offset := global_position.x - boundary_center.x
		if absf(horizontal_offset) >= boundary_radius and signf(horizontal_offset) == _roam_direction:
			_roam_direction = -signf(horizontal_offset)
	visual.play(&"run")
	_roam_timer -= delta
	var requested_velocity_x := move_toward(velocity.x, _roam_direction * speed, ground_acceleration * delta)
	velocity.x = requested_velocity_x
	_ground_motion(delta)
	if is_on_wall() and absf(requested_velocity_x) > 1.0 and absf(get_last_motion().x) < 0.01:
		_roam_direction *= -1.0
		_roam_timer = _random.randf_range(roam_burst_min_seconds, roam_burst_max_seconds)
		velocity.x = 0.0
		_pause_timer = _random_pause()
	elif _roam_timer <= 0.0:
		velocity.x = 0.0
		_pause_timer = _random_pause()

func _process_investigate(delta: float) -> void:
	if _player_detected():
		_enter_confirmed(_target)
		return
	if traversal.is_active():
		visual.play(&"run")
		traversal.physics_step(delta)
		return
	if _current_event.is_empty():
		_enter_roam()
		return
	_movement_speed = investigation_speed
	var result: GroundTraversal2D.RouteResult = traversal.request_move_to(_last_known_position, &"investigate")
	if result != GroundTraversal2D.RouteResult.SUCCESS:
		_discard_sound_event(_current_event)
		_current_event = {}
		_enter_search(_last_known_position)
	else:
		visual.play(&"run")
		traversal.physics_step(delta)

func _process_search(delta: float) -> void:
	_clear_search_ignored_target()
	if _player_detected():
		_enter_confirmed(_target)
		return
	if _state_timer <= 0.0:
		_discard_sound_event(_current_event)
		_current_event = {}
		var next_event: Dictionary = _best_sound_event()
		if next_event.is_empty():
			_enter_roam()
		else:
			_current_event = next_event
			_last_known_position = next_event.position
			_enter_investigate()
		return
	_process_flat_roam(delta, investigation_speed, _search_center, search_radius)

func _process_confirmed(delta: float) -> void:
	if not _player_detected():
		_target = null
		_enter_search(_last_known_position)
		return
	_last_known_position = _target.global_position
	if global_position.distance_to(_target.global_position) <= pounce_engagement_distance:
		_begin_prepare(_target)
		return
	_movement_speed = confirmed_chase_speed
	visual.play(&"run")
	var result: GroundTraversal2D.RouteResult = traversal.request_move_to(_target.global_position, &"chase")
	if result == GroundTraversal2D.RouteResult.SUCCESS:
		traversal.physics_step(delta)
	else:
		var unreachable_target := _target
		_enter_search(_last_known_position)
		_search_ignored_target = unreachable_target

func _process_prepare(delta: float) -> void:
	visual.play(&"idle")
	var prepare_direction := signf(_target.global_position.x - global_position.x) if is_instance_valid(_target) else _roam_direction
	if is_zero_approx(prepare_direction):
		prepare_direction = _roam_direction
	velocity.x = move_toward(velocity.x, prepare_direction * roam_speed * 0.35, ground_acceleration * delta)
	_ground_motion(delta)
	if not is_instance_valid(_target):
		_enter_search(_last_known_position)
		return
	if not _warned and _target.has_method("warn_attack"):
		_target.warn_attack(self, pounce_prepare_duration)
		_warned = true
	if _state_timer <= 0.0:
		_pounce_direction = global_position.direction_to(_target.global_position)
		if _pounce_direction.is_zero_approx():
			_pounce_direction = Vector2.RIGHT
		_pounce_hit = false
		state = State.POUNCE
		_state_timer = pounce_duration
		velocity = Vector2(_pounce_direction.x * pounce_speed, -pounce_vertical_velocity)
		visual.play(&"pounce")
		visual.frame = 1
		_set_pounce_hitbox(true)

func _process_pounce(delta: float) -> void:
	visual.play(&"pounce")
	visual.frame = 1
	velocity.y += gravity * delta
	move_and_slide()
	if get_slide_collision_count() > 0 and velocity.y >= 0.0:
		_recover()
	elif _state_timer <= 0.0:
		_recover()

func _process_recover(delta: float) -> void:
	visual.play(&"run")
	velocity.x = move_toward(velocity.x, _recovery_direction.x * roam_speed, ground_acceleration * delta)
	_ground_motion(delta)
	if _state_timer > 0.0:
		return
	if is_instance_valid(_retaliation_target):
		_begin_prepare(_retaliation_target)
	elif _player_detected():
		_enter_confirmed(_target)
	elif not _current_event.is_empty():
		_enter_investigate()
	else:
		_enter_roam()

func _process_retaliation_wait(delta: float) -> void:
	visual.play(&"idle")
	velocity.x = move_toward(velocity.x, 0.0, ground_acceleration * delta)
	_ground_motion(delta)
	if _state_timer <= 0.0:
		if is_instance_valid(_retaliation_target):
			_begin_prepare(_retaliation_target)
		else:
			_enter_roam()

func _refresh_detection() -> void:
	if not support.detectors_enabled():
		return
	_clear_search_ignored_target()
	var player := _nearby_player()
	if player != null:
		# Physical proximity overrides the temporary unreachable-target suppression.
		_search_ignored_target = null
		_target = player
		_last_known_position = player.global_position
		if state in [State.ROAM, State.INVESTIGATE, State.SEARCH]:
			_enter_confirmed(player)
		return
	if player == null and is_instance_valid(sight.current_target) and sight.can_see(sight.current_target):
		player = sight.current_target
	if player != null and player != _search_ignored_target:
		_target = player
		_last_known_position = player.global_position
		if state in [State.ROAM, State.INVESTIGATE, State.SEARCH]:
			_enter_confirmed(player)

func _nearby_player() -> Node2D:
	if not is_instance_valid(proximity) or not proximity.monitoring:
		return null
	for body in proximity.get_overlapping_bodies():
		if body is Node2D and body.is_in_group(&"player") and (not body.has_method("is_combat_protected") or not body.is_combat_protected()):
			return body as Node2D
	return null

func _player_detected() -> bool:
	if not support.detectors_enabled() or not is_instance_valid(_target):
		return false
	if _target.has_method("is_combat_protected") and _target.is_combat_protected():
		return false
	return _nearby_player() == _target or sight.can_see(_target)

func _player_is_detectable(player: Node2D) -> bool:
	if not is_instance_valid(player):
		return false
	if player.has_method("is_combat_protected") and player.is_combat_protected():
		return false
	return _nearby_player() == player or sight.can_see(player)

func _clear_search_ignored_target() -> void:
	if is_instance_valid(_search_ignored_target) and _player_is_detectable(_search_ignored_target):
		return
	_search_ignored_target = null

func _on_sight_seen(target: Node2D, last_known: Vector2) -> void:
	if not support.detectors_enabled() or target == null or target == _search_ignored_target:
		return
	_target = target
	_last_known_position = last_known
	if state in [State.ROAM, State.INVESTIGATE, State.SEARCH]:
		_enter_confirmed(target)

func _on_sight_lost(target: Node2D) -> void:
	if target == _target and _nearby_player() == null and state == State.CONFIRMED_TARGET:
		_last_known_position = target.global_position
		_target = null
		_enter_search(_last_known_position)

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	_consider_sound(event)

func _on_sound_heard(event: SoundEvent) -> void:
	_consider_sound(event)

func _on_route_completed() -> void:
	match state:
		State.INVESTIGATE:
			_enter_search(_last_known_position)
		State.ROAM:
			_roam_timer = 0.0
			_pause_timer = _random_pause()
		State.SEARCH:
			_pause_timer = _random_pause()

func _on_route_failed(_result: GroundTraversal2D.RouteResult, last_reachable: Vector2, _reason: StringName) -> void:
	match state:
		State.INVESTIGATE:
			_last_known_position = last_reachable
			_enter_search(last_reachable)
		State.CONFIRMED_TARGET:
			_enter_search(last_reachable)
		State.ROAM:
			_pause_timer = _random_pause()
		State.SEARCH:
			_pause_timer = _random_pause()

func _consider_sound(event: SoundEvent) -> void:
	if event == null or not support.detectors_enabled() or event.source == self:
		return
	var distance := global_position.distance_to(event.position)
	if distance > minf(event.radius, hearing_radius):
		return
	var record: Dictionary = {"position": event.position, "radius": event.radius, "priority": event.priority, "intensity": event.intensity, "category": event.sound_type, "timestamp": event.timestamp, "source_id": event.source.get_instance_id() if is_instance_valid(event.source) else 0}
	for index in _sound_queue.size():
		if int(_sound_queue[index].get("source_id", 0)) == int(record.get("source_id", 0)) and StringName(_sound_queue[index].get("category", &"")) == StringName(record.get("category", &"")):
			_sound_queue[index] = record
			return
	_sound_queue.append(record)
	while _sound_queue.size() > maxi(1, sound_queue_capacity):
		_sound_queue.remove_at(_worst_sound_index())
	if state in [State.ROAM, State.INVESTIGATE, State.SEARCH] and _sound_retarget_remaining <= 0.0:
		var best: Dictionary = _best_sound_event()
		if not best.is_empty() and (_current_event.is_empty() or _sound_score(best) > _sound_score(_current_event) + sound_retarget_margin):
			_current_event = best
			_last_known_position = best.get("position", global_position)
			_investigation = _last_known_position
			_sound_retarget_remaining = sound_retarget_cooldown
			_enter_investigate()

func _process_sound_priority() -> void:
	if state in [State.PREPARE_POUNCE, State.POUNCE, State.RECOVER, State.RETALIATION_WAIT, State.STUNNED]:
		return
	# A live player target always outranks a remembered sound. Without this,
	# proximity detection can bounce the hound back into investigation every frame.
	if _nearby_player() != null or _player_detected():
		return
	var best: Dictionary = _best_sound_event()
	if best.is_empty():
		return
	if state == State.CONFIRMED_TARGET and _sound_score(best) <= direct_hit_priority:
		return
	if _current_event.is_empty() or _sound_score(best) > _sound_score(_current_event) + sound_retarget_margin:
		_current_event = best
		_last_known_position = best.get("position", global_position)
		_investigation = _last_known_position
		_enter_investigate()

func _best_sound_event() -> Dictionary:
	var best: Dictionary = {}
	var best_score := -INF
	for event: Dictionary in _sound_queue:
		if _sound_age(event) > sound_memory_seconds:
			continue
		var score := _sound_score(event)
		if score > best_score:
			best = event
			best_score = score
	return best

func _discard_sound_event(event: Dictionary) -> void:
	if event.is_empty():
		return
	var timestamp := int(event.get("timestamp", -1))
	var category := StringName(event.get("category", &""))
	var source_id := int(event.get("source_id", 0))
	for index in range(_sound_queue.size() - 1, -1, -1):
		var queued: Dictionary = _sound_queue[index]
		if int(queued.get("timestamp", -2)) == timestamp and StringName(queued.get("category", &"")) == category and int(queued.get("source_id", 0)) == source_id:
			_sound_queue.remove_at(index)

func _sound_score(event: Dictionary) -> float:
	var category := StringName(event.get("category", &"generic"))
	var category_multiplier := 1.0
	if category in [&"whistle", &"resonance", &"rattlepod"]:
		category_multiplier = 1.5
	return float(event.get("priority", 0)) * 10.0 + float(event.get("intensity", 0.0)) * category_multiplier - global_position.distance_to(event.get("position", global_position)) * sound_distance_penalty - _sound_age(event) * sound_age_decay

func _sound_age(event: Dictionary) -> float:
	return maxf(0.0, (Time.get_ticks_msec() - int(event.get("timestamp", 0))) / 1000.0)

func _worst_sound_index() -> int:
	var index := 0
	var score := INF
	for current in _sound_queue.size():
		var current_score := _sound_score(_sound_queue[current])
		if current_score < score:
			score = current_score
			index = current
	return index

func _enter_investigate() -> void:
	if _current_event.is_empty():
		_enter_roam()
		return
	state = State.INVESTIGATE
	_target = null
	velocity.x = 0.0
	traversal.cancel()

func _enter_search(center: Vector2) -> void:
	state = State.SEARCH
	_search_center = center
	_state_timer = search_duration
	_pause_timer = 0.0
	_roam_timer = 0.0
	_target = null
	traversal.cancel()

func _enter_confirmed(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	_target = target
	_search_ignored_target = null
	_last_known_position = target.global_position
	state = State.CONFIRMED_TARGET
	_current_event = {}
	_pause_timer = 0.0
	traversal.cancel()
	velocity.x = 0.0

func _begin_prepare(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	traversal.cancel()
	_target = target
	state = State.PREPARE_POUNCE
	_state_timer = pounce_prepare_duration
	_warned = false

func _recover() -> void:
	var retreat_from := _target as Node2D
	if not is_instance_valid(retreat_from):
		retreat_from = get_tree().get_first_node_in_group(&"player") as Node2D
	if is_instance_valid(retreat_from):
		var away := retreat_from.global_position.direction_to(global_position)
		_recovery_direction = Vector2(signf(away.x), 0.0) if not is_zero_approx(away.x) else Vector2(-_pounce_direction.x, 0.0)
	else:
		_recovery_direction = Vector2(-_pounce_direction.x, 0.0)
	_set_pounce_hitbox(false)
	state = State.RECOVER
	_state_timer = recovery_duration
	_target = null
	_warned = false
	velocity.x *= 0.35

func _on_pounce_body_entered(body: Node2D) -> void:
	if state != State.POUNCE or _pounce_hit or body == self or not body.is_in_group(&"player"):
		return
	_pounce_hit = true
	var impact := ImpactData.new()
	impact.source_actor = self
	impact.source_species_id = support.species_id
	impact.base_damage = pounce_damage
	impact.damage_multiplier_min = 1.0
	impact.damage_multiplier_max = 1.0
	impact.velocity = velocity
	impact.force = _pounce_direction * pounce_force
	impact.attack_kind = &"hound_pounce"
	impact.status_effects = [{"effect_id": &"incapacitated", "duration": incapacitated_duration}]
	impact.apply_to(body)
	_recover()

func _enter_stunned() -> void:
	if state == State.STUNNED:
		return
	traversal.cancel()
	_set_pounce_hitbox(false)
	state = State.STUNNED
	_target = null

func _enter_roam() -> void:
	state = State.ROAM
	_current_event = {}
	_target = null
	_search_ignored_target = null
	_retaliation_target = null
	_roam_timer = 0.0
	_pause_timer = _random_pause()
	velocity.x = 0.0
	traversal.cancel()

func _on_damaged(info: DamageInfo) -> void:
	if support.health.is_dead:
		_set_pounce_hitbox(false)
		return
	if not info.causes_hit_reaction or info.tags.has(&"status_tick") or info.tags.has(&"fall"):
		return
	var source := info.source as Node2D
	if not is_instance_valid(source) or source == self:
		return
	_retaliation_target = source
	if state == State.POUNCE:
		return
	if state == State.PREPARE_POUNCE:
		traversal.cancel()
	state = State.RETALIATION_WAIT
	_state_timer = retaliation_wait_duration
	_target = null

func interrupt_action(_reason: StringName) -> bool:
	if state != State.PREPARE_POUNCE:
		return false
	traversal.cancel()
	_enter_stunned()
	return true

func request_interrupt(strength: float, reason: StringName = &"impact") -> bool:
	return support.request_interrupt(strength, reason)

func apply_damage(info: DamageInfo) -> bool:
	return support.apply_damage(info)

func apply_force(force: Vector2) -> void:
	velocity += support.apply_force(force)

func apply_status(id: StringName, data: Dictionary = {}) -> bool:
	return support.apply_status(id, data)

func get_ground_traversal_profile() -> Dictionary:
	return {
		"profile_id": &"tremor_hound",
		"walk_speed": maxf(_movement_speed, roam_speed),
		"ground_acceleration": ground_acceleration,
		"gravity": gravity,
		"jump_velocity": jump_velocity,
		"horizontal_jump_speed": horizontal_jump_speed,
		"max_jump_time": max_jump_time,
		"max_walkable_slope": deg_to_rad(max_walkable_slope_degrees),
		"max_step_height": 8.0,
		"can_jump": true,
		"can_fall": true,
		"max_health": support.health.max_health,
		"fall_damage_estimator": Callable(self, "_estimate_fall_damage")
	}

func _estimate_fall_damage(_height: float, _impact_speed: float) -> float:
	return 0.0

func capture_state() -> Dictionary:
	return support.capture_state()

func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		_sound_queue.clear()
		_current_event = {}
		_target = null
		_retaliation_target = null
		_enter_roam()

func handle_world_out_of_bounds() -> void:
	velocity = Vector2.ZERO
	_enter_roam()

func _ground_motion(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	move_and_slide()

func _random_pause() -> float:
	return _random.randf_range(roam_pause_min_seconds, roam_pause_max_seconds)

func _random_direction() -> float:
	return -1.0 if _random.randf() < 0.5 else 1.0

func _update_facing() -> void:
	if absf(velocity.x) > 1.0:
		visual.flip_h = velocity.x > 0.0
		sight.facing = Vector2(signf(velocity.x), 0.0)

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	_add_sheet(frames, &"idle", IDLE_SHEET, 6, 6.0, true)
	_add_sheet(frames, &"run", RUN_SHEET, 8, 10.0, true)
	_add_sheet(frames, &"pounce", ATTACK_SHEET, 2, 1.0, false)
	visual.sprite_frames = frames
	visual.animation = &"idle"
	visual.flip_h = true

func _add_sheet(frames: SpriteFrames, animation: StringName, sheet: Texture2D, count: int, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	for index in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(index * 64, 0, 64, 48)
		frames.add_frame(animation, atlas)

func _set_pounce_hitbox(active: bool) -> void:
	pounce_hitbox.set_deferred("monitoring", active)
	pounce_hitbox.set_deferred("monitorable", active)
	pounce_shape.set_deferred("disabled", not active)

func _draw() -> void:
	if not GameSession.debug_gameplay_draw:
		return
	draw_arc(Vector2.ZERO, proximity_detection_radius, 0.0, TAU, 32, Color(1.0, 0.3, 0.2, 0.8), 1.0)
	draw_arc(Vector2.ZERO, hearing_radius, 0.0, TAU, 64, Color(0.3, 0.75, 1.0, 0.25), 1.0)
	if state == State.POUNCE:
		draw_circle(to_local(global_position + _pounce_direction * 16.0), 12.0, Color(1.0, 0.2, 0.2, 0.35))
	var text := "%s  %d/%d  q:%d" % [State.keys()[state], int(support.health.health), int(support.health.max_health), _sound_queue.size()]
	draw_string(ThemeDB.fallback_font, Vector2(-100.0, -34.0), text, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 10, Color.WHITE)
