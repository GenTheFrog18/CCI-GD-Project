class_name PreparedLayer2Relic
extends Node2D

enum UmbrellaState { OPENING, OPEN, CLOSING, FORCED_RECOVERY }

var movement_multiplier := 1.0
var jump_multiplier := 1.0
var climb_multiplier := 1.0
var definition: ItemDefinition
var instance_state: Dictionary = {}
var source_actor: PlayerController
var kind: StringName
var settings: Dictionary = {}
var umbrella_state := UmbrellaState.OPENING
var timer := 0.0
var stability := 100.0
var aim_direction := Vector2.RIGHT
var _visual: Sprite2D
@onready var blocking_hitbox: CollisionPolygon2D = $BlockingArea/BlockHitbox

func configure(item: ItemDefinition, state: Dictionary, actor: Node2D, relic_kind: StringName, values: Dictionary) -> void:
	definition = item
	instance_state = state.duplicate(true)
	source_actor = actor as PlayerController
	kind = relic_kind
	settings = values.duplicate(true)
	movement_multiplier = float(settings.get("active_move_speed_multiplier", 1.0))
	if kind == &"plate_umbrella":
		stability = float(instance_state.get("stability", settings.max_stability))
		var recovery := float(instance_state.get("recovery_remaining", 0.0))
		umbrella_state = UmbrellaState.FORCED_RECOVERY if recovery > 0.0 else UmbrellaState.OPENING
		timer = recovery if recovery > 0.0 else float(settings.opening_duration)
		movement_multiplier *= float(settings.open_move_multiplier)
		jump_multiplier = float(settings.open_jump_multiplier)
		climb_multiplier = float(settings.open_climb_multiplier)
	elif kind == &"lacerator":
		jump_multiplier = 0.0

func _ready() -> void:
	_visual = Sprite2D.new()
	_visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_visual)
	_refresh_visual()

func _process(delta: float) -> void:
	if not is_instance_valid(source_actor):
		queue_free()
		return
	aim_direction = _direction_to_cursor(source_actor.get_global_mouse_position())
	global_rotation = aim_direction.angle()
	if _visual != null:
		_visual.flip_v = kind != &"plate_umbrella" and aim_direction.x < 0.0
	source_actor._set_facing(signf(aim_direction.x) if not is_zero_approx(aim_direction.x) else source_actor.facing_direction)
	queue_redraw()
	if kind != &"plate_umbrella":
		return
	timer = maxf(0.0, timer - delta)
	if umbrella_state == UmbrellaState.OPENING and timer <= 0.0:
		umbrella_state = UmbrellaState.OPEN
	elif umbrella_state == UmbrellaState.CLOSING and timer <= 0.0:
		stability = float(settings.max_stability)
		source_actor.item_controller.cancel_prepared(&"toggle_complete")
	elif umbrella_state == UmbrellaState.FORCED_RECOVERY and timer <= 0.0:
		stability = float(settings.max_stability)
		source_actor.item_controller.cancel_prepared(&"forced_complete")
	_refresh_visual()
	_visual.modulate = Color(1, 1, 1, 0.45) if umbrella_state != UmbrellaState.OPEN else Color.WHITE

func primary_action(_controller: PlayerItemController) -> bool:
	if kind != &"plate_umbrella" or umbrella_state in [UmbrellaState.CLOSING, UmbrellaState.FORCED_RECOVERY]:
		return false
	umbrella_state = UmbrellaState.CLOSING
	timer = float(settings.closing_duration)
	_refresh_visual()
	return true

func secondary_action(controller: PlayerItemController, world: Node, cursor: Vector2) -> bool:
	if kind == &"plate_umbrella":
		return primary_action(controller)
	if world == null:
		return false
	if kind == &"lacerator":
		var ball := preload("res://game/items/world/lacerator_ball.tscn").instantiate() as LaceratorBall
		ball.configure(source_actor, global_position, _lacerator_velocity(cursor), float(settings.direct_damage), float(settings.bleed_duration), int(settings.valid_ball_hits), float(settings.interrupt_strength))
		world.add_child(ball)
		instance_state["remaining_ammo"] = int(instance_state.get("remaining_ammo", settings.capacity)) - 1
		controller.feedback_requested.emit("Lacerator: %d shots remain" % instance_state.remaining_ammo)
	else:
		var direction := _direction_to_cursor(cursor)
		var rod := preload("res://game/items/world/bolt_shock_rod.tscn").instantiate() as BoltShockRod
		rod.configure(source_actor, global_position, direction * float(settings.launch_speed), float(settings.direct_damage), float(settings.rod_stun_duration), float(settings.rod_suppression_duration), float(settings.rod_shock_duration))
		world.add_child(rod)
		instance_state["remaining_uses"] = int(instance_state.get("remaining_uses", settings.capacity)) - 1
		controller.feedback_requested.emit("Bolt Shock: %d uses remain" % instance_state.remaining_uses)
	controller.cancel_prepared(&"fired")
	return true

func get_preview(cursor: Vector2) -> Dictionary:
	if kind != &"lacerator" or source_actor == null:
		return {}
	var preview_length := float(settings.get("preview_length", 48.0))
	if preview_length <= 0.0:
		return {}
	var points := PackedVector2Array([global_position])
	var position := global_position
	var velocity := _lacerator_velocity(cursor)
	var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var travelled := 0.0
	while travelled < preview_length and points.size() < 32:
		velocity.y += gravity * 0.04
		var next := position + velocity * 0.04
		travelled += position.distance_to(next)
		points.append(next)
		position = next
	return {"kind": &"trajectory", "points": points}

