class_name StatusController
extends Node

signal status_changed
signal tick_damage_requested(amount: float)
signal tick_healing_requested(amount: float)

var active: Dictionary = {}

func _process(delta: float) -> void:
	var changed := false
	for id: StringName in active.keys():
		var entry: Dictionary = active[id]
		var applications: Array = entry.get("applications", [])
		var previous_count := applications.size()
		var definition := ContentCatalog.get_effect(id)
		if definition != null and definition.tick_interval > 0.0 and not applications.is_empty():
			var longest_remaining := 0.0
			for application in applications:
				longest_remaining = maxf(longest_remaining, float(application.remaining))
			entry.tick_remaining = float(entry.get("tick_remaining", definition.tick_interval)) - minf(delta, longest_remaining)
			while entry.tick_remaining <= 0.0:
				entry.tick_remaining += definition.tick_interval
				if definition.tick_damage > 0.0:
					tick_damage_requested.emit(definition.tick_damage * applications.size())
				if definition.tick_healing > 0.0:
					tick_healing_requested.emit(definition.tick_healing * applications.size())
		for application in applications:
			application.remaining = float(application.remaining) - delta
		applications = applications.filter(func(application: Dictionary): return float(application.remaining) > 0.0)
		if applications.size() != previous_count:
			changed = true
		if applications.is_empty():
			active.erase(id)
			changed = true
			continue
		entry.applications = applications
		active[id] = entry
	if changed:
		status_changed.emit()

func apply_status(effect_id: StringName, data: Dictionary = {}) -> bool:
	var definition := ContentCatalog.get_effect(effect_id)
	if definition == null or not _is_eligible(definition):
		return false
	var duration := float(data.get("duration", definition.duration))
	if duration <= 0.0:
		return false
	var application := {
		"remaining": duration,
		"provider_id": String(data.get("provider_id", "")),
		"source_id": String(data.get("source_id", "")),
		"modifiers": (data.get("modifiers", {}) as Dictionary).duplicate(true),
	}
	var entry: Dictionary = active.get(effect_id, {"applications": [], "tick_remaining": definition.tick_interval})
	var applications: Array = entry.get("applications", [])
	var provider_id := String(application.provider_id)
	if not provider_id.is_empty():
		for index in applications.size():
			if String(applications[index].get("provider_id", "")) == provider_id:
				applications[index] = application
				entry.applications = applications
				active[effect_id] = entry
				status_changed.emit()
				return true
	match definition.stack_rule:
		EffectDefinition.StackRule.REFRESH:
			applications = [application]
		EffectDefinition.StackRule.STACK:
			if applications.size() < definition.max_stacks:
				applications.append(application)
			else:
				var shortest := 0
				for index in range(1, applications.size()):
					if float(applications[index].remaining) < float(applications[shortest].remaining):
						shortest = index
				applications[shortest] = application
		EffectDefinition.StackRule.REPLACE:
			applications = [application]
		EffectDefinition.StackRule.IGNORE:
			if not applications.is_empty():
				return false
			applications = [application]
	entry.applications = applications
	active[effect_id] = entry
	status_changed.emit()
	return true

func remove_status(effect_id: StringName, provider_id := "") -> bool:
	if not active.has(effect_id):
		return false
	if provider_id.is_empty():
		active.erase(effect_id)
		status_changed.emit()
		return true
	var entry: Dictionary = active[effect_id]
	var applications: Array = entry.get("applications", [])
	var previous_size := applications.size()
	applications = applications.filter(func(application: Dictionary): return String(application.get("provider_id", "")) != provider_id)
	if applications.size() == previous_size:
		return false
	if applications.is_empty():
		active.erase(effect_id)
	else:
		entry.applications = applications
		active[effect_id] = entry
	status_changed.emit()
	return true

func has_status(effect_id: StringName) -> bool:
	return active.has(effect_id)

func get_stack_count(effect_id: StringName) -> int:
	return (active.get(effect_id, {}).get("applications", []) as Array).size()

func get_remaining(effect_id: StringName) -> float:
	var result := 0.0
	for application in active.get(effect_id, {}).get("applications", []):
		result = maxf(result, float(application.get("remaining", 0.0)))
	return result

func get_multiplier(key: StringName) -> float:
	var result := 1.0
	for id: StringName in active:
		var definition := ContentCatalog.get_effect(id)
		if definition == null:
			continue
		for application in active[id].get("applications", []):
			var overrides: Dictionary = application.get("modifiers", {})
			if overrides.has(key):
				result *= float(overrides[key])
			elif definition.modifiers.has(key):
				result *= float(definition.modifiers[key])
	return result

func capture_state() -> Dictionary:
	var result: Dictionary = {}
	for id: StringName in active:
		var definition := ContentCatalog.get_effect(id)
		if definition != null and definition.persists:
			result[String(id)] = active[id].duplicate(true)
	return result

func restore_state(data: Dictionary) -> void:
	active.clear()
	for raw_id in data:
		var id := StringName(raw_id)
		var definition := ContentCatalog.get_effect(id)
		if definition == null:
			continue
		var saved: Dictionary = data[raw_id]
		if saved.has("applications"):
			active[id] = saved.duplicate(true)
		else:
			var applications: Array[Dictionary] = []
			for _index in int(saved.get("stacks", 1)):
				applications.append({"remaining": float(saved.get("remaining", definition.duration)), "provider_id": "", "source_id": "", "modifiers": {}})
			active[id] = {"applications": applications, "tick_remaining": float(saved.get("tick_remaining", definition.tick_interval))}
	status_changed.emit()

func _is_eligible(definition: EffectDefinition) -> bool:
	if definition.valid_actor_tags.is_empty():
		return true
	var actor := get_parent()
	if actor is EnemySupport:
		actor = actor.get_parent()
	for tag in definition.valid_actor_tags:
		if actor != null and actor.is_in_group(tag):
			return true
	return false
