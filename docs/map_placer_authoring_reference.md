# Map Placer Authoring Reference

This is the map-maker reference for placing enemies, loot, and unique relics in Godot. It describes current implemented behaviour. Use it alongside [map_section_authoring_tutorial.md](map_section_authoring_tutorial.md) for section creation and terrain rules.

## 1. What a placer does

A placer is a `Marker2D` with `DeterministicPlacer` attached. It does **not** immediately contain its gameplay object in the map scene. Instead, it stores a deterministic recipe:

```text
New Run seed + placer Persistent Id
  -> whether placer is active
  -> quantity
  -> selected SpawnPoint children
  -> weighted Entry choice for each point
  -> saved world manifest
  -> runtime enemy/item/breakable instance
```

Same seed plus same `Persistent Id` produces same result. Continue reads saved result; it does not reroll a different enemy or item.

Core code:

| File | Relevant lines | Responsibility |
|---|---:|---|
| `game/world/deterministic_placer.gd` | 4–21 | Inspector properties and validation. |
| `game/world/deterministic_placer.gd` | 37–80 | Seeded selection and runtime spawning. |
| `game/world/deterministic_placer.gd` | 82–121 | Saved result, weights, and SpawnPoint lookup. |
| `game/world/world_spawn_entry.gd` | 1–17 | Entry resource validation. |
| `game/world/world_generator.gd` | 49–112 | Resolves section placers into world manifest. |
| `game/world/world_layer.gd` | 39–72 | Spawns saved resolved results into active layer runtime root. |

## 2. Godot editor workflow

Use this procedure for every ordinary enemy/item placer.

1. Open target section variation, for example `game/world/sections/layer1/west/slot_02_a.tscn`.
2. In Scene dock select `Placers`.
3. In FileSystem dock drag a template from `game/world/placers/` onto `Placers`.
4. Rename node for humans, for example `SpiderLedgePlacer`. Node name is not runtime identity.
5. Select placer root. In Inspector fill **Persistent Id** first.
6. Position root or its child SpawnPoint markers. A SpawnPoint is exact world position where one result can appear.
7. Configure entries, chance, quantity, facing, patrol area, and optional group fields.
8. Save section, then use F6 with `game/world/test/section_test_runner.tscn` and test full Debug New Run.

Keep placers under `Placers` for organization. Runtime finds them recursively, but placing them elsewhere makes map scenes hard to review.

## 3. Shared Inspector properties

All templates use `DeterministicPlacer`. Select placer root to edit these fields.

| Inspector property | Required? | How to fill it | Runtime result |
|---|---|---|---|
| **Position** | Yes | Move root to rough placement location. | Moves all local SpawnPoints together. |
| **Persistent Id** | Yes | Globally unique, stable ID. Example: `layer1_west_02_a_spider_ledge_01`. | Seeds selection, identifies manifest result, and becomes spawned object ID prefix. Never rename after maps/saves are frozen. |
| **Spawn Chance** | Yes | `1.0` always active; `0.35` means 35% chance; use chance, not quantity zero, for an optional placer. | Entire placer either activates or produces no results. |
| **Entries** | Yes | Add one or more `WorldSpawnEntry` resources. Each needs Content Id, Scene, Weight. | One entry is picked per selected SpawnPoint. |
| **Minimum Quantity** | Yes | Minimum number when active. Use `1` for normal map content. | Random quantity roll after activation. |
| **Maximum Quantity** | Yes | Must be at least minimum and no larger than direct SpawnPoint child count. | Caps selected points; invalid maps fail generation. |
| **Allocation Group** | Usually blank | Leave blank for ordinary content. Use template-provided ID for one-per-run relic/flyer candidates. | All selected candidates in same non-empty group compete; only one winner resolves. |
| **Required Allocation** | Only unique required content | Keep `true` on provided unique templates. | Winning candidate always resolves even if chance would fail. |
| **Spawn Group Id** | Usually blank | Leave blank for normal enemies and isolated Primate groups. Enter a shared ID only when multiple Primate placers must coordinate. | Spawner copies it to compatible enemy scenes; blank becomes placer Persistent Id. |
| **Facing** | Optional | `1` normal/right, `-1` horizontal flip. Leave `1` for loot. | Sets spawned Node2D horizontal scale direction. |
| **Patrol Bounds** | Enemy-specific | Rect relative to placer. Leave empty unless enemy supports patrol/flight region. | Passed only to compatible scenes. Birds and some Layer 2 enemies use it. |

### SpawnPoint children

