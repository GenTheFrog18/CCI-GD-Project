# Tremor Hound — Programmer Handoff

> **Archived:** historical proposal. Current contract: [`../../implementation/layer_2_enemies.md`](../../implementation/layer_2_enemies.md).

**Project:** Two-layer game-jam build  
**Engine:** Godot  
**Content ID:** `tremor_hound`  
**Scene:** `game/enemies/layer2/tremor_hound.tscn`  
**Script:** `game/enemies/layer2/tremor_hound.gd`  
**Definition:** `data/enemies/tremor_hound.tres`  
**Status:** Final behavior specification for implementation

**Movement dependency:** optional shared `GroundTraversal2D` component described in `ground_traversal_pathfinding_programmer_handoff.md`

This document supersedes the patrol-area, territory-leash, home-point, and return-home portions of earlier Tremor Hound notes. The Hound has no authored patrol area and no maximum roaming distance from its spawn point. It freely roams valid Layer 2 ground terrain.

The existing shared systems and project conventions take priority over copying class names from this document literally.

---

## 1. Enemy identity and gameplay role

The Tremor Hound is a grounded sound hunter. It creates pressure by investigating disturbances rather than by receiving the player’s location directly.

Its gameplay question is:

> Where can the player safely create noise or impact?

The Hound should:

- roam freely across connected usable ground terrain;
- hear footsteps, landings, attacks, impacts, relics, and enemy events at their actual world positions;
- prioritize and remember several disturbances without rapidly retargeting every frame;
- travel to recorded event positions rather than magically tracking the player from sound;
- search locally after reaching an investigation point;
- confirm the player only through short-range 360-degree sight or separate close proximity detection;
- chase a confirmed player until detection is lost or a sufficiently high-priority disturbance takes over;
- slow down and visibly prepare before launching an arcing pounce;
- commit to a pounce direction and avoid sharp mid-flight retargeting;
- deal damage, strong knockback, and a temporary movement-stun effect on a valid hit;
- retaliate against the source of qualifying direct damage after a short recovery;
- return to free roaming when no disturbance or detectable player remains.

It is a pressure enemy, not a permanent omniscient chase enemy. Standing still prevents new footsteps, but does not make the player immune to close-range confirmation.

### Identity defaults

| Field | Value |
|---|---|
| Recommended tags | `enemy`, `small_enemy`, `grounded`, `sound_hunter`, `layer_2` |
| Health | 32 |
| Pounce damage | 15 |
| Pounce force | 210 |
| Primary regions | Layer 2 middle forest and bottom passages |
| First-pass spawn count | One Hound per placer |

---

## 2. State machine

Use a small explicit state machine. Do not introduce a universal behavior tree for this enemy.

```text
SPAWN
  -> ROAM

ROAM
  -> INVESTIGATE       accepted disturbance
  -> CONFIRMED_TARGET  close sight or proximity confirmation
  -> RETALIATION_WAIT  qualifying direct damage
  -> STUNNED            Bolt Shock/shared stun
  -> DEAD               health reaches zero

INVESTIGATE
  -> SEARCH             reaches recorded event position
  -> INVESTIGATE        higher-priority event takes over
  -> CONFIRMED_TARGET  close confirmation while travelling
  -> RETALIATION_WAIT  qualifying direct damage
  -> ROAM               no valid queued event remains

SEARCH
  -> CONFIRMED_TARGET  player confirmed
  -> INVESTIGATE        higher-priority queued event
  -> ROAM               search expires with no confirmation
  -> RETALIATION_WAIT  qualifying direct damage

CONFIRMED_TARGET
  -> PREPARE_POUNCE     player is within pounce engagement range
  -> INVESTIGATE        high-priority disturbance takes over
  -> ROAM               player can no longer be detected and no event remains
  -> RETALIATION_WAIT  qualifying direct damage

PREPARE_POUNCE
  -> POUNCE              preparation completes
  -> RETALIATION_WAIT  qualifying direct damage/interruption
  -> STUNNED            Bolt Shock/shared stun
  -> ROAM/INVESTIGATE  preparation cancelled without a valid target

POUNCE
  -> RECOVER             hit, terrain collision, or duration expiry
  -> STUNNED             shared stun handling
  -> DEAD                health reaches zero

RECOVER
  -> RETALIATION_WAIT  qualifying direct damage
  -> CONFIRMED_TARGET  player is still detectable
  -> INVESTIGATE        queued high-priority disturbance exists
  -> ROAM               no player or disturbance remains

RETALIATION_WAIT
  -> PREPARE_POUNCE     recovery completes and damage source is valid
  -> ROAM/INVESTIGATE  damage source is invalid or unavailable
  -> STUNNED            Bolt Shock/shared stun

STUNNED
  -> ROAM               stun ends; detectors resume without restoring stale targets
  -> DEAD               health reaches zero
```

