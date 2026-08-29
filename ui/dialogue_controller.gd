class_name DialogueController
extends Node

signal sequence_finished
signal sequence_closed(completed: bool)

const WORLD_ITEM_SCENE := preload("res://game/items/world/world_item.tscn")

var dialogue_box: DialogueBox
var player: PlayerController
var interactable: DialogueInteractable
var _sequence: DialogueSequence
var _steps: Array[DialogueStep] = []
var _step_index := 0
var _locked := false
var _resolving_choice := false

func setup(box: DialogueBox) -> void:
	dialogue_box = box
	dialogue_box.advance_requested.connect(_advance)
	dialogue_box.choice_requested.connect(_choose)
	dialogue_box.closed.connect(_close)
	add_to_group(&"dialogue_controller")

func is_active() -> bool:
	return _sequence != null

func close() -> void:
	_close(false)

func start_interaction(target: DialogueInteractable, actor: Node) -> bool:
	interactable = target
	return start_sequence(target.select_sequence(), target, actor)

func start_sequence(sequence: DialogueSequence, speaker: Node = null, actor: Node = null) -> bool:
	if sequence == null:
		return false
	if is_active():
		_close(false)
	if speaker is DialogueInteractable:
		interactable = speaker as DialogueInteractable
	_sequence = sequence
	player = actor as PlayerController
	_steps = _steps_for(sequence)
	if _steps.is_empty():
		_close(false)
		return false
	_step_index = 0
	_resolving_choice = false
	# Dialogue is non-blocking: the player can move and jump while reading.
	_locked = false
	dialogue_box.open_dialogue(speaker)
	_show_step()
	return true

func _steps_for(sequence: DialogueSequence) -> Array[DialogueStep]:
	if not sequence.steps.is_empty():
		var copied_steps: Array[DialogueStep] = []
		copied_steps.assign(sequence.steps)
		return copied_steps
	var result: Array[DialogueStep] = []
	for entry in sequence.entries:
		var step := DialogueStep.new()
		step.line = entry
		result.append(step)
	for text in sequence.lines:
		var step := DialogueStep.new()
		var line := DialogueLine.new()
		line.speaker_name = sequence.speaker
		line.text = text
		step.line = line
		result.append(step)
	return result

func _show_step() -> void:
	while _step_index < _steps.size():
		var step := _steps[_step_index]
		match step.type:
			DialogueStep.Type.LINE:
				if step.line != null:
					dialogue_box.show_line(step.line)
					return
				_step_index += 1
			DialogueStep.Type.CHOICE:
				dialogue_box.show_choices(step.choices, _available_choices(step.choices))
				return
			DialogueStep.Type.ACTION:
				if not _run_actions(step.actions):
					return
				_step_index += 1
			DialogueStep.Type.END:
				_finish()
				return
	_finish()

func _advance() -> void:
	if is_active() and _step_index < _steps.size() and _steps[_step_index].type == DialogueStep.Type.LINE:
		_step_index += 1
		_show_step()

func _choose(index: int) -> void:
	if not is_active() or _resolving_choice or _step_index >= _steps.size():
		return
	var step := _steps[_step_index]
	if step.type != DialogueStep.Type.CHOICE or index < 0 or index >= step.choices.size():
		return
	var choice := step.choices[index]
	if not _conditions_met(choice.conditions):
		return
	_resolving_choice = true
	dialogue_box.set_choices_enabled(false)
	var sequence_before := _sequence
	if not _run_actions(choice.actions):
		if _sequence != sequence_before:
			return
		_resolving_choice = false
		if is_active(): dialogue_box.set_choices_enabled(true)
		return
	if choice.next_sequence != null:
		var next := choice.next_sequence
		var next_interactable := interactable
		var next_player := player
		_close(false)
		start_sequence(next, next_interactable, next_player)
		return
	_step_index += 1
	_resolving_choice = false
	_show_step()

func _available_choices(choices: Array[DialogueChoice]) -> Array[bool]:
	var result: Array[bool] = []
	for choice in choices:
		result.append(_conditions_met(choice.conditions))
	return result

