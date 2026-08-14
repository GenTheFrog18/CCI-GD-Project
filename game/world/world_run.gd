class_name WorldRun
extends Node2D

const PLAYER_SCENE := preload("res://game/player/player.tscn")

@export var surface_scene: PackedScene
@export var layer_1_scene: PackedScene
@export var layer_2_scene: PackedScene

@onready var layer_host: Node2D = $LayerHost
@onready var generator: WorldGenerator = $WorldGenerator
@onready var loading_layer: CanvasLayer = $LoadingLayer
@onready var loading_label: Label = $LoadingLayer/Panel/Column/LoadingLabel
@onready var progress_bar: ProgressBar = $LoadingLayer/Panel/Column/ProgressBar

var active_layer: WorldLayer
var player: PlayerController
var hud: FoundationHUD
var _transitioning := false
var _activation_elapsed := 0.0
var _show_bounds := false
var _debug_draw: WorldDebugDraw
var _last_slot_id: StringName

func _ready() -> void:
	generator.layer_scenes = [layer_1_scene, layer_2_scene]
	generator.generation_started.connect(func(total: int): progress_bar.max_value = total; progress_bar.value = 0)
	generator.generation_progress.connect(_on_generation_progress)
	_debug_draw = WorldDebugDraw.new()
	add_child(_debug_draw)
	await _prepare_run()

func _process(delta: float) -> void:
	if active_layer == null or player == null or _transitioning:
		return
	_activation_elapsed += delta
	if _activation_elapsed < 0.2:
		return
	_activation_elapsed = 0.0
	var section := active_layer.section_at(player.global_position)
	var slot := active_layer.slot_for_section(section)
	if slot != null:
		GameSession.current_slot_id = slot.slot_id
		GameSession.current_route_id = StringName(slot.route_id)
		if _last_slot_id != slot.slot_id:
			_last_slot_id = slot.slot_id
			player.set_last_safe_position(section.respawn_anchor.global_position)
		active_layer.update_activation(player.global_position)
		player.set_camera_bounds(active_layer.camera_bounds_for(section))
		if hud != null:
			hud.set_world_debug_text(_world_debug_text())
	elif hud != null:
		GameSession.current_slot_id = &""
		hud.set_world_debug_text(_world_debug_text())
	if not active_layer.world_bounds.grow(96.0).has_point(player.global_position):
		player.recover_from_out_of_bounds()
	for child in active_layer.runtime_root.get_children():
		if child == player or not child is Node2D:
			continue
		if not active_layer.world_bounds.grow(96.0).has_point(child.global_position) and child.has_method("handle_world_out_of_bounds"):
			child.handle_world_out_of_bounds()
	_update_debug_draw()

func request_layer_transition(target_layer_id: StringName, target_route_id: StringName, target_spawn_id: StringName = &"") -> void:
	if _transitioning or target_layer_id.is_empty():
		return
	_transitioning = true
	loading_layer.visible = true
	loading_label.text = "Saving current layer..."
	if player != null:
		player.locks.lock(&"world_transition")
	SaveManager.capture_registered_objects()
	await get_tree().process_frame
	GameSession.current_layer_id = target_layer_id
	GameSession.current_route_id = target_route_id
	await _load_active_layer(true, target_spawn_id)
	SaveManager.save_run()
	_transitioning = false

func finish_run() -> void:
	if _transitioning:
		return
	_transitioning = true
	GameSession.progression_flags["reached_layer_3_entrance"] = true
	SaveManager.save_run()
	loading_layer.visible = true
	loading_label.text = "Prototype Complete\nLayer 3 entrance reached."
	progress_bar.visible = false
	await get_tree().create_timer(1.5).timeout
	SceneRouter.go_to("res://ui/main_menu.tscn")

func _prepare_run() -> void:
	loading_layer.visible = true
	if GameSession.world_manifest.is_empty():
		loading_label.text = "Preparing world..."
		var manifest := await generator.build_manifest(GameSession.run_seed)
		var errors: PackedStringArray = manifest.get("errors", PackedStringArray())
		if not errors.is_empty():
			loading_label.text = "World generation failed:\n%s" % "\n".join(errors)
			push_error(loading_label.text)
			return
		GameSession.world_manifest = manifest
		GameSession.world_generation_log.assign(manifest.get("generation_log", []))
	else:
		var manifest_errors := generator.validate_manifest(GameSession.world_manifest)
		if not manifest_errors.is_empty():
			loading_label.text = "Saved world is incompatible:\n%s" % "\n".join(manifest_errors)
			return
	await _load_active_layer(false)
	SaveManager.save_run()