- Direct `Marker2D` children are used automatically. The legacy `Spawn Points` array is only fallback; do not fill it for new maps.
- The root marker itself is not a spawn point. Add/duplicate child `SpawnPoint` markers in Scene dock.
- Quantity must never exceed number of child markers.
- A point is chosen without replacement: one point produces at most one object in a run.
- Scene-tree order becomes persisted suffix order: `persistent_id:0`, `persistent_id:1`, and so on. Do not reorder markers after a released save may reference them.
- Place enemy SpawnPoints on valid ground/air as required by that enemy. Place breakable and loose-item points over solid floor, not inside terrain.

### Persistent-ID rules

`WorldGenerator.validate_templates()` checks all generated section variations, not merely currently selected scene. IDs must therefore be unique across every Layer 1 and Layer 2 template.

Use this format:

```text
layer<layer>_<route>_<depth>_<variation>_<content>_<number>

layer1_west_02_a_spider_ledge_01
layer2_east_03_b_bulwark_lane_01
layer2_west_01_a_lacerator_01
```

Never reuse an ID for a second A/B variation. It can cause generation error, destroyed content returning, or wrong saved placement.

## 4. Entries: what to fill

Each **Entries** row is a `WorldSpawnEntry` resource.

| Field | Fill with | Rule |
|---|---|---|
| **Content Id** | Stable item/enemy ID, e.g. `cave_spider` or `driftseed`. | Match definition and scene. This ID is saved in manifest. |
| **Scene** | Scene that should instantiate. | Enemy entries use enemy `.tscn`; normal physical loot uses `game/items/world/world_item.tscn`; breakable loot uses `game/world/sources/breakable_loot.tscn`. |
| **Weight** | Positive integer. | Relative selection chance only. `3` versus `1` is roughly 75% versus 25%. |

The placer sets compatible runtime fields automatically:

```text
persistent_id    <- Persistent Id + selected SpawnPoint index
spawn_group_id   <- Spawn Group Id, or Persistent Id when blank
item_id          <- Content Id
spawn_position   <- selected SpawnPoint world position
patrol_bounds    <- placer Patrol Bounds
```

Do not set those generated fields manually on normal placer instances.

## 5. Ready-made templates

### 5.1 `EnemyPlacer` — ordinary Layer 1 ground/hazard enemy

**File:** `game/world/placers/enemy_placer.tscn`

Default entry is `tongue_amphibian` using `game/enemies/layer1/tongue_amphibian.tscn`. It has one SpawnPoint and quantity `1–1`.

Use it for one or more of these Layer 1 entries after replacing/adding Entries in Inspector:

| Content Id | Scene | Placement notes |
|---|---|---|
| `tongue_amphibian` | `game/enemies/layer1/tongue_amphibian.tscn` | Needs reachable grounded route and clear tongue line. Avoid seam landings and essential item paths. |
| `thorn_bloom` | `game/enemies/layer1/thorn_bloom.tscn` | Fixed hazard. Place where six-needle fan has readable warning space, not at a mandatory landing. |
| `lantern_snail` | `game/enemies/layer1/lantern_snail.tscn` | Place on connected terrain surface. It crawls floor/wall/ceiling and drops Lantern Crystal on death. |
| `cave_spider` | `game/enemies/layer1/cave_spider.tscn` | Needs usable ground and sight lane for projectile attack; sound/light can make it flee. |

Do **not** use this generic template for Knockback Bird, Large Flyer, Senior Diver, or Sky Hunter. Those have special placement contracts below.

### 5.2 `BirdNestPlacer` — Knockback Bird flight group

**File:** `game/world/placers/bird_nest_placer.tscn`

Defaults:

```text
Entry:            knockback_bird
Scene:            game/enemies/layer1/knockback_bird.tscn
Quantity:         1–3
Patrol Radius:    160
SpawnPoints:      3
```

Use for a nest encounter. Move root to nest centre. Adjust **Patrol Radius** to set the circular flight region around it. Keep all three SpawnPoints in free air and leave room for swoop/recovery. Do not place birds directly on floor collision. Add fewer points or lower maximum quantity for a smaller nest.

### 5.3 `LargeFlyerPlacer` — one Layer 1 large flyer candidate

**File:** `game/world/placers/large_flyer_placer.tscn`

Defaults:

```text
Entry:                large_layer1_flyer
Scene:                game/enemies/layer1/large_flyer.tscn
Allocation Group:     layer_1_large_flyer
Required Allocation:  true
```

Keep allocation fields unchanged. Place candidates across valid Layer 1 layouts; generator chooses exactly one candidate from selected sections. Place SpawnPoint in open air. The flyer needs authored `LargeFlyerPOI` roam markers and may use `LargeFlyerBlocker` scenes for transparent movement blockers. Do not add two unrelated allocation groups for this same flyer.

### 5.4 `Layer2EnemyPlacer` — ordinary Layer 2 enemy

**File:** `game/world/placers/layer2_enemy_placer.tscn`

