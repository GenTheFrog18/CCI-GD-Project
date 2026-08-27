class_name DialogueStep
extends Resource

enum Type { LINE, CHOICE, ACTION, END }

@export var type: Type = Type.LINE
@export var line: DialogueLine
@export var choices: Array[DialogueChoice] = []
@export var actions: Array[DialogueAction] = []
