class_name TestShopTerminal
extends Area2D

@export var persistent_id := "test_shop"
@export var interaction_priority := 30
@export var shop_definition: ShopDefinition

var service: ShopService

func _ready() -> void:
	add_to_group(&"interactables")
	add_to_group(&"persistent_objects")
	if shop_definition == null:
		shop_definition = ContentCatalog.get_shop(&"test_shop")
	service = ShopService.new(shop_definition)

func get_interaction_prompt(_actor: Node) -> String:
	return "Open Shop"

func interact(actor: Node) -> bool:
	if not actor is PlayerController:
		return false
	var hud := get_tree().get_first_node_in_group(&"foundation_hud") as FoundationHUD
	if hud == null:
		return false
	hud.open_shop(service, actor)
	return true

func capture_state() -> Dictionary:
	return service.capture_state()

func restore_state(data: Dictionary) -> void:
	service.restore_state(data)
