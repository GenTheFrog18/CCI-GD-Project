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

func on_thrown(_thrown_item: Node2D, _context: ItemContext, _state: Dictionary) -> void:
	pass

func on_impact(_thrown_item: Node2D, _impact: ImpactData) -> ItemActionResult:
	return ItemActionResult.completed()
