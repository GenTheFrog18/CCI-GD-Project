class_name SilverWeightBehavior
extends DefaultThrowBehavior

@export var impact_damage := 200.0

func on_impact(thrown_item: Node2D, impact: ImpactData) -> ItemActionResult:
	var body := impact.receiver
	if body != null and body.has_method("apply_damage"):
		body.apply_damage(DamageInfo.new(impact_damage, impact.source_actor, impact.source_species_id))
	if thrown_item.definition.item_id == &"silver_weight_damaged":
		SaveManager.mark_destroyed(String(thrown_item.persistent_id))
		thrown_item.queue_free()
	else:
		thrown_item.definition = ContentCatalog.get_item(&"silver_weight_damaged")
		thrown_item._apply_visual()
	GameSession.record_signature_use(&"silver_weight")
	return ItemActionResult.completed()
