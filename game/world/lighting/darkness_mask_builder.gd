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
		_rasterize_polygon(image, layer_bounds, region)
	return ImageTexture.create_from_image(image)

func _rasterize_polygon(image: Image, layer_bounds: Rect2, region: DarknessRegion2D) -> void:
	var polygon := region.world_polygon()
	if polygon.size() < 3:
		return
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	var falloff := region.edge_falloff_pixels
	var min_x := maxi(0, floori((bounds.position.x - layer_bounds.position.x - falloff) / TILE_SIZE))
	var max_x := mini(image.get_width() - 1, ceili((bounds.end.x - layer_bounds.position.x + falloff) / TILE_SIZE))
	var min_y := maxi(0, floori((bounds.position.y - layer_bounds.position.y - falloff) / TILE_SIZE))
	var max_y := mini(image.get_height() - 1, ceili((bounds.end.y - layer_bounds.position.y + falloff) / TILE_SIZE))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var point := layer_bounds.position + Vector2((x + 0.5) * TILE_SIZE, (y + 0.5) * TILE_SIZE)
			var inside := _point_in_polygon(point, polygon)
			var strength := region.darkness_strength if inside else 0.0
			if not inside and falloff > 0.0:
				var distance := _distance_to_polygon(point, polygon)
				strength = region.darkness_strength * _smooth_falloff(1.0 - distance / falloff)
			if strength <= 0.0:
				continue
			var current := image.get_pixel(x, y).r
			image.set_pixel(x, y, Color(current + strength, 0.0, 0.0, 1.0))

func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	var previous := polygon[polygon.size() - 1]
	for current in polygon:
		var crosses := (current.y > point.y) != (previous.y > point.y)
		if crosses and point.x < (previous.x - current.x) * (point.y - current.y) / (previous.y - current.y) + current.x:
			inside = not inside
		previous = current
	return inside

func _distance_to_polygon(point: Vector2, polygon: PackedVector2Array) -> float:
	var distance := INF
	for index in polygon.size():
		var start := polygon[index]
		var end := polygon[(index + 1) % polygon.size()]
		distance = minf(distance, _distance_to_segment(point, start, end))
	return distance

func _distance_to_segment(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment := end - start
	if segment.length_squared() <= 0.000001:
		return point.distance_to(start)
	var factor := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * factor)

func _smooth_falloff(value: float) -> float:
	var normalized := clampf(value, 0.0, 1.0)
	return normalized * normalized * (3.0 - 2.0 * normalized)
