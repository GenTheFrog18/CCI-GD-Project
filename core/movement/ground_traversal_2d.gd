class_name GroundTraversal2D
extends Node2D

enum RouteResult { SUCCESS, NO_ROUTE, TARGET_INVALID, START_INVALID, TEMPORARILY_BLOCKED }

signal route_completed
signal route_failed(result: RouteResult, last_reachable_position: Vector2, failure_reason: StringName)
signal action_changed(action: StringName)

@export var enabled := true
@export_flags_2d_physics var terrain_collision_mask := 1
@export_range(2.0, 64.0, 1.0) var sample_spacing := 8.0
@export_range(0.05, 2.0, 0.05) var grounded_replan_interval := 0.35
@export_range(0.1, 5.0, 0.1) var route_failure_cooldown := 0.75
@export_range(0.05, 2.0, 0.05) var blocked_timeout := 0.4
@export_range(0.0, 1.0, 0.01) var max_safe_fall_health_fraction := 0.1

var body: CharacterBody2D
var cache: GroundTraversalCache2D
var current_action: StringName = &"inactive"
var _projected_target := Vector2.ZERO
var _profile: Dictionary = {}
var _profile_key := ""
var _route: Array[GroundTraversalCache2D.TraversalLink] = []
var _route_index := 0
var _target := Vector2.ZERO
var _reason: StringName = &"scripted"
var _active := false
var _committed := false
var _became_airborne := false
var _replan_remaining := 0.0
var _blocked_remaining := 0.0
var _last_distance := INF
var _pending_request := false
var _pending_target := Vector2.ZERO
var _pending_reason: StringName
var _last_failure_reason: StringName
var _air_elapsed := 0.0
var _launch_elapsed := 0.0

func _ready() -> void:
	body = get_parent() as CharacterBody2D
	if body == null:
		push_error("GroundTraversal2D parent must be CharacterBody2D")
		enabled = false

func request_move_to(target_position: Vector2, movement_reason: StringName = &"scripted") -> RouteResult:
	if not enabled or body == null:
		return RouteResult.START_INVALID
	if _committed:
		_pending_request = true
		_pending_target = target_position
		_pending_reason = movement_reason
		return RouteResult.SUCCESS
	if _active and movement_reason == _reason and target_position.distance_to(_target) < sample_spacing and _replan_remaining > 0.0:
		return RouteResult.SUCCESS
	_target = target_position
	_reason = movement_reason
	return _plan()

func request_random_move(movement_reason: StringName = &"roam", minimum_distance := 24.0) -> RouteResult:
	if not enabled or body == null:
		return RouteResult.START_INVALID
	cache = _resolve_cache()
	if cache == null:
		return RouteResult.START_INVALID
	_profile = _build_profile()
	if _profile.is_empty():
		return RouteResult.START_INVALID
	var target := cache.random_target(_profile, body.global_position, minimum_distance)
	if target == Vector2.INF:
		return RouteResult.NO_ROUTE
	_target = target
	_reason = movement_reason
	return _plan()

func cancel(stop_horizontal_velocity := false) -> void:
	_active = false
	_committed = false
	_became_airborne = false
	_pending_request = false
	_route.clear()
	_route_index = 0
	_set_action(&"inactive")
	if stop_horizontal_velocity and body != null:
		body.velocity.x = 0.0
	queue_redraw()

func is_active() -> bool:
	return _active

func get_projected_target() -> Vector2:
	return _projected_target

func physics_step(delta: float) -> void:
	if not _active or body == null:
		return
	_replan_remaining = maxf(0.0, _replan_remaining - delta)
	if _route_index >= _route.size():
		_complete()
		return
	var link := _route[_route_index]
	match link.kind:
		GroundTraversalCache2D.WALK:
			_process_walk(link, delta)
		GroundTraversalCache2D.JUMP, GroundTraversalCache2D.FALL:
			_process_air(link, delta)
	queue_redraw()

