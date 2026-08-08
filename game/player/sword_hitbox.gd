class_name SwordHitbox
extends Area2D

@export var damage := 10.0

var hit_targets: Array[Node] = []

func _ready() -> void:
	$CollisionShape2D.disabled = true

func start_attack() -> void:
	hit_targets.clear()
	$CollisionShape2D.disabled = false

func end_attack() -> void:
	$CollisionShape2D.disabled = true

func _on_body_entered(body: Node2D) -> void:
	if body in hit_targets:
		return

	if body.has_method("apply_damage"):
		hit_targets.append(body)
		body.apply_damage(DamageInfo.new(damage))
