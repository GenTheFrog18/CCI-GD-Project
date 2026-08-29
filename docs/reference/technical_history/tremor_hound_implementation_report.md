# Tremor Hound Implementation Report

> **Archived:** point-in-time report. Current contract: [`../../implementation/layer_2_enemies.md`](../../implementation/layer_2_enemies.md).

Status: Layer 2 prototype exists; final behavior is not complete.

This report consolidates the current Tremor Hound code, scene, enemy definition, Layer 2 handoff, implementation contract, placer guidance, clarification answers, and smoke-test coverage. The Layer 2 handoff is a guideline: existing shared systems and project conventions take priority over copying its suggested class names literally.

## 1. Enemy identity

| Field | Current value |
| --- | --- |
| Content ID | `tremor_hound` |
| Scene | `game/enemies/layer2/tremor_hound.tscn` |
| Script | `game/enemies/layer2/tremor_hound.gd` |
| Definition | `data/enemies/tremor_hound.tres` |
| Role | Sound-driven grounded pouncer |
| Main regions | Layer 2 middle forest and bottom passages |
| Recommended tags | `enemy`, `small_enemy`, `grounded`, `sound_hunter`, `layer_2` |
| Current default health | 32 |
| Current default damage | 15 |
| Current default force | 210 |

The Hound should create danger from player-generated disturbances, not from magically knowing the player’s position. It turns footsteps, impacts, landings, attacks, and loud relics into investigation pressure. Once it confirms the player at close range, it commits to a readable pounce.

## 2. Intended gameplay philosophy

The Hound asks: “Where can the player safely create noise or impact?”

It should:

- Hear a disturbance at its actual world position.
- Decide whether the disturbance is worth investigating using priority, intensity, distance, recency, and category.
- Travel to the recorded position rather than tracking the player directly.
- Search locally after reaching that position.
- Confirm the player only at close range using short sight plus very small proximity/contact confirmation.
- Telegraph a pounce, commit its launch direction, and recover after the attack.
- Eventually return to its home territory if the investigation leads too far away or becomes stale.
- Remain grounded and require usable horizontal terrain.
- Work as part of the shared damage, force, status, detector-suppression, sound, warning, and save systems.

It is a pressure enemy, not a permanent chase enemy. Standing still should reduce new movement noise, but should not make the player immune to close-range confirmation.

## 3. Required disturbance sources

The intended compatible event sources are:

- Low-intensity grounded walking footsteps.
- Jump and normal landing events.
- Hard landing events.
- Rope jump-off; Rope climbing itself is quiet.
- Player or enemy attack impacts.
- Projectile impacts on terrain.
- Dropped or thrown heavy items.
- Resonance Core pulse.
- Rattlepod pulses.
- Whistles.
- Primate rock impacts.
- Bulwark charge collisions.

Disturbance handling rules:

- A new event replaces the stored event only when its score exceeds the current stored score by a margin.
- Old event scores decay with age.
- A short retarget cooldown prevents jitter.
- Repeated weak footsteps may eventually matter after stronger events age out.
- Hushcap blocks close-range sight but does not mute footsteps or impacts.
- Driftseed reduces landing intensity because it reduces falling speed.
- Detector suppression prevents accepting new disturbance events.

The existing project uses `SoundEvent`, which already carries `position`, `radius`, `priority`, `intensity`, `sound_type`, `source`, and `timestamp`. A separate `DisturbanceEvent` is not mandatory if `SoundEvent` is extended or interpreted consistently.

## 4. Intended state machine

```text
SPAWN
  -> PATROL / IDLE
  -> INVESTIGATE
  -> SEARCH
  -> CONFIRMED_TARGET
  -> PREPARE_POUNCE
  -> POUNCE
  -> RECOVER
  -> PATROL

INVESTIGATE / SEARCH timeout or territory limit
  -> RETURN_HOME
  -> PATROL

Bolt Shock or valid interrupt during preparation
  -> STUNNED / RECOVER

Health reaches zero
  -> DEAD
```

State responsibilities:

- `PATROL`/`IDLE`: move within the authored home territory; accept disturbances.
- `INVESTIGATE`: move toward the stored event position. Do not update the target to the player’s current position.
- `SEARCH`: perform local movement/search around the event position after arrival.
- `CONFIRMED_TARGET`: use close-range sight/proximity confirmation before attacking.
- `PREPARE_POUNCE`: stop or visibly prepare, warn the player, and capture the launch direction.
- `POUNCE`: move at committed speed/direction; do not sharply retarget in flight.
- `RECOVER`: provide a real vulnerable recovery window after hit or miss.
- `RETURN_HOME`: abandon an overextended investigation and travel back to the home point/territory.
- `STUNNED`: detector suppression and electric stun prevent new acquisition and cancel preparation safely.

## 5. Current implementation

The current script contains only:

```text
PATROL, INVESTIGATE, SEARCH, PREPARE, POUNCE, RECOVER
```

