class_name ItemDefinition
extends Resource

@export var item_id: StringName
@export var display_name := ""
@export_multiline var unknown_description := ""
@export_multiline var known_description := ""
@export var category: StringName = &"ordinary"
@export var icon: Texture2D
@export var world_scene: PackedScene
@export_range(1, 99, 1) var max_stack := 1
@export var purchase_price := 0
@export var surface_sale_value := 0
@export var delivery_value := 0
@export var discovery_threshold := 0
@export var sellable := false
@export var persistent_when_dropped := true
@export var retrievable := true
@export var behavior: ItemBehavior

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_id.is_empty():
		errors.append("item_id is blank")
	if display_name.is_empty():
		errors.append("%s display_name is blank" % item_id)
	if max_stack < 1:
		errors.append("%s max_stack must be positive" % item_id)
	if behavior == null:
		errors.append("%s behavior is missing" % item_id)
	return errors
