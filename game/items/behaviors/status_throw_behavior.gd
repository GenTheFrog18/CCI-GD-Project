class_name StatusThrowBehavior
extends DefaultThrowBehavior

@export var effect_id: StringName
@export var effect_duration := 30.0

func on_impact(thrown_item: Node2D, impact: ImpactData) -> ItemActionResult:
	super.on_impact(thrown_item, impact)
	if not impact_activation_allowed(impact):
		return ItemActionResult.completed()
	var body := impact.receiver
	if body != null and body.has_method("apply_status") and (body.is_in_group(&"small_enemy") or body.is_in_group(&"gatekeeper") or body.is_in_group(&"flying")):
		if body.apply_status(effect_id, {"duration": effect_duration}):
			SaveManager.mark_destroyed(String(thrown_item.persistent_id))
			thrown_item.queue_free()
			GameSession.record_signature_use(thrown_item.definition.item_id)
	return ItemActionResult.completed()
