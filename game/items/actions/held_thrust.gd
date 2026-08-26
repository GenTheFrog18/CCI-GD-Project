class_name HeldThrust
extends Area2D

var movement_multiplier := 0.6
var selected_target: Node
var selected_targets: Array[Node] = []

var _actor: Node2D
var _damage := 1.0
var _force := 40.0
var _extension := 8.0
var _active_remaining := 0.12
var _recovery_remaining := 0.18
var _recovery_duration := 0.18
var _enemy_recovery_seconds := 0.5
var _resolved := false

@onready var visual: Sprite2D = $Visual
@onready var hit_shape: CollisionShape2D = $CollisionShape2D

func configure(
	actor: Node2D,
	texture: Texture2D,
	direction: Vector2,
	damage: float,
	force: float,
	extension: float,
	active_seconds: float,
	recovery_seconds: float,
	enemy_recovery_seconds: float,
	target_mask: int,
	visual_rotation_offset: float,
	speed_multiplier: float
) -> void:
	_actor = actor
	_damage = damage
	_force = force
	_extension = extension
	_active_remaining = active_seconds
	_recovery_remaining = recovery_seconds
	_recovery_duration = recovery_seconds
	_enemy_recovery_seconds = enemy_recovery_seconds
	collision_mask = target_mask
	movement_multiplier = speed_multiplier
	rotation = (direction if not direction.is_zero_approx() else Vector2.RIGHT).angle()
	$Visual.texture = texture
	$Visual.position.x = extension
	$Visual.rotation = visual_rotation_offset
	$CollisionShape2D.position.x = extension

func _ready() -> void:
	monitoring = true

func _physics_process(delta: float) -> void:
	queue_redraw()
	if not _resolved:
		_resolved = true
		_resolve_hit()
	if _active_remaining > 0.0:
		_active_remaining -= delta
		if _active_remaining <= 0.0:
			hit_shape.disabled = true
		return
	_recovery_remaining -= delta
	var ratio := clampf(_recovery_remaining / maxf(_recovery_duration, 0.001), 0.0, 1.0)
	visual.position.x = _extension * ratio
	if _recovery_remaining <= 0.0:
		queue_free()

func _resolve_hit() -> void:
	if _actor == null:
		return
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hit_shape.shape
	query.transform = hit_shape.global_transform
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if _actor is CollisionObject2D:
		query.exclude = [_actor.get_rid()]
	var targets: Array[Node] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var candidate := hit.get("collider") as Node
		if candidate != null and candidate not in targets and _target_priority(candidate) < 3:
			targets.append(candidate)
	targets.sort_custom(_sort_targets)
	if targets.is_empty():
		return
	selected_target = targets.front()
	if _target_priority(selected_target) < 2:
		_apply_target(selected_target)
		return
	for target in targets:
		if _target_priority(target) == 2:
			_apply_target(target)

func _apply_target(target: Node) -> void:
	selected_targets.append(target)
	var is_enemy := target.get_node_or_null("EnemySupport") is EnemySupport
	if target.has_method("receive_multitool"):
		target.receive_multitool(_actor)
		return
	if is_enemy:
		_recovery_remaining = maxf(_recovery_remaining, _enemy_recovery_seconds)
		_recovery_duration = maxf(_recovery_duration, _enemy_recovery_seconds)
	var species = _actor.get("species_id")
	if target.has_method("apply_damage"):
		var info := DamageInfo.new(_damage, _actor, StringName(species) if species != null else &"")
		info.tags = [&"player_melee"]
		target.apply_damage(info)
	if target.has_method("apply_force"):
		target.apply_force(Vector2.RIGHT.rotated(global_rotation) * _force)

func _sort_targets(a: Node, b: Node) -> bool:
	var a_priority := _target_priority(a)
	var b_priority := _target_priority(b)
	if a_priority != b_priority:
		return a_priority < b_priority
	var origin := _actor.global_position if _actor != null else global_position
	var a_distance := origin.distance_squared_to((a as Node2D).global_position) if a is Node2D else INF
	var b_distance := origin.distance_squared_to((b as Node2D).global_position) if b is Node2D else INF
	if not is_equal_approx(a_distance, b_distance):
		return a_distance < b_distance
	return a.get_instance_id() < b.get_instance_id()

func _target_priority(target: Node) -> int:
	if target.has_method("receive_multitool"):
		return 0
	if target.is_in_group(&"multitool_breakable") or target.is_in_group(&"multitool_harvestable"):
		return 1
	if target.has_method("apply_damage"):
		return 2
	return 3

func _draw() -> void:
	if not GameSession.debug_gameplay_draw or hit_shape == null or hit_shape.shape is not RectangleShape2D:
		return
	var size := (hit_shape.shape as RectangleShape2D).size
	draw_rect(Rect2(hit_shape.position - size * 0.5, size), Color(1.0, 0.2, 0.2, 0.75), false, 1.0)
