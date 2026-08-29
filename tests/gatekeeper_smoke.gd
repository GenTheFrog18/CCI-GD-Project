extends Node

func _ready() -> void:
	var diver := preload("res://game/enemies/layer1/senior_diver.tscn").instantiate() as SeniorDiver
	add_child(diver)
	assert(diver.first_warning_dialogue != null)
	assert(diver.escalation_dialogue != null)
	assert(diver.grab_dialogue != null)
	assert(diver.blue_intro_dialogue != null)
	assert(diver.blue_intro_dialogue.entries.size() == 5)
	assert(diver.get_node("PlayerProximityPreview").radius_property == &"restricted_radius")
	assert(diver.collision_mask & 2 != 0)
	assert(diver.facing_direction == 1.0)
	diver._update_visual()
	assert(not diver.visual.flip_h)
	diver._last_known_position = Vector2(-10.0, 0.0)
	diver._has_last_known_position = true
	diver._update_visual()
	assert(diver.visual.flip_h)
	assert(diver.visual.sprite_frames.get_frame_count(&"idle") == 4)
	assert(diver.visual.sprite_frames.get_frame_count(&"walk") == 6)
	assert(diver.visual.sprite_frames.get_frame_count(&"grab") == 10)
	print("GATEKEEPER_SMOKE_OK")
	get_tree().quit()
