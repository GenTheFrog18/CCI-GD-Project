class_name LargeLayer1Flyer
extends CharacterBody2D

const IDLE_SHEET := preload("res://assets/art/enemies/big_flyer/flyer_idle.png")
const SEE_PLAYER_SHEET := preload("res://assets/art/enemies/big_flyer/flyer_see_player.png")
const ATTACK_SHEET := preload("res://assets/art/enemies/big_flyer/flyer_attack.png")
const SWOOP_ATTACK_FRAME := 7 # Frame 8 in the authored one-based sheet.

# ROAM/RECOVER retain previous public state names used by transfer checks.
enum State { ROAM, POI_PATROL, POI_IDLE, INVESTIGATE, CHASE, ATTACK_SETUP, DIVE, RECOVER, RECOVERY_TRAVEL, COOLDOWN_PATROL, SEARCH, BLOCKER_POI, DISABLED_FLIGHT }

@export var persistent_id := "large_layer1_flyer"
@export var roam_speed := 65.0
@export var chase_speed := 115.0
@export var dive_speed := 250.0
@export var sight_lock_seconds := 4.0
@export var engagement_distance := 80.0
@export var search_seconds := 15.0
@export var poi_change_min_seconds := 12.0
@export var poi_change_max_seconds := 18.0
@export var poi_recency_weight := 1.0
@export var poi_distance_weight := 1.0
@export_range(1.0, 1000.0, 1.0) var poi_patrol_radius := 160.0
@export var poi_inner_flight_radius := 130.0
@export var local_destination_refresh_min := 1.5
@export var local_destination_refresh_max := 2.5
@export var local_destination_min_distance := 50.0
@export var local_destination_max_distance := 120.0
@export_range(0.0, 180.0, 1.0) var local_direction_variance_degrees := 60.0
@export_range(0.0, 1.0, 0.01) var local_steering_strength := 0.04
@export_range(0.0, 1.0, 0.01) var local_idle_chance := 1.0 / 6.0
@export var local_idle_min_seconds := 1.0
@export var local_idle_max_seconds := 2.0
@export_range(1, 32, 1) var max_destination_attempts := 10
@export_flags_2d_physics var flight_blocking_collision_mask := 513
@export_flags_2d_physics var transparent_blocker_collision_mask := 512
@export var blocker_poi_seconds := 15.0
@export var blocker_poi_recreate_cooldown_seconds := 20.0
@export var telegraph_seconds := 0.9
@export var dive_seconds := 1.5
@export var attack_damage := 75.0
@export var attack_force := 180.0
@export var attack_hit_radius := 28.0
@export var attack_cooldown := 4.0
@export var recovery_seconds := 0.2
@export var recovery_distance := 80.0
@export_range(0.0, 180.0, 1.0) var recovery_angle_variance_degrees := 25.0
@export var priority_decay_per_second := 1.0
@export var tracking_mark_priority := 100.0
@export var snail_priority := 50.0
@export var distraction_priority := 40.0
@export var sight_priority := 20.0
@export var surround_sight_priority := 25.0
@export var sight_request_seconds := 0.25
@export var sound_request_seconds := 10.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener
@onready var visual: AnimatedSprite2D = $Visual
@onready var body_collision: CollisionShape2D = $CollisionShape2D
var state := State.ROAM
var _origin := Vector2.ZERO
var _target: PlayerController
var _poi: Node2D
var _aim := Vector2.ZERO
var _sight_time := 0.0
var _poi_time := 0.0
var _state_timer := 0.0
var _cooldown_remaining := 0.0
var _search_point := Vector2.ZERO
var _search_remaining := 0.0
var _dive_hit := false
var _poi_last_used: Dictionary = {}
var _requests: Array[Dictionary] = []
var _patrol_center := Vector2.ZERO
var _patrol_destination := Vector2.ZERO
var _patrol_timer := 0.0
var _patrol_hover := false
var _blocker_remaining := 0.0
var _blocker_cooldown_remaining := 0.0
var _finishing_attack_animation := false
var _surround_sight: SightSensor
var _surround_sight_active := false

func _ready() -> void:
	support.persistent_id = persistent_id
	_setup_visual()
	_setup_surround_sight()
	add_to_group(&"large_flyer")
	_origin = global_position
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(_on_lost)
	sound.sound_accepted.connect(_on_sound)
	_choose_poi()

