# Layer 2 Relics Implementation Contract

This file records implemented behavior, save boundaries, Inspector tuning, and the level-designer handoff. It must be updated in the same checkpoint as relic code.

Stable IDs are `plate_umbrella`, `lacerator`, `resonance_core`, `bolt_shock`, and `whistle_moon`. All four relics default to one item per stack and one acquisition per run. Umbrella and Lacerator use deterministic unique loot allocation, Core uses a required unique allocation, and Bolt Shock is quest-only.

- Plate Umbrella: both actions toggle; cursor-facing directional block; no throwing; durable stability/recovery; movement, jump, and Rope modifiers.
- Lacerator: primary loads, secondary fires, context unloads safely; four adjustable shots; persistent gravity balls with four accepted contacts and shared Bleed.
- Resonance Core: primary unavailable, secondary throws; physical impacts deal adjustable damage/force, emit tiered `SoundEvent`s, and discover on first qualifying resonance.
- Bolt Shock: primary loads, secondary fires; seven non-rechargeable uses; straight rod; accepted hit interrupts, suppresses detectors, stuns movement, applies low electrical DOT, and disables flight.

Final art, audio, and balance are intentionally deferred. Placeholder presentation must still make active state, aim, telegraph, impact, and failure readable.
