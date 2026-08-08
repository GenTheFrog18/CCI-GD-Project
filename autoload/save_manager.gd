extends Node

signal save_started
signal save_finished(success: bool)

const META_SAVE_VERSION := 1
const RUN_SAVE_VERSION := 4

var meta_path := "user://meta_save.json"
var run_path := "user://run_save.json"
var loaded_persistent_state: Dictionary = {}
var loaded_extra_state: Dictionary = {}
var destroyed_ids: Dictionary = {}

func _ready() -> void:
	GameSession.run_started.connect(_clear_run_state)

func save_meta() -> bool:
	var data := GameSession.capture_meta()
	data["version"] = META_SAVE_VERSION
	return _write_atomic(meta_path, data)

func load_meta() -> bool:
	var data := _read_valid(meta_path, META_SAVE_VERSION)
	if data.is_empty():
		return false
	GameSession.restore_meta(data)
	return true

func save_run(extra_state: Dictionary = {}) -> bool:
	save_started.emit()
	var persistent := loaded_persistent_state.duplicate(true)
	_capture_registered_objects(persistent)
	loaded_persistent_state = persistent.duplicate(true)
	var destroyed: Array[String] = []
	for id in destroyed_ids:
		destroyed.append(String(id))
	destroyed.sort()
	var data := {
		"version": RUN_SAVE_VERSION,
		"session": GameSession.capture_state(),
		"persistent_objects": persistent,
		"destroyed_ids": destroyed,
		"extra": extra_state.duplicate(true),
	}
	var success := _write_atomic(run_path, data)
	save_finished.emit(success)
	return success

func capture_registered_objects() -> void:
	_capture_registered_objects(loaded_persistent_state)

func _capture_registered_objects(persistent: Dictionary) -> void:
	var current_ids: Dictionary = {}
	for node in get_tree().get_nodes_in_group("persistent_objects"):
		if not node.has_method("capture_state") or node.get("persistent_id") == null:
			continue
		var id := String(node.persistent_id)
		if id.is_empty() or current_ids.has(id):
			push_error("Invalid or duplicate persistent ID: %s" % id)
			continue
		current_ids[id] = true
		if destroyed_ids.has(id):
			continue
		var state: Dictionary = node.capture_state()
		if not node.scene_file_path.is_empty():
			state["_scene_path"] = node.scene_file_path
		state["_layer_id"] = "" if id == "player" else String(GameSession.current_layer_id)
		persistent[id] = state

func load_run() -> Dictionary:
	var data := _read_valid(run_path, RUN_SAVE_VERSION)
	if data.is_empty():
		return {}
	GameSession.restore_state(data.get("session", {}))
	loaded_persistent_state = data.get("persistent_objects", {}).duplicate(true)
	loaded_extra_state = data.get("extra", {}).duplicate(true)
	destroyed_ids.clear()
	for id in data.get("destroyed_ids", []):
		destroyed_ids[String(id)] = true
	return data

func restore_registered_objects(layer_id: StringName = GameSession.current_layer_id) -> void:
	var existing: Dictionary = {}
	for node in get_tree().get_nodes_in_group("persistent_objects"):
		if not node.has_method("restore_state"):
			continue
		var id := String(node.get("persistent_id"))
		if destroyed_ids.has(id):
			node.queue_free()
			continue
		existing[id] = node
	for id in loaded_persistent_state:
		if destroyed_ids.has(id):
			continue
		var state: Dictionary = loaded_persistent_state[id]
		var saved_layer := StringName(state.get("_layer_id", ""))
		if not saved_layer.is_empty() and saved_layer != layer_id:
			continue
		if existing.has(id):
			existing[id].restore_state(state)
			continue
		var scene_path := String(state.get("_scene_path", ""))
		if not scene_path.begins_with("res://") or not ResourceLoader.exists(scene_path, "PackedScene"):
			continue
		var node := (load(scene_path) as PackedScene).instantiate()
		node.set("persistent_id", id)
		var root := get_tree().get_first_node_in_group("persistent_spawn_root")
		if root == null:
			root = get_tree().current_scene
		if root == null:
			node.free()
			continue
		root.add_child(node)
		node.restore_state(state)

func mark_destroyed(persistent_id: String) -> void:
	if not persistent_id.is_empty():
		destroyed_ids[persistent_id] = true

func has_valid_run() -> bool:
	return not _read_valid(run_path, RUN_SAVE_VERSION).is_empty()

func has_run_file() -> bool:
	return FileAccess.file_exists(run_path)

func delete_run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(run_path))

func _clear_run_state() -> void:
	loaded_persistent_state.clear()
	loaded_extra_state.clear()
	destroyed_ids.clear()

func _read_valid(path: String, expected_version: int) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var parsed = json.data
	if not parsed is Dictionary or int(parsed.get("version", -1)) != expected_version:
		return {}
	return parsed

func _write_atomic(path: String, data: Dictionary) -> bool:
	var temp_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	var absolute := ProjectSettings.globalize_path(path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	DirAccess.remove_absolute(backup_absolute)
	if FileAccess.file_exists(path):
		if DirAccess.rename_absolute(absolute, backup_absolute) != OK:
			DirAccess.remove_absolute(temp_absolute)
			return false
	if DirAccess.rename_absolute(temp_absolute, absolute) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_absolute, absolute)
		return false
	DirAccess.remove_absolute(backup_absolute)
	return true
