class_name WorldLayer
extends Node2D

@export var layer_id: StringName
@export var slots_root: Node
@export var runtime_root: Node2D
@export var west_spawn: Marker2D
@export var east_spawn: Marker2D
@export var world_bounds := Rect2(0.0, 0.0, 2560.0, 2400.0)

var instantiated_sections: Dictionary = {}
var spawned_by_slot: Dictionary = {}
var active_slot_ids: PackedStringArray = []

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if layer_id.is_empty():
		errors.append("WorldLayer layer_id is blank")
	if slots_root == null:
		errors.append("WorldLayer %s slots_root is missing" % layer_id)
	if runtime_root == null:
		errors.append("WorldLayer %s runtime_root is missing" % layer_id)
	var ids: Dictionary = {}
	for slot in get_slots():
		for error in slot.validate():
			errors.append(error)
		if ids.has(slot.slot_id):
			errors.append("WorldLayer %s duplicate slot_id %s" % [layer_id, slot.slot_id])
		ids[slot.slot_id] = true
	return errors

func get_slots() -> Array[WorldSlot]:
	var result: Array[WorldSlot] = []
	_collect_slots(slots_root, result)
	result.sort_custom(func(a: WorldSlot, b: WorldSlot): return String(a.slot_id) < String(b.slot_id))
	return result

func instantiate_manifest(manifest: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	instantiated_sections.clear()
	spawned_by_slot.clear()
	var section_results: Dictionary = manifest.get("sections", {})
	var placer_results: Dictionary = manifest.get("placers", {})
	for slot in get_slots():
		var section_data: Dictionary = section_results.get(String(slot.slot_id), {})
		var requested_id := StringName(section_data.get("variation_id", ""))
		var scene := slot.select_variation(int(manifest.get("seed", 0)), requested_id)
		if scene == null:
			errors.append("WorldSlot %s cannot resolve a section" % slot.slot_id)
			continue
		var section := scene.instantiate() as WorldSection
		if section == null:
			errors.append("WorldSlot %s scene root is not WorldSection" % slot.slot_id)
			continue
		slot.add_child(section)
		if not requested_id.is_empty() and section.variation_id != requested_id:
			push_warning("WorldSlot %s missing saved variation %s; using fallback %s" % [slot.slot_id, requested_id, section.variation_id])
		instantiated_sections[String(slot.slot_id)] = section
		for error in section.validate():
			errors.append(error)
		var spawned: Array[Node] = []
		for placer in _collect_placers(section):
			placer.restore_state({"resolved_results": placer_results.get(String(placer.persistent_id), [])})
			var previous_count := runtime_root.get_child_count()
			placer.spawn_resolved(runtime_root)
			for child_index in range(previous_count, runtime_root.get_child_count()):
				var child := runtime_root.get_child(child_index)
				child.set_meta(&"owner_slot_id", String(slot.slot_id))
				spawned.append(child)
		spawned_by_slot[String(slot.slot_id)] = spawned
	return errors

func section_at(world_position: Vector2) -> WorldSection:
	for slot in get_slots():
		var section := instantiated_sections.get(String(slot.slot_id)) as WorldSection
		if section == null:
			continue
		var bounds := Rect2(section.global_position + section.camera_bounds.position, section.camera_bounds.size)
		if bounds.has_point(world_position):
			return section
	return null

func slot_for_section(section: WorldSection) -> WorldSlot:
	if section == null:
		return null
	return section.get_parent() as WorldSlot

func update_activation(world_position: Vector2) -> PackedStringArray:
	var current_section := section_at(world_position)
	var current_slot := slot_for_section(current_section)
	var active: Dictionary = {}
	if current_slot != null:
		for slot in get_slots():
			var same_route := slot.route_id == current_slot.route_id
			var neighboring_depth := absi(slot.depth_index - current_slot.depth_index) <= 1
			if same_route and neighboring_depth:
				active[String(slot.slot_id)] = true
			if current_slot.depth_index == 3 and slot.depth_index == 3:
				active[String(slot.slot_id)] = true
	active_slot_ids.clear()
	for slot_id in active:
		active_slot_ids.append(slot_id)
	active_slot_ids.sort()
	for slot_id in spawned_by_slot:
		for node in spawned_by_slot[slot_id]:
			if is_instance_valid(node):
				if node.is_in_group(&"layer_global_actor"):
					node.process_mode = Node.PROCESS_MODE_INHERIT
				else:
					node.process_mode = Node.PROCESS_MODE_INHERIT if active.has(slot_id) else Node.PROCESS_MODE_DISABLED
	return active_slot_ids.duplicate()

func spawn_position(route: StringName, spawn_id: StringName = &"") -> Vector2:
	if not spawn_id.is_empty():
		var requested := find_child(String(spawn_id), true, false) as Marker2D
		if requested != null:
			return requested.global_position
	if route == &"east" and east_spawn != null:
		return east_spawn.global_position
	if west_spawn != null:
		return west_spawn.global_position
	return global_position + Vector2(640.0, 64.0)

func camera_bounds_for(section: WorldSection) -> Rect2:
	if section == null:
		return world_bounds
	var slot := slot_for_section(section)
	if slot == null:
		return world_bounds
	if slot.depth_index == 3:
		return world_bounds
	var route_x := 1280.0 if slot.route_id == "east" else 0.0
	return Rect2(global_position + Vector2(route_x, 0.0), Vector2(1280.0, 2400.0))

func _collect_slots(node: Node, result: Array[WorldSlot]) -> void:
	if node == null:
		return
	for child in node.get_children():
		if child is WorldSlot:
			result.append(child)
		_collect_slots(child, result)

func _collect_placers(node: Node) -> Array[DeterministicPlacer]:
	var result: Array[DeterministicPlacer] = []
	_collect_placers_recursive(node, result)
	result.sort_custom(func(a: DeterministicPlacer, b: DeterministicPlacer): return String(a.persistent_id) < String(b.persistent_id))
	return result

func _collect_placers_recursive(node: Node, result: Array[DeterministicPlacer]) -> void:
	for child in node.get_children():
		if child is DeterministicPlacer:
			result.append(child)
		_collect_placers_recursive(child, result)
