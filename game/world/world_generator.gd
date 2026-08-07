class_name WorldGenerator
extends Node

signal generation_started(total_steps: int)
signal generation_progress(stage: String, completed: int, total: int)
signal generation_finished(manifest: Dictionary)
signal generation_failed(errors: PackedStringArray)

const WORLD_REVISION := 1

@export var layer_scenes: Array[PackedScene] = []

var generation_log: Array[Dictionary] = []

func build_manifest(run_seed: int) -> Dictionary:
	generation_log.clear()
	var manifest := {
		"world_revision": WORLD_REVISION,
		"seed": run_seed,
		"sections": {},
		"placers": {},
	}
	var errors := PackedStringArray()
	var layer_instances: Array[WorldLayer] = []
	var selected_sections: Array[WorldSection] = []
	var placer_records: Array[Dictionary] = []
	var total_steps := maxi(1, layer_scenes.size() * 7 + 2)
	var completed := 0
	generation_started.emit(total_steps)

	var started := Time.get_ticks_usec()
	for layer_scene in layer_scenes:
		if layer_scene == null:
			errors.append("World generator contains a missing layer scene")
			continue
		var layer := layer_scene.instantiate() as WorldLayer
		if layer == null:
			errors.append("Layer scene root is not WorldLayer")
			continue
		layer_instances.append(layer)
		for error in layer.validate():
			errors.append(error)
		completed += 1
		generation_progress.emit("Validate layer pools", completed, total_steps)
		await get_tree().process_frame
	_record_stage("Validate layer pools", started)

	started = Time.get_ticks_usec()
	var stable_ids: Dictionary = {}
	for layer in layer_instances:
		for slot in layer.get_slots():
			var selected := slot.select_variation(run_seed)
			if selected == null:
				errors.append("WorldSlot %s has no selectable variation" % slot.slot_id)
				continue
			var section := selected.instantiate() as WorldSection
			if section == null:
				errors.append("WorldSlot %s selected scene is invalid" % slot.slot_id)
				continue
			selected_sections.append(section)
			for error in section.validate():
				errors.append(error)
			manifest.sections[String(slot.slot_id)] = {
				"layer_id": String(layer.layer_id),
				"variation_id": String(section.variation_id),
				"scene_path": selected.resource_path,
			}
			_validate_special_contract(layer.layer_id, slot, section, errors)
			for placer in layer._collect_placers(section):
				if stable_ids.has(placer.persistent_id):
					errors.append("Duplicate placer ID %s" % placer.persistent_id)
				stable_ids[placer.persistent_id] = true
				for error in placer.validate():
					errors.append(error)
				placer_records.append({"placer": placer, "section": section})
			completed += 1
			generation_progress.emit("Select and validate sections", completed, total_steps)
			await get_tree().process_frame
	_record_stage("Select and validate sections", started)

	started = Time.get_ticks_usec()
	var allocation_groups: Dictionary = {}
	for record in placer_records:
		var placer := record.placer as DeterministicPlacer
		if placer.allocation_group.is_empty():
			continue
		allocation_groups.get_or_add(String(placer.allocation_group), []).append(placer)
	var allocation_winners: Dictionary = {}
	for group_id in allocation_groups:
		var candidates: Array = allocation_groups[group_id]
		candidates.sort_custom(func(a: DeterministicPlacer, b: DeterministicPlacer): return String(a.persistent_id) < String(b.persistent_id))
		var random := RandomNumberGenerator.new()
		random.seed = hash("%s:allocation:%s" % [run_seed, group_id])
		allocation_winners[group_id] = candidates[random.randi_range(0, candidates.size() - 1)]
	completed += 1
	generation_progress.emit("Resolve allocation groups", completed, total_steps)
	await get_tree().process_frame
	_record_stage("Resolve allocation groups", started)

	started = Time.get_ticks_usec()
	for record in placer_records:
		var placer := record.placer as DeterministicPlacer
		var results: Array[Dictionary] = []
		if placer.allocation_group.is_empty():
			results = placer.resolve(run_seed)
		elif allocation_winners.get(String(placer.allocation_group)) == placer:
			results = placer.resolve(run_seed, placer.required_allocation)
		manifest.placers[String(placer.persistent_id)] = results
	completed += 1
	generation_progress.emit("Resolve placers", completed, total_steps)
	await get_tree().process_frame
	_record_stage("Resolve placers", started)

	for section in selected_sections:
		if is_instance_valid(section):
			section.free()
	for layer in layer_instances:
		if is_instance_valid(layer):
			layer.free()

	manifest["generation_log"] = generation_log.duplicate(true)
	if not errors.is_empty():
		manifest["errors"] = errors
		generation_failed.emit(errors)
	else:
		generation_finished.emit(manifest)
	return manifest

func validate_manifest(manifest: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if int(manifest.get("world_revision", -1)) != WORLD_REVISION:
		errors.append("World revision mismatch")
	if not manifest.get("sections", {}) is Dictionary:
		errors.append("World manifest sections are invalid")
	if not manifest.get("placers", {}) is Dictionary:
		errors.append("World manifest placers are invalid")
	return errors

func validate_templates() -> PackedStringArray:
	var errors := PackedStringArray()
	var stable_ids: Dictionary = {}
	for layer_scene in layer_scenes:
		if layer_scene == null:
			errors.append("Missing layer scene")
			continue
		var layer := layer_scene.instantiate() as WorldLayer
		if layer == null:
			errors.append("Layer scene root is not WorldLayer")
			continue
		for error in layer.validate():
			errors.append(error)
		for slot in layer.get_slots():
			for variation in slot.variations:
				if variation == null:
					continue
				var section := variation.instantiate() as WorldSection
				if section == null:
					continue
				for error in section.validate():
					errors.append(error)
				_validate_special_contract(layer.layer_id, slot, section, errors)
				for placer in layer._collect_placers(section):
					if stable_ids.has(placer.persistent_id):
						errors.append("Duplicate placer ID %s" % placer.persistent_id)
					stable_ids[placer.persistent_id] = true
					for error in placer.validate():
						errors.append(error)
				section.free()
		layer.free()
	return errors

func _validate_special_contract(layer_id: StringName, slot: WorldSlot, section: WorldSection, errors: PackedStringArray) -> void:
	if layer_id == &"layer_1" and slot.depth_index == 3 and not section.special_tags.has("crossing"):
		errors.append("%s must provide a crossing" % section.variation_id)
	if layer_id == &"layer_2" and slot.route_id == "east" and slot.depth_index == 2 and not section.special_tags.has("shop"):
		errors.append("%s must provide the optional shop" % section.variation_id)
	if layer_id == &"layer_2" and slot.depth_index == 3 and not section.special_tags.has("gauntlet"):
		errors.append("%s must provide the gauntlet crossing" % section.variation_id)
	if layer_id == &"layer_2" and slot.route_id == "east" and slot.depth_index == 3 and not section.special_tags.has("layer3_entrance"):
		errors.append("%s must provide the Layer 3 entrance" % section.variation_id)
	if layer_id == &"layer_2" and slot.route_id == "east" and slot.depth_index == 3:
		var entrance_count := _count_layer3_entrances(section)
		if entrance_count != 1:
			errors.append("%s must contain exactly one Layer3Entrance" % section.variation_id)

func _count_layer3_entrances(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is Layer3Entrance:
			count += 1
		count += _count_layer3_entrances(child)
	return count

func _record_stage(stage: String, started_usec: int) -> void:
	generation_log.append({
		"stage": stage,
		"duration_ms": float(Time.get_ticks_usec() - started_usec) / 1000.0,
	})
