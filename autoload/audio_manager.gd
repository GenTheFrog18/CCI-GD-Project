extends Node

const BANDAGE_USE := preload("res://assets/audio/Items/bandage-use.ogg")
const BOLT_SHOCK_ARMED := preload("res://assets/audio/Items/bolt-shock-armed.ogg")
const BOLT_SHOCK_FIRE := preload("res://assets/audio/Items/bolt-shock-fire.ogg")
const ITEM_DROPPED := preload("res://assets/audio/Items/item-dropped.ogg")
const LACERATOR_ARMED := preload("res://assets/audio/Items/lacerator-armed.ogg")
const LACERATOR_FIRE := preload("res://assets/audio/Items/lacerator-fire.ogg")
const PLATE_UMBRELLA_OPENED := preload("res://assets/audio/Items/plate-umbrella-opened.ogg")
const RATTLEPOD_RATTLING := preload("res://assets/audio/Items/rattlepod-rattling.ogg")
const RESONANCE_CORE_HUM := preload("res://assets/audio/Items/resonance-core-hum.ogg")
const PLAYER_ATTACK_VARIANTS: Array[AudioStream] = [
	preload("res://assets/audio/Player/attack-1.ogg"),
	preload("res://assets/audio/Player/attack-2.ogg"),
]
const PLAYER_CLICK := preload("res://assets/audio/Player/click-button.ogg")
const PLAYER_HIT_GROUND := preload("res://assets/audio/Player/hit-ground.ogg")
const PLAYER_HURT := preload("res://assets/audio/Player/hurt.ogg")
const PLAYER_THROW := preload("res://assets/audio/Player/throw.ogg")
const PLAYER_WARNING := preload("res://assets/audio/Player/warning-enemy.ogg")
const WHISTLE := preload("res://assets/audio/whistle/whistle.ogg")

const SFX_BUS := &"SFX"
const UI_BUS := &"UI"
const BUTTON_WIRED_META := &"audio_manager_button_wired"

var _loops: Dictionary = {}

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	call_deferred(&"_wire_existing_buttons")

func _process(_delta: float) -> void:
	for owner_id in _loops.keys().duplicate():
		var entry: Dictionary = _loops[owner_id]
		var owner: Variant = entry.get("owner")
		if is_instance_valid(owner) and (not owner is Node or (owner as Node).is_inside_tree()):
			continue
		_stop_loop_by_id(int(owner_id), entry.get("player") as AudioStreamPlayer)

func play_sfx(stream: AudioStream) -> AudioStreamPlayer:
	return _play(stream, SFX_BUS)

func play_ui(stream: AudioStream) -> AudioStreamPlayer:
	return _play(stream, UI_BUS)

func play_bandage_use() -> void:
	play_sfx(BANDAGE_USE)

func play_bolt_shock_armed() -> void:
	play_sfx(BOLT_SHOCK_ARMED)

func play_bolt_shock_fire() -> void:
	play_sfx(BOLT_SHOCK_FIRE)

func play_item_dropped() -> void:
	play_sfx(ITEM_DROPPED)

func play_lacerator_armed() -> void:
	play_sfx(LACERATOR_ARMED)

func play_lacerator_fire() -> void:
	play_sfx(LACERATOR_FIRE)

func play_plate_umbrella_opened() -> void:
	play_sfx(PLATE_UMBRELLA_OPENED)

func play_player_attack() -> AudioStreamPlayer:
	return play_sfx(PLAYER_ATTACK_VARIANTS[randi_range(0, PLAYER_ATTACK_VARIANTS.size() - 1)])

func play_player_hit_ground() -> void:
	play_sfx(PLAYER_HIT_GROUND)

func play_player_hurt() -> void:
	play_sfx(PLAYER_HURT)

func play_player_throw() -> void:
	play_sfx(PLAYER_THROW)

func play_player_warning() -> void:
	play_sfx(PLAYER_WARNING)

func play_whistle() -> void:
	play_sfx(WHISTLE)

func start_loop(owner: Object, stream: AudioStream, bus: StringName = SFX_BUS) -> AudioStreamPlayer:
	if not is_instance_valid(owner) or stream == null:
		return null
	stop_loop(owner)
	var player := AudioStreamPlayer.new()
	player.stream = _loop_stream(stream)
	player.bus = bus
	add_child(player)
	player.play()
	_loops[owner.get_instance_id()] = {"owner": owner, "player": player}
	return player

func stop_loop(owner: Object) -> void:
	if not is_instance_valid(owner):
		return
	var owner_id := owner.get_instance_id()
	if not _loops.has(owner_id):
		return
	var entry: Dictionary = _loops[owner_id]
	_stop_loop_by_id(owner_id, entry.player as AudioStreamPlayer)

func _play(stream: AudioStream, bus: StringName) -> AudioStreamPlayer:
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player

func _loop_stream(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate() as AudioStream
	if copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	return copy

func _stop_loop_by_id(owner_id: int, player: AudioStreamPlayer) -> void:
	_loops.erase(owner_id)
	if is_instance_valid(player):
		player.stop()
		player.queue_free()

func _wire_existing_buttons() -> void:
	_wire_buttons(get_tree().root)

func _wire_buttons(node: Node) -> void:
	if node is BaseButton:
		_wire_button(node as BaseButton)
	for child in node.get_children():
		_wire_buttons(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_wire_button(node as BaseButton)

func _wire_button(button: BaseButton) -> void:
	if button.get_meta(BUTTON_WIRED_META, false):
		return
	button.set_meta(BUTTON_WIRED_META, true)
	button.pressed.connect(func(): play_ui(PLAYER_CLICK))
