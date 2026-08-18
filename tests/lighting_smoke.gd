extends Node

func _ready() -> void:
	var builder := DarknessMaskBuilder.new()
	var region := DarknessRegion2D.new()
	region.region_id = &"smoke"
	region.region_rect = Rect2(16.0, 16.0, 32.0, 32.0)
	region.edge_falloff_pixels = 0.0
	var texture := builder.build_mask(Rect2(0.0, 0.0, 64.0, 64.0), [region])
	var image := texture.get_image()
	assert(image.get_pixel(2, 2).r > 0.8)
	assert(is_zero_approx(image.get_pixel(0, 0).r))

	var controller := WorldLightingController.new()
	add_child(controller)
	controller.build(Rect2(0.0, 0.0, 64.0, 64.0), [])
	var source := LightSource2D.new()
	add_child(source)
	await get_tree().process_frame
	assert(controller._lights.size() == 1)
	source.queue_free()
	await get_tree().process_frame
	assert(controller._lights.is_empty())
	print("LIGHTING_SMOKE_OK")
	get_tree().quit()
