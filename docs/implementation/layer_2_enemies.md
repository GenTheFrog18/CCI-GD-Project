# Layer 2 Enemies — Implemented Foundation

This is the current code contract. The longer design intent remains in `docs/layer_2_enemies_programmer_handoff.md`.

## Content IDs and files

| ID | Scene | Main behavior |
|---|---|---|
| `canopy_primate` | `game/enemies/layer2/canopy_primate.tscn` | Grounded frog jumps, sight-first spacing, coordinated gravity-rock throw |
| `tremor_hound` | `game/enemies/layer2/tremor_hound.tscn` | Ranks sound intensity/priority, travels to the recorded position, confirms nearby prey, then pounces |
| `carrion_stalker` | `game/enemies/layer2/carrion_stalker.tscn` | Periodically scores nearby Bleed, Poison, and low-health prey; otherwise roams neutrally |
| `bulwark_beast` | `game/enemies/layer2/bulwark_beast.tscn` | Telegraphs, locks one horizontal direction, charges for 50 base damage, then has a recovery window |
| `sky_hunter` | `game/enemies/layer2/sky_hunter.tscn` | One independently damageable flying flock member with chase, telegraph, strike, and recovery |
| flock owner | `game/enemies/layer2/sky_hunter_flock.tscn` | Creates the stable member set and owns shared attack spacing and persistence |

The matching placer-facing definitions are in `data/enemies/`. The persistent flock ID is `layer_2_sky_hunter_flock`; its default stable member IDs are `sky_hunter_0` through `sky_hunter_2`.

## Shared behavior

- `game/enemies/enemy_support.gd` owns health, status, same-species rejection, electric interruption, detector suppression, disabled-flight fall damage, and ordinary enemy save data.
- `game/enemies/attack_group_coordinator.gd` limits concurrent attacks and shares a temporary last-known alert. Each Primate placer must supply one unique `spawn_group_id`; the flock owns a separate coordinator.
- `game/projectiles/projectile.gd` now exposes `gravity_scale`. Primate rocks set it to `1.0`; other existing projectiles remain unchanged at `0.0`.
- All attacks route through `ImpactData`, so Plate Umbrella blocking, cross-species damage, force, and attached effects use the same receiver contract.
- Bolt Shock applies `electro_stunned` and detector suppression. Flying Sky Hunters fall and take configured landing damage; a stunned individual does not stop the flock.

## Inspector tuning

Select an enemy scene root to tune movement, patrol range, telegraph, attack speed/duration, damage, force, recovery, scan interval, and target thresholds. Select `EnemySupport` to tune health-adjacent resistance values. The `EnemyDefinition` resource remains the authoritative roster health/tags used when the catalog loads.

For level placement:

- Place ordinary enemy scenes through `game/world/placers/layer2_enemy_placer.tscn`; one Hound per first-pass placer is recommended.
- The placer automatically gives every spawned Primate its placer `persistent_id` as the group ID unless the optional `spawn_group_id` override is set.
- The flock owner is already allocated once in `layer_2.tscn`; do not place individual Sky Hunters through ordinary placers.
- Leave readable horizontal ground around Hounds and Stalkers and a clear avoidance lane around a Bulwark.

## Save boundary

Ordinary enemies save through `EnemySupport`: alive/dead, health, persistent statuses, and position. They restore into a safe roaming/patrol state rather than resuming an attack. The flock owner saves the dead-member list plus each survivor’s health, statuses, and position; individual Sky Hunters deliberately do not register themselves as separate persistent objects.

## Verification and remaining work

`tests/content_smoke.gd` validates catalog registration, runtime tags, coordinator limits, Hound sound position memory, Stalker retaliation, Bulwark interruption rules, and flock ownership.

Alarm Grazer and Glasswings remain removed. Final art/audio, authored navigation helpers, drop rewards, and balance fine-tuning remain intentionally deferred. Layer integration, placer group injection, activation, and the shop safe boundary are implemented and documented in `layer_2_world_integration.md`.
