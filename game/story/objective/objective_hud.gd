class_name ObjectiveHUD
extends Control

@onready var anchor: Control = $ObjectiveAnchor
@onready var panel: PanelContainer = $ObjectiveAnchor/PanelContainer

@onready var margin_container: MarginContainer = \
	$ObjectiveAnchor/PanelContainer/MarginContainer

@onready var content_container: VBoxContainer = \
	$ObjectiveAnchor/PanelContainer/MarginContainer/VBoxContainer

@onready var header_container: HBoxContainer = %HeaderContainer
@onready var header_label: Label = %HeaderLabel
@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var status_label: Label = %StatusLabel

@onready var toggle_button: Button = %ToggleButton
@onready var body_container: VBoxContainer = %BodyContainer
@onready var separator: HSeparator = %Separator

@export_category("Layout")

@export_range(120.0, 500.0, 1.0)
var expanded_width := 280.0

@export_range(100.0, 250.0, 1.0)
var minimized_width := 165.0

@export_range(28.0, 60.0, 1.0)
var minimized_height := 32.0

@export_range(70.0, 250.0, 1.0)
var maximum_height := 180.0


@export_category("Animation")

@export_range(0.08, 0.6, 0.01)
var toggle_animation_duration := 0.28

@export_range(0.05, 0.5, 0.01)
var appear_animation_duration := 0.22

@export_range(0.05, 0.5, 0.01)
var disappear_animation_duration := 0.16

@export_range(0.5, 1.0, 0.01)
var minimized_alpha := 0.97


@export_category("Position")

@export_range(0.0, 100.0, 1.0)
var right_margin := 10.0

@export_range(0.0, 150.0, 1.0)
var top_margin := 55.0

var _is_minimized := false
var _has_objective := false

var _toggle_tween: Tween
var _appear_tween: Tween
var _hide_tween: Tween

var _expanded_height := 100.0

func _ready() -> void:
	z_index = 50

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP

	_expanded_height = anchor.size.y

	call_deferred("_refresh_pivot")

	# Objective Manager
	if not Objective_Manager.objective_changed.is_connected(_on_objective_changed):
		Objective_Manager.objective_changed.connect(
			_on_objective_changed
		)

	# Toggle button
	if not toggle_button.pressed.is_connected(
		_on_toggle_pressed
	):
		toggle_button.pressed.connect(
			_on_toggle_pressed
		)

	# Initial state
	_on_objective_changed(Objective_Manager.get_current_objective())

func _on_objective_changed(objective: Dictionary) -> void:
	if objective.is_empty():
		_has_objective = false
		_hide_hud()
		return

	_has_objective = true

	show()

	var completed: bool = objective.get(
		"completed",
		false
	)

	title_label.text = str(
		objective.get("title", "")
	)

	description_label.text = str(
		objective.get("description", "")
	)

	if completed:
		header_label.text = "OBJECTIVE COMPLETE"
		status_label.text = "✓"
		description_label.text = "Objective completed."
	else:
		header_label.text = "CURRENT OBJECTIVE"
		status_label.text = "◈"

	_is_minimized = false

	_update_toggle_button()

	_apply_expanded_visual_state()

	call_deferred("_prepare_expanded_size")

func _on_toggle_pressed() -> void:
	if not _has_objective:
		return

	_is_minimized = not _is_minimized

	_update_toggle_button()
	_play_toggle_animation()


func set_minimized(
	minimized: bool,
	animated := true
) -> void:

	if _is_minimized == minimized:
		return

	_is_minimized = minimized

	_update_toggle_button()

	if animated:
		_play_toggle_animation()
	else:
		_apply_current_state()


func is_minimized() -> bool:
	return _is_minimized

func _update_toggle_button() -> void:
	if _is_minimized:
		toggle_button.text = "+"
		toggle_button.tooltip_text = "Show objective"
	else:
		toggle_button.text = "−"
		toggle_button.tooltip_text = "Minimize objective"


