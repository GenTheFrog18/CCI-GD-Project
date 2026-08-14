class_name SeniorDiver
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }

@export var persistent_id := "senior_diver"
@export var move_speed := 42.0
@export var gravity := 900.0
@export var restricted_radius := 120.0
@export var grab_range := 26.0
@export var telegraph_seconds := 0.25
@export var lost_seconds := 3.0
@export var trespass_knockback := 180.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
var state := State.IDLE
var _origin := Vector2.ZERO
var _target: PlayerController
var _timer := 0.0
var _lost := 0.0
var _has_sight := false
var _knockback := Vector2.ZERO
var _was_restricted := false

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	add_to_group(&"interactables")
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(func(_target_node: Node2D): _has_sight = false; _lost = lost_seconds)
	$LostItemReturn.add_to_group(&"lost_item_return_marker")

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += gravity * delta
	_timer = maxf(0.0, _timer - delta)
	var inside_restricted := _target != null and _has_sight and GameSession.whistle_tier != &"blue" and global_position.distance_to(_target.global_position) <= restricted_radius
	if inside_restricted and not _was_restricted:
		var away := global_position.direction_to(_target.global_position)
		_target.apply_force(Vector2(away.x * trespass_knockback, -trespass_knockback * 0.35))
	_was_restricted = inside_restricted
	if inside_restricted:
		if state == State.ATTACK:
			velocity.x = 0.0
			if _timer <= 0.0: _grab()
		elif global_position.distance_to(_target.global_position) <= grab_range:
			state = State.ATTACK
			_timer = telegraph_seconds
			_target.warn_attack(self, telegraph_seconds)
		else:
			state = State.MOVE
			velocity.x = signf(_target.global_position.x - global_position.x) * move_speed * support.status.get_multiplier(&"move_speed")
	else:
		if not _has_sight:
			_lost -= delta
		if _lost <= 0.0:
			_target = null
			state = State.IDLE
			velocity.x = signf(_origin.x - global_position.x) * move_speed if absf(_origin.x - global_position.x) > 4.0 else 0.0
	velocity += _knockback
	_knockback = Vector2.ZERO
	move_and_slide()
	sight.facing = Vector2(signf(velocity.x), 0) if absf(velocity.x) > 0.1 else sight.facing

func _on_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController:
		_target = target
		_has_sight = true

func _grab() -> void:
	if _target == null: return
	_target.locks.lock(&"senior_diver_grab")
	_target.confiscate_map_items()
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(_target): _target.locks.unlock(&"senior_diver_grab")
	var world := _find_world_run()
	if world != null: world.request_layer_transition(&"surface", &"west")
	state = State.IDLE
	_target = null

func get_interaction_prompt(_actor: Node) -> String: return "Talk to Senior Diver"
func interact(actor: Node) -> bool:
	if actor is not PlayerController: return false
	actor.item_controller.feedback_requested.emit("Blue rank confirmed." if GameSession.whistle_tier == &"blue" else "The diver warns you not to pass.")
	return true
func _find_world_run() -> WorldRun:
	var node: Node = self
	while node != null:
		if node is WorldRun: return node
		node = node.get_parent()
	return null
func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: _knockback += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data): global_position = _origin; state = State.IDLE
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