func resolve_impact(impact: ImpactData) -> Dictionary:
	if kind != &"plate_umbrella" or umbrella_state != UmbrellaState.OPEN or not impact.blockable or stability <= 0.0:
		return {}
	var incoming := Vector2.ZERO
	if is_instance_valid(impact.source_actor) and impact.source_actor is Node2D:
		incoming = source_actor.global_position.direction_to((impact.source_actor as Node2D).global_position)
	elif not impact.velocity.is_zero_approx():
		incoming = -impact.velocity.normalized()
	if incoming.is_zero_approx() or not _is_blocking_direction(incoming):
		return {}
	var reduction := float(settings.creature_damage_reduction)
	if impact.attack_kind in [&"projectile", &"primate_rock", &"thorn_needle", &"lacerator_ball", &"thrown_item"]:
		reduction = float(settings.projectile_damage_reduction)
	elif impact.attack_kind == &"bulwark_charge":
		reduction = float(settings.bulwark_damage_reduction)
	var reduced_damage := impact.damage_amount() * (1.0 - clampf(reduction, 0.0, 1.0))
	var damaged := source_actor.apply_damage(DamageInfo.new(reduced_damage, impact.source_actor, impact.source_species_id)) if reduced_damage > 0.0 else true
	if not impact.force.is_zero_approx():
		source_actor.apply_force(impact.force * float(settings.force_transfer_multiplier))
	stability -= impact.stability_damage if impact.stability_damage >= 0.0 else impact.damage_amount() + impact.force.length() * 0.1
	if stability <= 0.0 or impact.attack_kind == &"bulwark_charge":
		stability = 0.0
		umbrella_state = UmbrellaState.FORCED_RECOVERY
		timer = float(settings.forced_recovery_duration)
		_refresh_visual()
	return {"handled": true, "damage": damaged, "force": not impact.force.is_zero_approx(), "statuses": 0, "agitation": false, "blocked": true}

func cancel_preparation(controller: PlayerItemController, reason: StringName) -> void:
	if kind == &"plate_umbrella":
		instance_state["stability"] = stability
		instance_state["recovery_remaining"] = timer if umbrella_state == UmbrellaState.FORCED_RECOVERY else 0.0
	elif kind == &"lacerator":
		instance_state["remaining_ammo"] = int(instance_state.get("remaining_ammo", settings.capacity))
	else:
		instance_state["remaining_uses"] = int(instance_state.get("remaining_uses", settings.capacity))
	instance_state["loaded"] = false
	instance_state["visual_state"] = "default"
	if not controller.inventory.try_add_item(definition.item_id, 1, instance_state):
		var dropped := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
		dropped.configure(definition, instance_state, source_actor, source_actor.global_position, Vector2.ZERO)
		source_actor.get_parent().add_child(dropped)
	queue_free()

func _refresh_visual() -> void:
	if _visual == null or definition == null:
		return
	_visual.texture = definition.texture_for_state(_active_visual_state())

func _active_visual_state() -> StringName:
	if kind != &"plate_umbrella":
		return &"loaded"
	match umbrella_state:
		UmbrellaState.OPENING: return &"opening"
		UmbrellaState.OPEN: return &"open"
		UmbrellaState.CLOSING: return &"closing"
		UmbrellaState.FORCED_RECOVERY: return &"forced_recovery"
	return &"default"

func _direction_to_cursor(cursor: Vector2) -> Vector2:
	if kind == &"lacerator":
		var side := signf(cursor.x - source_actor.global_position.x)
		if is_zero_approx(side):
			side = signf(source_actor.facing_direction)
		if is_zero_approx(side):
			side = 1.0
		return Vector2(side, 0.0)
	var direction := global_position.direction_to(cursor)
	return Vector2.RIGHT if direction.is_zero_approx() else direction

func _lacerator_velocity(cursor: Vector2) -> Vector2:
	var offset := cursor - global_position
	if offset.is_zero_approx():
		offset = Vector2(signf(source_actor.facing_direction), 0.0)
	var maximum_distance := maxf(float(settings.get("maximum_cursor_distance", 240.0)), 1.0)
	var strength := clampf(offset.length() / maximum_distance, 0.0, 1.0)
	var minimum_speed := float(settings.get("minimum_launch_speed", 120.0))
	var maximum_speed := float(settings.get("maximum_launch_speed", settings.get("launch_speed", 260.0)))
	return offset.normalized() * lerpf(minimum_speed, maximum_speed, strength)

func _is_blocking_direction(incoming: Vector2) -> bool:
	if blocking_hitbox != null and blocking_hitbox.polygon.size() >= 3:
		var local_direction := incoming.normalized().rotated(-global_rotation)
		var ray := PackedVector2Array([local_direction * 0.1, local_direction * 1000.0])
		return not Geometry2D.intersect_polyline_with_polygon(ray, blocking_hitbox.polygon).is_empty()
	return aim_direction.dot(incoming) >= cos(deg_to_rad(float(settings.block_arc_degrees) * 0.5))

func _draw() -> void:
	if not GameSession.debug_gameplay_draw or kind != &"plate_umbrella" or blocking_hitbox == null or blocking_hitbox.polygon.size() < 3:
		return
	var color := Color(0.2, 1.0, 0.35, 0.22) if umbrella_state == UmbrellaState.OPEN else Color(1.0, 0.75, 0.2, 0.18)
	draw_colored_polygon(blocking_hitbox.polygon, color)
	var outline := PackedVector2Array(blocking_hitbox.polygon)
	outline.append(blocking_hitbox.polygon[0])
	draw_polyline(outline, color.lightened(0.35), 2.0)
