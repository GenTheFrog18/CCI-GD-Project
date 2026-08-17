class_name ThrownItem
extends RigidBody2D

@export var persistent_id := ""
@export var stop_speed := 12.0
@export var stop_seconds := 0.35

var definition: ItemDefinition
var instance_state: Dictionary = {}
var source_actor: Node
var source_species_id: StringName
var base_damage := 0.0
var item_mass := 1.0
var _spawn_position := Vector2.ZERO
var _initial_velocity := Vector2.ZERO
var _still_time := 0.0
var _hit_ids: Dictionary = {}

func configure(item_definition: ItemDefinition, state: Dictionary, source: Node, spawn_position: Vector2, velocity: Vector2, damage := 0.0) -> void:
	definition = item_definition
	instance_state = state.duplicate(true)
	source_actor = source
	var species = source.get("species_id") if source != null else null
	source_species_id = StringName(species) if species != null else &"player"
	_spawn_position = spawn_position
	_initial_velocity = velocity
	base_damage = damage
	item_mass = maxf(float(item_definition.weight), 0.1) if item_definition != null else 1.0
	mass = item_mass

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	global_position = _spawn_position
	linear_velocity = _initial_velocity
	if persistent_id.is_empty():
		persistent_id = GameSession.next_runtime_id(&"thrown", GameSession.current_layer_id)
	add_to_group(&"persistent_objects")
	add_to_group(&"loose_items")
	_apply_visual()

func _physics_process(delta: float) -> void:
	if freeze:
		return
	if linear_velocity.length() <= stop_speed:
		_still_time += delta
		if _still_time >= stop_seconds:
			freeze = true
			add_to_group(&"interactables")
	else:
		_still_time = 0.0

func _on_body_entered(body: Node) -> void:
	if is_queued_for_deletion() or body == source_actor or _hit_ids.has(body.get_instance_id()):
		return
	_hit_ids[body.get_instance_id()] = true
	var impact := ImpactData.new()
	impact.source_actor = source_actor if is_instance_valid(source_actor) else null
	impact.source_species_id = source_species_id
	impact.base_damage = base_damage
	impact.mass = item_mass
	impact.velocity = linear_velocity
	impact.force = linear_velocity.normalized() * item_mass * minf(linear_velocity.length(), 300.0)
	impact.apply_to(body)
	if definition != null:
		var behavior := definition.secondary_behavior if definition.secondary_behavior != null else definition.behavior
		if behavior != null:
			behavior.on_impact(self, impact)

func receive_impact(impact: ImpactData) -> void:
	if freeze:
		freeze = false
		remove_from_group(&"interactables")
	if definition != null:
		var behavior := definition.secondary_behavior if definition.secondary_behavior != null else definition.behavior
		if behavior != null:
			behavior.on_received_impact(self, impact)

func get_interaction_prompt(_actor: Node) -> String:
	return "Pick up %s" % (definition.display_name if definition != null else "item")

func interact(actor: Node) -> bool:
	if not freeze or definition == null or not actor.has_method("try_pickup_item"):
		return false
	if actor.try_pickup_item(definition.item_id, 1, instance_state):
		SaveManager.mark_destroyed(persistent_id)
		queue_free()
		return true
	return false

func take_as_stack() -> ItemStack:
	if definition == null:
		return ItemStack.new()
	var result := ItemStack.new(definition.item_id, 1, instance_state)
	SaveManager.mark_destroyed(persistent_id)
	queue_free()
	return result

func capture_state() -> Dictionary:
	return {
		"item_id": String(definition.item_id) if definition != null else "",
		"instance_state": instance_state.duplicate(true),
		"position": [global_position.x, global_position.y],
		"rotation": rotation,
		"linear_velocity": [linear_velocity.x, linear_velocity.y],
		"angular_velocity": angular_velocity,
		"freeze": freeze,
	}

func restore_state(data: Dictionary) -> void:
	definition = ContentCatalog.get_item(StringName(data.get("item_id", "")))
	item_mass = maxf(float(definition.weight), 0.1) if definition != null else 1.0
	mass = item_mass
	instance_state = data.get("instance_state", {}).duplicate(true)
	var position_data: Array = data.get("position", [0.0, 0.0])
	global_position = Vector2(float(position_data[0]), float(position_data[1]))
	rotation = float(data.get("rotation", 0.0))
	var velocity_data: Array = data.get("linear_velocity", [0.0, 0.0])
	linear_velocity = Vector2(float(velocity_data[0]), float(velocity_data[1]))
	angular_velocity = float(data.get("angular_velocity", 0.0))
	freeze = bool(data.get("freeze", true))
	if freeze:
		add_to_group(&"interactables")
	else:
		remove_from_group(&"interactables")
	_apply_visual()

func _apply_visual() -> void:
	var icon := get_node_or_null("Icon") as Sprite2D
	var fallback := get_node_or_null("Visual") as CanvasItem
	if icon != null:
		icon.texture = definition.icon if definition != null else null
		icon.visible = icon.texture != null
	if fallback != null:
		fallback.visible = icon == null or icon.texture == null

func handle_world_out_of_bounds() -> void:
	if definition != null and definition.recover_out_of_bounds:
		var marker := get_tree().get_first_node_in_group(&"quest_item_recovery_marker") as Node2D
		if marker != null:
			global_position = marker.global_position
			linear_velocity = Vector2.ZERO
			angular_velocity = 0.0
			freeze = true
			add_to_group(&"interactables")
			return
	SaveManager.mark_destroyed(persistent_id)
	queue_free()
