class_name Projectile
extends CharacterBody2D

signal terminal_resolved(result: StringName, body: Node)

@export var lifetime := 6.0
@export var gravity_scale := 0.0

var impact := ImpactData.new()
var _hit_ids: Dictionary = {}
var _terminal_resolved := false

func configure(data: ImpactData, initial_velocity: Vector2, visual_texture: Texture2D = null) -> void:
	impact = data
	velocity = initial_velocity
	impact.velocity = initial_velocity
	_update_visual_rotation()
	if visual_texture != null:
		$Icon.texture = visual_texture
		$Icon.visible = true
		$Visual.visible = false

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_resolve_terminal(&"expired")
		return
	if gravity_scale != 0.0:
		velocity.y += float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * gravity_scale * delta
	_update_visual_rotation()
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
		var result := &"hit_terrain" if body is StaticBody2D or body is TileMapLayer else &"hit_actor"
		_resolve_terminal(result, body)

func cancel() -> void:
	_resolve_terminal(&"cancelled")

func _resolve_terminal(result: StringName, body: Node = null) -> void:
	if _terminal_resolved:
		return
	_terminal_resolved = true
	terminal_resolved.emit(result, body)
	queue_free()

func _update_visual_rotation() -> void:
	if not velocity.is_zero_approx():
		rotation = velocity.angle()
