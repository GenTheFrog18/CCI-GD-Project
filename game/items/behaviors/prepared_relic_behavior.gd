class_name PreparedRelicBehavior
extends ItemBehavior

@export_enum("sun_sphere", "rattlepod", "silver_weight") var kind := "sun_sphere"
@export var duration := 20.0
@export var pulse_interval := 0.5
@export var pulse_count := 10
@export var pulse_radius := 300.0
@export var pulse_priority := 8
@export var throw_damage := 0.0
@export var throw_speed := 260.0
@export var movement_multiplier := 1.0

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.definition != null

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	var prepared := PreparedRelic.new()
	prepared.configure(context.definition, state, context.actor, StringName(kind), {
		"duration": duration, "pulse_interval": pulse_interval, "pulse_count": pulse_count,
		"pulse_radius": pulse_radius, "pulse_priority": pulse_priority,
		"throw_damage": throw_damage, "throw_speed": throw_speed,
		"movement_multiplier": movement_multiplier,
	})
	var result := ItemActionResult.completed(1)
	result.prepared_node = prepared
	GameSession.record_signature_use(context.definition.item_id)
	return result
