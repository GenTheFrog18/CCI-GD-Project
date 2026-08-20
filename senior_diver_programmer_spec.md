# Senior Diver — Programmer Specification

## 1. Role and design purpose

The Senior Diver is a systemic gatekeeper and progression check for Layer 1.

The Diver guards a restricted, authored zone beside a route that remains usable. The gate is not intended to be a single hard key. The player can:

- Earn Blue Whistle rank.
- Bypass the restricted area with sight-breaking or distraction tools.
- Accept the risk of being grabbed and losing map-found items.
- Fight and defeat the Diver.

The design test is that progression state, inventory provenance, and systemic AI work together without permanently locking the player out of the layer.

## 2. Player-facing contract

### Authorized player

If progression state says the player has earned Blue Whistle rank:

- The Diver does not become hostile when the player enters the restricted radius.
- This remains true even if the physical Blue Whistle item is missing, stolen, dropped, or otherwise absent from inventory.
- The physical whistle is a real inventory object; it must not be used as the sole authorization check.
- Interaction feedback should confirm the rank.

### Unauthorized trespasser

If the player enters the restricted zone without Blue rank while the Diver retains sight:

1. The Diver warns/knocks the player back on the first restricted-zone entry.
2. The Diver chases while sight is maintained.
3. At close range, the Diver gives a short grab telegraph.
4. If the grab succeeds, the player is locked for one second.
5. The Diver confiscates only map-origin inventory items.
6. The player is returned to the Surface.

The Diver must remain bypassable, distractible, and defeatable. Its death must never hard-lock or disable the gate.

## 3. Authoritative current values

| Property | Current value | Source |
|---|---:|---|
| Enemy ID | `senior_diver` | `data/enemies/senior_diver.tres` |
| Species ID | `senior_diver` | `.tres`, scene, support node |
| Tags | `gatekeeper` | `.tres`, `EnemySupport` |
| Layer | `1` | `.tres` |
| Max health | `250` | `.tres`, `EnemySupport` |
| Movement speed | `42 px/s` | `.gd`, `.tres` |
| Gravity | `900 px/s²` | `senior_diver.gd` |
| Restricted radius | `120 px` | `senior_diver.gd` |
| Sight range | `240 px` | `senior_diver.tscn` → `SightSensor.normal_range` |
| Grab range | `26 px` | `senior_diver.gd` |
| Grab telegraph | `0.25 s` | `senior_diver.gd` |
| Time without sight before return | `3 s` | `senior_diver.gd` |
| Trespass knockback | `180` horizontal base, with upward component | `senior_diver.gd` |
| Grab lock duration | `1 s` | `_grab()` |
| Required authorization | `GameSession.whistle_tier == &"blue"` | `senior_diver.gd` |
| Gatekeeper tag | `gatekeeper` | `.tres`, scene |

All distance, timing, movement, knockback, health, and damage-related values should remain tunable through the existing enemy/scene data pattern.

## 4. Progression versus physical inventory

These are deliberately separate systems:

| Concept | Meaning | Used for gate authorization? |
|---|---|---|
| Blue Whistle rank | Earned progression state | Yes |
| Physical Blue Whistle | Stealable/drop-able inventory item | No |
| Map-origin item | An item found during the current map/run | No authorization role; eligible for confiscation |
| Starting item | Player’s initial inventory | Never confiscated |
| Purchased item | Item obtained through the shop/economy | Never confiscated |
| Progression item | Persistent unlock/progression object | Never confiscated |

The authorization check must use progression data only:

```gdscript
var is_authorized := GameSession.whistle_tier == &"blue"
```

Do not replace this with an inventory lookup such as “player currently carries Blue Whistle.”

This is important because the intended player experience allows a player to earn authorization, lose the physical whistle, and still pass the Diver.

## 5. State machine

The current `IDLE`, `MOVE`, and `ATTACK` states can remain, but the implementation needs explicit guard/recovery state so the grab coroutine cannot be re-entered.

Recommended state model:

