# Player Foundation Clarification Questions

> **Status — 12 August 2026:** Closed. A1–H4 and the follow-up decisions are answered. The resulting rules are transferred into the source-of-truth documents; this file remains as decision history.

This document records the decisions still needed for the player, Multitool swing, cursor interaction, camera, movement, weight, throwing, detection, and rope systems. It is based on the current `feature/player` branch, `player mechanics note`, `player movement notes`, and the existing foundation documents.

Priorities:

- **BLOCKER** — changes system ownership, interfaces, saved state, controls, or required art. Answer before implementation planning is finalized.
- **BEFORE IMPLEMENTATION** — a safe recommendation exists, but the intended player experience should be confirmed before programming.
- **LATER** — does not block the first foundation implementation, but must be settled before final content or balance work.

## Decisions already understood

These points are already established and are not questions unless the new answers explicitly replace them:

- The active hotbar item's left click is its `primary_action`; right click is its configurable `secondary_action`; `E` is general interaction.
- Game-jam item actions use press input, not a general hold/release action contract.
- The Multitool is a normal inventory item. Its primary action is its swing/tool use; its currently undecided secondary action remains disabled rather than falling back to throw.
- Damage comes from an active attack hitbox, not cursor hitscan and not global contact damage.
- Ordinary damage does not cancel an item action, interaction, climbing, or Bandage healing. Death and scene changes still require safe cleanup.
- `Camera2D` native limits remain responsible for keeping the view inside the active route/layer.
- Item weight is an adjustable integer. An item held in the hotbar or prepared in the player's hand is still part of inventory weight and must not be counted twice.
- Sound travels by radius without terrain occlusion. Existing priority ordering is higher priority, then newer event, then nearer event.
- A placed Rope is approximately 160 px/5 m long, consumes one Rope, cannot be picked back up, persists for the living run, belongs to the layer runtime root, and may cross a seamless section boundary.
- Active attack frames, temporary projectiles, and other transient action state are not saved.
- Keyboard and mouse are the game-jam input target; controller support remains outside scope.

## Findings from the current branch

- `feature/player` is based on an older world-generation commit and does not contain the later world-authoring work.
- The current attack prototype uses a separate `J` action, hardcoded timers, a player-owned `SwordHitbox`, and a collision node with no shape assigned. It bypasses the existing item action route and can begin before inventory/control-lock checks.
- The airborne animation currently chooses jump/fall using horizontal velocity instead of vertical velocity.
- The current attack starts and stops damage after fixed time delays, so animation-speed changes can desynchronize the visible swing and damaging frames.
- The new player animation sheets are useful reference assets, but their 128 px cells contain a much smaller character drawing and their final item/body separation is not documented.
- `.godot/` was committed after its ignore rule was commented out. The same branch also removed the 16×16 size fields from the graybox TileSet.
- The existing foundation smoke test passes, but it does not exercise the new attack, hitbox, movement animation, cursor interaction, detection, or rope behavior.

---

# A. Branch and repository preparation

## A1 — Baseline before eventual player programming — BLOCKER

Should the latest `feature/world-generation` work be merged into `feature/player` before any player code is implemented?

The player branch split before later world-generation, persistence, section, placer, and thrown-item fixes. Building on the older state would either lose those fixes or force the player work to be reconciled twice.

**Recommendation:** merge the latest world-generation branch into the published player branch before programming. Do not rebase the shared branch. Resolve meaningful source conflicts deliberately and discard generated-cache conflicts.

**Answer:** yes, the world generation branch should be merged into player, make the player branch to be the most up to date

## A2 — Generated Godot files in Git — BLOCKER

May the eventual integration remove the tracked `.godot/` directory and restore `.godot/` as a real ignore rule?

These files contain machine-specific editor state, imported cache data, shaders, and generated metadata. Keeping them creates large conflicts between teammates without preserving source assets.

**Recommendation:** remove `.godot/` from Git and correctly ignore it. Keep source assets and their adjacent `.import` descriptions only where the project already intentionally tracks them.

**Answer:** yes that was a mistake in my part

## A3 — Graybox TileSet regression — BLOCKER

Should the removed `texture_region_size = Vector2i(16, 16)` and `tile_size = Vector2i(16, 16)` settings be restored during integration?

The removal is unrelated to the requested player work and can prevent or corrupt map painting.

**Recommendation:** restore both 16×16 settings unless the map team deliberately migrated the entire TileSet to another size.

**Answer:** that was probably an accidental removal

## A4 — Status of the current attack prototype — BLOCKER

May the current attack code be treated as a visual/prototyping reference rather than an interface that future work must preserve?

Keeping its hardcoded input, timers, and sword-specific ownership would conflict with the established item behavior system and make a second swing item require more player-specific code.

**Recommendation:** preserve useful animation assets and visual timing as reference, but replace the attack code with the smallest item-owned swing implementation that reuses the existing item controller and combat contracts.

**Answer:** follow the recommendation

---

# B. Multitool swing and reusable melee behavior

## B1 — Attack direction supported by the first art set — BLOCKER

Should the first Multitool swing only face left/right, aim in four directions, or rotate freely toward the cursor?

This determines the required animations, weapon pivot, collision transforms, and whether an attack can reach above or below the player. The current art appears suitable for a side-facing swing.

**Recommendation:** use left/right attacks for the first implementation. The cursor chooses the facing side, while future items may provide other swing profiles if final art requires them.

