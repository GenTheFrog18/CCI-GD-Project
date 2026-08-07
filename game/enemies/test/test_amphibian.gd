class_name TestAmphibian
extends CharacterBody2D

enum State { PATROL, ALERT, INVESTIGATE, WAIT, RETURN }

@export var species_id: StringName = &"amphibian"
@export var persistent_id := "test_amphibian"
@export var move_speed := 45.0
@export var gravity := 900.0
@export var patrol_distance := 80.0
@export var wait_seconds := 1.0
@export var sound_reaction_delay := 0.35
@export var fall_damage := 100.0
@export var fall_immune := false

@onready var health: HealthComponent = $HealthComponent

var state := State.PATROL
var _origin := Vector2.ZERO
var _target := Vector2.ZERO
var _patrol_direction := 1.0
var _wait_remaining := 0.0
var _reaction_remaining := 0.0
var _knockback := Vector2.ZERO
var _current_sound_priority := -1
var _current_sound_timestamp := -1

func _ready() -> void:
	_origin = global_position
	add_to_group(&"sound_listeners")
	add_to_group(&"persistent_objects")
	health.damaged.connect(_on_damaged)
	health.died.connect(func(_source: Node):
		SaveManager.mark_destroyed(persistent_id)
		queue_free()
	)

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
		State.INVESTIGATE, State.RETURN:
			var difference := _target.x - global_position.x
			velocity.x = signf(difference) * move_speed
			if absf(difference) < 5.0:
				velocity.x = 0.0
				if state == State.INVESTIGATE:
					state = State.WAIT
					_wait_remaining = wait_seconds
					_set_sound_indicator("")
				else:
					state = State.PATROL
					_current_sound_priority = -1
		State.WAIT:
			velocity.x = 0.0
			_wait_remaining -= delta
			if _wait_remaining <= 0.0:
				state = State.RETURN
				_target = _origin
	velocity += _knockback
	_knockback = Vector2.ZERO
	move_and_slide()

func hear_sound(event: SoundEvent) -> void:
	if global_position.distance_to(event.position) > event.radius:
		return
	var better := event.priority > _current_sound_priority or (event.priority == _current_sound_priority and event.timestamp > _current_sound_timestamp)
	if not better:
		return
	_current_sound_priority = event.priority
	_current_sound_timestamp = event.timestamp
	_target = event.position
	if state != State.ALERT and state != State.INVESTIGATE:
		state = State.ALERT
		_reaction_remaining = sound_reaction_delay
		_set_sound_indicator("!")

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
