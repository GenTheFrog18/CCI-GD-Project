class_name WorldEffectArea
extends Area2D

const PLACEHOLDER_LIGHT_TEXTURE := preload("res://game/items/world/placeholder_light_texture.tres")

var effect_kind: StringName
var effect_id: StringName
var duration := 8.0
var radius := 48.0
var source_actor: Node
var provider_id := ""
var sound_priority := -1
var sound_radius := 0.0

func configure(kind: StringName, status_id: StringName, seconds: float, area_radius: float, source: Node = null, priority := -1, hearing_radius := 0.0) -> void:
	effect_kind = kind
	effect_id = status_id
	duration = seconds
	radius = area_radius
	source_actor = source
	sound_priority = priority
	sound_radius = hearing_radius
	provider_id = "area:%d" % get_instance_id()

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	add_child(collision)
	collision_layer = 256 if effect_kind == &"hushcap" else 0
	collision_mask = 2 | 4 | 8 | 16 | 32 | 64
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	queue_redraw()
	if sound_priority >= 0 and sound_radius > 0.0:
		SoundBus.emit_sound(get_tree(), SoundEvent.new(global_position, sound_radius, effect_kind, sound_priority, self))
	if effect_kind == &"light":
		add_to_group(&"light_sources")
		var light := PointLight2D.new()
		light.texture = PLACEHOLDER_LIGHT_TEXTURE
		light.texture_scale = radius / 64.0
		light.energy = 0.8
		add_child(light)
	if effect_kind == &"crystal":
		call_deferred("_flash")

func _process(delta: float) -> void:
	duration -= delta
	if duration <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if effect_kind == &"resin":
		if body.has_method("apply_status"):
			body.apply_status(effect_id, {"provider_id": provider_id, "duration": duration})
		elif body is RigidBody2D:
			body.linear_velocity *= 0.5
		elif body is CharacterBody2D:
			body.velocity *= 0.5

func _on_body_exited(body: Node) -> void:
	if effect_kind == &"resin":
		var status = body.get("status")
		if not status is StatusController:
			var support := body.get_node_or_null("EnemySupport") as EnemySupport
			status = support.status if support != null else null
		if status is StatusController:
			status.remove_status(effect_id, provider_id)

func _flash() -> void:
	for actor in get_tree().get_nodes_in_group(&"effect_receivers"):
		if not actor is Node2D or global_position.distance_to(actor.global_position) > radius:
			continue
		var query := PhysicsRayQueryParameters2D.create(global_position, actor.global_position, 257)
		query.collide_with_areas = true
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.get("collider") == actor:
			var ratio := 1.0 - global_position.distance_to(actor.global_position) / maxf(radius, 1.0)
			actor.apply_status(&"dazzled", {"duration": maxf(0.1, duration * ratio)})
	duration = minf(duration, 0.15)

func _draw() -> void:
	var color := Color(0.75, 0.75, 0.75, 0.3)
	if effect_kind == &"resin": color = Color(0.8, 0.55, 0.15, 0.45)
	if effect_kind == &"light": color = Color(1.0, 0.85, 0.25, 0.4)
	if effect_kind == &"crystal": color = Color(0.8, 0.95, 1.0, 0.65)
	draw_circle(Vector2.ZERO, radius, color)
