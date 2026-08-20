# Knockback Bird — Natural Patrol Movement & Path Validation

## Purpose

This document supplements the main Knockback Bird implementation specification.

The current random-point patrol system works mechanically, but choosing a completely independent random destination every few seconds causes the bird to look jittery and artificial.

The goal is to keep the existing behavior:

> Choose a random point → fly toward it → after approximately 2 seconds or on arrival, choose another point.

but make the movement feel more like a bird naturally wandering around its nest.

The implementation should use:

1. Directional bias so the next destination relates to the bird's current travel direction.
2. Smooth steering so the bird does not instantly rotate toward every new point.
3. A smaller usable patrol area inside the nest radius so the bird has room to turn.
4. Randomized destination timing so the bird does not make perfectly synchronized turns.
5. Line-of-sight/path validation so the bird does not select a destination behind an obstacle.
6. Retry generation when a candidate destination is blocked.

---

# 1. Core Patrol Behavior

The patrol loop remains:

```text
PATROL
   |
   v
Generate destination
   |
   v
Validate destination
   |
   +---- blocked ----> Generate another destination
   |
   +---- valid ------> Fly toward destination
                            |
                            +--> reach destination
                            |
                            +--> timer expires
                                      |
                                      v
                              Generate destination
```

The player entering the nest radius still breaks this patrol behavior and transitions the bird into its attack/alert behavior.

This document only changes how PATROL chooses and moves toward destinations.

---

# 2. Do Not Choose Completely Independent Random Points

Avoid simply doing:

```gdscript
destination = random_point_inside_radius()
```

with no relationship to the bird's current movement.

That can produce repeated sharp turns.

Instead, the next destination should have a directional bias. If the bird is currently flying northeast, the next destination should usually be somewhere generally northeast of it, with enough randomness to gradually change course.

Conceptually:

```text
                 possible
              destinations
             •   •   •
              \  |  /
               \ | /
                \|/
              bird
```

rather than allowing the next destination to be equally likely anywhere around the bird.

---

# 3. Directional Bias

Use the bird's current velocity as the basis for the next destination direction.

Conceptually:

```gdscript
var forward_direction := velocity.normalized()
```

If the bird has no meaningful velocity yet, use a random initial direction.

Then rotate that direction by a random angle:

```gdscript
var random_angle := randf_range(
    deg_to_rad(-60.0),
    deg_to_rad(60.0)
)

var candidate_direction := forward_direction.rotated(random_angle)
```

This means the bird generally continues flying in its current direction but can gradually turn.

Recommended starting range:

```text
direction variance: ±60 degrees
```

Make this configurable.

---

# 4. Destination Distance

Do not always place the destination at a fixed distance.

Use a range:

```gdscript
var distance := randf_range(
    patrol_min_distance,
    patrol_max_distance
)
```

Recommended starting values:

```text
minimum distance: 50 px
maximum distance: 120 px
```

Then:

```gdscript
var candidate_position := (
    global_position +
    candidate_direction * distance
)
```

Tune these against the bird's speed and nest size.

---

# 5. Keep the Bird Inside an Inner Patrol Radius

The bird's configured nest radius remains the maximum territory.

However, normal patrol destinations should preferably be generated inside a smaller radius.

For example:

```gdscript
var usable_radius := flight_radius * 0.75
```

This leaves a buffer between normal destinations and the edge of the nest.

The buffer gives the bird room to turn, reduces boundary collisions, and makes movement less constrained.

The nest's actual radius remains authoritative.

---

# 6. Uniform Random Point Generation

If a completely random point inside a circle is ever needed, use a uniform radial distribution:

```gdscript
var angle := randf_range(0.0, TAU)
var distance := sqrt(randf()) * usable_radius

var random_point := nest_position + (
    Vector2.from_angle(angle) * distance
)
```

However, for the normal natural-wandering behavior, directional candidates should be preferred.

A fully random point can still be used as a fallback if directional candidate generation repeatedly fails.

---

# 7. Smooth Steering

Do not immediately set the bird's velocity to the new desired direction.

Avoid:

```gdscript
velocity = desired_direction * patrol_speed
```

because this causes instantaneous changes in direction.

Instead, smoothly steer the existing velocity toward the desired velocity:

```gdscript
var desired_velocity := desired_direction * patrol_speed

velocity = velocity.lerp(
    desired_velocity,
    patrol_steering_strength
)
```

Recommended starting value:

```text
patrol_steering_strength = 0.04
```

This is a tuning value.

The important behavior is that the bird gradually curves into its new direction instead of snapping to it.

