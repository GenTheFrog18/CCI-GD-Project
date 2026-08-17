# Layer 2 Enemies — Programmer Handoff

**Project:** Two-layer game-jam build
**Engine:** Godot
**Document purpose:** Implementation contract for the complete Layer 2 enemy roster
**Status:** Working specification; numerical values marked as provisional must remain adjustable in the Inspector

> **Answered-questionnaire authority (2026-08-17):** Alarm Grazer is removed; Glasswings remain excluded; the living Layer 1 Large Flyer still transfers into Layer 2; Canopy Primates are grounded frog-like jumpers with no perch, branch, or ceiling behavior; each Primate placer owns one independent group; Silver Weight deals adjustable heavy damage rather than tag-based instant death; and the Layer 2 Curse does not pause enemy attacks. Any older conflicting statement below is superseded.

---

## 1. Final Layer 2 roster

Layer 2 contains four ordinary enemy categories and one big-enemy category.

| Roster category | Enemy | Core niche | Primary region |
|---|---|---|---|
| Ordinary 1 | Canopy Primate | Coordinated ranged knockback and distance control | Top inverted forest |
| Ordinary 2 | Tremor Hound | Hunts sound, impacts, and movement disturbances | Middle forest; bottom passages |
| Ordinary 3 | Carrion Stalker | Prioritizes bleeding, poisoned, or weakened actors | Middle forest; bottom passages |
| Ordinary 4 | Bulwark Beast | High-damage charge with a locked direction | Bottom rocky region |
| Big enemy | Sky Hunter Flock | Persistent group pursuit in exposed air | Layer-wide open spaces |

Glasswings are not part of the required enemy roster. If added, they should be implemented as optional environmental fauna rather than a full combat enemy.

### Important terminology

“Ordinary enemy” in this document is a production-scope category. It does **not** automatically mean the existing `small_enemy` gameplay tag.

Recommended tag treatment:

| Enemy | Recommended gameplay tags |
|---|---|
| Canopy Primate | `enemy`, `small_enemy`, `grounded`, `ceiling_capable`, `layer_2` |
| Tremor Hound | `enemy`, `small_enemy`, `grounded`, `sound_hunter`, `layer_2` |
| Carrion Stalker | `enemy`, `small_enemy`, `grounded`, `wounded_hunter`, `layer_2` |
| Bulwark Beast | `enemy`, `heavy_enemy`, `grounded`, `charger`, `layer_2` |
| Individual Sky Hunter | `enemy`, `flying`, `flock_member`, `layer_2_big_enemy` |

This prevents Silver Weight from automatically killing the Bulwark Beast or deleting one member of the big-enemy encounter merely because both appear in the Layer 2 roster.

---

## 2. Shared implementation rules

Layer 2 enemies must extend the existing enemy framework:

- `EnemyDefinition` owns identity, species, tags, health, base movement values, status eligibility, and scene reference.
- Each enemy has a dedicated scene and a small enemy-specific state machine.
- `EnemySupport` remains responsible for health, accepted damage, force, statuses, death, and persistence.
- Shared sight, sound, status, force, and damage systems carry information; enemy scripts decide how to react.
- Tuning values must be exported or stored in data resources.

Do not introduce a universal behavior tree solely for Layer 2.

### Shared combat rules

- All enemies are killable.
- Same-species damage is rejected.
- Cross-species damage is accepted.
- Damage rejection must also reject associated status effects unless the effect explicitly bypasses damage acceptance.
- Enemy attacks must use the shared damage/force interfaces.
- Enemy scripts must not directly modify player health or velocity.
- Relic scripts must not directly force enemy state transitions; they should request damage, force, status, interruption, sound investigation, or detector suppression through shared interfaces.

### Readable failure rules

- Dangerous attacks require a visible and audible telegraph.
- Enemies must not begin damaging attacks from off-screen without a warning that reaches the player.
- Attack directions should be committed before the damaging phase where specified.
- Recovery windows must be genuine AI states, not animation-only pauses.
- The Layer 2 Curse can stop the player for approximately 0.5 seconds. Major attack telegraphs and attack scheduling must be tuned so the curse does not repeatedly create unavoidable damage.

### Persistence rules

The game autosaves during a living run. Enemy persistence must include:

- Alive/dead state.
- Current health.
- Persistent status effects supported by the existing status save system.
- Current section or persistent world position when applicable.
- Stolen or attached persistent objects, if any are added later.
- Remaining Sky Hunter flock members.

Transient AI state may reset safely on load, but loading must not leave an enemy stuck in an attack, stun, disabled-detector, or invalid navigation state.

---

## 3. Shared Layer 2 components

These are suggested reusable pieces, not mandatory exact class names.

### 3.1 Authored movement points

Layer 2 terrain is heavily authored. Prefer manually placed navigation helpers over expensive general-purpose movement logic.

Suggested helper types:

- `PerchPoint2D`: primate standing/hanging position, facing options, surface orientation, and neighbor links.
- `AirPOI2D`: Sky Hunter patrol/search destination.
- `TerritoryArea2D`: leash area for Hounds, Stalkers, and Bulwarks.
- `ChargeLaneHint2D`: optional hint for designers to verify a usable Bulwark charge lane; the AI must still use collision checks.

