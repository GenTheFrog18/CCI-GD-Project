class_name RopeBehavior
extends ItemBehavior

@export var placement_range := 72.0
@export var surface_search_distance := 18.0
@export var maximum_length := 160.0
@export var minimum_length := 16.0
@export_flags_2d_physics var terrain_mask := 1
@export var throw_behavior: DefaultThrowBehavior

var placed_rope_scene := preload("res://game/items/world/placed_rope.tscn")

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.world != null and context.definition != null

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	var placement := find_placement(context)
	if not placement.get("valid", false):
		return ItemActionResult.failed(placement.get("message", "No valid Rope anchor"))
	var rope := placed_rope_scene.instantiate() as PlacedRope
	rope.configure(placement.anchor, placement.length, placement.get("extension_root") as PlacedRope)
	var result := ItemActionResult.completed(1, state)
	result.world_node = rope
	return result

func can_secondary(context: ItemContext, state: Dictionary) -> bool:
	return throw_behavior != null and throw_behavior.can_secondary(context, state)

func secondary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	return throw_behavior.secondary(context, state) if throw_behavior != null else ItemActionResult.failed("Cannot throw here")

func get_preview(context: ItemContext, state: Dictionary) -> Dictionary:
	var placement := find_placement(context)
	placement.kind = &"rope"
	if throw_behavior != null:
		placement.trajectory = throw_behavior.get_preview(context, state).get("points", PackedVector2Array())
	return placement

func find_placement(context: ItemContext) -> Dictionary:
	if context.actor == null or context.actor.global_position.distance_to(context.cursor_position) > placement_range:
		return {"valid": false, "message": "Rope anchor is out of reach", "anchor": context.cursor_position, "length": maximum_length}
	var extension := _find_extension(context)
	if not extension.is_empty():
		var extended := _validate_column(context.actor.get_world_2d().direct_space_state, extension.anchor, context.world_bounds)
		extended.extension_root = extension.root
		return extended
	var anchors: Array[Vector2] = []
	for marker in context.actor.get_tree().get_nodes_in_group(&"rope_anchors"):
		if marker is Node2D and marker.global_position.distance_to(context.cursor_position) <= surface_search_distance:
			anchors.append(marker.global_position)
	var space := context.actor.get_world_2d().direct_space_state
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var query := PhysicsRayQueryParameters2D.create(context.cursor_position, context.cursor_position + direction * surface_search_distance, terrain_mask)
		var hit := space.intersect_ray(query)
		if not hit.is_empty():
			var normal := hit.normal as Vector2
			if normal.y < -0.5:
				anchors.append(hit.position + Vector2(-8.0, -2.0))
				anchors.append(hit.position + Vector2(8.0, -2.0))
			else:
				anchors.append(hit.position + normal * 4.0)
	var best := {"valid": false, "message": "No clear Rope anchor", "anchor": context.cursor_position, "length": maximum_length}
	var best_distance := INF
	for anchor in anchors:
		var candidate := _validate_column(space, anchor, context.world_bounds)
		var cursor_distance := anchor.distance_to(context.cursor_position)
		if candidate.valid and cursor_distance < best_distance:
			best = candidate
			best_distance = cursor_distance
	return best

func _find_extension(context: ItemContext) -> Dictionary:
	var roots: Array[PlacedRope] = []
	var best := {}
	var best_distance := INF
	for candidate in context.actor.get_tree().get_nodes_in_group(&"placed_ropes"):
		if candidate is not PlacedRope:
			continue
		var root := (candidate as PlacedRope).get_chain_root()
		if root in roots:
			continue
		roots.append(root)
		for endpoint in [root.global_position, Vector2(root.global_position.x, root.get_chain_bottom())]:
			var distance := context.cursor_position.distance_to(endpoint)
			if distance <= surface_search_distance and distance < best_distance:
				best = {"anchor": Vector2(root.global_position.x, root.get_chain_bottom()), "root": root}
				best_distance = distance
	return best

func _validate_column(space: PhysicsDirectSpaceState2D, anchor: Vector2, bounds: Rect2) -> Dictionary:
	var down := PhysicsRayQueryParameters2D.create(anchor + Vector2.DOWN * 2.0, anchor + Vector2.DOWN * maximum_length, terrain_mask)
	var floor_hit := space.intersect_ray(down)
	var available := maximum_length
	if not floor_hit.is_empty():
		available = anchor.distance_to(floor_hit.position) - 2.0
	var length := floorf(available / 16.0) * 16.0
	if length < minimum_length:
		return {"valid": false, "message": "Rope has no clear drop", "anchor": anchor, "length": maximum_length}
	if bounds.has_area() and (not bounds.has_point(anchor) or not bounds.has_point(anchor + Vector2.DOWN * length)):
		return {"valid": false, "message": "Rope would leave the world bounds", "anchor": anchor, "length": length}
	var shape := RectangleShape2D.new()
	shape.size = Vector2(4.0, maxf(length - 4.0, 1.0))
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, anchor + Vector2.DOWN * (length * 0.5))
	query.collision_mask = terrain_mask
	query.collide_with_areas = true
	if not space.intersect_shape(query, 1).is_empty():
		return {"valid": false, "message": "Terrain blocks the Rope", "anchor": anchor, "length": length}
	return {"valid": true, "message": "", "anchor": anchor, "length": length}
