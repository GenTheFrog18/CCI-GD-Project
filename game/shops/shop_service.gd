class_name ShopService
extends RefCounted

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
	var cost := roundi(item.purchase_price * definition.price_multiplier) * quantity
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
	return true

func try_sell_active(inventory: InventoryModel, quantity := 1) -> bool:
	var stack := inventory.get_active_stack()
	var item := ContentCatalog.get_item(stack.item_id)
	if definition == null or item == null or not item.sellable or stack.quantity < quantity:
		return false
	var value := roundi(item.surface_sale_value * definition.price_multiplier) * quantity
	if not inventory.remove_active(quantity):
		return false
	GameSession.add_money(value)
	if definition.counts_delivery:
		GameSession.add_delivery(item.delivery_value * quantity)
	return true

func capture_state() -> Dictionary:
	var serialized: Dictionary = {}
	for item_id in stock:
		serialized[String(item_id)] = stock[item_id]
	return {"shop_id": String(definition.shop_id) if definition != null else "", "stock": serialized}

func restore_state(data: Dictionary) -> void:
	stock.clear()
	for item_id in data.get("stock", {}):
		stock[StringName(item_id)] = int(data.stock[item_id])
