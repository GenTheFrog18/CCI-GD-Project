extends Node

class ReceiverProbe:
	extends Node2D
	var damage := 0.0
	var effects: Array[StringName] = []
	var detection_origin_offset := Vector2.ZERO
	func apply_damage(info: DamageInfo) -> bool:
		damage += info.amount
		return true
	func apply_status(id: StringName, _data: Dictionary = {}) -> bool:
		effects.append(id)
		return true
	func get_detection_origin() -> Vector2:
		return global_position + detection_origin_offset

var failures := PackedStringArray()

func _ready() -> void:
	_check(ContentCatalog.rebuild().is_empty(), "content catalog validates")
	_test_catalog()
	_test_state_visuals()
	_test_world_item_contract()
	_test_enemy_scenes()
	_test_layer2_enemies()
	_test_layer2_quest()
	_test_effects_and_curse()
	_test_player_item_regressions()
	await _test_hit_flash()
	await _test_item_impacts()
	await _test_layer2_relics()
	_test_flyer_transfer()
	await get_tree().process_frame
	if failures.is_empty():
		print("CONTENT_SMOKE_OK")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)

func _test_catalog() -> void:
	for id in [&"tongue_amphibian", &"knockback_bird", &"thorn_bloom", &"lantern_snail", &"cave_spider", &"large_layer1_flyer", &"senior_diver", &"canopy_primate", &"tremor_hound", &"carrion_stalker", &"bulwark_beast", &"sky_hunter"]:
		_check(ContentCatalog.get_enemy(id) != null, "enemy missing: %s" % id)
	for id in [&"bandage", &"info_book", &"numbing_pill", &"sun_sphere", &"lantern_crystal", &"rattlepod", &"hushcap", &"cling_resin", &"driftseed", &"silver_weight"]:
		_check(ContentCatalog.get_item(id) != null, "item missing: %s" % id)
	for id in [&"plate_umbrella", &"lacerator", &"resonance_core", &"bolt_shock", &"whistle_moon"]:
		_check(ContentCatalog.get_item(id) != null, "Layer 2 item missing: %s" % id)
	for id in [&"sun_sphere", &"lantern_crystal", &"rattlepod", &"hushcap", &"cling_resin", &"driftseed", &"silver_weight"]:
		_check(ContentCatalog.get_item(id).icon != null, "finished item art missing: %s" % id)
	for id in [&"bleed", &"poison", &"resin_bound", &"tracking_mark", &"curse_layer_1", &"curse_layer_2_penalty", &"curse_layer_2_health_cap", &"detector_suppressed", &"electro_stunned", &"electrocuted"]:
		_check(ContentCatalog.get_effect(id) != null, "effect missing: %s" % id)

func _test_state_visuals() -> void:
	var bolt := ContentCatalog.get_item(&"bolt_shock")
	var lacerator := ContentCatalog.get_item(&"lacerator")
	var umbrella := ContentCatalog.get_item(&"plate_umbrella")
	_check(bolt.texture_for_state(&"loaded") != bolt.icon, "Bolt Shock loaded visual is assigned")
	_check(lacerator.texture_for_state(&"loaded") != lacerator.icon, "Lacerator loaded visual is assigned")
	_check(umbrella.texture_for_state(&"open") != umbrella.icon, "Plate Umbrella open visual is assigned")
	_check(bolt.texture_for_instance({"visual_state": "loaded"}) == bolt.texture_for_state(&"loaded"), "state dictionary selects item visual")