**Answer:** i have just realised part way into answering this section that what i meant by swing is actually more of a thrust. since we're limited on time, we do not have a swing animation, instead the attack with multitool would be more like a poke towards the cursor from player's item holding pivot point, so the direction is supported to be everywhere the player can aim their mouse, the size of the hitbox is based on the item visual size. like this: player holds the multitool in hand, when cursor clicks primary use to a direction, the sprite appears facing to that direction from the player's item pivot point

## B2 — Body and weapon artwork separation — BLOCKER

Will the final Multitool swing be delivered as:

1. a player animation with the Multitool and swing arc already drawn into every frame,
2. a player body animation plus a separate Multitool sprite, or
3. a static player body plus a separately animated/rotated Multitool sprite?

A combined sheet is fast for one item but requires new player sheets for every future swing item. A separate item sprite is more reusable and makes “the weapon sprite overlaps the enemy” unambiguous.

**Recommendation:** use the existing body animation and a separate weapon sprite attached to a per-frame hand/pivot position. Do not build skeletal animation or a general equipment-rendering framework for the jam.

**Answer:** follow the recommendation

## B3 — Meaning of literal weapon-sprite overlap — BLOCKER

Does “damage when the weapon sprite actually hits the enemy hitbox” require pixel-perfect collision, or should an authored collision shape closely follow the visible weapon during active frames?

Godot physics operates on collision shapes, not opaque sprite pixels. Pixel-perfect collision would be expensive, fragile, and difficult for artists to maintain.

**Recommendation:** use a small authored `Shape2D` that follows the visible weapon closely enough to feel honest. The shape is enabled only during explicitly marked active animation frames.

**Answer:** follow the recommendation

## B4 — Attack timing source — BLOCKER

Should the damaging window be authored by animation frame events, or configured as seconds from the start of the attack?

Second-based timers can drift away from the visible sprite when animation FPS or frame count changes.

**Recommendation:** start and stop the hitbox from animation method tracks or frame markers. Keep damage, force, shape, and allowed targets in the item's swing configuration.

**Answer:** follow the recommendation

## B5 — Movement during a swing — BEFORE IMPLEMENTATION

Should the player stop, move at reduced speed, or retain normal horizontal movement while swinging?

Stopping gives the attack commitment but can make the weak utility tool feel sluggish. Full movement is responsive but makes spacing less important.

**Recommendation:** allow reduced horizontal movement during wind-up and recovery; do not forcibly set velocity to zero at the start or end of the animation.

**Answer:** follow the recommendation

## B6 — Airborne Multitool use — BEFORE IMPLEMENTATION

Can the player swing while jumping or falling?

Disallowing it simplifies animation but prevents breaking or attacking targets beside a vertical route. Allowing it must not reset vertical velocity or grant extra airtime.

**Recommendation:** allow one normal swing in the air without stopping gravity or vertical movement.

**Answer:** follow the recommendation

## B7 — Facing during the attack — BEFORE IMPLEMENTATION

Once a swing begins, may moving the cursor or changing movement direction flip the player and hitbox before recovery ends?

Changing side mid-swing can make the damaging area disagree with the startup animation.

**Recommendation:** lock attack facing when left click is pressed and release it when recovery finishes.

**Answer:** follow the recommendation

## B8 — Number of targets per swing — BLOCKER

Can one Multitool swing damage several overlapping targets, and can it hit the same target more than once?

An overlap hitbox is likely to observe the same body across several physics frames. Without a per-swing hit record it can apply accidental repeated damage.

**Recommendation:** allow multiple distinct targets, but each target can be affected only once per swing.

**Answer:** follow the recommendation

## B9 — Tool target, breakable, and enemy priority — BLOCKER

If one swing overlaps a special tool interaction, a breakable object, and an enemy, should it affect all of them or stop after the highest-priority target?

The existing documentation gives special tool interactions priority over breakables and damage targets, while physical overlap naturally permits several results.

**Recommendation:** a special tool interaction consumes that swing's effect; otherwise the hitbox may affect all overlapping breakables/enemies once. This preserves authored interactions without making ordinary combat single-target.

**Answer:** im assuming special tool here means an item with an effect for its primary, in that case the item primary use is the special effect, it does not have any swing mechanic as for now that is only for the multitool primary effect

## B10 — Repeated input, queueing, and combos — BEFORE IMPLEMENTATION

What should another left click do while a swing is already running: nothing, queue one next swing, or start a combo?

Queueing and combos add control state, cancellation rules, and additional art requirements.

**Recommendation:** ignore additional presses until recovery finishes. Add buffering or combos only when a final item explicitly needs them.

**Answer:**  follow the recommendation

## B11 — Action cancellation and cleanup — BLOCKER

Which events cancel an active swing: opening inventory, dialogue/control lock, beginning a rope climb, death, or leaving the scene?

The earlier decision says ordinary damage does not cancel an item action. Death and scene replacement still cannot leave an active hitbox behind.

**Recommendation:** ordinary damage does not cancel the swing. Death, scene transition, and loss of the active item cancel it immediately. Inventory/dialogue block new attacks but allow an already-started swing to finish. Starting a climb waits until recovery ends.

**Answer:** follow the recommendation

## B12 — Final animation delivery contract — BLOCKER

What will the artists provide for each swing animation?

Please specify the frame-cell size, frame count, playback FPS, loop setting, left/right handling, body pivot, weapon pivot or socket positions, active hit frames, and whether the impact arc is part of the body sheet, weapon sheet, or separate VFX.

