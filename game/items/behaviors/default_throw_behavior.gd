class_name DefaultThrowBehavior
extends ItemBehavior

@export var minimum_speed := 80.0
@export var maximum_speed := 420.0
@export var maximum_cursor_distance := 240.0
@export var base_damage := 0.0
@export var item_mass := 1.0

var thrown_scene := preload("res://game/items/world/thrown_item.tscn")

func can_secondary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.world != null and context.definition != null

func secondary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	if not can_secondary(context, state):
		return ItemActionResult.failed("Cannot throw here")
	var direction := context.cursor_position - context.action_origin
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var strength := clampf(direction.length() / maximum_cursor_distance, 0.0, 1.0)
	var speed := lerpf(minimum_speed, maximum_speed, strength)
	var thrown := thrown_scene.instantiate() as ThrownItem
	thrown.configure(context.definition, state, context.actor, context.action_origin, direction.normalized() * speed, base_damage, item_mass)
	var result := ItemActionResult.completed(1)
	result.world_node = thrown
	return result
