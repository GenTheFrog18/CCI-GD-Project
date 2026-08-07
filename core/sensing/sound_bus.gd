class_name SoundBus
extends RefCounted

static func emit_sound(tree: SceneTree, event: SoundEvent) -> void:
	if tree != null:
		tree.call_group(&"sound_listeners", &"hear_sound", event)
