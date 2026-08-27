class_name GroundTraversalCache2D
extends Node2D

class SurfaceSample:
	extends RefCounted
	var id := -1
	var position := Vector2.ZERO
	var normal := Vector2.UP
	var clearance_valid := true

class TraversalLink:
	extends RefCounted
	var from_id := -1
	var to_id := -1
	var kind: StringName = &"walk"
	var cost := 0.0
	var duration := 0.0
	var launch_velocity := Vector2.ZERO

class TraversalAStar:
	extends AStar2D
	var costs: Dictionary = {}
	var fastest_speed := 1.0

	func _compute_cost(from_id: int, to_id: int) -> float:
		return float(costs.get(_key(from_id, to_id), get_point_position(from_id).distance_to(get_point_position(to_id)) / fastest_speed))

	func _estimate_cost(from_id: int, to_id: int) -> float:
		return get_point_position(from_id).distance_to(get_point_position(to_id)) / fastest_speed

	func _key(from_id: int, to_id: int) -> String:
		return "%d:%d" % [from_id, to_id]

class ProfileGraph:
	extends RefCounted
	var astar := TraversalAStar.new()
	var samples: Array[SurfaceSample] = []
	var links: Dictionary = {}
	var failed_until: Dictionary = {}
	var gravity := 0.0
	var profile_label := ""

const WALK: StringName = &"walk"
const JUMP: StringName = &"jump"
const FALL: StringName = &"fall"

var section: WorldSection
var sample_spacing := 8.0
var terrain_mask := 1
var raw_samples: Array[SurfaceSample] = []
var graphs: Dictionary = {}
var build_count := 0

func configure(owner_section: WorldSection, spacing: float, collision_mask: int) -> void:
	section = owner_section
	sample_spacing = maxf(2.0, spacing)
	terrain_mask = collision_mask

func plan_route(start_position: Vector2, target_position: Vector2, profile: Dictionary) -> Dictionary:
	if section == null or not Rect2(section.global_position, section.section_size).has_point(target_position):
		return {"result": GroundTraversal2D.RouteResult.TARGET_INVALID}
	if raw_samples.is_empty():
		_build_surface_samples(float(profile.get("sample_spacing", sample_spacing)))
	if raw_samples.is_empty():
		return {"result": GroundTraversal2D.RouteResult.START_INVALID}
	var graph := _graph_for(profile)
	_restore_failed_links(graph)
	var start_id := _nearest_sample(graph.samples, start_position, float(profile.get("start_snap_distance", 48.0)))
	if start_id < 0:
		return {"result": GroundTraversal2D.RouteResult.START_INVALID}
	var candidates := graph.samples.duplicate()
	candidates.sort_custom(func(a: SurfaceSample, b: SurfaceSample) -> bool:
		return a.position.distance_squared_to(target_position) < b.position.distance_squared_to(target_position))
	var chosen_path := PackedInt64Array()
	var nearest_target_distance := (candidates[0] as SurfaceSample).position.distance_to(target_position)
	for candidate: SurfaceSample in candidates:
		if candidate.position.distance_to(target_position) > nearest_target_distance + float(profile.get("sample_spacing", sample_spacing)) * 1.5:
			break
		var path := graph.astar.get_id_path(start_id, candidate.id)
		if not path.is_empty():
			chosen_path = path
			break
	if chosen_path.is_empty():
		return {"result": GroundTraversal2D.RouteResult.NO_ROUTE, "last_reachable_position": graph.samples[start_id].position}
	var route: Array[TraversalLink] = []
	for index in range(chosen_path.size() - 1):
		var key := _link_key(int(chosen_path[index]), int(chosen_path[index + 1]))
		var link := graph.links.get(key) as TraversalLink
		if link != null:
			route.append(link)
	return {
		"result": GroundTraversal2D.RouteResult.SUCCESS,
		"route": route,
		"profile_key": _profile_key(profile),
		"projected_target": graph.samples[int(chosen_path[-1])].position,
	}

func mark_link_failed(profile_key: String, link: TraversalLink, cooldown: float) -> void:
	var graph := graphs.get(profile_key) as ProfileGraph
	if graph == null or link == null:
		return
	var key := _link_key(link.from_id, link.to_id)
	graph.failed_until[key] = Time.get_ticks_msec() + int(maxf(0.1, cooldown) * 1000.0)
	if graph.astar.are_points_connected(link.from_id, link.to_id, false):
		graph.astar.disconnect_points(link.from_id, link.to_id, false)
	queue_redraw()

func sample_position(profile_key: String, sample_id: int) -> Vector2:
	var graph := graphs.get(profile_key) as ProfileGraph
	if graph == null or sample_id < 0 or sample_id >= graph.samples.size():
		return Vector2.ZERO
	return graph.samples[sample_id].position

