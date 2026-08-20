# Large Layer 1 Flyer — Programmer Specification

## 1. Role and design purpose

The Large Layer 1 Flyer is one persistent, layer-wide living threat. It is not a normal per-room enemy and should not be duplicated when the player crosses between Layer 1 sections.

Its job is to make Layer 1 feel remembered and exposed:

- The player can trigger it indirectly through Tracking Mark, sound, or sight.
- It gives the player time to break sight unless a stronger system interaction overrides that delay.
- It creates pressure across multiple Layer 1 sections.
- Layer 1 decisions carry forward when the Flyer transfers to the Layer 2 shop marker.

The Flyer should remain a readable systemic threat rather than a conventional boss encounter.

## 2. Player-facing contract

- There is exactly one living Flyer instance for the run.
- Maximum health is adjustable; current default is `500`.
- Ordinary slow and ordinary knockback do not affect it.
- It accepts Poison, distraction, Driftseed, Bolt Shock, and Silver Weight damage.
- Silver Weight deals `200` adjustable damage; it does not instantly kill the Flyer.
- It chooses an authored point of interest (POI) every `15 s` by default.
- A normal visible player target requires `4 s` of continuous sight before dive commitment.
- Tracking Mark bypasses that four-second lock requirement.
- The committed dive deals `75` adjustable damage on one direct impact.
- Transparent authored blockers prevent movement through them but do not block sight.
- When the Flyer loses its target, it searches the last-known location and then returns to roaming.
- The Flyer crosses Layer 1 sections as one persistent actor.
- If alive at the Layer 2 transfer point, it appears at the Layer 2 shop marker with health and all active statuses preserved, but with transient AI reset and no target.
- The Sky Hunter Flock actively avoids being near the Flyer. The Flyer does not treat the flock as a threat or target.
- If the Flyer dies, it remains permanently dead for the run.

## 3. Current values and data ownership

| Property | Current/default value | Source or requirement |
|---|---:|---|
| Enemy ID | `large_layer1_flyer` | `large_layer1_flyer.tres` |
| Species ID | `large_layer1_flyer` | `.tres`, scene, support node |
| Tags | `flying`, `big_roamer`, `layer_global_actor` | `.tres`, scene |
| Layer | `1` | `.tres` |
| Max health | `500` | Adjustable; `.tres`/support currently use 500 |
| Roam speed | `65 px/s` | `large_flyer.gd` |
| Chase speed | `115 px/s` | `large_flyer.gd` and `.tres` move speed |
| Dive speed | `250 px/s` | `large_flyer.gd` |
| Sight range | `520 px` | `large_flyer.tscn` |
| Aggravated sight range | `650 px` | `large_flyer.tscn` |
| Sight cone | `150°` | `large_flyer.tscn` |
| Ordinary sight lock | `4 s` continuous | `large_flyer.gd` |
| POI interval | `15 s` | `large_flyer.gd` |
| Dive telegraph | `0.9 s` | `large_flyer.gd` |
| Dive damage | `75` default, adjustable | `large_flyer.gd`/enemy data |
| Dive cooldown | `4 s` | `large_flyer.gd` |
| Silver Weight damage | `200` default, adjustable | Silver Weight damage contract |
| Search duration | `15 s` default, adjustable | Current `_search_remaining` behavior |
| Tracking Mark priority | `100` example default | Adjustable target-request priority |
| Snail sound priority | `50` example default | Adjustable request priority |
| Rattlepod/Whistle/Lantern Crystal priority | `40` example default | Adjustable request priority |
| Roaming priority | `10` example default | Adjustable baseline priority |

Balance values should be editable in resources/scene configuration rather than requiring behavior-code edits.

## 4. One-instance lifetime and persistence

The Flyer must be owned by the layer/run-global enemy system, not by an individual Layer 1 section scene.

Required identity behavior:

- Spawn or restore one actor with persistent ID `large_layer1_flyer`.
- Section changes transfer the same actor or its serialized state; never spawn a second copy.
- The Flyer’s health, death state, and active statuses are persistent run state.
- Transient AI state is not persistent across section transfer.
- A dead Flyer remains dead and must not respawn because the player entered another section.

