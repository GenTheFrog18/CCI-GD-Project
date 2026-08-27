class_name SeniorDiver
extends CharacterBody2D

enum State { POST, CHASE, GRAB_TELEGRAPH, GRAB_RESOLUTION, LOST_TARGET, INVESTIGATE }

const GRAB_LOCK_REASON := &"senior_diver_grab"
const IDLE_SHEET := preload("res://assets/art/characters/npc/animation/Gatekeeper1/Gatekeeper1Idle-48x64-4FPS.png")
const WALK_SHEET := preload("res://assets/art/characters/npc/animation/Gatekeeper1/Gatekeeper1Walk-48x64-4FPS.png")
const GRAB_SHEET := preload("res://assets/art/characters/npc/animation/Gatekeeper1/Gatekeeper1Grab-48x64-10FPS.png")
const FIRST_WARNING_FLAG := "gatekeeper1:first_warning_seen"
const ESCALATION_FLAG := "gatekeeper1:escalation_seen"
const BLUE_INTRO_FLAG := "gatekeeper1:blue_intro_seen"

@export var persistent_id := "senior_diver"
@export var move_speed := 42.0
@export var gravity := 900.0
@export var restricted_radius := 120.0
@export var grab_range := 26.0
@export var telegraph_seconds := 0.25
@export var grab_lock_seconds := 1.0
@export var lost_seconds := 3.0
@export var trespass_knockback := 180.0
@export var investigation_speed := 76.0
@export var investigation_seconds := 3.0
@export var return_drop_spacing := 12.0
@export var first_warning_dialogue: DialogueSequence
@export var escalation_dialogue: DialogueSequence
@export var grab_dialogue: DialogueSequence
@export var blue_intro_dialogue: DialogueSequence

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener
@onready var lost_item_return: Marker2D = $LostItemReturn
@onready var visual: AnimatedSprite2D = $Visual

var state := State.POST
var _origin := Vector2.ZERO
var _target: PlayerController
var _grab_target: PlayerController
var _timer := 0.0
var _lost := 0.0
var _has_sight := false
var _has_last_known_position := false
var _knockback := Vector2.ZERO
var _was_restricted := false
var _last_known_position := Vector2.ZERO
var _investigation_position := Vector2.ZERO
var _investigation_remaining := 0.0
var _retaliation_target: PlayerController
var _grab_in_progress := false
var _grab_cancelled := false
var _grab_waiting_for_dialogue := false
var _first_warning_dialogue_active := false
var _aggravated := false