Current behavior:

- Gravity and horizontal movement are implemented.
- Patrol direction is generated from a time-based sine wave.
- Sound events are accepted through `SoundListener` when detector suppression allows them.
- Event score is currently:

```text
event.priority * 100 + event.intensity - distance * 0.2
```

- The highest-scoring event replaces the stored investigation position immediately.
- The Hound moves horizontally toward the stored event position.
- Reaching the position enters a short `SEARCH` state.
- If a player is within `close_confirmation_radius`, the Hound immediately enters `PREPARE`.
- Preparation captures a direction toward the player and warns the player.
- Pounce moves at fixed speed for a fixed duration.
- The first slide collision applies `ImpactData` with pounce damage, force, and attack kind `hound_pounce`.
- A miss or successful hit enters `RECOVER`.
- `interrupt_action` can cancel only `PREPARE`.
- Electric stun currently falls through a physics branch rather than using a dedicated Hound state.
- The scene uses a placeholder `Polygon2D` visual.
- The scene has a SoundListener and an editor preview for `close_confirmation_radius`.
- Save/load delegates to `EnemySupport`; restore resets AI to patrol and clears the stored investigation score.

## 6. Missing or incomplete feature work

These are feature gaps, not merely balance or bug fixes:

### Disturbance model

- No category multiplier system exists.
- No age decay exists in Hound scoring.
- No score replacement margin exists.
- No retarget cooldown exists.
- No explicit disturbance producers cover the complete required source list.

### Detection and investigation

- Current close confirmation is distance-only; it does not perform short sight blocked by terrain/Hushcap plus tiny proximity confirmation.
- Current Hound can confirm the player while patrolling or investigating without the intended confirmed-target stage.
- There is no explicit stored event lifetime or territory pursuit limit.
- There is no return-home state.
- `patrol_bounds` is exported but not used by the current patrol movement.
- Current patrol has no authored territory/home-area integration.

### Attack behavior

- The Hound has no explicit confirmed-target phase before preparation.
- Pounce direction is captured, but launch movement and terrain handling need to be verified against the committed-attack contract.
- There is no animation-driven preparation, launch, or hitbox timing.
- Pounce warning currently uses the player warning API, but final visual/audio telegraph presentation is not authored.
- There is no complete interruption contract for all supported relics and impacts.

### Shared Layer 2 integration

- No dedicated Hound disturbance event exists; it currently consumes ordinary `SoundEvent` data.
- Group alert and attack-token coordination are not used by the Hound, which is acceptable for a solo first-pass Hound but must remain compatible with ecosystem events.
- Cross-enemy disturbance reactions are not fully wired: Primate rock impacts, Bulwark collisions, Hound pounce impacts, and Resonance Core strength need explicit event coverage.
- Layer 2 territory helpers are suggested in the design but are not represented by a dedicated Hound territory scene/component.

### Presentation

- The Hound still uses a placeholder polygon visual.
- Final Hound sprite, animations, attack timing, sound effects, and encounter feedback are not present in the current asset contract.
- F3 range/state/hitbox visualization is not documented as complete for the Hound.

### Persistence

- Health, alive state, statuses, and position come from `EnemySupport`.
- Investigation target and patrol state intentionally reset on restore.
- Home territory/section identity is not stored by the Hound itself.
- Mid-pounce, stun, and detector suppression restore behavior needs explicit verification against the Layer 2 save rules.

## 7. Tuning values

Current scene/script exports:

| Property | Current default | Intended use |
| --- | ---: | --- |
| `patrol_bounds` | `Rect2(-160, 0, 320, 0)` | Authored horizontal territory; currently unused by movement |
| `gravity` | `900` | Grounded fall acceleration |
| `patrol_speed` | `42` | Home patrol speed |
| `investigation_speed` | `76` | Movement toward disturbance |
| `close_confirmation_radius` | `52` | Short confirmation range |
| `pounce_prepare_duration` | `0.75 s` | Telegraph/preparation time |
| `pounce_speed` | `250` | Committed launch speed |
| `pounce_duration` | `0.55 s` | Maximum pounce duration |
| `pounce_damage` | `15` | Direct pounce damage |
| `pounce_force` | `210` | Pounce force |
| `recovery_duration` | `1.2 s` | Post-pounce vulnerability |
| `search_duration` | `2 s` | Local search duration |

Definition-level defaults are health `32`, movement `76`, damage `15`, knockback `210`, and detection range `300`. Scene/script values currently control most runtime behavior; future tuning should keep one clear source of truth and avoid silently diverging definition and scene values.

## 8. Relic and enemy interactions

