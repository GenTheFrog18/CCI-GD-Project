class_name ShopConfirmation
extends Control

signal completed(confirmed: bool, quantity: int)

@onready var item_name: Label = $Panel/ItemName
@onready var quantity_label: Label = $Panel/QuantityRow/Quantity
@onready var total_label: Label = $Panel/Total
@onready var minus: Button = $Panel/QuantityRow/Minus
@onready var plus: Button = $Panel/QuantityRow/Plus
@onready var yes: TextureButton = $Panel/Actions/Yes
@onready var no: TextureButton = $Panel/Actions/No

var maximum_quantity := 1
var unit_price := 0
var quantity := 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	minus.pressed.connect(func(): _change_quantity(-1))
	plus.pressed.connect(func(): _change_quantity(1))
	yes.pressed.connect(func(): _finish(true))
	no.pressed.connect(func(): _finish(false))
	hide()

func open_confirmation(display_name: String, price: int, maximum: int) -> void:
	maximum_quantity = maxi(1, maximum)
	unit_price = maxi(0, price)
	quantity = 1
	item_name.text = display_name
	show()
	_update()
	yes.grab_focus()

func cancel() -> void:
	if visible:
		_finish(false)

func _change_quantity(delta: int) -> void:
	quantity = clampi(quantity + delta, 1, maximum_quantity)
	_update()

func _update() -> void:
	quantity_label.text = "[%d]" % quantity
	total_label.text = "Total: %dg" % (unit_price * quantity)
	minus.disabled = quantity <= 1
	plus.disabled = quantity >= maximum_quantity

func _finish(confirmed: bool) -> void:
	var result_quantity := quantity if confirmed else 0
	hide()
	completed.emit(confirmed, result_quantity)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_finish(false)
		get_viewport().set_input_as_handled()