func _test_world_item_contract() -> void:
	var definition := ContentCatalog.get_item(&"throwable_rock")
	var previous_hitbox := definition.world_hitbox
	var previous_hitbox_scene := definition.world_hitbox_scene
	var custom_hitbox := CircleShape2D.new()
	custom_hitbox.radius = 11.0
	definition.world_hitbox = custom_hitbox
	var thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	thrown.persistent_id = "content_smoke_world_thrown"
	thrown.configure(definition, {"origin": "smoke"}, null, Vector2.ZERO, Vector2.ZERO)
	add_child(thrown)
	var thrown_shape := thrown.get_node("CollisionShape2D").shape as CircleShape2D
	_check(thrown_shape != null and is_equal_approx(thrown_shape.radius, 11.0), "ThrownItem applies per-item world hitbox")
	definition.world_hitbox_scene = preload("res://game/items/world/world_hitbox_authoring.tscn")
	definition.world_hitbox = null
	var scene_thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	scene_thrown.configure(definition, {}, null, Vector2.ZERO, Vector2.ZERO)
	add_child(scene_thrown)
	var scene_shape := scene_thrown.get_node("CollisionShape2D").shape as CircleShape2D
	_check(scene_shape != null and is_equal_approx(scene_shape.radius, 6.0), "ThrownItem applies scene-authored world hitbox")
	var world_item := preload("res://game/items/world/world_item.tscn").instantiate() as WorldItem
	world_item.item_id = definition.item_id
	world_item.persistent_id = "content_smoke_world_item"
	add_child(world_item)
	var world_shape := world_item.get_node("CollisionShape2D").shape as CircleShape2D
	_check(world_shape != null and is_equal_approx(world_shape.radius, 6.0), "WorldItem applies scene-authored world hitbox")
	var book := ContentCatalog.get_item(&"info_book")
	var book_thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	book_thrown.configure(book, {}, null, Vector2.ZERO, Vector2.ZERO)
	add_child(book_thrown)
	var book_shape := book_thrown.get_node("CollisionShape2D").shape as ConvexPolygonShape2D
	_check(book_shape != null and book_shape.points.size() == 6, "Info Book applies polygon-authored world hitbox")
	var saved := world_item.capture_state()
	_check(saved.has("item_id") and saved.has("quantity") and saved.has("persistent_id"), "World state captures shared fields")
	world_item.free()
	book_thrown.free()
	scene_thrown.free()
	thrown.free()
	definition.world_hitbox = previous_hitbox
	definition.world_hitbox_scene = previous_hitbox_scene

func _test_enemy_scenes() -> void:
	var direct_flyer := LargeLayer1Flyer.new()
	_check(direct_flyer.has_method("restore_state"), "large flyer script class compiles")
	direct_flyer.free()
	var flyer := preload("res://game/enemies/layer1/large_flyer.tscn").instantiate() as LargeLayer1Flyer
	add_child(flyer)
	_check(flyer.support.hit_flash_duration > 0.0, "Enemy hit flash duration is adjustable")
	_check(flyer._surround_sight != null and flyer._surround_sight.normal_angle_degrees == 360.0 and flyer._surround_sight.process_mode == Node.PROCESS_MODE_DISABLED, "Large Flyer surround sight is configured and idle")
	_check(flyer.poi_change_min_seconds == 12.0 and flyer.poi_change_max_seconds == 18.0 and flyer.engagement_distance == 80.0, "Large Flyer route and engagement settings are adjustable")
	_check(flyer.poi_patrol_radius == 160.0 and flyer.poi_inner_flight_radius == 130.0 and flyer.max_destination_attempts == 10, "Large Flyer local patrol is adjustable")
	_check(flyer._steering_alpha(1.0 / 60.0) > 0.0, "Large Flyer patrol steering preserves momentum")
	flyer._begin_search(Vector2(96.0, 48.0))
	_check(flyer.state == LargeLayer1Flyer.State.SEARCH and flyer._search_point == Vector2(96.0, 48.0) and flyer._patrol_center == Vector2(96.0, 48.0), "Large Flyer search patrol centers on last known player position")
	flyer.free()
	var spider := preload("res://game/enemies/layer1/cave_spider.tscn").instantiate() as CaveSpider
	add_child(spider)
	_check(spider.sprite.sprite_frames.has_animation(&"walk") and spider.sprite.sprite_frames.has_animation(&"shoot"), "Cave Spider finished animations missing")
	_check(is_equal_approx(spider.projectile_damage, 3.0), "Cave Spider projectile damage is adjustable with 3 default")
	_check(spider.state == CaveSpider.State.IDLE_PAUSE and spider.bite_hitbox != null, "Cave Spider starts in pause state with a dedicated bite hitbox")
	_check(is_equal_approx(spider.miss_retry_cooldown_seconds, 2.0) and is_equal_approx(spider.bite_windup_seconds, 0.4), "Cave Spider retry and bite timings are adjustable")
	var disabled_light := LightSource2D.new()
	disabled_light.enabled = false
	disabled_light.light_intensity = 0.0
	add_child(disabled_light)
	disabled_light.global_position = spider.global_position
	_check(spider._nearest_light() == null, "Cave Spider ignores inactive lights")
	disabled_light.free()
	spider.free()
	var snail := preload("res://game/enemies/layer1/lantern_snail.tscn").instantiate() as LanternSnail
	add_child(snail)
	_check(snail.forward_probe is ShapeCast2D and snail.support_probe is ShapeCast2D, "Lantern Snail surface probes exist")
	_check(snail.walkable_collision_mask == 1, "Lantern Snail uses terrain collision mask")
	snail.free()
	var diver := preload("res://game/enemies/layer1/senior_diver.tscn").instantiate() as SeniorDiver
	add_child(diver)
	_check(diver.sound.minimum_priority == 8 and diver.state == SeniorDiver.State.POST, "Senior Diver has strong-sound investigation and post state")
	var diver_player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	add_child(diver_player)
	var old_whistle_tier := GameSession.whistle_tier
	GameSession.whistle_tier = &"blue"
	_check(diver._is_authorized(diver_player), "Senior Diver authorization uses Blue progression rank")
	GameSession.whistle_tier = &"red"
	_check(not diver._is_authorized(diver_player), "Physical whistle does not authorize Senior Diver")
	var distraction := SoundEvent.new(Vector2(40.0, 20.0), 200.0, &"rattlepod", 8)
	diver._on_sound(distraction, false)
	_check(diver.state == SeniorDiver.State.INVESTIGATE and diver._investigation_position == distraction.position, "Senior Diver investigates strong distraction sounds")
	GameSession.whistle_tier = old_whistle_tier
	diver_player.free()
	diver.free()
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

