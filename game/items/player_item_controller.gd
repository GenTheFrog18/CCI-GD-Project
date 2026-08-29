class_name PlayerItemController
extends Node

signal feedback_requested(message: String)
signal prepared_item_changed(item: Node2D)

@export var held_item_anchor: Node2D
@export var held_item_icon: Sprite2D

var inventory := InventoryModel.new()
var prepared_item: Node2D
var _active_item_id: StringName
var _committing := false
var held_light: LightSource2D
var _warming_light := true

func _ready() -> void:
	held_light = LightSource2D.new()
	held_light.light_radius = 96.0
	held_light.light_intensity = 0.7
	held_light.enabled = true
	if held_item_anchor != null:
		held_item_anchor.add_child(held_light)
	else:
		held_light.free()
		held_light = null
	inventory.changed.connect(_on_inventory_changed)
	_on_inventory_changed()
	_finish_light_warmup()

func _finish_light_warmup() -> void:
	await get_tree().process_frame
	_warming_light = false
	if held_light != null:
		held_light.light_intensity = 0.7
	_refresh_held_icon()

func cancel_prepared(reason: StringName = &"cancel") -> void:
	var item := prepared_item
	prepared_item = null
	if is_instance_valid(item):
		if item.has_method("cancel_preparation"):
			item.cancel_preparation(self, reason)
		else:
			item.queue_free()
	prepared_item_changed.emit(null)
	_refresh_held_icon()

func get_movement_multiplier() -> float:
	if not is_instance_valid(prepared_item):
		return 1.0
	var value = prepared_item.get("movement_multiplier")
	return float(value) if value != null else 1.0

func get_jump_multiplier() -> float:
	if not is_instance_valid(prepared_item):
		return 1.0
	var value = prepared_item.get("jump_multiplier")
	return float(value) if value != null else 1.0

func get_climb_multiplier() -> float:
	if not is_instance_valid(prepared_item):
		return 1.0
	var value = prepared_item.get("climb_multiplier")
	return float(value) if value != null else 1.0

func get_preview(actor: Node2D, world: Node, cursor: Vector2, target: Node = null) -> Dictionary:
	if is_instance_valid(prepared_item):
		if prepared_item.has_method("get_preview"):
			return prepared_item.get_preview(cursor)
		return {}
	var stack := inventory.get_active_stack()
	if stack.is_empty():
		return {}
	var definition := ContentCatalog.get_item(stack.item_id)
	if definition == null:
		return {}
	var behavior := definition.secondary_behavior if definition.secondary_behavior != null else definition.behavior
	return behavior.get_preview(_make_context(actor, world, cursor, target, definition, stack), stack.state) if behavior != null else {}

func primary(actor: Node2D, world: Node, cursor: Vector2, target: Node = null) -> bool:
	if prepared_item != null:
		if prepared_item.has_method("primary_action"):
			return bool(prepared_item.primary_action(self))
		if prepared_item.has_method("can_deactivate") and prepared_item.can_deactivate():
			cancel_prepared(&"toggle")
			return true
		feedback_requested.emit("Item already prepared")
		return false
	return _execute(false, actor, world, cursor, target)

func secondary(actor: Node2D, world: Node, cursor: Vector2, target: Node = null) -> bool:
	if prepared_item != null:
		if prepared_item.has_method("secondary_action"):
			return bool(prepared_item.secondary_action(self, world, cursor))
		if not prepared_item.has_method("throw_toward"):
			return false
		var item := prepared_item
		var keep_transform := item.global_transform
		item.reparent(world)
		item.global_transform = keep_transform
		item.throw_toward(cursor)
		AudioManager.play_player_throw()
		prepared_item = null
		prepared_item_changed.emit(null)
		_refresh_held_icon()
		return true
	return _execute(true, actor, world, cursor, target)

