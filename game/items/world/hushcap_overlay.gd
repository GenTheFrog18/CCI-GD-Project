class_name HushcapOverlay
extends CanvasLayer

@export_range(0.0, 1.0, 0.05) var layer_25_opacity := 0.25
@export_range(0.0, 1.0, 0.05) var layer_50_opacity := 0.50
@export_range(0.0, 1.0, 0.05) var layer_75_opacity := 0.75
@export_range(0.0, 1.0, 0.05) var layer_100_opacity := 1.0
@export_range(0.0, 5.0, 0.05) var fade_in_seconds := 0.25
@export_range(0.0, 5.0, 0.05) var fade_out_seconds := 0.35

@onready var _layer_25: TextureRect = $Layers/Layer25
@onready var _layer_50: TextureRect = $Layers/Layer50
@onready var _layer_75: TextureRect = $Layers/Layer75
@onready var _layer_100: TextureRect = $Layers/Layer100
@onready var _layers: Control = $Layers
var _fade_tween: Tween

func _ready() -> void:
	_set_layer_opacity(_layer_25, layer_25_opacity)
	_set_layer_opacity(_layer_50, layer_50_opacity)
	_set_layer_opacity(_layer_75, layer_75_opacity)
	_set_layer_opacity(_layer_100, layer_100_opacity)
	_layers.modulate.a = 0.0

func set_active(active: bool) -> void:
	var target := 1.0 if active else 0.0
	if is_equal_approx(_layers.modulate.a, target):
		return
	if _fade_tween != null:
		_fade_tween.kill()
	var seconds := fade_in_seconds if active else fade_out_seconds
	if seconds <= 0.0:
		_layers.modulate.a = target
		return
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_property(_layers, "modulate:a", target, seconds)

func _set_layer_opacity(layer: TextureRect, opacity: float) -> void:
	var tint := layer.modulate
	tint.a = clampf(opacity, 0.0, 1.0)
	layer.modulate = tint
