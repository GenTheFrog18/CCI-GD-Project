extends Node2D

@export_enum("None", "Layer 1", "Layer 2") var test_curse_layer := "None"

@onready var player: PlayerController = $Player
@onready var hud: FoundationHUD = $FoundationHUD

func _ready() -> void:
	hud.set_player(player)
	if test_curse_layer != "None":
		player.curse_tracker.apply_layer_curse(StringName(test_curse_layer.replace(" ", "_").to_lower()))
	call_deferred("_prepare_test_room")

func _prepare_test_room() -> void:
	for node in find_children("*", "DeterministicPlacer", true, false):
		var placer := node as DeterministicPlacer
		if placer == null:
			continue
		for error in placer.validate():
			push_error(error)
		placer.resolve(GameSession.run_seed)
		placer.spawn_resolved(self)
	SaveManager.restore_registered_objects()
