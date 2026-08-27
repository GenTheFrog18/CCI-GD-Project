extends Control

const DIALOGUE_BOX_SCENE := preload("res://ui/dialogue_box.tscn")

@export var fade_seconds := 1.5
@export var dialogue_sequence: DialogueSequence

@onready var fade: ColorRect = $PrologueOverlay/Fade
@onready var design_ui: Control = $DesignUI

var dialogue_box: DialogueBox
var dialogue_controller: DialogueController
var menu_cursor: Sprite2D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	GameSession.use_menu_cursor()
	GameSession.configure_design_root(design_ui)
	GameSession.display_settings_changed.connect(func(): GameSession.configure_design_root(design_ui))
	dialogue_box = DIALOGUE_BOX_SCENE.instantiate() as DialogueBox
	dialogue_box.position = Vector2(60, 245)
	design_ui.add_child(dialogue_box)
	dialogue_controller = DialogueController.new()
	design_ui.add_child(dialogue_controller)
	dialogue_controller.setup(dialogue_box)
	menu_cursor = Sprite2D.new()
	menu_cursor.texture = GameSession.MENU_CURSOR
	menu_cursor.centered = false
	menu_cursor.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	menu_cursor.z_index = 1000
	design_ui.add_child(menu_cursor)
	dialogue_controller.sequence_finished.connect(_on_dialogue_finished)
	fade.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, fade_seconds)
	await tween.finished
	dialogue_controller.start_sequence(dialogue_sequence)

func _process(_delta: float) -> void:
	if menu_cursor != null:
		menu_cursor.position = GameSession.screen_to_design(get_viewport().get_mouse_position())

func _on_dialogue_finished() -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, fade_seconds)
	await tween.finished
	SceneRouter.go_to("res://game/world/world_run.tscn")
