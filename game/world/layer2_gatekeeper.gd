class_name Layer2Gatekeeper
extends Area2D

const REWARD_FLAG := "layer_2_core_rewarded"
const REWARD_SCENE := preload("res://game/items/world/world_item.tscn")

@export var confirmation_seconds := 5.0
@export var interaction_priority := 80

@onready var reward_marker: Marker2D = $RewardMarker
var _confirmation_until := -1

func _ready() -> void:
	add_to_group(&"interactables")
	reward_marker.add_to_group(&"quest_item_recovery_marker")

func get_interaction_prompt(actor: Node) -> String:
	if bool(GameSession.progression_flags.get(REWARD_FLAG, false)):
		return "Talk to Layer 2 Gatekeeper"
	if actor is PlayerController and actor.item_controller.inventory.has_item(&"resonance_core"):
		return "Confirm: Give Resonance Core" if Time.get_ticks_msec() <= _confirmation_until else "Offer Resonance Core"
	return "Talk to Layer 2 Gatekeeper"

func interact(actor: Node) -> bool:
	if actor is not PlayerController:
		return false
	if bool(GameSession.progression_flags.get(REWARD_FLAG, false)):
		_feedback(actor, "The Resonance Core reward has already been claimed.")
		return true
	if not actor.item_controller.inventory.has_item(&"resonance_core"):
		_feedback(actor, "Bring me the Resonance Core and I will recognize your Moon rank.")
		return true
	var now := Time.get_ticks_msec()
	if now > _confirmation_until:
		_confirmation_until = now + int(confirmation_seconds * 1000.0)
		_feedback(actor, "Give Resonance Core? Interact again to confirm.")
		return true
	if actor.item_controller.inventory.take_item(&"resonance_core").is_empty():
		return false
	GameSession.progression_flags[REWARD_FLAG] = true
	GameSession.whistle_tier = &"moon"
	GameSession.whistle_changed.emit(GameSession.whistle_tier)
	actor.physical_whistle_id = &"whistle_moon"
	actor.whistle_slot_changed.emit(actor.physical_whistle_id)
	var reward_state := {"origin": "progression", "remaining_uses": 7}
	if not actor.item_controller.inventory.try_add_item(&"bolt_shock", 1, reward_state):
		_spawn_reward(reward_state)
	_feedback(actor, "Moon rank recognized. Take the Moon Whistle and Bolt Shock.")
	SaveManager.save_run()
	return true

func _spawn_reward(state: Dictionary) -> void:
	var reward := REWARD_SCENE.instantiate() as WorldItem
	reward.item_id = &"bolt_shock"
	reward.instance_state = state
	reward.persistent_id = "layer_2_bolt_shock_reward"
	get_parent().add_child(reward)
	reward.global_position = reward_marker.global_position

func _feedback(actor: PlayerController, message: String) -> void:
	actor.item_controller.feedback_requested.emit(message)
