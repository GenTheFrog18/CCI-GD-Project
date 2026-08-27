class_name DialogueAction
extends Resource

enum Type { CONSUME_ITEM, GRANT_ITEM, SET_FLAG, MARK_EXCHANGE, START_SEQUENCE, OPEN_TUTORIAL, EXCHANGE }

@export var type: Type = Type.SET_FLAG
@export var item_id: StringName
@export_range(1, 99, 1) var quantity := 1
@export var item_state: Dictionary = {}
@export var flag_id: StringName
@export var flag_value := true
@export var sequence: DialogueSequence
@export var tutorial_id: StringName = &"how_to_play"
@export var reward_item_id: StringName
@export_range(1, 99, 1) var reward_quantity := 1
@export var reward_state: Dictionary = {}