func _ready() -> void:
	support.persistent_id = persistent_id
	_origin = global_position
	_aggravated = bool(GameSession.progression_flags.get(ESCALATION_FLAG, false))
	_setup_visual()
	add_to_group(&"interactables")
	sight.target_seen.connect(_on_seen)
	sight.target_lost.connect(_on_lost)
	sound.sound_accepted.connect(_on_sound)
	support.health.died.connect(_on_died)
	lost_item_return.add_to_group(&"lost_item_return_marker")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	_timer = maxf(0.0, _timer - delta)

	if _grab_in_progress:
		_apply_motion(delta)
		return

	if state == State.GRAB_TELEGRAPH:
		_process_grab_telegraph()
		_apply_motion(delta)
		return

	if state == State.INVESTIGATE:
		_process_investigation(delta)
		_apply_motion(delta)
		return

	if not _valid_target(_target):
		_clear_target()
	var is_retaliating := is_instance_valid(_retaliation_target) and _target == _retaliation_target
	if is_retaliating:
		if _dialogue_is_active():
			_dialogue_controller().close()
		if _has_sight:
			_process_chase()
		else:
			_process_lost_target(delta)
		_apply_motion(delta)
		return

	var sees_red := _target != null and _has_sight and _is_red_whistle(_target)
	var sees_blue := _target != null and _has_sight and _is_authorized(_target)
	var inside_restricted := _target != null and _has_sight and not _is_authorized(_target) \
		and global_position.distance_to(_target.global_position) <= restricted_radius
	if sees_blue and not bool(GameSession.progression_flags.get(BLUE_INTRO_FLAG, false)):
		if _start_dialogue(blue_intro_dialogue, _target):
			GameSession.progression_flags[BLUE_INTRO_FLAG] = true
		state = State.POST
		velocity.x = 0.0
		_was_restricted = false
		_apply_motion(delta)
		return
	if sees_red:
		if _dialogue_is_active():
			state = State.POST
			velocity.x = 0.0
			_was_restricted = false
			_apply_motion(delta)
			return
		if not bool(GameSession.progression_flags.get(FIRST_WARNING_FLAG, false)):
			if _start_dialogue(first_warning_dialogue, _target):
				_first_warning_dialogue_active = true
				var controller: DialogueController = _dialogue_controller()
				controller.sequence_closed.connect(_on_first_warning_closed, CONNECT_ONE_SHOT)
			state = State.POST
			velocity.x = 0.0
			_was_restricted = false
			_apply_motion(delta)
			return
		if inside_restricted and not _aggravated:
			if _dialogue_is_active():
				state = State.POST
				velocity.x = 0.0
				_apply_motion(delta)
				return
			_aggravated = true
			GameSession.progression_flags[ESCALATION_FLAG] = true
			if _start_dialogue(escalation_dialogue, _target):
				state = State.POST
				velocity.x = 0.0
				_was_restricted = false
				_apply_motion(delta)
				return
	if inside_restricted and not _was_restricted:
		_warn_trespass(_target)
	_was_restricted = inside_restricted

	if _is_red_whistle(_target) and not _aggravated:
		state = State.POST
		_move_to_post()
	elif inside_restricted:
		_process_chase()
	elif not _has_sight and _target != null:
		_process_lost_target(delta)
	else:
		state = State.POST
		_lost = lost_seconds
		_move_to_post()

	_apply_motion(delta)

func _process_chase() -> void:
	if _target == null:
		return
	if global_position.distance_to(_target.global_position) <= grab_range:
		state = State.GRAB_TELEGRAPH
		_timer = telegraph_seconds
		_grab_target = _target
		_grab_cancelled = false
		_target.warn_attack(self, telegraph_seconds)
		velocity.x = 0.0
		return
	state = State.CHASE
	velocity.x = signf(_target.global_position.x - global_position.x) * move_speed * _move_multiplier()

func _process_grab_telegraph() -> void:
	velocity.x = 0.0
	if not _grab_valid():
		_cancel_grab()
		return
	if _timer <= 0.0:
		_resolve_grab()

func _resolve_grab() -> void:
	if _grab_in_progress or not _grab_valid():
		_cancel_grab()
		return
	_grab_in_progress = true
	_grab_cancelled = false
	state = State.GRAB_RESOLUTION
	var target := _grab_target
	target.locks.lock(GRAB_LOCK_REASON)
	_grab_waiting_for_dialogue = true
	if _start_dialogue(grab_dialogue, target):
		var controller: DialogueController = _dialogue_controller()
		controller.sequence_closed.connect(_on_grab_dialogue_closed.bind(target), CONNECT_ONE_SHOT)
		return
	_grab_waiting_for_dialogue = false
	_finish_grab(target)

func _on_grab_dialogue_closed(_completed: bool, target: PlayerController) -> void:
	if not _grab_waiting_for_dialogue or target != _grab_target:
		return
	_grab_waiting_for_dialogue = false
	_finish_grab(target)

func _finish_grab(target: PlayerController) -> void:
	var confiscated := target.confiscate_relic_items()
	_return_confiscated_items(confiscated)
	await get_tree().create_timer(grab_lock_seconds).timeout
	if _grab_cancelled:
		return
	if is_instance_valid(target):
		target.locks.unlock(GRAB_LOCK_REASON)
	_grab_in_progress = false
	_grab_target = null
	_target = null
	_has_sight = false
	_was_restricted = false
	state = State.POST
	_lost = lost_seconds
	var world := _find_world_run()
	if world != null:
		world.request_layer_transition(&"surface", &"west")

func _process_lost_target(delta: float) -> void:
	state = State.LOST_TARGET
	_lost = maxf(0.0, _lost - delta)
	if _lost <= 0.0:
		_clear_target()
		_move_to_post()
		return
	velocity.x = signf(_last_known_position.x - global_position.x) * move_speed * _move_multiplier()