func _physics_process(delta: float) -> void:
	if support.process_disabled_flight(self, delta):
		state = State.DISABLED_FLIGHT
		return
	if state == State.DISABLED_FLIGHT: _begin_poi_travel()
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	_state_timer = maxf(0.0, _state_timer - delta)
	_search_remaining = maxf(0.0, _search_remaining - delta)
	_blocker_remaining = maxf(0.0, _blocker_remaining - delta)
	_blocker_cooldown_remaining = maxf(0.0, _blocker_cooldown_remaining - delta)
	_refresh_tracking_mark()
	_refresh_sight_request(delta)
	if not _process_committed(delta): _process_request(delta)
	if not velocity.is_zero_approx(): sight.facing = velocity.normalized()
	_update_visual()
	if GameSession.debug_gameplay_draw: queue_redraw()

func _process_committed(delta: float) -> bool:
	match state:
		State.ATTACK_SETUP:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				state = State.DIVE
				_state_timer = dive_seconds
				_dive_hit = false
				_hold_attack_swoop_frame()
			return true
		State.DIVE:
			_move_toward(_aim, dive_speed, delta)
			if not _dive_hit and is_instance_valid(_target) and global_position.distance_to(_target.global_position) <= attack_hit_radius:
				_dive_hit = true
				var direction := velocity.normalized() if not velocity.is_zero_approx() else global_position.direction_to(_target.global_position)
				if _target.apply_damage(DamageInfo.new(attack_damage, self, support.species_id)): _target.apply_force(direction * attack_force)
			if _dive_hit or _state_timer <= 0.0 or global_position.distance_to(_aim) <= attack_hit_radius: _begin_recovery()
			return true
		State.RECOVER:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0: state = State.RECOVERY_TRAVEL
			return true
		State.RECOVERY_TRAVEL:
			_move_toward(_patrol_center, roam_speed, delta)
			if global_position.distance_to(_patrol_center) <= 12.0: _begin_cooldown_patrol()
			return true
	return false

func _process_request(delta: float) -> void:
	if state == State.CHASE and is_instance_valid(_target) and _target.is_alive():
		if _target.status.has_status(&"tracking_mark") or _can_see_with_active_detectors(_target):
			_process_chase(_target, delta)
		else:
			_process_background(delta)
		return
	var request := _select_request()
	var player := request.get("target_actor") as PlayerController if not request.is_empty() else null
	if player != null:
		_target = player
		var marked := StringName(request.get("request_id", "")) == &"tracking_mark"
		var surround := StringName(request.get("request_id", "")) == &"surround_sight"
		if state == State.BLOCKER_POI and _can_chase(player, marked, surround) and _path_to(player.global_position): state = State.CHASE
		if state == State.COOLDOWN_PATROL and _cooldown_remaining > 0.0 and not marked:
			_process_local(delta, State.COOLDOWN_PATROL)
		elif _can_chase(player, marked, surround) or (state in [State.CHASE, State.SEARCH] and (_can_see_with_active_detectors(player))):
			_process_chase(player, delta)
		else:
			_process_background(delta)
		return
	if not request.is_empty():
		_process_investigate(Vector2(request.get("target_position", global_position)), request, delta)
		return
	_target = null
	_process_background(delta)

func _process_background(delta: float) -> void:
	match state:
		State.CHASE:
			_begin_search(_search_point)
			_process_search(delta)
		State.SEARCH: _process_search(delta)
		State.BLOCKER_POI:
			if _blocker_remaining <= 0.0: _begin_poi_travel()
			else: _process_local(delta, State.BLOCKER_POI)
		State.COOLDOWN_PATROL:
			if _cooldown_remaining <= 0.0:
				if is_instance_valid(_target) and _target.is_alive() and (_target.status.has_status(&"tracking_mark") or _can_see_with_active_detectors(_target)):
					_process_chase(_target, delta)
				else:
					_begin_poi_travel()
			else: _process_local(delta, State.COOLDOWN_PATROL)
		_: _process_poi(delta)

func _can_chase(player: PlayerController, marked: bool, surround: bool = false) -> bool:
	return marked or ((surround or sight.can_see(player)) and (_sight_time >= sight_lock_seconds or global_position.distance_to(player.global_position) <= engagement_distance))

func _can_see_with_active_detectors(player: PlayerController) -> bool:
	return sight.can_see(player) or (_surround_sight_active and _surround_sight != null and _surround_sight.can_see(player))

