# Knockback Bird — Programmer Implementation Specification

> **Archived:** historical proposal. Current contract: [`../../implementation/layer_1_enemies.md`](../../implementation/layer_1_enemies.md).

## 1. Purpose

This document defines the intended implementation for the **Knockback Bird** enemy.

The bird is primarily a **displacement enemy**. Its normal attack does **no direct damage**. The danger comes from where the player is pushed: ledges, hazards, loss of Curse ascent, bad terrain, or follow-up attacks from other birds.

The intended experience is:

> One bird is primarily a displacement problem. A flock becomes dangerous through timing and terrain.

The bird should be predictable enough that a player can learn and dodge one bird, while multiple birds create pressure through staggered attack timing.

---

# 2. Final Design Rules

The following rules are authoritative for the implementation.

1. The bird is neutral while the player is outside its nest radius.
2. The nest provides the bird's patrol center and patrol radius through the nest configuration.
3. While patrolling, each bird has one random patrol destination.
4. A new patrol destination is selected when:
   - the bird reaches its current destination, or
   - 2 seconds have elapsed.
5. When a player enters the nest radius, normal patrol destination generation stops.
6. The bird becomes alert and attempts to attack the player.
7. The bird uses the `AttackGroupCoordinator` to stagger attack starts.
8. The coordinator must **not inherently limit the flock to one active attacker**. The nest configuration determines how many birds may participate.
9. Once an attack telegraph starts, the bird commits to the attack.
10. At the end of the telegraph, the bird captures the player's current position.
11. The swoop travels toward that captured position.
12. The bird does **not** home toward the player's live position during the swoop.
13. The swoop deals **zero normal damage**.
14. A successful swoop contact applies knockback:
    - 70% horizontal
    - 30% upward
15. A single swoop can hit a player only once.
16. Damage received during the actual swoop cancels the attack and enters recovery.
17. Damage during the telegraph does **not** cancel the attack.
18. The player remaining inside the nest radius means the bird continues to be eligible to attack after recovery.
19. If the player leaves the nest radius during an existing telegraph or swoop, the bird still completes that committed attack.
20. Two successful bird hits against the same player within 2 seconds trigger an additional **10 damage** event.
21. The second hit itself is the trigger: the normal bird hit remains displacement-only, then the species-wide counter applies the additional 10 damage.
22. After the two-hit threshold triggers, the species-wide counter resets.
23. The species-wide hit counter is shared by all birds of this species, not by individual birds.
24. Ordinary external physical force does not move the bird.
25. Valid damage and statuses continue to work through the existing enemy-support systems.
26. Electric stun / disabled flight interrupts normal flight behavior as it already does through `EnemySupport`.

---

# 3. Current Implementation Assessment

The uploaded prototype already contains several useful pieces:

- `KnockbackBird` is a `CharacterBody2D`.
- `EnemySupport` already owns health/status functionality.
- `AttackGroupCoordinator` already provides attack spacing and active-attacker tracking.
- The bird already has configurable telegraph, swoop speed, patrol radius, and knockback values.

However, the current bird script mixes patrol, telegraph, swoop, collision detection, cooldown, and recovery into only three states (`IDLE`, `MOVE`, `ATTACK`). This makes the intended behavior difficult to tune and causes several important behaviors to be implicit.

The current prototype also checks hit distance directly against the target instead of using a dedicated swoop hitbox, and the coordinator exists but is not currently used by the bird.

The current script also cancels the whole `ATTACK` state whenever damage is received, which means telegraph damage currently interrupts an attack. The desired behavior is specifically to cancel **during the swoop**, not during the telegraph.

The prototype's current patrol also continuously calculates an orbit point from elapsed time. The final behavior should instead use a randomly selected destination that remains valid for up to 2 seconds.

---

# 4. Recommended State Machine

Use explicit states:

```text
PATROL
ALERT / WAIT
TELEGRAPH
SWOOP
RECOVERY
```

`DEAD` and `DISABLED` can remain handled by the existing enemy systems rather than being ordinary bird behavior states.

## State overview

| State | Purpose |
|---|---|
| PATROL | Random flight around the nest radius |
| ALERT / WAIT | Player is inside nest radius; patrol is suspended while the bird waits for attack permission |
| TELEGRAPH | Attack warning; player can still dodge |
| SWOOP | Committed high-speed attack toward captured position |
| RECOVERY | Attack has ended; bird returns to normal nest flight |

The explicit `ALERT / WAIT` state is important because the patrol behavior is supposed to be broken as soon as the player is near the nest.

