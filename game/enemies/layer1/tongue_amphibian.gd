class_name TongueAmphibian
extends CharacterBody2D

const IDLE_SHEET := preload("res://assets/art/enemies/frog/Frog-idle.png")
const ATTACK_SHEET := preload("res://assets/art/enemies/frog/Frog-attack.png")
const JUMP_SHEET := preload("res://assets/art/enemies/frog/Frog-static (untuk jump).png")

enum State { IDLE, MOVE, ATTACK, RETREAT }

@export var persistent_id := "tongue_amphibian"
@export var move_speed := 45.0
@export var gravity := 900.0
@export var jump_velocity := -280.0
@export_range(0.0, 1.0, 0.05) var air_control := 0.15
@export var tongue_range := 150.0
@export var tongue_angle_degrees := 0.0
@export var tongue_width := 16.0
@export var telegraph_seconds := 0.45
@export var cooldown_seconds := 2.0
@export var jump_cooldown_min := 1.75
@export var jump_cooldown_max := 2.25
@export_range(0.0, 1.0, 0.05) var jump_height_randomness := 0.1
@export var theft_cooldown_seconds := 3.0
@export var can_steal_multitool := false
@export var leash_distance := 180.0
@export var carried_drop_offset := Vector2(0.0, -16.0)

@onready var support: EnemySupport = $EnemySupport
@onready var sight: SightSensor = $SightSensor
@onready var sound: SoundListener = $SoundListener
@onready var carried_icon: Sprite2D = $CarriedItemIcon
@onready var visual: AnimatedSprite2D = $Visual

var state := State.IDLE
var carried := ItemStack.new()
var _origin := Vector2.ZERO
var _target: Node2D
var _timer := 0.0
var _jump_timer := 0.0
var _theft_cooldown := 0.0
var _roam_target := Vector2.ZERO
var _has_roam_target := false
var _facing_direction := 1.0
var _random := RandomNumberGenerator.new()
var _knockback := Vector2.ZERO
var _investigation_remaining := 0.0

func _ready() -> void:
	support.persistent_id = persistent_id
	add_to_group(&"tongue_amphibian")
	_setup_visual()
	_origin = global_position
	_random.randomize()
	_jump_timer = _random_jump_cooldown()
	_refresh_carried_icon()
	sight.target_seen.connect(func(target: Node2D, _position: Vector2):
		_target = target
		_investigation_remaining = 0.0
		$AwarenessIndicator.text = "!"
		$AwarenessIndicator.show()
	)
	sight.target_lost.connect(func(_target_node: Node2D):
		_target = null
		if _investigation_remaining <= 0.0: $AwarenessIndicator.hide()
	)
	sound.sound_accepted.connect(func(event: SoundEvent, _direct: bool):
		_investigation_remaining = 2.0
		$AwarenessIndicator.text = "?"
		$AwarenessIndicator.show()
		_move_toward(event.position)
	)
	support.health.damaged.connect(func(_info: DamageInfo):
		if not carried.is_empty(): _drop_carried(global_position)
	)

func _physics_process(delta: float) -> void:
	if not is_on_floor(): velocity.y += gravity * delta
	_timer = maxf(0.0, _timer - delta)
	_jump_timer = maxf(0.0, _jump_timer - delta)
	_theft_cooldown = maxf(0.0, _theft_cooldown - delta)
	_investigation_remaining = maxf(0.0, _investigation_remaining - delta)
	if _target == null and _investigation_remaining <= 0.0:
		$AwarenessIndicator.hide()
	var grounded := is_on_floor()
	if grounded:
		velocity.x = 0.0
	else:
		var air_target := _facing_direction * move_speed * support.status.get_multiplier(&"move_speed")
		velocity.x = move_toward(velocity.x, air_target, move_speed * air_control * delta)
	var loose := _nearest_loose_item()
	var chasing_player := _target != null and sight.current_target == _target
	var desired: Node2D = _target if chasing_player else loose if loose != null else _target
	if not carried.is_empty():
		state = State.RETREAT
		_move_toward(_origin)
	elif state == State.ATTACK:
		if _timer <= 0.0:
			velocity.x = 0.0
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
		state = State.MOVE
		_roam()
	if state != State.ATTACK and grounded and _jump_timer <= 0.0 and not support.status.has_status(&"electro_stunned"):
		velocity.x = _facing_direction * move_speed * support.status.get_multiplier(&"move_speed")
		velocity.y = jump_velocity * _random_jump_height() * support.status.get_multiplier(&"jump_strength")
		_jump_timer = _random_jump_cooldown()
	velocity += _knockback
	_knockback = Vector2.ZERO
	move_and_slide()
	_update_visual(grounded)
	sight.facing = Vector2(_facing_direction, 0.0)
	if GameSession.debug_gameplay_draw:
		queue_redraw()

func _nearest_loose_item() -> Node2D:
	if _theft_cooldown > 0.0:
		return null
	var best: Node2D
	var distance := tongue_range * 1.5
	var best_weight := INF
	for node in get_tree().get_nodes_in_group(&"loose_items"):
		if node is not Node2D or node.is_queued_for_deletion() or not node.has_method("can_be_picked_up") or not node.can_be_picked_up() or not _can_steal_item(node): continue
		var candidate := global_position.distance_to(node.global_position)
		if candidate >= distance:
			continue
		var weight := _item_weight(node)
		if weight < best_weight or (is_equal_approx(weight, best_weight) and candidate < distance):
			best = node
			distance = candidate
			best_weight = weight
	return best