Persist:

- Current health.
- Dead/alive state.
- All active statuses, including their remaining durations/stacks according to the effect system.
- Any other explicitly persistent support state.

Reset on Layer 2 transfer:

- Current target.
- Sight timer.
- Current target request queue, unless the request system is explicitly run-global and still valid.
- Dive/telegraph state.
- Search timer and search point.
- Current chase/attack state.
- Transient POI intent.

After arriving at the Layer 2 shop marker:

1. Place the Flyer at the authored marker.
2. Restore health and active statuses.
3. Reset transient AI to roaming/idle.
4. Start with no target.
5. Reacquire through normal sensing and request rules.

## 5. Target-request priority system

The Flyer needs an explicit request system rather than a chain of special-case `if` statements. Requests can come from:

- Tracking Mark on the player.
- Lantern Snail scream.
- Rattlepod sound.
- Whistle sound.
- Lantern Crystal sound/flash event.
- Ordinary visible player sight.
- Roaming/POI selection as the baseline fallback.

Each request should contain:

```gdscript
class TargetRequest:
	var request_id: StringName
	var source: Node
	var target_position: Vector2
	var target_actor: Node2D
	var base_priority: float
	var created_at: float
	var last_updated_at: float
	var expires_at: float
	var requires_sight: bool
```

### Priority decay

Priority decreases with time. Use an adjustable decay rate:

```gdscript
var effective_priority := base_priority - priority_decay_per_second * age_seconds
```

Recommended defaults:

```text
Tracking Mark:             100
Lantern Snail scream:       50
Rattlepod/Whistle/Crystal:  40
Ordinary visible player:    20
Roaming baseline:            10
```

The exact values are adjustable. The important relationship is:

```text
Tracking Mark > Snail scream > Rattlepod/Whistle/Crystal > ordinary roaming
```

Tracking Mark bypasses the four-second ordinary sight lock. A valid marked player can become the active target immediately.

### Selection order

Every decision frame:

1. Remove expired or invalid requests.
2. Recalculate effective priority after time decay.
3. Select the valid request with the highest effective priority.
4. If effective priorities tie, select the newest request.
5. If the selected request becomes invalid, immediately select the next valid request.
6. If no request remains, use roaming priority and authored POI behavior.

“Invalid” means the target/source was freed, the request expired, the target is no longer eligible, or the event’s required condition is no longer true.

Do not let an invalid Tracking Mark request prevent a valid lower-priority distraction or player request from being selected.

### Tracking Mark request

When the player has `tracking_mark`:

- Maintain or refresh a priority-100 request tied to that player.
- Do not require four seconds of sight.
- Allow immediate chase/commit behavior according to the normal telegraph rules.
- Remove the request when the mark expires, the player is invalid, or the player is otherwise no longer targetable.

The mark is the strongest target request, but it does not make a freed/dead player valid.

## 6. POI selection

The Flyer selects from valid nodes in the `large_flyer_poi` group.

Every `poi_interval` seconds, default `15 s`:

- Exclude freed or invalid POIs.
- Prefer POIs that have been used least recently.
- Among similarly recent candidates, prefer the nearest candidate to the Flyer.
- Make both recency and distance weighting adjustable if the POI count grows.
- If no valid POI exists, fall back to `_origin` or the current section’s authored fallback point.

Recommended implementation data:

```gdscript
var _poi_last_used: Dictionary = {} # poi instance ID -> timestamp
@export var poi_interval := 15.0
@export var poi_recency_weight := 1.0
@export var poi_distance_weight := 1.0
```

Do not pick randomly by default. Random selection can repeatedly choose the same nearby POI and makes the Flyer’s route harder to reason about. A deterministic nearest/least-recently-used policy is easier to tune and test.

## 7. Sight and movement blockers

The Flyer uses sight and movement as separate systems.

### Sight

- Ordinary sight uses the existing `SightSensor` configuration.
- A target needs four seconds of continuous sight unless Tracking Mark overrides the lock.
- Hushcap and ordinary sight-obscuring rules should still affect sight where applicable.

### Movement

