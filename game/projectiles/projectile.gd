class_name Projectile
extends CharacterBody2D

@export var lifetime := 6.0

var impact := ImpactData.new()
var _hit_ids: Dictionary = {}

func configure(data: ImpactData, initial_velocity: Vector2) -> void:
	impact = data
	velocity = initial_velocity
	impact.velocity = initial_velocity

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var collision := move_and_collide(velocity * delta)
	if collision != null:
		_handle_collision(collision.get_collider())

func _handle_collision(body: Node) -> void:
	if body == impact.source_actor:
		return
	var id := body.get_instance_id()
	if _hit_ids.has(id):
		return
	_hit_ids[id] = true
	impact.velocity = velocity
	impact.force = velocity.normalized() * impact.mass * minf(velocity.length(), 300.0)
	if body.has_method("apply_damage"):
		body.apply_damage(impact.to_damage_info())
	if body.has_method("apply_force"):
		body.apply_force(impact.force)
	for effect in impact.status_effects:
		if body.has_method("apply_status"):
			body.apply_status(StringName(effect.get("effect_id", "")), effect)
	if _hit_ids.size() >= impact.max_hits:
		queue_free()