---

# 5. State Flow

Normal flow:

```text
PATROL
   |
   | player enters nest radius
   v
ALERT / WAIT
   |
   | coordinator grants attack start
   v
TELEGRAPH
   |
   | telegraph ends
   | capture player position
   v
SWOOP
   |
   +---- successful hit ------> RECOVERY
   |
   +---- damage interruption -> RECOVERY
   |
   +---- destination reached -> RECOVERY
   |
   +---- max swoop time -----> RECOVERY
                                  |
                                  v
                             PATROL / ALERT
```

After recovery:

- if the player is still inside the nest radius, return to `ALERT / WAIT`;
- if the player has left, return to `PATROL`.

This is important: **the bird should not return to a neutral patrol state while the player is still in the nest.**

---

# 6. Nest Configuration

The nest owns the bird's patrol area.

The bird should not independently invent a second patrol rectangle.

The intended setup is conceptually:

```text
Nest
 ├── nest center
 ├── patrol radius
 ├── attack-group configuration
 └── spawned birds
```

Each spawned bird uses the nest's configured center/radius.

The exact method of passing this configuration to the bird should follow the existing nest implementation.

The bird needs access to at least:

```gdscript
nest_position: Vector2
flight_radius: float
attack_group_id: StringName
maximum_attackers: int
attack_spacing: float
```

The nest remains responsible for configuring these values.

---

# 7. Patrol Destination System

The patrol behavior should be deliberately simple.

Each bird stores:

```gdscript
var patrol_destination: Vector2
var patrol_destination_timer: float
```

When the bird enters PATROL, choose a random point inside the nest radius.

For example:

```gdscript
func choose_patrol_destination() -> void:
    var angle := randf_range(0.0, TAU)
    var distance := sqrt(randf()) * flight_radius
    patrol_destination = nest_position + Vector2.from_angle(angle) * distance
    patrol_destination_timer = 2.0
```

The `sqrt(randf())` is recommended if a uniform distribution across the circular area is desired.

The bird then flies toward:

```gdscript
patrol_destination
```

The destination is replaced when either:

```text
bird reaches destination
OR
2 seconds have elapsed
```

Then a new random point is generated.

---

# 8. Patrol Movement

During PATROL:

```gdscript
var direction := global_position.direction_to(patrol_destination)
velocity = direction * patrol_speed
move_and_slide()
```

The bird should not continuously orbit the nest.

It should instead move from random point to random point.

This produces the intended behavior:

```text
point A
  ↓
fly
  ↓
point B
  ↓
fly
  ↓
point C
```

The bird can naturally appear to wander around the nest without requiring an explicit orbit.

---

# 9. Breaking Patrol When the Player Approaches

The patrol destination timer should effectively stop mattering once the player enters the nest radius.

Do not keep generating random patrol points while waiting for an attack.

Transition:

```text
PATROL
  |
  | player enters radius
  v
ALERT / WAIT
```

At this point:

- stop selecting new patrol destinations;
- stop normal wandering;
- face the target;
- request an attack through the coordinator;
- wait until attack permission is granted.

The bird may use a small idle/hover movement during ALERT / WAIT if needed for presentation, but this should not be another patrol route.

A simple implementation is to keep the bird approximately stationary while waiting.

---

# 10. Why ALERT / WAIT Exists

The coordinator is not intended to make only one bird attack.

The requirement is:

> Any number of birds can attack the player at the same time. The attack group coordinator exists so the attacks line up.

Therefore the coordinator's purpose is **attack timing**, not exclusive attack ownership.

Example:

```text
Bird A requests attack
       ↓
starts telegraph at 0.0s

Bird B requests attack
       ↓
starts telegraph at 0.8s

Bird C requests attack
       ↓
starts telegraph at 1.6s

Bird D requests attack
       ↓
starts telegraph at 2.4s
```

Several birds can therefore be simultaneously:

```text
TELEGRAPH
SWOOP
RECOVERY
```

The important restriction is on **attack start timing**, not active attacker count.

---

# 11. AttackGroupCoordinator Changes

The existing coordinator currently contains:

```gdscript
var maximum_attackers := 1
var attack_spacing := 0.8
```

and `request_attack()` rejects an attack when the active attacker count reaches `maximum_attackers`.

That behavior does not match the final bird design if the nest allows arbitrary numbers of birds to attack simultaneously.

The coordinator should therefore be changed so that its configuration comes from the nest and supports the intended concurrency.

Two acceptable approaches:

### Preferred

Keep `maximum_attackers`, but configure it from the nest.

