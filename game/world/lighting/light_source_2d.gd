class_name LightSource2D
extends Node2D

@export var source_id: StringName
@export var light_radius := 128.0
@export_range(0.0, 1.0, 0.01) var light_intensity := 1.0
@export var light_fade_in := 0.0
@export var light_fade_out := 0.0
@export var source_type: StringName = &"world"
@export var enabled := true

var _controller: WorldLightingController
var _last_position := Vector2.INF
var _last_radius := -1.0
var _last_intensity := -1.0
var _last_enabled := false

func _ready() -> void:
	add_to_group(&"light_sources")
	if source_id.is_empty():
		source_id = StringName(name)
	call_deferred(&"_sync")

func _process(_delta: float) -> void:
	_sync()

func _exit_tree() -> void:
	if is_instance_valid(_controller):
		_controller.unregister_light(self)

func _sync() -> void:
	if not is_instance_valid(_controller):
		_controller = get_tree().get_first_node_in_group(&"world_lighting_controller") as WorldLightingController
		if _controller == null:
			return
	var changed := global_position != _last_position or not is_equal_approx(light_radius, _last_radius)
	changed = changed or not is_equal_approx(light_intensity, _last_intensity) or enabled != _last_enabled
	if not changed:
		return
	_last_position = global_position
	_last_radius = light_radius
	_last_intensity = light_intensity
	_last_enabled = enabled
	_controller.update_light(self)
