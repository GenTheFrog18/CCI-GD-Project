class_name DeployableBehavior
extends DefaultThrowBehavior

@export_enum("hushcap", "resin", "light", "crystal") var kind := "hushcap"
@export var effect_id: StringName
@export var duration := 8.0
@export var primary_radius := 40.0
@export var impact_radius := 64.0
@export var sound_priority := -1
@export var sound_radius := 0.0

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.world != null

func primary(context: ItemContext, _state: Dictionary) -> ItemActionResult:
	var area := _make_area(context.actor.global_position, primary_radius, context.actor)
	var result := ItemActionResult.completed(1)
	result.world_node = area
	GameSession.record_signature_use(context.definition.item_id)
	return result

func on_impact(thrown_item: Node2D, impact: ImpactData) -> ItemActionResult:
	super.on_impact(thrown_item, impact)
	if thrown_item.has_meta(&"effect_deployed"):
		return ItemActionResult.completed()
	thrown_item.set_meta(&"effect_deployed", true)
	var parent := thrown_item.get_parent()
	if parent == null:
		return ItemActionResult.failed()
	var area := _make_area(thrown_item.global_position, impact_radius, impact.source_actor)
	parent.add_child(area)
	if thrown_item.definition != null:
		GameSession.record_signature_use(thrown_item.definition.item_id)
	if thrown_item.get("persistent_id") != null:
		SaveManager.mark_destroyed(String(thrown_item.persistent_id))
	thrown_item.queue_free()
	return ItemActionResult.completed()

func _make_area(position: Vector2, area_radius: float, source: Node) -> WorldEffectArea:
	var area := WorldEffectArea.new()
	area.configure(StringName(kind), effect_id, duration, area_radius, source, sound_priority, sound_radius)
	area.global_position = position
	return area
