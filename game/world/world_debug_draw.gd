class_name WorldDebugDraw
extends Node2D

var world_layer: WorldLayer
var enabled := false

func refresh(layer: WorldLayer, show: bool) -> void:
	world_layer = layer
	enabled = show
	queue_redraw()

func _draw() -> void:
	if not enabled or world_layer == null:
		return
	for slot in world_layer.get_slots():
		var section := world_layer.instantiated_sections.get(String(slot.slot_id)) as WorldSection
		if section == null:
			continue
		var color := Color(0.2, 1.0, 0.4, 0.9) if world_layer.active_slot_ids.has(String(slot.slot_id)) else Color(1.0, 0.8, 0.2, 0.45)
		var bounds := Rect2(section.global_position + section.camera_bounds.position, section.camera_bounds.size)
		draw_rect(bounds, color, false, 2.0)
		draw_rect(Rect2(section.global_position + section.entry_clearance.position, section.entry_clearance.size), Color.CYAN, false, 2.0)
		draw_rect(Rect2(section.global_position + section.exit_clearance.position, section.exit_clearance.size), Color.CYAN, false, 2.0)
