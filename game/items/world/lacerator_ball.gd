class_name LaceratorBall
extends RigidBody2D

@export var persistent_id := ""
@export var cleanup_delay := 0.35

var source_actor: Node
var source_species_id: StringName = &"player"
var direct_damage := 3.0
var bleed_duration := 8.0
var remaining_hits := 4
var interrupt_strength := 1.0
var _cleanup_remaining := -1.0

func configure(source: Node, position: Vector2, launch_velocity: Vector2, damage: float, bleed: float, hits: int, interrupt: float) -> void:
	source_actor = source
	global_position = position
	linear_velocity = launch_velocity
	direct_damage = damage
	bleed_duration = bleed
	remaining_hits = hits
	interrupt_strength = interrupt

func _ready() -> void:
	if persistent_id.is_empty():
		persistent_id = GameSession.next_runtime_id(&"lacerator_ball", GameSession.current_layer_id)
	add_to_group(&"persistent_objects")

func _physics_process(delta: float) -> void:
	if _cleanup_remaining >= 0.0:
		_cleanup_remaining -= delta
		if _cleanup_remaining <= 0.0:
			SaveManager.mark_destroyed(persistent_id)
			queue_free()
		return
	for body in $DamageArea.get_overlapping_bodies():
		if body == source_actor or body.is_in_group(&"player") or not body.has_method("apply_damage"):
			continue
		var impact := ImpactData.new()
		impact.source_actor = source_actor if is_instance_valid(source_actor) else null
		impact.source_species_id = source_species_id
		impact.base_damage = direct_damage
		impact.velocity = linear_velocity if linear_velocity.length() > 20.0 else Vector2.RIGHT * 300.0
		impact.attack_kind = &"lacerator_ball"
		impact.status_effects = [{"effect_id": &"bleed", "duration": bleed_duration}]
		var result := impact.apply_to(body)
		if not bool(result.damage):
			continue
		remaining_hits -= 1
		if body.has_method("request_interrupt"):
			body.request_interrupt(interrupt_strength, &"lacerator")
		if remaining_hits <= 0:
			$DamageArea.monitoring = false
			_cleanup_remaining = cleanup_delay
			break

func capture_state() -> Dictionary:
	return {"position": [global_position.x, global_position.y], "rotation": rotation, "linear_velocity": [linear_velocity.x, linear_velocity.y], "remaining_hits": remaining_hits, "armed": _cleanup_remaining < 0.0}

func restore_state(data: Dictionary) -> void:
	var position_data: Array = data.get("position", [0.0, 0.0])
	global_position = Vector2(float(position_data[0]), float(position_data[1]))
	rotation = float(data.get("rotation", 0.0))
	var velocity_data: Array = data.get("linear_velocity", [0.0, 0.0])
	linear_velocity = Vector2(float(velocity_data[0]), float(velocity_data[1]))
	remaining_hits = int(data.get("remaining_hits", 4))
	if not bool(data.get("armed", true)):
		_cleanup_remaining = cleanup_delay

func handle_world_out_of_bounds() -> void:
	SaveManager.mark_destroyed(persistent_id)
	queue_free()