For example:

```text
maximum_attackers = number of birds allowed to be active
```

or another nest-defined limit.

### Alternative

Allow a special value such as:

```text
maximum_attackers <= 0
```

to mean unlimited.

The coordinator then becomes:

```text
attack start scheduler
```

rather than:

```text
single attacker lock
```

The final choice should match how the nest configuration is already implemented.

---

# 12. Attack Request Timing

When the bird enters ALERT / WAIT:

```gdscript
if attack_coordinator.request_attack(self):
    begin_telegraph()
```

If the coordinator rejects the request because the spacing timer has not expired:

```text
remain ALERT / WAIT
```

Do not resume random patrol.

This creates the desired lineup:

```text
player enters nest
       |
       +--> all birds become alert
               |
               +--> coordinator schedules attack starts
```

---

# 13. Telegraph

Recommended starting duration:

```gdscript
telegraph_duration = 0.6
```

When TELEGRAPH begins:

1. Reserve the attack start through the coordinator.
2. Set the target.
3. Stop patrol behavior.
4. Face the target.
5. Play the telegraph animation/effect.
6. Call the player's existing warning/telegraph interface if appropriate.
7. Wait for the telegraph to finish.

Important:

**Do not capture the final attack position at the start of the telegraph.**

The player should have the telegraph duration to reposition.

---

# 14. Captured Attack Position

At the exact moment the telegraph ends:

```gdscript
attack_target_position = target.global_position
```

Then enter SWOOP.

From this point onward:

```text
attack_target_position is immutable
```

The bird must not replace it with:

```gdscript
target.global_position
```

during the swoop.

This is a core gameplay rule.

---

# 15. Example Dodge

If the player is here:

```text
Bird
  ↓
Player A
```

the bird telegraphs.

The player moves:

```text
Bird
  ↓
       Player A
```

When the telegraph ends, the bird captures the player's new position.

The player can then continue moving during the swoop, but the bird remains committed to the captured point.

This makes the attack readable and dodgeable without making it trivial.

---

# 16. Swoop Movement

During SWOOP:

```gdscript
var direction := global_position.direction_to(attack_target_position)
velocity = direction * swoop_speed
```

Do not use:

```gdscript
target.global_position
```

for movement after the attack has committed.

The swoop should have a maximum duration so a bad destination or collision cannot leave the bird permanently stuck.

Suggested starting value:

```gdscript
swoop_max_duration = 0.8
```

The attack ends when:

- the bird reaches the captured destination;
- the maximum swoop duration expires;
- the bird successfully hits the player;
- the bird receives a valid interrupting damage event.

All paths enter RECOVERY.

---

# 17. Dedicated Swoop Hitbox

The current prototype detects a hit using:

```gdscript
global_position.distance_to(target.global_position)
```

This should be replaced with a dedicated attack hitbox.

Recommended scene structure:

```text
KnockbackBird
├── CollisionShape2D
├── Visual
├── EnemySupport
├── SightSensor
└── SwoopHitbox
    └── CollisionShape2D
```

`SwoopHitbox` should be active only during SWOOP.

Recommended collision behavior:

| State | SwoopHitbox |
|---|---|
| PATROL | Disabled |
| ALERT / WAIT | Disabled |
| TELEGRAPH | Disabled |
| SWOOP | Enabled |
| RECOVERY | Disabled |

This gives the programmer and designer direct control over the attack's collision shape.

---

# 18. One Hit Per Swoop

Add:

```gdscript
var has_hit_this_swoop := false
```

At the beginning of every SWOOP:

```gdscript
has_hit_this_swoop = false
```

On valid player contact:

```gdscript
if has_hit_this_swoop:
    return

has_hit_this_swoop = true
```

Then:

1. apply knockback;
2. register the species hit;
3. disable the attack hitbox;
4. enter RECOVERY.

This prevents several physics frames of overlap from counting as multiple bird hits.

---

# 19. Normal Bird Damage

The bird's normal swoop deals:

```text
0 damage
```

The successful contact is a displacement event.

Do not create a normal bird damage value unless the design is intentionally changed later.

The only damage associated with the bird's normal attack is the species-wide two-hit escalation described below.

---

# 20. Knockback

The intended force is:

```text
70% horizontal
30% upward
```

The vertical component should be deliberately upward rather than derived from the bird's travel vector.

Conceptually:

```gdscript
var away := global_position.direction_to(player.global_position)

var force := Vector2(
    away.x * knockback_strength * 0.70,
    -knockback_strength * 0.30
)
```

