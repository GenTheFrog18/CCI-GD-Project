extends Node

class SoundProbe:
	extends Node2D
	var received := 0
	func hear_sound(event: SoundEvent) -> void:
		if global_position.distance_to(event.position) <= event.radius:
			received += 1

class PreparedProbe:
	extends Node2D
	var thrown := false
	func throw_toward(_cursor: Vector2) -> void:
		thrown = true

class DamageProbe:
	extends Node2D
	var hits := 0
	var forces := 0
	func apply_damage(_info: DamageInfo) -> bool:
		hits += 1
		return true
	func apply_force(_force: Vector2) -> void:
		forces += 1

class PickupProbe:
	extends Node2D
	var inventory := InventoryModel.new()
	func try_pickup_item(item_id: StringName, quantity: int, state: Dictionary) -> bool:
		return inventory.try_add_item(item_id, quantity, state)

func _ready() -> void:
	_test_catalog()
	_test_inventory()
	await _test_interaction_sensor()
	_test_combat_and_status()
	_test_projectile_hit_history()
	await _test_multitool_range()
	_test_turret_projectile()
	_test_ui_input_and_debug()
	_test_sound()
	_test_control_locks()
	await _test_determinism()
	_test_shop()
	_test_prepared_item()
	_test_save()
	await _test_world_run_runtime()
	_test_room_loads()
	_test_invalid_position_fallback()
	await get_tree().process_frame
	print("FOUNDATION_SMOKE_OK")
	get_tree().quit(0)

func _test_catalog() -> void:
	assert(ContentCatalog.rebuild().is_empty())
	assert(ContentCatalog.get_item(&"multitool") != null)
	assert(ContentCatalog.get_item(&"throwable_rock") != null)
	var registry: Dictionary = {}
	var errors := PackedStringArray()
	var definition := ContentCatalog.get_item(&"multitool")
	ContentCatalog._register(registry, &"duplicate", definition, "first", errors)
	ContentCatalog._register(registry, &"duplicate", definition, "second", errors)
	assert(errors.size() == 1)
	var has_w_jump := false
	for event in InputMap.action_get_events(&"jump"):
		if event is InputEventKey and event.physical_keycode == KEY_W:
			has_w_jump = true
	assert(has_w_jump)

func _test_inventory() -> void:
	var inventory := InventoryModel.new()
	assert(inventory.try_add_item(&"throwable_rock", 9))
	assert(inventory.hotbar[0].quantity == 8)
	assert(inventory.hotbar[1].quantity == 1)
	assert(inventory.swap_slots(&"hotbar", 0, &"backpack", 0))
	assert(inventory.backpack[0].quantity == 8)
	inventory.select_hotbar(1)
	assert(inventory.remove_active(1))
	assert(inventory.hotbar[1].is_empty())
	var restored := InventoryModel.new()
	restored.restore_state(inventory.capture_state())
	assert(restored.backpack[0].quantity == 8)
	_test_item_action_rollback_and_pickup()

func _test_item_action_rollback_and_pickup() -> void:
	var controller := PlayerItemController.new()
	var actor := Node2D.new()
	var anchor := Node2D.new()
	var world := Node2D.new()
	add_child(actor)
	actor.add_child(anchor)
	add_child(world)
	add_child(controller)
	actor.global_position = Vector2(20.0, 30.0)
	anchor.position = Vector2(8.0, -12.0)
	controller.held_item_anchor = anchor
	assert(controller.inventory.try_add_item(&"throwable_rock"))
	var failed_result := ItemActionResult.completed(2)
	failed_result.world_node = Node2D.new()
	assert(not controller._commit_result(failed_result, world))
	assert(controller.inventory.get_active_stack().quantity == 1)
	assert(failed_result.world_node.is_queued_for_deletion())
	assert(controller.secondary(actor, world, anchor.global_position + Vector2.RIGHT * 100.0))
	assert(controller.inventory.get_active_stack().is_empty())
	var thrown: ThrownItem
	for child in world.get_children():
		if child is ThrownItem and not child.is_queued_for_deletion():
			thrown = child
	assert(thrown != null)
	assert(thrown.global_position == anchor.global_position)
	thrown.freeze = true
	var picker := PickupProbe.new()
	assert(thrown.interact(picker))
	assert(picker.inventory.get_active_stack().quantity == 1)
	assert(controller.inventory.try_add_item(&"throwable_rock"))
	assert(controller.secondary(actor, world, actor.global_position + Vector2.LEFT * 100.0))
	var left_thrown: ThrownItem
	for child in world.get_children():
		if child is ThrownItem and not child.is_queued_for_deletion():
			left_thrown = child
	assert(left_thrown != null)
	assert(left_thrown.global_position == actor.global_position + Vector2(-8.0, -12.0))
	assert(left_thrown.linear_velocity.x < 0.0)
	picker.free()
	controller.free()
	actor.free()
	world.free()