**Recommendation:** agree on one short handoff table before final art is imported. The game should not infer damaging frames from filenames or opaque pixels.

**Answer:** we do not have the time for that, instead the tool sprite will kind of teleportto the direction cursor is facing

---

# C. Cursor interaction and camera

## C1 — Choosing between several interactables — BLOCKER

When several valid objects are inside the cursor area, should the game choose the closest object to the cursor, the highest `interaction_priority`, or apply both rules?

Pure distance can make small pickups steal focus from a shop/gate. Pure priority can select an object visibly farther from the cursor.

**Recommendation:** filter by player reach first, then choose highest `interaction_priority`, then shortest cursor distance as the tie-breaker.

**Answer:** follow the recommendation

## C2 — Interaction through terrain — BLOCKER

Can the player interact with an object inside range when a wall or solid floor lies between the player and that object?

Allowing it can open gates, shops, or pickups through authored barriers.

**Recommendation:** require an unobstructed physics line from the player to the target, while allowing each special interactable to opt out only if a real design requires it.

**Answer:** follow the recommendation

## C3 — Cursor outside interaction reach — BEFORE IMPLEMENTATION

If the cursor points beyond the player's interaction distance, should the query clamp to the edge of the reachable area or return no target?

Clamping can select an object that the cursor is not visibly near.

**Recommendation:** return no target and no interaction prompt until the cursor is both near an object and within player reach.

**Answer:** it should clamp to the reachable area

## C4 — Initial interaction tuning — LATER

What starting values should be used for maximum player-to-target distance and cursor selection radius?

Both will remain Inspector-adjustable, but initial values are needed for consistent map and UI testing.

**Recommendation:** start with 72 px maximum reach and a 16 px cursor radius, then tune after one map playtest.

**Answer:** follow the recommendation

## C5 — Target feedback — BEFORE IMPLEMENTATION

Should a valid cursor target only change the interaction prompt, or also receive an outline/highlight?

A highlight is clearer but needs an art-compatible shader or alternate sprite treatment.

**Recommendation:** use the existing prompt for the foundation. Add highlighting only when the art team chooses a consistent visual treatment.

**Answer:** use existing prompt for now, but a simple glow to the highlited item sprite could work

## C6 — Intended camera calculation — BLOCKER

The current camera already converts screen-space cursor position into a bounded offset from the player. Is the requested change specifically to use the world-space vector from the player to the cursor, clamped to a maximum distance?

This produces different behavior when the player is not centered because of world bounds and more directly follows where the cursor points.

**Recommendation:** target `player position + clamped(player-to-world-cursor vector) + base offset`, smooth toward it, and continue applying native world bounds.

**Answer:**` follow the recommendation`

## C7 — Camera limit shape and starting values — LATER

Should the cursor offset be limited by one circular distance or separate horizontal/vertical distances?

A separate vertical limit prevents showing too much empty vertical space while retaining useful horizontal look-ahead.

**Recommendation:** keep an elliptical limit with the current approximate 56 px horizontal and 28 px vertical offsets, plus the existing base vertical offset and smoothing.

**Answer:** this should be easily adjustable

## C8 — Camera while UI owns the cursor — BEFORE IMPLEMENTATION

What should the camera do while inventory, pause, or another mouse-driven UI is open: keep following the cursor, freeze at its previous offset, or ease back to the player?

Following UI clicks can move the world view behind an overlay and feel distracting.

**Recommendation:** ease back to the base player offset while inventory/pause owns the cursor; resume cursor look after it closes.

**Answer:**  follow the recommendation, but do a slight adjustable zoom into the player when it happens

## C9 — Meaning of “make a backup” — BLOCKER

Is a clean Git commit/history of the current camera implementation sufficient, or must the project contain an alternate runtime camera mode that can be switched back on?

Keeping two implementations in the game adds testing and maintenance for behavior that may never be used.

**Recommendation:** use Git history as the backup. Do not retain duplicate camera code or a runtime toggle unless playtesting requires direct comparison.

**Answer:** follow the recommendation, also if needed you can just make a folder in this directory as a backup

---

# D. Movement and carried weight

## D1 — Preserve existing map reach — BLOCKER

Should a fully held, unencumbered jump preserve approximately the current 44 px rise and 75 px horizontal travel envelope?

The authored map guidance assumes a roughly 32 px maximum required rise and 48 px normal gap. Large movement changes could invalidate completed sections.

**Recommendation:** preserve or slightly improve the current full-jump envelope. Variable jump should only add shorter jumps, not reduce the unencumbered maximum.

**Answer:** this should be easily adjustable

## D2 — Variable jump behavior — BEFORE IMPLEMENTATION

How short should a quick tap be compared with a fully held jump?

The simplest responsive implementation applies the normal launch velocity, then cuts remaining upward velocity when jump is released.

**Recommendation:** retain full height while held and target roughly 40–50% of full height for a quick tap. Keep the release multiplier adjustable.

**Answer:** follow the recommendation

## D3 — Coyote time and jump buffer defaults — LATER

Are 0.12 seconds for coyote time and 0.12 seconds for jump buffering acceptable starting values?

These are tuning values and remain exported. Much longer windows can make the player appear to jump after visibly leaving or reaching a platform.

**Recommendation:** begin at 0.12 seconds for each and tune together in the graybox maps.

**Answer:** follow the recommendation

## D4 — Midair steering strength — BEFORE IMPLEMENTATION

