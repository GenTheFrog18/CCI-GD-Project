class_name ItemDefinition
extends Resource

@export var item_id: StringName
@export var display_name := ""
@export_multiline var unknown_description := ""
@export_multiline var known_description := ""
@export var category: StringName = &"ordinary"
@export var icon: Texture2D
@export var world_scene: PackedScene
@export_range(0, 999, 1) var weight := 1
@export_range(1, 99, 1) var max_stack := 1
@export var purchase_price := 0
@export var surface_sale_value := 0
@export var delivery_value := 0
@export_range(0, 99, 1) var shop_quest_value := 0
@export var discovery_threshold := 0
@export var sellable := false
@export var persistent_when_dropped := true
@export var retrievable := true
@export var recover_out_of_bounds := false
@export var behavior: ItemBehavior
@export var primary_behavior: ItemBehavior
@export var secondary_behavior: ItemBehavior
@export var discoverable := false

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_id.is_empty():
		errors.append("item_id is blank")
	if display_name.is_empty():
		errors.append("%s display_name is blank" % item_id)
	if max_stack < 1:
		errors.append("%s max_stack must be positive" % item_id)
	if weight < 0:
		errors.append("%s weight cannot be negative" % item_id)
	if behavior == null and primary_behavior == null and secondary_behavior == null:
		errors.append("%s has no item behavior" % item_id)
	return errors
