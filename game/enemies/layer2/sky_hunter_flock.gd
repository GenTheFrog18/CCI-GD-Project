class_name SkyHunterFlock
extends Node2D

const MEMBER_SCENE := preload("res://game/enemies/layer2/sky_hunter.tscn")

@export var persistent_id := "layer_2_sky_hunter_flock"
@export_range(1, 8, 1) var starting_member_count := 3
@export var maximum_simultaneous_attackers := 1
@export var minimum_group_attack_spacing := 0.9
@export var spawn_spacing := 56.0

var _coordinator: AttackGroupCoordinator
var _dead_member_ids: Array[String] = []

func _ready() -> void:
	add_to_group(&"persistent_objects")
	add_to_group(&"layer_global_actor")
	add_to_group(&"sky_hunter_flock")
	_coordinator = AttackGroupCoordinator.find_or_create(self, &"sky_hunter_flock", maximum_simultaneous_attackers, minimum_group_attack_spacing)
	if _living_members().is_empty():
		for index in starting_member_count:
			_spawn_member("sky_hunter_%d" % index, global_position + Vector2((index - (starting_member_count - 1) * 0.5) * spawn_spacing, -20.0))
	process_mode = Node.PROCESS_MODE_INHERIT if bool(GameSession.progression_flags.get("layer_2_sky_hunter_active", false)) else Node.PROCESS_MODE_DISABLED

func activate_near(player_position: Vector2) -> void:
	GameSession.progression_flags["layer_2_sky_hunter_active"] = true
	var route_x := 1920.0 if player_position.x >= 1280.0 else 640.0
	if absf(global_position.x - route_x) > 800.0:
		global_position.x = route_x
	process_mode = Node.PROCESS_MODE_INHERIT

func _spawn_member(id: String, position: Vector2, state_data: Dictionary = {}) -> SkyHunter:
	if id in _dead_member_ids:
		return null
	var member := MEMBER_SCENE.instantiate() as SkyHunter
	add_child(member)
	member.global_position = position
	member.setup(self, _coordinator, id)
	if not state_data.is_empty():
		member.restore_state(state_data)
	return member

func notify_member_died(id: String) -> void:
	if not id.is_empty() and id not in _dead_member_ids:
		_dead_member_ids.append(id)

func capture_state() -> Dictionary:
	var members: Dictionary = {}
	for member in _living_members():
		members[member.member_id] = member.capture_state()
	return {"dead_member_ids": _dead_member_ids.duplicate(), "members": members}

func restore_state(data: Dictionary) -> void:
	_dead_member_ids.assign(data.get("dead_member_ids", []))
	for member in _living_members():
		member.queue_free()
	var members: Dictionary = data.get("members", {})
	for id in members:
		var state_data: Dictionary = members[id]
		var position_data: Array = state_data.get("position", [global_position.x, global_position.y])
		_spawn_member(String(id), Vector2(float(position_data[0]), float(position_data[1])), state_data)

func _living_members() -> Array[SkyHunter]:
	var result: Array[SkyHunter] = []
	for child in get_children():
		if child is SkyHunter and not child.is_queued_for_deletion():
			result.append(child)
	return result