This means:

- horizontal movement is away from the bird;
- vertical movement is always upward;
- the player receives a predictable lift.

The exact strength should remain configurable.

Suggested starting value:

```gdscript
knockback_strength = 260.0
```

This should be tuned against actual level hazards rather than against raw damage numbers.

---

# 21. Why the Knockback Direction Uses the Player's Current Position

The bird attacks a captured destination, but the contact itself happens at the actual player position.

Therefore, when the bird successfully hits:

```text
attack destination = where the bird committed to
player position = where contact actually occurs
```

The knockback direction should use the actual contact relationship.

This avoids strange behavior where the player gets pushed based on an old position from the telegraph.

---

# 22. Species-Wide Two-Hit Counter

The two-hit mechanic is a separate system from the attack coordinator.

The coordinator controls:

```text
when birds start attacks
```

The species hit tracker controls:

```text
how many successful bird hits the player has recently received
```

The tracker should be shared by all `knockback_bird` instances.

Conceptually:

```text
Bird A
   \
    \
     → SpeciesHitTracker → Player
    /
Bird B
```

It should not be stored as a variable on an individual bird.

---

# 23. Two-Hit Rule

The final rule is:

```text
Bird hit #1
    ↓
counter = 1

Bird hit #2 within 2 seconds
    ↓
trigger additional 10 damage
    ↓
reset counter
```

The second bird hit itself remains:

```text
0 normal damage + knockback
```

Then the species-wide counter applies:

```text
10 additional damage
```

The additional damage is therefore the consequence of being hit by two birds quickly.

---

# 24. Counter Timing

Use a rolling window based on the last successful bird hit.

Example:

```text
0.00s
Bird A hits
counter = 1

1.20s
Bird B hits
counter = 2
bonus damage = 10
counter = 0
```

If the second hit occurs after the window:

```text
0.00s
Bird A hits
counter = 1

2.10s
Bird B hits
```

The previous hit has expired.

The second hit becomes:

```text
counter = 1
```

It does not trigger the bonus.

Recommended configuration:

```gdscript
species_hit_window = 2.0
species_hits_required = 2
species_bonus_damage = 10.0
```

---

# 25. Only Successful Hits Count

The species counter should increment only after a legitimate bird hit.

Do not count:

- contact while player invulnerability is active;
- a disabled hitbox;
- a duplicate physics-frame overlap;
- a bird that visually passes near the player without a valid attack collision.

The species tracker should receive the event after the bird's hit has been accepted by the player/combat system.

---

# 26. Recommended Species Tracker API

Prefer an explicit API such as:

```gdscript
species_hit_tracker.register_hit(player)
```

rather than exposing ambiguous arguments such as:

```gdscript
player.register_bird_hit(2.0, 2, threshold_damage)
```

The tracker should own:

```text
hit window
required hits
bonus damage
per-player counters
counter reset
```

This makes the mechanic easy to reuse and tune.

---

# 27. Species Tracker Scope

The tracker should be shared by the entire species.

This means:

```text
Nest A / Bird A
Nest A / Bird B
Nest B / Bird C
```

can all contribute to the same player's `knockback_bird` counter if the game design requires the species-wide behavior to be global.

The attack coordinator remains local to the nest/flock.

These are intentionally different scopes:

| System | Scope |
|---|---|
| Patrol radius | Nest |
| Target/attack state | Individual bird |
| Attack spacing | Nest/flock |
| Two-hit counter | Species + player |

---

# 28. Damage Interrupt

The bird should respond to damage differently depending on its state.

## PATROL

Damage does not change the attack state because there is no attack.

## ALERT / WAIT

Damage does not cancel a telegraph because there is no telegraph yet.

## TELEGRAPH

Damage **does not cancel the attack**.

The bird continues its telegraph.

## SWOOP

Damage **does cancel the attack**.

Transition immediately:

```text
SWOOP
  ↓
RECOVERY
```

## RECOVERY

Damage does not restart or cancel recovery.

---

# 29. Damage Interrupt Condition

Use the existing `DamageInfo.causes_hit_reaction` field when determining whether damage should interrupt the swoop.

Conceptually:

```gdscript
func _on_damaged(info: DamageInfo) -> void:
    if state != State.SWOOP:
        return

    if not info.causes_hit_reaction:
        return

    enter_recovery()
```

This is preferable to the current behavior, which treats every `ATTACK` state as interruptible.

The existing `EnemySupport` already uses `causes_hit_reaction` for hit reactions, so the bird should align with that existing convention.

---

