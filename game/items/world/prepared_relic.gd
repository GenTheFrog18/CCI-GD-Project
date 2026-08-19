class_name PreparedRelic
extends RigidBody2D

const SUN_ACTIVE := preload("res://assets/art/items/sun_sphere_active.png")
const SUN_EXPIRING := preload("res://assets/art/items/sun_sphere_expiring.png")

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
var _light: LightSource2D
var _elapsed := 0.0
var _visual: Sprite2D
var _impact_velocity := Vector2.ZERO
var _impact_activation_pending := false

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
	_visual = Sprite2D.new()
	_visual.texture = definition.texture_for_state(&"active", SUN_ACTIVE) if kind == &"sun_sphere" else definition.texture_for_state(&"prepared")
	add_child(_visual)
	if kind == &"sun_sphere":
		_light = LightSource2D.new()
		_light.light_radius = maxf(_effect_extent(), 64.0)
		_light.light_intensity = 0.0
		_light.enabled = true
		add_child(_light)
	if _impact_activation_pending:
		call_deferred(&"_finish_impact_activation")

func _process(delta: float) -> void:
	_elapsed += delta
	if duration > 0.0:
		duration -= delta
		if kind == &"sun_sphere" and duration <= 3.0:
			_visual.texture = definition.texture_for_state(&"expiring", SUN_EXPIRING)
		if _light != null:
			_light.light_intensity = 0.8 * minf(clampf(_elapsed / 0.25, 0.0, 1.0), clampf(duration, 0.0, 1.0))
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

func activate_from_impact(velocity: Vector2) -> void:
	_launched = true
	_impact_velocity = velocity
	_impact_activation_pending = true
	if is_inside_tree():
		call_deferred(&"_finish_impact_activation")

func _finish_impact_activation() -> void:
	if not _impact_activation_pending or not is_inside_tree():
		return
	_impact_activation_pending = false
	_enable_world_physics()
	linear_velocity = _impact_velocity

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
