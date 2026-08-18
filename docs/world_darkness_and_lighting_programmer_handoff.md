# World Darkness and Lighting — Programmer Handoff

**Project:** CCI GD two-layer game-jam build  
**Engine:** Godot 4.7.1, GDScript, Compatibility renderer  
**Purpose:** Concrete implementation contract for dark map sections and light relics  
**Audience:** Gameplay/world programmers  
**Status:** Proposed implementation; unresolved decisions are listed at the end

---

## 1. Required result

The game must support authored cave and enclosed sections that are visibly dark enough to make light-based items useful.

The system must satisfy all of the following:

- Level designers paint background-wall tiles in the Godot TileMap editor.
- Background walls have no physics collision, interaction, placer behavior, or gameplay ownership.
- Darkness affects the player, enemies, dropped items, ropes, world effects, and world particles.
- HUD, inventory, dialogue, pause UI, and loading UI remain unaffected.
- Sun Sphere, Lantern Snail, and Lantern Crystal can reveal or illuminate dark areas.
- Solid terrain does not block light during the jam implementation.
- Darkness layout is authored per section variation and remains stable for a given run.
- Darkness is rebuilt correctly after New Run, Continue, layer transition, and section assembly.
- The system does not require terrain destruction, procedural terrain, live wall-density simulation, or real-time light occlusion.

The important distinction is:

> `BackgroundWalls` are the level-authoring/visual layer. `DarknessRegion2D` is the gameplay darkness source.

Painting a background wall must not silently create an unpredictable lighting field. A designer must be able to see and tune the exact dark area that the player will experience.

---

## 2. Existing world contracts this must preserve

The world is hand-authored. The generator selects section variations and placer results; it does not generate terrain.

Current map contract:

- Internal viewport: `640 × 360`.
- World scale: `32 px per metre`.
- Authoring grid: `16 px`.
- Route section: `1280 × 800 px`.
- Six sections per layer: west/east × three depths.
- Layer bounds: `2560 × 2400 px`.
- Entry/exit seam: `x = 640`.
- Entry/exit clearance: `96 px`.
- Terrain: `TileMapLayer`, authored and non-destructible.
- Runtime enemies, dropped items, and ropes live under the layer runtime root so they can cross seams.
- All selected variations and placer results are resolved at New Run and restored on Continue.
- Only the active layer is instantiated.
- UI is rendered separately from world content.

Do not solve darkness by changing terrain collision, moving terrain into a new scene type, or adding a second world-generation system.

---

## 3. Scene structure

Update `graybox_section_base.tscn` so every section variation has this optional-but-standard structure:

```text
WorldSection
├── BackgroundWalls       TileMapLayer
├── Terrain               TileMapLayer
├── EntryAnchor           Marker2D
├── ExitAnchor            Marker2D
├── RespawnAnchor         Marker2D
├── Placers               Node2D
├── DarknessRegions       Node2D
└── AuthoredContent       Node2D
```

The existing required `Terrain`, anchors, `Placers`, and `AuthoredContent` references remain unchanged.

### 3.1 BackgroundWalls

`BackgroundWalls` is a visual TileMapLayer only.

Required properties:

- Same TileSet grid as the section terrain.
- No TileSet physics layer.
- No navigation layer.
- No damage or interaction metadata.
- No enemy/loot spawn semantics.
- No dynamic runtime mutation during the jam.
- Rendered behind terrain, actors, dropped items, ropes, and world effects.
- Included in the authored section scene and therefore selected with the section variation.

Recommended node settings:

```text
z_index: lower than Terrain and world actors
z_as_relative: true
collision_layer: 0
collision_mask: 0
```

Do not rely on the visual tile itself to dim the player or enemies. Its purpose is to communicate that the space is enclosed and to make the cave look correct before the lighting pass is applied.

### 3.2 DarknessRegions

`DarknessRegions` contains authored regions that describe where ambient darkness exists.

Recommended region scene:

```text
DarknessRegion2D
├── Shape                  Polygon2D or authored rectangle data
└── EditorDebugDisplay     optional
```

It is not a physics body and must not use a collision shape for gameplay.

Minimum region data:

```gdscript
@export var region_id: StringName
@export_range(0.0, 1.0) var darkness_strength: float = 0.85
@export var edge_falloff_pixels: float = 32.0
@export var enabled: bool = true
```

