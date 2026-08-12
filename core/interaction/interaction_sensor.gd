class_name InteractionSensor
extends Node2D

@export var maximum_reach := 72.0
@export var cursor_radius := 16.0
@export_flags_2d_physics var collision_mask := 72
@export_flags_2d_physics var obstruction_mask := 1
@export_range(1, 64, 1) var maximum_results := 32

var last_query_point := Vector2.ZERO
var last_target: Node

func best_target(actor: Node2D = get_parent() as Node2D, cursor: Vector2 = get_global_mouse_position()) -> Node:
	last_target = null
	if actor == null or not is_inside_tree():
		return null
	last_query_point = actor.global_position + (cursor - actor.global_position).limit_length(maximum_reach)
	var shape := CircleShape2D.new()
	shape.radius = cursor_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, last_query_point)
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
	candidates.sort_custom(_sort_candidates)
	last_target = candidates.front() if not candidates.is_empty() else null
	return last_target

func _sort_candidates(a: Node, b: Node) -> bool:
	var a_priority := _priority(a)
	var b_priority := _priority(b)
	if a_priority != b_priority:
		return a_priority > b_priority
	var a_distance := _position(a).distance_squared_to(last_query_point)
	var b_distance := _position(b).distance_squared_to(last_query_point)
	if not is_equal_approx(a_distance, b_distance):
		return a_distance < b_distance
	return a.get_instance_id() < b.get_instance_id()

func _is_obstructed(actor: Node2D, candidate: Node) -> bool:
	if obstruction_mask == 0:
		return false
	var query := PhysicsRayQueryParameters2D.create(actor.global_position, _position(candidate), obstruction_mask)
	query.collide_with_areas = false
	if actor is CollisionObject2D:
		query.exclude = [actor.get_rid()]
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _priority(candidate: Node) -> float:
	var value = candidate.get("interaction_priority")
	return float(value) if value != null else 0.0

func _position(candidate: Node) -> Vector2:
	return (candidate as Node2D).global_position if candidate is Node2D else global_position
