class_name StatusController
extends Node

signal status_changed
signal tick_damage_requested(amount: float)

var active: Dictionary = {}

func _process(delta: float) -> void:
	var expired: Array[StringName] = []
	for id: StringName in active:
		var entry: Dictionary = active[id]
		entry.remaining -= delta
		var definition := ContentCatalog.get_effect(id)
		if definition != null and definition.tick_interval > 0.0:
			entry.tick_remaining -= delta
			while entry.tick_remaining <= 0.0 and entry.remaining > 0.0:
				entry.tick_remaining += definition.tick_interval
				tick_damage_requested.emit(definition.tick_damage * entry.stacks)
		active[id] = entry
		if entry.remaining <= 0.0:
			expired.append(id)
	for id in expired:
		active.erase(id)
		status_changed.emit()

func apply_status(effect_id: StringName, data: Dictionary = {}) -> bool:
	var definition := ContentCatalog.get_effect(effect_id)
	if definition == null:
		return false
	var duration := float(data.get("duration", definition.duration))
	if active.has(effect_id):
		var entry: Dictionary = active[effect_id]
		match definition.stack_rule:
			EffectDefinition.StackRule.REFRESH:
				entry.remaining = duration
			EffectDefinition.StackRule.STACK:
				entry.stacks = mini(entry.stacks + 1, definition.max_stacks)
				entry.remaining = maxf(entry.remaining, duration)
			EffectDefinition.StackRule.REPLACE:
				entry = _new_entry(definition, duration)
			EffectDefinition.StackRule.IGNORE:
				return false
		active[effect_id] = entry
	else:
		active[effect_id] = _new_entry(definition, duration)
	status_changed.emit()
	return true

func remove_status(effect_id: StringName) -> bool:
	var removed := active.erase(effect_id)
	if removed:
		status_changed.emit()
	return removed

func get_multiplier(key: StringName) -> float:
	var result := 1.0
	for id: StringName in active:
		var definition := ContentCatalog.get_effect(id)
		if definition != null and definition.modifiers.has(key):
			result *= float(definition.modifiers[key]) ** int(active[id].stacks)
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
	for id in data:
		if ContentCatalog.get_effect(StringName(id)) != null:
			active[StringName(id)] = data[id].duplicate(true)
	status_changed.emit()

func _new_entry(definition: EffectDefinition, duration: float) -> Dictionary:
	return {"remaining": duration, "stacks": 1, "tick_remaining": definition.tick_interval}
