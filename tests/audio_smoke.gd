extends Node

func _ready() -> void:
	var streams: Array[AudioStream] = [
		AudioManager.BANDAGE_USE,
		AudioManager.BOLT_SHOCK_ARMED,
		AudioManager.BOLT_SHOCK_FIRE,
		AudioManager.ITEM_DROPPED,
		AudioManager.LACERATOR_ARMED,
		AudioManager.LACERATOR_FIRE,
		AudioManager.PLATE_UMBRELLA_OPENED,
		AudioManager.RATTLEPOD_RATTLING,
		AudioManager.RESONANCE_CORE_HUM,
		AudioManager.PLAYER_CLICK,
		AudioManager.PLAYER_HIT_GROUND,
		AudioManager.PLAYER_HURT,
		AudioManager.PLAYER_THROW,
		AudioManager.PLAYER_WARNING,
		AudioManager.WHISTLE,
	]
	for stream in streams:
		assert(stream != null)

	var sfx_player := AudioManager.play_sfx(AudioManager.BANDAGE_USE)
	assert(sfx_player != null and sfx_player.bus == &"SFX")
	var ui_player := AudioManager.play_ui(AudioManager.PLAYER_CLICK)
	assert(ui_player != null and ui_player.bus == &"UI")
	for _index in 8:
		var attack_player := AudioManager.play_player_attack()
		assert(attack_player.stream in AudioManager.PLAYER_ATTACK_VARIANTS)
		attack_player.queue_free()

	var owner := Node.new()
	add_child(owner)
	var loop_player := AudioManager.start_loop(owner, AudioManager.RATTLEPOD_RATTLING)
	assert(loop_player != null and loop_player.bus == &"SFX")
	assert((loop_player.stream as AudioStreamOggVorbis).loop)
	AudioManager.stop_loop(owner)
	assert(AudioManager._loops.is_empty())

	GameSession.master_volume = 0.4
	GameSession.apply_settings()
	var master_index := AudioServer.get_bus_index(&"Master")
	assert(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(master_index)), 0.4))
	print("AUDIO_SMOKE_OK")
	get_tree().quit()
