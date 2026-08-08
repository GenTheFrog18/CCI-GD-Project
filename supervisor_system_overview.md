# Supervisor System Overview

This document explains the systems currently implemented in the runnable Godot prototype. The project deliberately uses placeholder visuals so programming, level design, saving, and content production can continue before final art is ready.

## 1. Runtime flow

1. Godot opens the main menu.
2. **New Run** creates a run seed and clears previous run state. **Continue** loads the saved run.
3. `WorldGenerator` uses the seed to select authored section variations and resolve enemy/loot placers.
4. `WorldRun` instantiates the active layer, restores persistent objects, creates the player, and enables nearby sections.
5. The player explores, uses items, fights enemies, enters shops, and moves between layers through authored gates.
6. Save data records the run manifest, player, inventory, enemies, dropped items, destroyed objects, money, and progression.

The generator does **not** draw terrain procedurally. Designers create terrain manually; generation selects between those authored variations. This keeps layouts intentional while still making each run reproducible from a seed.

## 2. Project startup and global services

Primary files:

- [`project.godot`](../project.godot)
- [`autoload/game_session.gd`](../autoload/game_session.gd)
- [`autoload/content_catalog.gd`](../autoload/content_catalog.gd)
- [`autoload/save_manager.gd`](../autoload/save_manager.gd)
- [`autoload/scene_router.gd`](../autoload/scene_router.gd)
- [`ui/main_menu.gd`](../ui/main_menu.gd)

Four Autoloads provide services shared by every scene:

- `GameSession`: current seed, money, layer, route, progression, and world manifest.
- `ContentCatalog`: loads data Resources and provides stable-ID lookup.
- `SaveManager`: writes and restores persistent state.
- `SceneRouter`: changes scenes through a short fade transition.

```ini
[autoload]

ContentCatalog="*res://autoload/content_catalog.gd"
GameSession="*res://autoload/game_session.gd"
SaveManager="*res://autoload/save_manager.gd"
SceneRouter="*res://autoload/scene_router.gd"
```

Starting a run resets run-specific state but keeps meta knowledge separate:

```gdscript
func start_new_run(seed_value := 0, enable_debug := false) -> void:
	run_seed = seed_value if seed_value != 0 else randi()
	money = STARTING_MONEY
	world_manifest.clear()
	current_layer_id = &"surface"
	run_started.emit()
```

## 3. Data-driven content

Primary files:

- [`autoload/content_catalog.gd`](../autoload/content_catalog.gd)
- [`data/definitions/item_definition.gd`](../data/definitions/item_definition.gd)
- [`data/definitions/enemy_definition.gd`](../data/definitions/enemy_definition.gd)
- [`data/definitions/effect_definition.gd`](../data/definitions/effect_definition.gd)
- [`data/definitions/shop_definition.gd`](../data/definitions/shop_definition.gd)
- Content Resources under [`data/`](../data/)

Items, enemies, effects, shops, and dialogue use `.tres` Resources instead of hard-coded lists. `ContentCatalog` scans the data folders, validates stable IDs, and rejects duplicates. New content can therefore be added without editing the catalog itself.

```gdscript
func get_item(item_id: StringName) -> ItemDefinition:
	return items.get(item_id) as ItemDefinition

func get_enemy(enemy_id: StringName) -> EnemyDefinition:
	return enemies.get(enemy_id) as EnemyDefinition
```

## 4. Player movement, camera, and control locks

Primary files:

- [`game/player/player.gd`](../game/player/player.gd)
- [`game/player/player.tscn`](../game/player/player.tscn)
- [`core/control/control_locks.gd`](../core/control/control_locks.gd)

The player is a `CharacterBody2D`. Movement uses acceleration and deceleration, gravity, jumping, knockback, fall tracking, and status-effect multipliers. The camera follows the mouse slightly while remaining inside layer limits.

Control locks are named reasons such as `death`, `dialogue`, or `world_transition`. Multiple systems can lock control safely without accidentally unlocking each other.

