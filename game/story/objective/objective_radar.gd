class_name ObjectiveRadar
extends Control


# ============================================================
# NODE REFERENCES
# ============================================================

@onready var radar_icon: TextureRect = $RadarIcon

@onready var target_marker: Control = $TargetMarker

@onready var exclamation_icon: TextureRect = \
	$TargetMarker/ExclamationIcon


# ============================================================
# CONFIGURATION
# ============================================================

@export_category("Arrow")

@export var arrow_distance_from_player := 28.0

@export_range(-180.0, 180.0, 1.0)
var arrow_rotation_offset_degrees := 0.0


@export_category("Target Marker")

@export var target_marker_offset := Vector2(0.0, -40.0)


# ============================================================
# STATE
# ============================================================

var _target: Node2D = null
var _target_group: StringName = &""
var _target_layer: StringName = &""

var _active := false


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	print("=== OBJECTIVE RADAR READY ===")

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	mouse_filter = Control.MOUSE_FILTER_IGNORE

	radar_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	target_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exclamation_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	radar_icon.hide()
	target_marker.hide()

	Objective_Manager.objective_started.connect(
		_on_objective_started
	)

	Objective_Manager.objective_completed.connect(
		_on_objective_completed
	)

	# Objective mungkin sudah dibuat sebelum Radar siap.
	if Objective_Manager.has_objective:
		_on_objective_started(
			Objective_Manager.get_current_objective()
		)


# ============================================================
# PROCESS
# ============================================================

func _process(_delta: float) -> void:
	if not _active:
		return

	# --------------------------------------------------------
	# CHECK LAYER
	# --------------------------------------------------------

	if _target_layer != GameSession.current_layer_id:
		radar_icon.hide()
		target_marker.hide()

		_target = null

		return


	# --------------------------------------------------------
	# FIND TARGET
	# --------------------------------------------------------

	if not is_instance_valid(_target):
		_find_target()

	if not is_instance_valid(_target):
		radar_icon.hide()
		target_marker.hide()

		return


	_update_radar()


# ============================================================
# OBJECTIVE STARTED
# ============================================================

func _on_objective_started(objective: Dictionary) -> void:
	print("=== OBJECTIVE RADAR START ===")
	print("Objective: ", objective)

	_target_group = StringName(
		objective.get("target_group", "")
	)

	_target_layer = StringName(
		objective.get(
			"target_layer",
			GameSession.current_layer_id
		)
	)

	print("Target group: ", _target_group)
	print("Target layer: ", _target_layer)

	_active = true

	_target = null

	# Kalau objective bukan layer aktif,
	# jangan cari target.
	if _target_layer != GameSession.current_layer_id:
		print(
			"Objective berada di layer lain: ",
			_target_layer
		)

		radar_icon.hide()
		target_marker.hide()

		return

	_find_target()

	if is_instance_valid(_target):
		print(
			"ObjectiveRadar: Target ditemukan -> ",
			_target.name
		)
	else:
		print("ObjectiveRadar: Target belum ditemukan.")


# ============================================================
# FIND TARGET
# ============================================================

func _find_target() -> void:
	if _target_group.is_empty():
		_target = null
		return

	var nodes := get_tree().get_nodes_in_group(
		_target_group
	)

	if nodes.is_empty():
		_target = null
		return

	for node in nodes:
		if node is Node2D:
			_target = node

			print(
				"ObjectiveRadar: Target ditemukan -> ",
				node.name
			)

			return

	_target = null


# ============================================================
# UPDATE RADAR
# ============================================================

func _update_radar() -> void:
	var player := get_tree().get_first_node_in_group(
		&"player"
	) as Node2D

	if player == null:
		return

	if not is_instance_valid(_target):
		return


	var direction := \
		_target.global_position - player.global_position


	if direction.is_zero_approx():
		radar_icon.hide()
	else:
		_update_arrow(player, direction)


	_update_target_marker()


# ============================================================
# UPDATE ARROW
# ============================================================

func _update_arrow(
	player: Node2D,
	direction: Vector2
) -> void:

	radar_icon.show()

	var player_screen_position := \
		get_viewport().get_canvas_transform() \
		* player.global_position

	var normalized_direction := \
		direction.normalized()

	var arrow_position := \
		player_screen_position + \
		normalized_direction * arrow_distance_from_player

	radar_icon.position = \
		arrow_position - radar_icon.size * 0.5

	radar_icon.rotation = \
		direction.angle() + \
		deg_to_rad(arrow_rotation_offset_degrees)


# ============================================================
# UPDATE TARGET MARKER
# ============================================================

func _update_target_marker() -> void:

	var target_screen_position := \
		get_viewport().get_canvas_transform() \
		* _target.global_position


	target_marker.show()

	target_marker.position = \
		target_screen_position + \
		target_marker_offset - \
		target_marker.size * 0.5


# ============================================================
# REFRESH TARGET
# ============================================================

func refresh_target() -> void:
	_target = null

	if not _active:
		return

	if _target_layer != GameSession.current_layer_id:
		return

	_find_target()


# ============================================================
# OBJECTIVE COMPLETED
# ============================================================

func _on_objective_completed(
	_objective: Dictionary
) -> void:

	print("ObjectiveRadar: Objective selesai.")

	_active = false

	_target = null
	_target_group = &""
	_target_layer = &""

	radar_icon.hide()
	target_marker.hide()
