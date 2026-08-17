class_name InventoryModel
extends RefCounted

signal changed

const HOTBAR_SIZE := 2
const BACKPACK_SIZE := 5

var hotbar: Array[ItemStack] = []
var backpack: Array[ItemStack] = []
var active_hotbar_index := 0

func _init() -> void:
	_reset_slots()

func get_active_stack() -> ItemStack:
	return hotbar[active_hotbar_index]

func get_total_weight() -> int:
	var total := 0
	for container in [hotbar, backpack]:
		for stack in container:
			if stack.is_empty():
				continue
			var definition := ContentCatalog.get_item(stack.item_id)
			if definition != null:
				total += stack.quantity * definition.weight
	return total

func select_hotbar(index: int) -> void:
	active_hotbar_index = posmod(index, HOTBAR_SIZE)
	changed.emit()

func try_add_item(item_id: StringName, quantity := 1, state: Dictionary = {}) -> bool:
	var definition := ContentCatalog.get_item(item_id)
	if definition == null or quantity <= 0:
		return false
	if not can_add_item(item_id, quantity, state):
		return false
	var remaining := quantity
	for container in [hotbar, backpack]:
		for raw_slot in container:
			var slot := raw_slot as ItemStack
			if not slot.is_empty() and slot.is_compatible(item_id, state):
				var room: int = definition.max_stack - slot.quantity
				var moved: int = mini(room, remaining)
				slot.quantity += moved
				remaining -= moved
				if remaining == 0:
					changed.emit()
					return true
	for container in [hotbar, backpack]:
		for index in container.size():
			if container[index].is_empty():
				var moved := mini(definition.max_stack, remaining)
				container[index] = ItemStack.new(item_id, moved, state)
				remaining -= moved
				if remaining == 0:
					changed.emit()
					return true
	return false

func can_add_item(item_id: StringName, quantity := 1, state: Dictionary = {}) -> bool:
	var definition := ContentCatalog.get_item(item_id)
	return definition != null and quantity > 0 and _free_capacity(definition, state) >= quantity

func has_item(item_id: StringName) -> bool:
	for container in [hotbar, backpack]:
		for slot in container:
			if not slot.is_empty() and slot.item_id == item_id:
				return true
	return false

func take_item(item_id: StringName) -> ItemStack:
	for container_name in [&"hotbar", &"backpack"]:
		var container := _container(container_name)
		for index in container.size():
			if not container[index].is_empty() and container[index].item_id == item_id:
				return take_one(container_name, index)
	return ItemStack.new()

func remove_active(quantity := 1) -> bool:
	var slot := get_active_stack()
	if quantity <= 0 or slot.quantity < quantity:
		return false
	slot.quantity -= quantity
	if slot.quantity == 0:
		hotbar[active_hotbar_index] = ItemStack.new()
	changed.emit()
	return true

func update_active_state(state: Dictionary) -> void:
	var slot := get_active_stack()
	if slot.is_empty():
		return
	slot.state = state.duplicate(true)
	changed.emit()

func swap_slots(from_container: StringName, from_index: int, to_container: StringName, to_index: int) -> bool:
	var from := _container(from_container)
	var to := _container(to_container)
	if from_index < 0 or from_index >= from.size() or to_index < 0 or to_index >= to.size():
		return false
	var temporary: ItemStack = from[from_index]
	from[from_index] = to[to_index]
	to[to_index] = temporary
	changed.emit()
	return true

func take_one(from_container: StringName, index: int) -> ItemStack:
	var container := _container(from_container)
	if index < 0 or index >= container.size() or container[index].is_empty():
		return ItemStack.new()
	var result := ItemStack.new(container[index].item_id, 1, container[index].state)
	container[index].quantity -= 1
	if container[index].quantity == 0:
		container[index] = ItemStack.new()
	changed.emit()
	return result

func take_for_theft() -> ItemStack:
	var order: Array[Array] = []
	order.append([&"hotbar", active_hotbar_index])
	for index in HOTBAR_SIZE:
		if index != active_hotbar_index:
			order.append([&"hotbar", index])
	for index in BACKPACK_SIZE:
		order.append([&"backpack", index])
	for entry in order:
		var container := _container(entry[0])
		var index := int(entry[1])
		if container[index].is_empty() or container[index].item_id == &"multitool":
			continue
		return take_one(entry[0], index)
	for entry in order:
		var container := _container(entry[0])
		var index := int(entry[1])
		if not container[index].is_empty() and container[index].item_id == &"multitool":
			return take_one(entry[0], index)
	return ItemStack.new()

func remove_origin(origin: StringName) -> Array[ItemStack]:
	var removed: Array[ItemStack] = []
	for container in [hotbar, backpack]:
		for index in container.size():
			var slot := container[index] as ItemStack
			if slot.is_empty() or StringName(slot.state.get("origin", "legacy")) != origin:
				continue
			removed.append(slot.copy())
			container[index] = ItemStack.new()
	if not removed.is_empty():
		changed.emit()
	return removed

func capture_state() -> Dictionary:
	return {
		"hotbar": hotbar.map(func(slot: ItemStack): return slot.capture_state()),
		"backpack": backpack.map(func(slot: ItemStack): return slot.capture_state()),
		"active_hotbar_index": active_hotbar_index,
	}

func restore_state(data: Dictionary) -> void:
	_reset_slots()
	_restore_container(hotbar, data.get("hotbar", []), HOTBAR_SIZE)
	_restore_container(backpack, data.get("backpack", []), BACKPACK_SIZE)
	active_hotbar_index = clampi(int(data.get("active_hotbar_index", 0)), 0, HOTBAR_SIZE - 1)
	changed.emit()

func _free_capacity(definition: ItemDefinition, state: Dictionary) -> int:
	var result := 0
	for container in [hotbar, backpack]:
		for raw_slot in container:
			var slot := raw_slot as ItemStack
			if slot.is_empty():
				result += definition.max_stack
			elif slot.is_compatible(definition.item_id, state):
				result += maxi(0, definition.max_stack - slot.quantity)
	return result

func _container(name: StringName) -> Array[ItemStack]:
	if name == &"hotbar":
		return hotbar
	if name == &"backpack":
		return backpack
	return []

func _reset_slots() -> void:
	hotbar.clear()
	backpack.clear()
	for _index in HOTBAR_SIZE:
		hotbar.append(ItemStack.new())
	for _index in BACKPACK_SIZE:
		backpack.append(ItemStack.new())

func _restore_container(container: Array[ItemStack], saved: Array, expected_size: int) -> void:
	for index in mini(saved.size(), expected_size):
		container[index] = ItemStack.from_state(saved[index])