func _process_investigation(delta: float) -> void:
	_investigation_remaining = maxf(0.0, _investigation_remaining - delta)
	if _investigation_remaining <= 0.0 or global_position.distance_to(_investigation_position) <= 12.0:
		state = State.POST
		_move_to_post()
		return
	velocity.x = signf(_investigation_position.x - global_position.x) * investigation_speed * _move_multiplier()

func _move_to_post() -> void:
	velocity.x = signf(_origin.x - global_position.x) * move_speed * _move_multiplier() if absf(_origin.x - global_position.x) > 4.0 else 0.0

func _warn_trespass(target: PlayerController) -> void:
	if target == null:
		return
	var away := global_position.direction_to(target.global_position)
	target.apply_force(Vector2(away.x * trespass_knockback, -trespass_knockback * 0.35))

func _apply_motion(_delta: float) -> void:
	velocity += _knockback
	_knockback = Vector2.ZERO
	move_and_slide()
	_update_visual()

func _on_seen(target: Node2D, position: Vector2) -> void:
	if target is not PlayerController:
		return
	_target = target
	_last_known_position = position
	_has_last_known_position = true
	_has_sight = true
	_lost = lost_seconds

func _on_lost(target: Node2D) -> void:
	if target != _target:
		return
	_has_sight = false
	_lost = lost_seconds
	_last_known_position = target.global_position
	_has_last_known_position = true
	if state == State.GRAB_TELEGRAPH:
		_cancel_grab()

func _on_first_warning_closed(_completed: bool) -> void:
	if not _first_warning_dialogue_active:
		return
	_first_warning_dialogue_active = false
	GameSession.progression_flags[FIRST_WARNING_FLAG] = true

func _on_sound(event: SoundEvent, _direct: bool) -> void:
	if event == null or event.sound_type not in [&"rattlepod", &"whistle", &"crystal", &"lantern_crystal"]:
		return
	if state == State.GRAB_RESOLUTION or _grab_in_progress:
		return
	_cancel_grab()
	_target = null
	_has_sight = false
	_was_restricted = false
	_investigation_position = event.position
	_investigation_remaining = investigation_seconds
	state = State.INVESTIGATE

func _grab_valid() -> bool:
	var forced := is_instance_valid(_retaliation_target) and _grab_target == _retaliation_target
	return (forced or (not _first_warning_dialogue_active and not _dialogue_is_active() \
		and bool(GameSession.progression_flags.get(FIRST_WARNING_FLAG, false)))) \
		and is_instance_valid(_grab_target) and _grab_target.is_alive() \
		and (forced or not _is_authorized(_grab_target)) and _has_sight \
		and global_position.distance_to(_grab_target.global_position) <= grab_range

func _valid_target(target: PlayerController) -> bool:
	return is_instance_valid(target) and target.is_alive()

func _is_authorized(player: PlayerController) -> bool:
	return player != null and GameSession.whistle_tier == &"blue"

func _is_red_whistle(player: PlayerController) -> bool:
	return player != null and GameSession.whistle_tier == &"red"

func _clear_target() -> void:
	_target = null
	_retaliation_target = null
	_has_sight = false
	_lost = 0.0
	_was_restricted = false
	if state in [State.CHASE, State.LOST_TARGET, State.GRAB_TELEGRAPH]:
		state = State.POST

func _cancel_grab() -> void:
	_grab_cancelled = true
	_grab_waiting_for_dialogue = false
	if is_instance_valid(_grab_target):
		_grab_target.locks.unlock(GRAB_LOCK_REASON)
	_grab_target = null
	_grab_in_progress = false
	if state == State.GRAB_TELEGRAPH or state == State.GRAB_RESOLUTION:
		state = State.POST
		_timer = 0.0

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"idle", IDLE_SHEET, 4, 4.0, true)
	_add_animation(frames, &"walk", WALK_SHEET, 6, 4.0, true)
	_add_animation(frames, &"grab", GRAB_SHEET, 10, 10.0, false)
	visual.sprite_frames = frames
	visual.play(&"idle")

