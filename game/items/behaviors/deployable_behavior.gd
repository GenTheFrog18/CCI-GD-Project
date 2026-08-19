class_name DeployableBehavior
extends DefaultThrowBehavior

@export_enum("hushcap", "resin", "light", "crystal") var kind := "hushcap"
@export var effect_id: StringName
@export var duration := 8.0
@export var primary_shape: Shape2D
@export var impact_shape: Shape2D
@export_range(0.0, 1.0, 0.05) var loose_item_speed_multiplier := 0.25
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
	if kind == "light" and thrown_item is ThrownItem and thrown_item.definition.item_id == &"sun_sphere":
		_activate_sun_sphere(thrown_item as ThrownItem, impact)
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

func _activate_sun_sphere(thrown_item: ThrownItem, impact: ImpactData) -> void:
	var active := PreparedRelic.new()
	active.configure(thrown_item.definition, thrown_item.instance_state, thrown_item.source_actor as Node2D, &"sun_sphere", {
		"duration": duration,
		"effect_shape": impact_shape,
	})
	thrown_item.get_parent().add_child(active)
	active.global_transform = thrown_item.global_transform
	active.activate_from_impact(impact.velocity)
	SaveManager.mark_destroyed(thrown_item.persistent_id)
	thrown_item.queue_free()

func _make_area(position: Vector2, area_shape: Shape2D, source: Node) -> WorldEffectArea:
	var area := WorldEffectArea.new()
	area.configure(StringName(kind), effect_id, duration, area_shape, source, sound_priority, sound_radius, loose_item_speed_multiplier)
	area.global_position = position
	return area