```gdscript
var axis := Input.get_axis(&"move_left", &"move_right") if can_control else 0.0
var target_speed := axis * move_speed * status.get_multiplier(&"move_speed")
velocity.x = move_toward(velocity.x, target_speed, rate * delta)

if can_control and Input.is_action_just_pressed(&"jump") and is_on_floor():
	velocity.y = jump_velocity
```

Current controls:

- `A`/`D` or arrows: move
- `Space`/`W`: jump
- `E`: interact or pick up
- Left mouse: primary item action
- Right mouse: secondary item action
- `1`/`2` or mouse wheel: select hotbar
- `Tab`: inventory
- `Esc`: pause
- `F3`: debug panel

## 5. Interaction system

Primary files:

- [`core/interaction/interaction_sensor.gd`](../core/interaction/interaction_sensor.gd)
- [`game/player/player.gd`](../game/player/player.gd)

An `Area2D` sensor gathers nearby bodies and areas. Any object implementing `interact(actor)` can participate. When several objects overlap, `interaction_priority` selects the most important target, allowing shops and gates to take priority over ordinary pickups.

```gdscript
for candidate in candidates:
	if not candidate.has_method("interact"):
		continue
	var priority_value = candidate.get("interaction_priority")
	var priority := float(priority_value) if priority_value != null else 0.0
	if priority > best_priority:
		best_priority = priority
		best = candidate
```

This avoids coupling the player to every shop, gate, item, or future NPC class.

## 6. Inventory and item actions

Primary files:

- [`core/items/inventory_model.gd`](../core/items/inventory_model.gd)
- [`core/items/item_stack.gd`](../core/items/item_stack.gd)
- [`game/items/player_item_controller.gd`](../game/items/player_item_controller.gd)
- [`data/definitions/item_definition.gd`](../data/definitions/item_definition.gd)
- Item behaviors under [`game/items/behaviors/`](../game/items/behaviors/)

The inventory contains two hotbar slots and five backpack slots. `InventoryModel` owns stacking, capacity checks, swapping, consuming, dropping, and serialization. UI only displays and requests changes from this model.

Each `ItemDefinition` points to an `ItemBehavior`. `PlayerItemController` creates an `ItemContext`, asks the behavior whether an action is allowed, runs it, then commits consumption or world-spawn results.

```gdscript
var behavior := definition.behavior
var allowed := behavior.can_secondary(context, stack.state) \
	if is_secondary else behavior.can_primary(context, stack.state)
var result := behavior.secondary(context, stack.state) \
	if is_secondary else behavior.primary(context, stack.state)
return _commit_result(result, world)
```

This means adding an item normally requires a Resource plus a behavior, not changes to player code.

## 7. Multitool and throwable items

Primary files:

- [`game/items/behaviors/multitool_behavior.gd`](../game/items/behaviors/multitool_behavior.gd)
- [`game/items/behaviors/default_throw_behavior.gd`](../game/items/behaviors/default_throw_behavior.gd)
- [`game/items/world/thrown_item.gd`](../game/items/world/thrown_item.gd)
- [`data/items/multitool.tres`](../data/items/multitool.tres)
- [`data/items/throwable_rock.tres`](../data/items/throwable_rock.tres)

The Multitool performs a short raycast toward the cursor. It first supports special tool interactions, then falls back to shared damage and force APIs.

```gdscript
if target != null and target.has_method("apply_damage"):
	target.apply_damage(DamageInfo.new(damage, context.actor, &"player"))
	if target.has_method("apply_force"):
		target.apply_force(direction * force)
```

Throwable items become `RigidBody2D` objects. Throw speed depends on cursor distance. An impact carries damage, mass, velocity, force, source actor, and species. When the object remains slow for a short time, it freezes and becomes pickupable.

```gdscript
if linear_velocity.length() <= stop_speed:
	_still_time += delta
	if _still_time >= stop_seconds:
		freeze = true
		add_to_group(&"interactables")
```

Position, rotation, linear velocity, angular velocity, and frozen state are saved. An airborne rock therefore continues moving after Continue instead of remaining suspended.

