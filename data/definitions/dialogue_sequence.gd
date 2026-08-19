class_name DialogueSequence
extends Resource

@export var sequence_id: StringName
@export var speaker := ""
@export_multiline var lines: PackedStringArray
@export var entries: Array[DialogueLine] = []
@export var locks_gameplay := true
@export var one_shot := false