```text
POST / IDLE
  ├─ authorized player → remain non-hostile
  ├─ unauthorized player seen in restricted zone → KNOCKBACK + CHASE
  └─ no active threat → remain or return to authored post

CHASE
  ├─ sight retained and unauthorized player in response range → pursue
  ├─ player reaches grab range → GRAB_TELEGRAPH
  ├─ sight lost → LOST_TARGET timer
  └─ authorized / distracted / defeated → abandon hostility

GRAB_TELEGRAPH
  ├─ 0.25 s expires → GRAB_RESOLUTION
  ├─ distraction or bypass event → cancel
  └─ target invalid/dead/no longer eligible → cancel

GRAB_RESOLUTION
  ├─ lock target for 1 s
  ├─ confiscate map-origin items
  ├─ transition player to Surface
  └─ reset Diver to POST

LOST_TARGET
  ├─ sight restored before 3 s → CHASE
  └─ 3 s without sight → return to authored post
```

If the project keeps the existing enum names, add a separate `_grab_in_progress` boolean or a dedicated `GRAB` state. The Diver must not stay in a state that causes `_grab()` to be called every frame.

## 6. Authored post and restricted zone

At `_ready()`:

- Capture the Diver’s authored post as `_origin`.
- Keep the post separate from the restricted-zone boundary.
- Use the post as the return destination after three seconds without sight.
- Use the post as the recovery position after save/restore and out-of-bounds handling.

The restricted zone is an authored gameplay volume/radius around the gatekeeper’s protected area. The radius is currently `120 px`, but the system should allow the level designer to tune it.

The adjacent route must remain usable even when the Diver is dead, distracted, or away from post. Do not implement the gate as a collision wall that only disappears when the Diver dies.

## 7. Detection and trespass response

The `SightSensor` currently has a `240 px` normal range. A player should only trigger hostility when all of the following are true:

- The target is a valid `PlayerController`.
- The Diver has current sight of the target.
- The player is inside the restricted radius.
- `GameSession.whistle_tier` is not `&"blue"`.

On the first transition into the unauthorized restricted state:

- Apply the trespass knockback once.
- Set `_was_restricted = true` to prevent repeated knockback every frame.
- Begin chase behavior.

The current knockback direction is from the Diver toward the player, applied to the player, with an upward component:

```gdscript
var away := global_position.direction_to(_target.global_position)
_target.apply_force(Vector2(away.x * trespass_knockback, -trespass_knockback * 0.35))
```

Keep this as a one-time warning response unless playtesting shows the player can repeatedly re-enter without readable feedback. If repeated re-entry is needed, use a cooldown rather than frame-based repeated knockback.

## 8. Chase and loss of sight

While the Diver has sight of an unauthorized player in the restricted zone:

- Move toward the player at `42 px/s` times the support movement multiplier.
- Continue normal floor gravity.
- Update facing from horizontal movement.
- Check grab range continuously.

When the sight sensor reports `target_lost`:

- Preserve the last target reference only if it remains valid.
- Start a `3 s` lost-sight timer.
- Continue searching/chasing only according to the project’s intended short-memory behavior.
- If sight is regained before the timer expires, resume chase.
- After `3 s` without sight, clear the target and return to `_origin`.

Hushcap should be able to break sight and create a bypass window. The Diver should not retain permanent omniscience through Hushcap.

Distraction sources such as Rattlepod, Lantern Crystal, or Whistle should be able to pull the Diver away according to the project’s sound/distraction rules. Do not hard-code these item names into the Diver if the sound system already exposes priority/source semantics.

## 9. Grab telegraph and resolution

When an unauthorized target is within `26 px`:

- Enter `GRAB_TELEGRAPH`.
- Stop horizontal movement.
- Call `target.warn_attack(self, 0.25)`.
- Play the existing attack/warning presentation used by the project.
- Capture the target reference for the pending grab.

After `0.25 s`, resolve the grab only if:

- The target is still a valid player.
- The Diver is not dead.
- The grab was not canceled by a distraction, bypass, or state reset.

On success:

1. Lock the player with `senior_diver_grab`.
2. Confiscate map-origin items only.
3. Wait exactly `1 s` while the player remains locked.
4. Unlock the player even if the Diver is removed or the world transition fails.
5. Request the Surface transition, currently `surface` / `west`.
6. Reset the Diver to post/idle state.

