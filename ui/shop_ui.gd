class_name ShopUI
extends Control

const ROW_SCENE := preload("res://ui/shop_item_row.tscn")

@export_range(0.05, 2.0, 0.01) var backdrop_animation_seconds := 0.25
@export_range(0.0, 500.0, 1.0) var backdrop_drop_pixels := 180.0
@export_range(0.0, 1.0, 0.01) var dimmer_alpha := 0.65

@onready var dimmer: ColorRect = $Dimmer
@onready var backdrop: Control = $Backdrop
@onready var close_button: TextureButton = $Backdrop/Close
@onready var buy_rows: VBoxContainer = $Backdrop/Columns/BuyColumn/BuyScroll/BuyRows
@onready var sell_rows: VBoxContainer = $Backdrop/Columns/SellColumn/SellScroll/SellRows
@onready var confirmation: ShopConfirmation = $Confirmation

var _service: ShopService
var _player: PlayerController
var _inventory: InventoryModel
var _rest_position := Vector2.ZERO
var _pending_mode: StringName
var _pending_item_id: StringName
var _tween: Tween
var _refresh_callable := Callable(self, "_refresh")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rest_position = backdrop.position
	close_button.pressed.connect(close_shop)
	confirmation.completed.connect(_on_confirmation_completed)
	GameSession.money_changed.connect(_refresh_callable)
	hide()

func open_shop(service: ShopService, shop_player: PlayerController) -> void:
	if _player != null and _player != shop_player:
		_player.locks.unlock(&"shop")
	_service = service
	_player = shop_player
	_inventory = shop_player.item_controller.inventory
	_connect_sources()
	_player.locks.lock(&"shop")
	visible = true
	if _tween != null:
		_tween.kill()
	dimmer.color.a = 0.0
	backdrop.position = _rest_position + Vector2(0.0, -backdrop_drop_pixels)
	backdrop.modulate.a = 0.0
	_refresh()
	_tween = create_tween().set_parallel()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(dimmer, "color:a", dimmer_alpha, backdrop_animation_seconds)
	_tween.tween_property(backdrop, "position", _rest_position, backdrop_animation_seconds)
	_tween.tween_property(backdrop, "modulate:a", 1.0, backdrop_animation_seconds)
	close_button.grab_focus()

func close_shop() -> void:
	if not visible:
		return
	if confirmation.visible:
		confirmation.cancel()
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(dimmer, "color:a", 0.0, 0.15)
	_tween.tween_property(backdrop, "position", _rest_position + Vector2(0.0, -backdrop_drop_pixels), 0.15)
	_tween.tween_property(backdrop, "modulate:a", 0.0, 0.15)
	_tween.chain().tween_callback(_finish_close)

func _finish_close() -> void:
	visible = false
	if _player != null:
		_player.locks.unlock(&"shop")
	_pending_mode = &""
	_pending_item_id = &""

func _connect_sources() -> void:
	if _service != null and not _service.changed.is_connected(_refresh_callable):
		_service.changed.connect(_refresh_callable)
	if _inventory != null and not _inventory.changed.is_connected(_refresh_callable):
		_inventory.changed.connect(_refresh_callable)

func _refresh(_ignored = null) -> void:
	if _service == null or _inventory == null:
		return
	_clear_rows(buy_rows)
	_clear_rows(sell_rows)
	for row_data in _service.get_buy_rows():
		var row := ROW_SCENE.instantiate() as ShopItemRow
		buy_rows.add_child(row)
		var item := ContentCatalog.get_item(row_data.item_id)
		if item == null:
			continue
		var stock := int(row_data.stock) if _service.definition.limited_stock else -1
		row.bind_buy(row_data.item_id, item.icon, item.display_name, stock, int(row_data.price), stock != 0 and GameSession.money >= int(row_data.price))
		row.activated.connect(_on_row_activated)
	for row_data in _service.get_sell_rows(_inventory):
		var row := ROW_SCENE.instantiate() as ShopItemRow
		sell_rows.add_child(row)
		var item := ContentCatalog.get_item(row_data.item_id)
		if item == null:
			continue
		row.bind_sell(row_data.item_id, item.icon, item.display_name, int(row_data.quantity), int(row_data.price))
		row.activated.connect(_on_row_activated)

func _clear_rows(container: Node) -> void:
	for child in container.get_children():
		child.free()

func _on_row_activated(mode: StringName, item_id: StringName, maximum: int, unit_price: int) -> void:
	_pending_mode = mode
	_pending_item_id = item_id
	if mode == &"buy" and unit_price > 0:
		maximum = mini(maximum, GameSession.money / unit_price)
	if maximum < 1:
		return
	var item := ContentCatalog.get_item(item_id)
	if item != null:
		confirmation.open_confirmation(item.display_name, unit_price, maximum)

func _on_confirmation_completed(confirmed: bool, quantity: int) -> void:
	if confirmed and _service != null and _inventory != null:
		var success := _service.try_buy(_inventory, _pending_item_id, quantity) if _pending_mode == &"buy" else _service.try_sell(_inventory, _pending_item_id, quantity)
		if _player != null:
			_player.item_controller.feedback_requested.emit("Transaction complete" if success else "Cannot complete transaction")
	_pending_mode = &""
	_pending_item_id = &""
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()
