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

class ToolProbe:
	extends StaticBody2D
	var hits := 0
	func receive_multitool(_actor: Node) -> void:
		hits += 1

func _ready() -> void:
	_test_catalog()
	_test_inventory()
	_test_weighted_throw()
	await _test_physical_inventory_drop()
	await _test_interaction_sensor()
	await _test_grounded_gate_interaction()
	_test_combat_and_status()
	_test_projectile_hit_history()
	await _test_multitool_range()
	_test_turret_projectile()
	await _test_main_menu_ui()
	_test_ui_input_and_debug()
	_test_sound()
	await _test_sight_and_sound_components()
	await _test_rope_prototype()
	_test_control_locks()
	await _test_determinism()
	_test_world_authoring_foundation()
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
	assert(ContentCatalog.get_item(&"debug_heavy_pack").weight == 12)
	assert(ContentCatalog.get_item(&"rope").weight == 8)
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
	assert(not has_w_jump)
	var has_w_climb := false
	for event in InputMap.action_get_events(&"move_up"):
		if event is InputEventKey and event.physical_keycode == KEY_W:
			has_w_climb = true
	assert(has_w_climb)

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
	assert(restored.get_total_weight() == 8)
	var protected := InventoryModel.new()
	assert(protected.try_add_item(&"multitool", 1))
	assert(protected.take_for_theft(false).is_empty())
	assert(protected.take_for_theft(true).item_id == &"multitool")
	_test_item_action_rollback_and_pickup()

func _test_weighted_throw() -> void:
	var actor := Node2D.new()
	var world := Node2D.new()
	add_child(actor)
	add_child(world)
	var rock := ContentCatalog.get_item(&"throwable_rock")
	var heavy := ContentCatalog.get_item(&"debug_heavy_pack")
	var rock_context := ItemContext.new(actor, world, Vector2(240.0, 0.0), null, rock, ItemStack.new(rock.item_id))
	var heavy_context := ItemContext.new(actor, world, Vector2(240.0, 0.0), null, heavy, ItemStack.new(heavy.item_id))
	var rock_behavior := rock.behavior as DefaultThrowBehavior
	var heavy_behavior := heavy.behavior as DefaultThrowBehavior
	assert(rock_behavior.launch_velocity(rock_context).length() > heavy_behavior.launch_velocity(heavy_context).length())
	var preview := rock_behavior.get_preview(rock_context, {})
	assert(preview.get("kind") == &"trajectory" and preview.get("points").size() > 1)
	var result := heavy_behavior.secondary(heavy_context, {})
	world.add_child(result.world_node)
	var thrown := result.world_node as ThrownItem
	assert(is_equal_approx(thrown.mass, float(heavy.weight)))
	assert(thrown.linear_velocity.is_equal_approx(heavy_behavior.launch_velocity(heavy_context)))
	actor.free()
	world.free()

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
	assert(left_thrown.global_position == anchor.global_position)
	assert(left_thrown.linear_velocity.x < 0.0)
	picker.free()
	controller.free()
	actor.free()
	world.free()

func _test_physical_inventory_drop() -> void:
	var world := Node2D.new()
	add_child(world)
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	world.add_child(player)
	assert(player.item_controller.inventory.try_add_item(&"throwable_rock"))
	assert(player.drop_inventory_slot(&"hotbar", 1))
	var dropped: ThrownItem
	for child in world.get_children():
		if child is ThrownItem:
			dropped = child
	assert(dropped != null and not dropped.freeze)
	var initial_y := dropped.global_position.y
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(dropped.global_position.y > initial_y)
	dropped.freeze = true
	assert(dropped.interact(player))
	world.free()

func _test_interaction_sensor() -> void:
	var sensor := InteractionSensor.new()
	sensor.collision_mask = 8
	add_child(sensor)
	var actor := Node2D.new()
	add_child(actor)
	var thrown := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	thrown.freeze = true
	thrown.configure(ContentCatalog.get_item(&"throwable_rock"), {}, null, Vector2(20.0, 0.0), Vector2.ZERO)
	add_child(thrown)
	var near_cursor := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	near_cursor.freeze = true
	near_cursor.configure(ContentCatalog.get_item(&"throwable_rock"), {}, null, Vector2(60.0, 0.0), Vector2.ZERO)
	add_child(near_cursor)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(sensor.best_target(actor, Vector2(72.0, 0.0)) == near_cursor)
	near_cursor.free()
	thrown.free()
	actor.free()
	sensor.free()

