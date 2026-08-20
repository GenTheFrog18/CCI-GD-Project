class_name DazzledOverlay
extends CanvasLayer

@export_range(0.0, 5.0, 0.05) var fade_in_seconds := 1.0
@export_range(0.0, 5.0, 0.05) var ninety_percent_hold_seconds := 2.0
@export_range(0.0, 1.0, 0.05) var screenshot_opacity := 1.0
@export_range(0.0, 1.0, 0.05) var white_opacity := 1.0

@onready var _layers: Control = $Layers
@onready var _screenshot: TextureRect = $Layers/Screenshot
@onready var _white_fill: ColorRect = $Layers/WhiteFill
var _duration := 0.0
var _elapsed := 0.0
var _active := false

func _ready() -> void:
	_screenshot.modulate.a = clampf(screenshot_opacity, 0.0, 1.0)
	_white_fill.modulate.a = clampf(white_opacity, 0.0, 1.0)
	_layers.modulate.a = 0.0

func start_flash(duration: float) -> void:
	var image := get_viewport().get_texture().get_image()
	if image == null:
		return
	_screenshot.texture = ImageTexture.create_from_image(image)
	_duration = maxf(duration, 0.0)
	_elapsed = 0.0
	_active = _duration > 0.0
	_layers.modulate.a = 0.0

func stop_flash() -> void:
	_active = false
	_layers.modulate.a = 0.0

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= _duration:
		stop_flash()
		return

	var fade_in := maxf(fade_in_seconds, 0.0)
	var opacity := 1.0
	if fade_in > 0.0 and _elapsed < fade_in:
		opacity = _elapsed / fade_in
	else:
		var hold_end := fade_in + minf(maxf(ninety_percent_hold_seconds, 0.0), maxf(_duration - fade_in, 0.0))
		if _elapsed < hold_end:
			opacity = 0.9
		else:
			var fade_out_duration := maxf(_duration - hold_end, 0.001)
			opacity = 0.9 * clampf((_duration - _elapsed) / fade_out_duration, 0.0, 1.0)
	_layers.modulate.a = opacity