Should midair movement approach normal ground speed with weaker acceleration, or should both top speed and acceleration be lower?

Keeping the same target speed but reducing acceleration gives useful correction without making airborne motion identical to walking.

**Recommendation:** keep the normal horizontal speed target, use separate lower air acceleration/deceleration values, and allow reversing direction in the air.

**Answer:** follow the recommendation

## D5 — Carry limit semantics — BLOCKER

Does “carry limit” mean the inventory refuses items above the limit, or that weight beyond a threshold increasingly penalizes movement while slot count remains the hard limit?

A hard weight rejection affects pickup, shops, drops, quest rewards, and full-inventory feedback. A soft threshold only affects movement.

**Recommendation:** use a soft encumbrance threshold; the existing slot limits remain the only hard capacity limit.

**Answer:** follow the recommendation

## D6 — Weight penalty curve and cap — BLOCKER

After the threshold is exceeded, should penalties scale linearly per weight unit, use weight bands, or immediately apply one fixed “heavy” state? What are the maximum permitted penalties?

Without caps, a heavily loaded player could become immobile, unable to jump, or accelerate downward indefinitely.

**Recommendation:** use a linear normalized load ratio with configurable minimum movement speed, minimum jump strength, and maximum gravity multiplier. Do not allow weight alone to make movement impossible.

**Answer:** no, weight can make the the player immobile if its heavy enough. but downward acceleration should be capped, make it adjustable

## D7 — Weight work included in this player stage — BLOCKER

Should this stage implement the complete inventory-weight calculation, or only establish the item `weight` field and the player modifier hook needed by throwing and later inventory work?

The request says not to focus on item weight until item implementation, but movement and weighted throwing need an agreed data source.

**Recommendation:** add one integer weight field and one inventory total calculation when coding begins, but postpone weight UI, final values, and elaborate capacity rules. The player reads the total through the inventory rather than duplicating item data.

**Answer:** follow the recommendation

## D8 — Which movement properties weight changes — BEFORE IMPLEMENTATION

Should weight affect only maximum speed, maximum jump height, and falling gravity as requested, or also ground acceleration, air steering, and knockback?

Changing every movement value makes tuning difficult and can make a heavy player feel unresponsive instead of deliberately burdened.

**Recommendation:** initially modify maximum run speed, jump launch velocity, and downward gravity only. Leave acceleration, steering, and knockback unchanged.

**Answer:** follow the recommendation

## D9 — Weight and fall damage — BLOCKER

Should the increased falling speed caused by weight also increase fall damage?

The current fall-damage system uses impact speed, so this will happen automatically unless weight-derived velocity is treated separately.

**Recommendation:** allow heavy loads to increase fall-damage risk, but retain the existing threshold and damage cap so a normal weighted jump cannot damage the player.

**Answer:** when testing previously the fall damage system feels unresponsive, we'll get back to this later after playtest

---

# E. Throwing refinement

## E1 — Comparison item — BEFORE IMPLEMENTATION

Should the temporary comparison item be lighter than the Throwable Rock, heavier than it, or should both a light and heavy test object be added?

One contrast item is enough to validate the formula without creating unnecessary content.

**Recommendation:** add one clearly heavy temporary test object. Use the existing rock as the light/normal baseline.

**Answer:** follow the recommendation

## E2 — Access to the comparison item — BEFORE IMPLEMENTATION

How should testers obtain the temporary comparison item: starting inventory, a debug-only pickup in the test world, or a normal loot definition?

Putting temporary content into normal generation can accidentally make it part of the designed item economy.

**Recommendation:** expose it through a clearly marked debug/test pickup or debug grant, not normal loot tables.

**Answer:** follow the recommendation, make sure its accessible through the debug menu

## E3 — When the dotted trajectory appears — BLOCKER

Because item actions are currently press-only, should the short dotted arc always appear while a throwable item is selected, appear only while a modifier key is held, or require changing secondary action to hold-and-release?

Changing right click to hold-and-release would expand the action contract for every item and prepared artifact.

**Recommendation:** show the short trajectory whenever a throwable/prepared item is active and the inventory is closed. Right click remains a single press to throw.

**Answer:** show the short trajectory whenever a held item can be thrown

## E4 — Trajectory collision prediction — BEFORE IMPLEMENTATION

Should trajectory dots stop at the first predicted terrain collision, and should they predict collision with enemies/items as well?

Predicting every moving body can make the preview flicker and costs more queries.

**Recommendation:** use the same launch velocity and gravity as the real item, stop at the first static terrain collision, and leave dynamic-target collision unpredicted.

**Answer:** it shouldn't even care about terrain collision, the trajectory is only 1.5 player height in length, this should be adjustable in the settings, but its just a visual guide that does not account terrain

## E5 — Cursor distance and throw power — BLOCKER

Should the existing rule—near cursor gives a short throw and distant cursor gives a stronger throw—remain after weight is added?

This rule provides analog strength without adding a hold input, but it must combine predictably with item weight.

**Recommendation:** keep cursor-distance strength. Apply configurable throw power first, then reduce launch speed by a simple weight curve such as dividing by the square root of weight, with safe minimum and maximum speeds.

**Answer:** follow the recommendation, should be adjustable

## E6 — Weight versus physical mass — BLOCKER

Should one item `weight` value control inventory burden, throw distance, impact force, and rigid-body mass, or may an item have separate carry weight and impact mass?

One value is easier for designers. Separate values support unusual artifacts but add fields and tuning ambiguity.

