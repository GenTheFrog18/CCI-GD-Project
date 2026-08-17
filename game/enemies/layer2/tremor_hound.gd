class_name TremorHound
extends CharacterBody2D

enum State { PATROL, INVESTIGATE, SEARCH, PREPARE, POUNCE, RECOVER }

@export var persistent_id := ""
@export var patrol_bounds := Rect2(-160, 0, 320, 0)
@export var gravity := 900.0
@export var patrol_speed := 42.0
@export var investigation_speed := 76.0
@export var close_confirmation_radius := 52.0
@export var pounce_prepare_duration := 0.75
@export var pounce_speed := 250.0
@export var pounce_duration := 0.55
@export var pounce_damage := 15.0
@export var pounce_force := 210.0
@export var recovery_duration := 1.2
@export var search_duration := 2.0

@onready var support: EnemySupport = $EnemySupport
@onready var sound: SoundListener = $SoundListener

var state := State.PATROL
var _origin := Vector2.ZERO
var _investigation := Vector2.ZERO
var _score := -INF
var _timer := 0.0
var _pounce_direction := Vector2.RIGHT

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	sound.sound_accepted.connect(_on_sound)

func _physics_process(delta: float) -> void:
	if support.status.has_status(&"electro_stunned"):
		velocity.x = 0.0; velocity.y += gravity * delta; move_and_slide(); return
	_timer = maxf(0.0, _timer - delta)
	if not is_on_floor(): velocity.y += gravity * delta
	var player := get_tree().get_first_node_in_group(&"player") as PlayerController
	match state:
		State.PREPARE:
			velocity.x = 0.0
			if _timer <= 0.0: state = State.POUNCE; _timer = pounce_duration; velocity = _pounce_direction * pounce_speed
		State.POUNCE:
			if _timer <= 0.0: _recover()
		State.RECOVER:
			velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
			if _timer <= 0.0: state = State.PATROL
		_:
			if player != null and not player.is_combat_protected() and global_position.distance_to(player.global_position) <= close_confirmation_radius:
				state = State.PREPARE
				_pounce_direction = global_position.direction_to(player.global_position)
				_timer = pounce_prepare_duration
				player.warn_attack(self, pounce_prepare_duration)
			elif state in [State.INVESTIGATE, State.SEARCH]:
				velocity.x = signf(_investigation.x - global_position.x) * investigation_speed
				if state == State.INVESTIGATE and absf(_investigation.x - global_position.x) < 12.0:
					state = State.SEARCH; _timer = search_duration
				if state == State.SEARCH and _timer <= 0.0: state = State.PATROL; _score = -INF
			else:
				var phase := sin(Time.get_ticks_msec() / 1200.0 + get_instance_id())
				velocity.x = signf(phase) * patrol_speed
	move_and_slide()
	if state == State.POUNCE:
		for index in get_slide_collision_count():
			var body := get_slide_collision(index).get_collider()
			if body == self: continue
			var impact := ImpactData.new(); impact.source_actor = self; impact.source_species_id = support.species_id
			impact.base_damage = pounce_damage; impact.damage_multiplier_min = 1.0; impact.damage_multiplier_max = 1.0
			impact.velocity = velocity; impact.force = _pounce_direction * pounce_force; impact.attack_kind = &"hound_pounce"
			impact.apply_to(body); _recover(); break

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if not support.detectors_enabled(): return
	var distance := global_position.distance_to(event.position)
	var score := event.priority * 100.0 + event.intensity - distance * 0.2
	if score <= _score: return
	_score = score; _investigation = event.position; state = State.INVESTIGATE

func _recover() -> void: state = State.RECOVER; _timer = recovery_duration; velocity.x = 0.0
func interrupt_action(_reason: StringName) -> bool:
	if state != State.PREPARE: return false
	_recover(); return true
func request_interrupt(strength: float, reason: StringName = &"impact") -> bool: return support.request_interrupt(strength, reason)
func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data): state = State.PATROL; _score = -INF
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