### State priority

Use this priority order for mutually conflicting actions:

1. `DEAD`
2. `STUNNED` / active shared interruption
3. active pounce resolution
4. qualifying damage retaliation
5. current confirmed player chase
6. high-priority disturbance investigation
7. ordinary disturbance investigation
8. free roaming

Recovery cannot be skipped. A new action may be selected only after the required recovery duration has elapsed, except that the result may be queued while recovery is active.

---

## 3. Free roaming

The Hound has no patrol area, territory rectangle, home point, leash, or return-home state.

### Roaming rules

- Roam across all valid connected Layer 2 ground terrain available to the movement system.
- Use stop-and-go movement rather than continuous sine-wave movement.
- At the beginning of each movement burst, select a valid horizontal direction.
- Continue that direction for a randomized adjustable duration.
- Stop for a randomized adjustable idle duration.
- Select a new direction after the movement duration or when the current route becomes invalid.
- At a wall, ledge, dead end, or unusable segment, stop briefly and then reverse or select another valid direction.
- Do not jitter or select a new direction every physics frame.
- Use the current roaming speed default of `42 px/s`, exposed for tuning.
- Use the existing `walk/chase` animation while moving and `idle` while stopped/listening.

### GroundTraversal2D integration

The Hound opts into the generalized `GroundTraversal2D` component. The Hound must not contain its own TileMap scanning, surface generation, jump-link generation, fall safety checks, or jump trajectory planner.

For free roaming, the Hound requests a reachable random ground destination or movement direction through `GroundTraversal2D`. The component may route across irregular ground, jump gaps, change elevation, or safely fall to lower ground according to the shared movement profile.

For investigation, the Hound requests the recorded disturbance position. For chase, it requests the player’s current reachable ground position. The Hound must never treat traversal as magical target tracking.

Required integration boundary:

```text
Hound chooses a behavior destination
  -> GroundTraversal2D plans against the shared static TileMap collision cache
  -> Hound executes walk, jump, or safe-fall segments
  -> GroundTraversal2D reports progress, landing, or failure
  -> Hound continues, chooses another destination, or enters its own search state
```

The component uses all relevant TileMaps in the loaded section and shares the generated cache with other opted-in enemies. No Hound-specific navigation nodes or authored jump points are allowed.

### Roaming movement exports

```gdscript
@export var roam_speed: float = 42.0
@export var roam_move_duration_min: float
@export var roam_move_duration_max: float
@export var roam_idle_duration_min: float
@export var roam_idle_duration_max: float
@export var roam_turn_pause_duration: float
@export var ground_traversal: NodePath
```

Exact movement and idle durations are playtest values and must remain Inspector-adjustable.

---

## 4. Disturbance event model

The project already uses `SoundEvent`. Extend it or interpret it consistently so the Hound can rank disturbances without requiring a separate incompatible event type.

The event must provide:

```gdscript
class_name DisturbanceEvent

var world_position: Vector2
var radius: float
var priority: int
var intensity: float
var category: StringName
var source: Node
var timestamp: float
```

