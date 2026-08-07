class_name DeterministicPlacer
extends Marker2D

@export var persistent_id: StringName
@export_range(0.0, 1.0, 0.01) var spawn_chance := 1.0
@export var scene_pool: Array[PackedScene] = []
@export_range(0, 16, 1) var minimum_quantity := 1
@export_range(0, 16, 1) var maximum_quantity := 1

var resolved_indices: Array[int] = []

func resolve(run_seed: int) -> Array[int]:
	resolved_indices.clear()
	if persistent_id.is_empty() or scene_pool.is_empty():
		return resolved_indices
	var random := RandomNumberGenerator.new()
	random.seed = hash("%s:%s" % [run_seed, persistent_id])
	if random.randf() > spawn_chance:
		return resolved_indices
	var quantity := random.randi_range(minimum_quantity, maximum_quantity)
	for _index in quantity:
		resolved_indices.append(random.randi_range(0, scene_pool.size() - 1))
	return resolved_indices.duplicate()

func spawn_resolved(parent: Node) -> void:
	for index in resolved_indices:
		var node := scene_pool[index].instantiate()
		parent.add_child(node)
		if node is Node2D:
			node.global_position = global_position

func capture_state() -> Dictionary:
	return {"resolved_indices": resolved_indices.duplicate()}

func restore_state(data: Dictionary) -> void:
	resolved_indices.assign(data.get("resolved_indices", []))