func _test_grounded_gate_interaction() -> void:
	var surface := preload("res://game/world/layers/surface.tscn").instantiate() as WorldLayer
	add_child(surface)
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	surface.add_child(player)
	player.global_position = Vector2(150.0, 320.0)
	var gate := surface.get_node("EnterWest") as WorldGate
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(player.interaction_sensor.best_target(player, gate.get_node("CollisionShape2D").global_position) == gate)
	player.free()
	surface.free()

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
	var second_frog := preload("res://game/enemies/test/test_amphibian.tscn").instantiate() as TestAmphibian
	add_child(player)
	add_child(frog)
	add_child(second_frog)
	player.global_position = Vector2.ZERO
	frog.global_position = Vector2(100.0, 0.0)
	second_frog.global_position = Vector2(100.0, 0.0)
	await get_tree().physics_frame
	assert(player.item_controller.primary(player, self, Vector2(120.0, -14.0)))
	await get_tree().physics_frame
	assert(frog.health.health == 20.0)
	for _frame in 24:
		await get_tree().physics_frame
	frog.global_position = player.global_position + Vector2(26.0, 0.0)
	second_frog.global_position = player.global_position + Vector2(26.0, 0.0)
	var tool_probe := ToolProbe.new()
	tool_probe.collision_layer = 4
	var tool_shape := CollisionShape2D.new()
	var tool_rectangle := RectangleShape2D.new()
	tool_rectangle.size = Vector2(12.0, 12.0)
	tool_shape.shape = tool_rectangle
	tool_probe.add_child(tool_shape)
	add_child(tool_probe)
	tool_probe.global_position = frog.global_position
	await get_tree().physics_frame
	assert(player.item_controller.primary(player, self, player.global_position + Vector2(80.0, -14.0)))
	await get_tree().physics_frame
	assert(tool_probe.hits == 1 and frog.health.health == 20.0 and second_frog.health.health == 20.0)
	tool_probe.free()
	for _frame in 24:
		await get_tree().physics_frame
	assert(player.item_controller.primary(player, self, player.global_position + Vector2(80.0, -14.0)))
	await get_tree().physics_frame
	assert(frog.health.health == 19.0)
	assert(second_frog.health.health == 19.0)
	player._set_facing(-1.0)
	assert(player.get_node("HeldItemAnchor").position.x < 0.0)
	var facing_context := player.item_controller._make_context(player, self, Vector2.LEFT * 80.0, null, ContentCatalog.get_item(&"multitool"), player.item_controller.inventory.get_active_stack())
	assert(facing_context.action_origin.x < player.global_position.x)
	player._set_facing(1.0)
	assert(player.get_node("HeldItemAnchor").position.x > 0.0)
	player.apply_force(Vector2(30.0, 0.0))
	player._physics_process(0.0)
	assert(player._knockback == Vector2.ZERO)
	frog.apply_force(Vector2(30.0, 0.0))
	frog._physics_process(0.0)
	assert(frog._knockback == Vector2.ZERO)
	assert(player.collision_mask == 1)
	assert(player.camera.target_offset_for(Vector2(320.0, 180.0), Vector2(640.0, 360.0)) == player.camera.base_offset)
	assert(player.camera.target_offset_for(Vector2(340.0, 180.0), Vector2(640.0, 360.0)) == player.camera.base_offset)
	assert(player.camera.target_offset_for(Vector2(640.0, 180.0), Vector2(640.0, 360.0)) == player.camera.base_offset + Vector2(56.0, 0.0))
	player.free()
	frog.free()
	second_frog.free()

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

func _test_main_menu_ui() -> void:
	var menu := preload("res://ui/main_menu.tscn").instantiate() as Control
	add_child(menu)
	await get_tree().process_frame
	await get_tree().process_frame
	assert(menu.background_travel_seconds > 0.0)
	assert(menu.get_node("MenuColumn").get_children().map(func(child: Node): return child.name) == [&"NewRun", &"Continue", &"Settings", &"Quit"])
	assert(menu.get_child(0).name == &"Background" and menu.get_child(1).name == &"Vignette")
	assert(menu.background.size.y > menu.size.y and menu._background_tween != null)
	assert(ProjectSettings.get_setting("gui/theme/custom") == "res://ui/game_theme.tres")
	var game_theme := load("res://ui/game_theme.tres") as Theme
	assert(game_theme.default_font.resource_path.ends_with("Perfect DOS VGA 437.ttf"))
	menu._show_settings()
	await get_tree().process_frame
	assert(menu.settings_popup.visible and not menu.settings_popup.include_resume)
	assert(absf(menu.settings_popup.card.get_global_rect().get_center().x - menu.get_global_rect().get_center().x) < 0.1)
	assert(not menu.settings_popup.get_node("Card/MenuPage/MenuColumn/EntryResume").visible)
	assert(not menu.settings_popup.get_node("Card/MenuPage/MenuColumn/EntryMainAction").visible)
	assert(menu.settings_popup.get_node("Card/CloseButton") is TextureButton)
	assert(menu.settings_popup.find_child("Back", true, false) == null)
	menu.settings_popup.close_button.pressed.emit()
	assert(not menu.settings_popup.visible)
	menu._show_new_run_confirmation()
	assert(menu.confirmation_popup.visible)
	assert(absf(menu.confirmation_popup.card.get_global_rect().get_center().x - menu.get_global_rect().get_center().x) < 32.0)
	assert(menu.find_children("*", "ConfirmationDialog", true, false).is_empty())
	menu.free()