Existing ordinary sound listeners may ignore the extra fields. Tremor Hounds use them for scoring.

### Required disturbance sources

- low-intensity grounded walking footsteps;
- jump and normal landing events;
- hard landing events;
- rope jump-off events;
- player or enemy attack impacts;
- projectile impacts on terrain;
- dropped or thrown heavy items;
- Resonance Core pulse;
- Rattlepod pulse;
- Whistle;
- Lantern Crystal event;
- Canopy Primate rock impact;
- Bulwark charge collision;
- relevant Tremor Hound pounce impacts.

Rope climbing itself is quiet. Hushcap blocks close-range sight but does not mute footsteps or impacts. Driftseed reduces landing intensity because it reduces falling speed.

### Event scoring

Keep the score formula simple and Inspector-driven. A suitable shape is:

```text
score = priority_weight
      + intensity * category_multiplier
      - distance_penalty
      - age_penalty
```

The score must account for:

- event priority;
- event intensity;
- category multiplier;
- distance from the Hound;
- event age and score decay;
- whether the event is still inside the configured hearing radius.

The previous prototype formula, `priority * 100 + intensity - distance * 0.2`, may be retained as a starting point but must be extended with category and age terms.

### Prioritized queue

The Hound maintains a small prioritized queue rather than one event slot.

Queue requirements:

- Store event position and metadata at the time the event is accepted.
- Sort live entries by current decayed score.
- Keep the queue capacity small and configurable; use a modest default such as four entries.
- Deduplicate or merge repeated events from the same active source when appropriate.
- Remove expired events.
- Prefer the newest event when scores are equal.
- Ignore the Hound’s own pounce disturbance when deciding its next target.
- Do not update an investigation position to the player’s current position merely because the player caused the original event.

### Replacing and interrupting

- A new event is accepted only when detector suppression is inactive and it passes the shared sound-listener rules.
- A new event replaces or outranks the current investigation only when it exceeds the current target’s score by the configured replacement margin.
- A short retarget cooldown prevents rapid target switching.
- A higher-priority event may interrupt free roaming, investigation, search, or confirmed chase once it passes the margin.
- During preparation and active pounce, do not redirect the attack. Store valid new events for later.
- During recovery, accept and queue events but do not skip recovery.
- When the current state ends, select the highest-scoring remaining live event.
- Repeated weak footsteps may eventually become relevant after stronger events age out.

### Disturbance exports

```gdscript
@export var hearing_radius: float
@export var disturbance_queue_capacity: int = 4
@export var event_replacement_margin: float
@export var event_retarget_cooldown: float
@export var event_memory_duration: float
@export var event_age_decay: float
@export var category_intensity_multipliers: Dictionary
```

---

## 5. Investigation and search

### Investigation

When the Hound selects an event:

1. Copy the event’s world position into the current investigation target.
2. Move toward that recorded position using `investigation_speed`, currently `76 px/s`.
3. Do not track the source’s current position while travelling.
4. Request movement through `GroundTraversal2D`; do not implement navigation locally.
5. If a stronger event passes the replacement margin, stop the current route and select the new event.
6. If the route fails, follow the route-failure rules below; do not push forever against an invalid obstacle.
7. On reaching the recorded position, enter `SEARCH`.

If the Hound confirms the player while investigating, it may immediately enter confirmed chase according to the detection rules below. The original disturbance remains in the queue if it is still valid.

If `GroundTraversal2D` returns `NO_ROUTE` during investigation, discard that investigation route and select the next live disturbance or resume free roaming. The Hound must not repeatedly retry an unreachable event.

### Search

Search is visible and readable rather than an invisible timer. During search:

- perform short local movement or directional sniff/listen pauses around the recorded position;
- use the `idle` animation during pauses;
- use the `walk/chase` animation during local movement;
- check short 360-degree sight and separate proximity detection;
- do not convert the disturbance position into continuous player tracking;
- after `search_duration` expires, discard the current search target and resume free roaming or select the next queued event.

