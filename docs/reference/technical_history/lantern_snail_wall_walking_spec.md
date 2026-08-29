# Lantern Snail — Wall and Ceiling Walking Handoff

> **Archived:** historical proposal. Current contract: [`../../implementation/layer_1_enemies.md`](../../implementation/layer_1_enemies.md).

## 1. Recommendation

Do not implement wall/ceiling walking as ordinary gravity with a changing gravity vector.

The Snail should use a surface-following controller:

1. Keep a current surface normal.
2. Move along the tangent of that surface.
3. Apply a small inward adhesion motion toward the surface.
4. Probe ahead for the next surface before reaching a corner.
5. When the probe finds a new surface, transition the normal and movement basis smoothly.
6. If no surface is found, enter a short “detached/falling” fallback instead of rotating gravity and hoping physics keeps the Snail attached.

For this game jam, the safest implementation is a hybrid:

- Use authored walkable surfaces or collision geometry as the source of truth.
- Use a forward `ShapeCast2D`/ray probe to detect the next surface.
- Use collision normals only as confirmation and for local corner transitions.

This solves floor → wall, wall → ceiling, ceiling → wall, and wall → floor without allowing the Snail to fall toward the sky or sideways merely because its orientation changed.

## 2. Why the current approach breaks

The current `lantern_snail.gd` does this:

```gdscript
var tangent := Vector2(-_surface_normal.y, _surface_normal.x)
velocity = tangent * _direction * move_speed * support.status.get_multiplier(&"move_speed") - _surface_normal * 60.0
move_and_slide()
```

After movement, it searches slide collisions and replaces `_surface_normal` with a collision normal when the normal differs enough from the current one.

This has several weaknesses:

- The next surface is discovered after the body has already reached the corner.
- A circular collision shape can touch multiple faces at once, producing an unstable or ambiguous normal.
- `move_and_slide()` modifies `velocity` during collision response, so the next frame is not necessarily using the clean tangent/adhesion velocity that the Snail intended.
- Changing `up_direction` changes Godot’s classification of floor/wall/ceiling; it does not itself attach the body to a new surface.
- A new normal does not reposition the body away from the corner or guarantee that the collision shape is still supported.
- A fixed inward force is not the same as a surface snap. If contact is lost for one physics frame, the Snail can begin drifting away.

Godot’s documentation describes `up_direction` as a way to classify surfaces for `move_and_slide()`, while `floor_snap_length` keeps a body attached along the opposite of `up_direction`. That built-in snap is designed around a conventional floor/up relationship, not a body whose walkable surface normal rotates continuously around walls and ceilings. See [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html) and [Using CharacterBody2D](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html).

## 3. Current Snail behavior to preserve

The wall-walking change should not alter these unrelated behaviors:

- `LanternSnail` remains a `CharacterBody2D`.
- Movement speed is `18 px/s` in script and overridden to `9 px/s` in the scene.
- Roaming remains limited by `roam_distance` around `_origin`.
- Proximity and sound agitation still trigger the attack/scream state.
- The Snail remains a light source.
- On death, the light is disabled and the Lantern Crystal is dropped.
- Rotation should continue to align the visual with the current surface.
- Restore and out-of-bounds recovery should return the Snail to its authored origin and default starting surface.

## 4. Coordinate conventions

Use these meanings consistently:

- `surface_normal`: unit vector pointing away from the walkable surface and toward the Snail’s “up” side.
- `inward`: `-surface_normal`, pointing into the surface.
- `tangent`: a 90-degree rotation of `surface_normal`.
- `walk_direction`: `tangent * _direction`.

For the standard clockwise route around a rectangular room:

| Surface | `surface_normal` | Forward tangent for `_direction = 1` |
|---|---|---|
| Floor | `(0, -1)` | `(1, 0)` — right |
| Right wall | `(1, 0)` | `(0, 1)` — down |
| Ceiling | `(0, 1)` | `(-1, 0)` — left |
| Left wall | `(-1, 0)` | `(0, -1)` — up |

