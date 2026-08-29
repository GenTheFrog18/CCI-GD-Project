class_name Layer1BackgroundController
extends CanvasLayer

@export var background_textures: Array[Texture2D] = []
@export_range(0.0, 512.0, 1.0) var fade_in_distance_pixels := 48.0
@export_range(0.0, 5.0, 0.05) var fade_in_duration_seconds := 0.5
@export_range(0.0, 0.2, 0.001) var parallax_strength := 0.02
@export_range(0.0, 128.0, 1.0) var parallax_padding_pixels := 32.0

@onready var _current: TextureRect = $CurrentBackground
@onready var _incoming: TextureRect = $IncomingBackground

var _layer: WorldLayer
var _player: PlayerController
var _active_depth := -1
var _transition_depth := -1
var _transition_reversing := false
var _fade_tween: Tween

func _ready() -> void:
	_layer = get_parent() as WorldLayer
	_configure_background_rect(_current)
	_configure_background_rect(_incoming)
	_incoming.modulate.a = 0.0

func _process(_delta: float) -> void:
	if _layer == null:
		_layer = get_parent() as WorldLayer
	if not is_instance_valid(_player):
		var candidate: Node = get_tree().get_first_node_in_group(&"player")
		_player = candidate as PlayerController
	if _layer == null or not is_instance_valid(_player) or background_textures.is_empty():
		return
	var section := _layer.section_at(_player.global_position)
	if section == null:
		if _active_depth < 0:
			_set_immediate(0)
		_update_background_layout(null)
		return
	var current_depth := _depth_for_section(section)
	if _active_depth < 0:
		_set_immediate(current_depth)
	var desired_depth := _depth_near_boundary(section, current_depth)
	if current_depth != _active_depth and current_depth != _transition_depth:
		_start_transition(current_depth)
	if desired_depth != _active_depth and desired_depth != _transition_depth:
		_start_transition(desired_depth)
	elif desired_depth == _active_depth and _transition_depth >= 0:
		_reverse_transition()
	_update_background_layout(section)

func _configure_background_rect(background: TextureRect) -> void:
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_layout_background_rect(background, Vector2.ZERO)

func _layout_background_rect(background: TextureRect, parallax_offset: Vector2) -> void:
	var size := GameSession.DESIGN_SIZE + Vector2.ONE * parallax_padding_pixels * 2.0
	background.position = (GameSession.DESIGN_SIZE - size) * 0.5 + parallax_offset
	background.size = size

func _update_background_layout(section: WorldSection = null) -> void:
	var parallax_offset := Vector2.ZERO
	if parallax_strength > 0.0 and is_instance_valid(_player) and _player.camera != null:
		var section_center := _layer.world_bounds.get_center()
		if section != null:
			section_center = section.global_position + section.section_size * 0.5
		parallax_offset = (_player.camera.get_screen_center_position() - section_center) * -parallax_strength
		parallax_offset.x = clampf(parallax_offset.x, -parallax_padding_pixels, parallax_padding_pixels)
		parallax_offset.y = clampf(parallax_offset.y, -parallax_padding_pixels, parallax_padding_pixels)
	_layout_background_rect(_current, parallax_offset)
	_layout_background_rect(_incoming, parallax_offset)

func _depth_for_section(section: WorldSection) -> int:
	var slot := _layer.slot_for_section(section)
	if slot == null:
		return 0
	return clampi(slot.depth_index - 1, 0, background_textures.size() - 1)

func _depth_near_boundary(section: WorldSection, current_depth: int) -> int:
	var distance := maxf(fade_in_distance_pixels, 0.0)
	if distance <= 0.0:
		return current_depth
	var local_y := section.to_local(_player.global_position).y
	if local_y >= section.section_size.y - distance and _player.velocity.y >= 0.0:
		if current_depth + 1 < background_textures.size():
			return current_depth + 1
	if local_y <= distance and _player.velocity.y <= 0.0:
		if current_depth > 0:
			return current_depth - 1
	return current_depth

func _texture_for_depth(depth: int) -> Texture2D:
	if depth < 0 or depth >= background_textures.size():
		return null
	return background_textures[depth]

func _set_immediate(depth: int) -> void:
	_cancel_fade()
	_active_depth = depth
	_transition_depth = -1
	_transition_reversing = false
	_current.texture = _texture_for_depth(depth)
	_current.modulate.a = 1.0
	_incoming.texture = null
	_incoming.modulate.a = 0.0
	visible = _current.texture != null

func _start_transition(target_depth: int) -> void:
	if target_depth == _active_depth:
		_reverse_transition()
		return
	var target_texture := _texture_for_depth(target_depth)
	if target_texture == null:
		return
	_cancel_fade()
	_transition_depth = target_depth
	_transition_reversing = false
	_incoming.texture = target_texture
	_incoming.modulate.a = 0.0
	visible = true
	if fade_in_duration_seconds <= 0.0:
		_commit_transition(target_depth)
		return
	var tween := create_tween()
	_fade_tween = tween
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_incoming, "modulate:a", 1.0, fade_in_duration_seconds)
	tween.finished.connect(func():
		if _fade_tween != tween:
			return
		_fade_tween = null
		_commit_transition(target_depth)
	)

func _reverse_transition() -> void:
	if _transition_depth < 0 or _transition_reversing:
		return
	_transition_reversing = true
	_cancel_fade()
	if fade_in_duration_seconds <= 0.0 or _incoming.modulate.a <= 0.001:
		_clear_transition()
		return
	var tween := create_tween()
	_fade_tween = tween
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_incoming, "modulate:a", 0.0, fade_in_duration_seconds)
	tween.finished.connect(func():
		if _fade_tween != tween:
			return
		_fade_tween = null
		_clear_transition()
	)

func _commit_transition(depth: int) -> void:
	_active_depth = depth
	_transition_depth = -1
	_transition_reversing = false
	_current.texture = _texture_for_depth(depth)
	_current.modulate.a = 1.0
	_incoming.texture = null
	_incoming.modulate.a = 0.0

func _clear_transition() -> void:
	_transition_depth = -1
	_transition_reversing = false
	_incoming.texture = null
	_incoming.modulate.a = 0.0

func _cancel_fade() -> void:
	if _fade_tween != null:
		_fade_tween.kill()
		_fade_tween = null
