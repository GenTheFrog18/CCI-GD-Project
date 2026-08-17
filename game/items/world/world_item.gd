class_name WorldItem
extends Area2D

@export var item_id: StringName
@export var quantity := 1
@export var instance_state: Dictionary = {}
@export var persistent_id := ""
@export var interaction_priority := 20

func _ready() -> void:
	add_to_group(&"interactables")
	add_to_group(&"loose_items")
	_apply_visual()
	if persistent_id.is_empty():
		persistent_id = GameSession.next_runtime_id(&"item", GameSession.current_layer_id)
	if ContentCatalog.get_item(item_id) != null and ContentCatalog.get_item(item_id).persistent_when_dropped:
		add_to_group(&"persistent_objects")

func get_interaction_prompt(_actor: Node) -> String:
	var definition := ContentCatalog.get_item(item_id)
	return "Pick up %s" % (definition.display_name if definition != null else String(item_id))

func interact(actor: Node) -> bool:
	if not actor.has_method("try_pickup_item"):
		return false
	if actor.try_pickup_item(item_id, quantity, instance_state):
		SaveManager.mark_destroyed(persistent_id)
		queue_free()
		return true
	return false

func take_as_stack() -> ItemStack:
	if quantity <= 0:
		return ItemStack.new()
	var result := ItemStack.new(item_id, 1, instance_state)
	quantity -= 1
	if quantity == 0:
		SaveManager.mark_destroyed(persistent_id)
		queue_free()
	return result

func capture_state() -> Dictionary:
	return {
		"item_id": String(item_id),
		"quantity": quantity,
		"instance_state": instance_state.duplicate(true),
		"position": [global_position.x, global_position.y],
	}

func restore_state(data: Dictionary) -> void:
	item_id = StringName(data.get("item_id", ""))
	quantity = int(data.get("quantity", 1))
	instance_state = data.get("instance_state", {}).duplicate(true)
	var saved_position: Array = data.get("position", [0.0, 0.0])
	global_position = Vector2(float(saved_position[0]), float(saved_position[1]))
	_apply_visual()

func _apply_visual() -> void:
	var definition := ContentCatalog.get_item(item_id)
	var icon := get_node_or_null("Icon") as Sprite2D
	var fallback := get_node_or_null("Visual") as CanvasItem
	if icon != null:
		icon.texture = definition.icon if definition != null else null
		icon.visible = icon.texture != null
	if fallback != null:
		fallback.visible = icon == null or icon.texture == null

func handle_world_out_of_bounds() -> void:
	var definition := ContentCatalog.get_item(item_id)
	if definition != null and definition.recover_out_of_bounds:
		var marker := get_tree().get_first_node_in_group(&"quest_item_recovery_marker") as Node2D
		if marker != null:
			global_position = marker.global_position
			return
	SaveManager.mark_destroyed(persistent_id)
	queue_free()
