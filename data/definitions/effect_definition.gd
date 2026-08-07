class_name EffectDefinition
extends Resource

enum StackRule { REFRESH, STACK, REPLACE, IGNORE }

@export var effect_id: StringName
@export var duration := 1.0
@export var stack_rule := StackRule.REFRESH
@export var max_stacks := 1
@export var tick_interval := 0.0
@export var tick_damage := 0.0
@export var persists := false
@export var modifiers: Dictionary = {}
@export var icon: Texture2D
