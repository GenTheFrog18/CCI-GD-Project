extends Node

func _ready() -> void:
	var diver := preload("res://game/enemies/layer1/senior_diver.tscn").instantiate() as SeniorDiver
	add_child(diver)
	assert(diver.first_warning_dialogue != null)
	assert(diver.escalation_dialogue != null)
	assert(diver.grab_dialogue != null)
	assert(diver.visual.sprite_frames.get_frame_count(&"idle") == 4)
	assert(diver.visual.sprite_frames.get_frame_count(&"walk") == 6)
	assert(diver.visual.sprite_frames.get_frame_count(&"grab") == 10)
	print("GATEKEEPER_SMOKE_OK")
	get_tree().quit()