func _test_interaction_sensor() -> void:
	var sensor := InteractionSensor.new()
	sensor.collision_mask = 8
	var sensor_shape := CollisionShape2D.new()
	var sensor_circle := CircleShape2D.new()
	sensor_circle.radius = 20.0
	sensor_shape.shape = sensor_circle
	sensor.add_child(sensor_shape)
	add_child(sensor)
	var thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	thrown.freeze = true
	add_child(thrown)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(sensor.best_target() == thrown)
	thrown.free()
	sensor.free()

func _test_combat_and_status() -> void:
	var health := HealthComponent.new()
	health.max_health = 10.0
	health.invulnerability_seconds = 0.0
	add_child(health)
	var death_count := [0]
	health.died.connect(func(_source: Node): death_count[0] += 1)
	assert(not health.apply_damage(DamageInfo.new(5.0, null, &"frog"), &"frog"))
	assert(health.health == 10.0)
	assert(health.apply_damage(DamageInfo.new(5.0, null, &"bird"), &"frog"))
	assert(health.health == 5.0)
	assert(health.apply_damage(DamageInfo.new(10.0, null, &"bird"), &"frog"))
	assert(health.is_dead and death_count[0] == 1)
	assert(not health.apply_damage(DamageInfo.new(10.0), &"frog"))
	assert(death_count[0] == 1)
	var status := StatusController.new()
	add_child(status)
	assert(status.apply_status(&"test_slow"))
	assert(is_equal_approx(status.get_multiplier(&"move_speed"), 0.5))
	status._process(2.1)
	assert(is_equal_approx(status.get_multiplier(&"move_speed"), 1.0))
	health.queue_free()
	status.queue_free()

func _test_projectile_hit_history() -> void:
	var projectile := Projectile.new()
	var impact := ImpactData.new()
	impact.max_hits = 2
	impact.base_damage = 1.0
	projectile.impact = impact
	projectile.velocity = Vector2(100.0, 0.0)
	var probe := DamageProbe.new()
	projectile._handle_collision(probe)
	projectile._handle_collision(probe)
	assert(probe.hits == 1 and probe.forces == 1)
	projectile.free()
	probe.free()

func _test_multitool_range() -> void:
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	var frog := preload("res://game/enemies/test/test_amphibian.tscn").instantiate() as TestAmphibian
	add_child(player)
	add_child(frog)
	player.global_position = Vector2.ZERO
	frog.global_position = Vector2(100.0, 0.0)
	await get_tree().physics_frame
	assert(player.item_controller.primary(player, self, Vector2(120.0, -14.0)))
	assert(frog.health.health == 20.0)
	frog.global_position = Vector2(40.0, 0.0)
	await get_tree().physics_frame
	assert(player.item_controller.primary(player, self, Vector2(80.0, -14.0)))
	assert(frog.health.health == 19.0)
	player.apply_force(Vector2(30.0, 0.0))
	player._physics_process(0.0)
	assert(player._knockback == Vector2.ZERO)
	frog.apply_force(Vector2(30.0, 0.0))
	frog._physics_process(0.0)
	assert(frog._knockback == Vector2.ZERO)
	assert(player.collision_mask == 1)
	assert(player._camera_target(Vector2(320.0, 180.0), Vector2(640.0, 360.0)) == player.camera_base_offset)
	assert(player._camera_target(Vector2(640.0, 360.0), Vector2(640.0, 360.0)) == player.camera_base_offset + Vector2(56.0, 28.0))
	player.free()
	frog.free()

