extends CanvasLayer

var _overlay: ColorRect
var _changing := false

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.modulate.a = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

func go_to(scene_path: String) -> void:
	if _changing or not ResourceLoader.exists(scene_path):
		return
	_changing = true
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.12)
	await tween.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	var fade_in := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_in.tween_property(_overlay, "modulate:a", 0.0, 0.12)
	await fade_in.finished
	_changing = false