## 8. Combat, health, force, and status effects

Primary files:

- [`core/combat/health_component.gd`](../core/combat/health_component.gd)
- [`core/combat/damage_info.gd`](../core/combat/damage_info.gd)
- [`core/combat/impact_data.gd`](../core/combat/impact_data.gd)
- [`core/status/status_controller.gd`](../core/status/status_controller.gd)
- Effect Resources under [`data/effects/`](../data/effects/)

Player, enemies, and breakables share `HealthComponent`. It handles health, invulnerability time, friendly-species rejection, damage signals, and a single death signal.

```gdscript
health = maxf(0.0, health - info.amount)
damaged.emit(info)
health_changed.emit(health, max_health)
if health == 0.0 and killable:
	is_dead = true
	died.emit(info.source)
```

`StatusController` supports timed effects, stacking rules, periodic damage, and multiplier-based changes such as movement speed or gravity. Only effects marked persistent are stored in save data.

## 9. Enemy AI and sound sensing

Primary files:

- [`game/enemies/test/test_amphibian.gd`](../game/enemies/test/test_amphibian.gd)
- [`core/sensing/sound_bus.gd`](../core/sensing/sound_bus.gd)
- [`core/sensing/sound_event.gd`](../core/sensing/sound_event.gd)

The placeholder amphibian demonstrates the intended enemy contract: movement, gravity, patrol, state changes, shared damage/force reactions, sound investigation, fall handling, and persistence.

Its small state machine uses `PATROL`, `ALERT`, `INVESTIGATE`, `WAIT`, and `RETURN`. Sound producers send a `SoundEvent`; `SoundBus` broadcasts it only to nodes in the `sound_listeners` group.

```gdscript
static func emit_sound(tree: SceneTree, event: SoundEvent) -> void:
	if tree != null:
		tree.call_group(&"sound_listeners", &"hear_sound", event)
```

Enemies compare sound radius and priority before changing state. This provides a reusable foundation for later enemy types without a global enemy manager.

## 10. Authored world and deterministic generation

Primary files:

- [`game/world/world_generator.gd`](../game/world/world_generator.gd)
- [`game/world/world_layer.gd`](../game/world/world_layer.gd)
- [`game/world/world_slot.gd`](../game/world/world_slot.gd)
- [`game/world/world_section.gd`](../game/world/world_section.gd)
- Layer scenes under [`game/world/layers/`](../game/world/layers/)
- Section scenes under [`game/world/sections/`](../game/world/sections/)

Layer 1 and Layer 2 each contain six fixed slots: west/east routes with three depths. Every slot references one or more authored section variations. Selection uses a random stream derived from `run_seed + slot_id`, so the same seed reproduces the same map.

```gdscript
var random := RandomNumberGenerator.new()
random.seed = hash("%s:%s" % [run_seed, slot_id])
var roll := random.randi_range(1, total_weight)
```

The generator validates section IDs, anchors, bounds, required special tags, placer IDs, and entry data before spawning the player. It stores selected variation IDs in a world manifest, so Continue does not reroll the layout.

Adding a B variation requires both creating the section scene and adding that scene to the matching `WorldSlot.variations` array in `layer_1.tscn` or `layer_2.tscn`.

## 11. Section authoring tools

Primary files:

- [`game/world/sections/graybox_section_base.tscn`](../game/world/sections/graybox_section_base.tscn)
- [`game/world/world_section.gd`](../game/world/world_section.gd)
- [`game/world/test/section_test_runner.tscn`](../game/world/test/section_test_runner.tscn)
- [`docs/panduan_world_generation.md`](panduan_world_generation.md)

Every section inherits the same 1280×800 template containing:

- an empty `TileMapLayer` named `Terrain`;
- fixed entry and exit seam anchors;
- a movable respawn anchor;
- a `Placers` root;
- an `AuthoredContent` root;
- a cyan border visible only in the Godot editor.

```gdscript
func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, section_size),
			Color(0.15, 0.9, 1.0, 0.9), false, 4.0)
```