The current default search duration is `2.0 s`, adjustable.

### Search exports

```gdscript
@export var investigation_speed: float = 76.0
@export var search_duration: float = 2.0
@export var search_radius: float
@export var search_pause_duration_min: float
@export var search_pause_duration_max: float
```

---

## 6. Player detection and chase

The Hound uses two separate close-range confirmation mechanisms.

### Short 360-degree sight

- Sight is a short-range, full-circle detection check.
- It must respect terrain obstruction.
- Hushcap blocks this sight check.
- Detector suppression prevents sight acquisition and refresh.
- Sight does not use a forward cone or facing requirement.

### Proximity detection

- Proximity is a separate close-range check.
- It is not a line-of-sight check.
- It can confirm the player even when terrain or Hushcap blocks short sight.
- It represents hearing/physical awareness at very close range.
- Detector suppression prevents new confirmation while active.

The existing `close_confirmation_radius` default of `52 px` can be used as the initial proximity radius, but the sight range and proximity radius must be separate Inspector values.

```gdscript
@export var short_sight_range: float = 300.0
@export var proximity_detection_radius: float = 52.0
```

The `300 px` value is the current definition-level detection range and is a starting value for the short sight range; tune it as needed so the sight remains meaningfully short.

### Confirmed player behavior

- If a detectable player enters confirmation range during roaming, the Hound immediately enters confirmed chase and attack evaluation.
- If the player is within pounce engagement range, the Hound begins preparation immediately.
- If the player is outside pounce range, the Hound chases the player using the current target position through `GroundTraversal2D`.
- Chase movement uses an adjustable `confirmed_chase_speed`.
- While the player remains detectable, chase has priority over ordinary roaming.
- A sufficiently high-priority disturbance may interrupt the chase after passing the replacement margin.
- If the player can no longer be detected, the Hound stops using the player’s live position, selects the most relevant queued disturbance, searches the last confirmed area only if the shared design explicitly provides that memory behavior, and otherwise resumes roaming.

The Hound must never retain omniscient player tracking after both sight and proximity detection are lost.

If `GroundTraversal2D` returns `NO_ROUTE` while the Hound is actively chasing:

- record the last position where a valid route to the target existed;
- stop requesting the unreachable target position;
- enter the Hound’s `SEARCH` state;
- center that search around the recorded last reachable position;
- use the Hound’s normal search duration and local search behavior;
- choose a new roaming destination after search expires.

If no last reachable position exists, use the Hound’s current valid grounded position.

```gdscript
@export var confirmed_chase_speed: float
@export var player_detection_memory_duration: float
```

---

## 7. Pounce attack

The pounce is a readable, committed arcing attack.

### Engagement

- When the Hound reaches the adjustable pounce engagement distance, it enters `PREPARE_POUNCE`.
- The Hound does not stop completely during preparation.
- It slows down by an adjustable preparation multiplier or to an adjustable preparation speed.
- This slowdown is the only required movement slowdown associated with attempting to pounce.
- The warning must begin before the damaging launch.
- Use the existing shared player-warning API.
- The existing pounce preparation default is `0.75 s`.

### Commitment

At the beginning of preparation:

- validate that the target is still a valid player or retaliation source;
- capture the launch direction toward the target;
- calculate a committed horizontal and vertical launch velocity;
- lock the launch solution for the damaging phase;
- do not sharply retarget toward later player movement.

The launch is an arc. It must include both horizontal and vertical movement and use the shared gravity/physics model or an equivalent configurable ballistic solution.

```gdscript
@export var pounce_prepare_duration: float = 0.75
@export var pounce_prepare_speed_multiplier: float
@export var pounce_speed: float = 250.0
@export var pounce_vertical_velocity: float
@export var pounce_duration: float = 0.55
```

The pounce ends on whichever occurs first:

