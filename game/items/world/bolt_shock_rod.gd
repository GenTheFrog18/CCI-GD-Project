class_name BoltShockRod
extends CharacterBody2D

@export var lifetime := 3.0

var source_actor: Node
var source_species_id: StringName = &"player"
var impact_damage := 10.0
var stun_duration := 3.0
var suppression_duration := 5.0
var shock_duration := 6.0

func configure(source: Node, position: Vector2, launch_velocity: Vector2, damage: float, stun: float, suppression: float, shock: float) -> void:
	source_actor = source
	global_position = position
	velocity = launch_velocity
	impact_damage = damage
	stun_duration = stun
	suppression_duration = suppression
	shock_duration = shock
	rotation = velocity.angle()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var collision := move_and_collide(velocity * delta)
	if collision != null:
		_resolve(collision.get_collider())

func _resolve(body: Node) -> void:
	if body == source_actor:
		return
	var impact := ImpactData.new()
	impact.source_actor = source_actor if is_instance_valid(source_actor) else null
	impact.source_species_id = source_species_id
	impact.base_damage = impact_damage
	impact.velocity = velocity
	impact.attack_kind = &"bolt_rod"
	var result := impact.apply_to(body)
	if bool(result.damage) and body.is_in_group(&"effect_receivers"):
		var support := body.get_node_or_null("EnemySupport") as EnemySupport
		if support != null:
			support.apply_electric_effects(stun_duration, suppression_duration, shock_duration)
		elif body.has_method("apply_status"):
			body.apply_status(&"electrocuted", {"duration": shock_duration})
			body.apply_status(&"electro_stunned", {"duration": stun_duration})
			body.apply_status(&"detector_suppressed", {"duration": suppression_duration})
	queue_free()
