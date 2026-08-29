# Effects Implementation Contract

> **Status:** current runtime contract, audited 30 August 2026. Tuning authority is `data/effects/*.tres`.

## Ownership

`EffectDefinition` owns stable ID, display name, default duration, stack rule, additive cap, max stacks, tick data, persistence, eligibility, icon, and modifiers. `StatusController` owns runtime applications.

Application data may override duration/modifiers and include serializable `source_id` and `provider_id`. Reapplying the same provider replaces only that provider's application. Area exit removes only its own provider contribution.

Timers advance while gameplay processes. Persistent effects are captured in run save; transient provider areas are rebuilt from world state.

## Stack behavior

- `REFRESH`: replace applications with the newest one.
- `STACK`: add until `max_stacks`, then replace the shortest remaining application.
- `REPLACE`: replace existing applications.
- `IGNORE`: reject while already active.
- `additive_duration_cap > 0`: bypass normal stack rule and add duration to the longest application up to cap.

Multipliers combine multiplicatively. Health-cap handling is actor-specific. Tick damage bypasses physical invulnerability, may kill, and does not create knockback/direct-hit reaction.

## Active effects

| ID | Current behavior | Save |
| --- | --- | --- |
| `bleed` | 1 damage each second for default 8 s. Thorn Needle adds configured duration through a dedicated 80 s cap. Bandage removes it. | Yes |
| `poison` | 5 damage every 2 s; applications add duration up to 15 s. | Yes |
| `spider_slow` | Move speed ×0.65; adds duration up to 10 s; flying actors reject it. | Yes |
| `tracking_mark` | Large Flyer high-priority target request; adds duration up to 20 s. | Yes |
| `healing` | 2 HP each second; Bandage adds duration up to 50 s. | Yes |
| `dazzled` | Sight disabled and player flash overlay; adds duration up to 10 s. | Yes |
| `detector_suppressed` | Sight and sound disabled. Used by Hushcap/electric systems. | No |
| `electro_stunned` | Movement/attack/flight multipliers become zero; flying enemy falls through `EnemySupport`. | No |
| `electrocuted` | 1 damage each second for default 6 s. | Yes |
| `resin_bound` | Provider-stacked move/jump reduction and knockback resistance; flying actors reject it. | No |
| `incapacitated` | Short movement/control lock used by attacks. | No |
| `driftseed` | Gravity ×0.25, received knockback ×1.5, flight speed ×0.6. | Yes |
| `curse_suppression` | Remaining time consumed by Curse threshold crossings. Numbing Pill applies its own duration. | Yes |
| `curse_layer_1` | Movement, healing, and throw penalties; 20 s default. | Yes |
| `curse_layer_2_penalty` | Throw penalty and Layer 2 stop-roll package; 40 s default. | Yes |
| `curse_layer_2_health_cap` | Independent 10% cap applications, maximum five, 40 s each. | Yes |
| `test_slow` | Smoke-test-only move multiplier. | No |

## Presentation and debug

Player HUD lists active effect name, stack count above one, and remaining seconds when configured. EnemySupport creates the same effect text above every enemy. F3 can apply available effects, clear them, and show enemy health/status labels.

Hushcap suppression must prevent sensor updates, not merely hide detection feedback. Electric stun must interrupt attacks through `EnemySupport.request_interrupt()` in addition to modifier checks.

## Extension checklist

1. Add one `EffectDefinition` with unique ID.
2. Choose stack rule or additive cap deliberately.
3. Set persistence and valid actor tags.
4. Route applications through `apply_status()`; do not edit `StatusController.active` externally.
5. Add a content smoke assertion for registration and critical stacking/tick behavior.