func _perform_tongue(target: Node2D) -> void:
	if target == null or not target.has_method("can_be_picked_up") and not target.has_method("take_item_for_theft"):
		return
	if _theft_cooldown > 0.0:
		return
	if global_position.distance_to(target.global_position) > tongue_range or not _tongue_reaches(target):
		return
	if target.has_method("take_as_stack"):
		if not _can_steal_item(target):
			return
		carried = target.take_as_stack()
		_refresh_carried_icon()
		return
	if target.has_method("take_item_for_theft"):
		carried = target.take_item_for_theft(can_steal_multitool)
		if carried.is_empty(): carried = target.take_physical_whistle()
		if carried.is_empty():
			target.apply_damage(DamageInfo.new(1.0, self, support.species_id))
		else:
			target.apply_status(&"spider_slow", {"duration": 1.0})
		_refresh_carried_icon()

func _tongue_reaches(target: Node2D) -> bool:
	var direction := _tongue_direction()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(tongue_range, maxf(tongue_width, 1.0))
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(direction.angle(), global_position + direction * tongue_range * 0.5)
	query.collision_mask = 15
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	for frog in get_tree().get_nodes_in_group(&"tongue_amphibian"):
		if frog is CollisionObject2D:
			query.exclude.append(frog.get_rid())
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 32):
		if hit.get("collider") == target:
			return true
	return false

func _move_toward(point: Vector2) -> void:
	if absf(point.x - global_position.x) > 1.0:
		_set_facing(signf(point.x - global_position.x))

func _move_away_from(point: Vector2) -> void:
	if absf(point.x - global_position.x) > 1.0:
		_set_facing(signf(global_position.x - point.x))

func _roam() -> void:
	if not _has_roam_target or global_position.distance_to(_roam_target) <= 8.0:
		_roam_target = _origin + Vector2(_random.randf_range(-leash_distance, leash_distance), 0.0)
		_has_roam_target = true
	_move_toward(_roam_target)

func _set_facing(direction: float) -> void:
	if is_zero_approx(direction):
		return
	_facing_direction = -1.0 if direction < 0.0 else 1.0
	$Visual.scale.x = absf($Visual.scale.x) * _facing_direction

func _setup_visual() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, &"idle", IDLE_SHEET, 4, 6.0, true)
	_add_animation(frames, &"attack", ATTACK_SHEET, 6, 10.0, false)
	_add_animation(frames, &"jump", JUMP_SHEET, 1, 1.0, true)
	visual.sprite_frames = frames
	visual.play(&"idle")

func _add_animation(frames: SpriteFrames, animation: StringName, sheet: Texture2D, count: int, speed: float, loop: bool) -> void:
	frames.add_animation(animation)
	frames.set_animation_speed(animation, speed)
	frames.set_animation_loop(animation, loop)
	for index in count:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(index * 64, 0, 64, 64)
		frames.add_frame(animation, frame)

func _update_visual(grounded: bool) -> void:
	if state == State.ATTACK:
		_play_visual(&"attack")
	elif not grounded:
		_play_visual(&"jump")
	else:
		_play_visual(&"idle")

func _play_visual(animation: StringName) -> void:
	if visual.animation != animation:
		visual.play(animation)

func _tongue_direction() -> Vector2:
	return Vector2(_facing_direction, 0.0).rotated(deg_to_rad(tongue_angle_degrees)).normalized()

func _random_jump_cooldown() -> float:
	return _random.randf_range(minf(jump_cooldown_min, jump_cooldown_max), maxf(jump_cooldown_min, jump_cooldown_max))

func _random_jump_height() -> float:
	var variation := clampf(jump_height_randomness, 0.0, 1.0)
	return _random.randf_range(1.0 - variation, 1.0 + variation)

func _item_weight(item: Node) -> float:
	var definition := item.get("definition") as ItemDefinition
	if definition == null:
		var item_id: Variant = item.get("item_id")
		definition = ContentCatalog.get_item(StringName(item_id)) if item_id != null else null
	return float(definition.weight) if definition != null else INF

func _can_steal_item(item: Node) -> bool:
	if can_steal_multitool:
		return true
	var definition := item.get("definition") as ItemDefinition
	if definition != null:
		return definition.item_id != &"multitool"
	var item_id: Variant = item.get("item_id")
	return item_id == null or StringName(item_id) != &"multitool"

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
		drop.configure(definition, carried.state, self, position + carried_drop_offset, Vector2(0, -40))
		get_parent().call_deferred(&"add_child", drop)
	carried = ItemStack.new()
	_theft_cooldown = maxf(theft_cooldown_seconds, 0.0)
	_refresh_carried_icon()

func _refresh_carried_icon() -> void:
	var definition := ContentCatalog.get_item(carried.item_id) if not carried.is_empty() else null
	carried_icon.texture = definition.texture_for_instance(carried.state) if definition != null else null
	carried_icon.visible = carried_icon.texture != null

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
		_refresh_carried_icon()
		velocity = Vector2.ZERO
		state = State.IDLE
		_has_roam_target = false

func _draw() -> void:
	if not GameSession.debug_gameplay_draw:
		return
	var direction := _tongue_direction()
	var angle := direction.angle()
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	draw_rect(Rect2(0.0, -maxf(tongue_width, 1.0) * 0.5, tongue_range, maxf(tongue_width, 1.0)), Color(1.0, 0.25, 0.25, 0.35), true)
	draw_line(Vector2.ZERO, Vector2.RIGHT * tongue_range, Color(1.0, 0.4, 0.2, 0.95), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
