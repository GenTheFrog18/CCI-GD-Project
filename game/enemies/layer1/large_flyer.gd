class_name LargeLayer1Flyer
extends CharacterBody2D

enum State { ROAM, CHASE, ATTACK_SETUP, DIVE, RECOVER, SEARCH, DISABLED_FLIGHT }

@export var persistent_id := "large_layer1_flyer"
@export var roam_speed := 65.0
@export var chase_speed := 115.0
@export var dive_speed := 250.0
@export var sight_lock_seconds := 4.0
@export var search_seconds := 15.0
@export var poi_interval := 15.0
@export var poi_recency_weight := 1.0
@export var poi_distance_weight := 1.0
@export var telegraph_seconds := 0.9
@export var dive_seconds := 1.5
@export var attack_damage := 75.0
@export var attack_force := 180.0
@export var attack_hit_radius := 28.0
@export var attack_cooldown := 4.0
@export var recovery_seconds := 0.2
@export var priority_decay_per_second := 1.0
@export var tracking_mark_priority := 100.0
@export var snail_priority := 50.0
@export var distraction_priority := 40.0
@export var sight_priority := 20.0
@export var sight_request_seconds := 0.25
@export var sound_request_seconds := 10.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener

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

func _ready() -> void:
	support.persistent_id = persistent_id
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
	if state == State.DISABLED_FLIGHT:
		state = State.ROAM

	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	_state_timer = maxf(0.0, _state_timer - delta)
	_search_remaining = maxf(0.0, _search_remaining - delta)
	_refresh_tracking_mark()
	_refresh_sight_request(delta)
	if _process_committed_state(delta):
		return

	var request := _select_request()
	if request.is_empty():
		_target = null
		_process_roaming(delta)
		return

	var target := request.get("target_actor") as PlayerController
	if target != null:
		_target = target
		var marked := StringName(request.get("request_id", "")) == &"tracking_mark"
		if _cooldown_remaining <= 0.0 and (marked or _sight_time >= sight_lock_seconds):
			_begin_attack(target)
			return
		state = State.CHASE
		velocity = global_position.direction_to(target.global_position) * chase_speed * _flight_speed_multiplier()
		move_and_slide()
	else:
		_target = null
		state = State.SEARCH
		velocity = global_position.direction_to(Vector2(request.target_position)) * roam_speed * _flight_speed_multiplier()
		move_and_slide()
		if global_position.distance_to(Vector2(request.target_position)) <= attack_hit_radius:
			_requests.erase(request)

	sight.facing = velocity.normalized() if not velocity.is_zero_approx() else sight.facing

func _process_committed_state(delta: float) -> bool:
	match state:
		State.ATTACK_SETUP:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				state = State.DIVE
				_state_timer = dive_seconds
				_dive_hit = false
			return true
		State.DIVE:
			velocity = global_position.direction_to(_aim) * dive_speed * _flight_speed_multiplier()
			move_and_slide()
			if not _dive_hit and is_instance_valid(_target) and global_position.distance_to(_target.global_position) <= attack_hit_radius:
				_dive_hit = true
				var direction := velocity.normalized() if not velocity.is_zero_approx() else global_position.direction_to(_target.global_position)
				if _target.apply_damage(DamageInfo.new(attack_damage, self, support.species_id)):
					_target.apply_force(direction * attack_force)
			if _state_timer <= 0.0 or _dive_hit:
				_recover()
			sight.facing = velocity.normalized() if not velocity.is_zero_approx() else sight.facing
			return true
		State.RECOVER:
			velocity = Vector2.ZERO
			if _state_timer <= 0.0:
				state = State.ROAM
			return true
	return false

func _process_roaming(delta: float) -> void:
	if _search_remaining > 0.0:
		state = State.SEARCH
		velocity = global_position.direction_to(_search_point) * roam_speed * _flight_speed_multiplier()
	else:
		state = State.ROAM
		_poi_time -= delta
		if _poi_time <= 0.0 or not is_instance_valid(_poi):
			_choose_poi()
		var destination := _poi.global_position if is_instance_valid(_poi) else _origin
		velocity = global_position.direction_to(destination) * roam_speed * _flight_speed_multiplier()
	move_and_slide()
	sight.facing = velocity.normalized() if not velocity.is_zero_approx() else sight.facing

func _begin_attack(target: PlayerController) -> void:
	state = State.ATTACK_SETUP
	_target = target
	_aim = target.global_position
	_state_timer = telegraph_seconds
	if is_instance_valid(target):
		target.warn_attack(self, telegraph_seconds)

func _recover() -> void:
	state = State.RECOVER
	_state_timer = recovery_seconds
	_cooldown_remaining = attack_cooldown
	_sight_time = 0.0

func _refresh_tracking_mark() -> void:
	var player := get_tree().get_first_node_in_group(&"player") as PlayerController
	if player != null and player.status.has_status(&"tracking_mark"):
		_upsert_request(&"tracking_mark", player.global_position, player, tracking_mark_priority, INF, false, player)
	else:
		_remove_request(&"tracking_mark")

func _refresh_sight_request(delta: float) -> void:
	var request := _find_request(&"sight")
	if request.is_empty():
		return
	var target := request.get("target_actor") as PlayerController
	if target == null or not sight.can_see(target):
		_sight_time = 0.0
		return
	_sight_time += delta
	_search_point = target.global_position
	_upsert_request(&"sight", target.global_position, target, sight_priority, _clock() + sight_request_seconds, true, target)

func _on_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController:
		_upsert_request(&"sight", target.global_position, target, sight_priority, _clock() + sight_request_seconds, true, target)

