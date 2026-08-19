class_name SoundListener
extends Node2D

signal sound_accepted(event: SoundEvent, direct_target: bool)
signal sound_target_lost

@export var minimum_priority := 0
@export var ignored_sound_types: Array[StringName] = []
@export_range(1, 20, 1) var escalation_count := 3
@export var escalation_window := 2.0
@export var target_timeout := 10.0
@export var search_seconds := 1.0

var current_event: SoundEvent
var direct_target := false
var _accepted_times: Dictionary = {}
var _debug_was_visible := false

func _ready() -> void:
	add_to_group(&"sound_listeners")

func _process(_delta: float) -> void:
	if GameSession.debug_gameplay_draw or _debug_was_visible:
		_debug_was_visible = GameSession.debug_gameplay_draw
		queue_redraw()
	if current_event == null:
		return
	var age := (Time.get_ticks_msec() - current_event.timestamp) / 1000.0
	var listener := get_parent() as Node2D
	var source_out_of_range := is_instance_valid(current_event.source) and current_event.source is Node2D and listener != null \
		and listener.global_position.distance_to(current_event.position) > current_event.radius
	if age > target_timeout or source_out_of_range:
		clear_target()

func hear_sound(event: SoundEvent) -> void:
	var listener := get_parent() as Node2D
	if event == null or listener == null or event.priority < minimum_priority or event.sound_type in ignored_sound_types:
		return
	var owner_status := _owner_status()
	if owner_status != null and owner_status.get_multiplier(&"sound_enabled") <= 0.0:
		clear_target()
		return
	if is_instance_valid(event.source) and event.source.has_method("is_combat_protected") and event.source.is_combat_protected():
		return
	if listener.global_position.distance_to(event.position) > event.radius:
		return
	var same_direct_source := direct_target and current_event != null and event.source == current_event.source
	if not same_direct_source and not _is_better(event, listener.global_position):
		return
	_register_event(event)
	current_event = event
	direct_target = same_direct_source or _source_event_count(event.source) >= escalation_count
	sound_accepted.emit(event, direct_target)
	queue_redraw()

func clear_target() -> void:
	if current_event == null:
		return
	current_event = null
	direct_target = false
	sound_target_lost.emit()
	queue_redraw()

func _is_better(event: SoundEvent, listener_position: Vector2) -> bool:
	if current_event == null:
		return true
	if event.priority != current_event.priority:
		return event.priority > current_event.priority
	if event.timestamp != current_event.timestamp:
		return event.timestamp > current_event.timestamp
	return listener_position.distance_to(event.position) < listener_position.distance_to(current_event.position)

func _register_event(event: SoundEvent) -> void:
	var source_id := event.source.get_instance_id() if is_instance_valid(event.source) else 0
	var cutoff := event.timestamp - int(escalation_window * 1000.0)
	var recent: Array = _accepted_times.get(source_id, [])
	recent = recent.filter(func(timestamp: int): return timestamp >= cutoff)
	recent.append(event.timestamp)
	_accepted_times[source_id] = recent

func _source_event_count(source: Node) -> int:
	var source_id := source.get_instance_id() if is_instance_valid(source) else 0
	return (_accepted_times.get(source_id, []) as Array).size()

func _owner_status() -> StatusController:
	var actor := get_parent()
	var value = actor.get("status") if actor != null else null
	if value is StatusController:
		return value
	var support := actor.get_node_or_null("EnemySupport") as EnemySupport if actor != null else null
	return support.status if support != null else null

func _draw() -> void:
	if GameSession.debug_gameplay_draw and current_event != null:
		draw_arc(to_local(current_event.position), current_event.radius, 0.0, TAU, 48, Color(0.3, 0.75, 1.0, 0.55), 1.0)