It ships with four weighted entries. Remove entries or adjust weights so encounter purpose is clear.

| Content Id | Scene | Map-authoring guidance |
|---|---|---|
| `canopy_primate` | `game/enemies/layer2/canopy_primate.tscn` | Grounded jumper/thrower. Use stable group behaviour: blank Spawn Group Id means all Primate results from this placer coordinate as one group. Use shared override only for deliberate multi-placer group. |
| `tremor_hound` | `game/enemies/layer2/tremor_hound.tscn` | Sound-driven grounded pouncer. Give readable horizontal approach/landing lane; first-pass maps should use one Hound per placer. |
| `carrion_stalker` | `game/enemies/layer2/carrion_stalker.tscn` | Grounded scavenger that values bleeding, poisoned, low-health prey. Give patrol ground and avoid tiny sealed spaces. |
| `bulwark_beast` | `game/enemies/layer2/bulwark_beast.tscn` | Large charging enemy. Give a long clear horizontal charge lane and recovery space; never point charge through a mandatory seam landing. |

Do not place individual `sky_hunter` scenes through a placer. The one persistent Sky Hunter Flock owner is already in `game/world/layers/layer_2.tscn` and activates via root-level `FlockActivationZone`.

### 5.5 `LootPlacer` — breakable map loot

**File:** `game/world/placers/loot_placer.tscn`

Defaults:

```text
Entry Content Id:  multitool
Scene:             game/world/sources/breakable_loot.tscn
Quantity:          1–1
```

This is not a loose pickup. It spawns `BreakableLoot`, a two-hit Multitool target. On destruction it permanently removes itself and releases:

```text
1 × throwable_rock
1 × configured Entry Content Id
```

Both drops are physical thrown-item objects with gravity and map origin. Breakable logic is in `game/world/sources/breakable_loot.gd:6–49`.

For normal breakable loot, keep Scene as `breakable_loot.tscn` and change only Content Id/Weight. Good current map-item candidates are:

| Item ID | Map use |
|---|---|
| `multitool` | Starting/early required tool. Do not make all routes depend on a low-chance roll. |
| `rope` | Traversal resource. Do not hide required Rope behind a route that needs Rope to reach it. |
| `bandage` | Healing/bleed support. |
| `info_book` | Knowledge item. |
| `numbing_pill` | Ascension-curse support. |
| `sun_sphere` | Light/impact activation. |
| `lantern_crystal` | Light/dazzle/lure utility; Lantern Snails also drop it. |
| `rattlepod` | Sound-distraction utility. |
| `hushcap` | Sound-suppression cloud. |
| `cling_resin` | Slow-zone utility. |
| `driftseed` | Falling control effect. |
| `silver_weight` | Heavy toggle/combat utility. |

`throwable_rock` is already emitted by every breakable; do not make it normal configured breakable loot unless duplicate rock reward is intentional.

Do not put `whistle_red`, `whistle_blue`, `whistle_moon`, `bolt_shock`, `resonance_core`, `plate_umbrella`, or `lacerator` in a generic LootPlacer. These are dedicated progression/relic rewards or have unique placement templates.

### 5.6 `PlateUmbrellaPlacer` — one unique Umbrella candidate

**File:** `game/world/placers/plate_umbrella_placer.tscn`

```text
Entry:                plate_umbrella
Scene:                game/items/world/world_item.tscn
Allocation Group:     layer_2_plate_umbrella
Required Allocation:  true
```

Keep Scene and allocation fields unchanged. Place one or more candidate instances only where a player can safely pick up a visible unique relic. Generator picks one selected candidate per run. Use a unique Persistent Id for every candidate.

### 5.7 `LaceratorPlacer` — one unique Lacerator candidate

**File:** `game/world/placers/lacerator_placer.tscn`

```text
Entry:                lacerator
Scene:                game/items/world/world_item.tscn
Allocation Group:     layer_2_lacerator
Required Allocation:  true
```

Keep provided group. Place accessible but optional candidate positions. Lacerator is a physical unique map item, not a breakable source.

### 5.8 `ResonanceCorePlacer` — guaranteed Core candidate

**File:** `game/world/placers/resonance_core_placer.tscn`

```text
Entry:                resonance_core
Scene:                game/items/world/world_item.tscn
Allocation Group:     layer_2_resonance_core
Required Allocation:  true
```

Keep provided group. Every possible generated Layer 2 layout must include at least one valid selected candidate, otherwise a run can lack required quest content. The Core recovers to shop marker if it exits world bounds; do not replace its Scene with BreakableLoot.

## 6. Loose world item versus breakable source

Use `game/items/world/world_item.tscn` when player should see and pick up item directly. Placer fills its `item_id` from Entry Content Id. `WorldItem` validates against `ContentCatalog`, shows item icon, and persists if item definition permits it.

