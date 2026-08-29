# Layer 2 Relics — Implemented Foundation

> **Status:** code and content Resource exist, but Layer 2 is outside normal current progression. Resource/scene exports are tuning authority.

## Stable IDs

`plate_umbrella`, `lacerator`, `resonance_core`, `bolt_shock`, and `whistle_moon`.

## Behavior

| Relic | Current contract |
| --- | --- |
| Plate Umbrella | Primary or secondary toggles opening/closing. Open cursor-facing block reduces accepted directional damage while force still acts. Stability and forced recovery persist in item state. Not throwable. |
| Lacerator | Primary loads, secondary fires one gravity ball. Context change unloads without spending ammunition. Ball persists, accepts four contacts, and applies Bleed. Not throwable. |
| Resonance Core | No primary. Secondary uses ordinary weighted physical throw plus high impact damage and tiered SoundEvent. Qualifying impact discovers it. Protected out-of-bounds recovery. |
| Bolt Shock | Primary loads, secondary fires one straight rod from seven-use capacity. Hit interrupts, suppresses detectors, electrically stuns, applies electrical DOT, and disables flight. Context change unloads safely. Protected recovery. |
| Moon Whistle | Progression/physical whistle granted with Core exchange foundation. |

## Runtime ownership

- `Layer2RelicBehavior` prepares Umbrella/Lacerator/Bolt without special inventory mutation.
- `PreparedLayer2Relic` owns aim, transition state, Umbrella blocking/stability, and launcher firing.
- `LaceratorBall` and `BoltShockRod` own their payload lifecycle.
- `ResonanceCoreBehavior` reuses `ThrownItem` preview, weight, collision, pickup, and save.
- Durable keys include stability/recovery/ammunition/use counts. `loaded` is transient and false outside prepared action.

## Quest foundation

`Layer2Gatekeeper` uses two interactions to accept one `resonance_core`. Reward path sets idempotent progression flag, Moon rank/physical whistle, and one Bolt Shock. Failed inventory insertion creates protected persistent pickup at reward marker.

This exchange is not reachable through normal current progression and does not redefine the current Layer 2-gate ending.

## Placement and persistence

- Umbrella and Lacerator use optional run-wide allocation groups.
- Resonance Core uses required run-wide allocation.
- Bolt Shock is quest reward, not ordinary loot placer content.
- All stateful relics remain max-stack-one in practice.
- Core/Bolt world forms use `recover_out_of_bounds` and authored `quest_item_recovery_marker`.

## Verification status

`tests/content_smoke.gd` covers registration, prepared state, impact behavior, quest reward, and recovery. The Resonance Core assertion was failing before the 30 August documentation audit; runtime/test correction remains separate work.