func _load_active_layer(is_transition: bool, target_spawn_id: StringName = &"") -> void:
	var stage_started := Time.get_ticks_usec()
	loading_layer.visible = true
	progress_bar.visible = true
	progress_bar.max_value = 4
	progress_bar.value = 0
	loading_label.text = "Instantiating %s..." % GameSession.current_layer_id
	if is_instance_valid(hud):
		hud.queue_free()
	if is_instance_valid(active_layer):
		active_layer.queue_free()
	await get_tree().process_frame
	var scene := _scene_for_layer(GameSession.current_layer_id)
	if scene == null:
		loading_label.text = "Missing layer scene: %s" % GameSession.current_layer_id
		return
	active_layer = scene.instantiate() as WorldLayer
	if active_layer == null:
		loading_label.text = "Layer root is invalid"
		return
	layer_host.add_child(active_layer)
	_last_slot_id = &""
	progress_bar.value = 1
	_append_runtime_stage("Instantiate %s" % GameSession.current_layer_id, stage_started)
	stage_started = Time.get_ticks_usec()
	active_layer.runtime_root.add_to_group(&"persistent_spawn_root")
	if GameSession.current_layer_id != &"surface":
		var errors := active_layer.instantiate_manifest(GameSession.world_manifest)
		if not errors.is_empty():
			loading_label.text = "Layer assembly failed:\n%s" % "\n".join(errors)
			return
	progress_bar.value = 2
	_append_runtime_stage("Assemble sections and placers", stage_started)
	stage_started = Time.get_ticks_usec()
	loading_label.text = "Restoring run..."
	player = PLAYER_SCENE.instantiate() as PlayerController
	active_layer.runtime_root.add_child(player)
	SaveManager.restore_registered_objects(GameSession.current_layer_id)
	progress_bar.value = 3
	_append_runtime_stage("Restore persistent state", stage_started)
	stage_started = Time.get_ticks_usec()
	if is_transition or SaveManager.loaded_persistent_state.is_empty():
		player.global_position = active_layer.spawn_position(GameSession.current_route_id, target_spawn_id)
		player.set_last_safe_position(player.global_position)
		player.curse_tracker.reset_reference(true)
	hud = FoundationHUD.new()
	add_child(hud)
	hud.set_player(player)
	hud.world_debug_action_requested.connect(_on_debug_action)
	hud.set_world_generation_log(GameSession.world_generation_log, GameSession.world_manifest)
	active_layer.update_activation(player.global_position)
	var section := active_layer.section_at(player.global_position)
	player.set_camera_bounds(active_layer.camera_bounds_for(section))
	progress_bar.value = 4
	_append_runtime_stage("Spawn player and activate sections", stage_started)
	hud.set_world_generation_log(GameSession.world_generation_log, GameSession.world_manifest)
	loading_label.text = "Ready"
	await get_tree().process_frame
	loading_layer.visible = false

func _scene_for_layer(layer_id: StringName) -> PackedScene:
	match layer_id:
		&"surface": return surface_scene
		&"layer_1": return layer_1_scene
		&"layer_2": return layer_2_scene
	return null

func _on_generation_progress(stage: String, completed: int, total: int) -> void:
	loading_label.text = stage
	progress_bar.max_value = total
	progress_bar.value = completed

func _append_runtime_stage(stage: String, started_usec: int) -> void:
	GameSession.world_generation_log.append({
		"stage": stage,
		"duration_ms": float(Time.get_ticks_usec() - started_usec) / 1000.0,
	})

func _world_debug_text() -> String:
	return "Layer: %s  Route: %s  Slot: %s\nActive: %s" % [
		GameSession.current_layer_id,
		GameSession.current_route_id,
		GameSession.current_slot_id,
		", ".join(active_layer.active_slot_ids),
	]

func _on_debug_action(action: StringName) -> void:
	match action:
		&"toggle_bounds":
			_show_bounds = not _show_bounds
		&"validate_world":
			var errors := generator.validate_manifest(GameSession.world_manifest)
			errors.append_array(generator.validate_templates())
			hud.set_world_debug_text("World valid" if errors.is_empty() else "\n".join(errors))
		&"dump_manifest":
			print(JSON.stringify(GameSession.world_manifest, "  "))
		&"teleport_next":
			_teleport_next_slot()
		&"teleport_shop":
			_debug_teleport(&"layer_2", &"east", Vector2(2280.0, 1190.0))
		&"teleport_ending":
			_debug_teleport(&"layer_2", &"east", Vector2(1920.0, 2260.0))
		&"teleport_surface":
			_debug_teleport(&"surface", &"west", Vector2(150.0, 320.0))
		&"curse_reset":
			player.curse_tracker.reset_reference(false)
		&"curse_clear":
			for id in player.status.active.keys(): player.status.remove_status(id)
		&"curse_heal":
			player.apply_status(&"healing", {"duration": 10.0})
		&"curse_apply":
			player.curse_tracker.apply_current_layer_curse()

func _teleport_next_slot() -> void:
	if active_layer == null or player == null:
		return
	var slots := active_layer.get_slots()
	if slots.is_empty():
		return
	var current_index := -1
	for index in slots.size():
		if slots[index].slot_id == GameSession.current_slot_id:
			current_index = index
	var next_slot := slots[(current_index + 1) % slots.size()]
	player.global_position = next_slot.global_position + Vector2(640.0, 80.0)
	player.set_last_safe_position(player.global_position)

func _debug_teleport(layer_id: StringName, route_id: StringName, position: Vector2) -> void:
	if GameSession.current_layer_id != layer_id:
		await request_layer_transition(layer_id, route_id)
	if player != null:
		player.global_position = position
		player.set_last_safe_position(position)
		player.curse_tracker.reset_reference(true)

func _update_debug_draw() -> void:
	if _debug_draw != null:
		_debug_draw.refresh(active_layer, _show_bounds)
