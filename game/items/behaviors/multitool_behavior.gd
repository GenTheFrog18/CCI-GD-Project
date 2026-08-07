class_name MultitoolBehavior
extends ItemBehavior

@export var damage := 1.0
@export var force := 40.0

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	if context.interaction_target == null:
		return ItemActionResult.completed(0, state)
	if context.interaction_target.has_method("receive_multitool"):
		context.interaction_target.receive_multitool(context.actor)
		return ItemActionResult.completed(0, state)
	if context.interaction_target.has_method("apply_damage"):
		var direction := context.actor.global_position.direction_to(context.interaction_target.global_position)
		context.interaction_target.apply_damage(DamageInfo.new(damage, context.actor, &"player"))
		if context.interaction_target.has_method("apply_force"):
			context.interaction_target.apply_force(direction * force)
		return ItemActionResult.completed(0, state)
	return ItemActionResult.completed(0, state)

func can_secondary(_context: ItemContext, _state: Dictionary) -> bool:
	return false
