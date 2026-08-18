# Map Section Authoring Tutorial

This guide explains how to make a playable map section in the Godot editor. It covers the current project pipeline: authored section scenes, deterministic variation selection, gameplay placement, validation, and testing.

Read this before making a section. A section that looks correct but breaks its anchors, slot ID, or persistent IDs can prevent a New Run from generating.

## 1. Mental model: what is a section?

The game world is not terrain-procedural. Level designers make every section by hand. The generator only chooses one authored variation for each fixed slot, then chooses each placer result from the run seed.

```text
Layer 1 / Layer 2

west_01 | east_01    y = 0
west_02 | east_02    y = 800
west_03 | east_03    y = 1600
```

Each section is always **1280 × 800 world pixels** (80 × 50 tiles at 16 px per tile). A west slot starts at `x = 0`; an east slot starts at `x = 1280`. The section scene itself is authored in local coordinates from `(0, 0)` to `(1280, 800)`.

The cyan outline in Godot is drawn by `WorldSection` only in the editor. It does not appear in game.

## 2. Files and code that make maps work

| File | Important lines | Purpose |
|---|---:|---|
| `game/world/sections/graybox_section_base.tscn` | 6–28 | Base scene every generated section inherits. Contains required nodes and anchors. |
| `game/world/world_section.gd` | 5–20 | Fixed section size, seam coordinates, exported Inspector fields. |
| `game/world/world_section.gd` | 22–52 | Validation rules and cyan editor border. |
| `game/world/layers/layer_1.tscn` | 21–111 | Layer 1 slot pool; this is where section variations are registered. |
| `game/world/layers/layer_2.tscn` | 45–195 | Layer 2 slot pool and its root-level authored systems. |
| `game/world/world_slot.gd` | 4–9 | Slot properties: ID, route, depth, variations, fallback. |
| `game/world/world_slot.gd` | 11–77 | Validates variation IDs and deterministically chooses a variation. |
| `game/world/world_generator.gd` | 15–127 | Builds and stores the run manifest: chosen section variation plus placer results. |
| `game/world/world_generator.gd` | 139–177 | Validates every template and special-slot contract. |
| `game/world/world_layer.gd` | 39–72 | Instantiates selected sections and their resolved placer results. |
| `game/world/world_layer.gd` | 89–156 | Enables nearby section content, chooses spawns, finds placers. |
| `game/world/world_run.gd` | 111–166 | Runtime load order: instantiate layer, restore state, spawn player, create HUD. |
| `game/world/deterministic_placer.gd` | 4–21 | Placer Inspector properties and validation. |
| `game/world/deterministic_placer.gd` | 23–80 | Deterministic spawn selection and runtime spawn behaviour. |
| `game/world/world_gate.gd` | 4–20 | Gate destination properties and transition call. |
| `game/world/test/section_test_runner.tscn` | entire scene | Small scene used to test one section alone. |
| `game/world/test/section_test_runner.gd` | 3–21 | Instantiates selected section, validates it, places player at RespawnAnchor. |

The existing world-design contract is also documented in `docs/panduan_world_generation.md`. This file is the practical Godot-editor guide.

## 3. Section scene anatomy

Every generated section must inherit from `graybox_section_base.tscn` and retain this structure:

```text
YourSection (WorldSection root)
├── BackgroundWalls    TileMapLayer
├── Terrain             TileMapLayer
├── EntryAnchor         Marker2D
├── ExitAnchor          Marker2D
├── RespawnAnchor       Marker2D
├── Placers             Node2D
├── DarknessRegions     Node2D
└── AuthoredContent     Node2D
```

What each part does:

- **Root `WorldSection`**: stores section identity, selection weight, tags, bounds, and links to the required child nodes. Do not remove its script or change its `section_size`/`camera_bounds`.
- **`Terrain`**: paint all map tiles here. Tile collision comes from the selected TileSet, so use collision-enabled terrain tiles for solid ground, walls, and platforms.
- **`BackgroundWalls`**: paint collisionless visual wall tiles behind enclosed spaces. It never creates gameplay darkness by itself.
- **`EntryAnchor`**: top vertical seam marker. It must stay at `(640, 0)`.
- **`ExitAnchor`**: bottom vertical seam marker. It must stay at `(640, 800)`.
- **`RespawnAnchor`**: safe point used when the player enters this section and after falling out of bounds. It may move anywhere inside the section.
- **`Placers`**: recommended home for enemy/loot placer instances. The code finds placers recursively, but keeping them here makes scenes readable.
- **`AuthoredContent`**: recommended home for authored gates, special props, fixed set pieces, and other non-random content.
- **`DarknessRegions`**: add `DarknessRegion2D` nodes for playable dark volumes. Tune strength and edge falloff to match intended visibility.