**Recommendation:** use one integer `weight` for the jam. Keep item-specific base throw power and impact behavior separate only where an actual item requires it.

**Answer:**  follow the recommendation

## E7 — Throwing sound events — BLOCKER

Does “throwing priority 1” mean a sound at the player's release position, the item's impact position, or both?

Release noise identifies the thrower; impact noise supports distraction gameplay at the landing point. They are different events and may need different priorities/radii.

**Recommendation:** emit the priority-1 throw action at the player. Let each item's impact behavior optionally emit a separate impact sound from the landing position.

**Answer:** follow the recommendation

## E8 — Prepared/activated item preview — BEFORE IMPLEMENTATION

When an item must be activated before throwing, should the trajectory appear only after activation, and should its active state be visible in the preview?

Showing an arc before the item is prepared may imply that right click is immediately available when it is not.

**Recommendation:** show the trajectory for the actual item currently ready to be thrown, including its current instance state; do not create a separate simulated item state.

**Answer:** show the trajectory whenever a throwable item is in hand, as items will be throwable whether or not its activated

---

# F. Modular sight, sound, and target selection

## F1 — First implementation scope — BLOCKER

Should this stage build the reusable detection foundation and integrate it into the existing test amphibian, or only provide components for future enemies?

Components without one real integration can appear correct while their ownership, state transitions, and performance remain untested.

**Recommendation:** build the minimal reusable producer/listener data and prove it on the existing test amphibian. Do not build every future enemy or a universal AI framework.

**Answer:** follow the recommendation

## F2 — Detection ownership — BLOCKER

Is the intended ownership:

- any player/artifact/creature can be a detection-signal producer,
- an enemy owns its sight/sound listener settings,
- the enemy's existing AI decides what to do with accepted signals?

This keeps sensing reusable without moving the entire enemy state machine into a generic component.

**Recommendation:** use this separation. A producer describes its detectability and emits events; a listener filters candidates; the enemy retains patrol/investigate/chase decisions.

**Answer:** follow the recommendation

## F3 — Normal sight geometry — BLOCKER

Should normal sight use a forward cone with a terrain raycast to each candidate, or one narrow forward ray only?

A single ray is cheap but frequently misses a 32 px character unless perfectly aligned. A cone supplies a cheap candidate list, while one obstruction ray per candidate confirms line of sight.

**Recommendation:** use an adjustable forward cone/area as broad phase and a physics ray for obstruction. Scan at a reduced, staggered frequency rather than every physics frame.

**Answer:** follow the recommendation

## F4 — Aggravated sight coverage — BLOCKER

When already targeting a producer, does “always checks if the player is in line of sight” mean 360-degree sight inside an aggravated radius, or a wider/longer forward cone that still respects facing?

Full 360-degree reacquisition makes flanking impossible during the memory period; a wider cone still allows evasion.

**Recommendation:** use a larger forward cone plus a small 360-degree proximity radius. Keep all ranges and angles per enemy.

**Answer:** follow the recommendation

## F5 — Sight memory after obstruction — BLOCKER

During the adjustable 10-second lost-sight period, does the enemy know the producer's current position through walls, or only the last position where line of sight was valid?

Live tracking through walls makes obstruction irrelevant once an enemy has seen the target.

**Recommendation:** remember and pursue the last-known position. A new valid sight check refreshes both the position and timer.

**Answer:** follow the recommendation

## F6 — End of sight pursuit — BEFORE IMPLEMENTATION

If the enemy reaches the last-known position before the 10-second sight-memory timer ends, should it wait/search there, continue wandering nearby, or immediately return to normal?

The existing test enemy already supports investigate, wait, and return states.

**Recommendation:** wait/search at the last-known position for the remaining configured investigation time, then return to normal.

**Answer:** follow the recommendation

## F7 — Anti-detection effects — BLOCKER

How should an anti-sight or anti-sound item modify its producer: completely disable that channel, multiply its visibility/loudness, reduce emitted priority, or add a threshold bonus enemies must overcome?

The representation affects every artifact and enemy even if only one anti-detection item exists initially.

**Recommendation:** use per-channel multipliers on the producer. Zero means fully hidden from that channel; values between zero and one reduce effective range. Do not change event priority unless the item explicitly says it changes perceived importance.

**Answer:** currently no item implementation will be able to disable any detection, the sight blocker will make a deployable smoke that acts as an obstruction for visiom check, the sound item will create a hugher priority sound that can take over the enemy sound priority target

## F8 — Proximity detection — BLOCKER

At very close range, should an enemy directly detect a producer regardless of sight obstruction, distraction, and anti-sight effects?

An unconditional radius prevents standing inside an enemy unnoticed but can detect through thin walls.

**Recommendation:** proximity overrides distraction and partial concealment, but still requires no solid terrain between enemy and producer. Complete supernatural concealment can explicitly opt out.

**Answer:** follow the recommendation

## F9 — Visible player versus artifact distraction — BLOCKER

Can an artifact distract an enemy that currently has unobstructed sight of the player, or only an idle/investigating enemy or one that has lost sight?

Allowing ordinary distractions to override direct sight makes enemies easy to reset while standing in front of them.

**Recommendation:** direct sight or valid proximity to the current player target wins. Artifact signals can redirect idle/investigating enemies and enemies that have lost sight, unless a specific high-priority artifact states otherwise.

**Answer:** refer to my f7 answer

## F10 — “Harder to distract” configuration — BLOCKER