### 3.2 Disturbance event

Tremor Hounds require more information than an ordinary sound event. Extend the sound system or introduce a compatible disturbance event.

```gdscript
class_name DisturbanceEvent

var world_position: Vector2
var radius: float
var priority: int
var intensity: float
var category: StringName # footsteps, landing, impact, attack, relic, creature_call
var source: Node
var timestamp: float
```

Ordinary sound listeners may ignore the additional fields. Tremor Hounds use intensity and category to rank investigation points.

### 3.3 Detector suppression

Bolt Shock disables enemy detectors. Every Layer 2 enemy must respect a shared detector-suppression status or interface.

While suppressed:

- Sight cannot acquire or refresh targets.
- Sound/disturbance listeners ignore new events.
- Status-based target scanners do not select new targets.
- Group alerts cannot be transmitted or accepted unless explicitly exempted.
- Current attacks are cancelled by the stun portion of Bolt Shock, not by individual sensors.

When suppression ends, detectors resume normally and do not automatically restore stale targets.

### 3.4 Attack scheduling token

Primates and Sky Hunters need simple group coordination. Use a small coordinator that grants a limited number of simultaneous attack tokens.

The coordinator should control:

- Maximum simultaneous attackers.
- Delay between group attacks.
- Shared alert position and timestamp.
- Member registration/removal.
- Selection of the next eligible attacker.

It should not perform movement or attacks for individual members.

---

## 4. Canopy Primate

### 4.1 Purpose

Canopy Primates pressure the player from a distance with gravity-affected rocks and knockback. They move in groups across inverted trees, can hang from ceiling surfaces, and retreat when the player approaches.

They should be dangerous because of positioning and coordinated pressure, not high damage.

### 4.2 Spawn and grouping

- Spawn through manually placed Layer 2 enemy spawners.
- Typical group size should be configurable; suggested starting range is 2–4.
- All primates from one spawn event share a group coordinator.
- Each spawner references a local network of `PerchPoint2D` nodes.
- A primate must not spawn unless at least one valid perch is available.
- Group size, spawn chance, and eligible section variations remain designer-controlled.

### 4.3 Movement model

Primates move between authored perches instead of using unrestricted navigation.

Each perch stores:

- World transform.
- Surface orientation: floor, branch side, or ceiling.
- Neighboring reachable perches.
- Whether throwing is allowed from that point.
- Optional cover/visibility score.
- Optional escape-only flag.

Movement rules:

- Idle members choose nearby perches within their territory.
- Alert members prefer perches within their desired attack distance.
- If the player becomes too close, select a reachable retreat perch farther from the player.
- Avoid choosing a perch already reserved by another member.
- Hanging animation/orientation is visual; collision and movement must remain stable under the selected surface orientation.
- If no retreat perch exists, use a short evasive movement or defensive delay rather than teleporting.

### 4.4 Detection

- Primary detection is line-of-sight.
- One primate acquiring the player shares the last seen position with nearby group members.
- Group alerts expire after a configurable duration.
- High-priority sound may create an investigation target, but sound does not grant perfect player tracking.
- Dazzled and detector suppression disable visual acquisition.
- Hushcap blocks line-of-sight using the existing sight-obstruction rules.

### 4.5 State machine

```text
SPAWN
IDLE
MOVE_TO_PERCH
INVESTIGATE
ALERT
REQUEST_ATTACK
AIM
THROW
RECOVER
RETREAT
STUNNED
DEAD
```

Required transitions:

- `IDLE` → `ALERT` on confirmed sight or accepted group alert.
- `ALERT` → `RETREAT` when inside minimum preferred distance.
- `ALERT` → `REQUEST_ATTACK` when a valid throw path exists.
- `REQUEST_ATTACK` → `AIM` only after receiving the group attack token.
- `AIM` → `THROW` after a visible wind-up.
- Accepted interruption during `AIM` → `RECOVER` or `STUNNED` without spawning a rock.
- `THROW` → `RECOVER` after exactly one projectile spawn attempt.
- Lost target → `INVESTIGATE`, then return to `IDLE` after memory expires.

### 4.6 Rock attack

- Capture an aim solution during the aim state.
- Projectile uses gravity and configurable launch speed.
- Prefer a simple ballistic solution with limited prediction of player velocity.
- Lock or heavily limit aim correction near the end of the wind-up.
- Deal small damage and meaningful knockback.
- Terrain collision ends the damaging projectile state.
- Primates must not throw through solid terrain or their own immediate cover.

For jam scope, primate attack rocks should use the transient `Projectile` system and should not become unlimited collectible Throwable Rocks. If the team later wants recoverable ammunition, expose a low drop chance rather than converting every attack projectile.

### 4.7 Group behavior

- Shared alerts communicate location, not exact continuous tracking.
- Limit simultaneous wind-ups through attack tokens.
- Apply randomized delay so group attacks do not form unavoidable identical volleys.
- Members should prefer different unoccupied perches when possible.
- Same-species rocks are rejected by other primates.
- Rocks may hit other species and create disturbance events.

### 4.8 Relic and system interactions