func _test_ui_input_and_debug() -> void:
	var original_debug_enabled := GameSession.debug_enabled
	var original_unlimited_health := GameSession.debug_unlimited_health
	GameSession.debug_enabled = false
	GameSession.debug_unlimited_health = false
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	var hud := preload("res://ui/foundation_hud.tscn").instantiate() as FoundationHUD
	add_child(player)
	add_child(hud)
	hud.set_player(player)
	assert(hud.hotbar_labels[0].text.contains("Multitool"))
	assert(hud.get_node("LogicalUI/Hotbar").get_child(0) == hud.whistle_button)
	assert(hud.whistle_button is TextureButton and hud.whistle_button.focus_mode == Control.FOCUS_NONE)
	assert(hud.whistle_icon.texture != null)
	for display_index in hud.hotbar_slots.size():
		var click_target := hud.hotbar_slots[display_index].get_node("ClickTarget") as Button
		click_target.pressed.emit()
		assert(player.item_controller.inventory.active_hotbar_index == hud.hotbar_indices[display_index])
	assert(not hud.health_label.visible and not hud.money_label.visible and not hud.weight_label.visible and not hud.location_label.visible)
	player.health.set_health(0.4)
	assert(hud.health_label.text == "HP 1/100")
	assert(hud.get_node("LogicalUI/HealthFlames").tooltip_text == "HP 1/100")
	assert(hud.health_value_tooltip.text == "HP 1/100")
	hud._finish_hotbar_layout()
	assert(hud.hotbar_arrow.visible)
	player.apply_status(&"healing", {"duration": 12.2})
	hud._process(0.1)
	assert(hud.status_label.text.contains("Healing 13s"))
	player.apply_status(&"resin_bound", {"provider_id": "hud_test", "duration": 20.0})
	hud._process(0.1)
	assert(hud.status_label.text.contains("Resin Bound — active"))
	player.status.remove_status(&"healing")
	player.status.remove_status(&"resin_bound")
	player.set_inventory_open(true)
	assert(hud.inventory_menu.visible and hud.inventory_menu.slot_buttons.size() == 7)
	assert(String(hud.inventory_menu.slot_buttons[0].get_path()).contains("HotbarSlots"))
	(hud.inventory_menu.get_node("BookContent/SubmenuButton") as Button).pressed.emit()
	assert((hud.inventory_menu.get_node("BookContent/Submenu") as Control).visible)
	hud._slot_pressed(0)
	assert(hud.inventory_menu.item_name.text == "Multitool")
	var inventory_event := InputEventAction.new()
	inventory_event.action = &"inventory"
	inventory_event.pressed = true
	hud._input(inventory_event)
	assert(not player.inventory_open and not hud.inventory_menu.visible and hud._selected_index == -1)
	player.set_inventory_open(true)
	assert(is_equal_approx(hud.inventory_menu.book_open_seconds, 0.5))
	hud.inventory_menu.close_button.pressed.emit()
	assert(not player.inventory_open and not hud.inventory_menu.visible)
	player.set_inventory_open(true)
	var pause_event := InputEventAction.new()
	pause_event.action = &"pause"
	pause_event.pressed = true
	hud._input(pause_event)
	assert(not player.inventory_open and not get_tree().paused)
	hud._input(pause_event)
	assert(get_tree().paused)
	assert(hud.pause_panel.visible and hud.pause_panel.include_resume)
	var pause_quit_label := hud.pause_panel.get_node("Card/MenuPage/MenuColumn/EntryMainAction/Label") as TextureRect
	assert(pause_quit_label.texture.resource_path.ends_with("main_menu/quit.png"))
	hud._input(pause_event)
	assert(not get_tree().paused)
	var debug_event := InputEventAction.new()
	debug_event.action = &"debug_toggle"
	debug_event.pressed = true
	hud._input(debug_event)
	assert(hud.debug_panel.visible and hud.health_label.visible and hud.money_label.visible and hud.weight_label.visible and hud.location_label.visible)
	hud._update_performance()
	hud._process(0.0)
	assert(not hud.performance_label.text.is_empty() and hud.crosshair != null)
	assert(hud.location_label.text.contains("X") and hud.location_label.text.contains("Y"))
	var debug_end := hud.debug_panel.position + hud.debug_panel.size
	var log_end := hud.world_log_panel.position + hud.world_log_panel.size
	assert(debug_end.x <= 640.0 and debug_end.y <= 360.0)
	assert(log_end.x <= 640.0 and log_end.y <= 360.0)
	hud.unlimited_health_toggle.button_pressed = true
	assert(GameSession.debug_unlimited_health and hud.health_label.text == "HP ∞")
	assert(not player.apply_damage(DamageInfo.new(10.0)) and player.health.health == player.health.max_health)
	hud.unlimited_health_toggle.button_pressed = false
	assert(player.apply_damage(DamageInfo.new(10.0)) and player.health.health < player.health.max_health)
	hud.world_log_panel.visible = true
	get_tree().paused = true
	hud._input(pause_event)
	assert(not hud.world_log_panel.visible and get_tree().paused)
	var close_buttons := hud.world_log_panel.find_children("*", "Button", true, false)
	assert(close_buttons.size() == 1)
	var close_button := close_buttons[0] as Button
	assert(close_button.text == "Close")
	hud.world_log_panel.visible = true
	close_button.pressed.emit()
	assert(not hud.world_log_panel.visible)
	get_tree().paused = false
	var dialogue := ContentCatalog.get_dialogue(&"foundation_intro")
	hud.show_dialogue(dialogue)
	assert(hud.dialogue_box.visible and not player.locks.is_locked())
	var inventory_event := InputEventAction.new()
	inventory_event.action = &"inventory"
	inventory_event.pressed = true
	hud._input(inventory_event)
	assert(not player.inventory_open)
	var cancel_dialogue_event := InputEventAction.new()
	cancel_dialogue_event.action = &"ui_cancel"
	cancel_dialogue_event.pressed = true
	hud._input(cancel_dialogue_event)
	assert(not hud.dialogue_box.visible and not hud.dialogue_controller.is_active())
	hud.show_dialogue(dialogue)
	var interact_event := InputEventAction.new()
	interact_event.action = &"interact"
	interact_event.pressed = true
	hud.dialogue_box._input(interact_event)
	assert(hud.dialogue_controller.is_active() and not hud.dialogue_box._typing)
	hud.dialogue_box._input(interact_event)
	assert(hud.dialogue_controller.is_active() and hud.dialogue_box._typing)
	hud.dialogue_box._input(interact_event)
	hud.dialogue_box._input(interact_event)
	assert(not hud.dialogue_box.visible and not player.locks.is_locked())
	var choice_sequence := DialogueSequence.new()
	var choice_step := DialogueStep.new()
	choice_step.type = DialogueStep.Type.CHOICE
	var choice := DialogueChoice.new()
	choice.label = "Set dialogue smoke flag"
	var action := DialogueAction.new()
	action.type = DialogueAction.Type.SET_FLAG
	action.flag_id = &"dialogue_smoke_choice"
	choice.actions.append(action)
	choice_step.choices.append(choice)
	choice_sequence.steps.append(choice_step)
	hud.show_dialogue(choice_sequence)
	assert(hud.dialogue_box.visible and not player.locks.is_locked())
	(hud.dialogue_box._choices.get_child(0) as Button).pressed.emit()
	assert(bool(GameSession.progression_flags.get("dialogue_smoke_choice", false)) and not hud.dialogue_controller.is_active() and not player.locks.is_locked())
	GameSession.progression_flags.erase("dialogue_smoke_choice")
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
	assert(player.get_node("AnimatedSprite2D").animation == &"idle" and player.get_node("AnimatedSprite2D").frame == 0 and not player.get_node("AnimatedSprite2D").is_playing())
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
	GameSession.debug_enabled = original_debug_enabled
	GameSession.debug_unlimited_health = original_unlimited_health

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