func _test_layer2_enemies() -> void:
	var coordinator := AttackGroupCoordinator.new()
	add_child(coordinator)
	var first := Node.new()
	var second := Node.new()
	add_child(first)
	add_child(second)
	_check(coordinator.request_attack(first) and not coordinator.request_attack(second), "attack coordinator limits simultaneous attackers")
	coordinator.release_attack(first)

	var hound := preload("res://game/enemies/layer2/tremor_hound.tscn").instantiate() as TremorHound
	add_child(hound)
	var disturbance := SoundEvent.new(Vector2(75, 20), 200.0, &"impact", 8, null, 20.0)
	hound._on_sound(disturbance, false)
	_check(hound.state == TremorHound.State.INVESTIGATE and hound._investigation == disturbance.position, "Hound investigates recorded sound position")

	var stalker := preload("res://game/enemies/layer2/carrion_stalker.tscn").instantiate() as CarrionStalker
	add_child(stalker)
	var attacker := Node2D.new()
	add_child(attacker)
	stalker._on_damaged(DamageInfo.new(1.0, attacker, &"tester"))
	_check(stalker.state == CarrionStalker.State.SHADOW and stalker._target == attacker, "neutral Stalker retaliates when attacked")

	var bulwark := preload("res://game/enemies/layer2/bulwark_beast.tscn").instantiate() as BulwarkBeast
	add_child(bulwark)
	bulwark.state = BulwarkBeast.State.CHARGE
	_check(not bulwark.interrupt_action(&"impact") and bulwark.interrupt_action(&"electric"), "Bulwark charge only accepts electric interruption")

	var had_flock_flag := GameSession.progression_flags.has("layer_2_sky_hunter_active")
	var old_flock_flag = GameSession.progression_flags.get("layer_2_sky_hunter_active")
	GameSession.progression_flags.erase("layer_2_sky_hunter_active")
	var flock := preload("res://game/enemies/layer2/sky_hunter_flock.tscn").instantiate() as SkyHunterFlock
	add_child(flock)
	var saved := flock.capture_state()
	_check((saved.get("members", {}) as Dictionary).size() == flock.starting_member_count and flock.is_in_group(&"persistent_objects") and flock.process_mode == Node.PROCESS_MODE_DISABLED, "Sky Hunter flock owns stable inactive members")
	flock.activate_near(Vector2(1900, 400))
	_check(flock.process_mode == Node.PROCESS_MODE_INHERIT and flock.global_position.x == 1920.0, "flock activation selects the current route")
	var flyer_probe := Node2D.new()
	flyer_probe.add_to_group(&"large_flyer")
	add_child(flyer_probe)
	var hunter: SkyHunter = flock._living_members()[0] as SkyHunter
	flyer_probe.global_position = hunter.global_position - Vector2.RIGHT * 20.0
	_check(hunter._separation_velocity().x > 0.0, "Sky Hunter avoids the Large Flyer")
	if had_flock_flag: GameSession.progression_flags["layer_2_sky_hunter_active"] = old_flock_flag
	else: GameSession.progression_flags.erase("layer_2_sky_hunter_active")

	flyer_probe.free()
	flock.free()
	bulwark.free()
	attacker.free()
	stalker.free()
	hound.free()
	second.free()
	first.free()
	coordinator.free()

