class_name WorldItem
extends Area2D

var world_state := WorldItemState.new()

@export var item_id: StringName:
	get: return world_state.item_id
	set(value): world_state.item_id = value
@export var quantity: int:
	get: return world_state.quantity
	set(value): world_state.quantity = value
@export var instance_state: Dictionary:
	get: return world_state.instance_state
	set(value): world_state.instance_state = value
@export var persistent_id: String:
	get: return world_state.persistent_id
	set(value): world_state.persistent_id = value
@export var interaction_priority := 20

var _spawn_position := Vector2.ZERO

func _ready() -> void:
	_spawn_position = global_position
	_apply_world_hitbox()
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
	world_state.position = global_position
	world_state.rotation = rotation
	return world_state.capture()

func restore_state(data: Dictionary) -> void:
	world_state.restore(data)
	global_position = world_state.position
	rotation = world_state.rotation
	_spawn_position = global_position
	_apply_world_hitbox()
	_apply_visual()

func _apply_world_hitbox() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		return
	var fallback := CircleShape2D.new()
	fallback.radius = 6.0
	collision.shape = WorldItemState.hitbox_for(ContentCatalog.get_item(item_id), fallback)

func _apply_visual() -> void:
	var definition := ContentCatalog.get_item(item_id)
	var icon := get_node_or_null("Icon") as Sprite2D
	var fallback := get_node_or_null("Visual") as CanvasItem
	if icon != null:
		icon.texture = definition.texture_for_instance(instance_state) if definition != null else null
		icon.visible = icon.texture != null
	if fallback != null:
		fallback.visible = icon == null or icon.texture == null

func handle_world_out_of_bounds() -> void:
	var definition := ContentCatalog.get_item(item_id)
	if definition != null and definition.recover_out_of_bounds:
		var marker := get_tree().get_first_node_in_group(&"quest_item_recovery_marker") as Node2D
		if marker != null:
			global_position = marker.global_position
		else:
			global_position = _spawn_position
		return
	SaveManager.mark_destroyed(persistent_id)
	queue_free()
