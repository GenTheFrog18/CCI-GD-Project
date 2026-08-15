class_name PreparedRelic
extends RigidBody2D

const PLACEHOLDER_LIGHT_TEXTURE := preload("res://game/items/world/placeholder_light_texture.tres")

var movement_multiplier := 1.0
var jump_multiplier := 1.0
var effect_shape: Shape2D
var kind: StringName
var definition: ItemDefinition
var instance_state: Dictionary = {}
var source_actor: Node2D
var duration := 0.0
var pulse_interval := 0.5
var pulse_count := 0
var pulse_radius := 300.0
var pulse_priority := 8
var throw_damage := 0.0
var throw_speed := 260.0
var _pulse_remaining := 0.5
var _pulses_sent := 0
var _launched := false
var _collision: CollisionShape2D
var _light: PointLight2D
var _elapsed := 0.0

func configure(item: ItemDefinition, state: Dictionary, actor: Node2D, relic_kind: StringName, settings: Dictionary = {}) -> void:
	definition = item
	instance_state = state.duplicate(true)
	source_actor = actor
	kind = relic_kind
	duration = float(settings.get("duration", 0.0))
	pulse_interval = float(settings.get("pulse_interval", 0.5))
	pulse_count = int(settings.get("pulse_count", 0))
	pulse_radius = float(settings.get("pulse_radius", 300.0))
	pulse_priority = int(settings.get("pulse_priority", 8))
	throw_damage = float(settings.get("throw_damage", 0.0))
	throw_speed = float(settings.get("throw_speed", 260.0))
	movement_multiplier = float(settings.get("movement_multiplier", 1.0))
	jump_multiplier = float(settings.get("jump_multiplier", 1.0))
	effect_shape = settings.get("effect_shape") as Shape2D
	_pulse_remaining = pulse_interval

func _ready() -> void:
	freeze = true
	collision_layer = 0
	collision_mask = 0
	contact_monitor = true
	max_contacts_reported = 4
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	shape_node.shape = shape
	shape_node.disabled = true
	_collision = shape_node
	add_child(shape_node)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([Vector2(0, -6), Vector2(6, 4), Vector2(-6, 4)])
	visual.color = Color(1.0, 0.75, 0.2) if kind == &"sun_sphere" else Color(0.7, 0.9, 0.35)
	add_child(visual)
	if kind == &"sun_sphere":
		add_to_group(&"light_sources")
		_light = PointLight2D.new()
		_light.texture = PLACEHOLDER_LIGHT_TEXTURE
		_light.energy = 0.0
		_light.texture_scale = _effect_extent() / 64.0
		add_child(_light)

func _process(delta: float) -> void:
	_elapsed += delta
	if duration > 0.0:
		duration -= delta
		if _light != null:
			_light.energy = 0.8 * minf(clampf(_elapsed / 0.25, 0.0, 1.0), clampf(duration, 0.0, 1.0))
		if duration <= 0.0:
			queue_free()
			return
	if kind == &"rattlepod" and _pulses_sent < pulse_count:
		_pulse_remaining -= delta
		if _pulse_remaining <= 0.0:
			_pulse_remaining += pulse_interval
			_pulses_sent += 1
			SoundBus.emit_sound(get_tree(), SoundEvent.new(global_position, pulse_radius, &"rattlepod", pulse_priority, self))
			if _pulses_sent >= pulse_count:
				queue_free()

func throw_toward(cursor: Vector2) -> void:
	if _launched:
		return
	_launched = true
	if kind == &"silver_weight" and definition != null:
		var thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
		var direction := global_position.direction_to(cursor)
		var velocity := (direction if not direction.is_zero_approx() else Vector2.RIGHT) * throw_speed
		thrown.configure(definition, instance_state, source_actor, global_position, velocity, 0.0)
		get_parent().add_child(thrown)
		queue_free()
		return
	_enable_world_physics()
	var direction := global_position.direction_to(cursor)
	linear_velocity = (direction if not direction.is_zero_approx() else Vector2.RIGHT) * throw_speed

func can_deactivate() -> bool:
	return kind == &"silver_weight"

func _effect_extent() -> float:
	if effect_shape == null:
		return 128.0
	var rect := effect_shape.get_rect()
	return maxf(rect.size.x, rect.size.y) * 0.5

func _enable_world_physics() -> void:
	freeze = false
	collision_layer = 24
	collision_mask = 7
	if _collision != null:
		_collision.disabled = false

func cancel_preparation(controller: PlayerItemController, reason: StringName) -> void:
	var actor := controller.get_parent() as Node2D
	var world := actor.get_parent() if actor != null else null
	if kind == &"rattlepod" or (kind == &"sun_sphere" and reason == &"save"):
		if world != null:
			var keep := global_transform
			reparent(world)
			global_transform = keep
			_enable_world_physics()
			linear_velocity = Vector2.ZERO
		return
	if definition != null:
		controller.inventory.try_add_item(definition.item_id, 1, instance_state)
	queue_free()
