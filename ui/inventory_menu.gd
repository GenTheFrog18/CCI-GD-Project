class_name InventoryMenu
extends Control

const BOOK_SHEET := preload("res://assets/art/ui/inventory/book-inventory-sprite.png")

signal close_requested

@export_range(0.1, 2.0, 0.05) var book_open_seconds := 0.5
@export_range(0.05, 2.0, 0.05) var backpack_enter_seconds := 0.25
@export var backpack_slide_offset := 20.0

@onready var dim: ColorRect = $Dim
@onready var backpack: TextureRect = $Backpack
@onready var book_opening: AnimatedSprite2D = $BookOpening
@onready var book_content: Control = $BookContent
@onready var close_button: TextureButton = $BookContent/Close
@onready var item_name: Label = $BookContent/ItemName
@onready var item_description: Label = $BookContent/ItemDescription
@onready var weight_label: Label = $BookContent/Weight
@onready var whistle_icon: TextureRect = $BookContent/Whistle/Icon

var slot_buttons: Array[InventorySlot] = []
var _backpack_rest_position := Vector2.ZERO
var _open_token := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_book_frames()
	for path in [
		"BookContent/BackpackSlots/Slot0/Button",
		"BookContent/BackpackSlots/Slot1/Button",
		"BookContent/BackpackSlots/Slot2/Button",
		"BookContent/BackpackSlots/Slot3/Button",
		"BookContent/BackpackSlots/Slot4/Button",
		"BookContent/HotbarSlots/Slot0/Button",
		"BookContent/HotbarSlots/Slot1/Button",
	]:
		slot_buttons.append(get_node(path) as InventorySlot)
	_backpack_rest_position = backpack.position
	close_button.pressed.connect(close_requested.emit)
	hide()

func open_menu() -> void:
	_open_token += 1
	show()
	dim.color.a = 0.0
	backpack.position = _backpack_rest_position + Vector2(0.0, backpack_slide_offset)
	backpack.modulate.a = 0.0
	book_opening.frame = 0
	book_opening.show()
	book_opening.play(&"open")
	book_content.hide()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(dim, "color:a", 0.68, backpack_enter_seconds)
	tween.tween_property(backpack, "position", _backpack_rest_position, backpack_enter_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(backpack, "modulate:a", 1.0, backpack_enter_seconds)
	_finish_opening_after_delay(_open_token)

func close_menu() -> void:
	_open_token += 1
	hide()
	book_opening.stop()
	book_content.hide()

func set_slot(index: int, icon: Texture2D, quantity: int, tooltip: String, selected: bool) -> void:
	var button := slot_buttons[index]
	button.icon = icon
	button.tooltip_text = tooltip
	button.text = ""
	var count := button.get_node("Quantity") as Label
	count.text = "x%d" % quantity if quantity > 1 else ""
	var frame := button.get_parent().get_node("Frame") as TextureRect
	frame.modulate = Color(1.0, 0.82, 0.36) if selected else Color.WHITE

func set_details(name_text: String, description_text: String, weight_text: String) -> void:
	item_name.text = name_text
	item_description.text = description_text
	weight_label.text = weight_text

func set_whistle(icon: Texture2D, tooltip: String) -> void:
	whistle_icon.texture = icon
	$BookContent/Whistle.tooltip_text = tooltip

func _finish_opening_after_delay(token: int) -> void:
	await get_tree().create_timer(book_open_seconds).timeout
	if token != _open_token or not visible:
		return
	book_opening.hide()
	book_content.show()

func _build_book_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"open")
	frames.set_animation_speed(&"open", 16.0 / book_open_seconds)
	frames.set_animation_loop(&"open", false)
	for index in 16:
		var frame := AtlasTexture.new()
		frame.atlas = BOOK_SHEET
		frame.region = Rect2(index * 240, 0, 240, 160)
		frames.add_frame(&"open", frame)
	book_opening.sprite_frames = frames
