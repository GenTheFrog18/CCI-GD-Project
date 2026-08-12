class_name PlayerItemController
extends Node

signal feedback_requested(message: String)
signal prepared_item_changed(item: Node2D)

@export var held_item_anchor: Node2D

var inventory := InventoryModel.new()
var prepared_item: Node2D

func cancel_prepared() -> void:
	if is_instance_valid(prepared_item):
		prepared_item.queue_free()
	prepared_item = null
	prepared_item_changed.emit(null)

func primary(actor: Node2D, world: Node, cursor: Vector2, target: Node = null) -> bool:
	if prepared_item != null:
		feedback_requested.emit("Item already prepared")
		return false
	return _execute(false, actor, world, cursor, target)

func secondary(actor: Node2D, world: Node, cursor: Vector2, target: Node = null) -> bool:
	if prepared_item != null:
		if not prepared_item.has_method("throw_toward"):
			return false
		var keep_transform := prepared_item.global_transform
		prepared_item.reparent(world)
		prepared_item.global_transform = keep_transform
		prepared_item.throw_toward(cursor)
		prepared_item = null
		prepared_item_changed.emit(null)
		return true
	return _execute(true, actor, world, cursor, target)

func try_prepare(node: Node2D) -> bool:
	if node == null or prepared_item != null or held_item_anchor == null:
		return false
	prepared_item = node
	held_item_anchor.add_child(node)
	node.position = Vector2.ZERO
	prepared_item_changed.emit(node)
	return true

func _execute(is_secondary: bool, actor: Node2D, world: Node, cursor: Vector2, target: Node) -> bool:
	var stack := inventory.get_active_stack()
	if stack.is_empty():
		feedback_requested.emit("Empty hotbar slot")
		return false
	var definition := ContentCatalog.get_item(stack.item_id)
	if definition == null or definition.behavior == null:
		return false
	var context := ItemContext.new(actor, world, cursor, target, definition, stack.copy())
	if held_item_anchor != null:
		var anchor_offset := held_item_anchor.global_position - actor.global_position
		anchor_offset.x = absf(anchor_offset.x) * (-1.0 if cursor.x < actor.global_position.x else 1.0)
		context.action_origin = actor.global_position + anchor_offset
	var behavior := definition.behavior
	var allowed := behavior.can_secondary(context, stack.state) if is_secondary else behavior.can_primary(context, stack.state)
	if not allowed:
		feedback_requested.emit("Action unavailable")
		return false
	var result := behavior.secondary(context, stack.state) if is_secondary else behavior.primary(context, stack.state)
	return _commit_result(result, world)

func _commit_result(result: ItemActionResult, world: Node) -> bool:
	if result == null or not result.success:
		if result != null and not result.message.is_empty():
			feedback_requested.emit(result.message)
		return false
	if result.prepared_node != null and not try_prepare(result.prepared_node):
		result.prepared_node.queue_free()
		return false
	if result.world_node != null:
		world.add_child(result.world_node)
	if result.consume_count > 0 and not inventory.remove_active(result.consume_count):
		if result.world_node != null:
			result.world_node.queue_free()
		if result.prepared_node != null:
			prepared_item = null
			result.prepared_node.queue_free()
		return false
	if not result.next_state.is_empty() and not inventory.get_active_stack().is_empty():
		inventory.update_active_state(result.next_state)
	if not result.message.is_empty():
		feedback_requested.emit(result.message)
	return true
