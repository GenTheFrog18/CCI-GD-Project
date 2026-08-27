@tool
class_name InteractionSensor
extends Node2D

@export var maximum_reach := 72.0
@export var query_width := 32.0
@export var priority_tie_distance := 4.0
@export_flags_2d_physics var collision_mask := 72
@export_flags_2d_physics var obstruction_mask := 1
@export_range(1, 64, 1) var maximum_results := 32
@export var show_editor_preview := true

var last_query_point := Vector2.ZERO
var last_query_origin := Vector2.ZERO
var last_target: Node

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and show_editor_preview:
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_preview:
		return
	var half_width := maxf(query_width, 1.0) * 0.5
	var reach := maxf(maximum_reach, 0.0)
	var points := PackedVector2Array([
		Vector2(0.0, -half_width),
		Vector2(reach, -half_width),
		Vector2(reach, half_width),
		Vector2(0.0, half_width),
	])
	draw_colored_polygon(points, Color(0.3, 0.8, 1.0, 0.08))
	points.append(points[0])
	draw_polyline(points, Color(0.3, 0.8, 1.0, 0.8), 1.0)
	draw_line(Vector2(reach, -half_width), Vector2(reach, half_width), Color(0.3, 0.8, 1.0, 0.9), 2.0)

func best_target(actor: Node2D = get_parent() as Node2D, cursor: Vector2 = get_global_mouse_position()) -> Node:
	last_target = null
	if actor == null or not is_inside_tree():
		return null
	last_query_origin = _position(actor)
	last_query_point = last_query_origin + (cursor - last_query_origin).limit_length(maximum_reach)
	var offset := last_query_point - last_query_origin
	var shape := RectangleShape2D.new()
	shape.size = Vector2(maxf(offset.length(), 1.0), query_width)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(offset.angle(), last_query_origin + offset * 0.5)
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if actor is CollisionObject2D:
		query.exclude = [actor.get_rid()]
	var candidates: Array[Node] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query, maximum_results):
		var candidate := hit.get("collider") as Node
		if candidate == null or candidate in candidates or not candidate.has_method("interact"):
			continue
		if _is_obstructed(actor, candidate):
			continue
		candidates.append(candidate)
	candidates.sort_custom(_sort_by_distance)
	if not candidates.is_empty():
		var nearest_distance := _position(candidates.front()).distance_to(last_query_point)
		var contenders := candidates.filter(func(candidate: Node): return _position(candidate).distance_to(last_query_point) <= nearest_distance + priority_tie_distance)
		contenders.sort_custom(_sort_by_priority)
		last_target = contenders.front()
	return last_target

func _sort_by_distance(a: Node, b: Node) -> bool:
	var a_distance := _position(a).distance_to(last_query_point)
	var b_distance := _position(b).distance_to(last_query_point)
	if not is_equal_approx(a_distance, b_distance):
		return a_distance < b_distance
	return a.get_instance_id() < b.get_instance_id()

func _sort_by_priority(a: Node, b: Node) -> bool:
	var a_priority := _priority(a)
	var b_priority := _priority(b)
	if a_priority != b_priority:
		return a_priority > b_priority
	return _sort_by_distance(a, b)

func _is_obstructed(actor: Node2D, candidate: Node) -> bool:
	if obstruction_mask == 0:
		return false
	var query := PhysicsRayQueryParameters2D.create(_position(actor), _position(candidate), obstruction_mask)
	query.collide_with_areas = false
	if actor is CollisionObject2D:
		query.exclude = [actor.get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _priority(candidate: Node) -> float:
	var value = candidate.get("interaction_priority")
	return float(value) if value != null else 0.0

func _position(candidate: Node) -> Vector2:
	var shape := candidate.get_node_or_null("CollisionShape2D") as CollisionShape2D
	return shape.global_position if shape != null else ((candidate as Node2D).global_position if candidate is Node2D else global_position)
