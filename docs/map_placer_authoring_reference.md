# Map Placer Authoring Reference

> **Status:** current Godot editor reference. General world rules are in [`panduan_world_generation.md`](panduan_world_generation.md).

## 1. What a placer resolves

```text
run seed + persistent ID
  -> activation roll
  -> quantity roll
  -> weighted entry per result
  -> SpawnPoint chosen with replacement
  -> stable result ID
```

The result is stored in world manifest. Continue never rerolls it.

## 2. Editor workflow

1. Open target section variation.
2. Select `Placers` node.
3. Drag a preset from `game/world/placers/`.
4. Set a globally unique `Persistent ID`.
5. Set chance, quantity, entries, and optional group fields.
6. Move/add direct child `Marker2D` SpawnPoints.
7. Configure facing/patrol/scatter fields relevant to spawned scene.
8. Run section, custom world, then F3 Validate World.

Do not edit the reusable preset itself when the change belongs to one map instance.

## 3. Shared Inspector properties

| Property | Authoring rule |
| --- | --- |
| `Persistent ID` | Required and unique across all templates. Use `layer_route_slot_variation_content_number`. |
| `Spawn Chance` | Entire placer activation chance. `1.0` always active. |
| `Entries` | One or more `WorldSpawnEntry` resources. |
| `Minimum/Maximum Quantity` | Valid range 1–16; minimum cannot exceed maximum. |
| `Allocation Group` | Run-wide competition between candidate placers. |
| `Required Allocation` | Winner must resolve active. |
| `Spawn Group ID` | Optional AI coordination identity, not allocation. |
| `Attack Group Maximum/Spacing` | Optional coordinated attack limits. |
| `Drop Scatter Radius` | Circular breakable-drop area, shown only in editor. |
| `Drop Height Offset` | Moves scatter circle above placer. |
| `Facing` | `1` normal/right, `-1` flipped/left. |
| `Patrol Bounds` | Optional rectangle passed to compatible actor. |

## 4. Entry fields

Each `WorldSpawnEntry` has:

- `Content ID`: stable enemy/item ID;
- `Scene`: instantiated scene;
- `Weight`: relative positive weight.

For enemy placers, scene and content ID must describe the same enemy. For Loot Placer, scene remains `breakable_loot.tscn`; Content ID is the nested item released.

## 5. SpawnPoint behavior

Direct child `Marker2D` nodes are candidate points. Quantity may exceed point count. Each result independently selects a marker, so one marker can spawn several objects.

Example one marker, quantity 3:

```text
loot_01:0
loot_01:0:1
loot_01:0:2
```

Add points for intentional distribution, not to satisfy a quantity validator. Ensure stacked results can separate safely. Breakable loot distributes its released pickups through scatter settings.

## 6. Allocation versus spawn group

`Allocation Group` answers “which placer exists this run?” `Spawn Group ID` answers “which spawned actors coordinate?” They are unrelated IDs.

Use allocation for unique relic/Flyer candidates. Use spawn group for Primate/other group AI. Leave both blank for ordinary independent content.

## 7. Presets

### Enemy Placer

Ordinary Layer 1 enemy/hazard. Replace/add weighted entries in the map instance. Place ground actors on support and flying actors in clear air.

### Loot Placer

Creates a two-hit `BreakableLoot`. On break it releases one Throwable Rock and one configured item per breakable result as static pickups. Set scatter radius/height to prevent overlap.

### Bird Nest Placer

Spawns a Knockback Bird group. `Patrol Radius` draws an editor-only circle and becomes each bird's nest patrol area. Leave clear air for swoop and recovery.

### Large Flyer Placer

Candidate for one run-wide Layer 1 Flyer. Preserve allocation group. Add `LargeFlyerPOI` scenes and optional transparent blockers to authored content.

### Layer 2 Enemy Placer

Weighted Primate, Tremor Hound, Carrion Stalker, or Bulwark Beast. Layer 2 remains development foundation. Unique placer ID becomes default coordination group for compatible actor.

### Layer 2 relic placers

Umbrella/Lacerator are optional unique allocation candidates. Resonance Core is required unique allocation. Every possible future layout needs a candidate for required group.

## 8. Placement safety

- No spawn inside terrain, respawn, gate trigger, safe-zone boundary, or mandatory narrow landing.
- Ground enemy needs connected support; Snail/Spider need compatible surfaces.
- Bird/Flyer needs clear flight and recovery space.
- Bulwark needs readable charge lane.
- Do not place required progression item where out-of-bounds loss or unreachable terrain can softlock run.
- Keep stable IDs and marker order unchanged after save compatibility matters.

## 9. Common failures

| Failure | Fix |
| --- | --- |
| `Duplicate placer ID` | Rename one placer globally. |
| Empty/invalid quantity range | Set minimum ≤ maximum, both at least 1. |
| No entries | Add valid `WorldSpawnEntry`. |
| No SpawnPoint | Add direct child `Marker2D`. |
| Wrong enemy/content | Match ID with scene or keep Loot scene with nested item ID. |
| Required relic absent | Add allocation candidate to every selectable layout. |
| Actor stuck/falls | Move point and author enough terrain/air/patrol space. |

`quantity exceeds SpawnPoint count` belongs to an older placer contract and should no longer be produced by current validator.

## 10. Verification

```bash
/usr/bin/Godot --headless --path . --editor --quit
/usr/bin/Godot --headless --path . --scene res://tests/foundation_smoke.tscn
/usr/bin/Godot --headless --path . --scene res://tests/content_smoke.tscn
```

Manual check: run same seed twice, inspect manifest, break loot, reload Continue, and confirm result count/IDs/drop state remain identical.
