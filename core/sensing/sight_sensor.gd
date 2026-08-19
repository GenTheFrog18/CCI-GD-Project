class_name SightSensor
extends Node2D

signal target_seen(target: Node2D, last_known_position: Vector2)
signal target_lost(target: Node2D)

@export var normal_range := 240.0
@export_range(0.0, 360.0) var normal_angle_degrees := 100.0
@export var aggravated_range := 300.0
@export_range(0.0, 360.0) var aggravated_angle_degrees := 160.0
@export var proximity_range := 32.0
@export var scan_interval := 0.1
@export_flags_2d_physics var obstruction_mask := 257

var aggravated := false
var facing := Vector2.RIGHT
var current_target: Node2D
var last_ray_end := Vector2.ZERO
var last_ray_blocked := false
var _scan_remaining := 0.0
var _debug_was_visible := false

func _ready() -> void:
	_scan_remaining = fmod(float(get_instance_id()), maxf(scan_interval, 0.001))

func _process(delta: float) -> void:
	if GameSession.debug_gameplay_draw or _debug_was_visible:
		_debug_was_visible = GameSession.debug_gameplay_draw
		queue_redraw()
	_scan_remaining -= delta
	if _scan_remaining > 0.0:
		return
	_scan_remaining = maxf(scan_interval, 0.001)
	scan()

func scan() -> Node2D:
	var owner_status := _owner_status()
	if owner_status is StatusController and owner_status.get_multiplier(&"sight_enabled") <= 0.0:
		return null
	var best: Node2D
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group(&"detection_producers"):
		if candidate is not Node2D or candidate == get_parent() or not candidate.is_inside_tree():
			continue
		var target := candidate as Node2D
		if target.has_method("is_combat_protected") and target.is_combat_protected():
			continue
		var distance := global_position.distance_to(_target_detection_position(target))
		if distance < best_distance and can_see(target):
			best = target
			best_distance = distance
	if best != null:
		current_target = best
		target_seen.emit(best, best.global_position)
	elif is_instance_valid(current_target):
		var lost := current_target
		current_target = null
		target_lost.emit(lost)
	else:
		current_target = null
	return best

func can_see(target: Node2D) -> bool:
	if target == null:
		return false
	var owner_status := _owner_status()
	if owner_status is StatusController and owner_status.get_multiplier(&"sight_enabled") <= 0.0:
		return false
	var target_position := _target_detection_position(target)
	var offset := target_position - global_position
	var distance := offset.length()
	var sight_range := aggravated_range if aggravated else normal_range
	var angle := aggravated_angle_degrees if aggravated else normal_angle_degrees
	if distance > sight_range:
		return false
	if distance > proximity_range and distance > 0.0:
		var forward := facing.normalized() if not facing.is_zero_approx() else Vector2.RIGHT
		if forward.dot(offset.normalized()) < cos(deg_to_rad(angle * 0.5)):
			return false
	last_ray_end = target_position
	var query := PhysicsRayQueryParameters2D.create(global_position, target_position, obstruction_mask)
	query.collide_with_areas = true
	if get_parent() is CollisionObject2D:
		query.exclude = [get_parent().get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	last_ray_blocked = not hit.is_empty() and hit.get("collider") != target
	return not last_ray_blocked

func _target_detection_position(target: Node2D) -> Vector2:
	return target.get_detection_origin() if target.has_method("get_detection_origin") else target.global_position

func _owner_status() -> StatusController:
	var actor := get_parent()
	var value = actor.get("status") if actor != null else null
	if value is StatusController:
		return value
	var support := actor.get_node_or_null("EnemySupport") as EnemySupport if actor != null else null
	return support.status if support != null else null

func _draw() -> void:
	if not GameSession.debug_gameplay_draw:
		return
	var sight_range := aggravated_range if aggravated else normal_range
	var angle := aggravated_angle_degrees if aggravated else normal_angle_degrees
	var center_angle := (facing if not facing.is_zero_approx() else Vector2.RIGHT).angle()
	var points := PackedVector2Array()
	for index in 25:
		points.append(Vector2.from_angle(center_angle - deg_to_rad(angle * 0.5) + deg_to_rad(angle) * index / 24.0) * sight_range)
	draw_polyline(points, Color(1.0, 0.75, 0.2, 0.65), 1.0)
	draw_arc(Vector2.ZERO, proximity_range, 0.0, TAU, 24, Color(1.0, 0.3, 0.2, 0.75), 1.0)
	if not last_ray_end.is_zero_approx():
		draw_line(Vector2.ZERO, to_local(last_ray_end), Color.RED if last_ray_blocked else Color.LIME_GREEN, 1.0)
