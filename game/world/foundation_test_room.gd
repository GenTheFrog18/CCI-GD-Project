extends Node2D

@export_enum("None", "Layer 1", "Layer 2") var test_curse_layer := "None"

@onready var player: PlayerController = $Player
@onready var hud: FoundationHUD = $FoundationHUD
var _debug_draw: WorldDebugDraw

func _ready() -> void:
	_debug_draw = WorldDebugDraw.new()
	add_child(_debug_draw)
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

func _process(_delta: float) -> void:
	if _debug_draw != null:
		_debug_draw.refresh(self, GameSession.debug_gameplay_draw)
