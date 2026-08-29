# Map Section Authoring Tutorial

> **Status:** current editor workflow for Layer 1 and Layer 2 section templates. Current playable build ends at Layer 2 gate.

## 1. Mental model

A section is an authored scene assigned to one fixed `WorldSlot`. Generator selects one variation for that slot; it does not rearrange terrain or connect arbitrary rooms.

```text
WorldLayer
  -> WorldSlot selects PackedScene
  -> WorldSection instantiated at slot transform
  -> Placers restore manifest results into runtime root
```

Surface is different: it is one directly authored `WorldLayer`, not a section pool.

## 2. Relevant files

- Layer scenes: `game/world/layers/`.
- Section templates: `game/world/sections/layer1/` and `layer2/`.
- Shared scripts: `world_layer.gd`, `world_slot.gd`, `world_section.gd`, `world_generator.gd`.
- Placer presets: `game/world/placers/`.
- Isolated test room: `game/world/foundation_test_room.tscn`.
- Editor six-section preview: `game/world/layer1_section_preview.tscn`.

## 3. Required scene anatomy

Typical variation:

```text
WorldSection
├── Terrain              TileMapLayer
├── EntryAnchor          Marker2D
├── ExitAnchor           Marker2D
├── RespawnAnchor        Marker2D
├── Placers              Node2D
└── AuthoredContent      Node2D
```

Root Inspector fields:

- `Slot ID`: exact owning slot ID;
- `Variation ID`: unique content ID;
- `Selection Weight`: positive relative weight;
- `Section Size`: normally 1280×800;
- `Camera Bounds`: normally same rectangle;
- anchor/root references;
- required `Special Tags` only where current validator needs them.

## 4. Create a variation

1. Open a variation/template belonging to the correct slot.
2. Use **Scene > Save As** or inherited scene workflow inside the same slot folder.
3. Change only `Variation ID`; keep `Slot ID` equal to owning slot.
4. Register the new PackedScene in that `WorldSlot.variations` array on layer scene.
5. Keep section origin and anchors compatible with sibling variations.
6. Open `layer1_section_preview.tscn` to compare connected choices in editor.

Never duplicate a west/east/depth scene and only rename the variation while leaving the wrong `slot_id`; world generation rejects it.

## 5. Paint terrain

1. Select `Terrain` TileMapLayer.
2. Use the existing TileSet and 16 px grid.
3. Keep outer route walls closed except intended seam/crossing.
4. Preserve opening and collision clearance around Entry/Exit.
5. Put safe ground near RespawnAnchor.
6. Test descent and ascent without debug flight/teleport.

Terrain collision belongs to TileSet physics. Do not cover collision defects with invisible StaticBody unless authored content specifically needs one.

Rope can assist traversal, but mandatory route should not require more Rope than the game guarantees.

## 6. Darkness and background

Place `DarknessRegion2D` under authored content. Its polygon is world-space and may extend outside cave/layer bounds. Light sources subtract from the generated screen overlay using world-to-screen transform.

Layer 1 background comes from section/depth metadata/controller, remains camera-space, and cross-fades before boundary. Do not place panorama as a giant world sprite.

## 7. Authored content

Use `AuthoredContent` for:

- gate and transition areas;
- NPC/dialogue actors;
- safe/combat zones;
- Large Flyer POIs/blockers;
- map-authored Rope;
- lighting regions/sources;
- background markers or encounter-specific geometry.

Use `Placers` for seeded enemy, breakable loot, and allocated relics.

## 8. Special slots

Current Layer 1 depth-03 variations provide compatible east/west crossing and access toward Layer 2 gate.

Layer 2 templates still contain old shop/gauntlet/Layer 3 tags and validator requirements. They are legacy implementation foundation. Preserve them while editing existing scenes so generator still runs, but do not treat Layer 3 entrance as current design goal or add new dependencies on it.

## 9. Add enemy or loot placer

1. Select `Placers`.
2. Drag appropriate preset.
3. Set unique `Persistent ID`.
4. Edit entries/chance/quantity on this map instance.
5. Move existing direct child SpawnPoint marker.
6. Add more markers only for authored position variety.
7. Configure facing, patrol, coordination, or scatter fields as needed.

Quantity may exceed SpawnPoint count; results select markers with replacement. See [`map_placer_authoring_reference.md`](map_placer_authoring_reference.md).

Loot Placer creates breakable sources. Released item and rock become static pickups immediately and scatter inside editor-visible circle.

## 10. Selection and save

For one seed, slot selection and placer resolution are deterministic. Manifest stores:

- chosen scene/variation per slot;
- resolved content and SpawnPoint index per placer;
- stable result IDs;
- generation log.

Continue restores this manifest and dynamic object state. Changing stable IDs or removing selected scene paths can invalidate old run saves; do this only with deliberate world revision/save reset.

## 11. Run one section

For fast terrain/encounter testing:

1. Open `foundation_test_room.tscn` or a copied test room.
2. Instance authored content/placer/enemy under appropriate root.
3. Configure layer/Curse profile in Inspector.
4. Press F6.

Direct section scene may not bootstrap player/HUD/placer services unless it uses test-room runner. Use full generated run before calling integration complete.

## 12. Custom generated world

1. Run main menu.
2. Press F3.
3. Open Custom World.
4. Choose one variation for each six Layer 1 slots.
5. Start debug run; player appears at Surface.
6. Enter Layer 1 normally or use gameplay debug teleport.
7. Enable only needed gameplay-range categories.
8. Run Validate World and inspect generation log.

## 13. Pre-commit checklist

- [ ] Root is `WorldSection`.
- [ ] Slot ID belongs to owning `WorldSlot`.
- [ ] Variation and placer IDs are unique.
- [ ] Anchor/root references are not null.
- [ ] Seam matches sibling variations.
- [ ] Respawn and mandatory landing are safe.
- [ ] Route works downward and upward.
- [ ] Placer entries/weights/quantity are valid.
- [ ] SpawnPoint terrain and overlap are safe.
- [ ] Required allocations remain possible.
- [ ] Darkness/background stay aligned while camera moves.
- [ ] F3 Validate World reports no errors.
- [ ] Continue does not reroll or respawn destroyed content.

## 14. Common failures

| Error/symptom | Cause | Fix |
| --- | --- | --- |
| `Layer scene root is not WorldLayer` | Wrong root scene/script. | Restore `WorldLayer` root. |
| `contains variation for slot ...` | Variation `slot_id` mismatch. | Correct root ID or register scene in correct slot. |
| `Duplicate placer ID ...` | Same ID exists in another template. | Rename one globally. |
| No object spawned | Empty point/entry, chance failed, or allocation lost. | Inspect manifest and placer fields. |
| Several objects overlap | Quantity reused one point. | Add markers or give spawned drop/actor safe separation. |
| Saved object returns | Missing `mark_destroyed`/duplicate ID. | Fix object persistence owner. |
| Camera/darkness offset | Presentation treated as world/camera in wrong space. | Use existing background/lighting controller. |
| Test room placer inactive | Scene lacks test bootstrap. | Use `foundation_test_room.tscn` or full run. |

`quantity exceeds SpawnPoint count` is obsolete under current placer implementation.
