class_name MultitoolBehavior
extends ItemBehavior

@export var damage := 1.0
@export var force := 40.0
@export var reach := 56.0
@export_flags_2d_physics var target_mask := 4

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	var target := context.interaction_target
	if target != null and target.has_method("receive_multitool"):
		target.receive_multitool(context.actor)
		return _result(state, "Tool interaction")
	var offset := context.cursor_position - context.action_origin
	if offset.is_zero_approx():
		offset = Vector2.RIGHT
	var ray_end := context.action_origin + offset.limit_length(reach)
	var query := PhysicsRayQueryParameters2D.create(context.action_origin, ray_end, target_mask)
	if context.actor is CollisionObject2D:
		query.exclude = [context.actor.get_rid()]
	var hit := context.actor.get_world_2d().direct_space_state.intersect_ray(query)
	target = hit.get("collider") as Node
	if target != null and target.has_method("apply_damage"):
		var direction := context.action_origin.direction_to(target.global_position)
		target.apply_damage(DamageInfo.new(damage, context.actor, &"player"))
		if target.has_method("apply_force"):
			target.apply_force(direction * force)
		return _result(state, "Multitool hit")
	return _result(state, "Multitool swing")

func can_secondary(_context: ItemContext, _state: Dictionary) -> bool:
	return false

func _result(state: Dictionary, message: String) -> ItemActionResult:
	var result := ItemActionResult.completed(0, state)
	result.message = message
	return result
