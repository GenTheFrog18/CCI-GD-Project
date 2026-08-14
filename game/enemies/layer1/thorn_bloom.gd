class_name ThornBloom
extends StaticBody2D

enum State { IDLE, ATTACK }

@export var persistent_id := "thorn_bloom"
@export var trigger_radius := 55.0
@export var telegraph_seconds := 0.7
@export var reload_seconds := 300.0
@export var needle_damage := 10.0
@export var needle_lifetime := 300.0
@export var needle_speeds: Array[float] = [150.0, 190.0, 230.0]

@onready var support: EnemySupport = $EnemySupport
var state := State.IDLE
var _timer := 0.0
var _loaded := true

func _ready() -> void:
	support.persistent_id = persistent_id

func _process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	if not _loaded and _timer <= 0.0:
		_loaded = true
	if state == State.ATTACK and _timer <= 0.0:
		_fire()
		state = State.IDLE
		_loaded = false
		_timer = reload_seconds
	if _loaded and state == State.IDLE:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and global_position.distance_to(player.global_position) <= trigger_radius:
			_trigger(player)

func receive_agitation(_data: Dictionary = {}) -> void:
	if _loaded and state == State.IDLE: _trigger(get_tree().get_first_node_in_group(&"player"))

func _trigger(player: Node) -> void:
	state = State.ATTACK
	_timer = telegraph_seconds
	if player != null and player.has_method("warn_attack"): player.warn_attack(self, telegraph_seconds)

func _fire() -> void:
	for side in [-1.0, 1.0]:
		for index in 3:
			var needle := ThornNeedle.new()
			get_parent().add_child(needle)
			needle.global_position = global_position + Vector2(0, -10)
			var speed := needle_speeds[index] if index < needle_speeds.size() else 180.0
			needle.configure(self, Vector2(side * speed, -120.0 - index * 35.0), needle_damage, needle_lifetime)

func apply_damage(info: DamageInfo) -> bool:
	var accepted := support.apply_damage(info)
	if accepted: receive_agitation({"kind": "damage"})
	return accepted
func apply_force(force: Vector2) -> void:
	if not force.is_zero_approx(): receive_agitation({"kind": "impact"})
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void: support.restore_state(data); state = State.IDLE