func _on_lost(target: Node2D) -> void:
	if target is PlayerController:
		_remove_request(&"sight")
		_sight_time = 0.0
		_begin_search(target.global_position)

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if event == null or event.priority < sound.minimum_priority:
		return
	var priority := _sound_priority(event)
	if priority < 0.0:
		return
	_upsert_request(
		StringName("sound_%d" % event.timestamp),
		event.position,
		null,
		priority,
		_clock() + sound_request_seconds,
		false,
		event.source
	)

func _sound_priority(event: SoundEvent) -> float:
	match event.sound_type:
		&"rattlepod", &"whistle", &"lantern_crystal":
			return distraction_priority
		&"crystal":
			var effect := event.source as WorldEffectArea
			return snail_priority if effect != null and effect.source_actor is LanternSnail else distraction_priority
	return -1.0

func receive_agitation(data: Dictionary = {}) -> void:
	var position := data.get("position", global_position) as Vector2
	if position == null:
		position = global_position
	_upsert_request(
		StringName("distraction_%d" % Time.get_ticks_usec()),
		position,
		null,
		float(data.get("priority", distraction_priority)),
		_clock() + float(data.get("duration", sound_request_seconds)),
		false,
		data.get("source") as Node
	)

func _begin_search(position: Vector2) -> void:
	_search_point = position
	_search_remaining = search_seconds
	state = State.SEARCH

func _choose_poi() -> void:
	var now := _clock()
	var best: Node2D
	var best_score := INF
	for candidate in get_tree().get_nodes_in_group(&"large_flyer_poi"):
		if not candidate is Node2D or not candidate.is_inside_tree():
			continue
		var point := candidate as Node2D
		var last_used := float(_poi_last_used.get(point.get_instance_id(), -INF))
		var age := 1000000000.0 if is_inf(last_used) else now - last_used
		var score := -age * poi_recency_weight + global_position.distance_to(point.global_position) * poi_distance_weight
		if score < best_score:
			best_score = score
			best = point
	_poi = best
	_poi_time = poi_interval
	if _poi != null:
		_poi_last_used[_poi.get_instance_id()] = now

func _upsert_request(request_id: StringName, position: Vector2, target: Node2D, priority: float, expires_at: float, requires_sight: bool, source: Node = null) -> void:
	var now := _clock()
	for request in _requests:
		if StringName(request.get("request_id", "")) != request_id:
			continue
		request["source"] = source
		request["source_id"] = source.get_instance_id() if source != null else 0
		request["target_position"] = position
		request["target_actor"] = target
		request["target_id"] = target.get_instance_id() if target != null else 0
		request["base_priority"] = priority
		request["last_updated_at"] = now
		request["expires_at"] = expires_at
		request["requires_sight"] = requires_sight
		return
	_requests.append({
		"request_id": request_id,
		"source": source,
		"source_id": source.get_instance_id() if source != null else 0,
		"target_position": position,
		"target_actor": target,
		"target_id": target.get_instance_id() if target != null else 0,
		"base_priority": priority,
		"created_at": now,
		"last_updated_at": now,
		"expires_at": expires_at,
		"requires_sight": requires_sight,
	})

func _select_request() -> Dictionary:
	var now := _clock()
	_requests = _requests.filter(func(request: Dictionary): return _request_valid(request, now))
	var best: Dictionary
	var best_priority := -INF
	var best_updated := -INF
	for request in _requests:
		var age := maxf(0.0, now - float(request.get("last_updated_at", now)))
		var effective := float(request.get("base_priority", 0.0)) - priority_decay_per_second * age
		var updated := float(request.get("last_updated_at", 0.0))
		if effective > best_priority or (is_equal_approx(effective, best_priority) and updated > best_updated):
			best = request
			best_priority = effective
			best_updated = updated
	return best

func _request_valid(request: Dictionary, now: float) -> bool:
	if float(request.get("expires_at", now)) < now:
		return false
	var source_id := int(request.get("source_id", 0))
	if source_id > 0 and not is_instance_valid(instance_from_id(source_id)):
		return false
	var target_id := int(request.get("target_id", 0))
	if target_id > 0 and not is_instance_valid(instance_from_id(target_id)):
		return false
	var target := request.get("target_actor") as Node2D
	if target != null and not target.is_inside_tree():
		return false
	if target != null and target.has_method("is_alive") and not target.is_alive():
		return false
	if bool(request.get("requires_sight", false)) and (target == null or not sight.can_see(target)):
		return false
	return true

func _find_request(request_id: StringName) -> Dictionary:
	for request in _requests:
		if StringName(request.get("request_id", "")) == request_id:
			return request
	return {}

func _remove_request(request_id: StringName) -> void:
	_requests = _requests.filter(func(request: Dictionary): return StringName(request.get("request_id", "")) != request_id)

func _flight_speed_multiplier() -> float:
	return support.status.get_multiplier(&"flight_speed")

func _clock() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func apply_damage(info: DamageInfo) -> bool:
	return support.apply_damage(info)

func apply_force(_force: Vector2) -> void:
	pass

func apply_status(id: StringName, data: Dictionary = {}) -> bool:
	return support.apply_status(id, data)

func interrupt_action(_reason: StringName) -> bool:
	if state not in [State.ATTACK_SETUP, State.DIVE]:
		return false
	_recover()
	return true

func capture_state() -> Dictionary:
	return support.capture_state()

func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		_origin = global_position
		_reset_transient_ai()

func _reset_transient_ai() -> void:
	state = State.ROAM
	_target = null
	_aim = Vector2.ZERO
	_sight_time = 0.0
	_state_timer = 0.0
	_cooldown_remaining = 0.0
	_search_point = Vector2.ZERO
	_search_remaining = 0.0
	_requests.clear()
	_choose_poi()

func handle_world_out_of_bounds() -> void:
	global_position = _origin
	velocity = Vector2.ZERO