# 30. Recovery

Recovery is mandatory after every committed attack.

Enter RECOVERY when:

- player is successfully hit;
- swoop destination is reached;
- swoop timer expires;
- swoop is interrupted by damage.

During RECOVERY:

- disable SwoopHitbox;
- stop attack movement;
- release the coordinator's active attack reservation;
- move back toward the nest / patrol area;
- prevent new attack requests.

Suggested starting duration:

```gdscript
recovery_duration = 0.8
```

---

# 31. Recovery Destination

The bird should recover toward a valid location inside its nest's patrol radius.

The simplest version:

```text
recover toward nest center
```

A better version, if needed during playtesting:

```text
recover toward a point inside the patrol radius
```

The important rule is that recovery should pull the bird back into the nest's authored flight area rather than leaving it at the player's location.

---

# 32. Recovery Completion

When recovery finishes:

```gdscript
if player_is_inside_nest:
    enter_alert_wait()
else:
    enter_patrol()
```

This prevents an unwanted neutral period while the player is still actively threatening the nest.

---

# 33. Player Leaves During Telegraph

If the player leaves the nest radius after the bird has already begun TELEGRAPH:

**Do not cancel the attack.**

The bird has already communicated that it is committing.

At the end of the telegraph:

```text
capture the player's current position
→ swoop toward it
```

If the player continues moving, the bird still does not home.

After the attack:

```text
RECOVERY
→ PATROL
```

because the player is no longer in the nest.

---

# 34. Player Leaves During Swoop

If the player leaves the nest radius during SWOOP:

**Do not cancel the swoop.**

The bird is already committed.

It continues toward:

```text
attack_target_position
```

Then enters recovery.

This prevents the player from exploiting the nest boundary to cancel a committed attack.

---

# 35. Player Remains in Nest

If the player remains inside the nest radius after the bird recovers:

```text
RECOVERY
   ↓
ALERT / WAIT
```

The bird should request another attack when the coordinator permits the next attack start.

The bird should not return to the random patrol loop while the player remains inside the nest.

---

# 36. Multiple Birds

Multiple birds should be allowed to attack the same player.

Example:

```text
Bird A → TELEGRAPH
Bird B → waiting
Bird C → waiting

0.8s later

Bird A → SWOOP
Bird B → TELEGRAPH
Bird C → waiting

0.8s later

Bird A → RECOVERY
Bird B → SWOOP
Bird C → TELEGRAPH
```

This is the desired flock rhythm.

The flock should feel coordinated rather than chaotic.

---

# 37. Coordinator Responsibility

`AttackGroupCoordinator` should do only this:

1. Track the group's attack spacing timer.
2. Decide whether a bird may begin an attack now.
3. Optionally enforce the nest-configured maximum simultaneous attackers.
4. Track active attack reservations.
5. Release reservations when attacks end.
6. Optionally broadcast the group's alert position if that system is used elsewhere.

It should not:

- perform bird movement;
- choose player targets;
- apply damage;
- apply knockback;
- own the species hit counter.

The current coordinator already has the core `request_attack()` / `release_attack()` structure needed for this.

---

# 38. Coordinator Cleanup

Every path that exits an attack must release the attack reservation.

This includes:

- successful hit;
- missed swoop;
- damage interruption;
- electric stun;
- bird death;
- forced disable;
- scene cleanup.

This should preferably be centralized inside the bird's state transition logic.

Do not duplicate:

```gdscript
attack_coordinator.release_attack(self)
```

across many unrelated functions if it can be handled safely by `enter_recovery()` / an attack cleanup function.

---

# 39. EnemySupport Integration

The current `EnemySupport` should remain the authority for:

- health;
- damage;
- statuses;
- electric stun;
- disabled flight;
- persistence;
- status-based flight modifiers.

The bird should continue to expose:

```gdscript
func apply_damage(info: DamageInfo) -> bool:
    return support.apply_damage(info)
```

and:

```gdscript
func apply_status(id: StringName, data: Dictionary = {}) -> bool:
    return support.apply_status(id, data)
```

The current support system already creates the health and status controllers and handles disabled flight when `electro_stunned` is active.

Do not duplicate those systems inside `KnockbackBird`.

---

# 40. External Force

The bird should ignore ordinary physical force.

The current bird already implements:

```gdscript
func apply_force(_force: Vector2) -> void:
    pass
```

That behavior should remain intentional.

The bird should still accept valid:

- damage;
- status effects;
- electric effects;
- interrupts.

The difference is:

```text
generic physical force → ignored
combat damage/status → accepted
```

