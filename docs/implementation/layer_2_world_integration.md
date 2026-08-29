# Layer 2 World Integration — Foundation Status

> **Status:** implemented foundation, not normal current progression. Current playable build ends at the gate from Layer 1 to Layer 2.

## Available content

| Template/system | Purpose |
| --- | --- |
| `layer2_enemy_placer.tscn` | Weighted Primate, Hound, Stalker, or Bulwark spawn. |
| `plate_umbrella_placer.tscn` | Optional unique Umbrella candidate. |
| `lacerator_placer.tscn` | Optional unique Lacerator candidate. |
| `resonance_core_placer.tscn` | Required unique Core candidate. |
| Layer 2 shop | Shop service, Curse safe zone, combat safe zone, enemy-only boundary. |
| Layer 2 Gatekeeper | Core confirmation/reward foundation. |
| Sky Hunter Flock | One persistent flock owner with activation zone. |

Every placed placer needs a globally unique `persistent_id`. Preserve relic allocation group IDs. Quantity may reuse one SpawnPoint; multiple child markers are only needed for authored position variety.

## Shop safety

Layer 2 root contains overlapping shop systems near its authored shop:

- Curse safe zone resets ascent reference.
- Combat safe zone makes player reject hostile acquisition/impact.
- Enemy boundary blocks Layer 2 enemies while player/projectiles pass.

Resize these together when map changes. A visual shop area that disagrees with safety/boundary shapes is invalid authoring.

## Resonance Core exchange

1. Player carries Core and interacts.
2. First interaction asks confirmation and preserves Core.
3. Second interaction within confirmation window removes one Core.
4. Reward grants Moon rank, physical Moon Whistle, and Bolt Shock.
5. `layer_2_core_rewarded` prevents duplication across load/reinteraction.
6. Full inventory drops protected reward at authored marker.

The quest does not control the current Layer 2 gate ending.

## Sky Hunter Flock

One flock owner in Layer 2 root creates stable members, owns attack coordination, and saves dead/survivor state. `FlockActivationZone` sets persistent activation flag and wakes flock near current route. Individual Sky Hunters must not be ordinary placer entries.

## Legacy Layer 3 content

Layer 2 templates, `WorldGenerator`, debug teleport, and `Layer3Entrance` still contain old jam-ending requirements. These are preserved code history, not current GDD commitment. New Layer 2 map work must not depend on them until a future world-scope decision replaces the legacy contract.

## Debug and verification

F3 can teleport to Layer 2 shop/legacy ending location, grant Layer 2 relics, and spawn ordinary Layer 2 enemies. These are development paths only.

Before Layer 2 enters normal progression, verify:

- every generated layout contains required allocations;
- shop safety shapes agree;
- Core reward cannot duplicate and survives Continue;
- flock activation/persistence works;
- Hound traversal tests pass;
- Layer 2 entry/return and eventual ending contract are redesigned against current GDD.
