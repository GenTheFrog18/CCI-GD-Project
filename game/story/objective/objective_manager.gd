class_name ObjectiveManager
extends Node

signal objective_started(objective: Dictionary)
signal objective_completed(objective: Dictionary)
signal objective_changed(objective: Dictionary)

var current_objective: Dictionary = {}
var has_objective: bool = false


func start_objective(
	id: String,
	title: String,
	description: String,
	target_group: StringName = &"",
	target_layer: StringName = &""
) -> void:

	current_objective = {
		"id": id,
		"title": title,
		"description": description,
		"target_group": target_group,
		"target_layer": target_layer,
		"completed": false
	}

	has_objective = true

	objective_started.emit(current_objective)
	objective_changed.emit(current_objective)


func complete_objective(id: String) -> void:
	if not has_objective:
		return

	if current_objective.get("id", "") != id:
		return

	current_objective["completed"] = true

	objective_completed.emit(current_objective)
	objective_changed.emit(current_objective)


func is_objective_active(id: String) -> bool:
	if not has_objective:
		return false

	return (
		current_objective.get("id", "") == id
		and not current_objective.get("completed", false)
	)


func get_current_objective() -> Dictionary:
	return current_objective


func get_target_layer() -> StringName:
	if not has_objective:
		return &""

	return StringName(
		current_objective.get("target_layer", "")
	)


func clear_objective() -> void:
	current_objective.clear()
	has_objective = false

	objective_changed.emit({})
