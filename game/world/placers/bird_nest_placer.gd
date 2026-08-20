class_name BirdNestPlacer
extends DeterministicPlacer

@export_range(1.0, 1000.0, 1.0) var patrol_radius := 160.0

func _configure_spawned_node(node: Node) -> void:
	if node is KnockbackBird:
		node.patrol_radius = patrol_radius
