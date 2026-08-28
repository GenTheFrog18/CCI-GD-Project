class_name EndScreen
extends CanvasLayer

@export var message_label_path: NodePath = ^"LogicalUI/Panel/Column/Message"

@onready var logical_ui: Control = $LogicalUI

func _ready() -> void:
	GameSession.configure_design_root(logical_ui)
	GameSession.display_settings_changed.connect(func(): GameSession.configure_design_root(logical_ui))

func set_completion_message(message: String) -> void:
	var message_label := get_node_or_null(message_label_path) as Label
	if message_label != null:
		message_label.text = message
