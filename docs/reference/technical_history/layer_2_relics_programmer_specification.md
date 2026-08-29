# Layer 2 Relics — Programmer Specification

> **Archived:** historical proposal. Current contract: [`../../implementation/layer_2_relics.md`](../../implementation/layer_2_relics.md).

**Project:** Two-layer game-jam build
**Engine:** Godot
**Document purpose:** Implementation contract for the four Layer 2 relics
**Status:** Working specification; exported tuning values must remain adjustable

> **Answered-questionnaire authority (2026-08-17):** The implementation uses a press-toggle Plate Umbrella; non-throwable Umbrella/Lacerator/Bolt Shock; primary-to-load and secondary-to-fire launchers; a throwable Resonance Core whose first qualifying impact discovers it; four adjustable Lacerator shots; seven non-rechargeable Bolt Shock uses; and context changes that unload launchers without consuming ammunition. Any older conflicting statement below is superseded.

### Locked input and persistence table

| Relic | Primary | Secondary | Context change | Persistent instance state |
| --- | --- | --- | --- | --- |
| Plate Umbrella | Toggle open/close | Same as primary | Close without free stability | Stability and forced recovery |
| Lacerator | Load | Fire loaded ball | Unload without spending ammo | Remaining ammo |
| Resonance Core | Unavailable | Physical throw | Ordinary inventory behavior | World transform/velocity |
| Bolt Shock | Load | Fire loaded rod | Unload without spending a use | Remaining uses |

Umbrella, Lacerator, and Bolt Shock cannot be thrown. Inventory dropping remains available. Core discovery is the sole exception to primary-use discovery: its first qualifying resonant impact reveals it.

---

## 1. Shared implementation requirements

All four relics must use the existing item architecture rather than introducing isolated one-off inventory logic.

### Existing systems to reuse

- `ItemDefinition` for static item data.
- `ItemStack` for inventory ownership and stack state.
- Persistent thrown-item/world-object behavior.
- Existing damage, force, Bleed, sound, detection, and status-effect interfaces.
- Existing hotbar primary-use and secondary-throw conventions.
- Save/autosave support for world objects and per-item state.

### Required data-driven fields

Each relic definition should expose, where relevant:

- Display name and description.
- Inventory icon and world scene.
- Weight.
- Sell value.
- Stack limit.
- Primary-use cooldown.
- Whether the relic can be thrown.
- Throw-speed multiplier.
- Persistent per-instance state.

Do not hardcode Layer 2 enemy names inside relic scripts. Relics should communicate through shared interfaces such as damage, force, status effects, detector suppression, sound events, and interrupt requests.

### Failure and consumption rules

- A failed activation must not consume a use.
- A projectile is consumed only after a valid launch is created.
- Invalid inventory state, blocked spawning, missing aim direction, or UI capture must fail safely.
- Limited-use state must persist through inventory movement, dropping, throwing, saving, loading, and shop transitions.
- Relics dropped in the world must remain recoverable unless their specification explicitly destroys them.

---

## 2. Plate Umbrella

### Purpose

A heavy directional defense relic. It intercepts projectiles and reduces frontal attack damage while transferring force and restricting player movement.

### Suggested scene structure

```text
PlateUmbrellaHeld
├── VisualRoot
├── AnimationPlayer
├── BlockArea2D
│   └── CollisionShape2D
├── ImpactPoint
└── StateTimer
```

The block area must rotate with the player’s aim direction. The collision shape should represent a frontal arc or plate surface, not a full circle.

### Runtime states

```text
CLOSED
OPENING
OPEN
FORCED_CLOSED
RECOVERING
THROWN
```

### Primary use

- Holding primary use requests `OPENING`, then `OPEN`.
- Releasing primary use returns the relic to `CLOSED`.
- Opening fails during forced-close recovery.
- While open, apply movement and optional jump/climb modifiers to the player.
- The umbrella faces the aim direction within an allowed rotation range.

### Blocking contract

An incoming attack can be blocked only when:

1. The umbrella is `OPEN`.
2. The incoming direction falls inside the configured frontal arc.
3. The attack implements the blockable-hit contract.
4. Stability is above zero before resolution.

On a successful block:

- Prevent or reduce attack damage according to `damage_reduction`.
- Prevent projectile-applied status effects when `block_status_effects` is enabled.
- Apply `force_transfer_multiplier` of the incoming force to the player.
- Subtract stability using the attack’s force or explicit stability-damage value.
- Notify the projectile whether it should stop, bounce, fall, or be destroyed.
- Emit a block event for animation, particles, and sound.

The umbrella must not globally grant invulnerability. Attacks outside its arc resolve normally.

### Stability

- Stability regenerates only while closed unless playtesting changes this rule.
- Reaching zero forces the umbrella closed.
- Forced closing starts a recovery timer.
- The item cannot reopen until recovery completes.
- Stability and recovery state should be saved if the game is closed during a living run.

### Secondary use

- Right-click throws the closed umbrella as a persistent physical item.
- Throwing while open first closes it.
- The thrown umbrella deals low impact damage and weight-derived force.
- The thrown item produces an ordinary impact sound event.
- It does not block attacks while lying in the world unless that behavior is explicitly added later.

### Exported tuning values

```gdscript
@export var max_stability: float
@export var stability_regeneration_per_second: float
@export var forced_close_duration: float
@export var block_arc_degrees: float
@export var damage_reduction: float
@export var force_transfer_multiplier: float
@export var open_move_speed_multiplier: float
@export var open_jump_multiplier: float
@export var open_climb_multiplier: float
@export var opening_duration: float
@export var thrown_damage: float
@export var thrown_force_multiplier: float
@export var block_status_effects: bool = true
```

### Enemy-specific expected outcomes

- **Primate rock:** blocked from the front; damages stability.
- **Sky Hunter strike:** damage reduced, substantial force transferred, major stability loss.
- **Tremor Hound pounce:** damage reduced from the front; large stability loss.
- **Carrion Stalker bite:** directional block only; circling remains effective.
- **Bulwark charge:** partial damage reduction at most, full or high knockback, immediate forced close.
- **Alarm Grazer:** no direct interaction beyond blocking sight if level code treats the open umbrella as an occluder. This is optional and should be tested before inclusion.

---

## 3. Lacerator

### Purpose

A gravity-affected launcher that deploys persistent damaging balls. A ball deals small contact damage, inflicts Bleeding, remains on the ground, and expires after four valid damaging contacts.

### Current interpretation requiring confirmation

This specification interprets “stays on the ground and lasts for 4 hits” as follows:

- Each launched ball remains as a physical ground hazard.
- Each ball can produce four valid damaging contacts.
- Terrain collisions do not consume those contacts.
- The launcher’s ammunition count is a separate playtest value.

If “four hits” instead means four total launcher shots, change the resource model before production; the art brief already keeps ammunition indicators separate.

### Suggested scenes

```text
LaceratorHeld
├── VisualRoot
├── Muzzle
├── AnimationPlayer
└── FireCooldown

LaceratorBall
├── RigidBody2D
├── VisualRoot
├── DamageArea2D
│   └── CollisionShape2D
├── PerTargetCooldowns
└── AnimationPlayer
```

### Primary use

- Aim toward the cursor.
- Validate that ammunition or charge is available.
- Spawn one `LaceratorBall` at the muzzle.
- Apply initial velocity using launch speed and aim direction.
- Allow normal gravity to form the trajectory.
- Decrease ammunition only after successful spawning.
- Start the firing cooldown.

### Ball behavior

- The ball is a persistent physical world object.
- It can damage while moving and while resting on terrain.
- A valid contact deals small direct damage and applies the existing Bleed status.
- Each valid contact decrements `remaining_hits` once.
- Terrain contact never decrements `remaining_hits`.
- Repeated physics callbacks must not consume all four hits immediately.
- Require the target to exit and re-enter, or enforce a per-target re-hit cooldown.
- At zero hits, play the depletion response and disable the damage area immediately.
- After depletion, either destroy the ball after its animation or leave inert debris according to performance testing.