Should an enemy that is harder to distract require a minimum signal priority, reduce the effective priority of non-player signals, or completely ignore selected signal types?

These approaches create different designer controls and target-selection rules.

**Recommendation:** give the listener a configurable distraction threshold for non-current producers plus optional ignored sound types. Avoid a complicated universal scoring formula.

**Answer:** follow the recommendation, make it adjustable

## F11 — Sound priority versus hearing radius — BLOCKER

Are the listed action values—walk 1, jump 3, throw 1, whistle 10—priorities, while every sound separately defines a world-space hearing radius?

Priority chooses between sounds already heard; radius determines whether a listener hears an event at all. Combining them would make every high-priority event automatically travel farther.

**Recommendation:** keep `priority` and `radius` separate, matching the existing `SoundEvent` contract. Priorities have no global maximum.

**Answer:** follow the recommendation

## F12 — Meaning of listener upper priority bound — BLOCKER

What should happen when a sound's priority is above an enemy listener's configured upper bound?

Ignoring unusually important sounds is counterintuitive, but the request explicitly mentions adjustable lower and upper bounds.

**Recommendation:** use only a minimum heard priority; accept all higher values. If an upper value is needed for balance, treat it as a comparison cap rather than making stronger sounds inaudible.

**Answer:** follow the recommendation

## F13 — Repeated-sound escalation — BLOCKER

How many sounds from the same producer, within what time window, should turn investigation into direct targeting? Should different sound types share the same counter?

Without fixed rules, normal footsteps may immediately cause direct chase or rapid item sounds may never escalate.

**Recommendation:** start with three accepted sounds from the same producer within two seconds. Count all sound types together, reset after the window, and expose both values per enemy.

**Answer:** follow the recommendation

## F14 — Priority of an escalated sound target — BLOCKER

Should escalation use one global high priority, add a bonus to the triggering sound, or use a per-enemy value?

A global arbitrary maximum conflicts with the rule that sound priority has no maximum.

**Recommendation:** store “direct sound target” as a target mode above ordinary investigation rather than inventing a magic numeric maximum. Direct sight/proximity can still take precedence.

**Answer:** follow the recommendation

## F15 — Tracking a direct sound target — BLOCKER

After repeated sound escalates to direct targeting, may the enemy continuously follow the producer's current position through walls, or only update its target when another sound event arrives?

Continuous tracking through walls gives sound a stronger capability than the event actually supplied.

**Recommendation:** update location when a fresh sound is heard. Between events, pursue the last-known sound location; lose the direct target after the configured silence/out-of-range timeout.

**Answer:** follow the recommendation

## F16 — Sound timeout and completed investigation — BEFORE IMPLEMENTATION

If an enemy reaches the remembered sound location before the 10-second timeout, when is it considered “done checking” the sound?

The request allows either finishing the check or timing out, but the waiting behavior is not defined.

**Recommendation:** use an adjustable short wait/search duration at the location. Completion clears that ordinary sound target; the 10-second timeout is the safety limit for unreachable or stale targets.

**Answer:** follow the recommendation

## F17 — Walking sound cadence — BEFORE IMPLEMENTATION

Should walking emit sound on animation footsteps, at a fixed distance interval, or at a fixed time interval? Does crouching or slower movement exist in this build?

Physics-frame emission would flood listeners and instantly trigger repetition escalation.

**Recommendation:** emit one event per configured distance travelled while grounded, later synchronize it to animation footstep markers when final animation timing is stable. Do not add crouching unless separately requested.

**Answer:** follow the recommendation

## F18 — Jump sound timing — BEFORE IMPLEMENTATION

Does priority-3 jumping sound occur on takeoff, landing, or both? If both, should landing priority scale with impact speed?

Takeoff reveals the action source; landing supports heavy/fall interactions but can duplicate the same jump signal.

**Recommendation:** emit priority 3 at takeoff and a separate landing event whose radius/priority can scale within configured limits. Normal soft landings may use a lower priority.

**Answer:** follow the recommendation

## F19 — Detection update frequency — BLOCKER

Does “detect once every few frames” apply only to sight/proximity scanning, or should sound events also be delayed and polled?

The existing sound bus is already event-driven and does no repeated spatial scan when the world is quiet. Polling it would add latency and more state.

**Recommendation:** dispatch sound immediately. Scan sight/proximity around every 0.1 seconds and stagger enemies across frames so they do not all query physics together.

**Answer:** follow the recommendation, the detection should only happen when an enemy's detection is loaded in

## F20 — Initial sight and sound tuning — LATER

Should the first test amphibian use temporary designer defaults, or are exact normal/aggravated sight ranges, cone angles, hearing radius limits, and memory times already defined?

The architecture only needs adjustable fields; exact balance can follow the first integrated test.

**Recommendation:** use clearly documented temporary values and tune them in one graybox section instead of blocking the foundation on final enemy balance.

**Answer:** follow the recommendation

---

# G. Rope placement and climbing
IMPORTANT: this rope mechanic is a prototype, this is just exploring one implementation method. do not make it fully integrated

## G1 — Rope asset handoff — BLOCKER

Where is the completed Rope asset, and what files does it include?

Please provide or push the exact paths and specify pixel dimensions, whether the rope body tiles vertically, whether an anchor/knot is separate, the intended pivot, and whether there are player climbing animations. No Rope asset is present on the current `feature/player` branch.

**Recommendation:** provide one tileable vertical rope body and one optional top anchor. The programming foundation should not scale a finite illustration to every possible rope length.

