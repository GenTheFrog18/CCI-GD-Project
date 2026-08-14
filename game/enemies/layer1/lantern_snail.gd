class_name LanternSnail
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }

@export var persistent_id := "lantern_snail"
@export var move_speed := 18.0
@export var roam_distance := 90.0
@export var trigger_radius := 42.0
@export var telegraph_seconds := 0.8
@export var scream_cooldown := 8.0
@export var scream_radius := 220.0
@export var scream_priority := 9
@export var sound_trigger_radius := 72.0

@onready var support: EnemySupport = $EnemySupport
@onready var sound: SoundListener = $SoundListener
var state := State.MOVE
var _origin := Vector2.ZERO
var _direction := 1.0
var _timer := 0.0
var _cooldown := 0.0
var _surface_normal := Vector2.UP

func _ready() -> void:
	support.persistent_id = persistent_id
	add_to_group(&"light_sources")
	_origin = global_position
	up_direction = _surface_normal
	sound.sound_accepted.connect(func(event: SoundEvent, _direct: bool):
		if global_position.distance_to(event.position) <= sound_trigger_radius:
			receive_agitation({"kind": "sound"})
	)
	support.health.died.connect(_drop_crystal)

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	if state == State.ATTACK:
		velocity = Vector2.ZERO
		if _timer <= 0.0: _scream()
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= trigger_radius:
		receive_agitation({"kind": "proximity"})
	var tangent := Vector2(-_surface_normal.y, _surface_normal.x)
	velocity = tangent * _direction * move_speed * support.status.get_multiplier(&"move_speed") - _surface_normal * 60.0
	move_and_slide()
	for index in get_slide_collision_count():
		var normal := get_slide_collision(index).get_normal().normalized()
		if absf(normal.dot(_surface_normal)) < 0.75 and normal.dot(tangent * _direction) < -0.25:
			_surface_normal = normal
			up_direction = normal
			rotation = normal.angle() + PI * 0.5
			break
	if global_position.distance_to(_origin) >= roam_distance: _direction *= -1.0

func receive_agitation(_data: Dictionary = {}) -> void:
	if _cooldown > 0.0 or state == State.ATTACK: return
	state = State.ATTACK
	_timer = telegraph_seconds
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method("warn_attack"): player.warn_attack(self, telegraph_seconds)

func _scream() -> void:
	var flash := WorldEffectArea.new()
	flash.configure(&"crystal", &"dazzled", 4.0, scream_radius, self, scream_priority, scream_radius * 2.0)
	get_parent().add_child(flash)
	flash.global_position = global_position
	state = State.MOVE
	_cooldown = scream_cooldown

func _drop_crystal(_source: Node) -> void:
	var definition := ContentCatalog.get_item(&"lantern_crystal")
	if definition == null: return
	var drop := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	drop.persistent_id = "%s:crystal" % persistent_id
	drop.configure(definition, {"origin": "enemy_drop"}, self, global_position, Vector2(0, -80))
	get_parent().add_child(drop)

func apply_damage(info: DamageInfo) -> bool:
	var accepted := support.apply_damage(info)
	if accepted: receive_agitation({"kind": "damage"})
	return accepted
func apply_force(force: Vector2) -> void:
	if force.length() > 40.0: receive_agitation({"kind": "impact"})
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		global_position = _origin
		_surface_normal = Vector2.UP
		up_direction = _surface_normal
		rotation = 0.0
		state = State.MOVE
func handle_world_out_of_bounds() -> void:
	global_position = _origin
	_surface_normal = Vector2.UP
	up_direction = _surface_normal
	rotation = 0.0
