class_name SoundEvent
extends RefCounted

var position := Vector2.ZERO
var radius := 0.0
var sound_type: StringName
var priority := 0
var source: Node
var timestamp := 0
var intensity := 0.0

func _init(at := Vector2.ZERO, range := 0.0, type: StringName = &"generic", importance := 0, source_node: Node = null, strength := -1.0) -> void:
	position = at
	radius = range
	sound_type = type
	priority = importance
	source = source_node
	intensity = float(importance) if strength < 0.0 else strength
	timestamp = Time.get_ticks_msec()