### Damage filtering

- Use existing accepted-hit and faction/cross-species rules.
- Do not decrement durability when the target rejects the hit.
- Do not apply Bleed when the hit is rejected.
- One contact should create one damage event even if multiple collision shapes overlap.
- Optional attack interruption must use the enemy’s shared interrupt interface, not direct state assignment.

### Secondary use

- Right-click throws the launcher itself as a persistent item.
- Throwing does not automatically fire a ball.
- Its ordinary item impact should deal minimal damage and weight-derived force.

### Persistence

Save for every launcher instance:

- Remaining ammunition or charges.

Save for every deployed ball:

- Transform and velocity if the current save system preserves active physics objects.
- Remaining valid hits.
- Armed/inert state.

### Exported tuning values

```gdscript
@export var ammunition_capacity: int
@export var launch_speed: float
@export var launch_speed_mouse_distance_curve: Curve
@export var fire_cooldown: float
@export var ball_gravity_scale: float
@export var direct_damage: float
@export var bleed_duration: float
@export var bleed_damage_per_tick: float
@export var ball_valid_hits: int = 4
@export var same_target_rehit_cooldown: float
@export var resting_velocity_threshold: float
@export var interrupt_strength: float
@export var inert_cleanup_delay: float
```

### Enemy-specific expected outcomes

- **Primate:** can bleed and may be interrupted during throw preparation.
- **Tremor Hound:** impact sound creates a disturbance; a timed hit may interrupt pounce preparation.
- **Alarm Grazer:** being hit causes its normal panic/alarm response.
- **Carrion Stalker:** bleeding targets become higher-priority prey, including other species.
- **Bulwark Beast:** takes limited damage but does not cancel an active charge.
- **Sky Hunter:** one individual can be injured; the relic does not disable the flock.

---

## 4. Resonance Core

### Purpose

A very heavy quest relic found in the gauntlet. It emits sound/vibration events when dropped, thrown, struck, or hit by another creature. It is delivered to the Layer 2 gatekeeper in exchange for the next whistle and Bolt Shock.

### Suggested scene structure

```text
ResonanceCore
├── PersistentItemBody
├── VisualRoot
├── AnimationPlayer
├── ImpactSensor
├── ResonanceCooldown
└── InteractionArea2D
```

### Weight behavior

- Use the existing item-weight system.
- The Core must be limited to one per slot.
- Its weight affects inventory burden, player movement, jumping, fall behavior, and throw speed through existing calculations.
- Do not add Core-specific movement code when the shared weight system can produce the required result.

### Resonance behavior

- Measure impact strength from collision impulse, relative velocity, received force, or an explicit impact event.
- Ignore contacts below `minimum_resonance_impact`.
- Map impact strength into sound priority/radius using exported thresholds or a curve.
- Apply a short emission cooldown to prevent continuous collision vibration from creating sound every physics frame.
- Resonance produces no direct damage.
- Emit through the shared sound-event system so any compatible enemy can respond.

### Expected triggers

- Player drops the Core from height.
- Player throws the Core into terrain.
- A projectile or creature strikes it.
- A Bulwark Beast collides with it.
- Another high-force world object collides with it.

### Quest handover

The gatekeeper interaction must:

1. Verify that the player owns the correct unique quest instance or item definition.
2. Ask for confirmation if the project’s quest dialogue supports confirmation.
3. Remove exactly one Resonance Core.
4. Update the fetch-quest state.
5. Award the next whistle/rank according to the progression system.
6. Award one Bolt Shock with its initial uses.
7. Handle full inventory safely by placing the reward in a protected pickup location.
8. Save the completed quest and awarded-reward state immediately.

The interaction must be idempotent: reloading or repeating dialogue cannot award additional Bolt Shocks.

### Exported tuning values