| Source | Expected response |
|---|---|
| Plate Umbrella | Frontal rock is blocked; umbrella loses stability; primates may later reposition |
| Lacerator | Small damage and Bleed; a hit during aim may interrupt the throw |
| Resonance Core | Impact creates an investigation point; does not override short-range sight forever |
| Bolt Shock | Stops movement/attack, disables detectors, and cancels current aim |
| Rattlepod | Creates repeated investigation points and may turn the group away from the player |
| Hushcap | Blocks sight but does not silence rock impacts or group calls outside the cloud |
| Lantern Crystal | Dazzles affected members and emits a sound event |
| Cling Resin | Reduces grounded movement or prevents a clean perch transition while affected |
| Driftseed | Alters eligible movement/force response; tune carefully for ceiling traversal |
| Silver Weight | Instantly kills if the primate retains the `small_enemy` tag |

### 4.9 Exported tuning values

```gdscript
@export var health: float
@export var preferred_distance_min: float
@export var preferred_distance_max: float
@export var sight_range: float
@export var sight_angle_degrees: float
@export var target_memory_duration: float
@export var group_alert_radius: float
@export var group_alert_duration: float
@export var move_speed: float
@export var perch_reservation_duration: float
@export var aim_duration: float
@export var aim_lock_time: float
@export var throw_cooldown: float
@export var projectile_speed: float
@export var projectile_gravity_scale: float
@export var rock_damage: float
@export var rock_force: float
@export var maximum_simultaneous_attackers: int
@export var group_attack_spacing: float
```

---

## 5. Tremor Hound

### 5.1 Purpose

The Tremor Hound hunts disturbances: footsteps, landings, impacts, attacks, and loud relics. It does not receive the player’s exact location merely because a sound occurred.

Its main question is: **where can the player safely create noise or impact?**

### 5.2 Spawn and territory

- Spawn in the middle forest and selected bottom passages.
- Usually spawn alone; occasional pairs are allowed only after individual behavior is readable.
- Assign a `TerritoryArea2D` and home point.
- The Hound may pursue disturbances outside its home area for a limited distance, then return.
- Do not place it in rooms where unavoidable traversal constantly emits maximum-priority impacts.

### 5.3 Detection model

Long-range detection comes from disturbance events rather than ordinary sight.

The Hound ranks events using:

- Event priority.
- Intensity.
- Distance.
- Recency.
- Category multiplier.

Suggested score shape:

```text
score = priority_weight
      + intensity * category_multiplier
      - distance_penalty
      - age_penalty
```

The exact formula should remain simple and inspector-driven.

Close-range confirmation:

- Inside a short configurable radius, the Hound can visually or physically confirm the player.
- Hushcap reduces sight but does not erase an already stored investigation point.
- Standing still prevents new footstep events but does not make the player invisible at contact range.
- Detector suppression prevents accepting new disturbances.

### 5.4 Disturbance sources

The following should create compatible events:

- Running footsteps.
- Hard landing.
- Player or enemy attack impact.
- Projectile hitting terrain.
- Dropped or thrown heavy item.
- Resonance Core pulse.
- Rattlepod pulse.
- Whistle.
- Primate rock impact.
- Bulwark charge collision.

Driftseed should reduce the player’s landing intensity because it reduces falling speed. Hushcap is a sight-blocking cloud in the current implementation and must **not** silently suppress sound unless its design is explicitly changed project-wide.

### 5.5 State machine

```text
SPAWN
IDLE
PATROL
LISTEN
INVESTIGATE
SEARCH
CONFIRMED_TARGET
PREPARE_POUNCE
POUNCE
RECOVER
RETURN_HOME
STUNNED
DEAD
```

Required behavior:

- New high-score event stores an investigation position.
- `INVESTIGATE` moves toward the stored position without updating it magically.
- Reaching the position begins a local `SEARCH`.
- Close-range confirmation enters `CONFIRMED_TARGET`.
- Losing confirmation returns to the most recent valid disturbance, not the player’s current transform.
- Territory or pursuit timeout enters `RETURN_HOME`.

### 5.6 Pounce attack

- Requires close-range target confirmation.
- Uses a readable preparation state.
- Captures a direction before launch.
- Cannot make sharp turns after launch.
- Deals configurable moderate damage and force.
- Can strike other species.
- Missing produces a genuine recovery window.
- Terrain collision ends the pounce safely.
- A valid interrupt during preparation cancels the pounce.

### 5.7 Relic and system interactions

| Source | Expected response |
|---|---|
| Plate Umbrella | Frontal pounce damage is reduced; major stability loss and transferred force |
| Lacerator | Impact creates a disturbance; hit applies Bleed; timed hit may interrupt preparation |
| Resonance Core | Very strong investigation target proportional to impact strength |
| Bolt Shock | Full detector suppression plus adjustable stun; clears current pounce safely |
| Rattlepod | Strong repeated lure, but keeps the Hound near the active pod |
| Hushcap | Blocks close-range sight only; does not mute footsteps or impacts |
| Lantern Crystal | Dazzles sight and creates a high-priority sound location |
| Driftseed | Reduces landing disturbance; increases the player’s knockback vulnerability |
| Silver Weight | Creates an extremely strong impact lure; kills on a valid hit if tagged `small_enemy` |

### 5.8 Exported tuning values