| Interaction | Required result |
| --- | --- |
| Plate Umbrella | Frontal pounce damage reduced; stability loss and force still matter |
| Lacerator | Impact creates a disturbance; Bleed can redirect Carrion Stalker; timed hit may interrupt preparation |
| Resonance Core | Very strong investigation event based on impact strength |
| Bolt Shock | Detector suppression and stun; safely cancels pounce preparation |
| Rattlepod | Strong repeated lure; Hound investigates the active pod location rather than magically tracking the player |
| Hushcap | Blocks close-range sight; does not mute footsteps or impacts |
| Lantern Crystal | Dazzles sight and creates a high-priority sound location |
| Driftseed | Reduces player landing disturbance and increases knockback vulnerability |
| Silver Weight | Strong impact lure; valid hit uses the shared small-enemy damage rule |
| Primate rock | Terrain impact becomes a Hound investigation event |
| Bulwark charge | Collision creates a strong Hound investigation event |
| Hound pounce on another species | Shared impact can create a Carrion Stalker reevaluation event |

All interactions should use shared damage, force, status, sound, and interruption interfaces. Relics should not directly mutate Hound state.

## 9. Placer and world-authoring requirements

- Use `game/world/placers/layer2_enemy_placer.tscn` for ordinary Hound placement.
- First-pass encounters should spawn one Hound per placer.
- Place Hounds only where normal horizontal footing exists.
- Give each Hound a readable horizontal approach and pounce/landing lane.
- Assign a unique persistent spawn key through the placer system.
- Use an authored home point or territory area when the territory helper is available.
- Keep Hounds away from rooms where unavoidable movement constantly emits maximum-priority disturbances.
- Spawn results must remain deterministic for the same world seed and spawn key.

## 10. Save/load contract

Persist:

- Alive/dead state.
- Current health.
- Persistent statuses and remaining durations supported by the status system.
- Current section/home territory or safe world position.
- Stable placer/persistent ID.

Safe reset on load:

- Clear investigation target if desired by the shared save policy.
- Do not resume a damaging pounce halfway through.
- Do not restore an invalid terrain position.
- Re-enable detectors unless detector suppression is persisted safely.
- Clear stale player/source references.
- Restore the Hound to patrol, recovery, or another neutral state.

## 11. Acceptance tests

### Disturbances

- Walking creates a low-intensity event.
- Jump/landing and hard landing produce stronger events.
- Rope climbing produces no event; Rope jump-off produces an event.
- Heavy item impacts, Rattlepod, Whistle, Resonance Core, Primate rock, and Bulwark collision reach the Hound with correct position and strength.
- A stronger new event replaces a weaker stored event only after the configured score margin.
- Old events decay and eventually stop dominating new events.

### Detection and movement

- Hound moves toward the recorded event position, not the player’s current position.
- Hushcap blocks short sight but does not remove stored investigations or sound events.
- Standing still prevents new footsteps but does not prevent close confirmation.
- Hound stays inside its territory during patrol and returns home after overextension.
- Detector suppression blocks new acquisition and group alerts.

### Attack

- Close confirmation enters a visible preparation state.
- Warning reaches the player before damage.
- Launch direction is committed before pounce.
- Pounce cannot sharply retarget in flight.
- Terrain collision ends pounce safely.
- Hit applies damage and force once per pounce.
- Miss produces a real recovery window.
- Bolt Shock/Lacerator interruption cancels preparation safely.

### Persistence and ecosystem

- Health/death/status survive save/continue.
- Hound reloads in a valid neutral state.
- Same-species damage is rejected; cross-species impact works once.
- Hound pounce and Bulwark/Primate impacts create the expected downstream events.
- Deterministic placer result is stable for the same seed and spawn key.

## 12. Open playtest tuning

The design intentionally leaves these values adjustable rather than requiring final numbers before implementation:

- Health and movement speeds.
- Hearing radius and close confirmation radius.
- Category intensity multipliers.
- Event score weights, score margin, age decay, and retarget cooldown.
- Investigation memory and search duration.
- Territory/pursuit distance.
- Preparation, pounce, and recovery durations.
- Pounce damage and force.
- Hound count per encounter.

Initial clarification decisions already made:

- Use short sight plus very small proximity/contact confirmation.
- Walking is low intensity; jump/landing and impacts are stronger; Rope climbing is quiet.
- Replace stored events only when the new score exceeds the old score by a margin; age old events and use a short retarget cooldown.
- Spawn one Hound per first-pass placer.
- Hound is sound-first; direct sight is only for close confirmation.

## Source files

- `game/enemies/layer2/tremor_hound.gd`
- `game/enemies/layer2/tremor_hound.tscn`
- `data/enemies/tremor_hound.tres`
- `game/world/placers/layer2_enemy_placer.tscn`
- `docs/reference/technical_history/layer_2_enemies_programmer_handoff.md`
- `docs/implementation/layer_2_enemies.md`
- `docs/implementation/layer_2_world_integration.md`
- `docs/pertanyaan_klarifikasi_layer_2.md`
- `docs/map_placer_authoring_reference.md`
- `tests/content_smoke.gd`
