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
var receiver: Node
var blockable := true
var attack_kind: StringName = &"impact"
var stability_damage := -1.0

func damage_amount() -> float:
	var speed_ratio := velocity.length() / maxf(reference_speed, 1.0)
	return base_damage * clampf(speed_ratio, damage_multiplier_min, damage_multiplier_max)

func to_damage_info() -> DamageInfo:
	var info := DamageInfo.new(damage_amount(), source_actor, source_species_id, force)
	info.tags.append(attack_kind)
	return info

func apply_to(receiver: Node) -> Dictionary:
	self.receiver = receiver
	var result := {"damage": false, "force": false, "statuses": 0, "agitation": false}
	if receiver == null:
		return result
	if receiver.has_method("resolve_impact"):
		var resolved: Dictionary = receiver.resolve_impact(self)
		if bool(resolved.get("handled", false)):
			return resolved
	var requires_damage_acceptance := receiver.has_method("apply_damage") and base_damage > 0.0
	if requires_damage_acceptance:
		result.damage = bool(receiver.apply_damage(to_damage_info()))
	var accepted := not requires_damage_acceptance or bool(result.damage)
	if accepted and receiver.has_method("apply_force") and not force.is_zero_approx():
		receiver.apply_force(force)
		result.force = true
	if accepted and receiver.has_method("apply_status"):
		for effect in status_effects:
			if receiver.apply_status(StringName(effect.get("effect_id", "")), effect):
				result.statuses += 1
	if accepted and receiver.has_method("receive_agitation") and not agitation.is_empty():
		receiver.receive_agitation(agitation)
		result.agitation = true
	return result
