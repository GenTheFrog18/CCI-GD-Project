class_name SilverWeightBehavior
extends DefaultThrowBehavior

@export var small_enemy_damage := 9999.0
@export var big_flyer_damage := 200.0

func on_impact(thrown_item: Node2D, impact: ImpactData) -> ItemActionResult:
	var body := impact.receiver
	if body != null and body.has_method("apply_damage"):
		var damage := big_flyer_damage if body.is_in_group(&"big_roamer") else small_enemy_damage if body.is_in_group(&"small_enemy") else 0.0
		if damage > 0.0:
			body.apply_damage(DamageInfo.new(damage, impact.source_actor, impact.source_species_id))
	if thrown_item.definition.item_id == &"silver_weight_damaged":
		SaveManager.mark_destroyed(String(thrown_item.persistent_id))
		thrown_item.queue_free()
	else:
		thrown_item.definition = ContentCatalog.get_item(&"silver_weight_damaged")
		thrown_item._apply_visual()
	GameSession.record_signature_use(&"silver_weight")
	return ItemActionResult.completed()
