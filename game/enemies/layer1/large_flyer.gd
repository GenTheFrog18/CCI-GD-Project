class_name LargeLayer1Flyer
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }

@export var persistent_id := "large_layer1_flyer"
@export var roam_speed := 65.0
@export var chase_speed := 115.0
@export var dive_speed := 250.0
@export var sight_lock_seconds := 4.0
@export var poi_interval := 15.0
@export var telegraph_seconds := 0.9
@export var attack_damage := 75.0
@export var attack_cooldown := 4.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener
var state := State.MOVE
var _origin := Vector2.ZERO
var _target: PlayerController
var _poi: Node2D
var _aim := Vector2.ZERO
var _sight_time := 0.0
var _poi_time := 0.0
var _timer := 0.0
var _search_point := Vector2.ZERO
var _search_remaining := 0.0

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(_on_lost)
	sound.sound_accepted.connect(_on_sound)
	_choose_poi()

func _physics_process(delta: float) -> void:
	if support.process_disabled_flight(self, delta):
		_target = null
		state = State.MOVE
		return
	_timer = maxf(0.0, _timer - delta)
	_poi_time -= delta
	_search_remaining = maxf(0.0, _search_remaining - delta)
	var player := get_tree().get_first_node_in_group(&"player") as PlayerController
	if player != null and player.status.has_status(&"tracking_mark"):
		_target = player
		_sight_time = sight_lock_seconds
	if _target != null and sight.can_see(_target):
		_sight_time += delta
		_search_point = _target.global_position
	if state == State.ATTACK:
		velocity = Vector2.ZERO if _timer > 0.0 else global_position.direction_to(_aim) * dive_speed * support.status.get_multiplier(&"flight_speed")
		if _target != null and global_position.distance_to(_target.global_position) < 28.0:
			_target.apply_damage(DamageInfo.new(attack_damage, self, support.species_id))
			_target.apply_force(global_position.direction_to(_target.global_position) * 180.0)
			_recover()
	elif _target != null and _sight_time >= sight_lock_seconds:
		if _timer <= 0.0:
			state = State.ATTACK
			_aim = _target.global_position
			_timer = telegraph_seconds
			_target.warn_attack(self, telegraph_seconds)
		else:
			velocity = global_position.direction_to(_target.global_position) * chase_speed * support.status.get_multiplier(&"flight_speed")
	else:
		state = State.MOVE
		if _search_remaining <= 0.0 and (_poi_time <= 0.0 or not is_instance_valid(_poi)): _choose_poi()
		var point := _search_point if _search_remaining > 0.0 else _poi.global_position if is_instance_valid(_poi) else _origin
		velocity = global_position.direction_to(point) * roam_speed * support.status.get_multiplier(&"flight_speed")
	move_and_slide()
	sight.facing = velocity.normalized()

func _on_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController: _target = target

func _on_lost(target: Node2D) -> void:
	_sight_time = 0.0
	_search_point = target.global_position
	_search_remaining = poi_interval
	_target = null

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if event.priority < 8: return
	if _target != null and _target.status.has_status(&"tracking_mark"): return
	_target = null
	_sight_time = 0.0
	_search_point = event.position
	_search_remaining = poi_interval

func _choose_poi() -> void:
	var points := get_tree().get_nodes_in_group(&"large_flyer_poi")
	_poi = points.pick_random() as Node2D if not points.is_empty() else null
	_poi_time = poi_interval

func _recover() -> void:
	state = State.MOVE
	_timer = attack_cooldown
	_sight_time = 0.0

func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(_force: Vector2) -> void: pass
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		_origin = global_position
		state = State.MOVE
		_target = null
		_choose_poi()
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
