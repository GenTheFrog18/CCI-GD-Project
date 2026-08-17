class_name Projectile
extends CharacterBody2D

@export var lifetime := 6.0
@export var gravity_scale := 0.0

var impact := ImpactData.new()
var _hit_ids: Dictionary = {}

func configure(data: ImpactData, initial_velocity: Vector2, visual_texture: Texture2D = null) -> void:
	impact = data
	velocity = initial_velocity
	impact.velocity = initial_velocity
	if visual_texture != null:
		$Icon.texture = visual_texture
		$Icon.visible = true
		$Visual.visible = false

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if gravity_scale != 0.0:
		velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * gravity_scale * delta
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
	impact.apply_to(body)
	if _hit_ids.size() >= impact.max_hits:
		queue_free()