The player lock must be released in a cleanup-safe path. A failed transition, freed target, or interrupted coroutine must not leave the player permanently locked.

### Required coroutine guard

The current code calls `_grab()` whenever `state == State.ATTACK` and `_timer <= 0.0`. Because `_grab()` contains an `await`, `_physics_process()` can call `_grab()` again on later frames while the first grab is still waiting.

Fix this with one of:

```gdscript
var _grab_in_progress := false

func _grab() -> void:
	if _grab_in_progress: return
	_grab_in_progress = true
	state = State.IDLE
	# capture target locally, then perform one resolution
	...
	_grab_in_progress = false
```

Prefer a dedicated `GRAB_RESOLUTION` state plus a `finally`-style cleanup helper so unlock and reset happen exactly once.

## 10. Inventory confiscation

The confiscation operation must use item provenance, not item names or current item category guesses.

Eligible:

- Items whose origin is `map` / map-found / current-run map acquisition, according to the project’s canonical provenance field.

Ineligible:

- Starting items.
- Purchased items.
- Progression items.
- Any other item whose origin is not map-found.
- The physical Blue Whistle if it is not map-origin, even though Blue rank itself is progression state.

Use the existing `PlayerController.confiscate_map_items()` API if it is already the canonical provenance-aware implementation. Do not reimplement item filtering inside `SeniorDiver`.

The confiscated items should be routed to the intended recovery destination, represented by the scene’s `LostItemReturn` marker and/or the existing inventory recovery system. The current scene registers this marker in the `lost_item_return_marker` group, but the current Diver script does not otherwise reference it; connect it to the canonical lost-item return flow or document why another system owns the destination.

## 11. Surface return

The current implementation requests:

```gdscript
world.request_layer_transition(&"surface", &"west")
```

Preserve this destination unless level design changes it. The teleport should be a world transition, not a direct `global_position` assignment inside the Diver.

The transition must be safe if:

- The player is already transitioning.
- The Diver is killed during the one-second lock.
- The target is freed.
- The world/run node is temporarily unavailable.

At minimum, release the player lock before or during the transition cleanup path so the player cannot be stranded in a locked state.

## 12. Distraction, bypass, and defeat

### Distraction

Rattlepod, Lantern Crystal, and Whistle events should be able to distract the Diver through the existing sound/event system. A distraction should:

- Break or redirect pursuit according to sound priority.
- Cancel a pending grab telegraph if the Diver’s attention is successfully pulled away.
- Clear or suspend the current player target.
- Allow the player to pass through the restricted area during the response window.

Do not make the Diver immune to its own systemic sound ecosystem.

### Bypass

Hushcap can break sight. The player should be able to use it to cross or reposition without triggering permanent pursuit. The Diver may reacquire the player if sight is restored before the `3 s` timer expires.

### Defeat

The Diver uses the generic `EnemySupport` damage path. On death:

- The gate remains usable.
- Any active chase/telegraph is canceled.
- Any pending player lock is cleaned up.
- The Diver does not respawn as an invisible blocker unless the encounter system explicitly requests it.

The `gatekeeper` tag also makes the Diver eligible for `Driftseed`; preserve that generic interaction.

## 13. Interaction prompt

The existing interaction prompt is:

```text
Talk to Senior Diver
```

Interaction feedback should remain non-hostile when the player has Blue rank:

```text
Blue rank confirmed.
```

Without Blue rank, the current feedback is:

```text
The diver warns you not to pass.
```

Interaction should not consume or require the physical Blue Whistle.

## 14. Implementation risks to resolve

### Current grab re-entry

As described above, `_grab()` needs a one-shot guard or dedicated state because it awaits for one second.

### Current return marker is unused

`LostItemReturn` is placed at `(-40, 0)` and added to the `lost_item_return_marker` group, but the script only calls `confiscate_map_items()` and does not use the marker directly. Verify whether `PlayerController` or inventory code consumes the group. If not, wire the confiscated items to the marker through the canonical item-return system.

