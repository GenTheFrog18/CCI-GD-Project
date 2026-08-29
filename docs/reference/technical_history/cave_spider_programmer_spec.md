# Cave Spider — Game Jam Programmer Specification

> **Archived:** historical proposal. Current contract: [`../../implementation/layer_1_enemies.md`](../../implementation/layer_1_enemies.md).

## 1. Purpose and design role

The Cave Spider is a small ranged setup enemy for Layer 1. Its individual projectile hit should feel manageable; the danger comes from applying several statuses at once and creating pressure from a larger enemy elsewhere in the layer.

The intended lesson is:

> Enemy combinations are more dangerous than isolated statistics.

A local mistake—being seen and hit by a Cave Spider—should become a layer-wide problem because `Tracking Mark` promotes the player to the Large Flyer’s highest-priority target.

### Combat role

- Ranged status applier.
- Setup enemy for a larger threat.
- Small enemy that can be removed by `Silver Weight`.
- Avoidance-focused threat: light and sufficiently loud events are reliable counters.

## 2. Player-facing behavior

The player should experience the following sequence:

1. The spider patrols or repositions along its configured gravity surface near its authored starting point.
2. A short sight scan detects the player when the player is close enough and visible.
3. The spider visibly aims and gives a 0.7-second warning before firing.
4. The temporary projectile deals modest immediate damage.
5. A successful hit applies all three statuses together:
   - `Spider Slow`
   - `Poison`
   - `Tracking Mark`
6. The player is now slower, takes delayed damage, and becomes the Large Flyer’s highest-priority target.
7. The spider can be driven away by nearby active light or by a priority-8-or-higher sound event.

The projectile is an attack projectile, not a collectible world item.

## 3. Authoritative current values

| Property | Current value | Source |
|---|---:|---|
| Enemy ID | `cave_spider` | `data/enemies/cave_spider.tres` |
| Species ID | `cave_spider` | `.tres`, scene, support node |
| Tags | `small_enemy` | `.tres`, `EnemySupport` |
| Layer | `1` | `.tres` |
| Max health | `22` | `.tres`, `EnemySupport` |
| Movement speed | `52` | `.gd`, `.tres` |
| Gravity direction | `Vector2.DOWN` | `.gd` default; should be overridable by authored placement/configuration |
| Sight range | `150 px` | `cave_spider.tscn` → `SightSensor.normal_range` |
| Sight scan interval | `0.5 s` | `cave_spider.tscn` → `SightSensor.scan_interval` |
| Attack range | `240 px` | `cave_spider.gd` |
| Telegraph / warning | `0.7 s` | `cave_spider.gd` |
| Projectile speed | `170 px/s` | `cave_spider.gd` |
| Projectile damage | `3` default, adjustable | `cave_spider.gd`; expose through enemy/projectile data as appropriate |
| Projectile max hits | `1` | `cave_spider.gd` |
| Post-shot cooldown | `4 s` | `cave_spider.gd` |
| Spider Slow duration | `3 s` | `cave_spider.gd` |
| Poison duration | `10 s` | `cave_spider.gd` |
| Tracking Mark duration | `20 s` | `cave_spider.gd` |
| Flee light radius | `240 px` | `_nearest_light()` uses `attack_range` |
| Flee sound threshold | Priority `>= 8` | `_on_sound()` |
| Silver Weight interaction | Kills as `small_enemy` | Enemy tag contract |

Unless a balancing decision below changes one of these values, treat this table as the implementation contract.

## 4. State machine

### `IDLE`

- Default state after spawn and after a shot.
- Countdown timers continue to tick.
- If a valid target is in range and visible, transition to `ATTACK`.
- If a light is active nearby or a priority-8-or-higher sound is accepted, clear the target and establish a retreat origin.

### `MOVE`

- Move along the tangent of the configured gravity surface.
- Move toward the current target when one exists; otherwise move toward `_origin`.
- Apply the support movement multiplier from statuses.
- Preserve the existing gravity contribution so the character remains grounded on the surface.
- Update sight facing from movement direction.

### `ATTACK`

- Stop movement during the telegraph. The spider must not move while locked on and warning the player.
- Play the `shoot` animation.
- Hold the captured last-known player position in `_aim`; do not silently retarget during the warning.
- After `0.7 s`, spawn and configure one temporary projectile.
- Return to `IDLE` and start the `4 s` cooldown.

## 5. Target acquisition and sight

