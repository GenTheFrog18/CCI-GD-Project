extends Control

@export var dialogue_data: DialogueData

@onready var dialogue_box: Control = $DialogueBox
@onready var fade: ColorRect = $PrologueOverlay/Fade
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	fade.modulate.a = 1.0

	dialogue_box.dialogue_finished.connect(_on_dialogue_finished)

	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 1.5)

	tween.finished.connect(_start_prologue)


func _start_prologue() -> void:
	dialogue_box.start_dialogue(dialogue_data, self, null)


func _on_dialogue_finished() -> void:
	print("Prologue dialogue selesai!")

	await get_tree().create_timer(0.5).timeout

	await _fade_to_black()

	_go_to_surface_town()


func _fade_to_black() -> void:
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.5)

	await tween.finished


func _go_to_surface_town() -> void:
	get_tree().change_scene_to_file("res://game/world/layers/surface.tscn")