The base scene defines these links at `graybox_section_base.tscn:6–28`. The validator rejects missing links, wrong bounds, or wrong seam positions in `world_section.gd:22–48`.

### Fixed seam geometry

| Requirement | Value | Why |
|---|---:|---|
| Section size | `1280 × 800` | Every slot aligns vertically and horizontally. |
| EntryAnchor | `(640, 0)` | Matches exit from section above. |
| ExitAnchor | `(640, 800)` | Matches entry from section below. |
| Clear entry rectangle | `x 592–688`, `y 0–96` | Player needs a safe seam landing. |
| Clear exit rectangle | `x 592–688`, `y 704–800` | Player needs a safe route to next seam. |
| Random enemies/hazards near seams | none within 96 px | Prevents unavoidable damage during transitions. |

Do not move `EntryAnchor` or `ExitAnchor`. Do not paint blocking collision through their 96 px clearance. Move `RespawnAnchor` only after ensuring ground beneath it is safe.

## 4. Where to create the section file

Use one of these folders:

```text
game/world/sections/layer1/west/
game/world/sections/layer1/east/
game/world/sections/layer2/west/
game/world/sections/layer2/east/
```

Naming pattern:

```text
slot_01_a.tscn
slot_01_b.tscn
slot_02_a.tscn
...
```

The folder indicates layer and route. Filename indicates depth and variation. The root Inspector properties are the authority:

```text
Layer 1 west depth 1 variation A
slot_id       = layer1_west_01
variation_id  = layer1_west_01_a

Layer 2 east depth 3 variation B
slot_id       = layer2_east_03
variation_id  = layer2_east_03_b
```

`slot_id` must match the slot in the layer scene. `variation_id` must be unique inside that slot. This is enforced by `game/world/world_slot.gd:11–36`.

## 5. Create a new variation in Godot

Use this workflow for a new map variation. Example: create `Layer 1 West 02 B`.

1. In Godot **Filesystem**, open `game/world/sections/layer1/west/`.
2. Right-click `slot_02_a.tscn` and choose **Duplicate**.
3. Rename duplicate to `slot_02_b.tscn`.
4. Open `slot_02_b.tscn`.
5. Select root node in Scene dock. In Inspector set only:

   ```text
   Slot Id:       layer1_west_02
   Variation Id:  layer1_west_02_b
   Selection Weight: 1
   ```

6. Keep `Section Size`, `Camera Bounds`, `Entry Anchor`, `Exit Anchor`, `Respawn Anchor`, `Placer Root`, and `Dynamic Root` unchanged unless instructed otherwise.
7. Save scene.
8. Open `game/world/layers/layer_1.tscn`.
9. In Scene dock open `Layer1 > Slots > West02`.
10. In Inspector, find **Variations**. Add `slot_02_b.tscn` to array. Leave `slot_02_a.tscn` as fallback unless design says otherwise.
11. Save `layer_1.tscn`.

Why this is necessary: a new `.tscn` file is not automatically selectable. `WorldSlot.variations` is the pool used by `select_variation()` in `world_slot.gd:38–67`.

Do not duplicate a section from another slot and only change its IDs. It can accidentally carry wrong special tags, gate logic, or seam design. Duplicate an existing variation from the **same slot**.

## 6. Paint terrain in the Godot GUI

1. Open your variation scene.
2. Select `Terrain` in Scene dock.
3. Switch to **TileMap** panel at bottom of Godot.
4. Confirm the correct TileSet is assigned in Inspector. The base scene uses `art/world/graybox_tileset.tres`; final art sections may override this with their own TileSet.
5. Choose **Paint** tool and draw terrain.
6. Use grid snapping and keep all walkable terrain within cyan section border.
7. Build a stable floor under `RespawnAnchor`.
8. Build a clear vertical route between upper and lower seams. The player should not need pixel-perfect jumps.
9. Check top/bottom 96 px seam areas are open and safe.
10. Save.

Useful Godot editor tools:

- **Select**: move a placed node or tile selection.
- **Paint**: draw tiles.
- **Line/Rectangle**: fast platforms, walls, and fills.
- **Eraser**: remove tiles without deleting node.
- **TileMap Layers**: use separate TileMapLayer nodes only when art order requires it. Keep collision terrain obvious and do not hide it behind decorative-only layers.

### Collision rule

Tile collision belongs to the TileSet tile definition, not to the section root. A pretty tile with no collision will not support the player. A solid tile with collision can block the player even if it looks like decoration. Test all ledges, walls, slopes, and seam floors in game.