```gdscript
@export var relic_weight: float
@export var throw_speed_multiplier: float
@export var minimum_resonance_impact: float
@export var maximum_resonance_impact: float
@export var minimum_sound_radius: float
@export var maximum_sound_radius: float
@export var minimum_sound_priority: int
@export var maximum_sound_priority: int
@export var resonance_cooldown: float
```

---

## 5. Bolt Shock

### Purpose

A powerful, limited-use quest reward. It fires a physical rod that damages one enemy, immobilizes it, disables its detectors, and applies very small electrical damage over time.

### Suggested scenes and resources

```text
BoltShockHeld
├── VisualRoot
├── Muzzle
├── AnimationPlayer
└── FireCooldown

BoltShockRod
├── ProjectileBody
├── CollisionShape2D
├── VisualRoot
├── Trail
└── ImpactDetector

ElectrocutedEffect
├── DurationTimer
├── StunTimer
├── DetectorSuppressionTimer
├── DamageTickTimer
└── VisualRoot
```

### Primary use

- Aim toward the cursor.
- Validate remaining uses and a valid spawn path.
- Spawn one physical rod projectile.
- Consume one use only after successful spawning.
- Start the firing cooldown.
- The rod affects only the first valid damageable target struck.
- Terrain impact does not electrocute an enemy and normally wastes the use.

### Impact sequence

When a rod hits a valid target:

1. Resolve impact damage through the ordinary damage interface.
2. If the hit is accepted, attach or visually anchor the rod to the enemy.
3. Apply `ElectrocutedEffect` through the status-effect system.
4. Request an immediate movement stun.
5. Suppress the enemy’s detectors.
6. Begin low electrical damage ticks.
7. Remove or disable the rod when the effect completes.

If the enemy rejects the hit, do not apply stun, detector suppression, or damage over time.

### Stun behavior

- Prevent intentional movement and attacks for the effective stun duration.
- Do not disable required physics processing or gravity.
- Cancel current attack preparation unless the enemy definition explicitly resists interruption.
- Clear or pause pathfinding velocity safely.
- Resume in a valid recovery state rather than continuing a stale attack animation.

### Detector suppression

Detector suppression should use one shared gate on the enemy’s perception system.

While suppressed:

- Sight detectors do not acquire or refresh targets.
- Sound detectors ignore new sound events.
- Proximity or tracking sensors do not acquire new information.
- Existing pursuit memory is cleared or suspended according to one consistent project-wide rule.
- The enemy cannot broadcast new detection alerts unless explicitly exempted.

Do not individually disable arbitrary sensor nodes from the projectile script. Apply a status/interface call so new enemy types automatically support the relic.

### Damage over time

- Electrical damage is intentionally very small.
- Damage ticks must pass through ordinary damage acceptance.
- The DOT should not repeatedly trigger heavy hit reactions.
- The final damage tick must not occur after the status has ended.

### Enemy resistance data

Every enemy definition should support multipliers rather than binary immunity:

```gdscript
@export var electric_stun_duration_multiplier: float = 1.0
@export var detector_suppression_duration_multiplier: float = 1.0
@export var electric_damage_multiplier: float = 1.0
@export var electric_interrupt_resistance: float = 0.0
```

Examples:

- Ordinary small enemies may receive full stun and detector suppression.
- A Bulwark Beast may receive a shorter stun, particularly during a committed charge.
- One Sky Hunter is disabled; the rest of the flock remains active.
- A gatekeeper can use tuned multipliers rather than complete immunity.

### Limited uses

- Uses belong to the individual relic instance.
- Remaining uses must persist across inventory movement, dropping, saving, and loading.
- When empty, primary use fails without spawning anything.
- The empty relic remains a physical item and may still be carried, thrown, or sold if allowed.
- Whether fired rods are recoverable is currently assumed to be **no**; change only after a deliberate balance decision.

### Secondary use

- Right-click throws the launcher itself as a persistent object.
- Throwing does not discharge a rod.
- The launcher deals ordinary weight-based impact force and minimal damage.

### Exported tuning values