Use `game/world/sources/breakable_loot.tscn` when player should strike a source with Multitool. Placer fills its `item_id`; breakable script creates rock plus configured item at destruction.

Never put a direct `WorldItem` in `LootPlacer` while expecting breakable behaviour. Conversely, never use `BreakableLoot` for a unique relic unless design explicitly wants that relic hidden behind a two-hit rock.

## 7. Enemies that are not ordinary placer content

| Enemy | Correct placement | Reason |
|---|---|---|
| `knockback_bird` | `BirdNestPlacer` | Uses flight patrol region and 1–3 nest group. |
| `large_layer1_flyer` | `LargeFlyerPlacer` plus POI/blocker authoring. | One world-wide living actor, special allocation and cross-section travel. |
| `senior_diver` | Authored scene near Layer 2 gate, not normal placer. | Gatekeeper progression/return logic. |
| `sky_hunter` | Existing Layer 2 flock root only. | Flock owner controls member set, persistence, and attacks. |

## 8. Placement safety rules

- Do not spawn random enemy, breakable, or hazard inside section top/bottom 96 px seam-clearance zones.
- Test each SpawnPoint with terrain collision: ground enemies need support, flying points need clear air, and loot cannot be buried in a tile.
- Do not overlap a SpawnPoint with player respawn, gate trigger, shop safe zone, or a mandatory narrow landing.
- `facing = -1` affects visual/object horizontal scale. Use it only if scene supports left/right orientation.
- Keep encounter placement readable: sight/projectile enemies need line of sight; charge/pounce enemies need run-up; hazards need reaction space.
- Do not change unique template allocation-group IDs. Do not create a new unique group unless gameplay design explicitly requires a different one-per-run item.
- Required unique candidate placers must exist in every possible selected layout. Put candidates in both A/B variations where needed, each with its own Persistent Id.

## 9. Testing checklist

### Test one section

1. Open `game/world/test/section_test_runner.tscn`.
2. Assign your section scene to **Section Scene**.
3. Press F6.
4. Confirm no validation error in Output.
5. Verify every marker is reachable/safe and every terrain collision behaves correctly.

### Test a generated run

1. Start **Debug Run** from Main Menu with a known seed.
2. Start a new run, not Continue.
3. Press F3 and use **Validate World**.
4. Verify selected map includes expected SpawnPoints/content.
5. Destroy/pick up content, save/return/continue, and verify destroyed objects remain gone and survivors restore safely.

### Automated checks

```bash
/usr/bin/Godot --headless --path . tests/foundation_smoke.tscn
/usr/bin/Godot --headless --path . tests/content_smoke.tscn
```

Expected last line for each test is `FOUNDATION_SMOKE_OK` or `CONTENT_SMOKE_OK`.

## 10. Common errors

| Error / symptom | Cause | Fix |
|---|---|---|
| `persistent_id is blank` | Required placer field is empty. | Set globally unique Persistent Id. |
| `has no entries` | Entries array empty. | Add at least one WorldSpawnEntry with Content Id and Scene. |
| `quantity range is invalid` | Minimum exceeds maximum. | Make minimum less than or equal to maximum. |
| `quantity exceeds SpawnPoint count` | Not enough direct Marker2D children. | Add SpawnPoints or lower maximum. |
| `Duplicate placer ID` | Same ID appears in another variation/template. | Rename one ID; include layer/route/depth/variation. |
| New placer never appears | Chance failed, a different variation was selected, or Continue kept old manifest. | Use chance `1.0`, verify seed/variation, start New Run. |
| Wrong item appears | Content Id and Scene do not match. | Use matching catalog ID and scene type. |
| Unique relic duplicates or disappears | Allocation group changed/missing or candidates not present in selected layouts. | Restore provided group/required flag; add valid candidates across layouts. |
| Bird/enemy behaves badly | SpawnPoint has wrong terrain/air/patrol space. | Move marker and provide needed lane or patrol bounds. |

## 11. Pre-commit checklist

- [ ] Every placer has a globally unique stable Persistent Id.
- [ ] Entries have correct Content Id, matching Scene, and positive Weight.
- [ ] Chance and quantity are intentional; maximum does not exceed SpawnPoint count.
- [ ] SpawnPoints are direct children and ordered intentionally.
- [ ] Enemy/loot points are physically valid and outside seam clearance.
- [ ] Allocation-group templates keep their supplied group and required flag.
- [ ] Primate Spawn Group Id is blank unless shared coordination is intentional.
- [ ] Bird/flyer patrol requirements and Layer 2 flock restrictions are respected.
- [ ] New Run and Continue persistence were checked.
- [ ] F3 Validate World and both smoke tests pass.
