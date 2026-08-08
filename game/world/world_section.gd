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
	if respawn_anchor != null and respawn_anchor.position != Vector2(SEAM_X, 64.0):
		errors.append("WorldSection %s respawn anchor must be at (640, 64)" % slot_id)
	if entry_clearance != Rect2(592.0, 0.0, 96.0, 96.0):
		errors.append("WorldSection %s entry clearance is invalid" % slot_id)
	if exit_clearance != Rect2(592.0, 704.0, 96.0, 96.0):
		errors.append("WorldSection %s exit clearance is invalid" % slot_id)
	if placer_root == null:
		errors.append("WorldSection %s placer root missing" % slot_id)
	if dynamic_root == null:
		errors.append("WorldSection %s authored content root missing" % slot_id)
	return errors
