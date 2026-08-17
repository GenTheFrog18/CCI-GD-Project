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
var _visual: Polygon2D

func configure(item: ItemDefinition, state: Dictionary, actor: Node2D, relic_kind: StringName, values: Dictionary) -> void:
	definition = item
	instance_state = state.duplicate(true)
	source_actor = actor as PlayerController
	kind = relic_kind
	settings = values.duplicate(true)
	if kind == &"plate_umbrella":
		stability = float(instance_state.get("stability", settings.max_stability))
		var recovery := float(instance_state.get("recovery_remaining", 0.0))
		umbrella_state = UmbrellaState.FORCED_RECOVERY if recovery > 0.0 else UmbrellaState.OPENING
		timer = recovery if recovery > 0.0 else float(settings.opening_duration)
		movement_multiplier = float(settings.open_move_multiplier)
		jump_multiplier = float(settings.open_jump_multiplier)
		climb_multiplier = float(settings.open_climb_multiplier)

func _ready() -> void:
	_visual = Polygon2D.new()
	_visual.polygon = PackedVector2Array([Vector2(0, -12), Vector2(20, -9), Vector2(24, 0), Vector2(20, 9), Vector2(0, 12)]) if kind == &"plate_umbrella" else PackedVector2Array([Vector2(-5, -3), Vector2(16, -3), Vector2(16, 3), Vector2(-5, 3)])
	_visual.color = Color(0.35, 0.6, 0.9) if kind == &"plate_umbrella" else Color(0.8, 0.35, 0.25) if kind == &"lacerator" else Color(0.3, 0.85, 1.0)
	add_child(_visual)

func _process(delta: float) -> void:
	if not is_instance_valid(source_actor):
		queue_free()
		return
	aim_direction = source_actor.global_position.direction_to(source_actor.get_global_mouse_position())
	if aim_direction.is_zero_approx():
		aim_direction = Vector2.RIGHT
	global_rotation = aim_direction.angle()
	source_actor._set_facing(signf(aim_direction.x) if not is_zero_approx(aim_direction.x) else source_actor.facing_direction)
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
	_visual.modulate = Color(1, 1, 1, 0.45) if umbrella_state != UmbrellaState.OPEN else Color.WHITE

func primary_action(_controller: PlayerItemController) -> bool:
	if kind != &"plate_umbrella" or umbrella_state in [UmbrellaState.CLOSING, UmbrellaState.FORCED_RECOVERY]:
		return false
	umbrella_state = UmbrellaState.CLOSING
	timer = float(settings.closing_duration)
	return true

func secondary_action(controller: PlayerItemController, world: Node, cursor: Vector2) -> bool:
	if kind == &"plate_umbrella":
		return primary_action(controller)
	if world == null:
		return false
	var direction := global_position.direction_to(cursor)
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	if kind == &"lacerator":
		var ball := preload("res://game/items/world/lacerator_ball.tscn").instantiate() as LaceratorBall
		ball.configure(source_actor, global_position, direction * float(settings.launch_speed), float(settings.direct_damage), float(settings.bleed_duration), int(settings.valid_ball_hits), float(settings.interrupt_strength))
		world.add_child(ball)
		instance_state["remaining_ammo"] = int(instance_state.get("remaining_ammo", settings.capacity)) - 1
		controller.feedback_requested.emit("Lacerator: %d shots remain" % instance_state.remaining_ammo)
	else:
		var rod := preload("res://game/items/world/bolt_shock_rod.tscn").instantiate() as BoltShockRod
		rod.configure(source_actor, global_position, direction * float(settings.launch_speed), float(settings.direct_damage), float(settings.rod_stun_duration), float(settings.rod_suppression_duration), float(settings.rod_shock_duration))
		world.add_child(rod)
		instance_state["remaining_uses"] = int(instance_state.get("remaining_uses", settings.capacity)) - 1
		controller.feedback_requested.emit("Bolt Shock: %d uses remain" % instance_state.remaining_uses)
	controller.cancel_prepared(&"fired")
	return true

func resolve_impact(impact: ImpactData) -> Dictionary:
	if kind != &"plate_umbrella" or umbrella_state != UmbrellaState.OPEN or not impact.blockable or stability <= 0.0:
		return {}
	var incoming := Vector2.ZERO
	if is_instance_valid(impact.source_actor) and impact.source_actor is Node2D:
		incoming = source_actor.global_position.direction_to((impact.source_actor as Node2D).global_position)
	elif not impact.velocity.is_zero_approx():
		incoming = -impact.velocity.normalized()
	if incoming.is_zero_approx() or aim_direction.dot(incoming) < cos(deg_to_rad(float(settings.block_arc_degrees) * 0.5)):
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
	if not controller.inventory.try_add_item(definition.item_id, 1, instance_state):
		var dropped := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
		dropped.configure(definition, instance_state, source_actor, source_actor.global_position, Vector2.ZERO)
		source_actor.get_parent().add_child(dropped)
	queue_free()
