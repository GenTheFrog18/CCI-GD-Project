class_name InteractionSensor
extends Area2D

func best_target() -> Node:
	var candidates: Array[CollisionObject2D] = []
	for area in get_overlapping_areas():
		candidates.append(area)
	for body in get_overlapping_bodies():
		candidates.append(body)
	var best: Node
	var best_priority := -INF
	for candidate in candidates:
		if not candidate.has_method("interact"):
			continue
		var priority_value = candidate.get("interaction_priority")
		var priority := float(priority_value) if priority_value != null else 0.0
		if priority > best_priority:
			best_priority = priority
			best = candidate
	return best