- valid hit resolution;
- terrain collision;
- maximum pounce duration;
- a valid shared stun/death transition.

### Hit resolution

A pounce can damage other species through the shared damage interface. On the first valid collision with a damageable target during one pounce:

- apply pounce damage once;
- apply strong knockback/force once;
- apply an adjustable temporary movement-stun effect to the player;
- emit any required downstream disturbance event once;
- prevent duplicate hits from the same pounce.

The Hound must not directly modify player health, velocity, or movement lock state. Use shared `ImpactData`, damage, force, and status interfaces.

Suggested attack-kind identifier:

```text
hound_pounce
```

The pounce movement should use the existing `pounce` animation. If the animation contains both preparation and launch, the script must still keep preparation and damaging resolution as separate AI phases.

### Pounce exports

```gdscript
@export var pounce_damage: float = 15.0
@export var pounce_force: float = 210.0
@export var pounce_player_stun_duration: float
@export var pounce_hit_radius: float
@export var pounce_recovery_duration: float = 1.2
```

---

## 8. Recovery and post-pounce behavior

Every pounce must enter a real `RECOVER` state after hit, miss, terrain collision, or duration expiry.

- Recovery cannot be skipped.
- Recovery lasts the full configured duration.
- The Hound may accept disturbances into its queue during recovery.
- The Hound may record that the player remains detectable during recovery.
- After recovery, if the player is still detectable, resume confirmed chase and prepare another pounce when close enough.
- If the player can no longer be detected, select a queued disturbance or resume free roaming.
- A sufficiently high-priority queued disturbance may take control after recovery.
- The Hound should not automatically return to a home territory because none exists.

The current recovery default is `1.2 s`, adjustable.

---

## 9. Damage-source retaliation

When the Hound receives qualifying direct damage from an actor, it retaliates against that damage source.

### Qualifying damage

Qualifying direct damage includes an intentional attack or impact that provides a valid source actor.

The following do **not** qualify as a retaliation trigger:

- poison tick damage;
- bleed tick damage;
- fall damage;
- other periodic/environmental damage without a valid attack source.

### Retaliation behavior

- Capture the direct damage source as the retaliation target.
- If the Hound is preparing, cancel preparation safely.
- If the Hound is already in an active pounce, allow that committed pounce to resolve safely, then retaliate.
- Enter an adjustable `0.5 s` retaliation recovery/wait.
- The wait cannot be skipped.
- After the wait, immediately prepare and pounce toward the damage source if the source remains valid.
- This retaliation takes priority over ordinary roaming and ordinary queued disturbances.
- If the source is dead, invalid, unloaded, or no longer targetable, discard retaliation and resume normal AI.
- After the retaliatory pounce, use the normal recovery rules.

```gdscript
@export var retaliation_recovery_duration: float = 0.5
```

Damage-source identity must come through the shared damage contract. The Hound must not infer the source from proximity or from the most recent sound event.

---

## 10. Interruptions and detector suppression

### Bolt Shock

Bolt Shock must:

- disable the Hound’s sight and proximity acquisition;
- prevent acceptance of new disturbance events;
- prevent stale target restoration when suppression ends;
- safely cancel pounce preparation;
- apply the shared stun behavior;
- prevent attack scheduling during the stun.

An already-launched pounce is not rewound. It should resolve through the shared movement/stun contract or transition safely if the stun system takes control.

### Lacerator and ordinary direct hits

- A timed Lacerator hit may interrupt preparation.
- Any qualifying direct damage enters the damage-source retaliation flow.
- A direct hit during preparation must not spawn the pounce damage event.
- A direct hit during recovery restarts the retaliation decision after the configured retaliation wait.
- Lethal damage transitions immediately to `DEAD` and cancels all AI actions.

Relics must request damage, force, status, interruption, sound investigation, or detector suppression through shared interfaces. They must not directly set Tremor Hound state names.

---

## 11. Relic and ecosystem interactions

