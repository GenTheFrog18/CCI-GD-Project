# Layer 2 World Integration

This file is the map-authoring and quest handoff for the implemented Layer 2 content.

## Ready-made placers

Use these scenes from the FileSystem dock and drag them into an eligible section variation:

| Template | Purpose |
|---|---|
| `game/world/placers/layer2_enemy_placer.tscn` | Weighted Primate, Hound, Stalker, or Bulwark spawn |
| `game/world/placers/plate_umbrella_placer.tscn` | One run-wide Umbrella allocation candidate |
| `game/world/placers/lacerator_placer.tscn` | One run-wide Lacerator allocation candidate |
| `game/world/placers/resonance_core_placer.tscn` | One guaranteed run-wide Core allocation candidate |

Every placed instance must receive a globally unique `persistent_id` in the Inspector. Use the existing pattern: `layer2_<route>_<slot>_<variation>_<content>_<number>`. Move/add child `SpawnPoint` markers to choose exact positions. Quantity may never exceed the number of child markers.

Keep the provided allocation group unchanged on relic templates. Put at least one candidate for each required group across every possible generated Layer 2 layout. The generator deterministically chooses one candidate from the selected section variations, preventing duplicates while preserving save/load results.

For an enemy placer, remove unwanted `entries` or adjust weights in the Inspector. Primates spawned by one placer automatically share its `persistent_id` as their independent coordination group; set `spawn_group_id` only when an explicit override is needed.

## Shop safety

`game/world/layers/layer_2.tscn` contains overlapping shop systems centered at `(2280, 1190)`:

- `ShopCurseSafeZone` resets Curse ascent reference.
- `ShopCombatSafeZone` marks the player combat-protected. Sight/sound acquisition and accepted hostile impacts reject the protected player.
- `ShopEnemyBoundary` uses collision layer `512`, which Layer 2 enemies collide with. Player, projectiles, and hitboxes can physically pass through as requested; hostile damage is still rejected while the player is inside.

Resize all three together if the authored shop changes. Do not resize only the visible gameplay area or the collision contract will disagree.

## Resonance Core exchange

The placeholder `Layer2Gatekeeper` is inside the shop. The quest has no requested/not-started stage: ownership of `resonance_core` is the check.

1. Interact while carrying the Core.
2. The first interaction asks for confirmation and keeps the Core.
3. Interact again within five seconds to hand it over.
4. The player receives Moon rank, the physical Moon Whistle, and one Bolt Shock with seven uses.
5. `layer_2_core_rewarded` is saved immediately, so later interaction/load cannot duplicate rewards.

If Bolt Shock cannot enter inventory, `layer_2_bolt_shock_reward` appears at `RewardMarker`. The same marker recovers Core/Bolt world objects that leave world bounds. Layer 3 access remains independent of this optional exchange.

## Sky Hunter Flock

The single persistent flock owner is already in the Layer 2 root. `FlockActivationZone` spans both routes at depth `Y=400`; crossing it sets the saved `layer_2_sky_hunter_active` flag and activates the flock near the current route. Dead member IDs and surviving member health/status/positions persist. Do not add individual Sky Hunter placers.

Move the activation strip or flock starting position in the Layer 2 root when the final map establishes a better reveal. Keep the trigger before exposed encounters and outside the shop.

## Debug and verification

F3 now grants every Layer 2 relic, grants the Moon Whistle, teleports to the shop/Layer 3 entrance, and spawns the four ordinary Layer 2 enemies near the player. Debug-spawned enemies receive valid persistent IDs.

Automated checks:

```bash
/usr/bin/Godot --headless --path . --scene res://tests/foundation_smoke.tscn
/usr/bin/Godot --headless --path . --scene res://tests/content_smoke.tscn
```

Before presentation, manually verify one generated run on each route: every required allocation exists, the shop boundary can be crossed by the player but not enemies, Core confirmation cannot duplicate rewards, the reward survives save/load, the flock wakes after its trigger, and the Layer 3 entrance remains usable without completing the quest.
