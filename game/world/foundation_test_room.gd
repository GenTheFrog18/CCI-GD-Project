extends Node2D

@onready var player: PlayerController = $Player
@onready var hud: FoundationHUD = $FoundationHUD
@onready var turret: ProjectileTurret = $ProjectileTurret

func _ready() -> void:
	turret.target = player
	hud.set_player(player)
	var intro := ContentCatalog.get_dialogue(&"foundation_intro")
	if intro != null and SaveManager.loaded_persistent_state.is_empty():
		hud.show_dialogue(intro)
	call_deferred("_restore_loaded_state")

func _restore_loaded_state() -> void:
	SaveManager.restore_registered_objects()