`region_id` is for editor/debug identification. It is not a runtime object ID and does not need a save record.

Use a rectangle for ordinary caves. Use an authored polygon for irregular rooms or corridors. Do not use a physics `Area2D` as the source of truth unless the script is explicitly configured as a non-colliding darkness region.

---

## 4. Darkness behavior

### 4.1 Darkness mask meaning

The runtime darkness mask uses a normalized value:

```text
0.0 = no additional darkness
1.0 = maximum authored darkness
```

The mask is generated from selected `DarknessRegion2D` nodes. It is not generated from the number of background-wall tiles.

If multiple regions overlap, use the maximum value rather than adding them:

```text
cell_darkness = max(region_a, region_b, region_c)
```

This prevents overlapping authoring regions from accidentally producing a black screen.

### 4.2 Edge falloff

`edge_falloff_pixels` controls a smooth transition between normal brightness and the region’s full darkness.

Recommended behavior:

- `0`: hard boundary.
- `16–32`: ordinary cave entrance.
- `48+`: gradual transition suitable for a large forest-to-cave boundary.

The falloff is baked into the mask or evaluated during mask generation. Do not calculate polygon distance for every screen pixel every frame on the CPU.

### 4.3 Darkness tint

Use a restrained tint rather than pure black. The exact color is art/balance data, not gameplay code.

Suggested starting values:

```gdscript
@export var darkness_tint: Color = Color(0.08, 0.10, 0.14, 1.0)
@export_range(0.0, 1.0) var maximum_screen_darkness: float = 0.82
```

The tint must preserve enough contrast for silhouettes and telegraphs to remain readable. Dark sections should be dangerous because visibility is reduced, not because the player cannot distinguish terrain from UI.

---

## 5. Recommended runtime architecture

Create one lighting controller per active layer, not one independent lighting system per section.

Suggested files:

```text
game/world/lighting/darkness_region_2d.gd
game/world/lighting/world_lighting_controller.gd
game/world/lighting/darkness_mask_builder.gd
game/world/lighting/darkness_overlay.tscn
game/world/lighting/darkness_overlay.gdshader
game/world/lighting/light_source_2d.gd
```

Suggested active-layer structure:

```text
WorldLayer
├── SelectedSections
├── RuntimeRoot
├── WorldLightingController
│   ├── DarknessOverlay
│   └── LightSourceRegistry
└── WorldEffects
```

`WorldLightingController` must be a child of the active layer/world runtime, not a child of one section. This is required because dropped items, enemies, ropes, and other runtime objects can move across section seams.

### 5.1 WorldLightingController responsibilities

The controller must:

1. Find selected sections after assembly.
2. Collect enabled `DarknessRegion2D` nodes from those sections.
3. Build one darkness mask for the active layer.
4. Register and unregister dynamic light sources.
5. Update the overlay’s camera/world transform uniforms.
6. Update light-source uniforms when a light moves, changes intensity, or expires.
7. Rebuild when changing layers.
8. Clear temporary lights on layer unload.
9. Expose debug visualization for regions, mask strength, and active lights.

The controller must not own item inventory, enemy states, or save data.

### 5.2 DarknessMaskBuilder

Build a low-resolution world-space mask from authored regions.

Recommended mask resolution for the current layer:

```text
Layer: 2560 × 2400 px
Grid: 16 px
Mask: 160 × 150 texels
```

One texel per authoring tile is sufficient for the first implementation. The mask can use linear filtering or a small baked blur to avoid visible square transitions.

The builder should:

- Create an empty grayscale image initialized to zero.
- Rasterize each region into the image.
- Apply region falloff.
- Compose overlapping regions with `max`.
- Upload the resulting image as an `ImageTexture`.
- Store the selected layer/world origin and mask size for coordinate conversion.

Pseudocode:

```gdscript
func build_mask(layer_bounds: Rect2, regions: Array[DarknessRegion2D]) -> ImageTexture:
    var image := Image.create(mask_width, mask_height, false, Image.FORMAT_RF)
    image.fill(Color(0.0))

    for region in regions:
        if not region.enabled:
            continue
        rasterize_region_max(image, layer_bounds, region)

    return ImageTexture.create_from_image(image)
```

The exact Godot image format/API can be adjusted, but the output contract must remain a grayscale texture sampled in world coordinates.

### 5.3 DarknessOverlay

