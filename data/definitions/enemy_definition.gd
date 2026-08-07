class_name EnemyDefinition
extends Resource

@export var enemy_id: StringName
@export var scene: PackedScene
@export var species_id: StringName
@export var max_health := 10.0
@export var move_speed := 50.0
@export var damage := 5.0
@export var knockback := 100.0
@export var detection_range := 160.0
@export var layer := 1
@export var persists_when_dead := true