### Target validity during await

Capture the target in a local variable before awaiting. Do not rely on `_target` remaining unchanged during the lock interval.

### Rank check centralization

Keep the Blue-rank authorization check in a small helper, for example:

```gdscript
func _is_authorized(player: PlayerController) -> bool:
	return GameSession.whistle_tier == &"blue"
```

This prevents one path from checking progression rank while another accidentally checks physical inventory.

## 15. Acceptance tests

### Authorization

- [ ] A player with Blue rank can enter the restricted zone without knockback, chase, or grab.
- [ ] Blue rank still authorizes passage when the physical Blue Whistle is missing.
- [ ] The physical whistle alone does not authorize passage if progression rank is not Blue.
- [ ] Talking to the Diver gives the correct rank-dependent feedback.

### Trespass and pursuit

- [ ] An unauthorized player entering the restricted radius receives one readable knockback warning.
- [ ] The Diver chases while it retains sight.
- [ ] The Diver does not repeatedly knock the player back every physics frame.
- [ ] Hushcap can break sight.
- [ ] Three seconds without restored sight causes the Diver to return to its authored post.
- [ ] The Diver can reacquire the player if sight returns before the timer expires.

### Grab

- [ ] The Diver telegraphs the close-range grab for `0.25 s`.
- [ ] The player is locked for exactly `1 s` on a successful grab.
- [ ] The grab cannot resolve more than once.
- [ ] Losing sight before the grab resolves follows the intended cancellation rule and cannot cause duplicate grabs.
- [ ] A successful grab requests the Surface / west transition.
- [ ] The player is never left permanently locked if the Diver dies or the transition fails.

### Inventory provenance

- [ ] Map-origin items are confiscated.
- [ ] Starting items are retained.
- [ ] Purchased items are retained.
- [ ] Progression items are retained.
- [ ] Non-map-origin items are retained regardless of their names.
- [ ] Confiscated items use the canonical lost-item return destination.

### Systemic counterplay

- [ ] Rattlepod can distract or redirect the Diver.
- [ ] Lantern Crystal can distract or redirect the Diver.
- [ ] Whistle events can distract or redirect the Diver.
- [ ] A successful distraction cancels a pending grab telegraph.
- [ ] Driftseed can affect the Diver through the `gatekeeper` tag.
- [ ] The player can bypass the guard using sight-breaking/distraction systems.
- [ ] Defeating the Diver never makes the route permanently unusable.

### Recovery and persistence

- [ ] Save/restore returns the Diver to its authored post without retaining a stale grab state.
- [ ] Out-of-bounds recovery resets position, target, timers, and hostility safely.
- [ ] Death clears any pending pursuit, telegraph, lock, or transition callback owned by the Diver.

## 16. Files and ownership

| File | Responsibility |
|---|---|
| `game/enemies/layer1/senior_diver.gd` | Gate authorization check, trespass response, chase/lost-sight state, grab sequence, generic damage/status hooks |
| `game/enemies/layer1/senior_diver.tscn` | Collision, sight range, authored return marker, interaction placement |
| `data/enemies/senior_diver.tres` | Enemy ID, `gatekeeper` tag, health, movement speed, layer |
| Player/inventory system | Canonical item provenance and map-origin confiscation |
| Progression/session system | Blue Whistle rank; must remain independent of physical inventory |
| Sound/distraction system | Rattlepod, Lantern Crystal, and Whistle event handling |
| World transition system | Surface / west return |

Do not put inventory-origin classification or Blue-rank persistence logic inside the Diver beyond calling their canonical APIs.

## 17. Source references

This specification was prepared from the attached files:

- `senior_diver.gd` — file citation: `file_00000000319081faa616c4411fb7206d`
- `senior_diver.tscn` — file citation: `file_00000000b14c81fa8498468b51e6540c`
- `senior_diver.tres` — file citation: `file_00000000442c81faa1bd0e1695aa8980`

Related implementation paths named in the design brief:

- `game/enemies/layer1/senior_diver.gd`
- `data/enemies/senior_diver.tres`
