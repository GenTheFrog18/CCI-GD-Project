class_name ItemStack
extends RefCounted

var item_id: StringName
var quantity := 0
var state: Dictionary = {}

func _init(id: StringName = &"", amount := 0, instance_state: Dictionary = {}) -> void:
	item_id = id
	quantity = amount
	state = instance_state.duplicate(true)

func is_empty() -> bool:
	return item_id.is_empty() or quantity <= 0

func is_compatible(other_id: StringName, other_state: Dictionary) -> bool:
	return item_id == other_id and state == other_state

func copy() -> ItemStack:
	return ItemStack.new(item_id, quantity, state)

func capture_state() -> Dictionary:
	return {"item_id": String(item_id), "quantity": quantity, "state": state.duplicate(true)}

static func from_state(data: Dictionary) -> ItemStack:
	return ItemStack.new(StringName(data.get("item_id", "")), int(data.get("quantity", 0)), data.get("state", {}))
