class_name ConsumableBehavior
extends ItemBehavior

@export_enum("bandage", "numbing_pill", "info_book", "driftseed") var kind := "bandage"
@export var duration := 10.0

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.definition != null

func primary(context: ItemContext, _state: Dictionary) -> ItemActionResult:
	var actor := context.actor
	match kind:
		"bandage":
			var health = actor.get("health")
			if health == null or float(health.health) >= float(health.max_health):
				return ItemActionResult.failed("Health is already full")
			if actor.has_method("apply_status"):
				var status = actor.get("status")
				if status != null:
					status.remove_status(&"bleed")
				actor.apply_status(&"healing", {"duration": duration})
			AudioManager.play_bandage_use()
		"numbing_pill":
			if not actor.has_method("apply_status"):
				return ItemActionResult.failed("Cannot use here")
			var status = actor.get("status")
			var current := float(status.get_remaining(&"curse_suppression")) if status != null else 0.0
			actor.apply_status(&"curse_suppression", {"duration": minf(999.0, current + 300.0)})
		"info_book":
			var learned := false
			for id: StringName in ContentCatalog.items:
				var definition := ContentCatalog.get_item(id)
				if definition != null and definition.discoverable and id not in GameSession.known_items:
					GameSession.known_items.append(id)
					learned = true
			if not learned:
				return ItemActionResult.failed("All known relics are already documented")
			SaveManager.save_meta()
		"driftseed":
			if not actor.has_method("apply_status") or not actor.apply_status(&"driftseed", {"duration": duration}):
				return ItemActionResult.failed("Driftseed has no valid target")
	GameSession.record_signature_use(context.definition.item_id)
	return ItemActionResult.completed(1)
