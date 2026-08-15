class_name CaveSpider
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK }

@export var persistent_id := "cave_spider"
@export var move_speed := 52.0
@export var gravity_direction := Vector2.DOWN
@export var attack_range := 240.0
@export var telegraph_seconds := 0.7
@export var cooldown_seconds := 4.0
@export var projectile_speed := 170.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var state := State.IDLE
var _origin := Vector2.ZERO
var _target: PlayerController
var _aim := Vector2.ZERO
var _timer := 0.0
var _flee_position := Vector2.ZERO

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	up_direction = -gravity_direction.normalized()
	sight.target_seen.connect(_on_seen)
	sound.sound_accepted.connect(_on_sound)

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	var light := _nearest_light()
	if light != null:
		_target = null
		_origin = global_position + light.global_position.direction_to(global_position) * 120.0
	if state == State.ATTACK:
		velocity = Vector2.ZERO
		sprite.play(&"shoot")
		if _timer <= 0.0: _fire()
	elif _target != null and global_position.distance_to(_target.global_position) <= attack_range and sight.can_see(_target):
		state = State.ATTACK
		_aim = _target.global_position
		_timer = telegraph_seconds
		_target.warn_attack(self, telegraph_seconds)
	else:
		state = State.MOVE
		sprite.play(&"walk")
		var tangent := Vector2(-gravity_direction.y, gravity_direction.x)
		var destination := _target.global_position if _target != null else _origin
		velocity = tangent * signf(tangent.dot(destination - global_position)) * move_speed * support.status.get_multiplier(&"move_speed")
		velocity += gravity_direction.normalized() * 80.0
	move_and_slide()
	if not is_zero_approx(velocity.x): sprite.flip_h = velocity.x < 0.0
	sight.facing = velocity.normalized()

func _nearest_light() -> Node2D:
	var best: Node2D
	var best_distance := attack_range
	for node in get_tree().get_nodes_in_group(&"light_sources"):
		if node is not Node2D or node == self or (node is CanvasItem and not node.visible): continue
		var distance := global_position.distance_to(node.global_position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best

func _on_seen(target: Node2D, _position: Vector2) -> void:
	if target is PlayerController: _target = target

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if event.priority >= 8:
		_target = null
		_origin = global_position + global_position.direction_to(event.position) * -120.0

func _fire() -> void:
	var projectile := preload("res://game/projectiles/projectile.tscn").instantiate() as Projectile
	var impact := ImpactData.new()
	impact.source_actor = self
	impact.source_species_id = support.species_id
	impact.base_damage = 3.0
	impact.max_hits = 1
	impact.status_effects = [
		{"effect_id": &"spider_slow", "duration": 3.0},
		{"effect_id": &"poison", "duration": 10.0},
		{"effect_id": &"tracking_mark", "duration": 20.0},
	]
	projectile.configure(impact, global_position.direction_to(_aim) * projectile_speed, preload("res://assets/art/enemies/cave_spider/projectile.png"))
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	state = State.IDLE
	_timer = cooldown_seconds

func apply_damage(info: DamageInfo) -> bool: return support.apply_damage(info)
func apply_force(force: Vector2) -> void: velocity += support.apply_force(force)
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary: return support.capture_state()
func restore_state(data: Dictionary) -> void:
	if support.restore_state(data): global_position = _origin; state = State.IDLE
func handle_world_out_of_bounds() -> void: global_position = _origin; velocity = Vector2.ZERO
