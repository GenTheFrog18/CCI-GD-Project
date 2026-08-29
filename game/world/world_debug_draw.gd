class_name WorldDebugDraw
extends Node2D

const RANGE_COLOR := Color(0.95, 0.35, 0.9, 0.8)
const RANGE_FILL := Color(0.95, 0.35, 0.9, 0.08)

var world_root: Node2D
var show_bounds := false

func refresh(root: Node2D, bounds_visible := false) -> void:
	var was_visible := show_bounds or GameSession.is_debug_draw_enabled(&"enemy_ranges") or GameSession.is_debug_draw_enabled(&"placer_ranges")
	var root_changed := world_root != root
	var bounds_changed := show_bounds != bounds_visible
	world_root = root
	show_bounds = bounds_visible
	var is_visible := show_bounds or GameSession.is_debug_draw_enabled(&"enemy_ranges") or GameSession.is_debug_draw_enabled(&"placer_ranges")
	if was_visible or is_visible or root_changed or bounds_changed:
		queue_redraw()

func _process(_delta: float) -> void:
	if show_bounds or GameSession.is_debug_draw_enabled(&"enemy_ranges") or GameSession.is_debug_draw_enabled(&"placer_ranges"):
		queue_redraw()

func _draw() -> void:
	if world_root == null:
		return
	if show_bounds and world_root is WorldLayer:
		_draw_world_bounds(world_root as WorldLayer)
	if GameSession.is_debug_draw_enabled(&"enemy_ranges"):
		_draw_enemy_ranges()
	if GameSession.is_debug_draw_enabled(&"placer_ranges"):
		_draw_enemy_placer_ranges()

func _draw_world_bounds(world_layer: WorldLayer) -> void:
	for slot in world_layer.get_slots():
		var section := world_layer.instantiated_sections.get(String(slot.slot_id)) as WorldSection
		if section == null:
			continue
		var color := Color(0.2, 1.0, 0.4, 0.9) if world_layer.active_slot_ids.has(String(slot.slot_id)) else Color(1.0, 0.8, 0.2, 0.45)
		var bounds := Rect2(section.global_position + section.camera_bounds.position, section.camera_bounds.size)
		draw_rect(bounds, color, false, 2.0)
		draw_rect(Rect2(section.global_position + section.entry_clearance.position, section.entry_clearance.size), Color.CYAN, false, 2.0)
		draw_rect(Rect2(section.global_position + section.exit_clearance.position, section.exit_clearance.size), Color.CYAN, false, 2.0)

func _draw_enemy_ranges() -> void:
	for node in get_tree().get_nodes_in_group(&"effect_receivers"):
		if not node is Node2D or node.is_in_group(&"player"):
			continue
		var actor := node as Node2D
		_draw_range_for_actor(actor, _actor_range_center(actor))

func _draw_enemy_placer_ranges() -> void:
	for placer_node in world_root.find_children("*", "DeterministicPlacer", true, false):
		var placer := placer_node as DeterministicPlacer
		if placer == null or not _is_enemy_placer(placer):
			continue
		var centers := _placer_centers(placer)
		for entry in placer.entries:
			if entry == null or entry.scene == null or ContentCatalog.get_enemy(entry.content_id) == null:
				continue
			var preview := entry.scene.instantiate() as Node2D
			if preview == null:
				continue
			for center in centers:
				_draw_range_for_actor(preview, center)
			preview.free()

func _is_enemy_placer(placer: DeterministicPlacer) -> bool:
	if placer is BirdNestPlacer:
		return true
	for entry in placer.entries:
		if entry != null and ContentCatalog.get_enemy(entry.content_id) != null:
			return true
	return false

func _placer_centers(placer: DeterministicPlacer) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for child in placer.get_children():
		if child is Marker2D:
			centers.append((child as Marker2D).global_position)
	if centers.is_empty():
		centers.append(placer.global_position)
	return centers

func _draw_range_for_actor(actor: Node2D, center: Vector2) -> void:
	var bounds: Variant = _property_value(actor, &"patrol_bounds")
	if bounds is Rect2 and (bounds as Rect2).size != Vector2.ZERO:
		var local_center := to_local(center)
		draw_set_transform(local_center, actor.global_rotation, Vector2.ONE)
		draw_rect(bounds, RANGE_FILL, true)
		draw_rect(bounds, RANGE_COLOR, false, 2.0)
		draw_string(ThemeDB.fallback_font, bounds.position + Vector2(4.0, 14.0), "patrol %.0fx%.0f" % [bounds.size.x, bounds.size.y], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, RANGE_COLOR)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var radius_property := &""
	for property_name in [&"roam_distance", &"leash_distance", &"patrol_radius", &"patrol_distance", &"restricted_radius", &"poi_patrol_radius"]:
		if _has_property(actor, property_name):
			radius_property = property_name
			break
	if radius_property.is_empty():
		return
	var radius := maxf(0.0, float(_property_value(actor, radius_property)))
	if radius <= 0.0:
		return
	var local_center := to_local(center)
	draw_circle(local_center, radius, RANGE_FILL)
	draw_arc(local_center, radius, 0.0, TAU, 48, RANGE_COLOR, 2.0)
	draw_string(ThemeDB.fallback_font, local_center + Vector2(4.0, -radius - 4.0), "%s %.0f" % [radius_property, radius], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, RANGE_COLOR)

func _actor_range_center(actor: Node2D) -> Vector2:
	if actor is LargeLayer1Flyer:
		var patrol_center: Variant = _property_value(actor, &"_patrol_center")
		if patrol_center is Vector2 and not (patrol_center as Vector2).is_zero_approx():
			return patrol_center
		var poi: Variant = _property_value(actor, &"_poi")
		if poi is Node2D and is_instance_valid(poi):
			return (poi as Node2D).global_position
	for property_name in [&"_nest", &"_origin"]:
		var value: Variant = _property_value(actor, property_name)
		if value is Vector2:
			return value
	return actor.global_position

func _has_property(object: Object, property_name: StringName) -> bool:
	for property in object.get_property_list():
		if StringName(property.name) == property_name:
			return true
	return false

func _property_value(object: Object, property_name: StringName) -> Variant:
	return object.get(property_name) if _has_property(object, property_name) else null