```gdscript
@export var health: float
@export var patrol_speed: float
@export var investigation_speed: float
@export var confirmed_chase_speed: float
@export var hearing_radius: float
@export var close_confirmation_radius: float
@export var short_sight_range: float
@export var investigation_memory_duration: float
@export var search_duration: float
@export var territory_pursuit_distance: float
@export var category_intensity_multipliers: Dictionary
@export var pounce_prepare_duration: float
@export var pounce_speed: float
@export var pounce_duration: float
@export var pounce_damage: float
@export var pounce_force: float
@export var pounce_recovery_duration: float
```

---

## 6. Carrion Stalker

### 6.1 Purpose

The Carrion Stalker is an opportunistic predator that changes target priority according to injury and status. It should often follow or threaten an injured actor before committing.

Its main question is: **which creature currently looks easiest to finish?**

### 6.2 Spawn and territory

- Spawn in the middle forest and selected bottom routes.
- Prefer solitary spawns.
- Give each Stalker a territory and retreat point.
- Avoid placing several Stalkers in one small room until the single-creature behavior is proven readable.
- It may follow wounded prey beyond its normal territory by a configurable additional distance.

### 6.3 Target eligibility

The Stalker can evaluate:

- Player.
- Canopy Primates.
- Tremor Hounds.
- Individual Sky Hunters when reachable.
- Other accepted cross-species damage targets.
- Injured Bulwark Beasts, but normally with a large danger penalty.

It must not target:

- Dead actors.
- Untargetable or protected shop actors.
- Same-species Stalkers.
- Actors behind permanent barriers with no valid route.

### 6.4 Target scoring

Use a small periodic scan rather than evaluating every actor every physics frame.

Suggested factors:

```text
target_score = bleeding_bonus
             + low_health_bonus
             + poison_or_weakness_bonus
             + isolation_bonus
             + recent_injury_bonus
             - distance_penalty
             - target_danger_penalty
             - unreachable_penalty
```

Recommended priority behavior:

1. Bleeding actor in range.
2. Critically injured actor.
3. Poisoned or visibly weakened actor.
4. Isolated small actor.
5. Healthy player only at very short range, when cornered, or when no safer prey exists.

Avoid exact health knowledge through the entire level. Target scanning must use a radius and either line-of-sight, scent/status broadcasting, or both.

### 6.5 Hunting behavior

- At medium range, shadow the selected target rather than immediately charging.
- Prefer positions outside the target’s direct facing when navigation permits.
- Commit when the target is isolated, close, recovering, or sufficiently injured.
- Re-evaluate when another nearby actor becomes a substantially better target.
- Do not switch targets every frame; use a score margin and minimum commitment time.
- Retreat after a successful bite, then decide whether to attack again.

### 6.6 State machine

```text
SPAWN
IDLE
PATROL
SCAN_PREY
SHADOW
CIRCLE
PREPARE_BITE
BITE
RETREAT
SEARCH_LAST_PREY_POSITION
RETURN_HOME
STUNNED
DEAD
```

Required transitions:

- Target acquired → `SHADOW`.
- Favorable attack conditions → `PREPARE_BITE`.
- Valid interruption during preparation → `RETREAT` or `STUNNED`.
- Successful or missed bite → `RETREAT`.
- Target becomes invalid → scan again or return home.
- Better target exceeds switch threshold → switch only after minimum commitment time.

### 6.7 Bite attack

- Short preparation and short forward commitment.
- Low-to-moderate direct damage.
- Small force compared with Primates and Bulwarks.
- Optional Bleed application must remain an exported balance switch; avoid guaranteed recursive bleeding until playtested.
- Successful bite triggers a retreat interval.
- Bite can hit other species.

### 6.8 Relic and system interactions

| Source | Expected response |
|---|---|
| Plate Umbrella | Frontal bite can be reduced; Stalker behavior encourages circling |
| Lacerator | Creates a bleeding target that may become the Stalker’s preferred prey |
| Resonance Core | Impact may cause cautious investigation, but injury scoring outranks ordinary sound |
| Bolt Shock | Stuns, disables prey scanning, and clears its current attack safely |
| Bandage | Removes Bleed; Stalker searches the last known position before rescoring |
| Poison | Increases prey score without being removed by Bandage |
| Rattlepod | May attract attention but does not outrank nearby bleeding prey |
| Hushcap | Blocks sight; does not remove status-based prey evidence already acquired |
| Lantern Crystal | Dazzles and creates a temporary escape window |
| Silver Weight | Kills on a valid meaningful hit if tagged `small_enemy` |

### 6.9 Exported tuning values

```gdscript
@export var health: float
@export var patrol_speed: float
@export var shadow_speed: float
@export var attack_speed: float
@export var prey_scan_interval: float
@export var prey_scan_radius: float
@export var prey_memory_duration: float
@export var target_switch_score_margin: float
@export var minimum_target_commitment_time: float
@export var bleeding_score_bonus: float
@export var critical_health_threshold: float
@export var critical_health_score_bonus: float
@export var poison_score_bonus: float
@export var isolation_score_bonus: float
@export var danger_penalties: Dictionary
@export var bite_prepare_duration: float
@export var bite_damage: float
@export var bite_force: float
@export var bite_applies_bleed: bool
@export var bite_bleed_duration: float
@export var retreat_duration: float
```