func _process_chase(player: PlayerController, delta: float) -> void:
	state = State.CHASE
	if _can_see_with_active_detectors(player): _search_point = player.global_position
	if global_position.distance_to(player.global_position) <= engagement_distance:
		_begin_attack(player)
		return
	_move_toward(player.global_position, chase_speed, delta)
	var blocker := _blocker_contact()
	if not blocker.is_empty() and _blocker_cooldown_remaining <= 0.0: _begin_blocker_poi(Vector2(blocker.get("position", global_position)))

func _process_investigate(position: Vector2, request: Dictionary, delta: float) -> void:
	state = State.INVESTIGATE
	_move_toward(position, roam_speed, delta)
	if global_position.distance_to(position) <= attack_hit_radius:
		_requests.erase(request)
		_begin_poi_travel()

func _process_search(delta: float) -> void:
	if _search_remaining <= 0.0:
		_begin_poi_travel()
	elif global_position.distance_to(_search_point) > attack_hit_radius:
		_move_toward(_search_point, roam_speed, delta)
	else:
		_process_local(delta, State.SEARCH)

func _process_poi(delta: float) -> void:
	_poi_time -= delta
	if _poi_time <= 0.0 or not is_instance_valid(_poi): _choose_poi()
	var destination := _poi.global_position if is_instance_valid(_poi) else _origin
	if global_position.distance_to(destination) > attack_hit_radius:
		state = State.ROAM
		_move_toward(destination, roam_speed, delta)
		return
	if state not in [State.POI_PATROL, State.POI_IDLE]: _start_local_patrol(destination)
	_process_local(delta, State.POI_PATROL)

func _process_local(delta: float, patrol_state: State) -> void:
	_patrol_timer -= delta
	if _patrol_hover:
		state = State.POI_IDLE if patrol_state == State.POI_PATROL else patrol_state
		velocity = velocity.lerp(Vector2.ZERO, _steering_alpha(delta))
		if _patrol_timer <= 0.0: _choose_local_destination()
		return
	state = patrol_state
	if _patrol_timer <= 0.0 or global_position.distance_to(_patrol_destination) <= 12.0: _choose_local_destination()
	if not _patrol_hover: _move_toward(_patrol_destination, roam_speed, delta)

func _begin_attack(player: PlayerController) -> void:
	state = State.ATTACK_SETUP
	_target = player
	_aim = player.global_position
	_state_timer = telegraph_seconds
	_finishing_attack_animation = false
	_play_attack_from_start()
	player.warn_attack(self, telegraph_seconds)

func _begin_recovery() -> void:
	var player_position := _target.global_position if is_instance_valid(_target) else _aim
	var away := -velocity.normalized()
	if away.is_zero_approx(): away = player_position.direction_to(global_position)
	if away.is_zero_approx(): away = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	_patrol_center = _recovery_point(player_position, away)
	state = State.RECOVER
	_state_timer = recovery_seconds
	_cooldown_remaining = attack_cooldown
	_sight_time = 0.0
	if _dive_hit:
		_finishing_attack_animation = true
		visual.frame = SWOOP_ATTACK_FRAME
		visual.frame_progress = 0.0
		visual.play(&"attack")

func _recovery_point(player_position: Vector2, away: Vector2) -> Vector2:
	for _attempt in max_destination_attempts:
		var angle := deg_to_rad(randf_range(-recovery_angle_variance_degrees, recovery_angle_variance_degrees))
		var candidate := player_position + away.rotated(angle) * recovery_distance
		if _path_to(candidate): return candidate
	return global_position

func _begin_cooldown_patrol() -> void:
	_start_local_patrol(_patrol_center)
	_cooldown_remaining = attack_cooldown
	state = State.COOLDOWN_PATROL

func _begin_search(_position: Vector2) -> void:
	_search_point = global_position
	_search_remaining = search_seconds
	_start_local_patrol(global_position)
	state = State.SEARCH

func _begin_blocker_poi(position: Vector2) -> void:
	_blocker_remaining = blocker_poi_seconds
	_blocker_cooldown_remaining = blocker_poi_recreate_cooldown_seconds
	_start_local_patrol(position)
	state = State.BLOCKER_POI

func _begin_poi_travel() -> void:
	_set_surround_sight_active(false)
	_choose_poi()
	state = State.ROAM