func _test_sight_and_sound_components() -> void:
	var owner := Node2D.new()
	var listener := SoundListener.new()
	owner.add_child(listener)
	add_child(owner)
	listener.minimum_priority = 1
	var source := Node2D.new()
	add_child(source)
	var accepted_direct := [false]
	listener.sound_accepted.connect(func(_event: SoundEvent, direct: bool): accepted_direct[0] = direct)
	listener.hear_sound(SoundEvent.new(Vector2.ZERO, 100.0, &"quiet", 0, source))
	assert(listener.current_event == null)
	for index in 3:
		var event := SoundEvent.new(Vector2.ZERO, 100.0, &"step", 1, source)
		event.timestamp += index
		listener.hear_sound(event)
	assert(listener.direct_target and accepted_direct[0])
	var lower := SoundEvent.new(Vector2.ZERO, 100.0, &"lower", 0, source)
	listener.hear_sound(lower)
	assert(listener.current_event.sound_type == &"step")

	var sensor_owner := Node2D.new()
	var sensor := SightSensor.new()
	sensor_owner.add_child(sensor)
	add_child(sensor_owner)
	var target := Node2D.new()
	target.add_to_group(&"detection_producers")
	add_child(target)
	target.global_position = Vector2(80.0, 0.0)
	sensor.facing = Vector2.RIGHT
	assert(sensor.can_see(target))
	sensor.facing = Vector2.LEFT
	assert(not sensor.can_see(target))
	sensor.aggravated = true
	sensor.aggravated_angle_degrees = 360.0
	assert(sensor.can_see(target))
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8.0, 80.0)
	wall_shape.shape = rectangle
	wall.add_child(wall_shape)
	add_child(wall)
	wall.global_position = Vector2(40.0, 0.0)
	await get_tree().physics_frame
	assert(not sensor.can_see(target))
	owner.free()
	source.free()
	sensor_owner.free()
	target.free()
	wall.free()

