class_name ShopItemRow
extends Control

signal activated(mode: StringName, item_id: StringName, maximum_quantity: int, unit_price: int)

@onready var background: NinePatchRect = $Background
@onready var icon: TextureRect = $Icon
@onready var item_name: Label = $ItemName
@onready var price: Label = $Price
@onready var amount: Label = $Amount
@onready var action_button: Button = $Action

const BUY_BACKGROUND := preload("res://assets/art/ui/shopkeeper/shop-box-container-buy.png")
const SELL_BACKGROUND := preload("res://assets/art/ui/shopkeeper/shop-box-container-sell.png")
const DISABLED_BACKGROUND := preload("res://assets/art/ui/shopkeeper/shop-box-container-disabled.png")

var mode: StringName
var item_id: StringName
var maximum_quantity := 0
var unit_price := 0

func _ready() -> void:
	action_button.pressed.connect(func(): activated.emit(mode, item_id, maximum_quantity, unit_price))

func bind_buy(id: StringName, item_icon: Texture2D, display_name: String, stock_amount: int, cost: int, enabled := true) -> void:
	_bind(&"buy", id, item_icon, display_name, stock_amount, cost, enabled)
	action_button.text = "+"
	amount.text = "x%d" % stock_amount if stock_amount >= 0 else "∞"

func bind_sell(id: StringName, item_icon: Texture2D, display_name: String, quantity: int, value: int) -> void:
	_bind(&"sell", id, item_icon, display_name, quantity, value, quantity > 0)
	action_button.text = "-"
	amount.text = "x%d" % quantity

func _bind(row_mode: StringName, id: StringName, item_icon: Texture2D, display_name: String, maximum: int, value: int, enabled: bool) -> void:
	mode = row_mode
	item_id = id
	maximum_quantity = maximum
	unit_price = value
	icon.texture = item_icon
	item_name.text = display_name
	price.text = "%dg" % value
	background.texture = BUY_BACKGROUND if mode == &"buy" else SELL_BACKGROUND
	if not enabled:
		background.texture = DISABLED_BACKGROUND
	action_button.disabled = not enabled
	modulate = Color.WHITE if enabled else Color(0.65, 0.65, 0.65, 1.0)