Transparent authored blockers must block Flyer movement while remaining invisible to the sight query.

Implement this with collision-layer separation:

- Put transparent movement blockers on a Flyer movement collision layer.
- Include that layer in the Flyer’s `collision_mask`.
- Exclude that layer from the sight raycast/query.
- Keep ordinary sight blockers on the sight-obstruction layer.

The current scene has `collision_mask = 513`; verify which layers this represents before adding the dedicated blocker layer. Do not solve this by making the blocker visible or by disabling all collision for the Flyer.

The movement controller must treat blockers as navigational obstacles, not as target visibility blockers.

## 8. State machine

Recommended states:

```text
ROAM
  ├─ valid target request → CHASE or ATTACK_SETUP
  └─ POI timer expires → choose next POI

CHASE
  ├─ ordinary sight lock reaches 4 s → ATTACK_SETUP
  ├─ Tracking Mark request → ATTACK_SETUP immediately
  ├─ current request invalid → select next valid request
  └─ no request → SEARCH

ATTACK_SETUP
  ├─ warn for 0.9 s
  ├─ capture target position
  ├─ valid interruption → cancel and reselect
  └─ timer expires → DIVE

DIVE
  ├─ travel toward captured aim position
  ├─ first valid player impact → deal damage once and RECOVER
  └─ miss/reach terminal dive condition → RECOVER

RECOVER
  ├─ wait for 4 s cooldown
  └─ reselect target request or ROAM

SEARCH
  ├─ search last-known point for adjustable duration, default 15 s
  ├─ target request restored → CHASE/ATTACK_SETUP
  └─ timer expires → ROAM

DISABLED_FLIGHT
  ├─ immediately enter falling/gravity movement
  ├─ retain all active statuses
  └─ when Bolt Shock expires → restore flight and resume AI
```

## 9. Ordinary target lock

For an unmarked player:

- The player must remain continuously visible for `4 s`.
- Reset the sight timer when sight is lost.
- Do not accumulate disconnected glimpses into a lock.
- The player’s current position may update while sight is maintained.
- On commitment, capture `_aim` and stop retargeting during the telegraph/dive.

For a marked player:

- Skip the four-second timer.
- The player becomes the active target immediately.
- Capture a current valid position for the attack telegraph.

## 10. Dive behavior

### Telegraph

When the active request is attack-eligible:

- Capture the target’s current world position in `_aim`.
- Call `target.warn_attack(self, telegraph_seconds)`.
- Use the existing `0.9 s` telegraph unless tuned.
- Do not silently retarget during the warning.
- A valid higher-priority request may replace the current request before commitment; once the dive commits, the aim is locked.

### Committed dive

- Travel toward the captured `_aim` at `250 px/s` times flight-speed modifiers.
- Deal damage only on the first valid direct impact.
- Apply `75` default damage, configurable through data.
- Apply the existing dive force if that force is part of the current attack contract.
- Do not deal repeated damage while overlapping the player.
- If the Flyer reaches the terminal dive condition without impact, recover without dealing damage.
- After hit or miss, enter recovery and respect the `4 s` cooldown.

The current script checks for impact within `28 px`; keep the hit radius adjustable and ensure the hit is one-shot.

## 11. Lost target and search

When the active target request becomes invalid or ordinary sight is lost:

1. Capture the last-known target position.
2. Move/search around that point for `search_duration`, default `15 s`.
3. Continue accepting higher-priority valid requests during the search.
4. If no valid request returns before the timer expires, select a new POI and resume roaming.

Search should not instantly forget the player, but it should also not create infinite pursuit.

## 12. Status, damage, and force interactions

### Ordinary resistance

- Ordinary slow does not reduce Flyer movement.
- Ordinary knockback does not move the Flyer.
- `apply_force()` should remain a no-op for ordinary force, or explicitly filter only the accepted exceptions.

### Accepted effects

| Interaction | Required behavior |
|---|---|
| Poison | Accepted and processed by the shared effect system |
| Distraction | Creates/updates a target request and may redirect the Flyer |
| Driftseed | Accepted; slows flight according to its intentional anti-flight behavior |
| Bolt Shock | Disables flight, applies gravity/fall, persists through Layer 2 transfer |
| Silver Weight | Deals `200` adjustable damage; does not instantly kill unless current health is at or below that amount |

