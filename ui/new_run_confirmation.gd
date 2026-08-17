class_name NewRunConfirmation
extends Control

signal confirmed

@export_range(0.01, 2.0, 0.01) var popup_animation_seconds := 0.15
@export_range(0.0, 64.0, 1.0) var popup_slide_pixels := 12.0

var _tween: Tween

@onready var dimmer: ColorRect = $Dimmer
@onready var card: Control = $Card
@onready var cancel_button: Button = $Card/Actions/Cancel
@onready var start_button: Button = $Card/Actions/StartNewRun

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 11
	visible = false
	cancel_button.pressed.connect(close_popup)
	start_button.pressed.connect(func(): confirmed.emit(); close_popup())

func show_popup() -> void:
	visible = true
	dimmer.color.a = 0.0
	card.modulate.a = 0.0
	card.position = Vector2(-180.0, -100.0 + popup_slide_pixels)
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(dimmer, "color:a", 0.55, popup_animation_seconds)
	_tween.tween_property(card, "modulate:a", 1.0, popup_animation_seconds)
	_tween.tween_property(card, "position:y", -100.0, popup_animation_seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	start_button.grab_focus()

func close_popup() -> void:
	if _tween != null:
		_tween.kill()
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close_popup()
		get_viewport().set_input_as_handled()
