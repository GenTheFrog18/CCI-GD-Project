class_name ImpactData
extends RefCounted

enum TerrainResponse { STOP, BOUNCE, STICK, BREAK, DISAPPEAR }

var source_actor: Node
var source_species_id: StringName
var base_damage := 0.0
var mass := 1.0
var velocity := Vector2.ZERO
var damage_multiplier_min := 0.5
var damage_multiplier_max := 2.0
var reference_speed := 300.0
var force := Vector2.ZERO
var status_effects: Array[Dictionary] = []
var agitation: Dictionary = {}
var terrain_response := TerrainResponse.STOP
var max_hits := 1

func damage_amount() -> float:
	var speed_ratio := velocity.length() / maxf(reference_speed, 1.0)
	return base_damage * clampf(speed_ratio, damage_multiplier_min, damage_multiplier_max)

func to_damage_info() -> DamageInfo:
	return DamageInfo.new(damage_amount(), source_actor, source_species_id, force)