func _play_toggle_animation() -> void:
	if _toggle_tween != null:
		_toggle_tween.kill()

	if _appear_tween != null:
		_appear_tween.kill()

	if not is_instance_valid(anchor):
		return

	if _expanded_height < minimized_height:
		_expanded_height = minimized_height

	var current_width := anchor.size.x

	var target_width := (
		minimized_width
		if _is_minimized
		else expanded_width
	)

	var target_height := (
		minimized_height
		if _is_minimized
		else _expanded_height
	)

	_toggle_tween = create_tween()
	_toggle_tween.set_parallel(true)

	if _is_minimized:

		_toggle_tween.tween_property(
			body_container,
			"modulate:a",
			0.0,
			toggle_animation_duration * 0.40
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_IN
		)
		
		_toggle_tween.tween_property(
			anchor,
			"offset_left",
			-anchor_right_offset() - target_width,
			toggle_animation_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_IN_OUT
		)

		_toggle_tween.tween_property(
			anchor,
			"offset_bottom",
			top_margin + target_height,
			toggle_animation_duration * 0.82
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_IN_OUT
		)

		_toggle_tween.tween_property(
			panel,
			"modulate:a",
			minimized_alpha,
			toggle_animation_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)
		toggle_button.scale = Vector2.ONE

		_toggle_tween.tween_property(
			toggle_button,
			"scale",
			Vector2.ONE * 0.88,
			toggle_animation_duration * 0.25
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_IN
		)

		_toggle_tween.tween_property(
			toggle_button,
			"scale",
			Vector2.ONE,
			toggle_animation_duration * 0.45
		).set_delay(
			toggle_animation_duration * 0.18
		).set_trans(
			Tween.TRANS_BACK
		).set_ease(
			Tween.EASE_OUT
		)

		_toggle_tween.chain().tween_callback(
			_finish_toggle_animation
		)

	else:

		body_container.visible = true
		body_container.modulate.a = 0.0

		panel.modulate.a = minimized_alpha

		anchor.offset_left = (
			-anchor_right_offset() - current_width
		)

		anchor.offset_bottom = (
			top_margin + minimized_height
		)

		_toggle_tween.tween_property(
			anchor,
			"offset_left",
			-anchor_right_offset() - target_width,
			toggle_animation_duration
		).set_trans(
			Tween.TRANS_CUBIC
		).set_ease(
			Tween.EASE_OUT
		)

		_toggle_tween.tween_property(
			anchor,
			"offset_bottom",
			top_margin + target_height,
			toggle_animation_duration
		).set_trans(
			Tween.TRANS_CUBIC
		).set_ease(
			Tween.EASE_OUT
		)

		_toggle_tween.tween_property(
			panel,
			"modulate:a",
			1.0,
			toggle_animation_duration
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)

		_toggle_tween.tween_property(
			body_container,
			"modulate:a",
			1.0,
			toggle_animation_duration * 0.60
		).set_delay(
			toggle_animation_duration * 0.25
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)

		toggle_button.scale = Vector2.ONE * 0.88

		_toggle_tween.tween_property(
			toggle_button,
			"scale",
			Vector2.ONE,
			toggle_animation_duration * 0.65
		).set_trans(
			Tween.TRANS_BACK
		).set_ease(
			Tween.EASE_OUT
		)

		_toggle_tween.chain().tween_callback(
			_finish_toggle_animation
		)

	_toggle_tween.tween_property(
		anchor,
		"offset_left",
		-anchor_right_offset() - target_width,
		toggle_animation_duration
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_IN_OUT
	)

	_toggle_tween.tween_property(
		anchor,
		"offset_bottom",
		top_margin + target_height,
		toggle_animation_duration
	).set_trans(
		Tween.TRANS_CUBIC
	).set_ease(
		Tween.EASE_IN_OUT
	)

	_toggle_tween.tween_property(
		panel,
		"modulate:a",
		1.0 if not _is_minimized else minimized_alpha,
		toggle_animation_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	if _is_minimized:

		_toggle_tween.tween_property(
			body_container,
			"modulate:a",
			0.0,
			toggle_animation_duration * 0.55
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_IN
		)

	else:

		_toggle_tween.tween_property(
			body_container,
			"modulate:a",
			1.0,
			toggle_animation_duration * 0.65
		).set_delay(
			toggle_animation_duration * 0.28
		).set_trans(
			Tween.TRANS_QUAD
		).set_ease(
			Tween.EASE_OUT
		)

	toggle_button.scale = Vector2.ONE * 0.92

	_toggle_tween.tween_property(
		toggle_button,
		"scale",
		Vector2.ONE,
		toggle_animation_duration * 0.65
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	_toggle_tween.chain().tween_callback(
		_finish_toggle_animation
	)

func _finish_toggle_animation() -> void:
	if not is_instance_valid(anchor):
		return

	if _is_minimized:
		body_container.visible = false
		body_container.modulate.a = 0.0

		panel.modulate.a = minimized_alpha

		_set_anchor_size(
			minimized_width,
			minimized_height
		)

	else:
		body_container.visible = true
		body_container.modulate.a = 1.0

		panel.modulate.a = 1.0

		_set_anchor_size(
			expanded_width,
			_expanded_height
		)

	toggle_button.scale = Vector2.ONE

	call_deferred("_refresh_pivot")

func _apply_minimized_visual_state() -> void:
	if not is_instance_valid(panel):
		return

	body_container.visible = false
	body_container.modulate.a = 0.0

	panel.modulate.a = minimized_alpha

	_set_anchor_size(
		minimized_width,
		minimized_height
	)

func _apply_expanded_visual_state() -> void:
	if not is_instance_valid(panel):
		return

	body_container.visible = true
	body_container.modulate.a = 1.0

	panel.modulate.a = 1.0

	_set_anchor_size(
		expanded_width,
		_expanded_height
	)

func _apply_current_state() -> void:
	if _is_minimized:
		_apply_minimized_visual_state()
	else:
		_apply_expanded_visual_state()

	_refresh_pivot()

func _play_appear_animation() -> void:
	if _appear_tween != null:
		_appear_tween.kill()

	if _hide_tween != null:
		_hide_tween.kill()

	show()

	_is_minimized = false

	_apply_expanded_visual_state()

	# Start sedikit kecil.
	panel.scale = Vector2(
		0.96,
		0.96
	)

	panel.modulate.a = 0.0

	_appear_tween = create_tween()

	_appear_tween.set_parallel(true)

	_appear_tween.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		appear_animation_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	_appear_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		appear_animation_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

func _hide_hud() -> void:
	if _appear_tween != null:
		_appear_tween.kill()

	if _toggle_tween != null:
		_toggle_tween.kill()

	if _hide_tween != null:
		_hide_tween.kill()

	_hide_tween = create_tween()

	_hide_tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		disappear_animation_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	_hide_tween.tween_callback(
		hide
	)

func _prepare_initial_size() -> void:
	await get_tree().process_frame

	_prepare_expanded_size()


func _prepare_expanded_size() -> void:
	if not is_instance_valid(panel):
		return

	await get_tree().process_frame
	await get_tree().process_frame

	var required_size := panel.get_combined_minimum_size()

	_expanded_height = clampf(
		required_size.y,
		minimized_height,
		maximum_height
	)

	if not _is_minimized:
		_set_anchor_size(
			expanded_width,
			_expanded_height
		)

		_refresh_pivot()

		_play_appear_animation()

func _set_anchor_size(
	width: float,
	height: float
) -> void:

	var right_offset := anchor_right_offset()

	anchor.offset_right = -right_offset
	anchor.offset_left = -right_offset - width

	anchor.offset_bottom = top_margin + height

func _set_anchor_position() -> void:
	var width := (
		minimized_width
		if _is_minimized
		else expanded_width
	)

	var height := (
		minimized_height
		if _is_minimized
		else _expanded_height
	)

	_set_anchor_size(
		width,
		height
	)

func anchor_right_offset() -> float:
	return right_margin
	
func _refresh_pivot() -> void:
	if not is_instance_valid(panel):
		return

	await get_tree().process_frame

	panel.pivot_offset = Vector2(
		panel.size.x,
		panel.size.y * 0.5
	)