---

## 7. Bulwark Beast

### 7.1 Purpose

The Bulwark Beast is a bulky territorial enemy in the rocky bottom region. It performs a very high-damage charge, but once committed it cannot turn, stop immediately, or choose a new target.

The player should treat it as both a threat and a source of directed force.

### 7.2 Spawn and terrain requirements

- Spawn through manually placed bottom-region spawners.
- Usually spawn alone.
- Require a territory with at least one readable charge lane and at least one safe avoidance option.
- Level designers must avoid placing one directly beside an unavoidable entrance transition.
- Permanent terrain cannot be destroyed.
- Breakable loot rocks may receive charge impacts through their existing damage/force interface.

### 7.3 Detection and aggression

The Bulwark may become aggressive through:

- Player entering its territorial radius.
- Sustained line-of-sight.
- Accepted damage.
- A sufficiently strong nearby impact or resonance event.

Sound can make it face or investigate a position before committing. Once the charge begins, new sounds and targets cannot redirect it.

### 7.4 State machine

```text
SPAWN
IDLE
PATROL
ALERT
FACE_TARGET
TELEGRAPH_CHARGE
CHARGE
DECELERATE
COLLISION_RECOVERY
EXHAUSTED
RETURN_HOME
STUNNED
DEAD
```

Required sequence:

1. Confirm a valid target or provocation.
2. Turn during `FACE_TARGET`.
3. Display a strong charge telegraph.
4. Capture and lock the charge direction.
5. Enter `CHARGE` with no ordinary steering.
6. End through terrain collision, maximum duration, external stun, or gradual deceleration.
7. Enter a real recovery/exhaustion window.

### 7.5 Charge attack

Known design targets:

- Approximately 50 player damage before final balancing.
- Large knockback.
- Approximately one second of player incapacitation.
- Direction locked before the damaging movement begins.
- Cannot stop immediately after missing.
- Slows down over several seconds if it does not collide with terrain.

Implementation rules:

- Use continuous collision detection or shape casting to prevent tunneling.
- Apply damage once per target per charge unless the target clearly exits and re-enters after a configured cooldown.
- Cross-species collisions apply damage and force.
- Same-species Bulwarks reject damage but may still receive a reduced physical displacement if desired.
- A terrain collision creates a high-intensity disturbance event.
- Collision with a sufficiently heavy object may end the charge early according to mass/force thresholds.
- Ordinary damage, Bleed, or distraction does not cancel an active charge.

### 7.6 Recovery

- Terrain collision uses `COLLISION_RECOVERY`.
- Missing and slowing naturally uses `EXHAUSTED`.
- Both states disable immediate recharging.
- Recovery duration may depend on collision strength.
- This is the primary safe window for passing, manipulating, or attacking the Beast.

### 7.7 Relic and system interactions

| Source | Expected response |
|---|---|
| Plate Umbrella | Reduces some frontal damage, transfers major force, and immediately forces the umbrella closed |
| Lacerator | Applies small damage and Bleed but does not cancel an active charge |
| Resonance Core | Strong impact can attract or provoke before commitment; heavy collision may shorten a charge |
| Bolt Shock | A valid rod can stop movement and stun; use enemy-specific duration multipliers |
| Rattlepod | Can make it face/investigate a location before committing; cannot redirect an active charge |
| Hushcap | Breaks sight but does not erase a charge direction already locked |
| Cling Resin | Reduces acceleration or increases deceleration if applied before/during charge; does not instantly immobilize |
| Driftseed | Does not meaningfully lift the heavy Beast; any effect uses a strong resistance multiplier |
| Silver Weight | Deals configured heavy damage/force; does not use `small_enemy` instant kill |

### 7.8 Exported tuning values

```gdscript
@export var health: float
@export var patrol_speed: float
@export var turn_speed: float
@export var territory_radius: float
@export var sight_range: float
@export var provocation_impact_threshold: float
@export var charge_telegraph_duration: float
@export var charge_acceleration: float
@export var maximum_charge_speed: float
@export var maximum_charge_duration: float
@export var charge_steering_degrees: float = 0.0
@export var charge_damage: float = 50.0
@export var charge_force: float
@export var player_incapacitation_duration: float = 1.0
@export var charge_same_target_cooldown: float
@export var natural_deceleration: float
@export var collision_recovery_duration: float
@export var exhaustion_duration: float
@export var heavy_object_stop_threshold: float
@export var electric_stun_duration_multiplier: float
@export var resin_acceleration_multiplier: float
```

---

## 8. Sky Hunter Flock — Big Enemy Category

### 8.1 Purpose

The Layer 2 big enemy is a flock of several smaller flying predators. The flock is more aggressive than the Layer 1 Large Flyer, spreads across open air, and deals less damage per successful attack.

Known damage target: approximately 25 damage per successful individual attack before balancing.

The flock collectively fills one big-enemy slot. Individual members are not ordinary ambient flyers.

### 8.2 Required Layer 1 integration change

The current Layer 1 reference transfers a surviving Large Layer 1 Flyer into the Layer 2 shop area. This conflicts with the decision that Layer 2 replaces its big enemy with the Sky Hunter Flock.

For the jam build:

- Do not transfer the Large Layer 1 Flyer into Layer 2 gameplay.
- Remove or disable its Layer 2 transfer handoff.
- If the team wants continuity, it may appear only as a non-combat scripted background event near the transition. This is optional and should not delay the flock.

### 8.3 Flock ownership and persistence

Use one `SkyHunterFlockCoordinator` for the persistent Layer 2 big-enemy encounter.

The coordinator owns:

- Unique flock ID.
- Member IDs and alive/dead state.
- Shared alert position and timestamp.
- Current active side/region.
- Air POI selection.
- Maximum simultaneous attackers.
- Attack-spacing timer.
- Regroup behavior.

Recommended starting flock size is configurable, approximately 3–5 members.

Rules:

- The flock is created once per new game, not every time a section loads.
- Dead members do not respawn until New Game.
- Surviving members retain health and persistent statuses through autosave.
- Loading a section must not duplicate members.
- If the entire flock dies, the big enemy remains absent for the rest of that game.
- The coordinator may relocate off-screen members between authored air POIs when the player changes Layer 2 sides, but must not visibly teleport an on-screen member.

### 8.4 Individual movement

- Fly between `AirPOI2D` nodes during roaming.
- Maintain configurable separation from other flock members.
- Avoid terrain using raycasts or short predictive shape casts.
- Do not require expensive flock simulation; separation, POI offsets, and attack scheduling are sufficient.
- Ordinary slows and Cling Resin are rejected while flying.
- Driftseed remains the intended anti-flight exception.

### 8.5 Detection

- Primary acquisition uses ordinary line-of-sight.
- Compared with the Layer 1 Flyer, acquisition should be faster and more aggressive.
- One member confirming the player shares the last seen position with the flock.
- Shared alert does not give permanent exact tracking through terrain.
- Members search around the last seen position after sight is broken.
- Dazzled and detector suppression disable acquisition for affected individuals.
- High-priority sound can redirect searching or uncommitted members.
- Members already committed to an attack do not instantly turn toward a new sound.

### 8.6 Individual state machine

```text
SPAWN
ROAM
INVESTIGATE
ALERT
CHASE
REQUEST_ATTACK
TELEGRAPH_ATTACK
ATTACK
RECOVER
DISENGAGE
REGROUP
STUNNED
FALLING_DISABLED
DEAD
```

Required behavior:

- `ROAM` uses flock-assigned POIs and offsets.
- `ALERT` approaches while maintaining separation.
- `REQUEST_ATTACK` waits for a coordinator token.
- `TELEGRAPH_ATTACK` captures or narrows the attack direction.
- `ATTACK` is committed enough to be dodgeable.
- `RECOVER` prevents immediate repeated contact damage.
- `DISENGAGE` creates space after attacking.
- `REGROUP` returns isolated members toward the flock without stacking them into one point.

### 8.7 Attack scheduling

The flock must feel aggressive without producing unavoidable simultaneous hits.

- Limit concurrent attack tokens.
- Enforce minimum spacing between attack starts.
- Prevent two members from selecting nearly identical attack lines when possible.
- Members without a token continue chase, flank, or reposition behavior.
- Use a per-player hit grace period if testing shows collision overlap can produce several 25-damage hits in one instant.
- A member that hits or misses must disengage before requesting another token.

### 8.8 Attack

- Strong visible and audible warning.
- Fast committed movement toward a captured position or line.
- Approximately 25 damage on successful contact.
- Moderate force.
- Damage once per attack pass.
- Can strike other species.
- Terrain collision ends the attack and begins recovery.
- Attacks must be readable against the Layer 2 background and during Curse discoloration.

### 8.9 Relic and system interactions

| Source | Expected response |
|---|---|
| Plate Umbrella | Can reduce one frontal strike; transfers force and heavy stability damage; other angles remain exposed |
| Lacerator | Can wound one member and apply Bleed; does not control the rest of the flock |
| Resonance Core | Can redirect searching or uncommitted members toward a strong impact |
| Bolt Shock | Disables exactly one struck member for adjustable durations; flock remains active |
| Rattlepod | Redirects uncommitted members but may keep the flock near the chosen location |
| Hushcap | Breaks sight through the cloud; does not remove shared last-known position |
| Lantern Crystal | Dazzles affected individuals and emits a strong lure |
| Cling Resin | Rejected during flight |
| Driftseed | Reduces individual flight speed and changes force response |
| Silver Weight | Deals configured heavy damage; no automatic `small_enemy` kill unless explicitly chosen |

### 8.10 Exported flock tuning values

```gdscript
@export var starting_member_count: int
@export var maximum_simultaneous_attackers: int
@export var minimum_group_attack_spacing: float
@export var shared_alert_duration: float
@export var regroup_distance: float
@export var preferred_member_separation: float
@export var active_side_transfer_delay: float
@export var player_multi_hit_grace_duration: float
```

### 8.11 Exported individual tuning values

```gdscript
@export var health: float
@export var roam_speed: float
@export var chase_speed: float
@export var attack_speed: float
@export var sight_range: float
@export var sight_angle_degrees: float
@export var ordinary_acquisition_duration: float
@export var last_seen_memory_duration: float
@export var attack_telegraph_duration: float
@export var attack_damage: float = 25.0
@export var attack_force: float
@export var attack_duration: float
@export var recovery_duration: float
@export var disengage_distance: float
@export var driftseed_speed_multiplier: float
@export var electric_stun_duration_multiplier: float
@export var silver_weight_damage: float
```

