class_name BreakableLoot
extends StaticBody2D

const WORLD_ITEM_SCENE := preload("res://game/items/world/world_item.tscn")

@export var persistent_id := ""
@export var item_id: StringName = &"multitool"

@onready var health: HealthComponent = $HealthComponent

var _broken := false

func _ready() -> void:
	add_to_group(&"persistent_objects")
	add_to_group(&"multitool_breakable")
	health.died.connect(_break)

func apply_damage(info: DamageInfo) -> bool:
	return health.apply_damage(info)

func capture_state() -> Dictionary:
	return {"health": health.capture_state()}

func restore_state(data: Dictionary) -> void:
	health.restore_state(data.get("health", {}))
	if health.is_dead:
		queue_free()

func _break(_source: Node) -> void:
	if _broken:
		return
	_broken = true
	SaveManager.mark_destroyed(persistent_id)
	_spawn_drop(&"throwable_rock", "%s:rock" % persistent_id)
	_spawn_drop(item_id, "%s:item" % persistent_id)
	queue_free()

func _spawn_drop(drop_item_id: StringName, drop_id: String) -> void:
	var definition := ContentCatalog.get_item(drop_item_id)
	var parent := get_parent()
	if definition == null or parent == null:
		push_error("BreakableLoot cannot spawn item %s" % drop_item_id)
		return
	var drop := WORLD_ITEM_SCENE.instantiate() as WorldItem
	drop.persistent_id = drop_id
	drop.item_id = definition.item_id
	drop.instance_state = {"origin": "map"}
	parent.add_child(drop)
	drop.global_position = global_position + Vector2(0.0, -12.0)