func _test_turret_projectile() -> void:
	var world := Node2D.new()
	var turret := preload("res://game/enemies/test/projectile_turret.tscn").instantiate() as ProjectileTurret
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	add_child(world)
	world.add_child(turret)
	world.add_child(player)
	turret.global_position = Vector2(100.0, 100.0)
	player.global_position = Vector2(20.0, 100.0)
	turret._aim_position = player.global_position + Vector2(0.0, -14.0)
	turret._fire()
	var projectile: Projectile
	for child in world.get_children():
		if child is Projectile:
			projectile = child
	assert(projectile != null and projectile.global_position == turret.muzzle.global_position)
	projectile._handle_collision(player)
	assert(player.health.health < player.health.max_health)
	player.health.set_health(0.0)
	turret.target = player
	turret._telegraph_remaining = 0.5
	turret._process(0.1)
	assert(turret._telegraph_remaining == 0.0)
	world.free()

func _test_ui_input_and_debug() -> void:
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	var hud := FoundationHUD.new()
	add_child(player)
	add_child(hud)
	hud.set_player(player)
	assert(hud.hotbar_labels[0].text.contains("Multitool"))
	player.health.set_health(0.4)
	assert(hud.health_label.text == "HP 1/100")
	player.set_inventory_open(true)
	hud.inventory_buttons[0].grab_focus()
	hud._slot_pressed(0)
	var inventory_event := InputEventAction.new()
	inventory_event.action = &"inventory"
	inventory_event.pressed = true
	hud._input(inventory_event)
	assert(not player.inventory_open and hud._selected_index == -1)
	player.set_inventory_open(true)
	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	hud._input(pause_event)
	assert(not player.inventory_open and not get_tree().paused)
	hud._input(pause_event)
	assert(get_tree().paused)
	hud._input(pause_event)
	assert(not get_tree().paused)
	hud.debug_panel.visible = true
	hud._update_performance()
	assert(not hud.performance_label.text.is_empty() and hud.crosshair != null)
	var dialogue := ContentCatalog.get_dialogue(&"foundation_intro")
	hud.show_dialogue(dialogue)
	assert(hud.dialogue_box.visible and not player.locks.is_locked())
	var interact_event := InputEventAction.new()
	interact_event.action = &"interact"
	interact_event.pressed = true
	hud.dialogue_box._input(interact_event)
	assert(hud.dialogue_box._index == 1)
	hud.dialogue_box._input(interact_event)
	assert(not hud.dialogue_box.visible)
	var original_run_path := SaveManager.run_path
	var original_meta_path := SaveManager.meta_path
	SaveManager.run_path = "user://foundation_smoke_death_run.json"
	SaveManager.meta_path = "user://foundation_smoke_death_meta.json"
	var run_file := FileAccess.open(SaveManager.run_path, FileAccess.WRITE)
	run_file.store_string("living run")
	run_file.close()
	hud.show_dialogue(dialogue)
	player.health.set_health(0.0)
	assert(not player.is_alive() and hud.death_panel.visible and not get_tree().paused)
	assert(not hud.dialogue_box.visible)
	assert(not FileAccess.file_exists(SaveManager.run_path) and FileAccess.file_exists(SaveManager.meta_path))
	player.apply_force(Vector2(30.0, 0.0))
	assert(player._knockback == Vector2.ZERO)
	hud._input(inventory_event)
	assert(not player.inventory_open and not get_tree().paused)
	SaveManager.delete_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.meta_path))
	SaveManager.run_path = original_run_path
	SaveManager.meta_path = original_meta_path
	hud.free()
	player.free()

func _test_sound() -> void:
	var probe := SoundProbe.new()
	probe.add_to_group(&"sound_listeners")
	add_child(probe)
	SoundBus.emit_sound(get_tree(), SoundEvent.new(Vector2.ZERO, 10.0, &"test", 1))
	assert(probe.received == 1)
	SoundBus.emit_sound(get_tree(), SoundEvent.new(Vector2(100.0, 0.0), 10.0, &"test", 1))
	assert(probe.received == 1)
	var frog := preload("res://game/enemies/test/test_amphibian.tscn").instantiate() as TestAmphibian
	add_child(frog)
	frog.hear_sound(SoundEvent.new(Vector2(100.0, 0.0), 200.0, &"test", 1))
	assert(frog.state == TestAmphibian.State.ALERT and frog.get_node("SoundIndicator").text == "!")
	frog._physics_process(0.36)
	assert(frog.state == TestAmphibian.State.INVESTIGATE and frog.get_node("SoundIndicator").text == "?")
	frog.global_position = frog._target
	frog._physics_process(0.0)
	assert(frog.state == TestAmphibian.State.WAIT and not frog.get_node("SoundIndicator").visible)
	frog.free()
	probe.queue_free()

