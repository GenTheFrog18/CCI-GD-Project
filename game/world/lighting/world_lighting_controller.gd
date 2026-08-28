class_name WorldLightingController
extends Node2D

const OVERLAY_SCENE := preload("res://game/world/lighting/darkness_overlay.tscn")
const MASK_BUILDER := preload("res://game/world/lighting/darkness_mask_builder.gd")

@export_range(1, 64, 1) var maximum_light_sources := 16
@export var darkness_tint := Color(0.08, 0.10, 0.14, 1.0)
@export_range(0.0, 1.0, 0.01) var maximum_screen_darkness := 0.82

var layer_bounds := Rect2()
var darkness_mask: ImageTexture
var overlay: DarknessOverlay
var _lights: Dictionary = {}
var _last_canvas_transform := Transform2D()
var _has_camera_transform := false

func _ready() -> void:
	add_to_group(&"world_lighting_controller")
	overlay = OVERLAY_SCENE.instantiate() as DarknessOverlay
	add_child(overlay)
	overlay.visible = false
	overlay._material.set_shader_parameter(&"darkness_tint", darkness_tint)
	overlay._material.set_shader_parameter(&"maximum_screen_darkness", maximum_screen_darkness)

func _process(_delta: float) -> void:
	_prune_lights()
	if not overlay.visible:
		return
	var canvas_transform := get_viewport().get_canvas_transform()
	if not _has_camera_transform or canvas_transform != _last_canvas_transform:
		_has_camera_transform = true
		_last_canvas_transform = canvas_transform
		overlay.apply_camera_transform(canvas_transform)

func build_for_layer(layer: WorldLayer) -> void:
	var sections: Array[Node] = []
	for section in layer.instantiated_sections.values():
		sections.append(section)
	build(layer.world_bounds, sections)

func build(bounds: Rect2, roots: Array[Node]) -> void:
	layer_bounds = bounds
	var regions: Array[DarknessRegion2D] = []
	for root in roots:
		_collect_regions(root, regions)
	var valid_regions: Array[DarknessRegion2D] = []
	for region in regions:
		var errors := region.validate_against(layer_bounds)
		if not errors.is_empty():
			for error in errors:
				push_error(error)
		else:
			valid_regions.append(region)
	overlay.visible = not valid_regions.is_empty()
	if valid_regions.is_empty():
		darkness_mask = null
		return
	darkness_mask = MASK_BUILDER.new().build_mask(layer_bounds, valid_regions)
	overlay.apply_mask(darkness_mask, layer_bounds)
	_upload_lights()

func register_light(source: LightSource2D) -> void:
	if source == null:
		return
	var id := source.get_instance_id()
	if not _lights.has(id) and _lights.size() >= maximum_light_sources:
		push_warning("WorldLightingController light limit reached; ignoring %s" % source.source_id)
		return
	_lights[id] = source
	_upload_lights()

func update_light(source: LightSource2D) -> void:
	if source == null:
		return
	if not _lights.has(source.get_instance_id()):
		register_light(source)
	else:
		_upload_lights()

func unregister_light(source: LightSource2D) -> void:
	if source == null:
		return
	_lights.erase(source.get_instance_id())
	_upload_lights()

func _collect_regions(node: Node, regions: Array[DarknessRegion2D]) -> void:
	if node == null:
		return
	if node is DarknessRegion2D:
		regions.append(node)
	for child in node.get_children():
		_collect_regions(child, regions)

func _prune_lights() -> void:
	var removed := false
	for id in _lights.keys():
		var source := _lights[id] as LightSource2D
		if not is_instance_valid(source):
			_lights.erase(id)
			removed = true
	if removed:
		_upload_lights()

func _upload_lights() -> void:
	if overlay == null:
		return
	var sources: Array[LightSource2D] = []
	for source in _lights.values():
		if is_instance_valid(source):
			sources.append(source)
	sources.sort_custom(func(a: LightSource2D, b: LightSource2D): return a.get_instance_id() < b.get_instance_id())
	overlay.apply_lights(sources, maximum_light_sources)