The `SightSensor` is configured for a short scan every 0.5 seconds. It should only assign a player target when the sensor reports a valid visible `PlayerController`.

The spider must not fire through `Hushcap`: Hushcap should block the sight result, preventing a clean shot. Once the attack telegraph begins, the spider keeps the last-known player position and still fires there even if sight is lost.

The current script checks sight again while deciding whether to enter `ATTACK`, but once the attack state has started it does not perform a second visibility check before firing.

## 6. Attack and telegraph requirements

When the player is detected within `240 px` and visible:

- Capture the player’s current world position in `_aim`.
- Enter `ATTACK`.
- Set the timer to `0.7` seconds.
- Call `target.warn_attack(self, telegraph_seconds)`.
- The player warning callback and existing shooting animation are sufficient; no literal aim line, reticle, laser, or projectile preview is required.
- Fire exactly once when the timer expires.

The projectile direction is calculated from the spider’s position to the captured `_aim` position. This makes the shot telegraphed and dodgeable rather than homing.

## 7. Projectile contract

Spawn:

- Instantiate `res://game/projectiles/projectile.tscn`.
- Set its world position to the spider’s current position.
- Configure velocity as the normalized direction to `_aim` multiplied by `170 px/s`.
- Use `res://assets/art/enemies/cave_spider/projectile.png` for the projectile visual.
- Add it to the spider’s parent so it can travel independently.

Impact payload:

```gdscript
impact.source_actor = self
impact.source_species_id = support.species_id
impact.base_damage = 3.0
impact.max_hits = 1
impact.status_effects = [
    {"effect_id": &"spider_slow", "duration": 3.0},
    {"effect_id": &"poison", "duration": 10.0},
    {"effect_id": &"tracking_mark", "duration": 20.0},
]
```

All three effects should be applied by the same successful impact. The effects are not separate chances, separate projectiles, or delayed follow-up attacks.

## 8. Status interactions

| Effect | Intended gameplay meaning | Required relationship |
|---|---|---|
| Spider Slow | Temporarily reduces player movement | Makes follow-up danger harder to avoid |
| Poison | Delayed damage over its duration | `Bandage` does not remove it, so avoidance remains important |
| Tracking Mark | Marks the player as a high-value target | Must directly feed the Layer-global Flyer’s highest-priority targeting |

The exact stack rules and tick damage should come from the effect definitions/data registry, not be duplicated in the Cave Spider script. The spider only supplies the effect IDs and attack-specific durations.

## 9. Flee responses

### Active light

The spider searches the `light_sources` group for the nearest visible `Node2D` within `240 px`.

While one is found:

- Clear the current target.
- Establish a retreat point 120 px away from the light, on the side opposite the light.
- Move toward that point using normal surface movement.
- Continue fleeing for as long as the spider remains threatened by an active light within range.
- Do not acquire or fire on the player while the light response is active.

The current implementation recalculates `_origin` every physics frame while a nearby light remains active. This is acceptable for the intended “continue fleeing while threatened” behavior, provided it does not prevent the spider from making meaningful retreat progress.

### High-priority sound

When `SoundListener` accepts an event with `event.priority >= 8`:

- Clear the current target.
- Set the retreat point 120 px away from the sound source, on the side opposite the source.
- Immediately cancel/override the current attack setup if the sound arrives during the telegraph.
- Continue fleeing while the sound threat remains active according to the sound system’s event/threat semantics.

This supports the intended counters:

- Strong `Rattlepod` sound.
- `Lantern Crystal` / Snail sound events.

The listener currently has `minimum_priority = 0`; the Cave Spider’s reaction threshold is implemented in `_on_sound()`.

## 10. Gravity-surface movement

The spider uses `gravity_direction` to derive:

- `up_direction = -gravity_direction.normalized()`.
- A surface tangent: `Vector2(-gravity_direction.y, gravity_direction.x)`.
- A tangent direction toward the target or origin.
- A gravity component of `80` along `gravity_direction.normalized()`.

The authored scene currently defaults to downward gravity. The level-placement/configuration system must be able to set the intended gravity direction for non-floor surfaces. The spider should remain associated with its authored surface rather than freely pathfinding through the layer.

## 11. Damage and item interactions

- `Silver Weight` should kill the Cave Spider through the existing `small_enemy` tag behavior.
- Do not add a Cave-Spider-specific Silver Weight branch unless the generic tag interaction cannot support it.
- Normal damage should route through `EnemySupport.apply_damage()`.
- Force and status application should continue routing through `EnemySupport`.

