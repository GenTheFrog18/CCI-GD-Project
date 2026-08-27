extends Node

class TraversalProbe:
	extends CharacterBody2D
	var traversal: GroundTraversal2D
	var profile_id: StringName = &"smoke_probe"
	var can_jump := true
	var can_fall := true

	func _init() -> void:
		collision_layer = 4
		collision_mask = 1
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(12.0, 20.0)
		collision.shape = shape
		add_child(collision)
		traversal = GroundTraversal2D.new()
		add_child(traversal)

	func get_ground_traversal_profile() -> Dictionary:
		return {
			"profile_id": profile_id,
			"walk_speed": 90.0,
			"ground_acceleration": 800.0,
			"gravity": 900.0,
			"jump_velocity": 300.0,
			"horizontal_jump_speed": 190.0,
			"max_jump_time": 1.0,
			"max_walkable_slope": deg_to_rad(50.0),
			"max_step_height": 8.0,
			"start_snap_distance": 48.0,
			"can_jump": can_jump,
			"can_fall": can_fall,
			"max_health": 100.0,
			"fall_damage_estimator": estimate_fall_damage,
		}

	func estimate_fall_damage(_height: float, _impact_speed: float) -> float:
		return 0.0

func _ready() -> void:
	var section := preload("res://game/world/sections/graybox_section_base.tscn").instantiate() as WorldSection
	section.slot_id = &"traversal_smoke"
	section.variation_id = &"traversal_smoke_a"
	add_child(section)
	var terrain := section.get_node("Terrain") as TileMapLayer
	for x in range(2, 19):
		terrain.set_cell(Vector2i(x, 30), 0, Vector2i.ZERO)
	for x in range(24, 41):
		terrain.set_cell(Vector2i(x, 30), 0, Vector2i.ZERO)
	for x in range(4, 8):
		terrain.set_cell(Vector2i(x, 28), 0, Vector2i.ZERO)
	var upper := TileMapLayer.new()
	upper.name = "SecondTerrainSource"
	upper.tile_set = terrain.tile_set
	section.add_child(upper)
	for x in range(10, 16):
		upper.set_cell(Vector2i(x, 27), 0, Vector2i.ZERO)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var first_cache := section.get_ground_traversal_cache(8.0, 1)
	var second_cache := section.get_ground_traversal_cache(8.0, 1)
	assert(first_cache == second_cache)

	var probe := TraversalProbe.new()
	probe.position = Vector2(144.0, 469.0)
	section.add_child(probe)
	await get_tree().physics_frame
	var profile := probe.traversal._build_profile()
	var flat := first_cache.plan_route(probe.global_position, Vector2(272.0, 480.0), profile)
	assert(int(flat.result) == GroundTraversal2D.RouteResult.SUCCESS)
	assert(_route_has(flat.route, GroundTraversalCache2D.WALK))
	assert(first_cache.build_count == 1)

	var jump := first_cache.plan_route(Vector2(280.0, 469.0), Vector2(416.0, 480.0), profile)
	assert(int(jump.result) == GroundTraversal2D.RouteResult.SUCCESS)
	assert(_route_has(jump.route, GroundTraversalCache2D.JUMP))
	var graph := first_cache.graphs[String(jump.profile_key)] as GroundTraversalCache2D.ProfileGraph
	assert(_has_surface_near(graph.samples, Vector2(200.0, 432.0)))
	assert(not _has_surface_near(graph.samples, Vector2(72.0, 480.0)))

	var walking_profile := profile.duplicate()
	walking_profile.profile_id = &"walking_only"
	walking_profile.can_jump = false
	walking_profile.can_fall = false
	var unreachable := first_cache.plan_route(Vector2(280.0, 469.0), Vector2(416.0, 480.0), walking_profile)
	assert(int(unreachable.result) == GroundTraversal2D.RouteResult.NO_ROUTE)
	var falling_profile := profile.duplicate()
	falling_profile.profile_id = &"safe_fall"
	falling_profile.can_jump = false
	var fall_route := first_cache.plan_route(Vector2(248.0, 421.0), Vector2(264.0, 480.0), falling_profile)
	assert(int(fall_route.result) == GroundTraversal2D.RouteResult.SUCCESS)
	assert(_route_has(fall_route.route, GroundTraversalCache2D.FALL))
	var unsafe_profile := falling_profile.duplicate()
	unsafe_profile.profile_id = &"unsafe_fall"
	unsafe_profile.fall_damage_estimator = func(_height: float, _speed: float) -> float: return 100.0
	var unsafe_fall := first_cache.plan_route(Vector2(248.0, 421.0), Vector2(264.0, 480.0), unsafe_profile)
	assert(int(unsafe_fall.result) == GroundTraversal2D.RouteResult.NO_ROUTE)

	var other_probe := TraversalProbe.new()
	other_probe.position = Vector2(152.0, 469.0)
	section.add_child(other_probe)
	await get_tree().physics_frame
	var other_profile := other_probe.traversal._build_profile()
	first_cache.plan_route(other_probe.global_position, Vector2(272.0, 480.0), other_profile)
	assert(first_cache.graphs.size() == 4)
	assert(first_cache.build_count == 1)

	assert(probe.traversal.request_move_to(Vector2(272.0, 480.0), &"scripted") == GroundTraversal2D.RouteResult.SUCCESS)
	for _frame in 240:
		probe.traversal.physics_step(1.0 / 60.0)
		await get_tree().physics_frame
		if not probe.traversal.is_active():
			break
	assert(not probe.traversal.is_active())
	assert(probe.global_position.x > 250.0)

	var jump_probe := TraversalProbe.new()
	jump_probe.position = Vector2(280.0, 469.0)
	section.add_child(jump_probe)
	await get_tree().physics_frame
	assert(jump_probe.traversal.request_move_to(Vector2(416.0, 480.0), &"chase") == GroundTraversal2D.RouteResult.SUCCESS)
	var queued_during_jump := false
	for _frame in 240:
		jump_probe.traversal.physics_step(1.0 / 60.0)
		await get_tree().physics_frame
		if jump_probe.traversal.current_action == GroundTraversalCache2D.JUMP and not queued_during_jump:
			var committed_velocity := jump_probe.velocity
			assert(jump_probe.traversal.request_move_to(Vector2(416.0, 480.0), &"chase") == GroundTraversal2D.RouteResult.SUCCESS)
			assert(jump_probe.velocity == committed_velocity)
			queued_during_jump = true
		if queued_during_jump and not jump_probe.traversal.is_active():
			break
	assert(queued_during_jump)
	assert(not jump_probe.traversal.is_active())
	assert(jump_probe.global_position.x > 390.0)

	var blocker := CharacterBody2D.new()
	blocker.collision_layer = 1
	blocker.collision_mask = 0
	blocker.position = Vector2(208.0, 460.0)
	var blocker_collision := CollisionShape2D.new()
	var blocker_shape := RectangleShape2D.new()
	blocker_shape.size = Vector2(20.0, 40.0)
	blocker_collision.shape = blocker_shape
	blocker.add_child(blocker_collision)
	section.add_child(blocker)
	var blocked_probe := TraversalProbe.new()
	blocked_probe.profile_id = &"walking_only"
	blocked_probe.can_jump = false
	blocked_probe.can_fall = false
	blocked_probe.position = Vector2(144.0, 469.0)
	section.add_child(blocked_probe)
	await get_tree().physics_frame
	var failures: Array[int] = []
	blocked_probe.traversal.route_failed.connect(func(result: GroundTraversal2D.RouteResult, _position: Vector2, _reason: StringName): failures.append(result))
	assert(blocked_probe.traversal.request_move_to(Vector2(272.0, 480.0), &"scripted") == GroundTraversal2D.RouteResult.SUCCESS)
	for _frame in 180:
		blocked_probe.traversal.physics_step(1.0 / 60.0)
		await get_tree().physics_frame
		if not failures.is_empty():
			break
	assert(failures == [GroundTraversal2D.RouteResult.TEMPORARILY_BLOCKED])

	print("GROUND_TRAVERSAL_SMOKE_OK")
	get_tree().quit(0)

func _route_has(route: Array, kind: StringName) -> bool:
	for value in route:
		if (value as GroundTraversalCache2D.TraversalLink).kind == kind:
			return true
	return false

func _has_surface_near(samples: Array[GroundTraversalCache2D.SurfaceSample], position: Vector2) -> bool:
	for sample in samples:
		if sample.position.distance_to(position) <= 12.0:
			return true
	return false