---

# 8. Preserve Momentum

The bird should feel like it has momentum.

If it was moving right and the next destination is slightly above it, the bird should gradually curve upward.

It should not instantly switch from horizontal movement to vertical movement.

This is one of the main differences between a natural flying creature and a point-to-point drone.

---

# 9. Randomize the Destination Refresh Time

Keep the intended approximately-2-second behavior, but do not make every destination live for exactly 2.000 seconds.

Use a small randomized range:

```text
minimum: 1.5 seconds
maximum: 2.5 seconds
```

For example:

```gdscript
patrol_destination_time = randf_range(1.5, 2.5)
```

This prevents multiple birds from making identical turns at exactly the same moment.

---

# 10. Destination Refresh Conditions

A new destination should be generated when either:

```text
bird reaches current destination
```

OR:

```text
destination timer expires
```

Whichever happens first.

The next destination should be generated immediately after this event.

---

# 11. Path Blocking Validation

Every generated destination must be checked before being accepted.

The bird should perform a raycast from its **current location** to the **intended destination**.

Conceptually:

```text
Bird
  |
  | raycast
  |
  |---------------------> Destination
```

If nothing blocks the ray, the destination is valid.

If something blocks it:

```text
Bird --------[ WALL ]----------> Destination
                  BLOCKED
```

the destination is invalid.

The bird must discard that point and generate another candidate.

This validation is required every time a new patrol destination is generated.

---

# 12. Raycast Requirements

The raycast should start at:

```gdscript
global_position
```

and end at:

```gdscript
candidate_position
```

Conceptually:

```gdscript
var query := PhysicsRayQueryParameters2D.create(
    global_position,
    candidate_position,
    flight_blocking_collision_mask
)

query.exclude = [self]

var result := get_world_2d().direct_space_state.intersect_ray(query)
```

Adapt the exact Godot API to the project's existing conventions/version.

The raycast should use a collision mask containing things that should physically block the bird's flight.

The query should normally ignore:

- the bird itself;
- other birds, unless intentionally configured as blockers;
- player detection/sensor areas;
- non-solid trigger areas.

Use the project's existing collision-layer conventions for the final mask.

---

# 13. Candidate Validation Loop

Destination generation should use a finite retry loop.

Conceptually:

```gdscript
func choose_patrol_destination() -> void:
    for attempt in max_destination_attempts:
        var candidate := generate_candidate_point()

        if not is_inside_patrol_area(candidate):
            continue

        if not is_destination_path_clear(candidate):
            continue

        if not is_direction_change_acceptable(candidate):
            continue

        patrol_destination = candidate
        return

    choose_safe_fallback_destination()
```

The exact implementation can differ, but the behavior should be equivalent.

---

# 14. Never Use an Infinite Retry Loop

Do not do:

```gdscript
while true:
    candidate = generate_candidate()
    if valid:
        break
```

A bird could be placed in an environment where every candidate is blocked.

Use a finite maximum number of attempts.

Recommended starting value:

```text
MAX_DESTINATION_ATTEMPTS = 10
```

---

# 15. Fallback Destination

If all candidate attempts fail, the bird needs safe fallback behavior.

Preferred fallback:

```text
nest center
```

provided the path to the nest center is clear.

If that is also blocked, reasonable fallback behavior is:

1. retain the current destination if it remains valid;
2. choose a very nearby point;
3. slow/hover temporarily;
4. retry destination generation on the next update.

The important requirement is that the bird must not become permanently stuck because candidate generation failed.

---

# 16. Candidate Must Be Inside the Patrol Radius

Reject candidates outside the usable patrol radius:

```gdscript
if candidate.distance_to(nest_position) > usable_radius:
    continue
```

The intended validation order is:

```text
generate candidate
       ↓
inside patrol radius?
       |
       +-- NO → reject
       |
       v
path raycast clear?
       |
       +-- NO → reject
       |
       v
direction change acceptable?
       |
       +-- NO → reject
       |
       v
ACCEPT
```

---

# 17. Avoid Destinations Too Close to the Bird

Reject candidates that are too close:

```gdscript
if candidate.distance_to(global_position) < patrol_min_distance:
    continue
```

Recommended starting value:

```text
50 px
```

This prevents tiny movements that can look jittery.

---

# 18. Optional Direction-Change Validation

Directional bias should normally be sufficient.

An additional check can reject candidates that require an excessive turn.

For example:

```gdscript
var candidate_direction := (
    candidate - global_position
).normalized()

var direction_dot := velocity.normalized().dot(candidate_direction)
```

