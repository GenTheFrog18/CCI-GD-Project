class_name SightSensor
extends Node2D

@export var range := 240.0
@export_flags_2d_physics var collision_mask := 257

func can_see(target: Node2D) -> bool:
	if target == null or global_position.distance_to(target.global_position) > range:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, collision_mask)
	query.collide_with_areas = true
	query.exclude = [get_parent().get_rid()] if get_parent() is CollisionObject2D else []
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target
