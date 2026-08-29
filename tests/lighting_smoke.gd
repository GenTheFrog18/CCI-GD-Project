extends Node

func _ready() -> void:
	var builder := DarknessMaskBuilder.new()
	var region := DarknessRegion2D.new()
	region.region_id = &"smoke"
	region.polygon = PackedVector2Array([Vector2(16.0, 16.0), Vector2(48.0, 16.0), Vector2(48.0, 48.0), Vector2(16.0, 48.0)])
	region.edge_falloff_pixels = 0.0
	var texture := builder.build_mask(Rect2(0.0, 0.0, 64.0, 64.0), [region])
	var image := texture.get_image()
	assert(image.get_pixel(2, 2).r > 0.8)
	assert(is_zero_approx(image.get_pixel(0, 0).r))
	var falloff_region := DarknessRegion2D.new()
	falloff_region.region_id = &"falloff"
	falloff_region.polygon = PackedVector2Array([Vector2(16.0, 16.0), Vector2(48.0, 16.0), Vector2(48.0, 48.0), Vector2(16.0, 48.0)])
	falloff_region.edge_falloff_pixels = 16.0
	var falloff_image := builder.build_mask(Rect2(0.0, 0.0, 64.0, 64.0), [falloff_region]).get_image()
	assert(falloff_image.get_pixel(2, 2).r > 0.8)
	assert(falloff_image.get_pixel(3, 2).r > 0.0)
	var overlap_region := DarknessRegion2D.new()
	overlap_region.region_id = &"overlap"
	overlap_region.darkness_strength = 0.75
	overlap_region.polygon = PackedVector2Array([Vector2(16.0, 16.0), Vector2(48.0, 16.0), Vector2(48.0, 48.0), Vector2(16.0, 48.0)])
	var overlap_region_2 := DarknessRegion2D.new()
	overlap_region_2.region_id = &"overlap_2"
	overlap_region_2.darkness_strength = 0.75
	overlap_region_2.polygon = overlap_region.polygon
	var overlap_image := builder.build_mask(Rect2(0.0, 0.0, 64.0, 64.0), [overlap_region, overlap_region_2]).get_image()
	assert(is_equal_approx(overlap_image.get_pixel(2, 2).r, 1.5))
	var invalid_region := DarknessRegion2D.new()
	invalid_region.region_id = &"invalid"
	var invalid_image := builder.build_mask(Rect2(0.0, 0.0, 64.0, 64.0), [invalid_region]).get_image()
	assert(is_zero_approx(invalid_image.get_pixel(2, 2).r))
	var outside_region := DarknessRegion2D.new()
	outside_region.region_id = &"outside"
	outside_region.polygon = PackedVector2Array([Vector2(-16.0, 16.0), Vector2(16.0, 16.0), Vector2(16.0, 48.0), Vector2(-16.0, 48.0)])
	assert(outside_region.validate_against(Rect2(0.0, 0.0, 64.0, 64.0)).is_empty())
	var outside_image := builder.build_mask(Rect2(0.0, 0.0, 64.0, 64.0), [outside_region]).get_image()
	assert(outside_image.get_pixel(0, 2).r > 0.0)

	var controller := WorldLightingController.new()
	add_child(controller)
	controller.build(Rect2(0.0, 0.0, 64.0, 64.0), [])
	assert(not controller.overlay.visible)
	controller.build(Rect2(0.0, 0.0, 64.0, 64.0), [region])
	assert(controller.overlay.visible)
	var viewport := get_viewport()
	var original_canvas_transform := viewport.get_canvas_transform()
	var original_global_canvas_transform := viewport.get_global_canvas_transform()
	var camera_transform := Transform2D(0.0, Vector2(-96.0, 48.0))
	var display_transform := Transform2D().scaled(Vector2(2.0, 2.0))
	viewport.set_global_canvas_transform(display_transform)
	viewport.set_canvas_transform(camera_transform)
	controller._process(0.0)
	var world_to_screen := viewport.get_final_transform() * camera_transform
	var expected_inverse := world_to_screen.affine_inverse()
	assert((controller.overlay._material.get_shader_parameter(&"screen_to_world_origin") as Vector2).is_equal_approx(expected_inverse.origin))
	var world_point := Vector2(37.0, 29.0)
	assert((expected_inverse * (world_to_screen * world_point)).is_equal_approx(world_point))
	viewport.set_global_canvas_transform(original_global_canvas_transform)
	viewport.set_canvas_transform(original_canvas_transform)
	controller._process(0.0)
	var source := LightSource2D.new()
	add_child(source)
	await get_tree().process_frame
	assert(controller._lights.size() == 1)
	source.queue_free()
	await get_tree().process_frame
	assert(controller._lights.is_empty())
	print("LIGHTING_SMOKE_OK")
	get_tree().quit()