Interpretation:

```text
dot ≈  1.0 → same direction
dot ≈  0.0 → 90° turn
dot ≈ -1.0 → 180° reversal
```

A starting rule could be:

```text
direction_dot < -0.25 → reject
```

This is optional because the ±60° directional bias already prevents most extreme turns.

---

# 19. Full Candidate Algorithm

The intended algorithm is:

```text
generate candidate
       |
       v
Is candidate inside usable nest radius?
       |
       +-- NO → retry
       |
       v
Is candidate far enough from bird?
       |
       +-- NO → retry
       |
       v
Does path raycast hit flight-blocking geometry?
       |
       +-- YES → retry
       |
       v
Does candidate require an excessive turn?
       |
       +-- YES → retry
       |
       v
ACCEPT DESTINATION
```

This happens every time the bird needs a new patrol destination.

---

# 20. Recommended Patrol Parameters

Start with:

```gdscript
@export_group("Patrol")

@export var patrol_speed := 70.0

@export var patrol_destination_refresh_min := 1.5
@export var patrol_destination_refresh_max := 2.5

@export var patrol_min_distance := 50.0
@export var patrol_max_distance := 120.0

@export_range(0.0, 1.0)
var patrol_inner_radius := 0.75

@export var patrol_direction_variance_degrees := 60.0

@export_range(0.0, 1.0)
var patrol_steering_strength := 0.04

@export var max_destination_attempts := 10
```

These are starting values only.

---

# 21. Suggested Candidate Generation

Conceptually:

```gdscript
func generate_candidate_point() -> Vector2:
    var forward_direction := velocity.normalized()

    if velocity.length_squared() < 1.0:
        forward_direction = Vector2.RIGHT.rotated(
            randf_range(0.0, TAU)
        )

    var angle := randf_range(
        -patrol_direction_variance_degrees,
        patrol_direction_variance_degrees
    )

    var direction := forward_direction.rotated(
        deg_to_rad(angle)
    )

    var distance := randf_range(
        patrol_min_distance,
        patrol_max_distance
    )

    return global_position + direction * distance
```

The candidate then goes through all validation checks.

---

# 22. Suggested Path Validation

Conceptually:

```gdscript
func is_destination_path_clear(candidate: Vector2) -> bool:
    var query := PhysicsRayQueryParameters2D.create(
        global_position,
        candidate,
        flight_blocking_collision_mask
    )

    query.exclude = [self]

    var result := get_world_2d().direct_space_state.intersect_ray(query)

    return result.is_empty()
```

Again, adapt the exact implementation to the project's Godot version and collision architecture.

The important requirement is:

> Test the complete path from the bird's current location to the candidate destination.

---

# 23. Raycast and Bird Size

A single center ray is the correct starting implementation.

However, a bird has physical size, so a center ray can potentially miss a corner collision.

If playtesting demonstrates this problem, upgrade the validation to a small shape cast or multiple rays.

Do not add that complexity initially unless needed.

Start with the requested single raycast.

---

# 24. What Counts as a Flight Blocker?

The programmer should define a dedicated collision mask for flight-blocking geometry.

Recommended:

```text
Bird Flight Blockers
    ├── solid level geometry
    ├── walls
    ├── terrain
    └── other intentionally blocking geometry
```

Do not automatically treat every collision layer as a blocker.

For the initial implementation, the sensible default is generally:

```text
solid level geometry = blocker
other birds = not blocker
player = not blocker
trigger areas = not blocker
```

The attack system handles player collision separately.

---

# 25. Natural Movement Example

The final path should look more like a smooth wandering trajectory:

```text
             nest boundary
        .---------------------.
     .-'                       '-.
   .'                             '.
  /          •                     |            \                    |
 |             •                   |
 |              \                  |
 |               •                 |
 |              /                  |
 |            •                    |
 |         ↗                       |
  \                                 /
   '.                             .'
     '-.                       .-'
        '---------------------'
```

It should not be a perfect circle, but it should also not be a series of sharp random zigzags.

---

# 26. Multiple Birds

Each bird independently chooses its own patrol destinations.

Do not synchronize patrol destinations across the flock.

For example:

```text
Bird A → northeast
Bird B → south
Bird C → west
Bird D → northeast
```

They should naturally produce different movement.

The attack coordinator remains responsible for synchronizing attack timing.

Patrol movement remains independent.

---

# 27. Interaction With Attack State

The patrol destination system must stop being relevant when the bird leaves PATROL.

When:

```text
player enters nest radius
```

the bird should:

