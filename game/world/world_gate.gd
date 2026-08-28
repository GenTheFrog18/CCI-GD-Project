class_name WorldGate
extends Area2D

@export var target_layer_id: StringName
@export_enum("west", "east") var target_route_id := "west"
@export var target_spawn_id: StringName
@export var prompt := "Enter"

func _ready() -> void:
	add_to_group(&"interactables")

func get_interaction_prompt(_actor: Node) -> String:
	return prompt

func interact(_actor: Node) -> bool:
	var world_run := _find_world_run()
	if world_run == null:
		return false
	world_run.request_layer_transition(target_layer_id, StringName(target_route_id), target_spawn_id)
	return true

func _find_world_run() -> WorldRun:
	var node: Node = self
	while node != null:
		if node is WorldRun:
			return node
		node = node.get_parent()
	return null
