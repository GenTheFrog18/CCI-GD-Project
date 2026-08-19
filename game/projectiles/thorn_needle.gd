class_name ThornNeedle
extends CharacterBody2D

const PROJECTILE_TEXTURE := preload("res://assets/art/enemies/thorn_bloom/projectile.png")

@export var gravity := 360.0
@export var damage := 10.0
@export var stuck_seconds := 300.0
var source_actor: Node
var species_id: StringName = &"thorn_bloom"
var _stuck := false

func _ready() -> void:
	collision_layer = 32
	collision_mask = 7
	var sprite := Sprite2D.new()
	sprite.texture = PROJECTILE_TEXTURE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.name = "Sprite"
	add_child(sprite)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 2)
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func configure(source: Node, initial_velocity: Vector2, hit_damage: float, lifetime: float) -> void:
	source_actor = source
	velocity = initial_velocity
	damage = hit_damage
	stuck_seconds = lifetime

func _physics_process(delta: float) -> void:
	stuck_seconds -= delta
	if stuck_seconds <= 0.0:
		queue_free()
		return
	if _stuck: return
	velocity.y += gravity * delta
	rotation = velocity.angle()
	var collision := move_and_collide(velocity * delta)
	if collision == null: return
	var body := collision.get_collider() as Node
	if body != source_actor and body.has_method("apply_damage"):
		var impact := ImpactData.new()
		impact.source_actor = source_actor
		impact.source_species_id = species_id
		impact.base_damage = damage
		impact.velocity = velocity
		impact.status_effects = [{"effect_id": &"bleed", "duration": 8.0}]
		impact.apply_to(body)
		queue_free()
	else:
		_stuck = true
		velocity = Vector2.ZERO
