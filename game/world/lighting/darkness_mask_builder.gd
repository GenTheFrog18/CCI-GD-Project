class_name DarknessMaskBuilder
extends RefCounted

const TILE_SIZE := 16.0

func build_mask(layer_bounds: Rect2, regions: Array[DarknessRegion2D]) -> ImageTexture:
	var size := Vector2i(ceili(layer_bounds.size.x / TILE_SIZE), ceili(layer_bounds.size.y / TILE_SIZE))
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RF)
	image.fill(Color(0.0, 0.0, 0.0, 1.0))
	for region in regions:
		if not is_instance_valid(region) or not region.enabled:
			continue
		_rasterize_rect(image, layer_bounds, region)
	return ImageTexture.create_from_image(image)

func _rasterize_rect(image: Image, layer_bounds: Rect2, region: DarknessRegion2D) -> void:
	var rect := region.world_rect()
	var falloff := region.edge_falloff_pixels
	var min_x := maxi(0, floori((rect.position.x - layer_bounds.position.x - falloff) / TILE_SIZE))
	var max_x := mini(image.get_width() - 1, ceili((rect.end.x - layer_bounds.position.x + falloff) / TILE_SIZE))
	var min_y := maxi(0, floori((rect.position.y - layer_bounds.position.y - falloff) / TILE_SIZE))
	var max_y := mini(image.get_height() - 1, ceili((rect.end.y - layer_bounds.position.y + falloff) / TILE_SIZE))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var point := layer_bounds.position + Vector2((x + 0.5) * TILE_SIZE, (y + 0.5) * TILE_SIZE)
			var strength := region.darkness_strength
			if falloff > 0.0:
				var distance := _distance_to_rect(point, rect)
				if rect.has_point(point):
					strength *= clampf(distance / falloff, 0.0, 1.0)
				else:
					strength *= 1.0 - smoothstep(0.0, falloff, distance)
			elif not rect.has_point(point):
				continue
			var current := image.get_pixel(x, y).r
			if strength > current:
				image.set_pixel(x, y, Color(strength, 0.0, 0.0, 1.0))

func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var outside := Vector2(
		maxf(rect.position.x - point.x, maxf(point.x - rect.end.x, 0.0)),
		maxf(rect.position.y - point.y, maxf(point.y - rect.end.y, 0.0))
	)
	if outside.length_squared() > 0.0:
		return outside.length()
	return minf(minf(point.x - rect.position.x, rect.end.x - point.x), minf(point.y - rect.position.y, rect.end.y - point.y))
