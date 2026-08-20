class_name TestShopTerminal
extends Area2D

const IDLE_SHEET := preload("res://assets/art/characters/npc/animation/shopkeeper/ShopkeeperIdle-32x48-4FPS.png")

@export var persistent_id := "test_shop"
@export var interaction_priority := 30
@export var shop_definition: ShopDefinition

@onready var visual: AnimatedSprite2D = $Visual
var service: ShopService

func _ready() -> void:
	_setup_visual()
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

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", 4.0)
	frames.set_animation_loop(&"idle", true)
	for index in 4:
		var frame := AtlasTexture.new()
		frame.atlas = IDLE_SHEET
		frame.region = Rect2(index * 32, 0, 32, 48)
		frames.add_frame(&"idle", frame)
	visual.sprite_frames = frames
	visual.play(&"idle")