func _plan(report_failure := true) -> RouteResult:
	cache = _resolve_cache()
	if cache == null:
		return _fail(RouteResult.START_INVALID, &"section_missing") if report_failure else RouteResult.START_INVALID
	_profile = _build_profile()
	if _profile.is_empty():
		return _fail(RouteResult.START_INVALID, &"profile_missing") if report_failure else RouteResult.START_INVALID
	var result := cache.plan_route(body.global_position, _target, _profile)
	var route_result := int(result.get("result", RouteResult.NO_ROUTE)) as RouteResult
	if route_result != RouteResult.SUCCESS:
		return _fail(route_result, &"no_route", result.get("last_reachable_position", body.global_position)) if report_failure else route_result
	_profile_key = String(result.get("profile_key", ""))
	var projected_target: Variant = result.get("projected_target", _target)
	_projected_target = projected_target if projected_target is Vector2 else _target
	_route.clear()
	for link in result.get("route", []):
		_route.append(link as GroundTraversalCache2D.TraversalLink)
	_route_index = 0
	_active = true
	_committed = false
	_last_failure_reason = &""
	_replan_remaining = grounded_replan_interval
	_blocked_remaining = blocked_timeout
	_last_distance = INF
	_set_action(&"walk" if not _route.is_empty() else &"complete")
	return RouteResult.SUCCESS

func _build_profile() -> Dictionary:
	if not body.has_method("get_ground_traversal_profile"):
		push_error("GroundTraversal2D host needs get_ground_traversal_profile()")
		return {}
	var profile: Dictionary = body.call("get_ground_traversal_profile")
	var collision := _body_collision()
	if collision == null or collision.shape == null:
		push_error("GroundTraversal2D host has no enabled CollisionShape2D")
		return {}
	profile["body_shape"] = collision.shape
	profile["body_bottom"] = collision.position.y + _shape_half_height(collision.shape)
	profile["body_shape_half_height"] = _shape_half_height(collision.shape)
	profile["body_width"] = _shape_width(collision.shape)
	profile["shape_rotation"] = collision.rotation
	profile["sample_spacing"] = sample_spacing
	profile["max_safe_fall_health_fraction"] = max_safe_fall_health_fraction
	return profile

func _process_walk(link: GroundTraversalCache2D.TraversalLink, delta: float) -> void:
	_set_action(&"walk")
	if not body.is_on_floor():
		body.velocity.y += float(_profile.get("gravity", 0.0)) * delta
	var target_surface := cache.sample_position(_profile_key, link.to_id)
	var target_x := target_surface.x
	var speed := float(_profile.get("walk_speed", 0.0))
	var acceleration := float(_profile.get("ground_acceleration", speed * 8.0))
	body.velocity.x = move_toward(body.velocity.x, signf(target_x - body.global_position.x) * speed, acceleration * delta)
	body.move_and_slide()
	var distance := absf(target_x - body.global_position.x)
	if distance <= maxf(2.0, sample_spacing * 0.35):
		_advance_segment()
		return
	_check_blocked(link, distance, delta)

func _process_air(link: GroundTraversalCache2D.TraversalLink, delta: float) -> void:
	if not _committed:
		body.velocity = link.launch_velocity
		_committed = true
		_became_airborne = false
		_air_elapsed = 0.0
		_launch_elapsed = 0.0
		_set_action(link.kind)
	body.velocity.y += float(_profile.get("gravity", 0.0)) * delta
	body.move_and_slide()
	if not body.is_on_floor():
		_became_airborne = true
		_air_elapsed += delta
	elif _became_airborne:
		var landing := cache.sample_position(_profile_key, link.to_id)
		var body_bottom := body.global_position + Vector2.DOWN * float(_profile.get("body_bottom", 0.0))
		var tolerance := maxf(sample_spacing * 2.0, float(_profile.get("body_width", 0.0)) + 4.0)
		if body_bottom.distance_to(landing) > tolerance:
			_fail_link(link, &"landing_invalid")
			return
		_committed = false
		_became_airborne = false
		_advance_segment()
		if _pending_request:
			_target = _pending_target
			_reason = _pending_reason
			_pending_request = false
			_plan()
		return
	else:
		_launch_elapsed += delta
		if _launch_elapsed >= blocked_timeout:
			_fail_link(link, &"launch_blocked")
			return
	if _air_elapsed > link.duration + 0.75:
		_fail_link(link, &"landing_invalid")
		return
	if body.get_slide_collision_count() > 0 and not body.is_on_floor() and body.velocity.y <= 0.0:
		_fail_link(link, &"arc_blocked")

