@tool
class_name DarknessRegion2D
extends Polygon2D

@export var region_id: StringName
@export_range(0.0, 1.0, 0.01) var darkness_strength := 0.85
@export_range(0.0, 256.0, 1.0) var edge_falloff_pixels := 32.0
@export var enabled := true

func _ready() -> void:
	add_to_group(&"darkness_regions")
	visible = Engine.is_editor_hint()
	queue_redraw()

func world_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in polygon:
		points.append(to_global(point))
	return points

func world_bounds() -> Rect2:
	var points := world_polygon()
	if points.is_empty():
		return Rect2(global_position, Vector2.ZERO)
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds

func validate_against(_bounds: Rect2) -> PackedStringArray:
	var errors := PackedStringArray()
	if region_id.is_empty():
		errors.append("DarknessRegion2D has blank region_id")
	if polygon.size() < 3:
		errors.append("DarknessRegion2D %s needs at least 3 polygon points" % region_id)
	if darkness_strength < 0.0 or darkness_strength > 1.0:
		errors.append("DarknessRegion2D %s has invalid darkness_strength" % region_id)
	if edge_falloff_pixels < 0.0:
		errors.append("DarknessRegion2D %s has negative edge_falloff_pixels" % region_id)
	return errors

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	if polygon.size() < 3:
		return
	var fill := Color(0.12, 0.16, 0.24, clampf(darkness_strength * 0.35, 0.08, 0.35))
	draw_colored_polygon(polygon, fill)
	var outline := PackedVector2Array(polygon)
	outline.append(polygon[0])
	draw_polyline(outline, Color(0.35, 0.65, 1.0, 0.9), 2.0)
	if edge_falloff_pixels > 0.0:
		var center := Vector2.ZERO
		for point in polygon:
			center += point
		center /= polygon.size()
		var falloff := PackedVector2Array()
		for point in polygon:
			var direction := point - center
			falloff.append(center + direction.normalized() * (direction.length() + edge_falloff_pixels))
		falloff.append(falloff[0])
		draw_polyline(falloff, Color(0.35, 0.65, 1.0, 0.35), 1.0)
	draw_string(ThemeDB.fallback_font, polygon[0] + Vector2(4.0, 16.0), String(region_id), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