func _test_control_locks() -> void:
	var locks := ControlLocks.new()
	locks.lock(&"inventory")
	locks.lock(&"dialogue")
	assert(locks.is_locked())
	locks.unlock(&"inventory")
	assert(locks.is_locked())
	locks.unlock(&"dialogue")
	assert(not locks.is_locked())

func _test_determinism() -> void:
	var placer := DeterministicPlacer.new()
	placer.persistent_id = &"test_placer"
	var entry := WorldSpawnEntry.new()
	entry.content_id = &"throwable_rock"
	entry.scene = preload("res://game/items/world/world_item.tscn")
	placer.entries = [entry]
	placer.minimum_quantity = 2
	placer.maximum_quantity = 2
	var first_point := Marker2D.new()
	var second_point := Marker2D.new()
	placer.add_child(first_point)
	placer.add_child(second_point)
	placer.spawn_points = [first_point, second_point]
	var first := placer.resolve(12345)
	var second := placer.resolve(12345)
	assert(first == second and first.size() == 2)
	assert(placer.validate().is_empty())
	var section := preload("res://game/world/test/section_a.tscn").instantiate() as WorldSection
	add_child(section)
	assert(section.validate().is_empty())
	section.queue_free()
	var generator := WorldGenerator.new()
	generator.layer_scenes = [
		preload("res://game/world/layers/layer_1.tscn"),
		preload("res://game/world/layers/layer_2.tscn"),
	]
	add_child(generator)
	var first_manifest := await generator.build_manifest(12345)
	var second_manifest := await generator.build_manifest(12345)
	assert(not first_manifest.has("errors"))
	assert(first_manifest.sections == second_manifest.sections)
	assert(first_manifest.placers == second_manifest.placers)
	assert(first_manifest.sections.size() == 12)
	assert(first_manifest.placers.size() == 2)
	assert(first_manifest.placers["layer1_east_02_a_enemy_01"].size() == 1)
	assert(generator.validate_templates().is_empty())
	var layer := preload("res://game/world/layers/layer_1.tscn").instantiate() as WorldLayer
	var varied_ids: Dictionary = {}
	var varied_slot: WorldSlot
	for slot in layer.get_slots():
		if slot.slot_id == &"layer1_west_01":
			varied_slot = slot
	assert(varied_slot != null)
	for seed in 24:
		var scene := varied_slot.select_variation(seed + 1)
		var selected_section := scene.instantiate() as WorldSection
		varied_ids[selected_section.variation_id] = true
		selected_section.free()
	assert(varied_ids.size() == 2)
	layer.free()
	generator.free()
	placer.free()

func _test_shop() -> void:
	GameSession.start_new_run(111)
	var inventory := InventoryModel.new()
	var shop := ShopService.new(ContentCatalog.get_shop(&"test_shop"))
	assert(shop.try_buy(inventory, &"multitool"))
	assert(GameSession.money == 10)
	assert(not shop.try_buy(inventory, &"multitool"))
	assert(GameSession.money == 10)

func _test_prepared_item() -> void:
	var controller := PlayerItemController.new()
	var anchor := Node2D.new()
	var world := Node2D.new()
	add_child(anchor)
	add_child(world)
	add_child(controller)
	controller.held_item_anchor = anchor
	var prepared := PreparedProbe.new()
	assert(controller.try_prepare(prepared))
	assert(prepared.get_parent() == anchor)
	var actor := Node2D.new()
	assert(controller.secondary(actor, world, Vector2.ONE))
	assert(prepared.thrown and prepared.get_parent() == world)
	actor.free()
	controller.free()
	anchor.free()
	world.free()