func _check_blocked(link: GroundTraversalCache2D.TraversalLink, distance: float, delta: float) -> void:
	if distance < _last_distance - 0.25:
		_blocked_remaining = blocked_timeout
	else:
		_blocked_remaining -= delta
	_last_distance = distance
	if _blocked_remaining <= 0.0:
		_fail_link(link, &"movement_blocked")

func _fail_link(link: GroundTraversalCache2D.TraversalLink, reason: StringName) -> void:
	cache.mark_link_failed(_profile_key, link, route_failure_cooldown)
	_committed = false
	_became_airborne = false
	var result := _plan(false)
	if result != RouteResult.SUCCESS:
		_fail(RouteResult.TEMPORARILY_BLOCKED, reason)

func _advance_segment() -> void:
	_route_index += 1
	_blocked_remaining = blocked_timeout
	_last_distance = INF
	if _route_index >= _route.size():
		_complete()

func _complete() -> void:
	_active = false
	_route.clear()
	_route_index = 0
	_set_action(&"inactive")
	route_completed.emit()

func _fail(result: RouteResult, reason: StringName, last_position := Vector2.INF) -> RouteResult:
	var position := body.global_position if last_position == Vector2.INF and body != null else last_position
	_last_failure_reason = reason
	cancel()
	route_failed.emit(result, position, reason)
	return result

func _resolve_cache() -> GroundTraversalCache2D:
	var node: Node = body
	while node != null:
		if node is WorldSection:
			return (node as WorldSection).get_ground_traversal_cache(sample_spacing, terrain_collision_mask)
		if node is WorldLayer:
			var section := (node as WorldLayer).section_at(body.global_position)
			return section.get_ground_traversal_cache(sample_spacing, terrain_collision_mask) if section != null else null
		node = node.get_parent()
	return null

func _body_collision() -> CollisionShape2D:
	for child in body.get_children():
		if child is CollisionShape2D and not (child as CollisionShape2D).disabled:
			return child as CollisionShape2D
	return null

func _shape_half_height(shape: Shape2D) -> float:
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size.y * 0.5
	if shape is CapsuleShape2D:
		return (shape as CapsuleShape2D).height * 0.5
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius
	if shape is ConvexPolygonShape2D:
		var maximum := 0.0
		for point in (shape as ConvexPolygonShape2D).points:
			maximum = maxf(maximum, point.y)
		return maximum
	return 0.0

func _shape_width(shape: Shape2D) -> float:
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size.x
	if shape is CapsuleShape2D:
		return (shape as CapsuleShape2D).radius * 2.0
	if shape is CircleShape2D:
		return (shape as CircleShape2D).radius * 2.0
	if shape is ConvexPolygonShape2D:
		var minimum := INF
		var maximum := -INF
		for point in (shape as ConvexPolygonShape2D).points:
			minimum = minf(minimum, point.x)
			maximum = maxf(maximum, point.x)
		return maximum - minimum
	return 0.0

func _set_action(action: StringName) -> void:
	if current_action == action:
		return
	current_action = action
	action_changed.emit(action)
	if body != null and body.has_method("on_ground_traversal_action"):
		body.call("on_ground_traversal_action", action)

func _process(_delta: float) -> void:
	if GameSession.debug_gameplay_draw:
		queue_redraw()

func _draw() -> void:
	if not GameSession.debug_gameplay_draw or cache == null:
		return
	for index in range(_route_index, _route.size()):
		var link := _route[index]
		var from_position := to_local(cache.sample_position(_profile_key, link.from_id))
		var to_position := to_local(cache.sample_position(_profile_key, link.to_id))
		draw_line(from_position, to_position, Color(1.0, 0.2, 0.2, 0.95), 3.0)
	var profile_text := "%s  %s" % [_profile.get("profile_id", &""), current_action]
	if not _last_failure_reason.is_empty():
		profile_text += "  fail:%s" % _last_failure_reason
	draw_string(ThemeDB.fallback_font, Vector2(-96.0, -40.0), profile_text, HORIZONTAL_ALIGNMENT_CENTER, 192.0, 11, Color.WHITE)
