class_name DamageInfo
extends RefCounted

var amount := 0.0
var source: Node
var source_species_id: StringName
var force := Vector2.ZERO
var tags: Array[StringName] = []
var bypass_invulnerability := false
var causes_hit_reaction := true

func _init(value := 0.0, source_node: Node = null, species: StringName = &"", impulse := Vector2.ZERO) -> void:
	amount = value
	source = source_node
	source_species_id = species
	force = impulse
