extends Control

@export var fade_seconds := 1.5
@export var dialogue_sequence: DialogueSequence

@onready var fade: ColorRect = $PrologueOverlay/Fade

var dialogue_box: DialogueBox

func _ready() -> void:
	dialogue_box = DialogueBox.new()
	dialogue_box.position = Vector2(60, 245)
	add_child(dialogue_box)
	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)
	fade.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, fade_seconds)
	await tween.finished
	dialogue_box.show_sequence(dialogue_sequence)

func _on_dialogue_finished() -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, fade_seconds)
	await tween.finished
	SceneRouter.go_to("res://game/world/world_run.tscn")
