extends Node

func _ready() -> void:
	GameSession.start_new_run(2026)
	var inventory := InventoryModel.new()
	assert(inventory.try_add_item(&"lantern_crystal", 2))
	var definition := ShopDefinition.new()
	definition.shop_id = &"smoke_shop"
	definition.limited_stock = true
	definition.stock = {&"multitool": 1}
	var shop := ShopService.new(definition)
	assert(shop.get_buy_rows().size() == 1)
	assert(shop.get_sell_rows(inventory)[0].quantity == 2)
	assert(shop.try_buy(inventory, &"multitool"))
	assert(GameSession.money == 10)
	assert(not shop.try_buy(inventory, &"multitool"))
	assert(shop.try_sell(inventory, &"lantern_crystal", 2))
	assert(GameSession.money == 110)
	var layer2 := ShopService.new(ContentCatalog.get_shop(&"layer2_shop"))
	assert(layer2.get_buy_price(&"bandage") == 38)
	assert(layer2.get_sell_price(&"lantern_crystal") == 38)
	var ui := preload("res://ui/shop_ui.tscn").instantiate()
	add_child(ui)
	await get_tree().process_frame
	assert(ui is ShopUI)
	print("SHOP_SMOKE_OK")
	get_tree().quit()
