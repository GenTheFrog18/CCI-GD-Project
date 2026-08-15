class_name TongueAmphibian
extends CharacterBody2D

enum State { IDLE, MOVE, ATTACK, RETREAT }

@export var persistent_id := "tongue_amphibian"
@export var move_speed := 45.0
@export var gravity := 900.0
@export var tongue_range := 150.0
@export var telegraph_seconds := 0.45
@export var cooldown_seconds := 2.0
@export var leash_distance := 180.0

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener

var state := State.IDLE
var carried := ItemStack.new()
var _origin := Vector2.ZERO
var _target: Node2D
var _timer := 0.0
var _knockback := Vector2.ZERO

func _ready() -> void:
	support.persistent_id = persistent_id
	add_to_group(&"tongue_amphibian")
	_origin = global_position
	sight.target_seen.connect(func(target: Node2D, _position: Vector2): _target = target)
	sight.target_lost.connect(func(_target_node: Node2D): _target = null)
	sound.sound_accepted.connect(func(event: SoundEvent, _direct: bool): _move_toward(event.position))
	support.health.damaged.connect(func(_info: DamageInfo):
		if not carried.is_empty(): _drop_carried(global_position)
	)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += gravity * delta
	_timer = maxf(0.0, _timer - delta)
	var loose := _nearest_loose_item()
	var desired: Node2D = loose if loose != null else _target
	if not carried.is_empty():
		state = State.RETREAT
		_move_toward(_origin)
	elif state == State.ATTACK:
		velocity.x = 0.0
		if _timer <= 0.0:
			_perform_tongue(desired)
			state = State.IDLE
			_timer = cooldown_seconds
	elif desired != null:
		var distance := global_position.distance_to(desired.global_position)
		if distance <= tongue_range and _timer <= 0.0:
			state = State.ATTACK
			_timer = telegraph_seconds
			if desired.has_method("warn_attack"): desired.warn_attack(self, telegraph_seconds)
		else:
			state = State.MOVE
			_move_toward(desired.global_position)
	else:
		state = State.IDLE
		velocity.x = 0.0
	velocity += _knockback
	_knockback = Vector2.ZERO
	move_and_slide()
	sight.facing = Vector2(signf(velocity.x), 0) if absf(velocity.x) > 0.1 else sight.facing

func _nearest_loose_item() -> Node2D:
	var best: Node2D
	var distance := tongue_range * 1.5
	for node in get_tree().get_nodes_in_group(&"loose_items"):
		if node is not Node2D or node.is_queued_for_deletion(): continue
		var candidate := global_position.distance_to(node.global_position)
		if candidate < distance:
			best = node
			distance = candidate
	return best

func _perform_tongue(target: Node2D) -> void:
	if target == null or global_position.distance_to(target.global_position) > tongue_range * 1.1 or not _tongue_reaches(target):
		return
	if target.has_method("take_as_stack"):
		carried = target.take_as_stack()
		return
	if target.has_method("take_item_for_theft"):
		carried = target.take_item_for_theft()
		if carried.is_empty(): carried = target.take_physical_whistle()
		if carried.is_empty():
			target.apply_damage(DamageInfo.new(1.0, self, support.species_id))
		else:
			target.apply_status(&"spider_slow", {"duration": 1.0})

func _tongue_reaches(target: Node2D) -> bool:
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 15)
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	for frog in get_tree().get_nodes_in_group(&"tongue_amphibian"):
		if frog is CollisionObject2D:
			query.exclude.append(frog.get_rid())
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == target

func _move_toward(point: Vector2) -> void:
	velocity.x = signf(point.x - global_position.x) * move_speed * support.status.get_multiplier(&"move_speed")

func apply_damage(info: DamageInfo) -> bool:
	return support.apply_damage(info)

func apply_force(force: Vector2) -> void:
	_knockback += support.apply_force(force)

func apply_status(id: StringName, data: Dictionary = {}) -> bool:
	return support.apply_status(id, data)

func _drop_carried(position: Vector2) -> void:
	if carried.is_empty(): return
	var definition := ContentCatalog.get_item(carried.item_id)
	if definition != null:
		var drop := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
		drop.configure(definition, carried.state, self, position, Vector2(0, -40))
		get_parent().call_deferred(&"add_child", drop)
	carried = ItemStack.new()

func handle_world_out_of_bounds() -> void:
	if not carried.is_empty():
		var marker := get_tree().get_first_node_in_group(&"lost_item_return_marker") as Node2D
		_drop_carried(marker.global_position if marker != null else _origin)
	global_position = _origin
	velocity = Vector2.ZERO

func capture_state() -> Dictionary:
	var data := support.capture_state()
	data.carried = carried.capture_state()
	return data

func restore_state(data: Dictionary) -> void:
	if support.restore_state(data):
		carried = ItemStack.from_state(data.get("carried", {}))
		global_position = _origin
		state = State.IDLE
