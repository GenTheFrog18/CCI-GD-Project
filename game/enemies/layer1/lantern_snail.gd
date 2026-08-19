class_name LanternSnail
extends CharacterBody2D

const IDLE_SHEET := preload("res://assets/art/enemies/snail/snail_idle.png")
const WALK_SHEET := preload("res://assets/art/enemies/snail/snail_walking.png")
const HIT_SHEET := preload("res://assets/art/enemies/snail/snail_hit.png")

enum State { MOVE, ATTACK }

@export var persistent_id := "lantern_snail"
@export var move_speed := 18.0
@export var roam_distance := 90.0
@export var trigger_radius := 42.0
@export var telegraph_seconds := 0.8
@export var scream_cooldown := 8.0
@export var scream_radius := 220.0
@export var scream_priority := 9
@export var flash_duration := 4.0
@export var sound_trigger_radius := 72.0
@export_range(0.1, 2.0, 0.05) var sprite_scale := 0.65

@onready var support: EnemySupport = $EnemySupport
@onready var sound: SoundListener = $SoundListener
@onready var light: LightSource2D = $LightSource2D
@onready var visual: AnimatedSprite2D = $Visual
var state := State.MOVE
var _origin := Vector2.ZERO
var _direction := 1.0
var _timer := 0.0
var _cooldown := 0.0
var _surface_normal := Vector2.UP
var _hit_remaining := 0.0

func _ready() -> void:
	support.persistent_id = persistent_id
	_setup_visual()
	visual.scale = Vector2.ONE * sprite_scale
	_play_animation(&"walk")
	add_to_group(&"light_sources")
	light.light_radius = 128.0
	light.light_intensity = 0.65
	light.source_type = &"lantern_snail"
	_origin = global_position
	up_direction = _surface_normal
	sound.sound_accepted.connect(func(event: SoundEvent, _direct: bool):
		if global_position.distance_to(event.position) <= sound_trigger_radius:
			receive_agitation({"kind": "sound"})
	)
	support.health.died.connect(_on_died)
	support.health.damaged.connect(func(_info: DamageInfo):
		_hit_remaining = 0.5
		_play_animation(&"hit")
	)

func _on_died(source: Node) -> void:
	light.enabled = false
	_drop_crystal(source)

func _physics_process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	_cooldown = maxf(0.0, _cooldown - delta)
	_hit_remaining = maxf(0.0, _hit_remaining - delta)
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and _cooldown <= 0.0 and global_position.distance_to(player.global_position) <= trigger_radius and state != State.ATTACK:
		receive_agitation({"kind": "proximity"})
	if state == State.ATTACK:
		velocity = Vector2.ZERO
		_play_animation(&"hit")
		if _timer <= 0.0: _scream()
		return
	var tangent := Vector2(-_surface_normal.y, _surface_normal.x)
	_play_animation(&"hit" if _hit_remaining > 0.0 else &"walk")
	velocity = tangent * _direction * move_speed * support.status.get_multiplier(&"move_speed") - _surface_normal * 60.0
	move_and_slide()
	for index in get_slide_collision_count():
		var normal := get_slide_collision(index).get_normal().normalized()
		if absf(normal.dot(_surface_normal)) < 0.75 and normal.dot(tangent * _direction) < -0.25:
			_surface_normal = normal
			up_direction = normal
			rotation = normal.angle() + PI * 0.5
			break
	visual.flip_h = _direction > 0.0
	if global_position.distance_to(_origin) >= roam_distance: _direction *= -1.0

func receive_agitation(_data: Dictionary = {}) -> void:
	if _cooldown > 0.0 or state == State.ATTACK: return
	state = State.ATTACK
	_timer = telegraph_seconds
	var player := get_tree().get_first_node_in_group(&"player")
	if player != null and player.has_method("warn_attack"): player.warn_attack(self, telegraph_seconds)

func _scream() -> void:
	var flash := WorldEffectArea.new()
	var shape := CircleShape2D.new()
	shape.radius = scream_radius
	flash.configure(&"crystal", &"dazzled", flash_duration, shape, self, scream_priority, scream_radius * 2.0)
	flash.global_position = global_position
	get_parent().add_child(flash)
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null and global_position.distance_to(player.global_position) <= scream_radius and player.has_method("apply_status"):
		player.apply_status(&"dazzled", {"duration": flash_duration})
	state = State.MOVE
	_cooldown = scream_cooldown

func _drop_crystal(_source: Node) -> void:
	var definition := ContentCatalog.get_item(&"lantern_crystal")
	if definition == null: return
	var drop := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	drop.persistent_id = "%s:crystal" % persistent_id
	drop.configure(definition, {"origin": "enemy_drop"}, self, global_position + _surface_normal * 12.0, _surface_normal * 80.0)
	drop.set_meta(&"effect_deployed", true)
	get_parent().add_child(drop)

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"idle", IDLE_SHEET, 1, 4.0, true)
	_add_animation(frames, &"walk", WALK_SHEET, 8, 10.0, true)
	_add_animation(frames, &"hit", HIT_SHEET, 7, 10.0, false)
	visual.sprite_frames = frames

func _add_animation(frames: SpriteFrames, animation: StringName, sheet: Texture2D, count: int, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(index * 32, 0, 32, 32)
		frames.add_frame(animation, frame)

func _play_animation(animation: StringName) -> void:
	if visual.animation != animation:
		visual.play(animation)

func apply_damage(info: DamageInfo) -> bool:
	var accepted := support.apply_damage(info)
	if accepted: receive_agitation({"kind": "damage"})
	return accepted
func apply_force(force: Vector2) -> void:
	if force.length() > 40.0: receive_agitation({"kind": "impact"})
func apply_status(id: StringName, data: Dictionary = {}) -> bool:
	if id == &"dazzled":
		return false
	return support.apply_status(id, data)
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
