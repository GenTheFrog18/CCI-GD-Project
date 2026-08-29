# Layer 1 Items Implementation Contract

> **Status:** current runtime contract. Item Resource and attached behavior Resource are tuning authority.

## Shared rules

- Primary and secondary behavior are explicit; `behavior` is compatibility fallback.
- Failed action never consumes or mutates item.
- Prepared action transfers one real unit out of inventory; cancel returns that unit/state when possible.
- Inactive throw creates persistent `ThrownItem`; prepared throw keeps active state.
- Default/stateless compatible instances may stack. Stateful forms remain individual.
- Signature use increments discovery only after successful behavior.
- Map/enemy drop origin remains in instance state for theft/confiscation/progression rules.
- World collision comes from `world_hitbox` or `world_hitbox_scene`; fallback is generic circle.

## Supplies and tools

| Item | Primary | Secondary |
| --- | --- | --- |
| Red/Blue/Moon Whistle | High-priority sound from dedicated whistle slot | Not an active hotbar throw contract |
| Multitool | Cursor-facing thrust for special interaction, breakable, then damage | Disabled; cannot be thrown |
| Rope | Place or extend persistent 160 px climbable Rope | Ordinary physical throw |
| Throwable Rock | Multitool-style short thrust | Physical throw with velocity-scaled impact |
| Bandage | Reject at full HP, remove Bleed, add 15 s Healing (30 HP total) | Ordinary physical throw |
| Info Book | Reveal every currently registered discoverable item description | Ordinary physical throw |
| Numbing Pill | Add 300 s Curse suppression up to 999 s | Ordinary physical throw |

The current Numbing Pill description says 180 s while code applies 300 s. This is a known content mismatch; runtime value above is authoritative until design resolves it.

## Layer 1 relics

| Item | Primary | Secondary/impact |
| --- | --- | --- |
| Sun Sphere | Prepare carried active light | Active sphere can be thrown while remaining active; inactive impact at speed threshold converts into moving active light |
| Lantern Crystal | Immediate LOS flash/sound around player | Physical throw; qualifying impact flashes actors with clear head LOS, emits sound, consumes crystal |
| Rattlepod | Prepared pod sends ten strong pulses over roughly 5 s | Inactive physical/recoverable throw |
| Hushcap | Small detector-suppression cloud at player | Qualifying impact creates larger cloud and consumes item |
| Cling Resin | Small resin patch at player | Qualifying impact creates larger patch; loose-item velocity decays by configured multiplier while inside |
| Driftseed | Apply Driftseed to player for 30 s | Qualifying hit applies it to valid actor; miss remains recoverable |
| Silver Weight | Prepared heavy carry with movement/jump penalty | Multi-hit 200 damage; first qualifying impact becomes intermediate damaged world form |

## Special world behavior

Hushcap cloud owns layered player overlay. Enter/exit count prevents overlapping clouds from fighting; fade times and layer opacity are editable on overlay scene.

Resin uses provider status for actors and continuous velocity damping for loose items. Entry must not zero horizontal velocity. Flying enemies reject `resin_bound`.

Lantern flash raycasts from source to player `get_detection_origin()`. Snail and crystal use the same visibility rule. Player dazzled overlay captures viewport image plus white fill, fades in, then decays from remaining effect time.

Sun Sphere impact activation creates `PreparedRelic`, copies transform and impact velocity, and defers tree/physics changes. It does not disappear into a static effect area.

## Silver Weight lifecycle

```text
silver_weight inventory
  -> qualifying impact
silver_weight_impact_damaged world item
  -> pickup
silver_weight_damaged inventory
  -> qualifying impact and later comes to rest
destroyed
```

Intermediate world form is pickupable and persistent. It becomes normal damaged ID only when player/frog takes it. A damaged weight thrown again remains physical until it is still and available, then removes itself.

## World/save boundary

- Inactive drops, Rope, moving throws, intermediate Silver Weight, and recoverable quest items save.
- Temporary cloud/resin, warning visuals, active Rattlepod pulses, and spent active forms do not restore.
- Actor statuses save according to `EffectDefinition.persists`.
- `recover_out_of_bounds` sends protected Core/Bolt objects to authored recovery marker; ordinary items are destroyed.

## Acceptance

- Preview and actual throw use identical launch velocity.
- Inventory commits only after world/prepared node succeeds.
- Physics monitoring/mode changes from impact are deferred.
- Hushcap blocks enemy detector updates.
- Resin slows loose items over time without erasing momentum at entry.
- Lantern/Snail flash respects LOS to player head.
- Sun Sphere keeps motion after activation.
- Silver Weight follows all three IDs without duplicate or premature disappearance.
