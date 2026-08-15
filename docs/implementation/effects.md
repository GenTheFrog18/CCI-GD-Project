# Effects Implementation Contract

## Ownership

`EffectDefinition` owns stable ID, display name, duration, stacking, maximum stacks, persistence, eligibility, tick data, and modifiers. `StatusController` owns applications. World areas own provider tokens and remove only their own contribution on exit. Runtime Node references are never saved; provider-area effects are transient.

Application data may override duration/modifiers and include serializable `source_id` and `provider_id`. Multipliers combine multiplicatively; health-cap reductions add; clamp once after aggregation except deliberate immobilisation. Status ticks bypass physical i-frames, may kill, and do not apply force, physical hit reaction, or bird counters.

Gameplay and inventory advance timers. Pause, menu, loading, and inactive processing stop them.

| ID | Rule | Save | Result |
| --- | --- | --- | --- |
| `bleed` | refresh | yes | adjustable 1 damage/second; Bandage removes |
| `poison` | refresh | yes | five 5-damage ticks/10 seconds; Bandage does not remove |
| `spider_slow` | refresh | yes | movement reduction; flying immune |
| `resin_bound` | per provider | no | movement/jump reduction, 0.5 knockback; flying immune |
| `incapacitated` | replace | no | gameplay lock and Rope detach |
| `tracking_mark` | refresh | yes | high-priority request visible only to large flyer |
| `dazzled` | refresh | yes | player overlay; enemy sight disabled |
| `healing` | refresh | yes | adjustable Bandage healing; provisional 2 HP/s for 25 s |
| `curse_suppression` | additive to 999 s | yes | consumes Curse thresholds |
| `driftseed` | refresh | yes | lower gravity/descent, higher knockback; lower flight speed |
| `curse_layer_1` | refresh/reroll | yes | movement, healing, throw, colour penalties for 20 s |
| `curse_layer_2_penalty` | refresh | yes | throw/colour and movement-stop clock for 40 s |
| `curse_layer_2_health_cap` | independent stacks | yes | 10% cap each, max five, each 40 s |

Every effect shows its normal name below health. Show stack counts above one. Overlays never cover HUD. Debug can clear effects and apply healing/current-layer Curse.