func _conditions_met(conditions: Array[DialogueCondition]) -> bool:
	for condition in conditions:
		if not _condition_met(condition):
			return false
	return true

func _condition_met(condition: DialogueCondition) -> bool:
	match condition.type:
		DialogueCondition.Type.HAS_ITEM:
			return player != null and player.item_controller.inventory.get_item_quantity(condition.item_id) >= condition.quantity
		DialogueCondition.Type.FIRST_INTERACTION:
			return interactable != null and interactable.is_first_completed() == condition.expected
		DialogueCondition.Type.EXCHANGE_COMPLETED:
			return interactable != null and interactable.is_exchange_completed() == condition.expected
		DialogueCondition.Type.PERSISTENT_FLAG, DialogueCondition.Type.TUTORIAL_SEEN:
			return bool(GameSession.progression_flags.get(String(condition.flag_id), false)) == condition.expected
	return false

func _run_actions(actions: Array[DialogueAction]) -> bool:
	for action in actions:
		if not _run_action(action):
			return false
	return true

func _run_action(action: DialogueAction) -> bool:
	match action.type:
		DialogueAction.Type.CONSUME_ITEM:
			return player != null and player.item_controller.inventory.remove_item(action.item_id, action.quantity)
		DialogueAction.Type.GRANT_ITEM:
			return _grant_or_drop(action.item_id, action.quantity, action.item_state)
		DialogueAction.Type.SET_FLAG:
			GameSession.progression_flags[String(action.flag_id)] = action.flag_value
		DialogueAction.Type.MARK_EXCHANGE:
			if interactable != null:
				interactable.mark_exchange_completed()
		DialogueAction.Type.START_SEQUENCE:
			if action.sequence == null:
				return false
			var next := action.sequence
			var next_interactable := interactable
			var next_player := player
			_close(false)
			start_sequence(next, next_interactable, next_player)
			return false
		DialogueAction.Type.OPEN_TUTORIAL:
			GameSession.progression_flags["dialogue_tutorial:%s" % action.tutorial_id] = true
			_close(false)
			var hud := get_tree().get_first_node_in_group(&"foundation_hud") as FoundationHUD
			if hud != null:
				hud.open_how_to_from_dialogue()
			return false
		DialogueAction.Type.EXCHANGE:
			return _exchange(action)
	return true

func _exchange(action: DialogueAction) -> bool:
	if player == null or player.item_controller.inventory.get_item_quantity(action.item_id) < action.quantity:
		return false
	if not _grant_or_drop(action.reward_item_id, action.reward_quantity, action.reward_state):
		return false
	if not player.item_controller.inventory.remove_item(action.item_id, action.quantity):
		return false
	if interactable != null:
		interactable.mark_exchange_completed()
	return true

func _grant_or_drop(item_id: StringName, quantity: int, state: Dictionary) -> bool:
	if player == null or ContentCatalog.get_item(item_id) == null:
		return false
	if player.try_pickup_item(item_id, quantity, state):
		return true
	var root: Node = get_tree().get_first_node_in_group(&"persistent_spawn_root")
	if root == null:
		root = get_tree().current_scene
	if root == null:
		return false
	var drop := WORLD_ITEM_SCENE.instantiate() as WorldItem
	drop.item_id = item_id
	drop.quantity = quantity
	drop.instance_state = state.duplicate(true)
	drop.persistent_id = GameSession.next_runtime_id(&"dialogue_reward", GameSession.current_layer_id)
	root.add_child(drop)
	drop.global_position = interactable.global_position + Vector2(0.0, -12.0) if interactable != null else player.global_position
	drop.add_to_group(&"persistent_objects")
	AudioManager.play_item_dropped()
	return true

func _finish() -> void:
	if interactable != null and not interactable.is_first_completed():
		interactable.mark_first_completed()
	_close(true)

func _close(completed := false) -> void:
	if _sequence == null:
		return
	if _locked and player != null:
		player.locks.unlock(&"dialogue")
	_locked = false
	_sequence = null
	_steps.clear()
	_step_index = 0
	_resolving_choice = false
	interactable = null
	dialogue_box.hide()
	sequence_closed.emit(completed)
	if completed:
		sequence_finished.emit()