If the desired route is counterclockwise, either negate the tangent or reverse `_direction`. Do not infer route direction from gravity.

## 5. Preferred controller architecture

Add explicit surface-following state rather than relying on `is_on_floor()`/`is_on_wall()`/`is_on_ceiling()`:

```gdscript
enum SurfaceState { ATTACHED, TRANSITIONING, DETACHED }

var surface_state := SurfaceState.ATTACHED
var _surface_normal := Vector2.UP
var _target_surface_normal := Vector2.UP
var _surface_transition := 0.0
var _last_surface_position := Vector2.ZERO
```

Recommended tunable values:

```gdscript
@export var adhesion_speed := 60.0
@export var surface_probe_distance := 10.0
@export var surface_probe_radius := 8.0
@export var surface_offset := 1.0
@export var normal_turn_speed := 12.0
@export var corner_search_angle := 100.0
@export var corner_search_steps := 7
@export var detach_grace_seconds := 0.12
```

All of these are balance/feel values and should be adjustable in the scene.

## 6. Per-frame movement algorithm

### Step A — Build the current movement basis

Normalize `_surface_normal` every frame. Compute:

```gdscript
var tangent := Vector2(-_surface_normal.y, _surface_normal.x)
var walk_direction := tangent * _direction
var speed := move_speed * support.status.get_multiplier(&"move_speed")
```

Do not use a world gravity vector for attached movement.

### Step B — Probe ahead before moving

Probe from a point slightly outside the Snail in the current normal direction, toward the intended travel direction. The probe should cover the Snail’s front edge, not only its center.

Conceptually:

```gdscript
var probe_origin := global_position + _surface_normal * surface_probe_radius
var probe_end := probe_origin + walk_direction * surface_probe_distance
```

Use a `ShapeCast2D` if the level surfaces are thick or corners are rounded. A ray is acceptable only if the collision geometry is simple and the Snail is small enough that a single center ray cannot miss support.

The probe should detect:

- The current surface continuing ahead.
- A new surface around a convex corner.
- The next surface normal.

The probe must ignore the Snail’s own collision layer and any non-walkable collision layers.

### Step C — Select or retain the surface normal

If the probe finds a support surface:

- Keep the current normal if the surface is effectively continuous.
- Otherwise set `_target_surface_normal` to the hit normal.
- Begin `TRANSITIONING`.

When selecting a hit normal, reject surfaces that are not walkable for this enemy. For a game-jam implementation, this can simply mean checking a dedicated walkable collision layer. This is more reliable than using Godot’s floor classification, because the Snail’s valid “floor” changes as it rotates.

### Step D — Move while attached

While `ATTACHED`:

```gdscript
velocity = walk_direction * speed + (-_surface_normal * adhesion_speed)
move_and_slide()
```

After movement, use the closest valid support collision to correct the normal and keep contact. Do not blindly assign the last collision normal; choose the normal that is most aligned with the expected new normal or the forward probe result.

### Step E — Transition around a corner

During `TRANSITIONING`:

1. Keep the Snail’s center near the corner/support surface.
2. Rotate `_surface_normal` toward `_target_surface_normal` using `lerp`/`slerp` or `Vector2.rotated()` with a capped angular step.
3. Recompute tangent and inward adhesion from the interpolated normal every physics frame.
4. Continue moving along the new tangent.
5. End the transition once the normal is within a small angular tolerance, for example `5°`.

The important detail is that the normal changes as part of a controlled transition while the body remains supported. It is not a one-frame assignment followed by ordinary gravity.

For square corners, the probe may see both the old and new faces. Prefer the candidate whose normal is most aligned with the expected turn direction. If there are two candidates, select the one with the smallest angular change from the current normal and whose surface lies in front of the Snail.

## 7. The wall-up-to-ceiling case

The difficult case is usually described as “wall upward to floor on top,” but mechanically it is wall → ceiling:

1. On the wall, the Snail’s normal points sideways.
2. Its tangent points upward.
3. Before the Snail reaches the corner, the forward probe detects the ceiling face.
4. The controller selects the ceiling normal, which points downward.
5. The normal rotates through the corner while adhesion remains directed into the connected surface.
6. The tangent rotates from upward to horizontal, so the Snail exits the corner moving across the ceiling.

The Snail should never experience a frame where “gravity” is simply changed from down to sideways or up while the body has no supporting contact. The supporting surface determines the next normal; the normal determines adhesion and tangent movement.

## 8. Robust corner handling options

### Option A — Authored surface graph: safest for the game jam

Give each walkable surface segment a small authored component/resource containing:

- Surface segment shape or endpoints.
- Surface normal.
- Tangent direction.
- Neighbor segment at each end.
- Whether the transition is allowed.

The Snail follows the current segment and switches to its known neighbor at the endpoint. A floor → wall → ceiling route becomes an explicit three-segment path. This is the most deterministic approach and makes level design predictable.

Use this if the level already has authored surfaces or if the Snail only needs to traverse designed cave geometry.

### Option B — Collision-probe controller: less authoring, more tuning

Use forward and inward `ShapeCast2D` probes against level collision. This supports arbitrary connected geometry, but requires careful filtering at corners and a fallback for gaps.

Use this if the cave geometry changes frequently or the project does not have a surface-authoring system.

### Option C — Position teleport at corners: avoid

Snapping the Snail to a new position on the next face can hide the problem temporarily, but causes visible jitter, can tunnel through thin geometry, and makes corner behavior dependent on frame rate. A tiny contact correction is acceptable; a full face-to-face teleport should not be the primary solution.

## 9. Recommended game-jam choice

Implement Option B with a small amount of Option A data:

- Add a walkable collision layer for surfaces the Snail may use.
- Add a forward `ShapeCast2D` and an inward support cast.
- Use the forward cast to detect the next face before the corner.
- Use collision normals to orient the Snail.
- If no valid next face is found, allow only a short detach grace period, then fall normally.
- For any notorious or visually important corner, add an authored transition marker or surface segment so the result is deterministic.

This gives the programmer a general solution without requiring a full path system, while still allowing the level designer to fix individual problem corners.

## 10. Detached fallback

If the inward support probe finds no walkable surface:

- Set `surface_state = DETACHED`.
- Stop applying surface adhesion.
- Apply the game’s ordinary downward gravity or the project’s existing falling behavior.
- Do not keep rotating the Snail’s normal while detached.
- During `detach_grace_seconds`, continue searching for a valid nearby surface; if found, reattach with a controlled normal transition.
- If no surface is found, remain detached until normal recovery/out-of-bounds handling applies.

This prevents the failure mode where changing the normal causes the Snail to accelerate toward the sky or sideways forever.

## 11. Rotation and visual orientation

The current rotation formula is appropriate as a starting point:

```gdscript
rotation = _surface_normal.angle() + PI * 0.5
```

During a transition, update rotation from the interpolated normal, not only after a collision. If the sprite’s artwork has a preferred “belly toward surface” direction, verify the sign with floor, wall, and ceiling screenshots and keep the correction in one configurable visual offset.

The collision shape should remain centered on the body. Do not rotate only the visual while leaving the physical surface basis unchanged.

## 12. Suggested pseudocode