---

## 9. Cross-enemy interaction contract

Layer 2 depends on short ecosystem chains. The following interactions are required or strongly recommended.

| Source event | Receiver | Expected result |
|---|---|---|
| Primate rock hits terrain | Tremor Hound | Investigates impact position |
| Primate rock hits another species | Carrion Stalker | May prefer newly injured target |
| Tremor Hound pounce hits another species | Carrion Stalker | Re-evaluates target priority |
| Bulwark charge collision | Tremor Hound | Strong investigation event |
| Bulwark injures another species | Carrion Stalker | Injured actor gains prey score |
| Sky Hunter injures another species | Carrion Stalker | Injured actor may become prey |
| Lacerator causes Bleed | Carrion Stalker | Bleeding target gains strong priority |
| Resonance Core impact | Primate/Hound/Hunter | Investigate according to sensory rules |

### Chain-reaction safety

- Every sound/disturbance receiver requires an investigation cooldown.
- One event must not recursively emit itself without a new physical action.
- Group alerts require cooldowns and finite radius.
- Territorial enemies eventually return home.
- Carrion target switching requires a score margin and commitment timer.
- A collision may damage multiple species, but each target receives at most one hit from that attack event.

---

## 10. Section and spawner contract

Each Layer 2 side contains three seamless sections, with two authored variations per section. Generation selects variations from a seed. Enemy spawners are manually placed inside each variation and independently roll their configured spawn chance.

### Recommended distribution

| Region | Primary enemies | Optional overlap |
|---|---|---|
| Top inverted forest | Canopy Primate, Sky Hunter Flock | Rare Tremor Hound only where normal footing exists |
| Middle normal forest | Tremor Hound, Carrion Stalker | Primates in selected canopy spaces; Sky Hunters in clearings |
| Bottom rocky terrain | Bulwark Beast, Tremor Hound, Carrion Stalker | Sky Hunters in exposed gaps |

### Spawner resource fields

```gdscript
@export var enemy_definition: EnemyDefinition
@export var spawn_chance: float
@export var minimum_count: int = 1
@export var maximum_count: int = 1
@export var required_anchor_group: NodePath
@export var territory_area: NodePath
@export var section_tags: Array[StringName]
@export var unique_spawn_key: StringName
@export var enabled_for_seed_generation: bool = true
```

Rules:

- Spawn roll must be deterministic from the world seed and stable spawn key.
- Loading a save must restore the previous result rather than rerolling.
- A dead persistent enemy must not respawn when its section reloads.
- Invalid required anchors should log a clear editor/development warning and skip spawning safely.
- Sky Hunter Flock uses its dedicated persistent coordinator rather than ordinary local spawners.

---

## 11. Layer 2 Curse fairness

The Layer 2 ascent Curse can:

- Reduce the player’s healable maximum health in stacks.
- Randomly stop movement for approximately 0.5 seconds.
- Reduce throwing distance.
- Discolor the screen.

Enemy implementation must account for this without directly reading or manipulating Curse state.

Required encounter safeguards:

- Major charge/dive telegraphs should normally exceed the movement-stop duration or provide prepared cover.
- Group attack scheduling must prevent unavoidable stacked hits.
- Reduced throwing distance must not make every authored distraction point unreachable.
- Critical cues require shape, motion, and sound; do not depend only on color.
- Enemies cannot attack through safe-shop boundaries.
- The Layer 2 shop remains a safe area even when the flock is active nearby.

---

## 12. Audio and animation event hooks

This is not an asset list. Programmers must expose stable events so art and sound can connect without changing AI code.

Recommended signals or animation callbacks:

```gdscript
signal became_alerted(target_position: Vector2)
signal attack_telegraph_started(attack_id: StringName)
signal attack_committed(attack_id: StringName)
signal attack_interrupted(attack_id: StringName)
signal attack_recovered(attack_id: StringName)
signal emitted_group_alert(position: Vector2)
signal received_disturbance(position: Vector2, intensity: float)
signal target_changed(old_target: Node, new_target: Node)
signal stun_started(duration: float)
signal detector_suppression_started(duration: float)
signal detector_suppression_ended()
signal died(source: Node)
```

Use animation events for exact projectile release and hitbox activation timing. Do not infer those moments from hardcoded frame numbers in AI scripts.

---

## 13. Save-data checklist

| Enemy/system | Persistent data |
|---|---|
| Canopy Primate | Alive, health, statuses, section/perch or safe restore position, group ID |
| Tremor Hound | Alive, health, statuses, section/home territory; investigation target may reset |
| Carrion Stalker | Alive, health, statuses, section/home territory; target selection may reset |
| Bulwark Beast | Alive, health, statuses, section/home territory; load into safe non-charge state |
| Sky Hunter member | Stable member ID, alive, health, statuses |
| Flock coordinator | Flock ID, member list, active side/region, global defeated state |
| Deterministic spawner | Spawn result and persistent unique key |

On load:

