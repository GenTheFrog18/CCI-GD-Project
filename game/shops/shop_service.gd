class_name ShopService
extends RefCounted

signal changed

var definition: ShopDefinition
var stock: Dictionary = {}

func _init(shop_definition: ShopDefinition = null) -> void:
	definition = shop_definition
	if definition != null:
		stock = definition.stock.duplicate(true)

func try_buy(inventory: InventoryModel, item_id: StringName, quantity := 1) -> bool:
	if definition == null or quantity <= 0:
		return false
	var item := ContentCatalog.get_item(item_id)
	if item == null:
		return false
	var cost := get_buy_price(item_id) * quantity
	if GameSession.money < cost:
		return false
	if definition.limited_stock and int(stock.get(item_id, 0)) < quantity:
		return false
	var purchase_state := {"origin": "purchased"}
	if not inventory.can_add_item(item_id, quantity, purchase_state):
		return false
	if not inventory.try_add_item(item_id, quantity, purchase_state):
		return false
	if not GameSession.try_spend(cost):
		push_error("Shop prevalidation failed after inventory commit")
		return false
	if definition.limited_stock:
		stock[item_id] = int(stock[item_id]) - quantity
	changed.emit()
	return true

func try_sell_active(inventory: InventoryModel, quantity := 1) -> bool:
	var stack := inventory.get_active_stack()
	return try_sell(inventory, stack.item_id, quantity)

func try_sell(inventory: InventoryModel, item_id: StringName, quantity := 1) -> bool:
	var item := ContentCatalog.get_item(item_id)
	if definition == null or item == null or not item.sellable or quantity <= 0:
		return false
	var value := get_sell_price(item_id) * quantity
	if not inventory.remove_item(item_id, quantity):
		return false
	GameSession.add_money(value)
	if definition.counts_delivery:
		GameSession.add_delivery(item.delivery_value * quantity)
	changed.emit()
	return true

func get_buy_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if definition == null:
		return rows
	for raw_id in definition.stock.keys():
		var item_id := StringName(raw_id)
		var item := ContentCatalog.get_item(item_id)
		if item == null:
			continue
		rows.append({"item_id": item_id, "stock": int(stock.get(item_id, definition.stock[raw_id])), "price": get_buy_price(item_id)})
	rows.sort_custom(func(a: Dictionary, b: Dictionary): return String(a.item_id) < String(b.item_id))
	return rows

func get_sell_rows(inventory: InventoryModel) -> Array[Dictionary]:
	var quantities: Dictionary = {}
	for container in [inventory.hotbar, inventory.backpack]:
		for stack in container:
			if stack.is_empty():
				continue
			var item := ContentCatalog.get_item(stack.item_id)
			if item == null or not item.sellable:
				continue
			quantities[stack.item_id] = int(quantities.get(stack.item_id, 0)) + stack.quantity
	var rows: Array[Dictionary] = []
	for item_id in quantities:
		rows.append({"item_id": item_id, "quantity": quantities[item_id], "price": get_sell_price(item_id)})
	rows.sort_custom(func(a: Dictionary, b: Dictionary): return String(a.item_id) < String(b.item_id))
	return rows

func get_buy_price(item_id: StringName) -> int:
	var item := ContentCatalog.get_item(item_id)
	return roundi(item.purchase_price * definition.buy_price_multiplier) if item != null and definition != null else 0

func get_sell_price(item_id: StringName) -> int:
	var item := ContentCatalog.get_item(item_id)
	return roundi(item.surface_sale_value * definition.sell_price_multiplier) if item != null and definition != null else 0

func capture_state() -> Dictionary:
	var serialized: Dictionary = {}
	for item_id in stock:
		serialized[String(item_id)] = stock[item_id]
	return {"shop_id": String(definition.shop_id) if definition != null else "", "stock": serialized}

func restore_state(data: Dictionary) -> void:
	stock.clear()
	for item_id in data.get("stock", {}):
		stock[StringName(item_id)] = int(data.stock[item_id])
	changed.emit()