**Answer:** i will provide all of the made assets later after i have given all of the answers

## G2 — Direct placement or placement mode — BLOCKER

Should one left click immediately place a Rope at the valid anchor nearest the cursor, or enter a placement preview that requires another confirmation?

A two-step mode conflicts with the current press-only item contract and needs cancellation/UI state.

**Recommendation:** direct placement on one press. Show a valid/invalid preview whenever Rope is selected so the player knows what the press will do.

**Answer:** follow the recommendation

## G3 — Valid anchor surfaces — BLOCKER

What exactly can receive a Rope anchor: the top edge of solid terrain, ceilings, side walls, one-way platforms, authored anchor nodes, or any world point?

“Anywhere” must still prevent floating ropes, placement inside terrain, and shortcuts outside the playable map.

**Recommendation:** allow the top surface of ordinary solid terrain and optional authored Rope anchor nodes within range. Reject midair, side-wall, ceiling, and out-of-bounds placement for the first version.

**Answer:** follow the recommendation, but allow side wall and ceiling placement if they're not inside of terrain

## G4 — Placement range and cursor behavior — BEFORE IMPLEMENTATION

How far from the player may a Rope anchor be placed, and should an out-of-range cursor clamp to a nearby valid surface?

Long-distance placement can bypass traversal challenges; clamping can place a costly permanent Rope somewhere unexpected.

**Recommendation:** use the same approximate 72 px reach as interaction and never clamp. Invalid or out-of-range placement consumes nothing and shows feedback.

**Answer:** follow the recommendation

## G5 — Rope length and intervening terrain — BLOCKER

Should the Rope end at the first solid surface below the anchor, pass through one-way platforms, or always extend the full 160 px even through terrain?

The visual, climbable area, and save data must all agree on the final length.

**Recommendation:** extend vertically up to 160 px and stop before the first solid terrain collision. Decide separately whether one-way platforms are intentionally ignored.

**Answer:** follow the recommendation

## G6 — Attaching to the Rope — BLOCKER

How does the player begin climbing: touch the Rope and press up/down, press `E`, or automatically attach on contact?

Automatic attachment can interrupt a fall unexpectedly. Requiring `E` adds an extra interaction before every climb.

**Recommendation:** while overlapping the Rope, pressing up or down attaches and begins climbing. Merely touching it does not change movement.

**Answer:** follow the recommendation

## G7 — Jump input conflict — BLOCKER

The documented jump key is Space, but some team setups may also map `W` to jump. While overlapping a Rope, should `W/S` always mean climb and Space mean jump/detach?

One input cannot reliably start a normal jump and climb in the same frame.

**Recommendation:** keep Space as jump. Use `W/S` or up/down for climbing while attached; Space jumps away from the Rope.

**Answer:** follow the recommendation, space when attached to the rope is detach and jump

## G8 — Positioning and exits — BEFORE IMPLEMENTATION

Should attaching snap the player horizontally to the Rope center? At the top and bottom, should movement automatically step onto nearby terrain or simply detach?

Without a small snap/ease, the player can visually climb beside the Rope. Automatic ledge movement can push the player into arbitrary terrain.

**Recommendation:** quickly ease the player's horizontal position to the Rope center, disable gravity while attached, and detach safely at either end. Add automatic top-out only if map playtesting proves it necessary.

**Answer:** follow the recommendation, player can press space to jump out of the rope

## G9 — Horizontal movement while climbing — BEFORE IMPLEMENTATION

Should left/right immediately detach, move the player slightly around the Rope while attached, or do nothing until Space is pressed?

Immediate detachment is responsive but can cause accidental falls during small corrections.

**Recommendation:** left/right plus a small threshold detaches in that direction; Space performs a clearer jump-away. Keep both tunable.

**Answer:** pressing left/right by itself wont release, but pressing a direction while jumping away will make the player jump that way

## G10 — Item actions while climbing — BLOCKER

Can the player swing, interact, or throw items while attached to a Rope?

Allowing item actions requires climbing-compatible facing, hand positions, and animation combinations that may not exist in the current art.

**Recommendation:** allow `E` interaction if a target is valid, but block primary/secondary item actions during the first climbing implementation. Revisit when climbing attack art exists.

**Answer:** allow interaction and primary/secondary actions, its fine even though we do not have the art asset as this is a jam

## G11 — Damage, force, and Rope attachment — BLOCKER

The existing rule says ordinary damage does not cancel climbing. What should knockback force do while the player remains attached?

Applying normal knockback would physically separate the player from the Rope even if climbing state remains active.

**Recommendation:** ordinary damage keeps the player attached and suppresses horizontal/vertical displacement from its force while climbing. Explicit launch/stun effects may request detachment; death always detaches.

**Answer:** ordinary damage doesnt do anything, but if an enemy does knockback of any kind, it knocks the player out of the rope

## G12 — Saving while attached — BLOCKER

If autosave or Quit occurs while the player is climbing, should Continue restore the exact climbing state, restore the position but unattached, or move the player to a nearby safe point?

Saving transient input/animation state is fragile, but restoring inside a Rope without attachment can cause a fall.

**Recommendation:** save the normal player position and Rope separately, but not climbing state. On load, place the player safely beside the Rope or at `last_safe_position` if the saved position is invalid.

**Answer:** follow the recommendation

## G13 — Rope behavior near world bounds — BLOCKER

Should placement be rejected when any part of the Rope leaves the playable layer bounds or creates a route around authored collision?