func _test_layer2_quest() -> void:
	var old_flags := GameSession.progression_flags.duplicate(true)
	var old_tier := GameSession.whistle_tier
	var old_path := SaveManager.run_path
	var old_persistent := SaveManager.loaded_persistent_state.duplicate(true)
	var old_destroyed := SaveManager.destroyed_ids.duplicate(true)
	SaveManager.run_path = "user://content_smoke_layer2_quest.json"
	SaveManager.loaded_persistent_state.clear()
	SaveManager.destroyed_ids.clear()
	GameSession.progression_flags.erase(Layer2Gatekeeper.REWARD_FLAG)

	var world := Node2D.new()
	add_child(world)
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	world.add_child(player)
	var gatekeeper := preload("res://game/world/layer2_gatekeeper.tscn").instantiate() as Layer2Gatekeeper
	world.add_child(gatekeeper)
	_check(player.item_controller.inventory.try_add_item(&"resonance_core", 1, {"origin": "map"}), "Core enters inventory for handover")
	_check(gatekeeper.interact(player) and not bool(GameSession.progression_flags.get(Layer2Gatekeeper.REWARD_FLAG, false)), "Core handover asks for confirmation")
	_check(gatekeeper.interact(player), "Core handover confirms")
	_check(bool(GameSession.progression_flags.get(Layer2Gatekeeper.REWARD_FLAG, false)) and GameSession.whistle_tier == &"moon" and player.physical_whistle_id == &"whistle_moon", "Core handover awards Moon progression")
	_check(not player.item_controller.inventory.has_item(&"resonance_core") and player.item_controller.inventory.has_item(&"bolt_shock"), "Core handover exchanges exactly one Core for Bolt Shock")
	var state := player.item_controller.inventory.take_item(&"bolt_shock")
	_check(int(state.state.get("remaining_uses", -1)) == 7, "quest Bolt Shock starts with seven uses")
	player.item_controller.inventory.try_add_item(&"bolt_shock", 1, state.state)
	gatekeeper.interact(player)
	var bolt_count := 0
	for container in [player.item_controller.inventory.hotbar, player.item_controller.inventory.backpack]:
		for stack in container:
			if stack.item_id == &"bolt_shock": bolt_count += stack.quantity
	_check(bolt_count == 1, "repeated gatekeeper interaction cannot duplicate reward")

	world.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.run_path))
	SaveManager.run_path = old_path
	SaveManager.loaded_persistent_state = old_persistent
	SaveManager.destroyed_ids = old_destroyed
	GameSession.progression_flags = old_flags
	GameSession.whistle_tier = old_tier