`BackgroundWalls` uses a separate TileSet with no physics layer. Never copy collision-enabled terrain tiles into it without checking the TileSet.

### Darkness rule

Darkness comes only from explicit `DarknessRegion2D` nodes. Keep regions inside section bounds and outside the 96 px required seam clearances. Overlapping regions use the strongest value. Test the section with no light, Sun Sphere, Lantern Snail, and Lantern Crystal.

## 7. Place authored gameplay content

Put fixed gameplay nodes under `AuthoredContent` where practical.

Examples:

- `WorldGate` for route/layer transitions.
- `Layer3Entrance` in Layer 2 east depth 3.
- Fixed visual landmarks, scripted triggers, or deliberate set pieces.

For a `WorldGate`, select the instance and set these Inspector fields from `game/world/world_gate.gd:4–7`:

| Property | Meaning |
|---|---|
| `Target Layer Id` | `surface`, `layer_1`, or `layer_2`. |
| `Target Route Id` | `west` or `east`. |
| `Target Spawn Id` | Optional named Marker2D in target layer, such as `EastBottomSpawn`. Leave blank to use route spawn. |
| `Prompt` | Text shown to player. |

At interaction, `WorldGate` calls `WorldRun.request_layer_transition()` (`world_gate.gd:15–20`). Do not hand-script scene changes inside a map section.

## 8. Use special tags correctly

The generator validates some slots as required world structure. Set **Special Tags** on section root in Inspector.

| Layer / slot | Required tag | Extra requirement |
|---|---|---|
| Layer 1 west depth 3 | `crossing` | Must provide compatible crossing. |
| Layer 1 east depth 3 | `crossing` | Must provide compatible crossing. |
| Layer 2 east depth 2 | `shop` | Must provide optional shop branch/guidance. |
| Layer 2 west depth 3 | `gauntlet` | Must provide gauntlet/crossing half. |
| Layer 2 east depth 3 | `gauntlet` and `layer3_entrance` | Must contain exactly one `Layer3Entrance`. |

These checks live in `game/world/world_generator.gd:168–187`. If a variation does not meet its slot contract, world generation fails deliberately.

Layer 2 also contains root-level systems in `game/world/layers/layer_2.tscn:111–175`: shop safe zones, gatekeeper, flock, and activation zone. Do not delete or move these while making a normal section variation.

## 9. Place enemies and loot with placers

Do not drag runtime enemies or breakable loot directly into a generated section unless they are a deliberate fixed encounter. Use placer scenes for normal random map content.

### Enemy placer

1. Drag `game/world/placers/enemy_placer.tscn` into `Placers`.
2. Rename node for readability, for example `AmphibianPlacerNorth`.
3. Set a globally unique **Persistent Id**, for example `l1_west_02_b_enemy_north`.
4. Set **Spawn Chance**, **Minimum Quantity**, **Maximum Quantity**.
5. Expand **Entries**. Set each entry's `Content Id`, `Scene`, and `Weight`.
6. Move existing `SpawnPoint` child to valid ground.
7. Duplicate `SpawnPoint` children if maximum quantity needs more positions.

### Loot placer

1. Drag `game/world/placers/loot_placer.tscn` into `Placers`.
2. Set unique **Persistent Id**, for example `l1_west_02_b_loot_01`.
3. Set quantity/chance and SpawnPoint positions.
4. In **Entries**, set `Content Id` to item to release. Keep `Scene` as `game/world/sources/breakable_loot.tscn`.

The current loot source is breakable. It releases a rock and its configured item; spawned item is physical and falls with gravity.

### Important placer rules

- Persistent IDs must be unique across every generated template, not only the currently open scene. `WorldGenerator.validate_templates()` checks all variation scenes (`world_generator.gd:139–167`).
- `Maximum Quantity` cannot exceed number of direct Marker2D SpawnPoint children.
- SpawnPoint order in Scene dock determines generated suffixes such as `placer_id:0`; do not reorder points after a save-compatible map is frozen.
- Entries use weighted random selection. Weight `3` against `1` means about 75% versus 25% when that placer spawns.
- `Allocation Group` makes multiple placers compete so only one is selected per run. Use it for unique quest/rare content.
- Use **Facing** for enemy orientation and **Patrol Bounds** only for enemies that support patrol bounds.

The exact placer behaviour is in `game/world/deterministic_placer.gd:23–121`. It uses `run_seed + persistent_id`, so same seed produces same result.

## 10. How variation selection and saves work

On **New Run**:

