class_name DarknessOverlay
extends CanvasLayer

@onready var _rect: ColorRect = $DarknessRect
@onready var _material: ShaderMaterial = _rect.material

func apply_mask(mask: Texture2D, bounds: Rect2) -> void:
	_material.set_shader_parameter(&"darkness_mask", mask)
	_material.set_shader_parameter(&"mask_origin", bounds.position)
	_material.set_shader_parameter(&"mask_size", bounds.size)

func apply_camera_transform(canvas_transform: Transform2D) -> void:
	var inverse := canvas_transform.affine_inverse()
	_material.set_shader_parameter(&"screen_to_world", PackedFloat32Array([
		inverse.x.x, inverse.x.y, 0.0,
		inverse.y.x, inverse.y.y, 0.0,
		inverse.origin.x, inverse.origin.y, 1.0,
	]))

func apply_lights(sources: Array[LightSource2D], maximum_sources: int) -> void:
	var positions := PackedVector4Array()
	var parameters := PackedVector4Array()
	for index in maximum_sources:
		positions.append(Vector4.ZERO)
		parameters.append(Vector4.ZERO)
	var count := 0
	for source in sources:
		if count >= maximum_sources or not is_instance_valid(source) or not source.enabled:
			continue
		positions[count] = Vector4(source.global_position.x, source.global_position.y, maxf(source.light_radius, 1.0), 0.0)
		parameters[count] = Vector4(clampf(source.light_intensity, 0.0, 1.0), 0.0, 0.0, 0.0)
		count += 1
	_material.set_shader_parameter(&"light_positions", positions)
	_material.set_shader_parameter(&"light_parameters", parameters)
	_material.set_shader_parameter(&"light_count", count)
