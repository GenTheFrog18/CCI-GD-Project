class_name ResonanceCoreBehavior
extends DefaultThrowBehavior

@export var weak_impact := 80.0
@export var medium_impact := 180.0
@export var strong_impact := 280.0
@export var weak_radius := 160.0
@export var medium_radius := 320.0
@export var strong_radius := 520.0
@export var weak_priority := 3
@export var medium_priority := 6
@export var strong_priority := 9

func on_impact(thrown_item: Node2D, impact: ImpactData) -> ItemActionResult:
	if not impact_activation_allowed(impact):
		return ItemActionResult.completed()
	_emit_resonance(thrown_item, impact.velocity.length())
	return ItemActionResult.completed()

func on_received_impact(thrown_item: Node2D, impact: ImpactData) -> void:
	_emit_resonance(thrown_item, impact.force.length())

func _emit_resonance(body: Node2D, strength: float) -> void:
	if strength < weak_impact:
		return
	var radius := weak_radius
	var priority := weak_priority
	if strength >= strong_impact:
		radius = strong_radius
		priority = strong_priority
	elif strength >= medium_impact:
		radius = medium_radius
		priority = medium_priority
	SoundBus.emit_sound(body.get_tree(), SoundEvent.new(body.global_position, radius, &"resonance", priority, body, strength))
	GameSession.record_signature_use(&"resonance_core")