The existing world documentation explicitly requires Rope not to create an out-of-bounds shortcut.

**Recommendation:** validate the whole rope segment against active layer bounds and terrain before consuming the item.

**Answer:**  follow the recommendation

## G14 — Physics model — BLOCKER

Is the Rope intended to hang as a fixed vertical traversal object, or swing/bend with physics?

Physics rope requires joints, moving collision, save reconstruction, character constraints, and substantially more testing.

**Recommendation:** use a fixed, non-solid vertical `Area2D` with a repeated/tiled visual. Add physical swinging only if it becomes an explicit core mechanic.

**Answer:** follow the recommendation

---

# H. Debugging, performance, and acceptance

## H1 — Debug visualization — BEFORE IMPLEMENTATION

Should the existing debug toggle expose melee hitboxes, cursor interaction range, predicted trajectory, sight cone/rays, sound radii/events, and Rope placement validity?

These invisible systems will otherwise be difficult for an amateur programmer and level designers to tune.

**Recommendation:** add lightweight debug drawing behind the existing debug mode, disabled in normal play. Do not build a separate debug UI framework.

**Answer:** follow the recommendation, make it toggleable in debug menu

## H2 — Performance target — BEFORE IMPLEMENTATION

Is maintaining at least 60 FPS on the current VM during a representative section the acceptance target for the detection foundation?

The VM previously exposed large performance regressions, and the new design can create many physics queries if every enemy scans every frame.

**Recommendation:** require 60 FPS in the test scene and use staggered sight scans. Sound remains event-driven. Optimize further only if a measured representative scene misses the target.

**Answer:** follow the recommendation

## H3 — Required integrated test scene — BLOCKER

May one graybox test area include the player, a breakable, an enemy, the rock, the temporary comparison item, an obstruction, a noise source, and a Rope surface so all foundations can be checked together?

Unit-level contracts alone cannot verify movement feel, visible overlap, targeting, distraction, and traversal.

**Recommendation:** use one compact integrated test area plus the existing assertion smoke test. Do not introduce a new test framework.

**Answer:** follow the recommendation

## H4 — Minimum acceptance scenarios — BLOCKER

Are the following required before the player foundation is considered complete?

- Full and tapped jumps work; coyote time and jump buffer are observable without creating double jumps.
- Existing authored rise/gap guidance remains traversable while unencumbered.
- Multitool damage only occurs while the visible weapon shape overlaps a valid target during active frames.
- Cursor interaction never selects an unreachable or hidden target.
- Rock and comparison item produce visibly different but predictable trajectories.
- Equal-priority newer sounds replace older sounds; lower-priority sounds do not; repeated sounds escalate according to the chosen rule.
- Sight is blocked by terrain and loses its target after the configured memory period.
- A placed Rope consumes exactly one item, can be climbed, crosses a section seam safely, and returns at the same position after Continue.
- Opening inventory, death, scene transition, and load leave attack/climb controls in a neutral state.

**Recommendation:** accept this list as the minimum integrated contract, with exact feel values remaining tunable.

**Answer:** follow the recommendation

---

# I. Follow-up decisions

These decisions resolve contradictions found while reconciling the original answers.

## I1 — Multitool thrust motion

The Multitool has no attack sprite-sheet animation. On primary action, its separate sprite rotates toward the cursor, snaps from the held-item pivot to full extension, remains active for a short adjustable duration, then returns. The damaging shape is active only at extension.

## I2 — Multitool target resolution

One thrust resolves exactly one compatible target in this order:

1. special Multitool interaction;
2. breakable or harvestable target;
3. damage target.

The same target cannot receive the action more than once during one thrust.

## I3 — Sound distraction during direct sight

Each enemy may configure whether a high-priority sound can replace a target it currently sees. The default is that direct sight wins; ordinary sound redirects idle/investigating enemies or enemies that have lost sight.

## I4 — Rope prototype boundary

The first Rope implementation is an item-flow prototype: selection, placement preview, item consumption, placed visual, climbing, and controls. Save/restore, section-seam persistence, shops, and final integration are explicitly deferred even though they remain requirements for the final Rope system. This later decision overrides the Rope persistence item in H4 for the prototype.

## I5 — Rope direction from non-horizontal anchors

Rope may attach to a valid top surface, ceiling, or unobstructed side wall. The chosen point is always the top anchor and the fixed Rope always hangs vertically downward, regardless of surface orientation.

## I6 — Encumbrance curve

There is no movement penalty through the adjustable carry capacity. Between capacity and twice capacity, movement speed and jump strength decrease linearly to zero. Falling acceleration increases over the same range but stops at an adjustable cap.

## I7 — Delivered Rope art

The delivered Rope files are 16×16 px:

- `rope-item.png`: inventory/world coil;
- `rope-mid.png`: repeatable placed segment;
- `rope-end.png`: bottom cap.

Their `.aseprite` source files must be preserved. The source bitmaps stay at 16×16 with nearest filtering; the placed Rope is built by repeating/cropping the segment rather than stretching it.

---

# Result

- Decisions are transferred into `fondasi_teknis_godot.md`, `panduan_programming.md`, and the relevant item/world guidance.
- Follow-up decisions I1–I7 explicitly replace conflicting earlier recommendations.
- The programming order, minimal ownership contracts, tests, and delivered-asset mapping are documented.
- No gameplay code should be written until this documentation-only update is reviewed and a separate programming greenlight is given.