1. `WorldGenerator` validates every layer, slot, section, tag, and placer.
2. Each `WorldSlot` chooses one variation deterministically using run seed and slot ID.
3. Each placer resolves its content and SpawnPoint before gameplay starts.
4. Chosen variation IDs and placer results are saved in world manifest.
5. Only active layer is instantiated, but its selected sections remain loaded for that layer.

On **Continue**, game reads saved manifest. It does not re-roll a new section or new placer result.

Practical result: after adding a variation, use **New Run** with a new seed to verify it can be selected. An existing save is expected to keep old selected variation. Use Debug Run seed input when you need reproducible testing.

## 11. Test one section in isolation

1. Open `game/world/test/section_test_runner.tscn`.
2. Select root `SectionTestRunner`.
3. Drag your variation scene into **Section Scene** in Inspector.
4. Press **F6** (run current scene).
5. Check Output/Debugger for validation errors.
6. Player spawns at `RespawnAnchor`; test movement, all floors, collision, ledges, seam approach, gates, and placer locations.

`section_test_runner.gd:9–21` instantiates selected section, calls `section.validate()`, then places player at RespawnAnchor. This is fastest check before loading full world.

## 12. Test full world generation

1. Run project with **F6/F5**.
2. From Main Menu enable **Debug Run**.
3. Enter a known seed if you need repeatable result.
4. Start New Run.
5. Press **F3** in game.
6. Use **Validate World**. It validates manifest and every authoring template.
7. Use debug teleports to check routes, shop, gauntlet, and ending.

Also run smoke test from terminal after structural changes:

```bash
/usr/bin/Godot --headless --path . tests/foundation_smoke.tscn
```

Expected final line:

```text
FOUNDATION_SMOKE_OK
```

## 13. Pre-commit checklist

- [ ] Section inherits `graybox_section_base.tscn`.
- [ ] Root `slot_id` matches registered WorldSlot.
- [ ] Root `variation_id` is unique within that slot.
- [ ] Root `selection_weight` is intentional.
- [ ] Section remains 1280 × 800.
- [ ] EntryAnchor `(640, 0)` and ExitAnchor `(640, 800)` unchanged.
- [ ] RespawnAnchor is inside section and on safe ground.
- [ ] Top/bottom seam clearance has no blocking terrain, random hazard, or random enemy.
- [ ] Terrain collision is tested, not assumed from visuals.
- [ ] New variation is registered in correct `Variations` array in `layer_1.tscn` or `layer_2.tscn`.
- [ ] Fallback scene remains valid.
- [ ] Every placer persistent ID is globally unique.
- [ ] Maximum placer quantity does not exceed SpawnPoint count.
- [ ] Required special tags and required entrance count are present.
- [ ] Section test runner works.
- [ ] Full Debug Run `Validate World` works.
- [ ] New Run has been tested; old Continue behaviour has not been mistaken for a reroll.

## 14. Common failures and fixes

| Error or symptom | Cause | Fix |
|---|---|---|
| `WorldSection ... must be 1280x800` | Root bounds changed. | Restore `Section Size` and `Camera Bounds` to `1280 × 800`. |
| `entry anchor must be at (640, 0)` | Anchor moved while painting. | Restore EntryAnchor position. |
| `duplicate variation_id` | A/B scenes use same root variation ID. | Change only duplicate's `variation_id`. |
| `contains variation for slot ...` | Section root slot_id does not match layer slot. | Set root `slot_id` to exact slot ID. |
| `Duplicate placer ID` | Same persistent ID exists anywhere in all section pools. | Rename one placer ID; include layer, route, depth, variation, purpose. |
| `quantity exceeds SpawnPoint count` | Placer can select more content than markers. | Add SpawnPoints or lower maximum quantity. |
| New map never appears | Scene is not registered in layer slot Variations, or existing save keeps old manifest. | Register scene; begin New Run with fresh seed. |
| Player falls/spawns badly at seam | Terrain blocks required clearance or RespawnAnchor has no floor. | Rebuild safe seam and respawn landing. |
| World generation fails for special slot | Required tag/entrance missing. | Apply correct root Special Tags and required `Layer3Entrance`. |

## 15. Surface is different

`game/world/layers/surface.tscn` is a single authored hub, not a 1280 × 800 generated section pool. Edit it directly for hub layout, shop, initial spawn, and Layer 1 gates. Its initial spawn is separate from west/east return spawns; the spawn priority is implemented in `game/world/world_layer.gd:114–125` and called from `game/world/world_run.gd:152–158`.

Do not add Surface to Layer 1/Layer 2 variation arrays. Do not turn its map into a `WorldSection`.
