class_name TestShopTerminal
extends Area2D

@export var persistent_id := "test_shop"
@export var interaction_priority := 30

var service: ShopService

func _ready() -> void:
	add_to_group(&"interactables")
	add_to_group(&"persistent_objects")
	service = ShopService.new(ContentCatalog.get_shop(&"test_shop"))

func get_interaction_prompt(_actor: Node) -> String:
	return "Buy Multitool (40g)"

func interact(actor: Node) -> bool:
	if not actor is PlayerController:
		return false
	var success := service.try_buy(actor.item_controller.inventory, &"multitool")
	actor.item_controller.feedback_requested.emit("Bought Multitool" if success else "Cannot buy Multitool")
	return success

func capture_state() -> Dictionary:
	return service.capture_state()

func restore_state(data: Dictionary) -> void:
	service.restore_state(data)
