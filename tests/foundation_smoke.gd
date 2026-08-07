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
	_test_combat_and_status()
	_test_projectile_hit_history()
	_test_sound()
	_test_control_locks()
	_test_determinism()
	_test_shop()
	_test_prepared_item()
	_test_save()
	_test_room_loads()
	_test_invalid_position_fallback()
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
	var world := Node2D.new()
	add_child(actor)
	add_child(world)
	add_child(controller)
	assert(controller.inventory.try_add_item(&"throwable_rock"))
	var failed_result := ItemActionResult.completed(2)
	failed_result.world_node = Node2D.new()
	assert(not controller._commit_result(failed_result, world))
	assert(controller.inventory.get_active_stack().quantity == 1)
	assert(failed_result.world_node.is_queued_for_deletion())
	assert(controller.secondary(actor, world, actor.global_position + Vector2.RIGHT * 100.0))
	assert(controller.inventory.get_active_stack().is_empty())
	var thrown: ThrownItem
	for child in world.get_children():
		if child is ThrownItem and not child.is_queued_for_deletion():
			thrown = child
	assert(thrown != null)
	thrown.freeze = true
	var picker := PickupProbe.new()
	assert(thrown.interact(picker))
	assert(picker.inventory.get_active_stack().quantity == 1)
	picker.free()
	controller.free()
	actor.free()
	world.free()

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

func _test_sound() -> void:
	var probe := SoundProbe.new()
	probe.add_to_group(&"sound_listeners")
	add_child(probe)
	SoundBus.emit_sound(get_tree(), SoundEvent.new(Vector2.ZERO, 10.0, &"test", 1))
	assert(probe.received == 1)
	SoundBus.emit_sound(get_tree(), SoundEvent.new(Vector2(100.0, 0.0), 10.0, &"test", 1))
	assert(probe.received == 1)
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
	placer.scene_pool = [preload("res://game/items/world/world_item.tscn")]
	placer.minimum_quantity = 2
	placer.maximum_quantity = 2
	var first := placer.resolve(12345)
	var second := placer.resolve(12345)
	assert(first == second and first.size() == 2)
	var section := preload("res://game/world/test/section_a.tscn").instantiate() as WorldSection
	add_child(section)
	assert(section.validate().is_empty())
	section.queue_free()
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

func _test_invalid_position_fallback() -> void:
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	add_child(player)
	player.restore_state({"position": [0.0, 2001.0], "last_safe_position": [33.0, 44.0]})
	assert(player.global_position == Vector2(33.0, 44.0))
	player.free()
