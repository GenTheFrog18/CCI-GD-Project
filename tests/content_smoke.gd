extends Node

class ReceiverProbe:
	extends Node2D
	var damage := 0.0
	var effects: Array[StringName] = []
	func apply_damage(info: DamageInfo) -> bool:
		damage += info.amount
		return true
	func apply_status(id: StringName, _data: Dictionary = {}) -> bool:
		effects.append(id)
		return true

var failures := PackedStringArray()

func _ready() -> void:
	_check(ContentCatalog.rebuild().is_empty(), "content catalog validates")
	_test_catalog()
	_test_enemy_scenes()
	_test_effects_and_curse()
	_test_player_item_regressions()
	await _test_item_impacts()
	_test_flyer_transfer()
	await get_tree().process_frame
	if failures.is_empty():
		print("CONTENT_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)

func _test_catalog() -> void:
	for id in [&"tongue_amphibian", &"knockback_bird", &"thorn_bloom", &"lantern_snail", &"cave_spider", &"large_layer1_flyer", &"senior_diver"]:
		_check(ContentCatalog.get_enemy(id) != null, "enemy missing: %s" % id)
	for id in [&"bandage", &"info_book", &"numbing_pill", &"sun_sphere", &"lantern_crystal", &"rattlepod", &"hushcap", &"cling_resin", &"driftseed", &"silver_weight"]:
		_check(ContentCatalog.get_item(id) != null, "item missing: %s" % id)
	for id in [&"sun_sphere", &"lantern_crystal", &"rattlepod", &"hushcap", &"cling_resin", &"driftseed", &"silver_weight"]:
		_check(ContentCatalog.get_item(id).icon != null, "finished item art missing: %s" % id)
	for id in [&"bleed", &"poison", &"resin_bound", &"tracking_mark", &"curse_layer_1", &"curse_layer_2_penalty", &"curse_layer_2_health_cap"]:
		_check(ContentCatalog.get_effect(id) != null, "effect missing: %s" % id)

func _test_enemy_scenes() -> void:
	var direct_flyer := LargeLayer1Flyer.new()
	_check(direct_flyer.has_method("restore_state"), "large flyer script class compiles")
	direct_flyer.free()
	var spider := preload("res://game/enemies/layer1/cave_spider.tscn").instantiate() as CaveSpider
	add_child(spider)
	_check(spider.sprite.sprite_frames.has_animation(&"walk") and spider.sprite.sprite_frames.has_animation(&"shoot"), "Cave Spider finished animations missing")
	spider.free()
	for id: StringName in ContentCatalog.enemies:
		var definition := ContentCatalog.get_enemy(id)
		var enemy := definition.scene.instantiate() as CollisionObject2D
		add_child(enemy)
		_check(enemy.has_method("restore_state"), "%s scene root script is missing persistence contract" % id)
		_check(enemy != null and enemy.collision_layer & 4 != 0, "%s must use Enemy collision layer" % id)
		for tag in definition.tags:
			_check(enemy.is_in_group(tag), "%s missing runtime tag %s" % [id, tag])
		enemy.free()
	var frog := preload("res://game/enemies/layer1/tongue_amphibian.tscn").instantiate() as TongueAmphibian
	var target := Node2D.new()
	add_child(frog)
	add_child(target)
	target.global_position = frog.global_position + Vector2.RIGHT * 10.0
	frog.apply_status(&"dazzled", {"duration": 1.0})
	_check(not frog.sight.can_see(target), "dazzle disables production enemy sight")
	frog.apply_status(&"resin_bound", {"provider_id": "content_smoke_resin", "duration": 20.0})
	var resin := WorldEffectArea.new()
	resin.effect_kind = &"resin"
	resin.effect_id = &"resin_bound"
	resin.provider_id = "content_smoke_resin"
	resin._on_body_exited(frog)
	_check(not frog.support.status.has_status(&"resin_bound"), "leaving resin removes enemy provider effect")
	resin.free()
	var health_before := frog.support.health.health
	frog.apply_status(&"poison", {"duration": 10.0})
	frog.support.status._process(10.0)
	_check(is_equal_approx(frog.support.health.health, health_before - 25.0), "poison applies five enemy damage ticks")
	frog.free()
	target.free()

func _test_effects_and_curse() -> void:
	var old_layer := GameSession.current_layer_id
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	add_child(player)
	player.health.set_health(95.0)
	player.apply_status(&"curse_layer_2_health_cap")
	player.apply_status(&"curse_layer_2_health_cap")
	_check(player.status.get_stack_count(&"curse_layer_2_health_cap") == 2, "Layer 2 health-cap stacks independently")
	_check(player.heal(10.0) == 0.0 and player.health.health == 95.0, "health cap must not delete existing health")
	GameSession.current_layer_id = &"layer_1"
	player.curse_tracker.apply_current_layer_curse()
	_check(player.status.has_status(&"curse_layer_1"), "Layer 1 Curse package applies")
	player.apply_status(&"curse_suppression", {"duration": 100.0})
	player.curse_tracker.reference_y = player.global_position.y + 700.0
	player.curse_tracker.crossed_band = 0
	player.curse_tracker._physics_process(0.0)
	_check(is_equal_approx(player.status.get_remaining(&"curse_suppression"), 80.0), "suppression resets ascent reference after one threshold")
	GameSession.current_layer_id = &"layer_2"
	player.curse_tracker.apply_current_layer_curse()
	_check(not player.status.has_status(&"curse_layer_1") and player.status.has_status(&"curse_layer_2_penalty") and player.status.get_stack_count(&"curse_layer_2_health_cap") == 1, "Layer 2 Curse replaces Layer 1 package")
	player.free()
	GameSession.current_layer_id = old_layer

func _test_player_item_regressions() -> void:
	var world := Node2D.new()
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	add_child(world)
	world.add_child(player)
	player.apply_status(&"driftseed", {"duration": 30.0})
	player.velocity.y = -100.0
	player._physics_process(0.1)
	_check(is_equal_approx(player.velocity.y, -10.0), "Driftseed must not increase jump height")
	player.velocity.y = 200.0
	player._physics_process(0.1)
	_check(player.velocity.y <= player.driftseed_fall_speed_cap, "Driftseed must cap falling speed")
	player.health.set_health(10.0)
	player.apply_status(&"healing", {"duration": 25.0})
	player.status._process(25.0)
	_check(is_equal_approx(player.health.health, 60.0), "Bandage healing remains 50 total health")
	_check(player.item_controller.inventory.try_add_item(&"silver_weight"), "Silver Weight enters inventory")
	player.item_controller.inventory.select_hotbar(1)
	_check(player.item_controller.primary(player, world, Vector2.RIGHT * 40.0), "Silver Weight activates")
	_check(is_equal_approx(player.item_controller.get_movement_multiplier(), 0.45) and is_equal_approx(player.item_controller.get_jump_multiplier(), 0.35), "Silver Weight exposes movement and jump tuning")
	_check(player.item_controller.primary(player, world, Vector2.RIGHT * 40.0), "Silver Weight toggles off")
	_check(not is_instance_valid(player.item_controller.prepared_item) and player.item_controller.inventory.get_active_stack().item_id == &"silver_weight", "Silver Weight returns after toggle")
	var resin := ContentCatalog.get_item(&"cling_resin").primary_behavior as DeployableBehavior
	_check(resin.primary_shape is CircleShape2D and resin.impact_shape is CircleShape2D, "item effect shapes are editable resources")
	world.free()

func _test_item_impacts() -> void:
	var probe := ReceiverProbe.new()
	probe.add_to_group(&"small_enemy")
	add_child(probe)
	var thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	thrown.definition = ContentCatalog.get_item(&"silver_weight")
	thrown.persistent_id = "content_smoke_weight"
	add_child(thrown)
	var impact := ImpactData.new()
	impact.receiver = probe
	(ContentCatalog.get_item(&"silver_weight").secondary_behavior as SilverWeightBehavior).on_impact(thrown, impact)
	_check(probe.damage >= 9999.0, "Silver Weight kills small enemies")
	_check(thrown.definition.item_id == &"silver_weight_damaged", "Silver Weight changes to damaged item")
	var frog := preload("res://game/enemies/layer1/tongue_amphibian.tscn").instantiate() as TongueAmphibian
	add_child(frog)
	frog.carried = ItemStack.new(&"throwable_rock")
	var enemy_weight := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	enemy_weight.definition = ContentCatalog.get_item(&"silver_weight")
	enemy_weight.persistent_id = "content_smoke_enemy_weight"
	add_child(enemy_weight)
	var enemy_impact := ImpactData.new()
	enemy_impact.receiver = frog
	enemy_impact.source_actor = probe
	(ContentCatalog.get_item(&"silver_weight").secondary_behavior as SilverWeightBehavior).on_impact(enemy_weight, enemy_impact)
	_check(frog.support.health.is_dead, "Silver Weight safely kills a real small enemy")
	await get_tree().process_frame
	await get_tree().process_frame
	var expired_source := Node2D.new()
	add_child(expired_source)
	var safe_drop := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	safe_drop.configure(ContentCatalog.get_item(&"throwable_rock"), {}, expired_source, Vector2.ZERO, Vector2.ZERO)
	add_child(safe_drop)
	expired_source.free()
	safe_drop._on_body_entered(probe)
	safe_drop.free()
	probe.free()
	thrown.free()
	if is_instance_valid(enemy_weight): enemy_weight.free()
	SaveManager.destroyed_ids.erase("content_smoke_weight")
	SaveManager.destroyed_ids.erase("content_smoke_enemy_weight")

func _test_flyer_transfer() -> void:
	var old_state := SaveManager.loaded_persistent_state.duplicate(true)
	var old_destroyed := SaveManager.destroyed_ids.duplicate(true)
	SaveManager.loaded_persistent_state = {"flyer:test": {"_scene_path": "res://game/enemies/layer1/large_flyer.tscn", "_layer_id": "layer_1", "health": {"health": 321.0}}}
	SaveManager.destroyed_ids.clear()
	var id := SaveManager.transfer_first_scene("res://game/enemies/layer1/large_flyer.tscn", &"layer_2", Vector2(10, 20))
	_check(id == "flyer:test", "living flyer transfer resolves")
	_check(SaveManager.loaded_persistent_state[id]._layer_id == "layer_2" and SaveManager.loaded_persistent_state[id].position == [10.0, 20.0], "flyer transfer preserves state and changes destination")
	var root := Node2D.new()
	root.add_to_group(&"persistent_spawn_root")
	add_child(root)
	SaveManager.restore_registered_objects(&"layer_2")
	var flyer := root.get_child(0) as LargeLayer1Flyer
	_check(flyer != null and flyer.global_position == Vector2(10, 20) and flyer.support.health.health == 321.0, "transferred flyer restores health and position")
	root.free()
	SaveManager.loaded_persistent_state = old_state
	SaveManager.destroyed_ids = old_destroyed

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