func _refresh_tracking_mark() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as PlayerController
	if player != null and player.status.has_status(&"tracking_mark"):
		_upsert_request(&"tracking_mark", player.global_position, player, tracking_mark_priority, INF, false, player)
		_search_point = player.global_position
		return
	var had_mark := not _find_request(&"tracking_mark").is_empty()
	_remove_request(&"tracking_mark")
	if had_mark and state == State.CHASE and (player == null or not sight.can_see(player)): _begin_search(_search_point)

func _refresh_sight_request(delta: float) -> void:
	var request := _find_request(&"sight")
	var target := request.get("target_actor") as PlayerController if not request.is_empty() else _target
	if target == null or not _can_see_with_active_detectors(target):
		_sight_time = 0.0
		return
	_sight_time += delta
	_search_point = target.global_position
	if sight.can_see(target):
		_upsert_request(&"sight", target.global_position, target, sight_priority, _clock() + sight_request_seconds, true, target)
	if _surround_sight_active and _surround_sight.can_see(target):
		_upsert_request(&"surround_sight", target.global_position, target, surround_sight_priority, _clock() + sight_request_seconds, false, target)

func _on_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController:
		_set_surround_sight_active(true)
		_upsert_request(&"sight", target.global_position, target, sight_priority, _clock() + sight_request_seconds, true, target)

func _on_surround_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController and _surround_sight_active:
		_upsert_request(&"surround_sight", target.global_position, target, surround_sight_priority, _clock() + sight_request_seconds, false, target)

func _on_lost(target: Node2D) -> void:
	if target is PlayerController:
		_remove_request(&"sight")
		_sight_time = 0.0
		if state not in [State.CHASE, State.ATTACK_SETUP, State.DIVE, State.RECOVER, State.RECOVERY_TRAVEL, State.COOLDOWN_PATROL]: _set_surround_sight_active(false)
		if state == State.CHASE and not target.status.has_status(&"tracking_mark"): _begin_search(_search_point)

func _on_surround_lost(target: Node2D) -> void:
	if target is PlayerController: _remove_request(&"surround_sight")

func _setup_surround_sight() -> void:
	_surround_sight = sight.duplicate() as SightSensor
	_surround_sight.name = &"SurroundSight"
	_surround_sight.normal_angle_degrees = 360.0
	_surround_sight.aggravated_angle_degrees = 360.0
	_surround_sight.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(_surround_sight)
	_surround_sight.target_seen.connect(_on_surround_seen)
	_surround_sight.target_lost.connect(_on_surround_lost)

func _set_surround_sight_active(active: bool) -> void:
	if _surround_sight == null or _surround_sight_active == active: return
	_surround_sight_active = active
	_surround_sight.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if not active:
		_surround_sight.current_target = null
		_remove_request(&"surround_sight")

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if event == null or event.priority < sound.minimum_priority: return
	var priority := _sound_priority(event)
	if priority >= 0.0: _upsert_request(StringName("sound_%d" % event.timestamp), event.position, null, priority, _clock() + sound_request_seconds, false, event.source)

func _sound_priority(event: SoundEvent) -> float:
	match event.sound_type:
		&"rattlepod", &"whistle", &"lantern_crystal": return distraction_priority
		&"crystal":
			var effect := event.source as WorldEffectArea
			return snail_priority if effect != null and effect.source_actor is LanternSnail else distraction_priority
	return -1.0

func receive_agitation(data: Dictionary = {}) -> void:
	var position := data.get("position", global_position) as Vector2
	if position == null: position = global_position
	_upsert_request(StringName("distraction_%d" % Time.get_ticks_usec()), position, null, float(data.get("priority", distraction_priority)), _clock() + float(data.get("duration", sound_request_seconds)), false, data.get("source") as Node)

func _choose_poi() -> void:
	var now := _clock()
	var best: Node2D
	var best_age := -INF
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group(&"large_flyer_poi"):
		if not candidate is Node2D or not candidate.is_inside_tree(): continue
		var point := candidate as Node2D
		var last_used := float(_poi_last_used.get(point.get_instance_id(), -INF))
		var age := INF if is_inf(last_used) else now - last_used
		var distance := global_position.distance_to(point.global_position)
		if age > best_age or (is_equal_approx(age, best_age) and distance < best_distance):
			best = point
			best_age = age
			best_distance = distance
	_poi = best
	_poi_time = randf_range(minf(poi_change_min_seconds, poi_change_max_seconds), maxf(poi_change_min_seconds, poi_change_max_seconds))
	if _poi != null: _poi_last_used[_poi.get_instance_id()] = now

