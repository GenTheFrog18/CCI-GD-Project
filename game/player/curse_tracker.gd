class_name CurseTracker
extends Node

@export var trigger_distance := 320.0
@export var stillness_seconds := 10.0
@export var stillness_tolerance := 32.0
@export var transition_grace := 1.0
@export var layer1_duration := 20.0
@export var layer2_duration := 40.0
@export var layer2_stop_chance := 0.05
@export var layer2_stop_seconds := 0.5

var player: PlayerController
var reference_y := 0.0
var crossed_band := 0
var rest_anchor_y := 0.0
var rest_elapsed := 0.0
var grace_remaining := 0.0
var _layer2_roll_remaining := 1.0
var _debug_was_visible := false

func setup(owner_player: PlayerController) -> void:
	player = owner_player
	reference_y = player.global_position.y
	rest_anchor_y = reference_y

func _physics_process(delta: float) -> void:
	if player == null or not player.is_alive(): return
	var layer := GameSession.current_layer_id
	if layer not in [&"layer_1", &"layer_2"]:
		reset_reference(false)
		return
	grace_remaining = maxf(0.0, grace_remaining - delta)
	if player.global_position.y > reference_y:
		reference_y = player.global_position.y
		crossed_band = 0
		rest_anchor_y = reference_y
		rest_elapsed = 0.0
	_update_rest(delta)
	if grace_remaining <= 0.0:
		var band := maxi(0, floori((reference_y - player.global_position.y) / trigger_distance))
		while crossed_band < band:
			crossed_band += 1
			if _cross_threshold(layer): break
	_update_layer2_stop(delta)
	var debug_visible := GameSession.is_debug_draw_enabled(&"player_debug")
	if debug_visible or _debug_was_visible:
		_debug_was_visible = debug_visible
		player.queue_redraw()

func _update_rest(delta: float) -> void:
	if absf(player.global_position.y - rest_anchor_y) > stillness_tolerance:
		rest_anchor_y = player.global_position.y
		rest_elapsed = 0.0
		return
	if player.is_on_floor() or player.is_climbing():
		rest_elapsed += delta
		if rest_elapsed >= stillness_seconds:
			reset_reference(false)
	else:
		rest_elapsed = 0.0

func _cross_threshold(layer: StringName) -> bool:
	var suppression := player.status.get_remaining(&"curse_suppression")
	if suppression > 0.0:
		var cost := 40.0 if layer == &"layer_2" else 20.0
		var remaining := maxf(0.0, suppression - cost)
		if remaining > 0.0:
			player.apply_status(&"curse_suppression", {"duration": remaining})
		else:
			player.status.remove_status(&"curse_suppression")
		reset_reference(false)
		return true
	apply_current_layer_curse()
	return false

func apply_current_layer_curse() -> void:
	apply_layer_curse(GameSession.current_layer_id)

func apply_layer_curse(layer: StringName) -> void:
	if player == null: return
	if layer == &"layer_1":
		player.status.remove_status(&"curse_layer_2_penalty")
		player.status.remove_status(&"curse_layer_2_health_cap")
		var random := RandomNumberGenerator.new()
		random.seed = hash("%s:%s:%d" % [GameSession.run_seed, reference_y, crossed_band])
		player.apply_status(&"curse_layer_1", {"duration": layer1_duration, "modifiers": {
			&"move_speed": random.randf_range(0.6, 0.85),
			&"healing_received": random.randf_range(0.45, 0.75),
			&"throw_range": random.randf_range(0.55, 0.8),
		}})
	elif layer == &"layer_2":
		player.status.remove_status(&"curse_layer_1")
		player.apply_status(&"curse_layer_2_penalty", {"duration": layer2_duration})
		player.apply_status(&"curse_layer_2_health_cap", {"duration": layer2_duration})

func _update_layer2_stop(delta: float) -> void:
	if not player.status.has_status(&"curse_layer_2_penalty"): return
	_layer2_roll_remaining -= delta
	if _layer2_roll_remaining > 0.0: return
	_layer2_roll_remaining += 1.0
	if randf() < layer2_stop_chance:
		player.apply_status(&"incapacitated", {"duration": layer2_stop_seconds})

func reset_reference(with_grace := true) -> void:
	if player == null: return
	reference_y = player.global_position.y
	crossed_band = 0
	rest_anchor_y = reference_y
	rest_elapsed = 0.0
	if with_grace: grace_remaining = transition_grace

func capture_state() -> Dictionary:
	return {
		"reference_y": reference_y, "crossed_band": crossed_band,
		"rest_anchor_y": rest_anchor_y, "rest_elapsed": rest_elapsed,
		"grace_remaining": grace_remaining,
	}

func restore_state(data: Dictionary) -> void:
	reference_y = float(data.get("reference_y", player.global_position.y if player != null else 0.0))
	crossed_band = int(data.get("crossed_band", 0))
	rest_anchor_y = float(data.get("rest_anchor_y", reference_y))
	rest_elapsed = float(data.get("rest_elapsed", 0.0))
	grace_remaining = float(data.get("grace_remaining", transition_grace))