func _test_effects_and_curse() -> void:
	var old_layer := GameSession.current_layer_id
	var flash_receiver := ReceiverProbe.new()
	flash_receiver.add_to_group(&"effect_receivers")
	flash_receiver.position = Vector2(80.0, 80.0)
	flash_receiver.detection_origin_offset = Vector2(0.0, -80.0)
	add_child(flash_receiver)
	var crystal_flash := WorldEffectArea.new()
	var crystal_shape := CircleShape2D.new()
	crystal_shape.radius = 110.0
	crystal_flash.configure(&"crystal", &"dazzled", 4.0, crystal_shape)
	add_child(crystal_flash)
	crystal_flash._flash()
	_check(flash_receiver.effects.has(&"dazzled"), "Crystal flash targets the receiver detection origin")
	crystal_flash.free()
	flash_receiver.free()
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
	player.apply_status(&"poison", {"duration": 10.0})
	player.apply_status(&"poison", {"duration": 10.0})
	_check(is_equal_approx(player.status.get_remaining(&"poison"), 15.0), "Poison duration stacks to its cap")
	player.apply_status(&"spider_slow", {"duration": 3.0})
	player.apply_status(&"spider_slow", {"duration": 3.0})
	_check(is_equal_approx(player.status.get_remaining(&"spider_slow"), 6.0), "Spider slow duration stacks additively")
	player.apply_status(&"tracking_mark", {"duration": 20.0})
	player.apply_status(&"tracking_mark", {"duration": 20.0})
	_check(is_equal_approx(player.status.get_remaining(&"tracking_mark"), 20.0), "Tracking mark duration respects its cap")
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
	_check(is_equal_approx(resin.loose_item_speed_multiplier, 0.25), "Cling Resin exposes loose item slowdown")
	var resin_area := WorldEffectArea.new()
	resin_area.effect_kind = &"resin"
	resin_area.loose_item_speed_multiplier = resin.loose_item_speed_multiplier
	var loose_item := RigidBody2D.new()
	loose_item.add_to_group(&"loose_items")
	loose_item.linear_velocity = Vector2.RIGHT * 100.0
	resin_area._on_body_entered(loose_item)
	resin_area._physics_process(1.0 / 60.0)
	_check(loose_item.linear_velocity.x < 100.0 and loose_item.linear_velocity.x > 90.0, "Cling Resin gradually slows loose items")
	loose_item.linear_velocity += Vector2.DOWN * 100.0
	resin_area._physics_process(1.0 / 60.0)
	_check(loose_item.linear_velocity.x > 80.0 and loose_item.linear_velocity.y > 90.0, "Cling Resin preserves velocity while slowing")
	resin_area._on_body_exited(loose_item)
	_check(resin_area._resin_bodies.is_empty(), "Loose items leave resin tracking on exit")
	loose_item.free()
	resin_area.free()
	world.free()

func _test_hit_flash() -> void:
	var actor := Node2D.new()
	var visual := Sprite2D.new()
	var original := CanvasItemMaterial.new()
	visual.material = original
	actor.add_child(visual)
	add_child(actor)
	var flash := HitFlash.new()
	actor.add_child(flash)
	_check(flash.setup(actor), "Hit flash finds actor visual")
	flash.play(2)
	_check(visual.material is ShaderMaterial, "Hit flash turns visual white immediately")
	await get_tree().create_timer(0.25).timeout
	_check(visual.material == original, "Hit flash restores original material")
	actor.free()

func _test_item_impacts() -> void:
	var probe := ReceiverProbe.new()
	probe.add_to_group(&"small_enemy")
	add_child(probe)
	var safe_thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	safe_thrown.definition = ContentCatalog.get_item(&"silver_weight")
	safe_thrown.persistent_id = "content_smoke_safe_weight"
	add_child(safe_thrown)
	var safe_impact := ImpactData.new()
	safe_impact.receiver = probe
	safe_impact.velocity = Vector2.RIGHT * 20.0
	(ContentCatalog.get_item(&"silver_weight").secondary_behavior as SilverWeightBehavior).on_impact(safe_thrown, safe_impact)
	_check(is_equal_approx(probe.damage, 0.0) and safe_thrown.definition.item_id == &"silver_weight", "Soft Silver Weight impact stays safely pickup-able")
	var thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	thrown.definition = ContentCatalog.get_item(&"silver_weight")
	thrown.persistent_id = "content_smoke_weight"
	add_child(thrown)
	var impact := ImpactData.new()
	impact.receiver = probe
	impact.velocity = Vector2.RIGHT * 200.0
	(ContentCatalog.get_item(&"silver_weight").secondary_behavior as SilverWeightBehavior).on_impact(thrown, impact)
	_check(is_equal_approx(probe.damage, 200.0), "Silver Weight deals global adjustable heavy damage")
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
	enemy_impact.velocity = Vector2.RIGHT * 200.0
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
	safe_thrown.free()
	thrown.free()
	if is_instance_valid(enemy_weight): enemy_weight.free()
	SaveManager.destroyed_ids.erase("content_smoke_weight")
	SaveManager.destroyed_ids.erase("content_smoke_safe_weight")
	SaveManager.destroyed_ids.erase("content_smoke_enemy_weight")

