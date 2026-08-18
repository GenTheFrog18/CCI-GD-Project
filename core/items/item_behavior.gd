class_name ItemBehavior
extends Resource

func can_primary(_context: ItemContext, _state: Dictionary) -> bool:
	return false

func primary(_context: ItemContext, state: Dictionary) -> ItemActionResult:
	return ItemActionResult.failed("Primary action unavailable")

func can_secondary(_context: ItemContext, _state: Dictionary) -> bool:
	return false

func secondary(_context: ItemContext, _state: Dictionary) -> ItemActionResult:
	return ItemActionResult.failed("Secondary action unavailable")

func get_preview(_context: ItemContext, _state: Dictionary) -> Dictionary:
	return {}

func on_thrown(_thrown_item: Node2D, _context: ItemContext, _state: Dictionary) -> void:
	pass

func on_impact(_thrown_item: Node2D, _impact: ImpactData) -> ItemActionResult:
	return ItemActionResult.completed()

func on_received_impact(_thrown_item: Node2D, _impact: ImpactData) -> void:
	pass

func get_impact_activation_speed() -> float:
	return 0.0

func impact_activation_allowed(impact: ImpactData) -> bool:
	return impact.velocity.length() >= get_impact_activation_speed()
