class_name WorldItem
extends Area2D

@export var item_id: StringName
@export var quantity := 1
@export var instance_state: Dictionary = {}
@export var persistent_id := ""
@export var interaction_priority := 20

func _ready() -> void:
	add_to_group(&"interactables")
	if persistent_id.is_empty():
		persistent_id = "item_%s_%s" % [Time.get_ticks_usec(), randi()]
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