| Source | Required result |
|---|---|
| Plate Umbrella | Frontal pounce damage is reduced; force and stability consequences still apply through shared combat rules |
| Lacerator | Impact creates a disturbance; Bleed applies through shared status rules; qualifying timed hit may interrupt preparation and trigger retaliation |
| Resonance Core | Creates a very strong investigation event scaled to impact strength |
| Bolt Shock | Detector suppression and stun; safely cancels preparation |
| Rattlepod | Repeated strong lure; Hound investigates the active pod location rather than tracking the player magically |
| Hushcap | Blocks short sight only; does not mute footsteps, impacts, or stored disturbances |
| Lantern Crystal | Dazzles sight through the shared effect and creates a high-priority sound event |
| Driftseed | Reduces landing disturbance and modifies force/vulnerability through shared systems |
| Silver Weight | Instantly kills the Hound because it retains the `small_enemy` tag, using the shared Silver Weight rule |
| Canopy Primate rock impact | Sends the terrain impact position to the Hound as a disturbance |
| Bulwark charge collision | Sends a strong collision disturbance to the Hound |
| Hound pounce impact | Creates downstream disturbance once per physical impact; the originating Hound ignores its own event |
| Hound pounce on another species | May create the expected Carrion Stalker reevaluation event |

The Hound does not share target alerts with other Hounds. Multiple Hounds behave independently.

---

## 12. Persistence and save/load

Persist:

- alive/dead state;
- current health;
- persistent statuses and remaining durations supported by the shared status system;
- current section;
- valid persistent world position;
- stable placer/persistent ID.

Do not persist transient AI state:

- current disturbance queue;
- current investigation target;
- search timer;
- current player target;
- preparation timer;
- pounce trajectory;
- recovery timer;
- retaliation target;
- stale source references.

On load:

- restore the Hound to a valid neutral roaming state;
- restore it at its saved position when valid;
- otherwise place it at a safe nearby grounded position;
- do not resume a damaging pounce halfway through;
- do not leave it stuck in preparation, stun, detector suppression, or invalid navigation;
- resume detectors only when the shared persisted status rules allow it;
- clear all stale player, event-source, and damage-source references.

Because the Hound has no home territory, no home-area identity or return-home state is required.

---

## 13. Scene, definition, and authoring requirements

Use the existing Layer 2 enemy placer:

```text
game/world/placers/layer2_enemy_placer.tscn
```

Placement rules:

- first-pass encounters spawn one Hound per placer;
- place it on usable grounded terrain;
- ensure there is enough readable terrain for walking, investigation, and an arcing pounce;
- add the optional `GroundTraversal2D` child component to the Hound scene;
- allow `GroundTraversal2D` to derive routes from all relevant static TileMap collisions in the loaded section;
- assign a unique persistent spawn key through the placer system;
- avoid rooms where unavoidable traversal constantly emits maximum-priority disturbances;
- preserve deterministic spawn results for the same world seed and spawn key.

Remove or stop using the current unused `patrol_bounds` export. It must not be used as a hidden leash.

The final scene must contain:

- enemy collision body;
- shared `EnemySupport` integration;
- shared `SoundListener`/disturbance listener;
- short 360-degree sight detector;
- separate proximity detector;
- animation player/controller using the existing `walk/chase`, `idle`, and `pounce` animations;
- warning/telegraph integration;
- debug visualization for state, sight range, proximity range, hearing range, current event queue, and pounce hitbox when F3 tools are enabled.

The placeholder `Polygon2D` should be replaced by the final Hound visual when available.

---

## 14. Recommended script organization

The implementation may use different class names, but keep responsibilities separated:

```text
TremorHound
├── state machine
├── free-roam movement controller
├── GroundTraversal2D integration
├── disturbance listener and prioritized queue
├── short sight detector
├── proximity detector
├── pounce commitment/trajectory controller
├── damage-source retaliation handler
├── shared EnemySupport integration
└── save/load reset hooks
```

The enemy script owns decisions. Shared systems own information delivery and consequences:

