class_name HitFlash
extends Node

const FLASH_SECONDS := 0.05
const GAP_SECONDS := 0.04
const WHITE_SHADER := """
shader_type canvas_item;
void fragment() {
	vec4 pixel = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(vec3(1.0), pixel.a);
}
"""

var _visual: CanvasItem
var _normal_material: Material
var _white_material: ShaderMaterial
var _sequence: Tween

func setup(actor: Node) -> bool:
	_visual = _find_visual(actor)
	if _visual == null:
		return false
	var shader := Shader.new()
	shader.code = WHITE_SHADER
	_white_material = ShaderMaterial.new()
	_white_material.shader = shader
	return true

func play(pulses: int) -> void:
	if _visual == null or pulses <= 0:
		return
	if _sequence != null and _sequence.is_valid():
		_sequence.kill()
		_visual.material = _normal_material
	_normal_material = _visual.material
	_visual.material = _white_material
	_sequence = create_tween()
	for index in pulses:
		_sequence.tween_interval(FLASH_SECONDS)
		_sequence.tween_callback(func(): _visual.material = _normal_material)
		if index + 1 < pulses:
			_sequence.tween_interval(GAP_SECONDS)
			_sequence.tween_callback(func(): _visual.material = _white_material)

func _find_visual(actor: Node) -> CanvasItem:
	for type in [&"AnimatedSprite2D", &"Sprite2D", &"Polygon2D"]:
		for candidate in actor.find_children("*", type, true, false):
			if candidate is CanvasItem and candidate.visible:
				return candidate as CanvasItem
	return null
