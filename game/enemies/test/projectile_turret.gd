class_name ProjectileTurret
extends Node2D

@export var target: Node2D
@export var species_id: StringName = &"turret"
@export var cooldown := 3.0
@export var telegraph_seconds := 0.6
@export var projectile_speed := 170.0

var _cooldown_remaining := 1.0
var _telegraph_remaining := 0.0
var _aim_position := Vector2.ZERO
var _projectile_scene := preload("res://game/projectiles/projectile.tscn")

@onready var muzzle: Marker2D = $Muzzle

func _process(delta: float) -> void:
	if target == null or (target.has_method("is_alive") and not target.is_alive()):
		_telegraph_remaining = 0.0
		$Visual.color = Color(0.65, 0.25, 0.25)
		return
	if _telegraph_remaining > 0.0:
		_telegraph_remaining -= delta
		$Visual.color = Color(1.0, 0.2, 0.2)
		if _telegraph_remaining <= 0.0:
			_fire()
			_cooldown_remaining = cooldown
		return
	$Visual.color = Color(0.65, 0.25, 0.25)
	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		_aim_position = target.global_position + Vector2(0.0, -14.0)
		_telegraph_remaining = telegraph_seconds

func _fire() -> void:
	var projectile := _projectile_scene.instantiate() as Projectile
	var data := ImpactData.new()
	data.source_actor = self
	data.source_species_id = species_id
	data.base_damage = 8.0
	data.mass = 0.5
	data.max_hits = 1
	var direction := muzzle.global_position.direction_to(_aim_position)
	projectile.configure(data, direction * projectile_speed)
	get_parent().add_child(projectile)
	projectile.global_position = muzzle.global_position
