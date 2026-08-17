class_name Layer2RelicBehavior
extends ItemBehavior

@export_enum("plate_umbrella", "lacerator", "bolt_shock") var kind := "plate_umbrella"
@export var capacity := 4
@export var opening_duration := 0.3
@export var closing_duration := 0.3
@export var max_stability := 100.0
@export var forced_recovery_duration := 2.0
@export var block_arc_degrees := 120.0
@export var projectile_damage_reduction := 1.0
@export var creature_damage_reduction := 0.65
@export var bulwark_damage_reduction := 0.25
@export var force_transfer_multiplier := 1.0
@export var open_move_multiplier := 0.6
@export var open_jump_multiplier := 0.75
@export var open_climb_multiplier := 0.6
@export var launch_speed := 260.0
@export var direct_damage := 3.0
@export var bleed_duration := 8.0
@export var valid_ball_hits := 4
@export var interrupt_strength := 1.0
@export var rod_stun_duration := 3.0
@export var rod_suppression_duration := 5.0
@export var rod_shock_duration := 6.0

var prepared_scene := preload("res://game/items/world/prepared_layer2_relic.tscn")

func can_primary(context: ItemContext, state: Dictionary) -> bool:
	if context.actor == null or context.definition == null:
		return false
	if kind == "plate_umbrella":
		return true
	return int(state.get(_remaining_key(), capacity)) > 0

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	if not can_primary(context, state):
		return ItemActionResult.failed("No ammunition remaining")
	var prepared := prepared_scene.instantiate() as PreparedLayer2Relic
	prepared.configure(context.definition, state, context.actor, StringName(kind), {
		"capacity": capacity,
		"opening_duration": opening_duration,
		"closing_duration": closing_duration,
		"max_stability": max_stability,
		"forced_recovery_duration": forced_recovery_duration,
		"block_arc_degrees": block_arc_degrees,
		"projectile_damage_reduction": projectile_damage_reduction,
		"creature_damage_reduction": creature_damage_reduction,
		"bulwark_damage_reduction": bulwark_damage_reduction,
		"force_transfer_multiplier": force_transfer_multiplier,
		"open_move_multiplier": open_move_multiplier,
		"open_jump_multiplier": open_jump_multiplier,
		"open_climb_multiplier": open_climb_multiplier,
		"launch_speed": launch_speed,
		"direct_damage": direct_damage,
		"bleed_duration": bleed_duration,
		"valid_ball_hits": valid_ball_hits,
		"interrupt_strength": interrupt_strength,
		"rod_stun_duration": rod_stun_duration,
		"rod_suppression_duration": rod_suppression_duration,
		"rod_shock_duration": rod_shock_duration,
	})
	var result := ItemActionResult.completed(1)
	result.prepared_node = prepared
	result.message = "Umbrella opening" if kind == "plate_umbrella" else "%s loaded" % context.definition.display_name
	GameSession.record_signature_use(context.definition.item_id)
	return result

func can_secondary(context: ItemContext, state: Dictionary) -> bool:
	return kind == "plate_umbrella" and can_primary(context, state)

func secondary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	return primary(context, state) if kind == "plate_umbrella" else ItemActionResult.failed("Load first")

func _remaining_key() -> StringName:
	return &"remaining_uses" if kind == "bolt_shock" else &"remaining_ammo"