---

# 41. Electric / Disabled Flight

The existing `EnemySupport.process_disabled_flight()` should continue to run before normal bird movement.

When flight is disabled:

```text
normal bird state machine does not execute movement
```

The support system handles the fall.

Once the disabled status ends, the bird can resume its normal behavior.

If the player is still inside the nest radius afterward, the bird should return to:

```text
ALERT / WAIT
```

rather than blindly resuming random patrol.

---

# 42. SightSensor Responsibility

`SightSensor` should remain responsible for detecting a valid player.

It should not decide whether the bird is allowed to attack.

The bird should combine:

```text
SightSensor sees player
+
player is inside nest radius
+
bird is in an attack-capable state
+
coordinator permits attack
```

to begin a telegraph.

The current scene already contains a `SightSensor` with a configured detection range and angle. Keep that system rather than replacing it with direct player searching unless the existing sensing architecture requires it.

---

# 43. Target Handling

The bird needs:

```gdscript
var target: PlayerController
```

and:

```gdscript
var attack_target_position: Vector2
```

These must have different meanings.

### `target`

The current player being considered by the bird.

### `attack_target_position`

The position captured for the current committed swoop.

Never use the latter as a live target.

---

# 44. State Transition API

Avoid changing the state directly from many locations.

Prefer explicit methods:

```gdscript
func enter_patrol() -> void:
    ...

func enter_alert_wait() -> void:
    ...

func enter_telegraph() -> void:
    ...

func enter_swoop() -> void:
    ...

func enter_recovery() -> void:
    ...
```

Each transition should configure all state-specific properties.

For example:

```text
enter_swoop()
 ├─ capture attack position
 ├─ reset swoop timer
 ├─ reset has_hit_this_swoop
 ├─ enable hitbox
 └─ set swoop velocity
```

And:

```text
enter_recovery()
 ├─ disable hitbox
 ├─ release attack reservation
 ├─ clear attack-specific state
 └─ begin return movement
```

This is much easier to debug than a single `_physics_process()` containing all state logic.

---

# 45. Recommended Variables

A cleaned-up bird should have roughly these configuration groups.

```gdscript
@export_group("Identity")
@export var persistent_id := "knockback_bird"

@export_group("Patrol")
@export var patrol_speed := 70.0
@export var patrol_destination_refresh_time := 2.0

@export_group("Nest")
@export var nest_trigger_radius := 170.0

@export_group("Attack")
@export var telegraph_duration := 0.6
@export var swoop_speed := 240.0
@export var swoop_max_duration := 0.8
@export var recovery_duration := 0.8

@export_group("Knockback")
@export var knockback_strength := 260.0
@export_range(0.0, 1.0) var horizontal_force_ratio := 0.7
@export_range(0.0, 1.0) var vertical_force_ratio := 0.3

@export_group("Species Hit Counter")
@export var species_hit_window := 2.0
@export var species_hits_required := 2
@export var species_bonus_damage := 10.0
```

The nest should provide the values that are genuinely nest-specific, especially patrol radius and attack-group configuration.

---

# 46. Scene Structure

Recommended scene:

```text
KnockbackBird (CharacterBody2D)
├── CollisionShape2D
├── Visual
├── EnemySupport
├── SightSensor
├── SwoopHitbox (Area2D)
│   └── CollisionShape2D
└── TelegraphVisual
```

`TelegraphVisual` is optional but strongly recommended.

---

# 47. Collision Responsibilities

Keep these separate:

```text
CharacterBody2D collision
    = physical body

SwoopHitbox
    = attack contact

SightSensor
    = perception

Nest radius
    = territory/aggression
```

Do not use the bird's normal body collision as the attack detection.

This allows the attack hitbox to be tuned independently of the bird's physical body.

---

# 48. Attack Hit Processing

The intended successful-hit flow is:

```text
SwoopHitbox detects Player
        |
        v
validate contact
        |
        v
check has_hit_this_swoop
        |
        v
mark hit
        |
        +--> apply 70/30 knockback
        |
        +--> register species hit
        |        |
        |        +--> possibly apply 10 bonus damage
        |
        +--> disable SwoopHitbox
        |
        v
RECOVERY
```

The species tracker should be called only after the contact has been accepted as a legitimate hit.

---

# 49. Species Hit Tracker Example

The tracker can conceptually use:

```gdscript
class_name BirdSpeciesHitTracker
extends Node

@export var hit_window := 2.0
@export var hits_required := 2
@export var bonus_damage := 10.0

var _player_data: Dictionary = {}
```