| Responsibility | Owner |
|---|---|
| Health, accepted damage, death | `EnemySupport` |
| Force and impact consequences | Shared force/damage system |
| Poison, Bleed, movement stun | Shared status system |
| Sight obstruction and Hushcap | Shared sight system |
| Disturbance delivery | Shared sound/disturbance system |
| Detector suppression and stun | Shared status/effect system |
| Warning presentation | Shared player-warning system |
| Ground traversal routes | `GroundTraversal2D` and shared section collision cache |
| State selection and attack commitment | `TremorHound` |

---

## 15. Tuning exports

All values that affect behavior must be data-driven or Inspector-adjustable.

```gdscript
# Identity/combat
@export var health: float = 32.0
@export var pounce_damage: float = 15.0
@export var pounce_force: float = 210.0
@export var pounce_player_stun_duration: float

# Free roaming
@export var roam_speed: float = 42.0
@export var roam_move_duration_min: float
@export var roam_move_duration_max: float
@export var roam_idle_duration_min: float
@export var roam_idle_duration_max: float
@export var roam_turn_pause_duration: float

# Investigation
@export var hearing_radius: float
@export var investigation_speed: float = 76.0
@export var disturbance_queue_capacity: int = 4
@export var event_replacement_margin: float
@export var event_retarget_cooldown: float
@export var event_memory_duration: float
@export var event_age_decay: float
@export var category_intensity_multipliers: Dictionary
@export var search_duration: float = 2.0
@export var search_radius: float
@export var search_pause_duration_min: float
@export var search_pause_duration_max: float

# Player confirmation/chase
@export var short_sight_range: float = 300.0
@export var proximity_detection_radius: float = 52.0
@export var confirmed_chase_speed: float
@export var player_detection_memory_duration: float

# Pounce
@export var pounce_engagement_distance: float
@export var pounce_prepare_duration: float = 0.75
@export var pounce_prepare_speed_multiplier: float
@export var pounce_speed: float = 250.0
@export var pounce_vertical_velocity: float
@export var pounce_duration: float = 0.55
@export var pounce_hit_radius: float
@export var pounce_recovery_duration: float = 1.2

# Retaliation
@export var retaliation_recovery_duration: float = 0.5

# Navigation/debug
@export var ground_traversal: NodePath
@export var show_debug_events: bool
```

`patrol_bounds`, `territory_pursuit_distance`, `home_point`, and `return_home` settings should be removed or ignored.

---

## 16. Acceptance tests

### Free roaming

- [ ] The Hound roams freely without a patrol rectangle, territory leash, or home point.
- [ ] Roaming alternates between movement bursts and idle pauses.
- [ ] Movement and idle durations are randomized within Inspector ranges.
- [ ] Direction changes do not occur every physics frame.
- [ ] Invalid terrain causes a brief pause followed by reversal or a valid alternate direction.
- [ ] The Hound uses `GroundTraversal2D` for routes that require walking, jumping, or safe falling.
- [ ] No Hound-specific TileMap scanning or jump-link generation exists.
- [ ] The existing walk/chase and idle animations map correctly to movement and pauses.

### Disturbances

- [ ] Walking creates a low-intensity disturbance.
- [ ] Jumping, normal landing, and hard landing produce distinguishable intensities.
- [ ] Rope climbing is quiet; rope jump-off creates a disturbance.
- [ ] Heavy item impacts, Rattlepod, Whistle, Resonance Core, Lantern Crystal, Primate rock impacts, and Bulwark collisions reach the Hound at the correct position and strength.
- [ ] Disturbance score includes priority, intensity, category, distance, and age.
- [ ] The Hound maintains a small prioritized queue.
- [ ] A new event replaces or interrupts the current target only after the configured score margin.
- [ ] Retarget cooldown prevents jitter.
- [ ] Repeated weak footsteps matter after stronger events decay.
- [ ] The Hound ignores its own pounce disturbance.
- [ ] Detector suppression blocks new events.

