@tool
class_name Layer1SectionPreview
extends Node2D

const SECTION_SIZE := Vector2(1280.0, 800.0)
const SLOT_IDS: Array[StringName] = [
	&"layer1_west_01", &"layer1_west_02", &"layer1_west_03",
	&"layer1_east_01", &"layer1_east_02", &"layer1_east_03",
]
const SLOT_POSITIONS: Array[Vector2] = [
	Vector2(0.0, 0.0), Vector2(0.0, SECTION_SIZE.y), Vector2(0.0, SECTION_SIZE.y * 2.0),
	Vector2(SECTION_SIZE.x, 0.0), Vector2(SECTION_SIZE.x, SECTION_SIZE.y), Vector2(SECTION_SIZE.x, SECTION_SIZE.y * 2.0),
]

@export_group("West Route")
@export var west_01: PackedScene
@export var west_02: PackedScene
@export var west_03: PackedScene

@export_group("East Route")
@export var east_01: PackedScene
@export var east_02: PackedScene
@export var east_03: PackedScene

@export_group("Editor Guides")
@export var show_guides := true

var _preview_root: Node2D
var _last_signature: Array[String] = []

func _ready() -> void:
	_preview_root = get_node_or_null("PreviewSections") as Node2D
	if not Engine.is_editor_hint():
		visible = false
		set_process(false)
		return
	call_deferred("_rebuild_preview")

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	var signature := _scene_signature()
	if signature != _last_signature:
		_rebuild_preview()

func _rebuild_preview() -> void:
	if not Engine.is_editor_hint() or _preview_root == null:
		return
	for child in _preview_root.get_children():
		child.free()
	var scenes := _selected_scenes()
	for index in scenes.size():
		var scene := scenes[index]
		if scene == null:
			continue
		var instance := scene.instantiate()
		if instance == null:
			continue
		var section := instance as WorldSection
		if section == null:
			instance.free()
			continue
		section.name = "Preview_%s" % SLOT_IDS[index]
		section.position = SLOT_POSITIONS[index]
		_preview_root.add_child(section)
	_last_signature = _scene_signature()
	update_configuration_warnings()
	queue_redraw()

func _selected_scenes() -> Array[PackedScene]:
	return [west_01, west_02, west_03, east_01, east_02, east_03]

func _scene_signature() -> Array[String]:
	var signature: Array[String] = []
	for scene in _selected_scenes():
		signature.append(scene.resource_path if scene != null else "")
	return signature

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var scenes := _selected_scenes()
	for index in scenes.size():
		var scene := scenes[index]
		if scene == null:
			warnings.append("Missing preview scene for %s" % SLOT_IDS[index])
			continue
		var instance := scene.instantiate()
		if instance == null:
			warnings.append("Preview scene for %s could not be instantiated" % SLOT_IDS[index])
			continue
		var section := instance as WorldSection
		if section == null:
			instance.free()
			warnings.append("Preview scene for %s must have a WorldSection root" % SLOT_IDS[index])
			continue
		if section.slot_id != SLOT_IDS[index]:
			warnings.append("%s belongs to %s, expected %s" % [scene.resource_path, section.slot_id, SLOT_IDS[index]])
		section.free()
	return warnings

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_guides:
		return
	var guide_color := Color(0.2, 0.8, 1.0, 0.9)
	var route_color := Color(0.2, 0.8, 1.0, 0.45)
	var preview_size := Vector2(SECTION_SIZE.x * 2.0, SECTION_SIZE.y * 3.0)
	draw_rect(Rect2(Vector2.ZERO, preview_size), guide_color, false, 4.0)
	for x in [0.0, SECTION_SIZE.x, preview_size.x]:
		draw_line(Vector2(x, 0.0), Vector2(x, preview_size.y), route_color, 2.0)
	for y in [0.0, SECTION_SIZE.y, SECTION_SIZE.y * 2.0, preview_size.y]:
		draw_line(Vector2(0.0, y), Vector2(preview_size.x, y), route_color, 2.0)
	for index in SLOT_IDS.size():
		draw_string(ThemeDB.fallback_font, SLOT_POSITIONS[index] + Vector2(16.0, 32.0), String(SLOT_IDS[index]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 20, guide_color)