func _add_animation(frames: SpriteFrames, name: StringName, sheet: Texture2D, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loop)
	for index in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(index * 48.0, 0.0, 48.0, 48.0)
		frames.add_frame(name, atlas)

func _update_visual() -> void:
	var animation: StringName = &"grab" if state in [State.GRAB_TELEGRAPH, State.GRAB_RESOLUTION] else (&"walk" if absf(velocity.x) > 0.1 else &"idle")
	if visual.animation != animation:
		visual.play(animation)
	var facing: float = signf(velocity.x)
	if is_zero_approx(facing):
		if is_instance_valid(_target):
			facing = signf(_target.global_position.x - global_position.x)
		elif _has_last_known_position:
			facing = signf(_last_known_position.x - global_position.x)
	if not is_zero_approx(facing):
		visual.flip_h = facing < 0.0
		sight.facing = Vector2(facing, 0.0)

func _dialogue_controller() -> DialogueController:
	var hud := get_tree().get_first_node_in_group(&"foundation_hud") as FoundationHUD
	return hud.dialogue_controller if hud != null else null

func _dialogue_is_active() -> bool:
	var controller: DialogueController = _dialogue_controller()
	return controller != null and controller.is_active()

func _start_dialogue(sequence: DialogueSequence, target: PlayerController) -> bool:
	if sequence == null:
		return false
	var controller: DialogueController = _dialogue_controller()
	return controller != null and not controller.is_active() and controller.start_sequence(sequence, self, target)

func _return_confiscated_items(stacks: Array[ItemStack]) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var index := 0
	for stack in stacks:
		var definition := ContentCatalog.get_item(stack.item_id)
		if definition == null:
			continue
		for _quantity in stack.quantity:
			var drop := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
			var offset := Vector2(float(index % 4) * return_drop_spacing, float(index / 4) * return_drop_spacing)
			drop.configure(definition, stack.state, null, lost_item_return.global_position + offset, Vector2.ZERO)
			drop.freeze = true
			parent.call_deferred(&"add_child", drop)
			index += 1

func _on_died(_source: Node) -> void:
	_cancel_grab()
	_target = null
	_retaliation_target = null
	_has_sight = false
	_was_restricted = false

func get_interaction_prompt(_actor: Node) -> String:
	return "Talk to Senior Diver"

func interact(actor: Node) -> bool:
	if actor is not PlayerController:
		return false
	actor.item_controller.feedback_requested.emit("Blue rank confirmed." if _is_authorized(actor) else "The diver warns you not to pass.")
	return true

func _find_world_run() -> WorldRun:
	var node: Node = self
	while node != null:
		if node is WorldRun:
			return node
		node = node.get_parent()
	return null

func _move_multiplier() -> float:
	return support.status.get_multiplier(&"move_speed")

func apply_damage(info: DamageInfo) -> bool:
	var applied := support.apply_damage(info)
	var attacker := info.source as PlayerController
	if applied and not support.health.is_dead and is_instance_valid(attacker):
		_retaliation_target = attacker
		_target = attacker
		_last_known_position = attacker.global_position
		_has_last_known_position = true
		_has_sight = true
		_aggravated = true
		GameSession.progression_flags[ESCALATION_FLAG] = true
		_cancel_grab()
		if _dialogue_is_active():
			_dialogue_controller().close()
		_process_chase()
	return applied

func apply_force(force: Vector2) -> void:
	_knockback += support.apply_force(force)

func apply_status(id: StringName, data: Dictionary = {}) -> bool:
	return support.apply_status(id, data)

func capture_state() -> Dictionary:
	return support.capture_state()

func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		global_position = _origin
		velocity = Vector2.ZERO
		_cancel_grab()
		_target = null
		_retaliation_target = null
		_has_sight = false
		_lost = 0.0
		_was_restricted = false
		state = State.POST

func handle_world_out_of_bounds() -> void:
	_cancel_grab()
	global_position = _origin
	velocity = Vector2.ZERO
	_target = null
	_retaliation_target = null
	_has_sight = false
	_lost = 0.0
	_was_restricted = false
	state = State.POST
