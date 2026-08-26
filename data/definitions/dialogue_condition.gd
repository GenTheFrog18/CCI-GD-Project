class_name DialogueCondition
extends Resource

enum Type { HAS_ITEM, FIRST_INTERACTION, EXCHANGE_COMPLETED, PERSISTENT_FLAG, TUTORIAL_SEEN }

@export var type: Type = Type.HAS_ITEM
@export var item_id: StringName
@export_range(1, 99, 1) var quantity := 1
@export var flag_id: StringName
@export var expected := true