func try_prepare(node: Node2D) -> bool:
	if node == null or prepared_item != null or held_item_anchor == null:
		return false
	prepared_item = node
	node.tree_exited.connect(_on_prepared_exited.bind(node), CONNECT_ONE_SHOT)
	held_item_anchor.add_child(node)
	node.position = Vector2.ZERO
	_refresh_held_icon()
	prepared_item_changed.emit(node)
	return true

func _on_prepared_exited(node: Node) -> void:
	if prepared_item == node:
		prepared_item = null
		prepared_item_changed.emit(null)
		_refresh_held_icon()

func _on_inventory_changed() -> void:
	if _committing:
		return
	var stack := inventory.get_active_stack()
	var current_id := stack.item_id if not stack.is_empty() else &""
	if current_id != _active_item_id and is_instance_valid(prepared_item):
		cancel_prepared()
	_active_item_id = current_id
	_refresh_held_icon()

func _refresh_held_icon() -> void:
	if held_item_icon == null:
		return
	var definition := ContentCatalog.get_item(_active_item_id)
	var stack := inventory.get_active_stack()
	held_item_icon.texture = definition.texture_for_instance(stack.state) if definition != null and not stack.is_empty() else null
	held_item_icon.visible = held_item_icon.texture != null and not is_instance_valid(prepared_item)
	if held_light != null:
		held_light.enabled = _warming_light or _active_item_id == &"lantern_crystal"

func _execute(is_secondary: bool, actor: Node2D, world: Node, cursor: Vector2, target: Node) -> bool:
	var stack := inventory.get_active_stack()
	if stack.is_empty():
		feedback_requested.emit("Empty hotbar slot")
		return false
	var definition := ContentCatalog.get_item(stack.item_id)
	if definition == null:
		return false
	var context := _make_context(actor, world, cursor, target, definition, stack)
	var behavior := definition.secondary_behavior if is_secondary else definition.primary_behavior
	if behavior == null:
		behavior = definition.behavior
	if behavior == null:
		return false
	var allowed := behavior.can_secondary(context, stack.state) if is_secondary else behavior.can_primary(context, stack.state)
	if not allowed:
		feedback_requested.emit("Action unavailable")
		return false
	var result := behavior.secondary(context, stack.state) if is_secondary else behavior.primary(context, stack.state)
	var committed := _commit_result(result, world, actor)
	if committed and is_secondary:
		AudioManager.play_player_throw()
	return committed

func _make_context(actor: Node2D, world: Node, cursor: Vector2, target: Node, definition: ItemDefinition, stack: ItemStack) -> ItemContext:
	var context := ItemContext.new(actor, world, cursor, target, definition, stack.copy())
	if held_item_anchor != null:
		context.action_origin = held_item_anchor.global_position
	var owner := world
	while owner != null:
		var bounds = owner.get("world_bounds")
		if bounds is Rect2:
			context.world_bounds = bounds
			break
		owner = owner.get_parent()
	return context

func _commit_result(result: ItemActionResult, world: Node, actor: Node2D = null) -> bool:
	if result == null or not result.success:
		if result != null and not result.message.is_empty():
			feedback_requested.emit(result.message)
		return false
	_committing = true
	if result.prepared_node != null and not try_prepare(result.prepared_node):
		_committing = false
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
		_committing = false
		return false
	if not result.next_state.is_empty() and not inventory.get_active_stack().is_empty():
		inventory.update_active_state(result.next_state)
	if not result.message.is_empty():
		feedback_requested.emit(result.message)
	if actor != null and result.sound_priority >= 0 and result.sound_radius > 0.0:
		SoundBus.emit_sound(actor.get_tree(), SoundEvent.new(
			actor.get_detection_origin() if actor.has_method("get_detection_origin") else actor.global_position,
			result.sound_radius,
			result.sound_type,
			result.sound_priority,
			actor
		))
	_committing = false
	var stack := inventory.get_active_stack()
	_active_item_id = stack.item_id if not stack.is_empty() else &""
	_refresh_held_icon()
	return true

func prepare_for_save() -> void:
	if is_instance_valid(prepared_item):
		cancel_prepared(&"save")
