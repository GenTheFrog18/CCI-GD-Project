class_name ItemContext
extends RefCounted

var actor: Node2D
var world: Node
var cursor_position := Vector2.ZERO
var interaction_target: Node
var definition: ItemDefinition
var stack: ItemStack

func _init(
	actor_node: Node2D = null,
	world_node: Node = null,
	cursor := Vector2.ZERO,
	target: Node = null,
	item_definition: ItemDefinition = null,
	item_stack: ItemStack = null
) -> void:
	actor = actor_node
	world = world_node
	cursor_position = cursor
	interaction_target = target
	definition = item_definition
	stack = item_stack