Per-player state could be:

```gdscript
{
    "count": 1,
    "last_hit_time": 123.45
}
```

The exact implementation can use instance IDs or another player identity mechanism already present in the project.

The important behavior is:

```text
register successful bird hit
    ↓
if previous hit is older than hit_window:
    reset count
    count = 1
else:
    count += 1

if count >= hits_required:
    apply bonus damage
    reset count
```

---

# 50. Species Tracker Location

The tracker should be created at a scope that matches the intended species-wide behavior.

Good options include:

- a combat manager;
- a global enemy/system manager;
- a species-level manager;
- another existing global gameplay service.

Avoid putting it inside every bird.

If the existing project already has a suitable global combat or enemy registry, use that instead of creating another singleton solely for this enemy.

---

# 51. Patrol / Attack Interaction

The key transition is:

```text
PATROL
```

becomes:

```text
ALERT / WAIT
```

as soon as a valid player is within nest proximity.

At that point the bird stops choosing random destinations.

The attack coordinator decides when its telegraph begins.

After recovery:

```text
player inside nest → ALERT / WAIT
player outside nest → PATROL
```

This is the complete aggression loop.

---

# 52. Suggested Starting Timing

These are recommended starting values, not final balance.

| Parameter | Starting value |
|---|---:|
| Patrol destination refresh | 2.0 s |
| Telegraph | 0.60 s |
| Swoop speed | 240 px/s |
| Swoop max duration | 0.80 s |
| Recovery | 0.80 s |
| Knockback strength | 260 |
| Horizontal force | 70% |
| Vertical force | 30% |
| Species hit window | 2.0 s |
| Species hits required | 2 |
| Species bonus damage | 10 |
| Attack spacing | 0.80 s |

The most important values to playtest are:

1. telegraph duration;
2. swoop speed;
3. knockback strength;
4. recovery duration;
5. attack spacing.

---

# 53. What Should Not Be Hard-Coded

Avoid hard-coding:

- nest center;
- patrol radius;
- attack-group ID;
- attack spacing;
- maximum simultaneous attackers;
- species bonus damage;
- hit-window duration.

The nest configuration should provide nest-specific values.

Species-wide values should be owned by the species configuration/tracker.

The bird script should primarily implement behavior.

---

# 54. Implementation Order

Implement the enemy in the following order.

## Phase 1 — State machine

Implement:

```text
PATROL
ALERT / WAIT
TELEGRAPH
SWOOP
RECOVERY
```

Do not implement the species counter yet.

Verify the state flow.

---

## Phase 2 — Random patrol

Implement:

```text
choose random point
→ fly toward it
→ replace after 2 sec or arrival
```

Verify the bird remains inside the nest radius.

---

## Phase 3 — Nest detection

Verify:

```text
outside nest → PATROL
inside nest → ALERT / WAIT
```

and:

```text
player remains inside → bird remains alert after recovery
```

---

## Phase 4 — Coordinator

Connect the bird to `AttackGroupCoordinator`.

Verify that several birds:

```text
receive the same alert
→ request attacks
→ begin telegraphs at the configured spacing
```

Verify that the coordinator is not accidentally restricting the flock to one attacker unless the nest explicitly configures such a limit.

---

## Phase 5 — Telegraph and committed target

Verify:

- telegraph is visible;
- player can move;
- position is captured only at telegraph completion;
- swoop does not home.

---

## Phase 6 — Swoop hitbox

Add the dedicated `SwoopHitbox`.

Verify:

- hitbox only exists during SWOOP;
- one hit maximum per swoop;
- successful contact enters recovery.

---

## Phase 7 — Knockback

Implement the 70/30 force split.

Test against actual level geometry.

Do not balance the bird based solely on how the knockback feels in an empty test room.

---

## Phase 8 — Damage interruption

Verify:

```text
TELEGRAPH + damage → continue telegraph
SWOOP + damage → recovery
```

This distinction is important.

---

## Phase 9 — Species hit counter

Implement:

```text
hit 1
→ hit 2 within 2 sec
→ +10 damage
→ reset
```

Verify that different birds contribute to the same player counter.

---

## Phase 10 — Presentation

Only after the gameplay is correct:

- telegraph animation;
- warning effects;
- wing animation;
- swoop animation;
- sound;
- hit feedback;
- recovery animation.

---

# 55. Acceptance Tests

## Territory

- [ ] Bird is neutral outside nest radius.
- [ ] Bird patrols around its configured nest.
- [ ] Player entering nest radius interrupts normal patrol behavior.
- [ ] Player leaving nest radius causes the bird to become neutral after any already-committed attack finishes.