func _build_surface_samples(spacing: float) -> void:
	build_count += 1
	var tilemaps: Dictionary = {}
	for node in section.find_children("*", "TileMapLayer", true, false):
		var tilemap := node as TileMapLayer
		if tilemap != null and tilemap.collision_enabled:
			tilemaps[tilemap.get_instance_id()] = true
	if tilemaps.is_empty():
		return
	var bounds := Rect2(section.global_position, section.section_size)
	var space := get_world_2d().direct_space_state
	var x := bounds.position.x + spacing * 0.5
	while x < bounds.end.x:
		var was_solid := false
		var y := bounds.position.y
		while y <= bounds.end.y:
			var solid := _point_is_tile_terrain(space, Vector2(x, y), tilemaps)
			if solid and not was_solid:
				var ray := PhysicsRayQueryParameters2D.create(Vector2(x, maxf(bounds.position.y, y - spacing)), Vector2(x, y + 0.5), terrain_mask)
				ray.collide_with_areas = false
				var hit := space.intersect_ray(ray)
				var collider := hit.get("collider") as TileMapLayer
				if collider != null and tilemaps.has(collider.get_instance_id()):
					var normal: Vector2 = hit.get("normal", Vector2.UP)
					if normal.dot(Vector2.UP) > 0.1:
						var sample := SurfaceSample.new()
						sample.position = hit.get("position", Vector2(x, y - spacing * 0.5))
						sample.normal = normal
						raw_samples.append(sample)
			was_solid = solid
			y += spacing
		x += spacing
	raw_samples.sort_custom(func(a: SurfaceSample, b: SurfaceSample) -> bool:
		return a.position.x < b.position.x if not is_equal_approx(a.position.x, b.position.x) else a.position.y < b.position.y)
	for index in raw_samples.size():
		raw_samples[index].id = index
	queue_redraw()

func _point_is_tile_terrain(space: PhysicsDirectSpaceState2D, position: Vector2, tilemaps: Dictionary) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = position
	query.collision_mask = terrain_mask
	query.collide_with_areas = false
	for hit in space.intersect_point(query, 32):
		var collider := hit.get("collider") as TileMapLayer
		if collider != null and tilemaps.has(collider.get_instance_id()):
			return true
	return false

func _graph_for(profile: Dictionary) -> ProfileGraph:
	var key := _profile_key(profile)
	var existing := graphs.get(key) as ProfileGraph
	if existing != null:
		return existing
	var graph := ProfileGraph.new()
	graph.gravity = float(profile.get("gravity", 0.0))
	graph.profile_label = "%s walk %.0f jump %.0f gravity %.0f" % [profile.get("profile_id", &"default"), profile.get("walk_speed", 0.0), profile.get("jump_velocity", 0.0), graph.gravity]
	graph.astar.fastest_speed = maxf(float(profile.get("horizontal_jump_speed", 1.0)), float(profile.get("walk_speed", 1.0)))
	for raw: SurfaceSample in raw_samples:
		if raw.normal.dot(Vector2.UP) < cos(float(profile.get("max_walkable_slope", deg_to_rad(50.0)))):
			continue
		if not _shape_clear(raw.position, profile):
			continue
		var sample := SurfaceSample.new()
		sample.id = graph.samples.size()
		sample.position = raw.position
		sample.normal = raw.normal
		graph.samples.append(sample)
		graph.astar.add_point(sample.id, sample.position)
	_build_walk_links(graph, profile)
	_build_air_links(graph, profile)
	graphs[key] = graph
	queue_redraw()
	return graph

func _build_walk_links(graph: ProfileGraph, profile: Dictionary) -> void:
	var maximum_x := float(profile.get("sample_spacing", sample_spacing)) * 1.6
	var maximum_step := float(profile.get("max_step_height", 8.0))
	for from_index in graph.samples.size():
		var from_sample := graph.samples[from_index]
		for to_index in range(from_index + 1, graph.samples.size()):
			var to_sample := graph.samples[to_index]
			var difference := to_sample.position - from_sample.position
			if difference.x > maximum_x:
				break
			if difference.x <= 0.1 or absf(difference.y) > maximum_step + absf(difference.x):
				continue
			if not _shape_sweep_clear(from_sample.position, to_sample.position, profile):
				continue
			_add_link(graph, from_sample.id, to_sample.id, WALK, difference.length() / maxf(1.0, float(profile.get("walk_speed", 1.0))), 0.0, Vector2.ZERO, true)