```text
stop generating patrol destinations
→ ALERT / WAIT
```

During:

```text
TELEGRAPH
SWOOP
RECOVERY
```

the bird follows the attack/recovery movement rules from the main specification.

After recovery:

```text
player inside nest → ALERT / WAIT
player outside nest → PATROL
```

If returning to PATROL, generate a fresh destination rather than blindly resuming an obsolete one.

---

# 28. Do Not Simulate Steering With Frequent Random Points

Do not solve jitter by generating random destinations extremely frequently.

For example, avoid:

```text
new random point every 0.1 seconds
```

That generally makes the movement worse.

The intended model is:

```text
relatively infrequent destination changes
+
continuous smooth steering
```

The bird should have a clear movement intention while its actual velocity changes smoothly.

---

# 29. Tuning Order

When tuning, adjust these in order:

### 1. Steering strength

Controls how sharply the bird changes direction.

Too low:

```text
bird feels sluggish
```

Too high:

```text
bird feels robotic/jittery
```

### 2. Direction variance

Controls how much the bird changes course at each destination refresh.

Too low:

```text
bird flies in almost a straight line
```

Too high:

```text
bird constantly turns around
```

### 3. Destination distance

Controls how often the bird needs to turn.

Too short:

```text
lots of small turns
```

Too long:

```text
long straight paths
```

### 4. Destination timer

Controls how often a new intention is generated.

Keep this around the intended 2-second behavior.

### 5. Inner radius

Controls how much room the bird has around the nest.

---

# 30. Recommended Initial Values

Use these for the first playtest:

```text
Patrol speed:                 70
Destination refresh:          1.5–2.5 sec
Minimum destination distance: 50
Maximum destination distance: 120
Inner patrol radius:          75% of nest radius
Direction variance:           ±60°
Steering strength:            0.04
Maximum retries:              10
```

Do not treat these as final balance values.

---

# 31. Acceptance Tests

## Natural movement

- [ ] Bird no longer makes abrupt 90–180° turns under normal patrol.
- [ ] Bird maintains momentum when changing destinations.
- [ ] Bird gradually changes direction.
- [ ] Bird still visibly wanders rather than flying in a perfect circle.
- [ ] Destination refreshes approximately every 2 seconds.
- [ ] Destination timer has slight random variation.
- [ ] Different birds do not all turn at exactly the same time.

## Patrol boundaries

- [ ] Bird stays inside the nest's configured patrol radius.
- [ ] Normal destinations use an inner portion of the radius.
- [ ] Bird does not repeatedly slam into the outer boundary.
- [ ] Recovery can still return the bird to a valid nest location.

## Path validation

- [ ] Every candidate destination is raycast-tested.
- [ ] Raycast starts at the bird's current position.
- [ ] Raycast ends at the candidate destination.
- [ ] The raycast uses the configured flight-blocking collision mask.
- [ ] Flight-blocking geometry invalidates the candidate.
- [ ] Invalid candidates are discarded.
- [ ] A new candidate is generated automatically.
- [ ] Candidate generation repeats until a valid point is found or the retry limit is reached.
- [ ] No infinite candidate-generation loop exists.
- [ ] The bird has safe fallback behavior if all candidates fail.
- [ ] The bird cannot select a destination through a wall or other configured flight blocker.

## Attack interaction

- [ ] Entering nest proximity stops patrol destination generation.
- [ ] Attack states do not use patrol destinations.
- [ ] Recovery does not accidentally resume an obsolete patrol destination.
- [ ] Returning to patrol after an attack generates a fresh destination.

---

# 32. Final Intended Behavior

The final patrol system should work like this:

```text
             choose general direction
                       ↓
              choose destination
                       ↓
              check patrol radius
                       ↓
              check minimum distance
                       ↓
                raycast path
                  /                    blocked      clear
                |            |
                ↓            ↓
          generate again   check turn
                              |
                         acceptable?
                          /                               no        yes
                        |           |
                        ↓           ↓
                   generate      accept
                      again      destination
                                    |
                                    ↓
                           smoothly steer toward
                              desired velocity
                                    |
                         ┌──────────┴──────────┐
                         ↓                     ↓
                    reach point          timer expires
                         |                     |
                         └──────────┬──────────┘
                                    ↓
                             choose again
```

The key design principle is:

> **Randomness determines where the bird wants to go; steering determines how it gets there.**

The raycast acts as a safety filter:

> **If the intended route is blocked, invalidate that destination, generate another point, and repeat the validation process.**

This preserves the original random-point concept while making the bird's movement smoother, more readable, and more natural.