```gdscript
@export var maximum_uses: int
@export var rod_speed: float
@export var rod_gravity_scale: float
@export var fire_cooldown: float
@export var impact_damage: float
@export var stun_duration: float
@export var detector_suppression_duration: float
@export var shock_duration: float
@export var damage_tick_interval: float
@export var damage_per_tick: float
@export var interrupt_strength: float
@export var rod_cleanup_delay: float
```

---

## 6. Save-data requirements

The game autosaves during a living run, so the following state cannot be reconstructed only from item definitions:

| Relic | Instance/world state to save |
|---|---|
| Plate Umbrella | Stability, forced-close recovery if active, world transform when dropped |
| Lacerator | Launcher ammunition, each deployed ball’s remaining hits, armed state, transform |
| Resonance Core | Ownership or world transform, quest handover state |
| Bolt Shock | Remaining uses, world transform when dropped |

Temporary combat effects such as an enemy’s remaining stun duration may be saved only if the current status-effect save system already supports active effects. If it does not, loading should resolve them consistently rather than leaving enemies permanently frozen or detector-disabled.

---

## 7. Required shared interfaces

Prefer small reusable interfaces or components over relic-to-enemy dependencies.

### Blockable hit

Should provide:

- Incoming direction.
- Damage amount/type.
- Force vector.
- Stability damage override if any.
- Applied status effects.
- Projectile response after blocking.

### Interruptible action

Should accept:

- Interrupt strength.
- Source.
- Optional reason/type.

Should return whether the current action was interrupted.

### Detector suppression

Should support:

- Apply suppression for a duration.
- Extend or replace existing suppression consistently.
- Query whether perception is currently suppressed.
- Notify sensors when suppression begins and ends.

### Resonance/sound event

Should provide:

- World position.
- Priority.
- Radius.
- Source object.
- Optional event category such as impact or resonance.

---

## 8. Test checklist

### Plate Umbrella

- [ ] Blocks only within its configured frontal arc.
- [ ] Does not create full-body invulnerability.
- [ ] Prevents projectile status effects only when the projectile was actually blocked.
- [ ] Transfers configured knockback.
- [ ] Forced close cannot be bypassed by swapping inventory slots.
- [ ] Stability persists after dropping and picking the same instance up.

### Lacerator

- [ ] Ball trajectory responds to gravity.
- [ ] Terrain impacts do not consume valid hits.
- [ ] One overlapping enemy does not consume four hits in one physics frame.
- [ ] Rejected damage does not consume a hit.
- [ ] Bleed uses the shared status implementation.
- [ ] Grounded balls remain visible and hazardous.
- [ ] Remaining ball hits survive save/load.

### Resonance Core

- [ ] Small resting collisions do not spam sound events.
- [ ] Strong impacts create stronger signals.
- [ ] Enemy reactions use the ordinary sound system.
- [ ] Weight behavior comes from the shared inventory system.
- [ ] Quest reward cannot be duplicated by dialogue or reloading.
- [ ] Full inventory does not destroy the reward.

### Bolt Shock

- [ ] A missed rod consumes exactly one use.
- [ ] A valid hit applies impact damage once.
- [ ] Stun prevents movement and attacks without breaking gravity.
- [ ] All detector categories respect suppression.
- [ ] Effect expiration restores movement and detection.
- [ ] DOT stops at effect expiration.
- [ ] One stunned Sky Hunter does not freeze the entire flock.
- [ ] Remaining uses survive save/load and item transfer.

---

## 9. Jam-scope implementation order

1. Implement the shared detector-suppression and interrupt hooks.
2. Implement Bolt Shock as the quest-critical reward.
3. Implement Resonance Core physics, sound emission, and quest handover.
4. Implement Plate Umbrella directional blocking without advanced reflection.
5. Implement Lacerator projectile persistence and four-hit contact tracking.
6. Add save-state support for charges, stability, and deployed balls.
7. Connect final art, animation, VFX, and audio events.
8. Tune enemy-specific multipliers through data resources.

Advanced projectile reflection, dynamic umbrella occlusion, recoverable Bolt Shock rods, and persistent Lacerator debris are optional polish rather than launch requirements.