func _build_air_links(graph: ProfileGraph, profile: Dictionary) -> void:
	var can_jump := bool(profile.get("can_jump", false))
	var can_fall := bool(profile.get("can_fall", false))
	if not can_jump and not can_fall:
		return
	var spacing := float(profile.get("sample_spacing", sample_spacing))
	var gravity := maxf(1.0, float(profile.get("gravity", 1.0)))
	var jump_velocity := maxf(0.0, float(profile.get("jump_velocity", 0.0)))
	var horizontal_speed := maxf(1.0, float(profile.get("horizontal_jump_speed", 1.0)))
	var maximum_time := maxf(0.1, float(profile.get("max_jump_time", 1.5)))
	var walk_degrees: Dictionary = {}
	for link_value in graph.links.values():
		var link := link_value as TraversalLink
		if link.kind == WALK:
			walk_degrees[link.from_id] = int(walk_degrees.get(link.from_id, 0)) + 1
	for from_sample: SurfaceSample in graph.samples:
		if int(walk_degrees.get(from_sample.id, 0)) >= 2:
			continue
		for to_sample: SurfaceSample in graph.samples:
			if from_sample == to_sample:
				continue
			var offset := to_sample.position - from_sample.position
			if absf(offset.x) > horizontal_speed * maximum_time:
				continue
			if can_jump and jump_velocity > 0.0 and absf(offset.x) >= spacing * 0.75:
				var discriminant := jump_velocity * jump_velocity + 2.0 * gravity * offset.y
				if discriminant >= 0.0:
					var duration := (jump_velocity + sqrt(discriminant)) / gravity
					var launch_x := offset.x / maxf(duration, 0.001)
					if duration <= maximum_time and absf(launch_x) <= horizontal_speed:
						var launch := Vector2(launch_x, -jump_velocity)
						if _arc_clear(from_sample.position, duration, launch, gravity, profile):
							_add_link(graph, from_sample.id, to_sample.id, JUMP, duration + 0.5, duration, launch)
			if can_fall and offset.y > spacing:
				var fall_duration := sqrt(2.0 * offset.y / gravity)
				if absf(offset.x) > horizontal_speed * fall_duration:
					continue
				var fall_direction := signf(offset.x)
				if is_zero_approx(fall_direction):
					continue
				var fall_speed := maxf(absf(offset.x) / maxf(fall_duration, 0.001), float(profile.get("walk_speed", 1.0)))
				var fall_launch := Vector2(fall_direction * minf(fall_speed, horizontal_speed), 0.0)
				var fall_arc_start := from_sample.position + Vector2(fall_direction * (float(profile.get("body_width", 0.0)) * 0.5 + float(profile.get("ground_skin", 1.0))), 0.0)
				var estimator: Callable = profile.get("fall_damage_estimator", Callable())
				if estimator.is_valid():
					var damage := float(estimator.call(offset.y, gravity * fall_duration))
					var maximum_damage := float(profile.get("max_health", 1.0)) * float(profile.get("max_safe_fall_health_fraction", 0.1))
					if damage <= maximum_damage and _arc_clear(fall_arc_start, fall_duration, fall_launch, gravity, profile):
						_add_link(graph, from_sample.id, to_sample.id, FALL, fall_duration + 0.25 + damage / maxf(1.0, maximum_damage), fall_duration, fall_launch)

func _add_link(graph: ProfileGraph, from_id: int, to_id: int, kind: StringName, cost: float, duration: float, launch_velocity: Vector2, bidirectional := false) -> void:
	if graph.links.has(_link_key(from_id, to_id)):
		return
	var link := TraversalLink.new()
	link.from_id = from_id
	link.to_id = to_id
	link.kind = kind
	link.cost = cost
	link.duration = duration
	link.launch_velocity = launch_velocity
	var key := _link_key(from_id, to_id)
	graph.links[key] = link
	graph.astar.costs[key] = cost
	graph.astar.connect_points(from_id, to_id, false)
	if bidirectional:
		var reverse := TraversalLink.new()
		reverse.from_id = to_id
		reverse.to_id = from_id
		reverse.kind = kind
		reverse.cost = cost
		reverse.duration = duration
		reverse.launch_velocity = Vector2(-launch_velocity.x, launch_velocity.y)
		var reverse_key := _link_key(to_id, from_id)
		graph.links[reverse_key] = reverse
		graph.astar.costs[reverse_key] = cost
		graph.astar.connect_points(to_id, from_id, false)

func _shape_clear(surface_position: Vector2, profile: Dictionary) -> bool:
	var query := _shape_query(surface_position, profile)
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _shape_sweep_clear(from_surface: Vector2, to_surface: Vector2, profile: Dictionary) -> bool:
	var query := _shape_query(from_surface, profile)
	query.motion = to_surface - from_surface
	var result := get_world_2d().direct_space_state.cast_motion(query)
	return result.is_empty() or result[0] >= 0.999