```gdscript
func _physics_process(delta: float) -> void:

	if state == State.ATTACK:
		velocity = Vector2.ZERO
		return

	var speed := move_speed * support.status.get_multiplier(&"move_speed")
	var tangent := Vector2(-_surface_normal.y, _surface_normal.x)
	var walk_direction := tangent * _direction

	var next_surface := _probe_forward_surface(walk_direction)
	if next_surface.valid:
		if next_surface.normal.angle_to(_surface_normal) > normal_change_epsilon:
			_target_surface_normal = next_surface.normal
			surface_state = SurfaceState.TRANSITIONING
	elif not _probe_support_surface():
		_detach_or_recover(delta)

	if surface_state == SurfaceState.TRANSITIONING:
		_surface_normal = _rotate_normal_toward(
			_surface_normal,
			_target_surface_normal,
			normal_turn_speed * delta
		)
		if _surface_normal.angle_to(_target_surface_normal) <= normal_change_epsilon:
			_surface_normal = _target_surface_normal
			surface_state = SurfaceState.ATTACHED

	if surface_state != SurfaceState.DETACHED:
		up_direction = _surface_normal
		var current_tangent := Vector2(-_surface_normal.y, _surface_normal.x)
		velocity = current_tangent * _direction * speed - _surface_normal * adhesion_speed
		move_and_slide()
		rotation = _surface_normal.angle() + PI * 0.5
```

The exact probe implementation is up to the programmer. The required behavior is the separation between sensing the next surface, choosing the surface normal, and moving along that surface.

## 13. Acceptance tests

### Basic attachment

- [ ] The Snail stays attached to a floor without drifting downward.
- [ ] The Snail stays attached to a wall without drifting sideways away from it.
- [ ] The Snail stays attached to a ceiling without falling.
- [ ] The Snail does not accelerate toward the sky or sideways merely because its surface normal changes.

### Transitions

- [ ] Floor → wall works in both left and right directions where geometry is connected.
- [ ] Wall → ceiling works while moving upward.
- [ ] Ceiling → wall works while moving toward either side.
- [ ] Wall → floor works while moving downward.
- [ ] The Snail remains in contact throughout a rounded or square corner transition.
- [ ] The Snail’s sprite rotates continuously and does not snap to an incorrect orientation.
- [ ] The Snail does not reverse direction unexpectedly at a corner.

### Geometry and failure handling

- [ ] A gap or non-walkable surface causes a controlled detach/fall rather than an infinite sideways/skyward acceleration.
- [ ] The Snail can reattach to a nearby valid surface during the detach grace period.
- [ ] Non-walkable collision layers are ignored by surface probes.
- [ ] The collision shape does not tunnel through thin corners.

### Existing behavior regression

- [ ] Roaming still respects `roam_distance` along the active surface route.
- [ ] Proximity agitation and sound agitation still trigger the scream telegraph.
- [ ] The Snail’s light remains active while alive and turns off on death.
- [ ] Lantern Crystal drops with the correct offset relative to the current surface.
- [ ] Save/restore and out-of-bounds recovery return the Snail to its authored starting surface and orientation.

## 14. Files and likely edit locations

| File | Responsibility |
|---|---|
| `game/enemies/layer1/lantern_snail.gd` | Surface state, probes, movement basis, transitions, detach fallback |
| `game/enemies/layer1/lantern_snail.tscn` | Shape casts/probes, collision layers, visual setup, tunable defaults |
| Level collision or surface-authoring scripts | Identify valid walkable surfaces and optional authored corner transitions |

Do not put this logic into generic gravity unless the entire project is being converted to a general surface-walking character controller. For the Snail, a local surface-following controller is lower-risk and easier to tune.

## 15. Programmer questions / decisions

Before implementation, confirm:

1. Are all cave walls and ceilings represented by continuous collision geometry, or are there gaps/one-way surfaces?
2. Should the Snail walk every connected surface, or only surfaces on a dedicated “snail-walkable” layer?
3. Should corners be square, rounded, or both?
4. If the Snail reaches an open edge, should it fall immediately or get the short detach grace period described above?
5. Should `_direction` preserve clockwise/counterclockwise travel around the room, or should it preserve world-left/world-right movement when the surface changes?

## 16. Source references

This handoff was prepared from the attached files:

- `lantern_snail.gd` — file citation: `file_00000000034c81fa99f933ac09a4416d`
- `lantern_snail.tscn` — file citation: `file_00000000c7c881fabcf78e1ebc9c48ef`

Godot references:

- [CharacterBody2D documentation](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
- [Using CharacterBody2D](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html)
