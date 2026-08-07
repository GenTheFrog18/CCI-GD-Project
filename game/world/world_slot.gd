class_name WorldSlot
extends Marker2D

@export var slot_id: StringName
@export var layer_id: StringName
@export_enum("west", "east") var route_id := "west"
@export_range(1, 3, 1) var depth_index := 1
@export var variations: Array[PackedScene] = []
@export var fallback_scene: PackedScene

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if slot_id.is_empty():
		errors.append("WorldSlot slot_id is blank")
	if layer_id.is_empty():
		errors.append("WorldSlot %s layer_id is blank" % slot_id)
	if variations.is_empty():
		errors.append("WorldSlot %s has no variations" % slot_id)
	if fallback_scene == null:
		errors.append("WorldSlot %s fallback_scene is missing" % slot_id)
	var variation_ids: Dictionary = {}
	for scene in variations:
		if scene == null:
			errors.append("WorldSlot %s contains a missing variation" % slot_id)
			continue
		var section := scene.instantiate() as WorldSection
		if section == null:
			errors.append("WorldSlot %s variation root is not WorldSection" % slot_id)
			continue
		if section.slot_id != slot_id:
			errors.append("WorldSlot %s contains variation for slot %s" % [slot_id, section.slot_id])
		if variation_ids.has(section.variation_id):
			errors.append("WorldSlot %s duplicate variation_id %s" % [slot_id, section.variation_id])
		variation_ids[section.variation_id] = true
		section.free()
	return errors

func select_variation(run_seed: int, requested_id: StringName = &"") -> PackedScene:
	if not requested_id.is_empty():
		for scene in variations:
			if _variation_id(scene) == requested_id:
				return scene
		return fallback_scene
	var candidates: Array[PackedScene] = []
	var weights: Array[int] = []
	var total_weight := 0
	for scene in variations:
		if scene == null:
			continue
		var section := scene.instantiate() as WorldSection
		if section == null:
			continue
		var weight := maxi(1, section.selection_weight)
		section.free()
		candidates.append(scene)
		weights.append(weight)
		total_weight += weight
	if candidates.is_empty():
		return fallback_scene
	var random := RandomNumberGenerator.new()
	random.seed = hash("%s:%s" % [run_seed, slot_id])
	var roll := random.randi_range(1, total_weight)
	for index in candidates.size():
		roll -= weights[index]
		if roll <= 0:
			return candidates[index]
	return candidates.back()

func _variation_id(scene: PackedScene) -> StringName:
	if scene == null:
		return &""
	var section := scene.instantiate() as WorldSection
	if section == null:
		return &""
	var id := section.variation_id
	section.free()
	return id