func _arc_clear(from_surface: Vector2, duration: float, launch: Vector2, gravity: float, profile: Dictionary) -> bool:
	var step_seconds := maxf(0.01, float(profile.get("arc_step_seconds", 0.04)))
	var previous := from_surface
	var elapsed := step_seconds
	while elapsed < duration * 0.92:
		var position := from_surface + launch * elapsed + Vector2.DOWN * 0.5 * gravity * elapsed * elapsed
		if not _shape_sweep_clear(previous, position, profile):
			return false
		previous = position
		elapsed += step_seconds
	return true

func _shape_query(surface_position: Vector2, profile: Dictionary) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = profile.get("body_shape") as Shape2D
	query.transform = Transform2D(float(profile.get("shape_rotation", 0.0)), _shape_center(surface_position, profile))
	query.collision_mask = terrain_mask
	query.collide_with_areas = false
	query.margin = 0.01
	return query

func _shape_center(surface_position: Vector2, profile: Dictionary) -> Vector2:
	return surface_position - Vector2(0.0, float(profile.get("body_bottom", 0.0)) + float(profile.get("ground_skin", 1.0)))

func _nearest_sample(samples: Array[SurfaceSample], position: Vector2, maximum_distance: float) -> int:
	var best_id := -1
	var best_distance := maximum_distance * maximum_distance
	for sample: SurfaceSample in samples:
		var distance := sample.position.distance_squared_to(position)
		if distance <= best_distance:
			best_distance = distance
			best_id = sample.id
	return best_id

func _restore_failed_links(graph: ProfileGraph) -> void:
	var now := Time.get_ticks_msec()
	for key_value in graph.failed_until.keys():
		var key := String(key_value)
		if now < int(graph.failed_until[key]):
			continue
		graph.failed_until.erase(key)
		var link := graph.links.get(key) as TraversalLink
		if link != null and not graph.astar.are_points_connected(link.from_id, link.to_id, false):
			graph.astar.connect_points(link.from_id, link.to_id, false)

func _profile_key(profile: Dictionary) -> String:
	return "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [
		String(profile.get("profile_id", &"default")),
		str(profile.get("body_width", 0.0)),
		str(profile.get("body_bottom", 0.0)),
		str(profile.get("walk_speed", 0.0)),
		str(profile.get("gravity", 0.0)),
		str(profile.get("jump_velocity", 0.0)),
		str(profile.get("horizontal_jump_speed", 0.0)),
		str(profile.get("max_walkable_slope", 0.0)),
		str(profile.get("max_step_height", 0.0)),
		str(profile.get("can_jump", false)),
		str(profile.get("can_fall", false)),
	]

func _link_key(from_id: int, to_id: int) -> String:
	return "%d:%d" % [from_id, to_id]

func _process(_delta: float) -> void:
	if GameSession.debug_gameplay_draw:
		queue_redraw()

func _draw() -> void:
	if not GameSession.debug_gameplay_draw:
		return
	for sample: SurfaceSample in raw_samples:
		draw_circle(to_local(sample.position), 2.0, Color(0.2, 1.0, 0.45, 0.9))
	for graph_value in graphs.values():
		var graph := graph_value as ProfileGraph
		var label_index: int = graphs.values().find(graph_value)
		draw_string(ThemeDB.fallback_font, Vector2(8.0, 18.0 + label_index * 14.0), graph.profile_label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color.WHITE)
		for link_value in graph.links.values():
			var link := link_value as TraversalLink
			var failed := graph.failed_until.has(_link_key(link.from_id, link.to_id))
			var color := Color(1.0, 0.15, 0.15, 0.9) if failed else Color(0.25, 0.8, 1.0, 0.45) if link.kind == WALK else Color(1.0, 0.75, 0.2, 0.6) if link.kind == JUMP else Color(0.7, 0.4, 1.0, 0.6)
			if link.kind == WALK:
				draw_line(to_local(graph.samples[link.from_id].position), to_local(graph.samples[link.to_id].position), color, 1.0)
			else:
				_draw_arc(graph, link, color)

func _draw_arc(graph: ProfileGraph, link: TraversalLink, color: Color) -> void:
	var points := PackedVector2Array()
	var start := graph.samples[link.from_id].position
	var steps := maxi(2, ceili(link.duration / 0.04))
	for index in range(steps + 1):
		var elapsed := link.duration * float(index) / steps
		var position := start + link.launch_velocity * elapsed + Vector2.DOWN * 0.5 * graph.gravity * elapsed * elapsed
		points.append(to_local(position))
	draw_polyline(points, color, 1.0)
	draw_circle(to_local(start), 3.0, color)
	draw_circle(to_local(graph.samples[link.to_id].position), 3.0, color)
