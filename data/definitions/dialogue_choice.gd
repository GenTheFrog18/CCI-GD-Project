class_name DialogueChoice
extends Resource

@export var choice_id: StringName
@export var label := "Choice"
@export var disabled_reason := "Unavailable"
@export var conditions: Array[DialogueCondition] = []
@export var actions: Array[DialogueAction] = []
@export var next_sequence: DialogueSequence
