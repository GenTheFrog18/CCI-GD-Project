class_name TestAmphibian
extends CharacterBody2D

enum State { PATROL, ALERT, INVESTIGATE, WAIT, RETURN, CHASE, SEARCH }

@export var species_id: StringName = &"amphibian"
@export var persistent_id := "test_amphibian"
@export var move_speed := 45.0
@export var gravity := 900.0
@export var patrol_distance := 80.0
@export var wait_seconds := 1.0
@export var sound_reaction_delay := 0.35
@export var sight_memory_seconds := 10.0
@export var sound_override_while_visible := false
@export var sound_sight_override_priority := 10
@export var fall_damage := 100.0
@export var fall_immune := false

@onready var health: HealthComponent = $HealthComponent
@onready var sight_sensor: SightSensor = $SightSensor
@onready var sound_listener: SoundListener = $SoundListener

var state := State.PATROL
var _origin := Vector2.ZERO
var _target := Vector2.ZERO
var _patrol_direction := 1.0
var _wait_remaining := 0.0
var _reaction_remaining := 0.0
var _search_remaining := 0.0
var _knockback := Vector2.ZERO
var _has_direct_sight := false
var _chasing_sound := false

func _ready() -> void:
	_origin = global_position
	add_to_group(&"persistent_objects")
	health.damaged.connect(_on_damaged)
	health.died.connect(func(_source: Node):
		SaveManager.mark_destroyed(persistent_id)
		queue_free()
	)
	sight_sensor.target_seen.connect(_on_target_seen)
	sight_sensor.target_lost.connect(_on_target_lost)
	sound_listener.sound_accepted.connect(_on_sound_accepted)
	sound_listener.sound_target_lost.connect(_on_sound_target_lost)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	match state:
		State.PATROL:
			velocity.x = _patrol_direction * move_speed
			if absf(global_position.x - _origin.x) >= patrol_distance:
				_patrol_direction *= -1.0
		State.ALERT:
			velocity.x = 0.0
			_reaction_remaining -= delta
			if _reaction_remaining <= 0.0:
				state = State.INVESTIGATE
				_set_sound_indicator("?")
		State.INVESTIGATE, State.RETURN, State.CHASE:
			_move_to_target()
			if absf(_target.x - global_position.x) < 5.0:
				velocity.x = 0.0
				if state == State.INVESTIGATE:
					state = State.WAIT
					_wait_remaining = wait_seconds
					_set_sound_indicator("")
				elif state == State.RETURN:
					state = State.PATROL
					sound_listener.clear_target()
				elif state == State.CHASE and not _has_direct_sight:
					_start_search(sound_listener.search_seconds if _chasing_sound else sight_memory_seconds)
		State.WAIT:
			velocity.x = 0.0
			_wait_remaining -= delta
			if _wait_remaining <= 0.0:
				_return_to_patrol()
		State.SEARCH:
			_move_to_target()
			_search_remaining -= delta
			if _search_remaining <= 0.0:
				_return_to_patrol()
	velocity += _knockback
	_knockback = Vector2.ZERO
	move_and_slide()
	if absf(velocity.x) > 0.01:
		sight_sensor.facing = Vector2(signf(velocity.x), 0.0)
	sight_sensor.aggravated = state == State.CHASE or state == State.SEARCH

func _move_to_target() -> void:
	velocity.x = signf(_target.x - global_position.x) * move_speed

func _on_target_seen(target: Node2D, last_known_position: Vector2) -> void:
	_has_direct_sight = true
	_chasing_sound = false
	_target = last_known_position
	state = State.CHASE
	_search_remaining = sight_memory_seconds
	_set_sound_indicator("!")

func _on_target_lost(_target_node: Node2D) -> void:
	_has_direct_sight = false
	if state == State.CHASE and not _chasing_sound:
		_start_search(sight_memory_seconds)

func _on_sound_accepted(event: SoundEvent, direct: bool) -> void:
	if _has_direct_sight and (not sound_override_while_visible or event.priority < sound_sight_override_priority):
		return
	_target = event.position
	_chasing_sound = direct
	if direct:
		state = State.CHASE
		_set_sound_indicator("!")
	else:
		state = State.ALERT
		_reaction_remaining = sound_reaction_delay
		_set_sound_indicator("!")

func _on_sound_target_lost() -> void:
	if _chasing_sound and not _has_direct_sight:
		_start_search(sound_listener.search_seconds)

func hear_sound(event: SoundEvent) -> void:
	sound_listener.hear_sound(event)

func _start_search(seconds: float) -> void:
	state = State.SEARCH
	_search_remaining = seconds
	_set_sound_indicator("?")

func _return_to_patrol() -> void:
	state = State.RETURN
	_target = _origin
	_chasing_sound = false
	_set_sound_indicator("")

func _set_sound_indicator(symbol: String) -> void:
	$SoundIndicator.text = symbol
	$SoundIndicator.visible = not symbol.is_empty()

func apply_damage(info: DamageInfo) -> bool:
	return health.apply_damage(info, species_id)

func apply_force(force: Vector2) -> void:
	if not health.is_dead:
		_knockback += force

func _on_damaged(_info: DamageInfo) -> void:
	$Visual.color = Color.WHITE
	create_tween().tween_property($Visual, "color", Color(0.45, 0.85, 0.35), 0.12)

func handle_world_out_of_bounds() -> void:
	if not fall_immune:
		apply_damage(DamageInfo.new(fall_damage))
	if not health.is_dead:
		global_position = _origin
		velocity = Vector2.ZERO
		state = State.PATROL

func capture_state() -> Dictionary:
	return {"alive": not health.is_dead, "health": health.capture_state()}

func restore_state(data: Dictionary) -> void:
	if not bool(data.get("alive", true)):
		queue_free()
		return
	health.restore_state(data.get("health", {}))
	global_position = _origin
	velocity = Vector2.ZERO
	state = State.PATROL
