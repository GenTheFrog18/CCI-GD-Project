@tool
class_name WorldSection
extends Node2D

const REQUIRED_SIZE := Vector2(1280.0, 800.0)
const SEAM_X := 640.0

@export var slot_id: StringName
@export var variation_id: StringName
@export_range(1, 1000, 1) var selection_weight := 1
@export var section_size := REQUIRED_SIZE
@export var camera_bounds := Rect2(Vector2.ZERO, REQUIRED_SIZE)
@export var entry_clearance := Rect2(592.0, 0.0, 96.0, 96.0)
@export var exit_clearance := Rect2(592.0, 704.0, 96.0, 96.0)
@export var special_tags: PackedStringArray = []
@export var entry_anchor: Marker2D
@export var exit_anchor: Marker2D
@export var respawn_anchor: Marker2D
@export var placer_root: Node
@export var dynamic_root: Node
@export var darkness_regions_root: Node

var _ground_traversal_cache: GroundTraversalCache2D

func get_ground_traversal_cache(sample_spacing := 8.0, terrain_collision_mask := 1) -> GroundTraversalCache2D:
	if _ground_traversal_cache == null:
		_ground_traversal_cache = GroundTraversalCache2D.new()
		_ground_traversal_cache.name = "GroundTraversalCache2D"
		add_child(_ground_traversal_cache)
		_ground_traversal_cache.configure(self, sample_spacing, terrain_collision_mask)
	return _ground_traversal_cache

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if slot_id.is_empty():
		errors.append("WorldSection slot_id is blank")
	if variation_id.is_empty():
		errors.append("WorldSection %s variation_id is blank" % slot_id)
	if entry_anchor == null or exit_anchor == null or respawn_anchor == null:
		errors.append("WorldSection %s seam anchor missing" % slot_id)
	if section_size != REQUIRED_SIZE:
		errors.append("WorldSection %s must be 1280x800" % slot_id)
	if camera_bounds.size != section_size:
		errors.append("WorldSection %s camera bounds must match section size" % slot_id)
	if entry_anchor != null and entry_anchor.position != Vector2(SEAM_X, 0.0):
		errors.append("WorldSection %s entry anchor must be at (640, 0)" % slot_id)
	if exit_anchor != null and exit_anchor.position != Vector2(SEAM_X, 800.0):
		errors.append("WorldSection %s exit anchor must be at (640, 800)" % slot_id)
	if respawn_anchor != null and not Rect2(Vector2.ZERO, section_size).has_point(respawn_anchor.position):
		errors.append("WorldSection %s respawn anchor must be inside the section" % slot_id)
	if entry_clearance != Rect2(592.0, 0.0, 96.0, 96.0):
		errors.append("WorldSection %s entry clearance is invalid" % slot_id)
	if exit_clearance != Rect2(592.0, 704.0, 96.0, 96.0):
		errors.append("WorldSection %s exit clearance is invalid" % slot_id)
	if placer_root == null:
		errors.append("WorldSection %s placer root missing" % slot_id)
	if dynamic_root == null:
		errors.append("WorldSection %s authored content root missing" % slot_id)
	var background_walls := get_node_or_null("BackgroundWalls") as TileMapLayer
	if background_walls == null:
		errors.append("WorldSection %s BackgroundWalls missing" % slot_id)
	elif background_walls.collision_enabled:
		errors.append("WorldSection %s BackgroundWalls must have collision disabled" % slot_id)
	if darkness_regions_root == null:
		errors.append("WorldSection %s darkness regions root missing" % slot_id)
	if darkness_regions_root != null:
		for region in darkness_regions_root.get_children():
			if region is DarknessRegion2D:
				errors.append_array(region.validate_against(Rect2(global_position, section_size)))
	return errors

func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, section_size), Color(0.15, 0.9, 1.0, 0.9), false, 4.0)
