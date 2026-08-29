extends Node

const LAYER_SCENE := preload("res://game/world/layers/layer_1.tscn")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const SECTION_SCENE := preload("res://game/world/sections/layer1/west/slot_01_a.tscn")
const BACKGROUND_ONE := preload("res://assets/art/world/background/layer1section1.png")
const BACKGROUND_TWO := preload("res://assets/art/world/background/layer1section2.png")

func _ready() -> void:
	var layer := LAYER_SCENE.instantiate() as WorldLayer
	add_child(layer)
	var first_slot := layer.get_node("Slots/West01") as WorldSlot
	var first_section := SECTION_SCENE.instantiate() as WorldSection
	first_slot.add_child(first_section)
	layer.instantiated_sections["layer1_west_01"] = first_section
	var player := PLAYER_SCENE.instantiate() as PlayerController
	layer.runtime_root.add_child(player)
	player.global_position = Vector2(640.0, 64.0)
	var background := layer.get_node("SectionBackground") as Layer1BackgroundController
	assert(background != null)
	background._player = player
	background._process(0.0)
	assert(background._active_depth == 0)
	assert(background._current.texture.resource_path == BACKGROUND_ONE.resource_path)

	background.fade_in_duration_seconds = 0.05
	player.global_position = Vector2(640.0, 790.0)
	player.velocity = Vector2(0.0, 100.0)
	background._process(0.0)
	assert(background._incoming.texture == BACKGROUND_TWO)

	var second_slot := layer.get_node("Slots/West02") as WorldSlot
	var second_section := SECTION_SCENE.instantiate() as WorldSection
	second_slot.add_child(second_section)
	layer.instantiated_sections["layer1_west_02"] = second_section
	player.global_position = Vector2(640.0, 810.0)
	background._commit_transition(1)
	assert(background._active_depth == 1)

	player.velocity = Vector2(0.0, -100.0)
	background._process(0.0)
	assert(background._incoming.texture == BACKGROUND_ONE)
	print("LAYER1_BACKGROUND_SMOKE_OK")
	get_tree().quit()
