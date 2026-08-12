class_name DefaultThrowBehavior
extends ItemBehavior

@export var minimum_speed := 80.0
@export var maximum_speed := 420.0
@export var maximum_cursor_distance := 240.0
@export var base_damage := 0.0
@export var preview_length := 48.0
@export var preview_step_seconds := 0.04
@export var throw_sound_priority := 1
@export var throw_sound_radius := 96.0
@export var impact_sound_priority := -1
@export var impact_sound_radius := 0.0

var thrown_scene := preload("res://game/items/world/thrown_item.tscn")

func can_secondary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.world != null and context.definition != null

func secondary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	if not can_secondary(context, state):
		return ItemActionResult.failed("Cannot throw here")
	var thrown := thrown_scene.instantiate() as ThrownItem
	thrown.configure(context.definition, state, context.actor, context.action_origin, launch_velocity(context), base_damage)
	var result := ItemActionResult.completed(1)
	result.world_node = thrown
	result.sound_type = &"throw"
	result.sound_priority = throw_sound_priority
	result.sound_radius = throw_sound_radius
	return result

func get_preview(context: ItemContext, state: Dictionary) -> Dictionary:
	if not can_secondary(context, state):
		return {}
	var points := PackedVector2Array([context.action_origin])
	var position := context.action_origin
	var velocity := launch_velocity(context)
	var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	var travelled := 0.0
	while travelled < preview_length and points.size() < 32:
		velocity.y += gravity * preview_step_seconds
		var next := position + velocity * preview_step_seconds
		travelled += position.distance_to(next)
		points.append(next)
		position = next
	return {"kind": &"trajectory", "points": points}

func launch_velocity(context: ItemContext) -> Vector2:
	var offset := context.cursor_position - context.action_origin
	if offset.is_zero_approx():
		offset = Vector2.RIGHT
	var strength := clampf(offset.length() / maxf(maximum_cursor_distance, 1.0), 0.0, 1.0)
	var base_speed := lerpf(minimum_speed, maximum_speed, strength)
	var weight := maxi(context.definition.weight if context.definition != null else 1, 1)
	return offset.normalized() * base_speed / sqrt(float(weight))

func on_impact(thrown_item: Node2D, _impact: ImpactData) -> ItemActionResult:
	if impact_sound_priority >= 0 and impact_sound_radius > 0.0 and not thrown_item.has_meta(&"impact_sound_emitted"):
		thrown_item.set_meta(&"impact_sound_emitted", true)
		SoundBus.emit_sound(thrown_item.get_tree(), SoundEvent.new(
			thrown_item.global_position,
			impact_sound_radius,
			&"item_impact",
			impact_sound_priority,
			thrown_item
		))
	return ItemActionResult.completed()