Do not add Flyer-specific copies of Poison or Driftseed logic. Use the shared status system and configure the Flyer’s accepted tags/eligibility there.

## 13. Bolt Shock

When Bolt Shock is applied:

1. Immediately disable flight.
2. Switch to gravity-affected movement.
3. Allow the Flyer to fall and receive fall damage according to the normal damage system.
4. Keep flight disabled for the full active effect duration.
5. Restore flight automatically when the effect expires.
6. Preserve the active Bolt Shock status and its remaining duration during Layer 2 transfer.

The existing support hook `process_disabled_flight(self, delta)` appears intended to centralize disabled-flight movement. Use that shared hook if it already handles gravity and fall damage correctly; otherwise extend it rather than duplicating gravity logic in the Flyer.

The transition must not reset merely because the Flyer changes sections. If Bolt Shock is active at transfer, the Flyer arrives disabled and continues falling/grounded behavior until the effect expires.

## 14. Layer 1 section transfer

The Flyer crosses Layer 1 sections as a global actor.

On section transfer:

- Preserve the same persistent identity.
- Preserve health.
- Preserve all active statuses and remaining durations/stacks.
- Preserve dead/alive state.
- Reset target to none.
- Reset sight timer to zero.
- Cancel telegraph, dive, search, and cooldown state unless the world-transition system explicitly preserves cooldowns.
- Place the Flyer at the next section’s authored Flyer position/entry point.
- Reacquire using ordinary sensing after arrival.

If the Flyer is alive on the Layer 2 transfer, place it at the Layer 2 shop marker. It must begin with no target, even if it had a target immediately before transfer.

If dead, do not transfer a replacement actor. The dead state remains authoritative.

## 15. Sky Hunter Flock relationship

The Sky Hunter Flock actively avoids being near the Flyer.

Required division of responsibility:

- The Flock detects the Flyer and chooses avoidance movement.
- The Flyer does not target, chase, or react aggressively to the Flock.
- The Flyer’s movement should not intentionally steer toward flock members.
- Avoidance should be spatial, not damage-based; the Flock should not need to be hit or killed to move away.

Use a shared species/tag query or avoidance layer rather than adding hard-coded flock node names to the Flyer.

## 16. Permanent death

When the Flyer dies:

- Set the run-global Flyer state to permanently dead.
- Remove/disable its active behavior and collision as appropriate.
- Cancel sight, target requests, telegraph, dive, search, and transfer callbacks.
- Do not respawn it in another Layer 1 section or at the Layer 2 shop marker.
- Ensure the Sky Hunter Flock no longer treats it as an avoidance source.

## 17. Current implementation gaps to fix

### Target priority is currently implicit

The current `_on_sound()` immediately clears the target unless the current target is marked. Replace this with the request queue/priority model so Snail, Rattlepod, Whistle, Crystal, marked-player, and ordinary sight requests can coexist and decay over time.

### POI selection is currently random

`_choose_poi()` currently calls `pick_random()`. Replace this with nearest/least-recently-used selection and retain a last-used timestamp per POI.

### Mark handling should be explicit

The current script sets `_sight_time = sight_lock_seconds` when the player has Tracking Mark. Keep the behavior, but make it a named “mark bypass” path so the rule is visible and testable.

### Disabled flight needs persistence

The current early return from `support.process_disabled_flight(self, delta)` clears the target and sets `MOVE`, but cross-section transfer must preserve the active Bolt Shock status and disabled-flight state.

### Dive hit should be guarded

The current attack branch can resolve when the player is within `28 px`. Add an explicit one-hit guard so a single dive cannot deal damage multiple times across frames.

### Layer-global ownership is external to this script

The scene/script currently behaves like a normal scene-local `CharacterBody2D`. The run/layer manager must own identity, transfer, and permanent death state so loading a new section cannot create another Flyer.

## 18. Acceptance tests

### Lifetime and transfer

