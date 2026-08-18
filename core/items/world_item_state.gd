class_name WorldItemState
extends RefCounted

var definition: ItemDefinition
var item_id: StringName = &""
var quantity := 1
var instance_state: Dictionary = {}
var persistent_id := ""
var position := Vector2.ZERO
var rotation := 0.0
var linear_velocity := Vector2.ZERO
var angular_velocity := 0.0
var frozen := true

func set_definition(value: ItemDefinition) -> void:
	definition = value
	item_id = value.item_id if value != null else &""

func capture() -> Dictionary:
	return {
		"item_id": String(item_id),
		"quantity": quantity,
		"instance_state": instance_state.duplicate(true),
		"persistent_id": persistent_id,
		"position": [position.x, position.y],
		"rotation": rotation,
		"linear_velocity": [linear_velocity.x, linear_velocity.y],
		"angular_velocity": angular_velocity,
		"freeze": frozen,
	}

func restore(data: Dictionary) -> void:
	item_id = StringName(data.get("item_id", ""))
	definition = ContentCatalog.get_item(item_id)
	quantity = int(data.get("quantity", 1))
	instance_state = data.get("instance_state", {}).duplicate(true)
	if data.has("persistent_id"):
		persistent_id = String(data.get("persistent_id", ""))
	var position_data: Array = data.get("position", [0.0, 0.0])
	position = Vector2(float(position_data[0]), float(position_data[1]))
	rotation = float(data.get("rotation", 0.0))
	var velocity_data: Array = data.get("linear_velocity", [0.0, 0.0])
	linear_velocity = Vector2(float(velocity_data[0]), float(velocity_data[1]))
	angular_velocity = float(data.get("angular_velocity", 0.0))
	frozen = bool(data.get("freeze", true))

static func hitbox_for(item: ItemDefinition, fallback: Shape2D) -> Shape2D:
	if item != null and item.world_hitbox != null:
		return item.world_hitbox.duplicate() as Shape2D
	return fallback.duplicate() as Shape2D