func _test_save() -> void:
	var original_path := SaveManager.run_path
	SaveManager.run_path = "user://foundation_smoke_run.json"
	GameSession.start_new_run(9876)
	GameSession.add_money(5)
	assert(SaveManager.save_run({"smoke": true}))
	GameSession.money = 0
	var loaded := SaveManager.load_run()
	assert(not loaded.is_empty())
	assert(GameSession.run_seed == 9876 and GameSession.money == 55)
	assert(bool(loaded.extra.smoke))
	var spawn_root := Node2D.new()
	spawn_root.add_to_group(&"persistent_spawn_root")
	add_child(spawn_root)
	var dropped := preload("res://game/items/world/world_item.tscn").instantiate() as WorldItem
	dropped.item_id = &"throwable_rock"
	dropped.persistent_id = "smoke_dynamic_item"
	spawn_root.add_child(dropped)
	dropped.global_position = Vector2(12.0, 34.0)
	assert(SaveManager.save_run())
	dropped.free()
	assert(not SaveManager.load_run().is_empty())
	SaveManager.restore_registered_objects()
	var restored_item: WorldItem
	for child in spawn_root.get_children():
		if child is WorldItem:
			restored_item = child
	assert(restored_item != null and restored_item.global_position == Vector2(12.0, 34.0))
	SaveManager.mark_destroyed(restored_item.persistent_id)
	assert(SaveManager.save_run())
	restored_item.free()
	var preplaced := preload("res://game/items/world/world_item.tscn").instantiate() as WorldItem
	preplaced.item_id = &"throwable_rock"
	preplaced.persistent_id = "smoke_dynamic_item"
	spawn_root.add_child(preplaced)
	assert(not SaveManager.load_run().is_empty())
	SaveManager.restore_registered_objects()
	assert(preplaced.is_queued_for_deletion())
	spawn_root.free()
	SaveManager.delete_run()
	var corrupt := FileAccess.open(SaveManager.run_path, FileAccess.WRITE)
	corrupt.store_string("not-json")
	corrupt.close()
	assert(SaveManager.load_run().is_empty())
	SaveManager.delete_run()
	SaveManager.run_path = original_path

func _test_room_loads() -> void:
	var room := preload("res://game/world/foundation_test_room.tscn").instantiate()
	assert(room != null)
	room.free()
	var world_run := preload("res://game/world/world_run.tscn").instantiate()
	assert(world_run != null)
	world_run.free()

func _test_world_run_runtime() -> void:
	var original_run_path := SaveManager.run_path
	var original_meta_path := SaveManager.meta_path
	SaveManager.run_path = "user://foundation_smoke_world_run.json"
	SaveManager.meta_path = "user://foundation_smoke_world_meta.json"
	SaveManager.delete_run()
	GameSession.start_new_run(2468, true)
	var world := preload("res://game/world/world_run.tscn").instantiate() as WorldRun
	add_child(world)
	for _frame in 24:
		await get_tree().process_frame
	assert(world.active_layer != null and world.active_layer.layer_id == &"surface")
	assert(world.player != null and GameSession.world_manifest.sections.size() == 12)
	await world.request_layer_transition(&"layer_1", &"east")
	assert(world.active_layer.layer_id == &"layer_1")
	assert(world.active_layer.instantiated_sections.size() == 6)
	assert(world.player.global_position.distance_to(world.active_layer.east_spawn.global_position) < 5.0)
	world._process(0.21)
	assert(world.active_layer.active_slot_ids.has("layer1_east_01"))
	assert(world.active_layer.active_slot_ids.has("layer1_east_02"))
	var found_generated_enemy := false
	for child in world.active_layer.runtime_root.get_children():
		if child is TestAmphibian:
			found_generated_enemy = true
	assert(found_generated_enemy)
	await world.request_layer_transition(&"layer_2", &"east")
	assert(world.active_layer.layer_id == &"layer_2")
	await world.request_layer_transition(&"layer_1", &"east", &"EastBottomSpawn")
	assert(world.player.global_position.distance_to(Vector2(960.0, 4660.0)) < 5.0)
	assert(SaveManager.has_valid_run())
	world.free()
	assert(not SaveManager.load_run().is_empty())
	var continued_world := preload("res://game/world/world_run.tscn").instantiate() as WorldRun
	add_child(continued_world)
	for _frame in 24:
		await get_tree().process_frame
	assert(continued_world.active_layer.layer_id == &"layer_1")
	assert(continued_world.player != null and GameSession.world_manifest.sections.size() == 12)
	continued_world.free()
	SaveManager.delete_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveManager.meta_path))
	SaveManager.run_path = original_run_path
	SaveManager.meta_path = original_meta_path

func _test_invalid_position_fallback() -> void:
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	add_child(player)
	player.restore_state({"position": [INF, 2001.0], "last_safe_position": [33.0, 44.0]})
	assert(player.global_position == Vector2(33.0, 44.0))
	player.global_position = Vector2(100.0, 9000.0)
	player.recover_from_out_of_bounds()
	assert(player.global_position == Vector2(33.0, 44.0) and player.health.health == 1.0)
	player.free()
