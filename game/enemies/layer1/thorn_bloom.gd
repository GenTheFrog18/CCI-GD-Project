class_name ThornBloom
extends StaticBody2D

const IDLE_SHEET := preload("res://assets/art/enemies/thorn_bloom/idle.png")
const EXPLODE_SHEET := preload("res://assets/art/enemies/thorn_bloom/explode.png")

enum State { IDLE, EXPLODING, DORMANT }

@export var persistent_id := "thorn_bloom"
@export var trigger_radius := 55.0
@export var telegraph_seconds := 0.7
@export var reload_seconds := 300.0
@export var needle_damage := 10.0
@export var needle_lifetime := 300.0
@export var needle_speeds: Array[float] = [150.0, 190.0, 230.0]
@export var radial_projectile_count := 8
@export var spike_iframe_seconds := 0.35
@export var needle_bleed_duration := 10.0
@export var needle_bleed_cap := 80.0

@onready var support: EnemySupport = $EnemySupport
@onready var visual: AnimatedSprite2D = $Visual
var state := State.IDLE
var _timer := 0.0

func _ready() -> void:
	support.persistent_id = persistent_id
	_setup_visual()
	_set_visual_state()

func _process(delta: float) -> void:
	_timer = maxf(0.0, _timer - delta)
	if state == State.EXPLODING and _timer <= 0.0:
		_fire()
		state = State.DORMANT
		_timer = reload_seconds
		_set_visual_state()
	if state == State.DORMANT and _timer <= 0.0:
		state = State.IDLE
		_set_visual_state()
	if state == State.IDLE:
		var player := get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null and global_position.distance_to(player.global_position) <= trigger_radius:
			_trigger(player)

func receive_agitation(_data: Dictionary = {}) -> void:
	if state == State.IDLE: _trigger(get_tree().get_first_node_in_group(&"player"))

func _trigger(player: Node) -> void:
	state = State.EXPLODING
	_timer = telegraph_seconds
	_set_visual_state()
	if player != null and player.has_method("warn_attack"): player.warn_attack(self, telegraph_seconds)

func _fire() -> void:
	var count := maxi(radial_projectile_count, 1)
	for index in count:
		var needle := ThornNeedle.new()
		get_parent().add_child(needle)
		needle.global_position = global_position + Vector2(0, -10)
		var speed := needle_speeds[index % needle_speeds.size()] if not needle_speeds.is_empty() else 180.0
		needle.configure(self, Vector2.RIGHT.rotated(TAU * index / count) * speed, needle_damage, needle_lifetime, spike_iframe_seconds, needle_bleed_duration, needle_bleed_cap)

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 8.0)
	for index in 6: frames.add_frame(&"idle", _sheet_frame(IDLE_SHEET, index))
	frames.add_animation(&"explode")
	frames.set_animation_speed(&"explode", 10.0)
	for index in 8: frames.add_frame(&"explode", _sheet_frame(EXPLODE_SHEET, index))
	visual.sprite_frames = frames

func _sheet_frame(sheet: Texture2D, index: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = sheet
	frame.region = Rect2(index * 48, 0, 48, 48)
	return frame

func _set_visual_state() -> void:
	if state == State.DORMANT:
		visual.hide()
		visual.stop()
		return
	visual.show()
	visual.play(&"explode" if state == State.EXPLODING else &"idle")

func apply_damage(info: DamageInfo) -> bool:
	var accepted := support.apply_damage(info)
	if accepted: receive_agitation({"kind": "damage"})
	return accepted
func apply_force(force: Vector2) -> void:
	if not force.is_zero_approx(): receive_agitation({"kind": "impact"})
func apply_status(id: StringName, data: Dictionary = {}) -> bool: return support.apply_status(id, data)
func capture_state() -> Dictionary:
	var data := support.capture_state()
	data.thorn_bloom_state = state
	data.thorn_bloom_timer = _timer
	return data

func restore_state(data: Dictionary) -> void:
	if not support.restore_state(data):
		return
	state = clampi(int(data.get("thorn_bloom_state", State.IDLE)), State.IDLE, State.DORMANT)
	_timer = maxf(0.0, float(data.get("thorn_bloom_timer", 0.0)))
	_set_visual_state()
