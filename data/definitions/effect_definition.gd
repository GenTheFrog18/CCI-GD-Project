class_name EffectDefinition
extends Resource

enum StackRule { REFRESH, STACK, REPLACE, IGNORE }

@export var effect_id: StringName
@export var display_name := ""
@export var duration := 1.0
@export var additive_duration_cap := 0.0
@export var stack_rule := StackRule.REFRESH
@export var max_stacks := 1
@export var tick_interval := 0.0
@export var tick_damage := 0.0
@export var tick_healing := 0.0
@export var persists := false
@export var show_timer := true
@export var modifiers: Dictionary = {}
@export var valid_actor_tags: Array[StringName] = []
@export var icon: Texture2D

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if effect_id.is_empty(): errors.append("effect_id is blank")
	if duration <= 0.0: errors.append("%s duration must be positive" % effect_id)
	if max_stacks < 1: errors.append("%s max_stacks must be positive" % effect_id)
	if tick_interval < 0.0: errors.append("%s tick_interval cannot be negative" % effect_id)
	return errors
