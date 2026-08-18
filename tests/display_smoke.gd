extends Node

func _ready() -> void:
	assert(ProjectSettings.get_setting("display/window/size/viewport_width") == 640)
	assert(ProjectSettings.get_setting("display/window/size/viewport_height") == 360)
	assert(ProjectSettings.get_setting("display/window/stretch/mode") == "disabled")
	assert(InputMap.has_action(&"toggle_fullscreen"))
	assert(GameSession.sanitize_windowed_size(Vector2i(1, 1)) == Vector2i(640, 360))
	assert(GameSession.get_windowed_size_options(Vector2i(1280, 720)).size() == 4)
	assert(Vector2i(1920, 1080) in GameSession.get_windowed_size_options())
	assert(Vector2i(1920, 1080) == Vector2i(640, 360) * 3)
	var design_root := Control.new()
	add_child(design_root)
	GameSession.configure_design_root(design_root)
	assert(design_root.size == GameSession.DESIGN_SIZE)
	assert(is_equal_approx(design_root.scale.x, GameSession.display_scale()))
	design_root.queue_free()
	var old_fullscreen := GameSession.fullscreen
	var old_size := GameSession.windowed_size
	GameSession.fullscreen = false
	GameSession.windowed_size = Vector2i(1280, 720)
	var meta := GameSession.capture_meta()
	assert(meta.windowed_size == [1280, 720])
	GameSession.restore_meta({"known_items": [], "item_use_counts": {}, "master_volume": 1.0, "fullscreen": false})
	assert(GameSession.windowed_size == GameSession.DEFAULT_WINDOWED_SIZE)
	GameSession.fullscreen = true
	GameSession.apply_settings()
	assert(not GameSession._applying_display)
	GameSession.fullscreen = false
	GameSession.apply_settings()
	var popup := preload("res://ui/settings_popup.tscn").instantiate() as SettingsPopup
	add_child(popup)
	await get_tree().process_frame
	popup._show_page(popup.screen_page, popup.fullscreen)
	assert(popup.resolution.item_count >= 2 and not popup.resolution.disabled)
	GameSession.fullscreen = true
	GameSession.display_settings_changed.emit()
	assert(popup.resolution.disabled and popup.fullscreen_hint.visible)
	popup.free()
	GameSession.fullscreen = old_fullscreen
	GameSession.windowed_size = old_size
	GameSession.apply_settings()
	GameSession.display_settings_changed.emit()
	print("DISPLAY_SMOKE_OK")
	get_tree().quit()
