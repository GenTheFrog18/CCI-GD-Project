# Layer 2 Enemies — Implemented Foundation

> **Status:** code foundation exists, but Layer 2 is not part of normal current progression. Scene exports and `data/enemies/*.tres` are tuning authority.

## Roster

| ID | Implemented role |
| --- | --- |
| `canopy_primate` | Grounded jumping ranged enemy; maintains spacing and throws gravity rock through placer-owned coordination group. |
| `tremor_hound` | Sound-first grounded hunter; investigates entity-source position, searches with stop/go roaming, confirms nearby player, pounces, then retreats during recovery. |
| `carrion_stalker` | Periodically scores Bleed, Poison, and low-health prey; shadows, prepares, bites, then retreats. |
| `bulwark_beast` | Patrols, telegraphs one locked horizontal charge, hits hard, and exposes a long recovery window. |
| `sky_hunter` | Independently damageable flying flock member with chase, telegraph, strike, and recovery. |
| flock owner | Creates stable Sky Hunter members and owns shared attack spacing plus persistence. |

Alarm Grazer and Glasswings are not implemented roster members.

## Shared contracts

- All attacks use `ImpactData`; same-species filtering, Plate Umbrella interaction, force, and status remain shared.
- `EnemySupport` owns health/status/flash/save/electric disable.
- `AttackGroupCoordinator` limits simultaneous attacks and shares temporary alerts. Primate placer supplies an independent `spawn_group_id` unless explicitly overridden.
- Sky Hunter flock owns one coordinator and saves member state; individual members do not register separate persistent objects.
- Bolt Shock can disable flight and cause landing damage without disabling the entire flock.
- F3 categories show health, combat hitboxes, sensors, enemy ranges, and pathfinding separately.

## Tremor Hound movement

`GroundTraversal2D` is used for route attempts, with local movement fallback. Sound events prefer `entity_source.get_detection_origin()`/global position over listener position. Investigation first targets sound centre; after arrival it searches using the same burst/pause values as roaming.

Search must continue horizontal movement and gravity when player enters proximity area. Proximity may confirm target but cannot freeze velocity. Stall detection tries jump or a short opposite-direction escape. Recovery uses run animation and moves away from player for the full recovery duration.

The debug `pathfinding` category displays remembered sound centre and route target.

## Placement

- Ordinary enemies use `game/world/placers/layer2_enemy_placer.tscn`.
- Give every placer a globally unique persistent ID.
- Primates spawned by one placer share its default group; use `spawn_group_id` only for explicit cross-placer grouping.
- Hound/Stalker need connected ground; Bulwark needs a readable charge lane.
- Sky Hunter flock owner already belongs in Layer 2 root. Do not place individual members through ordinary placer.

## Persistence

Ordinary enemies save alive/dead, health, persistent status, and position, then restore into neutral roam. Flock saves dead member IDs plus survivor health/status/position. Target, telegraph, attack lease, search route, and sound queue are transient.

## Verification status

`tests/content_smoke.gd` covers roster registration, tags, coordinator behavior, Hound sound memory, Stalker retaliation, Bulwark interruption, and flock ownership. `tests/ground_traversal_smoke.gd` covers route generation/execution and Hound integration.

Both suites had pre-existing Hound-related assertion failures during the 30 August documentation audit. Do not claim Layer 2 enemy foundation green until those tests and manual generated-map behavior pass.