### Investigation and detection

- [ ] The Hound travels to the recorded event location, not the source’s current position.
- [ ] Investigation routes use the shared static collision cache across all relevant TileMaps.
- [ ] A failed investigation route selects another queued disturbance or resumes roaming.
- [ ] The Hound searches locally after arrival.
- [ ] Search visibly includes short movement and sniff/listen pauses.
- [ ] Short sight is 360 degrees and blocked by terrain/Hushcap.
- [ ] Proximity detection is separate from sight and can confirm through obstruction.
- [ ] Standing still prevents new footsteps but does not prevent proximity confirmation.
- [ ] The Hound never tracks the player omnisciently after sight and proximity are both lost.
- [ ] A detectable player inside pounce range causes immediate attack evaluation.
- [ ] An unreachable chase stores the last reachable target position and enters local search.

### Pounce

- [ ] Preparation slows the Hound but does not stop it completely.
- [ ] Preparation produces a readable warning before damage.
- [ ] Launch direction and arc are committed before launch.
- [ ] The pounce has both horizontal and vertical movement.
- [ ] The pounce cannot sharply retarget in flight.
- [ ] Terrain collision, hit, or duration expiry ends the pounce safely.
- [ ] A pounce can damage other species through shared damage interfaces.
- [ ] A valid hit applies damage once, strong force once, and movement stun once.
- [ ] A miss always produces the full recovery state.
- [ ] Recovery cannot be skipped.

### Retaliation and interruptions

- [ ] A qualifying direct hit causes a 0.5-second adjustable retaliation recovery.
- [ ] After retaliation recovery, the Hound pounces at the damage source if valid.
- [ ] Poison, Bleed, and fall-damage ticks do not trigger retaliation.
- [ ] Bolt Shock suppresses detectors and safely cancels preparation.
- [ ] A timed Lacerator hit can interrupt preparation.
- [ ] An already-launched pounce is not rewound by a later target update.
- [ ] Lethal damage immediately transitions to death.

### Persistence and ecosystem

- [ ] Health, death, statuses, section, position, and persistent ID survive save/load.
- [ ] Queue, target, preparation, pounce, recovery, and stale source references reset safely on load.
- [ ] The Hound reloads into valid free roaming rather than a damaging attack.
- [ ] Same-species damage is rejected through shared rules.
- [ ] Cross-species impacts are accepted once.
- [ ] Silver Weight applies the configured instant-kill small-enemy rule.
- [ ] Hound, Primate, and Bulwark impact events create the expected downstream disturbances.
- [ ] Multiple Hounds remain independent.
- [ ] Spawn results are deterministic for the same seed and persistent spawn key.

---

## 17. Implementation order

1. Remove patrol-area, territory, home-point, and return-home assumptions.
2. Replace sine patrol movement with randomized stop-and-go free roaming.
3. Add the optional `GroundTraversal2D` component and connect the Hound’s movement profile.
4. Finalize shared disturbance fields and required event producers.
5. Implement scored prioritized disturbance queue with decay, margin, and retarget cooldown.
6. Implement recorded-position investigation and readable local search.
7. Add separate 360-degree short sight and proximity confirmation.
8. Implement confirmed player chase and target-loss behavior.
9. Implement slowed telegraphed preparation and committed arcing pounce.
10. Add damage, force, movement stun, hit-once, collision, and recovery rules.
11. Add direct damage-source retaliation and shared interruption handling.
12. Connect relic and cross-enemy disturbance interactions.
13. Replace placeholder visuals and map the existing animations.
14. Verify shared traversal debug visualization, save/load reset behavior, and deterministic placer tests.
15. Tune free-roam rhythm, queue behavior, detection distances, pounce arc, recovery, and Curse fairness through playtesting.

Advanced procedural navigation, a universal behavior tree, dynamic terrain destruction, and complex pack tactics remain out of scope for the first implementation.