func _start_local_patrol(center: Vector2) -> void:
	_patrol_center = center
	_patrol_destination = center
	_patrol_timer = 0.0
	_patrol_hover = false

func _choose_local_destination() -> void:
	_patrol_hover = false
	for _attempt in max_destination_attempts:
		var candidate := _local_candidate()
		if not _valid_local_candidate(candidate): continue
		_patrol_destination = candidate
		_patrol_hover = randf() < local_idle_chance
		_patrol_timer = randf_range(local_idle_min_seconds, local_idle_max_seconds) if _patrol_hover else randf_range(local_destination_refresh_min, local_destination_refresh_max)
		return
	if _path_to(_patrol_center):
		_patrol_destination = _patrol_center
		_patrol_timer = 0.25
	else:
		_patrol_destination = global_position
		_patrol_hover = true
		_patrol_timer = 0.25

func _local_candidate() -> Vector2:
	var forward := velocity.normalized()
	if velocity.length_squared() < 1.0: forward = Vector2.RIGHT.rotated(randf_range(0.0, TAU))
	return global_position + forward.rotated(deg_to_rad(randf_range(-local_direction_variance_degrees, local_direction_variance_degrees))) * randf_range(local_destination_min_distance, local_destination_max_distance)

func _valid_local_candidate(candidate: Vector2) -> bool:
	if candidate.distance_to(_patrol_center) > minf(poi_patrol_radius, poi_inner_flight_radius): return false
	if candidate.distance_to(global_position) < local_destination_min_distance: return false
	var direction := global_position.direction_to(candidate)
	if velocity.length_squared() >= 1.0 and velocity.normalized().dot(direction) < -0.25: return false
	return _path_to(candidate)

func _move_toward(destination: Vector2, speed: float, delta: float) -> void:
	velocity = velocity.lerp(global_position.direction_to(destination) * speed * _flight_speed_multiplier(), _steering_alpha(delta))
	move_and_slide()

func _path_to(candidate: Vector2) -> bool:
	if candidate.is_equal_approx(global_position): return true
	var query := PhysicsRayQueryParameters2D.create(global_position, candidate, flight_blocking_collision_mask)
	query.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _blocker_contact() -> Dictionary:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider is CollisionObject2D and (collider as CollisionObject2D).collision_layer & transparent_blocker_collision_mask != 0: return {"position": collision.get_position()}
	return {}

func _steering_alpha(delta: float) -> float:
	return clampf(local_steering_strength * delta * 60.0, 0.0, 1.0)

func _upsert_request(request_id: StringName, position: Vector2, target: Node2D, priority: float, expires_at: float, requires_sight: bool, source: Node = null) -> void:
	var now := _clock()
	for request in _requests:
		if StringName(request.get("request_id", "")) != request_id: continue
		request.merge({"source": source, "source_id": source.get_instance_id() if source != null else 0, "target_position": position, "target_actor": target, "target_id": target.get_instance_id() if target != null else 0, "base_priority": priority, "last_updated_at": now, "expires_at": expires_at, "requires_sight": requires_sight})
		return
	_requests.append({"request_id": request_id, "source": source, "source_id": source.get_instance_id() if source != null else 0, "target_position": position, "target_actor": target, "target_id": target.get_instance_id() if target != null else 0, "base_priority": priority, "created_at": now, "last_updated_at": now, "expires_at": expires_at, "requires_sight": requires_sight})

func _select_request() -> Dictionary:
	var now := _clock()
	_requests = _requests.filter(func(request: Dictionary) -> bool: return _request_valid(request, now))
	var best: Dictionary
	var best_priority := -INF
	var best_updated := -INF
	for request in _requests:
		var effective := float(request.get("base_priority", 0.0)) - priority_decay_per_second * maxf(0.0, now - float(request.get("last_updated_at", now)))
		var updated := float(request.get("last_updated_at", 0.0))
		if effective > best_priority or (is_equal_approx(effective, best_priority) and updated > best_updated):
			best = request
			best_priority = effective
			best_updated = updated
	return best

func _request_valid(request: Dictionary, now: float) -> bool:
	if float(request.get("expires_at", now)) < now: return false
	var source_id := int(request.get("source_id", 0))
	var target_id := int(request.get("target_id", 0))
	if source_id > 0 and not is_instance_valid(instance_from_id(source_id)): return false
	if target_id > 0 and not is_instance_valid(instance_from_id(target_id)): return false
	var target := request.get("target_actor") as Node2D
	if target != null and (not target.is_inside_tree() or (target.has_method("is_alive") and not target.is_alive())): return false
	return not bool(request.get("requires_sight", false)) or (target != null and sight.can_see(target))

