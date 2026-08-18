extends Node

func _ready() -> void:
	var theme := ThemeDB.get_project_theme()
	assert(theme.default_font != null)
	var body := theme.default_font as FontFile
	assert(body.resource_path.ends_with("Perfect DOS VGA 437.ttf"))
	assert(body.multichannel_signed_distance_field)
	assert(body.has_char(ord("×")))
	assert(theme.has_type_variation(&"PixelHeading"))
	var heading := theme.get_font(&"font", &"PixelHeading") as FontFile
	assert(heading == body)
	assert(theme.get_font_size(&"font_size", &"PixelHeading") == 18)
	var label := Label.new()
	label.theme_type_variation = &"PixelHeading"
	add_child(label)
	assert(label.get_theme_font().resource_path.ends_with("Perfect DOS VGA 437.ttf"))
	assert(label.get_theme_font_size() == 18)
	label.queue_free()
	print("FONT_SMOKE_OK")
	get_tree().quit()