## 12. File ownership and likely edit locations

| File | Responsibility |
|---|---|
| `game/enemies/layer1/cave_spider.gd` | State machine, sensing reactions, movement, telegraph, projectile creation |
| `game/enemies/layer1/cave_spider.tscn` | Collision, sensors, animation frames, scene defaults |
| `game/projectiles/projectile.gd` | Generic projectile travel, hit, and `ImpactData` application |
| `data/enemies/cave_spider.tres` | Enemy registry data, health, speed, layer, tags |
| `enemy_definition.gd` | Shared enemy resource schema and validation |
| `effect_definition.gd` | Shared status-effect schema, stacking, ticking, and modifiers |

Avoid putting global Flyer targeting logic in the Cave Spider. The Cave Spider should emit the `tracking_mark` effect; the Flyer should interpret that mark through the existing layer-global targeting system.

## 13. Acceptance tests

### Detection and firing

- [ ] A player outside `150 px` is not detected by normal sight.
- [ ] Sight scans occur every `0.5 s`.
- [ ] A player in range but blocked by Hushcap does not produce a clean shot.
- [ ] A valid target within `240 px` causes a `0.7 s` warning.
- [ ] The spider remains stationary during the warning.
- [ ] The warning is visible/audible enough for the player to react.
- [ ] The shot uses the captured last-known player position and is not homing.
- [ ] One projectile is spawned per attack.
- [ ] The spider cannot fire again until the `4 s` cooldown expires.

### Impact and status bundle

- [ ] The projectile deals `3` damage on its one allowed hit.
- [ ] One successful hit applies Spider Slow for `3 s`.
- [ ] The same hit applies Poison for `10 s`.
- [ ] The same hit applies Tracking Mark for `20 s`.
- [ ] Tracking Mark causes the Layer-global Flyer to treat the player as its highest-priority target.
- [ ] Bandage does not remove Poison.
- [ ] The projectile cannot hit more than one target.

### Fleeing and counters

- [ ] A visible active light within `240 px` causes the spider to flee away from the light.
- [ ] Rattlepod priority-8-or-higher sound causes the spider to abandon its target and retreat.
- [ ] Lantern Crystal/Snail priority-8-or-higher sound causes the same response.
- [ ] A high-priority sound or nearby active light immediately cancels/overrides the attack during the telegraph.
- [ ] Silver Weight kills the spider through `small_enemy` handling.

### Recovery and persistence

- [ ] Saving/restoring the spider returns it to its authored origin and `IDLE` state according to the current script contract.
- [ ] World out-of-bounds recovery returns it to `_origin` with zero velocity.
- [ ] The spider does not retain a stale player target after fleeing.

## 14. Decisions needed before implementation is considered final

Please confirm these points:

All gameplay decisions requested for this draft are now resolved:

1. The spider remains stationary during the telegraph.
2. The player warning callback and shooting animation are sufficient; no literal aim indicator is needed.
3. If sight is lost during the telegraph, the spider fires at the captured last-known player position.
4. A priority-8-or-higher sound or nearby active light immediately cancels/overrides the telegraph.
5. Poison behavior is owned by the existing effect system and should not be duplicated here.
6. The spider continues fleeing while it remains threatened.
7. Damage values must be adjustable; `3` is the current default, not a hard-coded final balance value.

Remaining implementation note: expose projectile damage through the project’s existing data/configuration pattern so designers can tune it without editing behavior code. Apply the same principle to other balance-sensitive values if the shared enemy/projectile data model supports them.

## 15. Source references

This specification was prepared from the attached project files:

- `cave_spider.gd` — file citation: `file_00000000fc1c820b932455b9298c5801`
- `cave_spider.tscn` — file citation: `file_0000000090b88230ad81d1feaf9a7d02`
- `cave_spider.tres` — file citation: `file_00000000c25881fab44f4cdced8dd9e9`
- `enemy_definition.gd` — file citation: `file_000000006b0c81fa8bec140dbb04921f`
- `effect_definition.gd` — file citation: `file_00000000604c81faab9f9a82d10d0e14`

Related implementation paths named in the current design brief:

- `game/enemies/layer1/cave_spider.gd`
- `game/projectiles/projectile.gd`
- `data/enemies/cave_spider.tres`
