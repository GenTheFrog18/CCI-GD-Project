class_name DeployableBehavior
extends DefaultThrowBehavior

@export_enum("hushcap", "resin", "light", "crystal") var kind := "hushcap"
@export var effect_id: StringName
@export var duration := 8.0
@export var primary_shape: Shape2D
@export var impact_shape: Shape2D
@export var sound_priority := -1
@export var sound_radius := 0.0

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.world != null

func primary(context: ItemContext, _state: Dictionary) -> ItemActionResult:
	var area := _make_area(context.actor.global_position, primary_shape, context.actor)
	var result := ItemActionResult.completed(1)
	result.world_node = area
	GameSession.record_signature_use(context.definition.item_id)
	return result

func on_impact(thrown_item: Node2D, impact: ImpactData) -> ItemActionResult:
	super.on_impact(thrown_item, impact)
	if not impact_activation_allowed(impact):
		return ItemActionResult.completed()
	if thrown_item.has_meta(&"effect_deployed"):
		return ItemActionResult.completed()
	thrown_item.set_meta(&"effect_deployed", true)
	var parent := thrown_item.get_parent()
	if parent == null:
		return ItemActionResult.failed()
	var area := _make_area(thrown_item.global_position, impact_shape, impact.source_actor)
	parent.call_deferred(&"add_child", area)
	if thrown_item.definition != null:
		GameSession.record_signature_use(thrown_item.definition.item_id)
	if thrown_item.get("persistent_id") != null:
		SaveManager.mark_destroyed(String(thrown_item.persistent_id))
	thrown_item.queue_free()
	return ItemActionResult.completed()

func _make_area(position: Vector2, area_shape: Shape2D, source: Node) -> WorldEffectArea:
	var area := WorldEffectArea.new()
	area.configure(StringName(kind), effect_id, duration, area_shape, source, sound_priority, sound_radius)
	area.global_position = position
	return area
