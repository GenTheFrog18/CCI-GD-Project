class_name DeterministicPlacer
extends Marker2D

@export var persistent_id: StringName
@export_range(0.0, 1.0, 0.01) var spawn_chance := 1.0
@export var entries: Array[WorldSpawnEntry] = []
@export_range(1, 16, 1) var minimum_quantity := 1
@export_range(1, 16, 1) var maximum_quantity := 1
@export_storage var spawn_points: Array[Marker2D] = []
@export var allocation_group: StringName
@export var required_allocation := false
@export var spawn_group_id: StringName
@export_range(0, 16, 1) var attack_group_maximum := 0
@export_range(0.0, 5.0, 0.05) var attack_group_spacing := 0.8
@export var facing := 1.0
@export var patrol_bounds := Rect2()

var resolved_results: Array[Dictionary] = []

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var points := _get_spawn_points()
	if persistent_id.is_empty():
		errors.append("DeterministicPlacer persistent_id is blank")
	if entries.is_empty():
		errors.append("DeterministicPlacer %s has no entries" % persistent_id)
	if minimum_quantity > maximum_quantity:
		errors.append("DeterministicPlacer %s quantity range is invalid" % persistent_id)
	for entry in entries:
		if entry == null:
			errors.append("DeterministicPlacer %s has a missing entry" % persistent_id)
			continue
		for error in entry.validate():
			errors.append("DeterministicPlacer %s: %s" % [persistent_id, error])
	return errors

func resolve(run_seed: int, force_active := false) -> Array[Dictionary]:
	resolved_results.clear()
	var points := _get_spawn_points()
	if persistent_id.is_empty() or entries.is_empty() or points.is_empty():
		return resolved_results
	var random := RandomNumberGenerator.new()
	random.seed = hash("%s:%s" % [run_seed, persistent_id])
	if not force_active and random.randf() > spawn_chance:
		return resolved_results
	var quantity := random.randi_range(minimum_quantity, maximum_quantity)
	for _index in quantity:
		var point_index := random.randi_range(0, points.size() - 1)
		var entry := _pick_entry(random)
		if entry == null:
			continue
		var occurrence := 0
		for previous in resolved_results:
			if int(previous.get("spawn_point_index", -1)) == point_index:
				occurrence += 1
		var result_id := "%s:%d" % [persistent_id, point_index]
		if occurrence > 0:
			result_id = "%s:%d:%d" % [persistent_id, point_index, occurrence]
		resolved_results.append({
			"content_id": String(entry.content_id),
			"spawn_point_index": point_index,
			"persistent_id": result_id,
		})
	return resolved_results.duplicate(true)

func spawn_resolved(parent: Node) -> void:
	var points := _get_spawn_points()
	for result in resolved_results:
		var entry := _entry_for_id(StringName(result.get("content_id", "")))
		var point_index := int(result.get("spawn_point_index", -1))
		if entry == null or entry.scene == null or point_index < 0 or point_index >= points.size():
			continue
		var node := entry.scene.instantiate()
		_set_property_if_present(node, &"persistent_id", String(result.get("persistent_id", "")))
		_set_property_if_present(node, &"spawn_group_id", spawn_group_id if not spawn_group_id.is_empty() else persistent_id)
		_set_property_if_present(node, &"nest_position", global_position)
		_set_property_if_present(node, &"attack_group_maximum", attack_group_maximum)
		_set_property_if_present(node, &"attack_group_spacing", attack_group_spacing)
		_set_property_if_present(node, &"item_id", entry.content_id)
		_set_property_if_present(node, &"spawn_position", points[point_index].global_position)
		_set_property_if_present(node, &"patrol_bounds", patrol_bounds)
		_configure_spawned_node(node)
		if node is Node2D and parent is Node2D:
			node.position = (parent as Node2D).to_local(points[point_index].global_position)
			if facing != 0.0:
				node.scale.x = absf(node.scale.x) * signf(facing)
		parent.add_child(node)

func _configure_spawned_node(_node: Node) -> void:
	pass

func capture_state() -> Dictionary:
	return {"resolved_results": resolved_results.duplicate(true)}

func restore_state(data: Dictionary) -> void:
	resolved_results.assign(data.get("resolved_results", []))

func _pick_entry(random: RandomNumberGenerator) -> WorldSpawnEntry:
	var total_weight := 0
	for entry in entries:
		if entry != null:
			total_weight += maxi(1, entry.weight)
	if total_weight <= 0:
		return null
	var roll := random.randi_range(1, total_weight)
	for entry in entries:
		if entry == null:
			continue
		roll -= maxi(1, entry.weight)
		if roll <= 0:
			return entry
	return entries.back()

func _entry_for_id(content_id: StringName) -> WorldSpawnEntry:
	for entry in entries:
		if entry != null and entry.content_id == content_id:
			return entry
	return null

func _set_property_if_present(node: Object, property_name: StringName, value: Variant) -> void:
	for property in node.get_property_list():
		if StringName(property.name) == property_name:
			node.set(property_name, value)
			return

func _get_spawn_points() -> Array[Marker2D]:
	var points: Array[Marker2D] = []
	for child in get_children():
		if child is Marker2D:
			points.append(child)
	return points if not points.is_empty() else spawn_points