Use a full-viewport `ColorRect` or equivalent CanvasItem in a CanvasLayer above world content and below UI.

The overlay shader must:

1. Read the already-rendered world screen texture.
2. Convert the current screen pixel to world coordinates using the current Camera2D transform.
3. Sample the static darkness mask.
4. Evaluate active light contributions at that world position.
5. Reduce darkness by those light contributions.
6. Multiply/tint the world pixel.
7. Preserve the world alpha.

Conceptual shader operation:

```text
base_darkness = sample(darkness_mask, world_position)

light_reveal = 0
for each active light:
    distance_ratio = distance(world_position, light.position) / light.radius
    contribution = smoothstep(1.0, 0.0, distance_ratio)
    contribution *= light.intensity
    light_reveal = max(light_reveal, contribution)

final_darkness = clamp(base_darkness - light_reveal, 0.0, 1.0)
world_color = mix(screen_color, screen_color * darkness_tint, final_darkness)
```

Use `max` for light contributions during the first implementation. Additive light stacking is not needed and makes overlapping lights difficult to balance.

The shader must not sample terrain collision, query enemies, or perform physics checks. Solid terrain does not block light in this version.

### 5.4 Camera mapping

The overlay is screen-space, but the mask is world-space. The controller must update the shader whenever the Camera2D moves or zoom changes.

Use the actual camera transform rather than reconstructing the camera from player position. This prevents darkness/light drift during camera smoothing, route bounds, and horizontal crossing.

Pass one of the following to the shader:

- An inverse screen-to-world `Transform2D`; or
- Camera world position, zoom, viewport size, and camera rotation if rotation is guaranteed to remain zero.

The current camera is not expected to rotate. Passing a transform is safer and should be preferred if convenient.

---

## 6. LightSource2D contract

All dynamic lights must use one shared registration interface.

Suggested data:

```gdscript
class_name LightSourceData

var source_id: StringName
var world_position: Vector2
var radius: float
var intensity: float
var enabled: bool
var source_type: StringName
```

Suggested interface:

```gdscript
register_light(source: Node, data: LightSourceData) -> void
update_light(source: Node, data: LightSourceData) -> void
unregister_light(source: Node) -> void
```

The registry must use the source instance as the owner and must not duplicate entries when an item changes section or is reloaded.

### Light update rules

- Static lights register once.
- Moving lights update only when position/intensity changes beyond a small threshold.
- Temporary lights unregister on expiry.
- Disabled lights do not contribute.
- A source may be destroyed before unregistering; the registry must clean invalid references safely.
- The controller exposes a configurable maximum source count.

Recommended starting maximum: `16` active lights per layer. If more are needed, profile before increasing the shader array.

### Light-source tuning fields

```gdscript
@export var light_radius: float
@export_range(0.0, 1.0) var light_intensity: float
@export var light_fade_in: float
@export var light_fade_out: float
@export var source_type: StringName
```

Light radius and intensity are independent. A short bright flash and a large weak glow should be possible.

---

## 7. Existing item integration

### 7.1 Sun Sphere

Sun Sphere must register a light source when it becomes active or is deployed.

Required behavior:

- Dormant inventory Sun Sphere has no light contribution.
- Prepared/held active Sun Sphere registers at the player/light position.
- Thrown active Sun Sphere registers at the thrown object position.
- An inactive thrown Sun Sphere remains dark until its normal deployment behavior activates it.
- Light fades according to the existing active duration.
- On expiry, unregister the source and resolve the existing item consumption rule.
- Do not save a temporary active prepared state if the current item-save contract cancels prepared items before Save & Menu.

The Sun Sphere does not need to instantiate a `PointLight2D` if the darkness overlay system is used. It only needs to implement the shared light-source interface.

### 7.2 Lantern Snail

Lantern Snail is a moving persistent light source.

Required behavior:

- Register while the Snail is alive and loaded.
- Update position as the Snail moves.
- Disable/unregister when the Snail dies or is unloaded.
- Restore the light after Continue if the Snail is alive.
- The dropped Lantern Crystal is a separate item and must not remain linked to the Snail light.

The Snail’s illumination and scream are separate systems. A light update must not emit a sound event.

### 7.3 Lantern Crystal

Lantern Crystal is a short, high-intensity flash/lure.

Required behavior:

- Register a short-lived light source at the player or impact position.
- Use a high intensity and shorter radius/falloff profile than Sun Sphere if that matches playtest goals.
- End the light and unregister exactly once.
- Continue to emit its existing sound/Dazzled behavior separately.
- A thrown Crystal must use its impact position for both its light and flash behavior.

The flash must not be implemented as a global screen-white effect that bypasses the darkness system. It should reveal the local world area and retain the existing sight/Dazzled mechanics.

---

## 8. No terrain light occlusion in the jam version

Do not add `LightOccluder2D` or terrain shadow polygons to the base terrain during this implementation.

Reason:

- The current design explicitly says solid terrain does not affect brightness lighting.
- Terrain collision and light collision would become two separate geometry contracts.
- Every tile variation would require shadow-polygon authoring or generation.
- It would make debugging light leaks and seam behavior substantially harder.

The darkness overlay must ignore terrain. A light can reveal a dark area through a wall in this version. If that looks unacceptable in playtest, treat physical light occlusion as a separate feature decision rather than quietly adding it to individual tiles.

Godot’s `LightOccluder2D` is available for a future implementation, but it requires an authored `OccluderPolygon2D` and introduces a separate shadow geometry layer. See the official [LightOccluder2D documentation](https://docs.godotengine.org/en/4.7/classes/class_lightoccluder2d.html).

---

## 9. World generation and loading integration

Add a lighting stage to the existing world load sequence.

Recommended sequence:

```text
validate pools
→ select section variations
→ validate selected scenes
→ resolve allocation groups
→ resolve placers
→ instantiate active layer
→ assemble selected sections
→ collect darkness regions
→ build darkness mask
→ instantiate/register persistent light sources
→ restore saved state
→ restore/re-register persistent lights
→ spawn player
→ final validation
```

The player must not spawn before the darkness mask exists. This prevents one-frame bright flashes or incorrect light mapping during Continue.

### Layer transition

When changing layers:

1. Unregister all light sources belonging to the old layer.
2. Free or detach the old `WorldLightingController`.
3. Instantiate the destination layer.
4. Collect its selected sections and DarknessRegions.
5. Build the destination mask.
6. Restore persistent enemies/items/ropes.
7. Register destination light sources.
8. Place the player at the destination safe anchor.
9. Complete the transition.

Do not carry the old layer’s mask into the destination layer.

### Continue

The darkness mask is derived data and does not need its own save record.

Continue reads:

- World seed.
- Selected variation IDs.
- World revision.
- Living-run object state.
- Enemy/source state.
- Player/item state.

Then it rebuilds the mask from the selected section scenes. If a selected variation is invalid and the world uses its documented fallback, rebuild the mask from the actual fallback scene, not the missing scene.

### Autosave

Do not save the darkness mask image. Save only the world manifest and normal runtime state. Rebuilding a 160 × 150 mask is cheap and avoids versioning generated textures.

---

## 10. Authoring workflow for level designers

Add this process to `map_section_authoring_tutorial.md`.

### Create a dark cave

1. Open the correct section variation.
2. Select `BackgroundWalls`.
3. Paint the background-wall tiles behind the cave’s playable space.
4. Ensure the wall TileSet has no physics collision.
5. Select `DarknessRegions`.
6. Add a `DarknessRegion2D` for the cave’s playable dark volume.
7. Shape the region to match the intended dark area, not merely the visual wall outline.
8. Set `darkness_strength` and `edge_falloff_pixels`.
9. Use the editor debug display to preview the region.
10. Test the section with no light source.
11. Test Sun Sphere illumination.
12. Test Lantern Snail illumination if the section contains or can receive one.
13. Test Lantern Crystal flash.
14. Run the section test runner.
15. Run full Debug Run and `Validate World`.

### Placement rules

- BackgroundWalls must stay inside section bounds except where a deliberate seam visual continues across a junction.
- Do not paint wall tiles over the 96 px seam opening if they visually imply a blocked route.
- Do not place a DarknessRegion outside section/layer bounds.
- Do not make the first 96 px of a required entry completely dark without a clear landmark or light source.
- Darkness regions may overlap optional branches and dead ends.
- A required jump must remain readable at the minimum intended ambient brightness.
- Do not put DarknessRegions under `Placers`; they are authored map data, not random content.
- Do not use a placer to randomize cave darkness during the jam.

### Editor debug display

`DarknessRegion2D` should display:

- Region outline.
- Filled preview using the configured darkness strength.
- Region ID.
- Falloff boundary.

`WorldLightingController` debug mode should display:

- Current mask bounds.
- Mask texture resolution.
- Active light source positions and radii.
- Current sampled darkness under the player.
- Current light contribution under the player.

---

## 11. Background-wall TileSet requirements

Create or designate a TileSet for BackgroundWalls.

Every wall tile must:

- Have a visual texture or placeholder color.
- Have no physics polygon.
- Have no navigation polygon.
- Have no damage/interaction metadata.
- Use nearest filtering consistent with the project.
- Have a stable atlas coordinate after content freeze.

If a combined TileSet is used for terrain and walls, the wall tiles must still have an empty physics layer. Do not assume that a visually similar terrain tile has the same collision behavior.

The validator should report an error if a BackgroundWalls tile contributes physics collision.

---

## 12. Optional future wall-density mode

Do not implement this for the first jam pass unless explicit DarknessRegions prove too slow to author.

A future mode could read a wall TileMap layer, bake a low-resolution coverage field, blur it, and use the result as the darkness mask. It would require decisions about:

- Which wall cells count as coverage.
- How darkness spreads into empty playable cells.
- How open-air gaps reduce darkness.
- How rooms are separated.
- How seams connect fields.
- How designers override incorrect automatic results.

If implemented later, it should bake a mask in the editor or at generation. It must not scan wall cells every frame.

---

## 13. Performance requirements

The jam implementation should avoid per-tile or per-actor lighting work.

Required performance rules:

- Build the static darkness mask once per active layer assembly.
- Rebuild only when changing layers or regenerating a New Run.
- Update dynamic light uniforms only when a source moves/changes meaningfully.
- Use a fixed maximum light-source count.
- Do not add one Light2D or shader node per wall tile.
- Do not run physics queries for lighting.
- Do not scan every enemy to calculate darkness.
- Do not update the mask while the player moves.

Target behavior:

- No visible frame hitch when entering a dark section.
- No visible one-frame lighting reset during camera movement.
- Stable 60 FPS target on the Linux jam build’s expected test machine.

---

## 14. Save and persistence rules

### Do not save

- Generated darkness mask texture.
- Overlay shader state.
- Current screen-space camera uniform.
- Temporary flash shader state.
- Per-frame light contribution.

### Save through existing systems

- Selected section variation IDs.
- World revision/seed.
- Alive Lantern Snail state and position/health as already required.
- Persistent dropped item state.
- Any persistent deployed light object if an item definition explicitly makes it persistent.

Prepared/temporary light behavior must follow the existing item save contract. Do not create a second save rule only for lighting.

On load, all static and persistent light sources must register exactly once. Temporary expired lights must not reappear.

---

## 15. Failure handling

### Missing darkness mask

If the mask fails to build:

- Log the failure with layer ID and selected variation IDs.
- Use a zero-darkness fallback in Development only if player spawn must continue for debugging.
- In an export build, use a safe authored fallback or stop player spawn with a visible loading error according to the existing world-generation error policy.

### Invalid region

Invalid regions include:

- Empty polygon.
- Region outside layer bounds.
- NaN/invalid strength.
- Negative falloff.

Development validation should fail clearly. Do not silently clamp malformed map content except for harmless numeric ranges.

### Invalid light source

If a light source has invalid radius/intensity:

- Clamp radius to a positive minimum or disable the source with a warning.
- Clamp intensity to the supported range.
- Remove destroyed source references from the registry.
- Never leave the overlay permanently black because one light node failed.

---

## 16. Test checklist

### Map authoring

- [ ] A BackgroundWalls tile has no collision.
- [ ] Player can walk through the space in front of a wall.
- [ ] BackgroundWalls render behind terrain and actors.
- [ ] A wall tile by itself does not create a physics or spawn side effect.
- [ ] DarknessRegion editor preview matches runtime position.
- [ ] Region edge falloff is smooth and stable.
- [ ] Darkness does not cover UI.

### Runtime darkness

- [ ] No region produces normal ambient brightness.
- [ ] A dark cave visibly darkens the player, enemies, items, ropes, and world particles.
- [ ] Darkness follows the camera correctly during horizontal and vertical movement.
- [ ] Darkness does not drift at camera bounds or seam transitions.
- [ ] Multiple overlapping regions use the maximum, not additive blackening.
- [ ] Solid terrain does not block light.

### Sun Sphere

- [ ] Dormant inventory item contributes no light.
- [ ] Active held/deployed item registers one light.
- [ ] Thrown/deployed position updates correctly.
- [ ] Expiry unregisters exactly once.
- [ ] Temporary state follows existing save rules.

### Lantern Snail

- [ ] Living Snail light moves with the Snail.
- [ ] Snail death unregisters its light and drops a separate Crystal.
- [ ] Continue restores light for a living Snail.
- [ ] Unloading/reloading a section does not duplicate the light.

### Lantern Crystal

- [ ] Flash reveals the correct local area.
- [ ] Flash duration and fade are correct.
- [ ] Sound/Dazzled behavior remains separate from visual illumination.
- [ ] Thrown impact position is used.
- [ ] Expired flash does not leave a registered light.

### World generation/persistence

- [ ] Same seed selects the same variation and darkness layout.
- [ ] Different selected variation produces the correct darkness mask.
- [ ] Continue does not reroll wall/darkness layout.
- [ ] Layer transition rebuilds the destination mask.
- [ ] Dropped items and ropes are darkened after crossing seams.
- [ ] Player is not spawned before the mask exists.
- [ ] Mask is not saved as a separate asset or record.

### Performance

- [ ] Mask is built once per active layer assembly.
- [ ] No per-wall Light2D nodes are created.
- [ ] No per-frame TileMap scan runs.
- [ ] Active light count is capped and visible in debug mode.
- [ ] Camera movement does not cause a measurable lighting spike.

---

## 17. Implementation order

1. Add `BackgroundWalls` to the section base scene and confirm it has no collision.
2. Add `DarknessRegion2D` and editor debug drawing.
3. Add region validation to `WorldSection`/world validation.
4. Implement `DarknessMaskBuilder` for a selected active layer.
5. Implement `DarknessOverlay` and camera-to-world coordinate mapping.
6. Add a single test light source controlled by a debug key or test scene.
7. Add `LightSource2D` registration to Sun Sphere.
8. Add registration to Lantern Snail.
9. Add registration to Lantern Crystal.
10. Integrate mask build and light registration into world load/Continue/layer transition.
11. Add editor/runtime debug visualization.
12. Author one meadow-to-cave test section and one cave with a narrow light-dependent route.
13. Run the full save, seam, camera, and performance checklist.
14. Only after this works, author darkness for the remaining sections.

---

## 18. Definition of done

The feature is complete when:

- A level designer can paint BackgroundWalls without touching collision.
- A level designer can place and tune a DarknessRegion without writing code.
- A cave is visibly dark when no light source is nearby.
- Sun Sphere, Lantern Snail, and Lantern Crystal reveal darkness through the same shared interface.
- The player, enemies, ropes, dropped items, and world effects are affected consistently.
- UI remains readable.
- Solid terrain does not block light.
- Darkness remains correct after New Run, Continue, layer transition, camera movement, and seam crossing.
- No duplicate light sources or saved mask records occur.
- The section test runner and full world validator report no lighting-related errors.
- The system does not require per-tile light nodes, terrain destruction, or live wall-density simulation.

---

## 19. Official Godot references

- [CanvasModulate](https://docs.godotengine.org/en/4.7/classes/class_canvasmodulate.html)
- [PointLight2D](https://docs.godotengine.org/en/4.7/classes/class_pointlight2d.html)
- [LightOccluder2D](https://docs.godotengine.org/en/4.7/classes/class_lightoccluder2d.html)

The jam implementation in this document uses a world-space darkness mask and screen-space overlay instead of terrain LightOccluders. The official occluder system is reserved for a future physical-shadow pass.

---

## 20. Clarifications requested from the lead designer

The programmer can begin with the assumptions in this document. Please confirm or change these decisions:

1. **Darkness source:** should the team approve explicit `DarknessRegion2D` authoring paired with BackgroundWalls, or must darkness be calculated automatically from BackgroundWalls coverage?
2. **Light-through-terrain rule:** should lights continue to reveal through solid terrain for the jam, as assumed here, or should terrain block light despite the current world-generation proposal?
3. **Outdoor ambient level:** should outdoor sections have no darkness mask and remain fully bright, or should the entire world have a small global ambient dim level with caves adding darkness on top?

Until changed, this document assumes explicit DarknessRegions, no terrain light occlusion, and fully bright outdoor areas.