func _test_rope_prototype() -> void:
	var world := Node2D.new()
	add_child(world)
	var player := preload("res://game/player/player.tscn").instantiate() as PlayerController
	world.add_child(player)
	var anchor := Node2D.new()
	anchor.add_to_group(&"rope_anchors")
	world.add_child(anchor)
	anchor.global_position = Vector2(24.0, 0.0)
	assert(player.item_controller.inventory.try_add_item(&"rope"))
	player.item_controller.inventory.select_hotbar(1)
	var rope_definition := ContentCatalog.get_item(&"rope")
	var rope_behavior := rope_definition.behavior as RopeBehavior
	var context := ItemContext.new(player, world, anchor.global_position, null, rope_definition, ItemStack.new(&"rope"))
	context.world_bounds = Rect2(-50.0, -20.0, 150.0, 100.0)
	assert(not rope_behavior.find_placement(context).valid)
	context.world_bounds = Rect2()
	assert(rope_behavior.find_placement(context).valid)
	var preview := player.item_controller.get_preview(player, world, anchor.global_position)
	assert(preview.get("kind") == &"rope" and preview.get("trajectory", PackedVector2Array()).size() > 1)
	assert(player.item_controller.primary(player, world, anchor.global_position))
	assert(player.item_controller.inventory.get_active_stack().is_empty())
	var rope: PlacedRope
	for child in world.get_children():
		if child is PlacedRope:
			rope = child
	assert(rope != null and is_equal_approx(rope.rope_length, 160.0))
	assert(rope.is_in_group(&"persistent_objects"))
	var rope_shape := rope.get_child(-1) as CollisionShape2D
	assert((rope_shape.shape as RectangleShape2D).size.x == 24.0)
	assert((rope.get_child(0) as Sprite2D).scale.x == 0.5)
	assert((rope.get_child(1) as Sprite2D).position.y - (rope.get_child(0) as Sprite2D).position.y == 14.0)
	assert((player.get_node("CollisionShape2D").shape as CapsuleShape2D).radius == 6.0)
	assert(player.item_controller.inventory.try_add_item(&"rope"))
	var extension_context := ItemContext.new(player, world, rope.global_position, null, rope_definition, ItemStack.new(&"rope"))
	extension_context.world_bounds = Rect2(-50.0, -20.0, 150.0, 200.0)
	assert(not rope_behavior.find_placement(extension_context).valid)
	assert(player.item_controller.primary(player, world, rope.global_position))
	var rope_count := 0
	var extension: PlacedRope
	for child in world.get_children():
		if child is PlacedRope:
			rope_count += 1
			if child != rope:
				extension = child
	assert(rope_count == 2 and extension.get_chain_root() == rope and rope.get_chain_bottom() == 320.0)
	assert(rope._end_sprite.texture == PlacedRope.SEGMENT_TEXTURE)
	assert(extension._end_sprite.texture == PlacedRope.END_TEXTURE)
	assert(not rope.persistent_id.is_empty() and rope.is_in_group(&"persistent_objects"))
	assert(extension.persistent_id.is_empty() and not extension.is_in_group(&"persistent_objects"))
	var rope_state := rope.capture_state()
	assert(rope_state.position == [24.0, 0.0] and rope_state.segment_lengths == [160.0, 160.0])
	var restored_rope := preload("res://game/items/world/placed_rope.tscn").instantiate() as PlacedRope
	restored_rope.persistent_id = "smoke_restored_rope"
	world.add_child(restored_rope)
	restored_rope.restore_state(rope_state)
	assert(restored_rope._get_chain_members().size() == 2 and restored_rope.get_chain_bottom() == 320.0)
	restored_rope.restore_state(rope_state)
	assert(restored_rope._get_chain_members().size() == 2)
	var restored_extension := preload("res://game/items/world/placed_rope.tscn").instantiate() as PlacedRope
	restored_extension.configure(Vector2(24.0, restored_rope.get_chain_bottom()), 16.0, restored_rope)
	world.add_child(restored_extension)
	assert(restored_rope.capture_state().segment_lengths == [160.0, 160.0, 16.0])
	for restored_piece in restored_rope._get_chain_members():
		restored_piece.free()
	player.global_position = rope.global_position + Vector2(0.0, 32.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(rope in player._nearby_ropes)
	Input.action_press(&"move_up")
	player._try_begin_climb(true)
	Input.action_release(&"move_up")
	assert(player.is_climbing())
	player.last_safe_position = Vector2(12.0, 34.0)
	assert(player.capture_state().position == [12.0, 34.0])
	var before_climb_y := player.global_position.y
	var before_climb_x := player.global_position.x
	Input.action_press(&"move_right")
	Input.action_press(&"move_down")
	player._physics_climb(0.1, true)
	Input.action_release(&"move_down")
	Input.action_release(&"move_right")
	assert(player.global_position.y > before_climb_y)
	assert(player.global_position.x > before_climb_x and player._rope_lateral_offset > 0.0)
	player.global_position.y = rope.bottom_y() - 1.0
	Input.action_press(&"move_down")
	player._physics_climb(0.1, true)
	Input.action_release(&"move_down")
	assert(player.is_climbing() and player.global_position.y > rope.bottom_y())
	player.unregister_climbable(rope)
	assert(player.is_climbing())
	player.global_position.y = rope.get_chain_bottom()
	Input.action_press(&"move_down")
	player._physics_climb(0.1, true)
	Input.action_release(&"move_down")
	assert(player.is_climbing() and player.global_position.y == rope.get_chain_bottom() and player.velocity.y == 0.0)
	player.global_position.y = rope.get_chain_top()
	Input.action_press(&"move_up")
	player._physics_climb(0.1, true)
	Input.action_release(&"move_up")
	assert(player.is_climbing() and player.global_position.y == rope.get_chain_top() and player.velocity.y == 0.0)
	player.item_controller.inventory.select_hotbar(0)
	assert(player.item_controller.primary(player, world, player.global_position + Vector2.RIGHT * 40.0))
	assert(is_instance_valid(player.item_controller.prepared_item))
	player.item_controller.cancel_prepared()
	Input.action_press(&"move_right")
	player._jump_from_rope()
	Input.action_release(&"move_right")
	assert(not player.is_climbing() and player.velocity.x > 0.0 and player.velocity.y < 0.0)
	player._climbing_rope = rope
	Input.action_press(&"move_up")
	player.apply_force(Vector2.RIGHT * 10.0)
	assert(not player.is_climbing())
	player._try_begin_climb(true)
	Input.action_release(&"move_up")
	assert(not player.is_climbing())
	world.free()

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
	assert(not first_manifest.placers.is_empty())
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

func _test_world_authoring_foundation() -> void:
	var surface := preload("res://game/world/layers/surface.tscn").instantiate() as WorldLayer
	assert(surface.spawn_position(&"west", &"", true) == surface.initial_spawn.global_position)
	assert(surface.spawn_position(&"west") == surface.west_spawn.global_position)
	surface.free()
	var layer2 := preload("res://game/world/layers/layer_2.tscn").instantiate() as WorldLayer
	assert(layer2.get_node("ShopCombatSafeZone") is CombatSafeZone)
	assert((layer2.get_node("ShopEnemyBoundary") as StaticBody2D).collision_layer == 512)
	assert(layer2.get_node("Layer2Gatekeeper") is Layer2Gatekeeper and layer2.get_node("SkyHunterFlock") is SkyHunterFlock)
	layer2.free()
	var section := preload("res://game/world/test/section_a.tscn").instantiate() as WorldSection
	add_child(section)
	section.respawn_anchor.position = Vector2(100.0, 300.0)
	assert(section.validate().is_empty())
	section.respawn_anchor.position = Vector2(-1.0, 300.0)
	assert(not section.validate().is_empty())
	section.free()

	var enemy_placer := preload("res://game/world/placers/enemy_placer.tscn").instantiate() as DeterministicPlacer
	enemy_placer.persistent_id = &"smoke_enemy_placer"
	assert(enemy_placer.validate().is_empty())
	assert(enemy_placer.resolve(10).size() == 1)
	enemy_placer.free()
	var layer2_placer := preload("res://game/world/placers/layer2_enemy_placer.tscn").instantiate() as DeterministicPlacer
	layer2_placer.persistent_id = &"smoke_layer2_group"
	layer2_placer.entries = [layer2_placer.entries[0]]
	add_child(layer2_placer)
	assert(layer2_placer.validate().is_empty() and layer2_placer.resolve(10).size() == 1)
	var layer2_spawn_root := Node2D.new()
	add_child(layer2_spawn_root)
	layer2_placer.spawn_resolved(layer2_spawn_root)
	var primate := layer2_spawn_root.get_child(0) as CanopyPrimate
	assert(primate != null and primate.spawn_group_id == &"smoke_layer2_group")
	layer2_spawn_root.free()
	layer2_placer.free()
	for path in ["res://game/world/placers/plate_umbrella_placer.tscn", "res://game/world/placers/lacerator_placer.tscn", "res://game/world/placers/resonance_core_placer.tscn"]:
		var relic_placer := (load(path) as PackedScene).instantiate() as DeterministicPlacer
		relic_placer.persistent_id = StringName("smoke_%s" % relic_placer.name)
		assert(relic_placer.required_allocation and not relic_placer.allocation_group.is_empty() and relic_placer.validate().is_empty())
		relic_placer.free()
	var loot_placer := preload("res://game/world/placers/loot_placer.tscn").instantiate() as DeterministicPlacer
	loot_placer.persistent_id = &"smoke_loot_placer"
	add_child(loot_placer)
	assert(loot_placer.validate().is_empty())
	assert(loot_placer.resolve(10).size() == 1)
	loot_placer.minimum_quantity = 3
	loot_placer.maximum_quantity = 3
	var multi_loot := loot_placer.resolve(10)
	var multi_ids := {}
	for result in multi_loot:
		multi_ids[result.persistent_id] = true
	assert(multi_loot.size() == 3 and multi_ids.size() == 3)

	var drop_root := Node2D.new()
	add_child(drop_root)
	loot_placer.spawn_resolved(drop_root)
	var breakable := drop_root.get_child(0) as BreakableLoot
	assert(breakable != null and breakable.item_id == &"multitool")
	assert(breakable.apply_damage(DamageInfo.new(1.0)))
	assert(not breakable.is_queued_for_deletion())
	assert(breakable.apply_damage(DamageInfo.new(1.0)))
	await get_tree().process_frame
	var dropped_ids: Dictionary = {}
	for child in drop_root.get_children():
		if child is WorldItem:
			dropped_ids[child.item_id] = true
			assert(child.is_in_group(&"interactables") and not child is RigidBody2D)
	assert(dropped_ids.has(&"throwable_rock") and dropped_ids.has(&"multitool"))
	assert(dropped_ids.size() == 2)
	SaveManager.destroyed_ids.erase("smoke_loot_placer:0")
	drop_root.free()
	loot_placer.free()

	var moving := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	moving.configure(ContentCatalog.get_item(&"throwable_rock"), {}, null, Vector2(10.0, 20.0), Vector2(30.0, -40.0))
	add_child(moving)
	moving.rotation = 0.5
	moving.angular_velocity = 1.25
	var state := moving.capture_state()
	var restored := preload("res://game/items/world/thrown_item.tscn").instantiate() as ThrownItem
	add_child(restored)
	restored.restore_state(state)
	assert(restored.global_position == Vector2(10.0, 20.0))
	assert(restored.linear_velocity == Vector2(30.0, -40.0))
	assert(is_equal_approx(restored.rotation, 0.5))
	assert(is_equal_approx(restored.angular_velocity, 1.25))
	assert(not restored.freeze and not restored.is_in_group(&"interactables"))
	moving.free()
	restored.free()

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
	var prologue := preload("res://game/story/prologue/prologue.tscn").instantiate()
	assert(prologue.dialogue_sequence is DialogueSequence)
	prologue.free()
	var room := preload("res://game/world/foundation_test_room.tscn").instantiate()
	assert(room != null)
	assert(room.test_curse_layer == "None")
	assert(room.get_node("Ground").position == Vector2(320.0, 344.0))
	assert((room.get_node("Ground/CollisionShape2D").shape as RectangleShape2D).size == Vector2(640.0, 32.0))
	assert(room.get_node("LeftWall").position == Vector2(0.0, 180.0))
	assert(room.get_node("RightWall").position == Vector2(640.0, 180.0))
	assert(not room.has_node("Background"))
	assert(not room.has_node("Platform") and not room.has_node("TestShopTerminal"))
	assert(not room.has_node("RockPickup") and not room.has_node("BreakableLoot"))
	assert(not room.has_node("TestAmphibian") and not room.has_node("ProjectileTurret"))
	room.free()
	var world_run := preload("res://game/world/world_run.tscn").instantiate()
	assert(world_run != null)
	world_run.free()
	var section := preload("res://game/world/sections/graybox_section_base.tscn").instantiate() as WorldSection
	assert(section.section_size == Vector2(1280.0, 800.0))
	assert(section.entry_anchor.position == Vector2(640.0, 0.0))
	assert(section.exit_anchor.position == Vector2(640.0, 800.0))
	assert(section.respawn_anchor.position == Vector2(640.0, 64.0))
	assert(section.get_node("Terrain") is TileMapLayer)
	assert(not section.has_node("AuthoredContent/Traversal"))
	section.free()
	var surface := preload("res://game/world/layers/surface.tscn").instantiate()
	var surface_ids: Dictionary = {}
	for child in surface.get_children():
		if child is TestAmphibian:
			surface_ids[child.persistent_id] = true
	assert(surface_ids.is_empty())
	surface.free()

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
	assert(world.active_layer.world_bounds == Rect2(0.0, 0.0, 2560.0, 2400.0))
	assert(world.player.global_position.distance_to(world.active_layer.east_spawn.global_position) < 5.0)
	world._process(0.21)
	assert(world.active_layer.active_slot_ids.has("layer1_east_01"))
	assert(world.active_layer.active_slot_ids.has("layer1_east_02"))
	assert(world.player.camera.limit_left == 1280 and world.player.camera.limit_right == 2560)
	assert(world.player.camera.limit_top == 0 and world.player.camera.limit_bottom == 2400)
	var rope_scene := preload("res://game/items/world/placed_rope.tscn")
	var saved_rope := rope_scene.instantiate() as PlacedRope
	saved_rope.configure(Vector2(1920.0, 760.0), 160.0)
	world.active_layer.runtime_root.add_child(saved_rope)
	var saved_rope_id := saved_rope.persistent_id
	var saved_extension := rope_scene.instantiate() as PlacedRope
	saved_extension.configure(Vector2(1920.0, 920.0), 96.0, saved_rope)
	world.active_layer.runtime_root.add_child(saved_extension)
	assert(not saved_rope_id.is_empty() and saved_rope.get_chain_bottom() == 1016.0)
	world.player.global_position = Vector2(1920.0, 810.0)
	world._process(0.21)
	assert(world.player.camera.limit_top == 0 and world.player.camera.limit_bottom == 2400)
	assert(world.player.last_safe_position == Vector2(1920.0, 864.0))
	world.player.health.set_health(20.0)
	world.player.global_position = Vector2(1920.0, 2600.0)
	world._process(0.21)
	assert(world.player.global_position == Vector2(1920.0, 864.0) and world.player.health.health == 1.0)
	world.player.global_position = Vector2(1920.0, 1610.0)
	world._process(0.21)
	assert(world.player.camera.limit_left == 0 and world.player.camera.limit_right == 2560)
	await world.request_layer_transition(&"layer_2", &"east")
	assert(world.active_layer.layer_id == &"layer_2")
	await world.request_layer_transition(&"layer_1", &"east", &"EastBottomSpawn")
	assert(world.player.global_position.distance_to(Vector2(1920.0, 2260.0)) < 5.0)
	var returned_rope: PlacedRope
	for child in world.active_layer.runtime_root.get_children():
		if child is PlacedRope and child.persistent_id == saved_rope_id:
			returned_rope = child
	assert(returned_rope != null and returned_rope._get_chain_members().size() == 2)
	assert(returned_rope.capture_state().segment_lengths == [160.0, 96.0])
	assert(returned_rope._end_sprite.texture == PlacedRope.SEGMENT_TEXTURE)
	world.player.global_position = returned_rope.global_position + Vector2(0.0, 32.0)
	world.player.set_last_safe_position(Vector2(1920.0, 2260.0))
	world.player.register_climbable(returned_rope)
	Input.action_press(&"move_up")
	world.player._try_begin_climb(true)
	Input.action_release(&"move_up")
	assert(world.player.is_climbing())
	assert(SaveManager.save_run())
	assert(SaveManager.has_valid_run())
	world.free()
	assert(not SaveManager.load_run().is_empty())
	assert(SaveManager.loaded_persistent_state.player.position == [1920.0, 2260.0])
	var continued_world := preload("res://game/world/world_run.tscn").instantiate() as WorldRun
	add_child(continued_world)
	for _frame in 24:
		await get_tree().process_frame
	assert(continued_world.active_layer.layer_id == &"layer_1")
	assert(continued_world.player != null and GameSession.world_manifest.sections.size() == 12)
	assert(not continued_world.player.is_climbing())
	assert(continued_world.player.global_position.distance_to(Vector2(1920.0, 2260.0)) < 24.0)
	var continued_rope: PlacedRope
	for child in continued_world.active_layer.runtime_root.get_children():
		if child is PlacedRope and child.persistent_id == saved_rope_id:
			continued_rope = child
	assert(continued_rope != null and continued_rope.get_chain_bottom() == 1016.0)
	SaveManager.restore_registered_objects(&"layer_1")
	assert(continued_rope._get_chain_members().size() == 2)
	var new_rope := rope_scene.instantiate() as PlacedRope
	new_rope.configure(Vector2(1800.0, 1200.0), 16.0)
	continued_world.active_layer.runtime_root.add_child(new_rope)
	assert(not new_rope.persistent_id.is_empty() and new_rope.persistent_id != saved_rope_id)
	new_rope.free()
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
