@tool
class_name DialogueInteractable
extends Area2D

@export var persistent_id: StringName
@export var interaction_priority := 10.0
@export var prompt := "Talk"
@export var first_sequence: DialogueSequence
@export var repeat_sequence: DialogueSequence
@export var completed_sequence: DialogueSequence
@export var face_parent_sprite := true
@export_range(0.0, 256.0, 1.0) var interaction_radius := 18.0
@export var show_editor_preview := true

@onready var interaction_indicator: Label = $InteractionIndicator

func _ready() -> void:
	_sync_collision_shape()
	interaction_indicator.visible = false
	if Engine.is_editor_hint():
		queue_redraw()
		return
	add_to_group(&"interactables")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_collision_shape()
		if show_editor_preview:
			queue_redraw()

func _sync_collision_shape() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var current := collision.shape as CircleShape2D if collision != null else null
	if current == null or is_equal_approx(current.radius, interaction_radius):
		return
	var shape := current.duplicate() as CircleShape2D
	shape.radius = interaction_radius
	collision.shape = shape

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_editor_preview:
		return
	draw_circle(Vector2.ZERO, interaction_radius, Color(1.0, 0.7, 0.25, 0.1))
	draw_arc(Vector2.ZERO, interaction_radius, 0.0, TAU, 32, Color(1.0, 0.7, 0.25, 0.9), 2.0)

func get_interaction_prompt(_actor: Node) -> String:
	return prompt

func set_interaction_indicator(enabled: bool) -> void:
	interaction_indicator.visible = enabled

func interact(actor: Node) -> bool:
	var controller: DialogueController
	var hud := get_tree().get_first_node_in_group(&"foundation_hud") as FoundationHUD
	if hud != null:
		controller = hud.dialogue_controller
	if controller == null:
		controller = get_tree().get_first_node_in_group(&"dialogue_controller") as DialogueController
	if controller == null or controller.is_active():
		return false
	_face_actor(actor)
	return controller.start_interaction(self, actor)

func select_sequence() -> DialogueSequence:
	if is_exchange_completed() and completed_sequence != null:
		return completed_sequence
	if not is_first_completed() and first_sequence != null:
		return first_sequence
	return repeat_sequence if repeat_sequence != null else first_sequence

func is_first_completed() -> bool:
	return bool(GameSession.progression_flags.get(_flag_key(&"first_completed"), false))

func mark_first_completed() -> void:
	GameSession.progression_flags[_flag_key(&"first_completed")] = true

func is_exchange_completed() -> bool:
	return bool(GameSession.progression_flags.get(_flag_key(&"exchange_completed"), false))

func mark_exchange_completed() -> void:
	GameSession.progression_flags[_flag_key(&"exchange_completed")] = true

func _flag_key(suffix: StringName) -> String:
	var key := persistent_id if not persistent_id.is_empty() else StringName(get_path())
	return "dialogue:%s:%s" % [key, suffix]

func _face_actor(actor: Node) -> void:
	if not face_parent_sprite or actor is not Node2D:
		return
	var sprite := get_parent().get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite != null:
		sprite.flip_h = (actor as Node2D).global_position.x < global_position.x
