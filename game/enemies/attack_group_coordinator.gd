class_name AttackGroupCoordinator
extends Node

var group_id: StringName
var maximum_attackers := 1
var attack_spacing := 0.8
var alert_position := Vector2.ZERO
var alert_remaining := 0.0
var _active_attackers: Dictionary = {}
var _spacing_remaining := 0.0

static func find_or_create(parent: Node, id: StringName, max_attackers := 1, spacing := 0.8) -> AttackGroupCoordinator:
	for child in parent.get_children():
		if child is AttackGroupCoordinator and child.group_id == id:
			return child
	var coordinator := AttackGroupCoordinator.new()
	coordinator.name = "AttackGroup_%s" % id
	coordinator.group_id = id
	coordinator.maximum_attackers = max_attackers
	coordinator.attack_spacing = spacing
	parent.add_child(coordinator)
	return coordinator

func _process(delta: float) -> void:
	_spacing_remaining = maxf(0.0, _spacing_remaining - delta)
	alert_remaining = maxf(0.0, alert_remaining - delta)
	for id in _active_attackers.keys():
		if not is_instance_id_valid(int(id)):
			_active_attackers.erase(id)

func broadcast_alert(position: Vector2, duration: float) -> void:
	alert_position = position
	alert_remaining = maxf(alert_remaining, duration)

func has_alert() -> bool:
	return alert_remaining > 0.0

func request_attack(member: Node) -> bool:
	if member == null or _spacing_remaining > 0.0 or _active_attackers.size() >= maximum_attackers:
		return false
	_active_attackers[member.get_instance_id()] = true
	_spacing_remaining = attack_spacing
	return true

func release_attack(member: Node) -> void:
	if member != null:
		_active_attackers.erase(member.get_instance_id())
