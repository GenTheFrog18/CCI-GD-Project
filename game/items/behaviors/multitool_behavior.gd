class_name MultitoolBehavior
extends ItemBehavior

@export var damage := 1.0
@export var force := 40.0
@export var extension := 8.0
@export var active_seconds := 0.12
@export var recovery_seconds := 0.18
@export var enemy_recovery_seconds := 0.5
@export var movement_multiplier := 0.6
@export var visual_rotation_offset := PI / 4.0
@export_flags_2d_physics var target_mask := 68

var thrust_scene := preload("res://game/items/actions/held_thrust.tscn")

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.definition != null

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	var direction := context.cursor_position - context.action_origin
	AudioManager.play_player_attack()
	var thrust := thrust_scene.instantiate() as HeldThrust
	thrust.configure(
		context.actor,
		context.definition.icon,
		direction,
		damage,
		force,
		extension,
		active_seconds,
		recovery_seconds,
		enemy_recovery_seconds,
		target_mask,
		visual_rotation_offset,
		movement_multiplier
	)
	var result := ItemActionResult.completed(0, state)
	result.prepared_node = thrust
	return result

func can_secondary(_context: ItemContext, _state: Dictionary) -> bool:
	return false
