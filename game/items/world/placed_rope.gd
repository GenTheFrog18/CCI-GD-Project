@tool
class_name PlacedRope
extends Area2D

const SEGMENT_TEXTURE := preload("res://assets/art/items/rope/rope_segment.png")
const END_TEXTURE := preload("res://assets/art/items/rope/rope_end.png")
const ROPE_SCENE_PATH := "res://game/items/world/placed_rope.tscn"

@export var persistent_id := ""
@export_range(16.0, 1000.0, 16.0) var rope_length: float = 160.0:
	set(value):
		rope_length = maxf(16.0, floorf(float(value) / 16.0) * 16.0)
		if Engine.is_editor_hint() and is_inside_tree():
			_rebuild_rope()

var chain_root: PlacedRope
var _anchor := Vector2.ZERO
var _end_sprite: Sprite2D
var _configured := false

func configure(anchor_position: Vector2, length: float, root: PlacedRope = null) -> void:
	_configured = true
	_anchor = anchor_position
	rope_length = maxf(16.0, floorf(length / 16.0) * 16.0)
	chain_root = root

func _ready() -> void:
	if Engine.is_editor_hint():
		chain_root = self
		_anchor = global_position
		_build_rope()
		return
	if chain_root == null:
		chain_root = self
	if _configured:
		global_position = _anchor
	add_to_group(&"placed_ropes")
	if get_chain_root() == self:
		if persistent_id.is_empty():
			persistent_id = GameSession.next_runtime_id(&"rope", GameSession.current_layer_id)
		add_to_group(&"persistent_objects")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_build_rope()
	get_chain_root()._refresh_chain_ends()

func top_y() -> float:
	return global_position.y

func bottom_y() -> float:
	return global_position.y + rope_length

func get_chain_root() -> PlacedRope:
	return chain_root if is_instance_valid(chain_root) else self

func get_chain_top() -> float:
	var top := top_y()
	for candidate in _get_chain_members():
		top = minf(top, candidate.top_y())
	return top

func get_chain_bottom() -> float:
	var bottom := bottom_y()
	for candidate in _get_chain_members():
		bottom = maxf(bottom, candidate.bottom_y())
	return bottom

func capture_state() -> Dictionary:
	var pieces := _get_chain_members()
	pieces.sort_custom(func(a: PlacedRope, b: PlacedRope): return a.top_y() < b.top_y())
	var lengths: Array[float] = []
	for piece in pieces:
		lengths.append(piece.rope_length)
	return {
		"position": [global_position.x, global_position.y],
		"segment_lengths": lengths,
	}

func restore_state(data: Dictionary) -> void:
	for piece in _get_chain_members():
		if piece != self:
			piece.free()
	var saved_position: Array = data.get("position", [0.0, 0.0])
	global_position = Vector2(float(saved_position[0]), float(saved_position[1]))
	_anchor = global_position
	chain_root = self
	_configured = true
	var saved_lengths: Array = data.get("segment_lengths", [rope_length])
	if saved_lengths.is_empty():
		saved_lengths = [rope_length]
	rope_length = maxf(16.0, floorf(float(saved_lengths[0]) / 16.0) * 16.0)
	_rebuild_rope()
	var rope_scene := load(ROPE_SCENE_PATH) as PackedScene
	var next_y := bottom_y()
	for index in range(1, saved_lengths.size()):
		var piece := rope_scene.instantiate() as PlacedRope
		piece.configure(Vector2(global_position.x, next_y), float(saved_lengths[index]), self)
		get_parent().add_child(piece)
		next_y = piece.bottom_y()
	_refresh_chain_ends()

func _get_chain_members() -> Array[PlacedRope]:
	var members: Array[PlacedRope] = []
	var root := get_chain_root()
	for candidate in get_tree().get_nodes_in_group(&"placed_ropes"):
		if candidate is PlacedRope and candidate.get_chain_root() == root:
			members.append(candidate)
	return members

func _refresh_chain_ends() -> void:
	var final_piece: PlacedRope
	for candidate in _get_chain_members():
		if final_piece == null or candidate.bottom_y() > final_piece.bottom_y():
			final_piece = candidate
	for candidate in _get_chain_members():
		candidate._end_sprite.texture = END_TEXTURE if candidate == final_piece else SEGMENT_TEXTURE

func _rebuild_rope() -> void:
	for child in get_children():
		child.free()
	_build_rope()

func _build_rope() -> void:
	var middle_count := maxi(0, ceili((rope_length - 16.0) / 14.0))
	for index in middle_count:
		var sprite := Sprite2D.new()
		sprite.texture = SEGMENT_TEXTURE
		sprite.position = Vector2(0.0, index * 14.0 + 8.0)
		sprite.scale.x = 0.5
		add_child(sprite)
	_end_sprite = Sprite2D.new()
	_end_sprite.texture = END_TEXTURE
	_end_sprite.position = Vector2(0.0, rope_length - 8.0)
	_end_sprite.scale.x = 0.5
	add_child(_end_sprite)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24.0, rope_length)
	var collision := CollisionShape2D.new()
	collision.position = Vector2(0.0, rope_length * 0.5)
	collision.shape = shape
	add_child(collision)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("register_climbable"):
		body.register_climbable(self)

func _on_body_exited(body: Node2D) -> void:
	if body.has_method("unregister_climbable"):
		body.unregister_climbable(self)