Designers paint terrain through the Godot TileMap GUI and can run one section through the shared test runner before adding it to full generation.

## 12. Enemy and loot placers

Primary files:

- [`game/world/deterministic_placer.gd`](../game/world/deterministic_placer.gd)
- [`game/world/world_spawn_entry.gd`](../game/world/world_spawn_entry.gd)
- [`game/world/placers/enemy_placer.tscn`](../game/world/placers/enemy_placer.tscn)
- [`game/world/placers/loot_placer.tscn`](../game/world/placers/loot_placer.tscn)
- [`game/world/sources/breakable_loot.gd`](../game/world/sources/breakable_loot.gd)

Designers drag either preset under a section's `Placers` node, give it a unique `persistent_id`, set chance/quantity, and position its `SpawnPoint` children.

Each placer supports weighted entries, activation chance, quantity range, facing, patrol bounds, and optional global allocation groups. Results use a seed derived from the placer ID and are stored in the world manifest.

```gdscript
random.seed = hash("%s:%s" % [run_seed, persistent_id])
if not force_active and random.randf() > spawn_chance:
	return []

resolved_results.append({
	"content_id": String(entry.content_id),
	"persistent_id": "%s:%d" % [persistent_id, point_index],
})
```

The current LootPlacer creates a breakable rock. Destroying it records the rock as destroyed, then creates one Throwable Rock and one gravity-affected item selected by the placer. Multitool is the current placeholder nested item.

```gdscript
SaveManager.mark_destroyed(persistent_id)
_spawn_drop(&"throwable_rock", "%s:rock" % persistent_id, Vector2(-35, -120))
_spawn_drop(item_id, "%s:item" % persistent_id, Vector2(35, -140))
```

## 13. Layer loading, activation, gates, and recovery

Primary files:

- [`game/world/world_run.gd`](../game/world/world_run.gd)
- [`game/world/world_layer.gd`](../game/world/world_layer.gd)
- [`game/world/world_gate.gd`](../game/world/world_gate.gd)
- [`game/world/layer3_entrance.gd`](../game/world/layer3_entrance.gd)

`WorldRun` owns the active layer and loading sequence. During a transition it captures persistent objects, unloads the old layer, creates the new layer, restores saved state, places the player, updates camera limits, and saves again.

All terrain sections remain instantiated, but only the player's section, nearby vertical sections, and relevant crossing sections process spawned content. This reduces unnecessary enemy processing without a complex streaming framework.

Entering a new section updates the player's `last_safe_position` from that section's movable respawn anchor. Leaving world bounds returns the player there with 1 HP. Enemies receive fall damage or return to their authored origin if they survive.

```gdscript
if _last_slot_id != slot.slot_id:
	_last_slot_id = slot.slot_id
	player.set_last_safe_position(section.respawn_anchor.global_position)
	active_layer.update_activation(player.global_position)
	player.set_camera_bounds(active_layer.camera_bounds_for(section))
```

Authored `WorldGate` scenes request layer transitions. Reaching the Layer 3 entrance records completion and ends the current prototype build.

## 14. Save and persistence system

Primary files:

- [`autoload/save_manager.gd`](../autoload/save_manager.gd)
- [`autoload/game_session.gd`](../autoload/game_session.gd)
- Persistent objects implementing `capture_state()` and `restore_state()`

Persistent objects join the `persistent_objects` group and have a stable `persistent_id`. SaveManager captures their scene path, layer, and custom state. Destroyed or collected IDs are recorded separately so generated content does not return after Continue.

```gdscript
for node in get_tree().get_nodes_in_group("persistent_objects"):
	if not node.has_method("capture_state"):
		continue
	var state: Dictionary = node.capture_state()
	state["_scene_path"] = node.scene_file_path
	persistent[node.persistent_id] = state
```

Run saves include:

- session state and seed;
- selected section and placer manifest;
- player position, health, inventory, and status;
- enemy health/alive state;
- shop stock;
- dropped and airborne items;
- destroyed/collected object IDs;
- layer, route, slot, money, and progression flags.