## Patrol

- [ ] Bird chooses one random point.
- [ ] Bird flies toward that point.
- [ ] Destination changes when reached.
- [ ] Destination also changes after 2 seconds.
- [ ] Patrol destination generation stops while the player is near.

## Attack scheduling

- [ ] Alert birds request attacks through the coordinator.
- [ ] Attack starts are separated by the configured spacing.
- [ ] Multiple birds can be in active attack states simultaneously when allowed by the nest configuration.
- [ ] Coordinator reservations are released correctly.

## Telegraph

- [ ] Telegraph lasts the configured duration.
- [ ] Telegraph communicates attack intent.
- [ ] Player can move during telegraph.
- [ ] Damage during telegraph does not cancel the attack.
- [ ] Attack position is captured at telegraph completion.

## Swoop

- [ ] Bird flies toward the captured position.
- [ ] Bird does not home toward the player's current position.
- [ ] Swoop has a maximum duration.
- [ ] Swoop hitbox is active only during swoop.
- [ ] One swoop can hit a given player only once.
- [ ] Normal bird hit deals zero damage.

## Knockback

- [ ] Horizontal component is 70%.
- [ ] Vertical component is 30%.
- [ ] Vertical component is upward.
- [ ] Knockback is based on the actual contact relationship.

## Damage interruption

- [ ] Valid damage during SWOOP enters recovery.
- [ ] Swoop hitbox is disabled immediately.
- [ ] Attack coordinator reservation is released.
- [ ] Damage without a hit reaction does not unintentionally interrupt the swoop.

## Recovery

- [ ] Every completed/interrupted swoop enters recovery.
- [ ] Bird cannot start another attack during recovery.
- [ ] Bird returns toward the nest area.
- [ ] Player still inside nest causes ALERT / WAIT after recovery.
- [ ] Player outside nest causes PATROL after recovery.

## Species counter

- [ ] First successful bird hit creates a counter of 1.
- [ ] Second successful bird hit within 2 seconds triggers 10 bonus damage.
- [ ] The normal bird attacks still deal zero damage.
- [ ] The two-hit bonus is adjustable.
- [ ] The hit window is adjustable.
- [ ] The counter resets after triggering.
- [ ] Hits outside the window do not combine.
- [ ] Different birds contribute to the same player counter.
- [ ] Invalid/invulnerable contacts do not incorrectly increment the counter.

## Physics and statuses

- [ ] Ordinary external force does not move the bird.
- [ ] Valid damage works.
- [ ] Valid statuses work.
- [ ] Electric stun disables normal flight.
- [ ] The bird does not run normal attack movement while flight is disabled.

---

# 56. Final Responsibility Split

The cleanest implementation is:

```text
                         ┌───────────────────┐
                         │   Nest Config     │
                         │                   │
                         │ center            │
                         │ patrol radius     │
                         │ attack spacing    │
                         │ concurrency       │
                         └─────────┬─────────┘
                                   │
                                   ▼
                         ┌───────────────────┐
                         │ Knockback Bird    │
                         │                   │
                         │ PATROL            │
                         │ ALERT / WAIT      │
                         │ TELEGRAPH         │
                         │ SWOOP             │
                         │ RECOVERY          │
                         └──────┬───────┬────┘
                                │       │
                    ┌───────────┘       └────────────┐
                    ▼                                ▼
          ┌──────────────────┐             ┌──────────────────┐
          │ Attack Group     │             │ Species Hit      │
          │ Coordinator      │             │ Tracker          │
          │                  │             │                  │
          │ attack timing    │             │ 2 hits / 2 sec   │
          │ spacing          │             │ +10 damage       │
          │ concurrency      │             │ reset            │
          └──────────────────┘             └──────────────────┘
                    │
                    │
                    ▼
          ┌──────────────────┐
          │ EnemySupport     │
          │                  │
          │ health           │
          │ damage           │
          │ statuses         │
          │ electric stun    │
          └──────────────────┘
```

## Core design principle

The bird itself should answer:

> **"What am I doing right now?"**

The attack coordinator should answer:

> **"When can I start my next attack?"**

The species tracker should answer:

> **"Has this player been hit by this species twice quickly enough to trigger the escalation?"**

The nest should answer:

> **"Where does this flock live, how large is its territory, and how should its attacks be scheduled?"**

Keeping those responsibilities separate should make the bird much easier to implement, tune, debug, and reuse.
