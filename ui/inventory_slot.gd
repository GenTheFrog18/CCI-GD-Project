class_name InventorySlot
extends Button

var hud: FoundationHUD
var flat_index := -1

func _get_drag_data(_position: Vector2) -> Variant:
	if icon == null or hud == null:
		return null
	var preview := TextureRect.new()
	preview.texture = icon
	preview.custom_minimum_size = Vector2(32, 32)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return flat_index

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is int and data >= 0 and data < 7

func _drop_data(_position: Vector2, data: Variant) -> void:
	hud.swap_inventory_slots(data, flat_index)