Writes are atomic: data goes to a temporary file, the old save becomes a backup, and the new file replaces it only after writing succeeds.

## 15. Shop, money, and progression shell

Primary files:

- [`game/shops/shop_service.gd`](../game/shops/shop_service.gd)
- [`game/shops/test_shop_terminal.gd`](../game/shops/test_shop_terminal.gd)
- [`data/definitions/shop_definition.gd`](../data/definitions/shop_definition.gd)
- [`autoload/game_session.gd`](../autoload/game_session.gd)

`ShopService` validates money, inventory capacity, price, and stock before completing a purchase. Selling uses item values and can increase delivery progression. Shop stock is persistent.

```gdscript
if GameSession.money < cost or not inventory.can_add_item(item_id, quantity):
	return false
if not inventory.try_add_item(item_id, quantity):
	return false
if not GameSession.try_spend(cost):
	push_error("Shop prevalidation failed after inventory commit")
	return false
return true
```

`GameSession` already stores whistle tier, delivery count, money, and progression flags. Full quest and dialogue content will use this foundation as it is authored.

## 16. HUD, pause menu, dialogue, and debug tools

Primary files:

- [`ui/foundation_hud.gd`](../ui/foundation_hud.gd)
- [`ui/dialogue_box.gd`](../ui/dialogue_box.gd)
- [`game/world/world_debug_draw.gd`](../game/world/world_debug_draw.gd)

The runtime HUD shows health, money, location, interaction prompts, feedback, two hotbar slots, inventory, pause/death menus, dialogue, and a mouse crosshair.

The F3 debug panel provides:

- FPS and frame-time display;
- give rock, damage, slow, and sound tests;
- unlimited health;
- save/load buttons;
- world-bound visualization;
- teleport between slots, shop, ending, and surface;
- world validation;
- manifest dump and generation log.

```gdscript
&"validate_world":
	var errors := generator.validate_manifest(GameSession.world_manifest)
	errors.append_array(generator.validate_templates())
	hud.set_world_debug_text("World valid" if errors.is_empty() else "\n".join(errors))
```

These tools let designers reproduce a seed and inspect failures without changing release gameplay code.

## 17. Automated foundation check

Primary files:

- [`tests/foundation_smoke.gd`](../tests/foundation_smoke.gd)
- [`tests/foundation_smoke.tscn`](../tests/foundation_smoke.tscn)

The smoke check covers content validation, inventory, physical drops, interaction priority, combat, status effects, projectiles, Multitool range, sound reactions, deterministic generation, placer presets, breakable loot, airborne-item restoration, shops, save/load, world transitions, camera bounds, and out-of-bounds recovery.

Run it with:

```bash
/usr/bin/Godot --headless --path . tests/foundation_smoke.tscn
```

Expected final line:

```text
FOUNDATION_SMOKE_OK
```

## 18. Current prototype limits

- Visuals and audio are placeholders.
- Terrain is being authored by the map team; generation infrastructure is ready but map content is incomplete.
- The amphibian is a test enemy proving shared AI/combat/sensing contracts, not final enemy content.
- The LootPlacer uses Multitool as temporary nested loot until final item distribution is authored.
- Rope, full quest content, final gatekeeper behavior, and remaining item/enemy roster are planned on top of the existing foundations.

## 19. Suggested supervisor demonstration

1. Start a **Debug Run** from the main menu and note the displayed seed.
2. Demonstrate movement, camera response, inventory, Multitool, Throwable Rock, enemy damage, knockback, and sound reaction.
3. Enter Layer 1 and show that authored section variations are assembled from the seed.
4. Open F3 and show FPS, current layer/route/slot, world bounds, teleport tools, validator, and generation log.
5. Open a section in the Godot editor and show the empty TileMap workflow, cyan boundary, movable respawn anchor, and separate Enemy/Loot placer presets.
6. Break a LootPlacer rock and show both gravity-driven drops.
7. Save while a rock is moving, return to menu, Continue, and show its physical state restored.
8. Run the headless smoke check and show `FOUNDATION_SMOKE_OK`.
