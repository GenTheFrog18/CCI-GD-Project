# Layer 2 Relics Implementation Contract

This file records implemented behavior, save boundaries, Inspector tuning, and the level-designer handoff. It must be updated in the same checkpoint as relic code.

Stable IDs are `plate_umbrella`, `lacerator`, `resonance_core`, `bolt_shock`, and `whistle_moon`. All four relics default to one item per stack and one acquisition per run. Umbrella and Lacerator use deterministic unique loot allocation, Core uses a required unique allocation, and Bolt Shock is quest-only.

- Plate Umbrella: both actions toggle; cursor-facing directional block; no throwing; durable stability/recovery; movement, jump, and Rope modifiers.
- Lacerator: primary loads, secondary fires, context unloads safely; four adjustable shots; persistent gravity balls with four accepted contacts and shared Bleed.
- Resonance Core: primary unavailable, secondary throws; physical impacts deal adjustable damage/force, emit tiered `SoundEvent`s, and discover on first qualifying resonance.
- Bolt Shock: primary loads, secondary fires; seven non-rechargeable uses; straight rod; accepted hit interrupts, suppresses detectors, stuns movement, applies low electrical DOT, and disables flight.

Final art, audio, and balance are intentionally deferred. Placeholder presentation must still make active state, aim, telegraph, impact, and failure readable.

## Implemented foundation

- `Layer2RelicBehavior` prepares Umbrella/Lacerator/Bolt without duplicating inventory logic. Prepared launchers are real consumed instances; cancellation returns the same state unarmed.
- `PreparedLayer2Relic` owns cursor aim, Umbrella stability, and launcher firing. Lacerator creates `LaceratorBall`; Bolt creates `BoltShockRod`.
- `ResonanceCoreBehavior` reuses normal thrown-item weight, pickup, preview, persistence, and collision behavior while adding tiered resonance.
- `ItemDefinition.recover_out_of_bounds` returns Core and Bolt pickups to `quest_item_recovery_marker`; other relics use ordinary loss rules.
- Durable state keys are `stability`, `recovery_remaining`, `remaining_ammo`, and `remaining_uses`. `loaded` is always false outside a prepared action.
- `Layer2Gatekeeper` uses a two-interaction confirmation before taking exactly one Core. It immediately saves the idempotent `layer_2_core_rewarded` flag, Moon rank/physical Moon Whistle, and one seven-use Bolt Shock. A failed inventory insertion creates the protected persistent pickup `layer_2_bolt_shock_reward` at the shop marker.

## Provisional values

| Relic | Defaults |
| --- | --- |
| Plate Umbrella | weight 8; stability 100; arc 120°; open/close 0.3 s; forced recovery 2 s; movement/jump/climb 0.6/0.75/0.6 |
| Lacerator | weight 4; 4 shots; 260 speed; 3 damage; 8 s Bleed; 4 accepted ball contacts |
| Resonance Core | weight 18; 100 impact damage; resonance tiers at 80/180/280 impact strength |
| Bolt Shock | weight 5; 7 uses; 500 speed; 10 impact damage; 3 s stun; 5 s suppression; 6 one-damage ticks |

These values live in item resources and remain editable without changing scripts.