func _test_flyer_transfer() -> void:
	var old_state := SaveManager.loaded_persistent_state.duplicate(true)
	var old_destroyed := SaveManager.destroyed_ids.duplicate(true)
	SaveManager.loaded_persistent_state = {"flyer:test": {
		"_scene_path": "res://game/enemies/layer1/large_flyer.tscn",
		"_layer_id": "layer_1",
		"health": {"health": 321.0},
		"status": {&"driftseed": {"applications": [{"remaining": 12.0, "provider_id": "", "source_id": "", "modifiers": {}}], "tick_remaining": 1.0}},
	}}
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
	_check(flyer != null and flyer.support.status.has_status(&"driftseed") and flyer.state == LargeLayer1Flyer.State.ROAM and flyer._target == null and flyer._requests.is_empty() and flyer.is_in_group(&"large_flyer"), "transferred flyer keeps status but resets transient AI")
	if flyer != null:
		flyer._upsert_request(&"ordinary", Vector2.ZERO, null, 20.0, INF, false)
		flyer._upsert_request(&"snail", Vector2.ZERO, null, 50.0, INF, false)
		_check(StringName(flyer._select_request().get("request_id", "")) == &"snail", "flyer selects strongest target request")
		flyer._remove_request(&"snail")
		_check(StringName(flyer._select_request().get("request_id", "")) == &"ordinary", "flyer falls back to valid lower-priority request")
		var stale_source := Node2D.new()
		root.add_child(stale_source)
		flyer._upsert_request(&"stale", Vector2.ZERO, null, 90.0, INF, false, stale_source)
		stale_source.free()
		_check(StringName(flyer._select_request().get("request_id", "")) == &"ordinary", "flyer removes requests from freed sources")
		flyer.state = LargeLayer1Flyer.State.ATTACK_SETUP
		_check(flyer.interrupt_action(&"electric") and flyer.state == LargeLayer1Flyer.State.RECOVER, "Bolt Shock interrupts flyer attacks")
	root.free()
	SaveManager.loaded_persistent_state = old_state
	SaveManager.destroyed_ids = old_destroyed