- Do not restore an enemy inside terrain.
- Do not resume midway through a damaging attack unless the current save system explicitly supports it safely.
- Clear temporary attack tokens and rebuild group membership.
- Remove references to dead or unloaded targets.
- Restore detector suppression only if active status durations are already persisted; otherwise load detectors enabled and enemies in a neutral recovery state.

---

## 14. Testing matrix

### Shared

- [ ] Same-species attacks are rejected.
- [ ] Cross-species attacks deal damage once and apply force correctly.
- [ ] Bolt Shock suppresses every detector type through the shared interface.
- [ ] Dazzled affects sight without disabling sound/status targeting.
- [ ] Hushcap blocks sight but does not mute sound.
- [ ] Enemy death and health persist through save/load and section reload.
- [ ] Spawner results remain stable for the same seed/save.
- [ ] Shop safety boundaries cannot be crossed by attacks or pursuit.

### Canopy Primate

- [ ] Group alert communicates last seen position without perfect tracking.
- [ ] Attack tokens limit simultaneous throws.
- [ ] Primates reserve different perches.
- [ ] Ceiling and floor perch transitions do not invert collision incorrectly.
- [ ] Hitting during aim cancels projectile creation.
- [ ] Projectile follows gravity and applies configured knockback.
- [ ] Plate Umbrella blocks only frontal rocks.
- [ ] No unlimited collectible-rock accumulation occurs.

### Tremor Hound

- [ ] Footsteps, landings, and impacts create distinct disturbance intensities.
- [ ] Hound travels to the recorded event location rather than tracking the player magically.
- [ ] Standing still prevents new footstep events but not close-range confirmation.
- [ ] Hushcap does not accidentally silence the player.
- [ ] Driftseed reduces landing disturbance.
- [ ] Pounce direction is committed and missing creates recovery.

### Carrion Stalker

- [ ] Bleeding targets receive higher priority.
- [ ] Bandage removal causes eventual rescan rather than permanent tracking.
- [ ] Poison remains relevant after Bandage.
- [ ] Stalker does not switch targets every frame.
- [ ] Same-species Stalkers do not hunt each other.
- [ ] Target selection respects route validity and shop protection.
- [ ] Lacerator can redirect the Stalker by wounding another species.

### Bulwark Beast

- [ ] Charge direction locks before damaging movement.
- [ ] Beast cannot stop immediately after missing.
- [ ] Charge deals approximately 50 provisional damage once per pass.
- [ ] Player incapacitation lasts the configured duration.
- [ ] Terrain remains indestructible.
- [ ] Breakable rocks and other species accept charge impacts.
- [ ] Plate Umbrella cannot fully stop the Beast.
- [ ] Bolt Shock ends the charge safely and enters a valid stun state.

### Sky Hunter Flock

- [ ] Flock is created once and never duplicated by section loading.
- [ ] Dead members remain dead until New Game.
- [ ] Group alert shares a position without permanent exact tracking.
- [ ] Attack tokens prevent unavoidable simultaneous strikes.
- [ ] Each attack deals approximately 25 provisional damage once.
- [ ] One Bolt Shock rod affects one member, not the whole flock.
- [ ] Driftseed affects individual flight.
- [ ] Plate Umbrella protects only from the covered angle.
- [ ] Shop boundary remains safe.
- [ ] Large Layer 1 Flyer no longer transfers into active Layer 2 gameplay.

---

## 15. Jam-scope implementation order

1. Implement/verify shared disturbance events, detector suppression, and attack interruption.
2. Implement Canopy Primate perch movement and one-member rock attack.
3. Add Primate group alerts, perch reservation, and attack-token coordination.
4. Implement Bulwark locked charge, collision damage, slowdown, and recovery.
5. Implement Tremor Hound event scoring, investigation, and committed pounce.
6. Implement Carrion Stalker prey scoring, shadowing, bite, and retreat.
7. Implement one Sky Hunter member with patrol, sight chase, committed attack, and recovery.
8. Add the persistent flock coordinator, group alerts, separation, and attack scheduling.
9. Connect all four Layer 2 relics and existing Layer 1 relic interactions.
10. Add save/load restoration and deterministic spawner verification.
11. Tune section encounters and Curse fairness through playtesting.

### Explicitly out of scope unless core work is complete

- Advanced behavior trees.
- Procedural navigation generation for inverted trees.
- Full flocking or boid simulation.
- Dynamic terrain destruction.
- Complex pack tactics beyond shared alert and attack tokens.
- Glasswing combat AI.
- Enemy breeding, feeding schedules, or long-term simulation.
- Respawning enemies during an existing game.

---

## 16. Decisions still left for playtesting

The following values should not block initial implementation:

- Exact health values.
- Primate rock damage and knockback.
- Tremor Hound pounce damage.
- Carrion Stalker bite damage and whether it applies Bleed.
- Sky Hunter starting flock size.
- Maximum simultaneous Primate and Sky Hunter attackers.
- Bolt Shock stun multipliers for Bulwarks and Sky Hunters.
- Silver Weight damage against Bulwarks and Sky Hunters.
- Lacerator ammunition count and final Bleed values.
- Individual enemy sell/drop rewards, if any.

Keep these in resources or exported Inspector fields so the team can balance them without editing AI code.
