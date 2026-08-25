extends Node2D

@export_enum("None", "Layer 1", "Layer 2") var test_curse_layer := "None"

@onready var player: PlayerController = $Player
@onready var hud: FoundationHUD = $FoundationHUD

func _ready() -> void:
	hud.set_player(player)
	if test_curse_layer != "None":
		player.curse_tracker.apply_layer_curse(StringName(test_curse_layer.replace(" ", "_").to_lower()))
	call_deferred("_restore_loaded_state")

func _restore_loaded_state() -> void:
	SaveManager.restore_registered_objects()
