class_name InteractionSensor
extends Area2D

func best_target() -> Node:
	var candidates := get_overlapping_areas()
	candidates.append_array(get_overlapping_bodies())
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