- [ ] Only one Flyer exists across all Layer 1 sections.
- [ ] Health persists when moving between sections.
- [ ] All active statuses and remaining durations persist across Layer 2 transfer.
- [ ] Transient target, sight, search, telegraph, and dive state reset on Layer 2 arrival.
- [ ] The Flyer arrives at the Layer 2 shop marker with no target.
- [ ] A dead Flyer never respawns.

### Target priority

- [ ] Tracking Mark immediately bypasses the four-second sight lock.
- [ ] Tracking Mark outranks Snail scream and Rattlepod/Whistle/Lantern Crystal requests.
- [ ] Snail scream outranks ordinary roaming.
- [ ] Rattlepod/Whistle/Lantern Crystal requests outrank ordinary roaming.
- [ ] Effective priority decreases with request age.
- [ ] Equal-priority requests select the newest request.
- [ ] Invalid requests are removed and the next valid request is selected immediately.
- [ ] When no request is valid, the Flyer resumes roaming.

### POI and movement

- [ ] A POI is selected every `15 s` by default.
- [ ] POI selection prefers least-recently-used valid points and then nearest points.
- [ ] No valid POI falls back safely to the authored origin/section fallback.
- [ ] Transparent authored blockers block Flyer movement.
- [ ] The same transparent blockers do not block Flyer sight.
- [ ] The Flyer does not become trapped permanently against a blocker.

### Sight, search, and dive

- [ ] An unmarked player requires four seconds of continuous sight.
- [ ] Breaking sight resets the ordinary lock timer.
- [ ] Losing a target begins a search at its last-known position.
- [ ] Search duration is adjustable and defaults to `15 s`.
- [ ] Search ends in ordinary roaming when no request returns.
- [ ] The dive telegraphs for `0.9 s`.
- [ ] The dive uses a captured aim position and does not retarget after commitment.
- [ ] A dive deals adjustable `75` damage once on direct impact.
- [ ] A missed dive recovers without dealing damage.

### Damage and effects

- [ ] Ordinary slow does not slow the Flyer.
- [ ] Ordinary knockback does not move the Flyer.
- [ ] Poison affects the Flyer through the shared effect system.
- [ ] Driftseed affects flight through the shared effect system.
- [ ] Silver Weight deals adjustable `200` damage.
- [ ] Bolt Shock immediately disables flight.
- [ ] Bolt Shock applies gravity and permits fall damage.
- [ ] Flight returns when Bolt Shock expires.
- [ ] Bolt Shock persists across Layer 2 transfer.

### Other actors

- [ ] The Sky Hunter Flock actively avoids the Flyer.
- [ ] The Flyer does not target or attack the Sky Hunter Flock.
- [ ] The Flock stops treating the Flyer as an avoidance source after its permanent death.

## 19. Files and ownership

| File/system | Responsibility |
|---|---|
| `game/enemies/layer1/large_flyer.gd` | Flyer state machine, movement, target requests, sight lock, search, telegraph, dive |
| `game/enemies/layer1/large_flyer.tscn` | Collision, sensors, movement blocker mask, adjustable scene defaults |
| `data/enemies/large_layer1_flyer.tres` | Identity, tags, health, speed, damage, detection range, layer |
| Layer/run-global enemy manager | One-instance ownership, section transfer, permanent death, Layer 2 placement |
| `EnemySupport` / effect system | Health, statuses, Poison, Driftseed, Bolt Shock, disabled flight, fall damage |
| Sound/distraction system | Snail/Rattlepod/Whistle/Lantern Crystal requests |
| POI system | Authored points, validity, recency tracking |
| Sky Hunter Flock | Avoidance behavior around the Flyer |

## 20. Source references

This specification was prepared from the attached files:

- `large_flyer.gd` — file citation: `file_000000000c7081faa92c4aa0f385bdae`
- `large_flyer.tscn` — file citation: `file_000000002620820bbd6b405adf82338f`
- `large_layer1_flyer.tres` — file citation: `file_00000000f3c881faa56c2ff5ec432714`
- `layer_1_enemy_item_design_reference(2).md` — file citation: `file_0000000062c881fab12a7a97f35e0bbf`
