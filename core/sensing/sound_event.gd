class_name SoundEvent
extends RefCounted

var position := Vector2.ZERO
var radius := 0.0
var sound_type: StringName
var priority := 0
var source: Node
var timestamp := 0

func _init(at := Vector2.ZERO, range := 0.0, type: StringName = &"generic", importance := 0, source_node: Node = null) -> void:
	position = at
	radius = range
	sound_type = type
	priority = importance
	source = source_node
	timestamp = Time.get_ticks_msec()