func _find_request(request_id: StringName) -> Dictionary:
	for request in _requests:
		if StringName(request.get("request_id", "")) == request_id: return request
	return {}

func _remove_request(request_id: StringName) -> void:
	_requests = _requests.filter(func(request: Dictionary) -> bool: return StringName(request.get("request_id", "")) != request_id)

func _flight_speed_multiplier() -> float: return support.status.get_multiplier(&"flight_speed")
func _clock() -> float: return float(Time.get_ticks_msec()) / 1000.0

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"idle", IDLE_SHEET, 6, 8.0, true)
	_add_animation(frames, &"see_player", SEE_PLAYER_SHEET, 8, 10.0, true)
	_add_animation(frames, &"attack", ATTACK_SHEET, 11, 8.0, false)
	visual.sprite_frames = frames
	visual.flip_h = true
	visual.play(&"idle")

func _add_animation(frames: SpriteFrames, animation: StringName, sheet: Texture2D, count: int, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(index * 128, 0, 128, 128)
		frames.add_frame(animation, frame)

func _play_attack_from_start() -> void:
	visual.play(&"attack")
	visual.frame = 0
	visual.frame_progress = 0.0

func _hold_attack_swoop_frame() -> void:
	visual.pause()
	visual.frame = SWOOP_ATTACK_FRAME
	visual.frame_progress = 0.0

func _update_visual() -> void:
	if not velocity.is_zero_approx():
		visual.flip_h = velocity.x > 0.0
	if _finishing_attack_animation:
		if visual.is_playing():
			return
		_finishing_attack_animation = false
	if state == State.ATTACK_SETUP:
		return
	if state == State.DIVE:
		_hold_attack_swoop_frame()
		return
	if is_instance_valid(_target) and (state in [State.CHASE, State.RECOVER, State.RECOVERY_TRAVEL, State.COOLDOWN_PATROL] or sight.can_see(_target)):
		if visual.animation != &"see_player": visual.play(&"see_player")
	elif visual.animation != &"idle":
		visual.play(&"idle")

func _draw() -> void:
	if not GameSession.debug_gameplay_draw:
		return
	var state_names := ["ROAM", "POI_PATROL", "POI_IDLE", "INVESTIGATE", "CHASE", "ATTACK_SETUP", "DIVE", "RECOVER", "RECOVERY_TRAVEL", "COOLDOWN_PATROL", "SEARCH", "BLOCKER_POI", "DISABLED_FLIGHT"]
	draw_string(ThemeDB.fallback_font, Vector2(-96.0, -72.0), "State: %s" % state_names[state], HORIZONTAL_ALIGNMENT_CENTER, 192.0, 12, Color(1.0, 0.9, 0.35, 1.0))
	if body_collision == null or body_collision.shape == null:
		return
	if body_collision.shape is RectangleShape2D:
		var size := (body_collision.shape as RectangleShape2D).size
		draw_rect(Rect2(-size * 0.5, size), Color(1.0, 0.2, 0.2, 0.9), false, 2.0)
func apply_damage(info: DamageInfo) -> bool:
	var applied := support.apply_damage(info)
	if applied and support.is_alive() and state not in [State.ATTACK_SETUP, State.DIVE]: _begin_recovery()
	return applied
func apply_force(_force: Vector2) -> void: pass
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func interrupt_action(_reason: StringName) -> bool:
	if state not in [State.ATTACK_SETUP, State.DIVE]: return false
	_begin_recovery()
	return true
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		_origin = global_position
		_reset_transient_ai()
func _reset_transient_ai() -> void:
	_set_surround_sight_active(false)
	state = State.ROAM
	_target = null
	_aim = Vector2.ZERO
	_sight_time = 0.0
	_state_timer = 0.0
	_cooldown_remaining = 0.0
	_search_remaining = 0.0
	_patrol_center = Vector2.ZERO
	_patrol_destination = Vector2.ZERO
	_patrol_timer = 0.0
	_patrol_hover = false
	_blocker_remaining = 0.0
	_blocker_cooldown_remaining = 0.0
	_requests.clear()
	_choose_poi()
func handle_world_out_of_bounds() -> void:
	global_position = _origin
	velocity = Vector2.ZERO