func _test_layer2_relics() -> void:
	var world := Node2D.new()
	add_child(world)
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	world.add_child(player)
	_check(player.item_controller.inventory.try_add_item(&"plate_umbrella"), "Umbrella enters inventory")
	player.item_controller.inventory.select_hotbar(1)
	_check(player.item_controller.primary(player, world, Vector2.RIGHT * 100.0), "Umbrella prepares")
	var umbrella := player.item_controller.prepared_item as PreparedLayer2Relic
	umbrella.umbrella_state = PreparedLayer2Relic.UmbrellaState.OPEN
	umbrella.aim_direction = Vector2.RIGHT
	_check(umbrella.blocking_hitbox != null and umbrella.blocking_hitbox.polygon.size() >= 3 and player.item_controller.get_movement_multiplier() == 1.0, "Umbrella has editable hitbox and neutral default speed")
	var attacker := Node2D.new()
	world.add_child(attacker)
	attacker.global_position = player.global_position + Vector2.RIGHT * 40.0
	var impact := ImpactData.new()
	impact.source_actor = attacker
	impact.source_species_id = &"enemy"
	impact.base_damage = 10.0
	impact.velocity = Vector2.LEFT * 200.0
	impact.force = Vector2.LEFT * 50.0
	impact.attack_kind = &"projectile"
	var health_before := player.health.health
	_check(bool(player.resolve_impact(impact).get("blocked", false)) and player.health.health == health_before, "Umbrella blocks frontal projectile damage")
	player.item_controller.cancel_prepared(&"inventory")
	world.remove_child(player)
	player.free()

	player = preload("res://game/player/player.tscn").instantiate() as PlayerController
	world.add_child(player)
	_check(player.item_controller.inventory.try_add_item(&"lacerator"), "Lacerator enters inventory")
	player.item_controller.inventory.select_hotbar(1)
	_check(player.item_controller.get_preview(player, world, player.global_position + Vector2.RIGHT * 100.0).is_empty(), "Lacerator hides trajectory until loaded")
	_check(player.item_controller.primary(player, world, Vector2.RIGHT * 100.0), "Lacerator loads")
	var loaded_lacerator := player.item_controller.prepared_item as PreparedLayer2Relic
	var lacerator_preview := player.item_controller.get_preview(player, world, player.global_position + Vector2.RIGHT * 100.0)
	_check(loaded_lacerator._direction_to_cursor(player.global_position + Vector2(100.0, 200.0)) == Vector2.RIGHT and loaded_lacerator._direction_to_cursor(player.global_position + Vector2(-100.0, 200.0)) == Vector2.LEFT, "Lacerator aim stays horizontal")
	_check(lacerator_preview.get("kind") == &"trajectory" and lacerator_preview.get("points", PackedVector2Array()).size() > 1, "Loaded Lacerator shows trajectory dots")
	var upward_preview := player.item_controller.get_preview(player, world, player.global_position + Vector2.UP * 100.0)
	var upward_points: PackedVector2Array = upward_preview.get("points", PackedVector2Array())
	_check(player.item_controller.get_jump_multiplier() == 0.0, "Active Lacerator locks jumping")
	_check(player.item_controller.get_movement_multiplier() == 1.0, "Active Lacerator keeps default speed")
	_check(upward_points.size() > 1 and upward_points[1].y < upward_points[0].y, "Active Lacerator aims its throw")
	_check(player.item_controller.secondary(player, world, Vector2.RIGHT * 100.0), "Lacerator fires")
	var lacerator_state := player.item_controller.inventory.get_active_stack().state
	_check(int(lacerator_state.get("remaining_ammo", -1)) == 3, "Lacerator spends one successful shot")
	_check(player.item_controller.primary(player, world, Vector2.RIGHT * 100.0), "Lacerator reloads")
	player.item_controller.cancel_prepared(&"inventory")
	_check(int(player.item_controller.inventory.get_active_stack().state.get("remaining_ammo", -1)) == 3, "Context unload preserves Lacerator ammunition")
	for child in world.get_children():
		if child is LaceratorBall:
			var saved: Dictionary = child.capture_state()
			_check(int(saved.remaining_hits) == 4, "Lacerator ball saves remaining contacts")
			child.queue_free()
	world.remove_child(player)
	player.free()

	player = preload("res://game/player/player.tscn").instantiate() as PlayerController
	world.add_child(player)
	_check(player.item_controller.inventory.try_add_item(&"bolt_shock"), "Bolt Shock enters inventory")
	player.item_controller.inventory.select_hotbar(1)
	_check(player.item_controller.primary(player, world, Vector2.RIGHT * 100.0), "Bolt Shock loads")
	_check(player.item_controller.secondary(player, world, Vector2.RIGHT * 100.0), "Bolt Shock fires")
	_check(int(player.item_controller.inventory.get_active_stack().state.get("remaining_uses", -1)) == 6, "Bolt Shock starts with seven uses")
	for child in world.get_children():
		if child is BoltShockRod:
			child.queue_free()
	world.remove_child(player)
	player.free()

	var core := ContentCatalog.get_item(&"resonance_core")
	_check(core.primary_behavior == null and core.recover_out_of_bounds and core.weight == 18, "Resonance Core uses impact discovery and protected recovery")
	var previous_known := GameSession.known_items.duplicate()
	GameSession.known_items.erase(&"resonance_core")
	var thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	thrown.configure(core, {}, null, Vector2.ZERO, Vector2.RIGHT * 300.0, 100.0)
	world.add_child(thrown)
	var core_impact := ImpactData.new()
	core_impact.velocity = Vector2.RIGHT * 300.0
	(core.secondary_behavior as ResonanceCoreBehavior).on_impact(thrown, core_impact)
	_check(&"resonance_core" in GameSession.known_items, "Core discovers on qualifying impact")
	thrown.global_position = Vector2(99999, 99999)
	thrown.handle_world_out_of_bounds()
	_check(thrown.global_position == Vector2.ZERO and thrown.freeze, "protected thrown relic returns to its spawn without a recovery marker")
	var protected_pickup := preload("res://game/items/world/world_item.tscn").instantiate() as WorldItem
	protected_pickup.item_id = &"resonance_core"
	protected_pickup.position = Vector2(50, 60)
	world.add_child(protected_pickup)
	protected_pickup.global_position = Vector2(99999, 99999)
	protected_pickup.handle_world_out_of_bounds()
	_check(protected_pickup.global_position == Vector2(50, 60), "protected pickup returns to its spawn without a recovery marker")
	GameSession.known_items.assign(previous_known)
	thrown.queue_free()
	protected_pickup.queue_free()
	attacker.queue_free()
	world.queue_free()

func _check(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
