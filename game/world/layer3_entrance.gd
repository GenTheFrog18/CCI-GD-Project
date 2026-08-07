class_name Layer3Entrance
extends Area2D

func _ready() -> void:
	add_to_group(&"interactables")

func get_interaction_prompt(_actor: Node) -> String:
	return "Enter Layer 3"

func interact(_actor: Node) -> bool:
	var node: Node = self
	while node != null:
		if node is WorldRun:
			node.finish_run()
			return true
		node = node.get_parent()
	return false
