# Layer 2 Enemies, Relics, Quest, and Remaining GDD — Clarification Questionnaire

> Purpose: lock the decisions required to implement the supplied Layer 2 enemy and relic designs without guessing.
>
> Deadline context: four development days remain. Answer **P0** first. For a recommended answer you accept, writing `follow recommendation` is enough.

## Source documents

This questionnaire was prepared from:

- `docs/layer_2_enemies_programmer_handoff.md`;
- `docs/layer_2_relics_programmer_specification.md`;
- the current Layer 1 runtime and implementation documents;
- `docs/pertanyaan_lanjutan_gdd.md`;
- unanswered sections of the earlier GDD/content questionnaire.

## Priority labels

- **P0 — CODING BLOCKER:** implementation would materially change depending on the answer.
- **P1 — INTEGRATION BLOCKER:** a safe placeholder can be built, but the complete interaction needs an answer.
- **P2 — TUNING/LATER:** keep adjustable; the answer is useful but should not stop the first implementation pass.
- **GDD — NON-BLOCKING:** story/presentation clarity. These questions must not delay Layer 2 code unless their answer changes gameplay.

## Decisions already treated as current

- Required Layer 2 concepts are Plate Umbrella, Lacerator, Resonance Core, Bolt Shock, Canopy Primate, Tremor Hound, Carrion Stalker, Bulwark Beast, and Sky Hunter Flock.
- Existing `ItemDefinition`, inventory, thrown-item, projectile, damage, force, status, sight, sound, persistence, world generation, and Inspector-tuning foundations should be reused.
- All enemies remain killable unless explicitly corrected below.
- Same-species damage is rejected; cross-species damage is allowed.
- Final art, audio, and manual numeric tuning are later passes. Placeholder presentation is acceptable now.
- No question below asks for repair of the already-known Layer 1 bugs. This document only prevents new Layer 2 ambiguity.

---

# A. Authority, roster, and four-day scope

## A1 — Authority of the new Layer 2 specifications — P0

**Question:** When the two new Layer 2 specifications conflict with the old roadmap, GDD, Layer 1 reference, or archived item documents, should the new specifications win unless this questionnaire explicitly changes them?

**Why this matters:** Several old documents describe different enemies, rewards, and Large Flyer behaviour. Implementation needs one authority order.

**Recommendation:** Yes. Use this order: answered questionnaire → new Layer 2 specifications → current GDD/implementation documents → archived references.

**Answer:** follow the recommendation

## A2 — Alarm Grazer contradiction — P0

**Question:** Is Alarm Grazer a required Layer 2 enemy, optional fauna, a removed concept, or an accidental leftover reference?

**Why this matters:** The relic specification describes Lacerator and Plate Umbrella interactions with Alarm Grazer, but the final enemy roster does not include it.

**Recommendation:** Remove Alarm Grazer from the four-day implementation and delete its interaction requirements from the final implementation documents.

**Answer:** alarm grazer is removed concept

## A3 — Glasswings scope — P0

**Question:** Confirm that Glasswings are excluded from required gameplay implementation. If time remains, are they visual-only ambient fauna with no health, combat, save state, or placer requirements?

**Why this matters:** “Optional fauna” can still expand into animation, spawning, saving, and interaction work if its boundary is unclear.

**Recommendation:** Exclude them entirely until every required enemy and relic has a runnable placeholder implementation.

**Answer:** follow the recommendation

## A4 — Layer 1 Large Flyer transfer — P0

**Question:** Should the surviving Large Layer 1 Flyer stop transferring into active Layer 2 gameplay because the Sky Hunter Flock now owns the Layer 2 big-enemy role?

**Why this matters:** Current code transfers the Flyer into Layer 2. The new enemy specification explicitly conflicts with this.

**Recommendation:** Disable the gameplay transfer. Do not add a scripted background appearance during the four-day scope.

**Answer:** layer 1 flyer will still be able to transfer into layer 2

## A5 — Required delivery roster — P0

**Question:** Must the first Layer 2 content pass include all four relics and all five enemy categories, or is there an approved cut order if time runs short?

**Why this matters:** “Add everything first” establishes the target but not the emergency fallback for the final day.

**Recommendation:** Required target: all nine concepts. Emergency cut order: optional polish → advanced coordination → Carrion circling sophistication → Glasswings. Do not cut Resonance Core, Bolt Shock, Bulwark, or the basic Sky Hunter encounter because they define progression and the final route.

**Answer:** follow the recommendation

## A6 — Stable names and IDs — P0

**Question:** Freeze these display names and technical IDs?

| Display name | Proposed stable ID |
| --- | --- |
| Plate Umbrella | `plate_umbrella` |
| Lacerator | `lacerator` |
| Resonance Core | `resonance_core` |
| Bolt Shock | `bolt_shock` |
| Canopy Primate | `canopy_primate` |
| Tremor Hound | `tremor_hound` |
| Carrion Stalker | `carrion_stalker` |
| Bulwark Beast | `bulwark_beast` |
| Sky Hunter | `sky_hunter` |
| Flock coordinator | `layer_2_sky_hunter_flock` |

**Why this matters:** Item/enemy IDs enter saves, placers, catalog lookup, tests, and quest state. Renaming them later requires migration work.

**Recommendation:** Freeze these IDs now. Display names may be changed later without changing IDs.

**Answer:** follow the recommendation

## A7 — “Implemented first” completion boundary — P0

**Question:** For this pass, does each concept need functional placeholder behaviour, Inspector tuning, save/load, debug spawning/granting, basic feedback, and smoke coverage, while final art/audio/balance may remain unfinished?

**Why this matters:** The team cannot use “scene opens” as the definition of complete, but four days cannot support full polish.

**Recommendation:** Yes. Require the functional integration boundary above; postpone final presentation assets and manual tuning.

**Answer:** follow the recommendation

## A8 — Provisional numeric values — P2

**Question:** May all unspecified health, damage, duration, radius, weight, value, ammunition, flock-size, and cooldown values begin from the recommendations in the supplied specs and remain exported for your tuning?

**Why this matters:** Asking for every number before coding would waste the remaining time.

**Recommendation:** Yes. Only behaviour-changing choices should block implementation; all balance numbers remain editable.

**Answer:** follow the recommendation

---

# B. Shared Layer 2 relic rules

## B1 — Mutable relic stacking — P0

**Question:** Should Plate Umbrella, Lacerator, and Bolt Shock always have `max_stack = 1` because stability, ammunition, and remaining uses belong to individual instances? Should Resonance Core also be one per slot because it is unique and heavy?

**Why this matters:** Stacking mutable instances can merge or duplicate state.

**Recommendation:** Set all four to maximum stack one.

**Answer:** follow the recommendation, but still make it adjustable

## B2 — Acquisition sources — P0

**Question:** Confirm the intended source for each relic: where does Plate Umbrella come from, where does Lacerator come from, where exactly is Resonance Core found, and is Bolt Shock obtainable only as the completed quest reward?

**Why this matters:** An implemented item cannot be playtested in a normal run without an acquisition path.

**Recommendation:** Place Umbrella and Lacerator through deterministic Layer 2 loot placers, allocate exactly one Resonance Core per run, and make Bolt Shock quest-only plus debug-grantable.

**Answer:** follow the recommendation, all of these item can only have 1 per game

## B3 — Weight and economy data — P1

**Question:** Should all four relics be sellable? What provisional weight and Surface/Layer 2 sale value should each use? Can the unique Resonance Core be sold before quest completion?

**Why this matters:** Selling the quest relic can make the quest impossible; weight is also a major gameplay property.

**Recommendation:** Keep all values editable. Make Umbrella and Lacerator sellable, Bolt Shock sellable only if empty or explicitly allowed, and Resonance Core unsellable until the quest is complete.

**Answer:** follow the recommendation, bolt shock is sellable

## B4 — Dropping, pits, and recovery — P0

**Question:** May each relic be dropped or thrown into a pit and lost? Which ones require guaranteed recovery or replacement?

**Why this matters:** Resonance Core and Bolt Shock are unique progression items, while current ordinary relics may be permanently lost.

**Recommendation:** Umbrella and Lacerator may be lost normally. Resonance Core and an awarded Bolt Shock should return to a protected quest-recovery marker or become replaceable if lost out of bounds.

**Answer:** follow the recommendation

## B5 — Theft and confiscation — P1

**Question:** Can Tongue Amphibians or any future Layer 2 thief steal these relics? Can the Senior Diver confiscate map-found Umbrella, Lacerator, or Resonance Core based on origin?

**Why this matters:** Current ownership rules allow real items to be stolen and map-origin items to be confiscated.

**Recommendation:** Ordinary relics follow normal theft/origin rules. Unique quest/reward items may be carried by enemies but must have protected recovery and must not be permanently confiscated.

**Answer:** all of them can be confiscated and stolen

## B6 — Secondary throw rule — P0

**Question:** Confirm that right click throws the physical relic itself for all four items when they are not in a special active state. Does throwing preserve stability/ammunition/uses?

**Why this matters:** Mutable state must follow the same physical item across inventory and world ownership.

**Recommendation:** Yes. Throw the same instance state. Throwing never reloads, repairs, or duplicates it.

**Answer:** none of these items can be thrown except for resonance core. their primary use is activate/reload, secondary use is shoot

## B7 — Save boundary for temporary combat state — P0

**Question:** On Save & Menu, should held/open states and active firing animations cancel safely while durable instance state persists? Should deployed Lacerator balls persist, while flying rods, active hitboxes, attack tokens, and short stuns clear?

**Why this matters:** Restoring midway through an attack can duplicate projectiles or leave controls/sensors disabled.

**Recommendation:** Persist item state and deployed real hazards; clear short combat actions/projectiles and restore actors into neutral recovery states.

**Answer:** follow the recommendation

## B8 — Discovery descriptions — P1

**Question:** Are all four relics discoverable through successful signature use? What counts as discovery: first successful block, first damaging Lacerator contact, first Core resonance, and first accepted Bolt Shock hit?

**Why this matters:** Current relic knowledge increments only after a successful signature effect.

**Recommendation:** Use those four signature events with discovery threshold one. Invalid activation or a missed attack reveals nothing.

**Answer:** they're counted by primary use action.

---

# C. Plate Umbrella

## C1 — Hold input versus press-only contract — P0

**Question:** Should Plate Umbrella use true hold/release input, or should primary press toggle it open/closed?

**Why this matters:** The new design requires holding and releasing primary, but the current item architecture and earlier decisions support press-only actions.

**Recommendation:** Use press-to-toggle for the jam build. It reuses the prepared-item pattern and avoids redesigning input lifecycle for one item.

**Answer:**  follow the recommendation, use press to toggle active or inactive. secondary use is the same as primary use

## C2 — Aim direction and rotation limit — P0

**Question:** Can an open Umbrella aim freely toward the cursor in all directions, or only flip left/right with a limited vertical angle?

**Why this matters:** Directional blocking, animation, collision rotation, climbing, and overhead attacks depend on this.

**Recommendation:** Allow cursor-facing 360-degree blocking with a configurable arc, but keep the player sprite facing left/right independently.

**Answer:** allow cursor facing 360 degrees, and player sprite follows left/right according to direction

## C3 — Exact blockable attacks — P0

**Question:** Mark each as `full block`, `damage reduction`, `force only`, or `not blockable`: Primate rock, Cave Spider projectile, Thorn needle, Lacerator ball, Bolt rod, Sky Hunter strike, Tremor Hound pounce, Carrion bite, Bulwark charge, and ordinary thrown items.

**Why this matters:** A shared block contract still needs authoritative per-attack responses.

**Recommendation:** Fully block small projectiles and their statuses from the front; reduce creature-contact damage while transferring force; only partially reduce Bulwark damage and always force-close.

**Answer:** follow the recommendation

## C4 — Damage and status resolution — P0

**Question:** When a projectile is successfully blocked, are its damage and statuses both prevented? If stability reaches zero from that hit, does that same hit still count as blocked?

**Why this matters:** Resolution order changes whether the final point of stability saves the player.

**Recommendation:** If stability was above zero before impact, resolve that hit as blocked, then subtract stability and force-close. Block associated statuses only when the hit was blocked.

**Answer:** follow the recommendation

## C5 — Force transfer — P1

**Question:** Should blocked force always move the player, including knocking them off Rope or ledges? Can stability reduce transferred force, or is force controlled only by the per-attack multiplier?

**Why this matters:** The Umbrella is intended as defense with a spatial cost, not invulnerability.

**Recommendation:** Always transfer configured force through normal player force rules. Strong force may detach Rope. Stability controls forced close, not force absorption.

**Answer:** follow the recommendation

## C6 — Stability regeneration and anti-exploit rules — P0

**Question:** Does stability regenerate only while closed? Does inventory switching close the Umbrella without bypassing forced-close recovery? Should stability and remaining recovery persist through dropping and Continue?

**Why this matters:** Switching slots could otherwise instantly reset the defense.

**Recommendation:** Closed-only regeneration; switching cannot cancel forced recovery; save stability and remaining forced-close time on the instance.

**Answer:** follow the recommendation, closing it instantly regenerates stability, but opening and closing it takes time

## C7 — Movement, jump, Rope, and airborne use — P0

**Question:** May the player open the Umbrella while jumping, falling, or climbing? Does it reduce horizontal movement, jump strength, and Rope climb speed, and can it remain open when knockback detaches the player?

**Why this matters:** These are different control paths in the current player script.

**Recommendation:** Allow airborne use; allow use on Rope but reduce climb speed; reduce movement/jump while open; close automatically on incapacitation, death, or forced recovery.

**Answer:** follow the recommendation, make all of that adjustable

## C8 — Sight occlusion — P2

**Question:** Should the open Umbrella block enemy sight rays, or is it only a combat blocker?

**Why this matters:** Sight occlusion adds collision-layer and AI complexity and could make Hushcap less distinct.

**Recommendation:** Do not make it a sight blocker during the jam.

**Answer:** follow the recommendation

---

# D. Lacerator

## D1 — Meaning of “lasts for four hits” — P0

**Question:** Does each deployed ball have four valid damaging contacts, or does the launcher have only four total shots?

**Why this matters:** These interpretations require different state, UI, saving, and balance.

**Recommendation:** Each ball has four accepted damaging contacts. Launcher ammunition is a separate limited count.

**Answer:** follow the recommendation

## D2 — Ammunition and reload source — P0

**Question:** How many balls can one Lacerator launch, and can ammunition be restored? Is ammunition inherent charge, a separate inventory item, shop service, or permanently finite?

**Why this matters:** A finite launcher without a recharge rule may become dead inventory after one encounter.

**Recommendation:** Start with four inherent shots, no separate ammo item, and no field reload. A shop may restore it later only if time permits.

**Answer:** follow the recommendation, make ammo count adjustable

## D3 — Ball lifetime, pickup, and depleted state — P0

**Question:** Is a deployed ball recoverable as ammunition/item, or only a persistent hazard? At zero contacts, should it disappear immediately or remain as inert debris?

**Why this matters:** Persistent collectible balls can multiply ammunition and inert debris can accumulate across the whole layer.

**Recommendation:** Balls are not pickups. They persist while armed, then disappear after a short depletion animation/delay.

**Answer:** follow the recommendation

## D4 — Owner and friendly-hit rules — P0

**Question:** Can a deployed ball damage the player who fired it after bouncing/resting? Can it damage enemies of any species, and should same-species filtering use the launcher's owner species?

**Why this matters:** Ground hazards need clear ownership and accepted-hit rules.

**Recommendation:** Ignore the source player; allow accepted cross-species enemy hits; rejected hits do not consume contacts or apply Bleed.

**Answer:** follow the recommendation

## D5 — Repeated contact rule — P1

**Question:** Must a target exit and re-enter the ball, or may the same target be hit again after a cooldown while remaining overlapped?

**Why this matters:** Physics overlap callbacks can spend all four contacts instantly.

**Recommendation:** Require exit/re-entry, with a small per-target cooldown as a defensive safeguard.

**Answer:** do not require exit/re-entry, but each enemy will have an adjustable iframe from the ball damage

## D6 — Damage and Bleed — P1

**Question:** Should Lacerator use the existing Bleed effect exactly, with only duration overridden per ball? May one ball refresh Bleed repeatedly without stacking multiple Bleed instances?

**Why this matters:** Carrion Stalker targeting depends on a consistent Bleed status.

**Recommendation:** Use existing refreshable Bleed; make direct damage and duration exported; never add parallel Lacerator-only bleeding.

**Answer:** follow the recommendation

## D7 — Attack interruption strength — P1

**Question:** Which preparations can a Lacerator contact interrupt: Primate aim, Hound pounce preparation, Carrion bite preparation, Sky Hunter telegraph, and Bulwark pre-charge? Can it interrupt committed attacks?

**Why this matters:** “May interrupt” is too ambiguous for a shared interrupt contract.

**Recommendation:** Allow interruption of ordinary wind-ups when configured strength meets resistance. Do not interrupt committed Bulwark charges or committed Sky Hunter passes.

**Answer:** follow the recommendation

## D8 — Maximum deployed balls and save/load — P1

**Question:** Is there a maximum number of armed Lacerator balls per launcher/player/layer? Must every armed ball save position, velocity, remaining contacts, and owner?

**Why this matters:** Unlimited persistent physics hazards can damage performance and inflate saves.

**Recommendation:** Persist armed balls, cap active balls per owner to the launcher's ammunition capacity, and remove depleted balls promptly.

**Answer:** follow the recommendation

---

# E. Resonance Core

## E1 — Quest route and circular progression — P0

**Question:** Where exactly is the Resonance Core relative to the shop and final gauntlet? Must the player enter part of the gauntlet, retrieve it, return upward to the shop, receive Bolt Shock/Moon Whistle, then cross the gauntlet again?

**Why this matters:** The spec says the Core is found “in the gauntlet” while Bolt Shock is meant to help with that gauntlet. Without clarification the reward may arrive after the challenge it is designed for.

**Recommendation:** Place the Core in an optional dangerous branch before the final gauntlet. The player retrieves it, returns to the shop, then uses the reward on the final route.

**Answer:** follow the recommendation, placement will be determined by level designer

## E2 — Unique deterministic allocation — P0

**Question:** Is there exactly one Resonance Core per run, selected through a required deterministic allocation group across eligible section variations?

**Why this matters:** Every generated run must support the quest without duplicating the unique relic.

**Recommendation:** Yes: exactly one guaranteed allocation, stable across save/load.

**Answer:** follow the recommendation

## E3 — Inventory movement and passive resonance — P0

**Question:** Does the Core emit resonance only as a physical world object, or also while carried when the player walks, jumps, lands, climbs, or is hit?

**Why this matters:** Passive inventory sound would make merely carrying the quest item a constant stealth penalty.

**Recommendation:** Inventory movement stays silent. Only physical world impacts after dropping/throwing, or explicit received-impact events, emit resonance.

**Answer:** follow the recommendation

## E4 — Sound mapping — P1

**Question:** Should weak, medium, and strong Core impacts map to three Inspector-tunable sound priorities/radii, or use a continuous curve? Can the strongest impact equal Whistle priority?

**Why this matters:** Enemy attention ordering depends primarily on integer priority.

**Recommendation:** Use three thresholds for jam readability. Cap the strongest impact below or equal to the Whistle, with all values editable.

**Answer:** follow the recommendation, all of that should be adjustable

## E5 — Physical collision effects — P0

**Question:** Can enemy attacks, projectiles, Silver Weight, and Bulwark charges push the Core? Does the Core itself deal physical damage/force when thrown, or only emit sound?

**Why this matters:** The supplied spec says resonance causes no direct damage, but shared thrown items normally apply mass-derived force.

**Recommendation:** Let valid impacts move it and emit sound. The Core itself deals no direct damage, but may transfer normal weight-derived force.

**Answer:** follow the recommendation, but core can deal direct damage like silver weight, though it deals less adjustable damage, and does not break

## E6 — Quest handover confirmation — P1

**Question:** Should interacting with the quest authority immediately hand over the Core, or show a confirmation so the player may keep using it as a sound tool?

**Why this matters:** Handover permanently removes a unique systemic item.

**Recommendation:** Use a confirmation dialogue: “Give Resonance Core?”

**Answer:** follow the recommendation

## E7 — Loss, sale, and recovery — P0

**Question:** If the Core is dropped out of bounds, stolen, sold, or left in another section, how does the player recover it? Can the quest authority locate it?

**Why this matters:** A unique optional quest should not become silently impossible through an ordinary physics accident.

**Recommendation:** Make it unsellable before handover and return out-of-bounds Core instances to a protected recovery marker. Leaving it elsewhere is allowed and saved normally.

**Answer:** follow the recommendation

---

# F. Bolt Shock

## F1 — Exact quest rewards — P0

**Question:** Confirm that the Layer 2 quest authority gives two separate rewards for one Resonance Core: the Moon Whistle/earned Moon rank and one Bolt Shock relic. Is Bolt Shock the previously unnamed “powerful relic”?

**Why this matters:** Older documents distinguish the whistle and powerful relic but did not name the relic.

**Recommendation:** Yes. Moon progression and the physical Bolt Shock item are separate rewards and separate saved states.

**Answer:** follow the recommendation

## F2 — Maximum uses and recharge — P0

**Question:** How many rods does a fresh Bolt Shock contain? Can it ever be recharged, replaced, or purchased after becoming empty?

**Why this matters:** Remaining uses are central to its balance, UI, save data, and empty-item value.

**Recommendation:** Start with three uses. No recharge or replacement during the jam unless loss recovery is required.

**Answer:** it has 7 uses, no charge or replacement.

## F3 — Rod trajectory and recovery — P0

**Question:** Does the rod fly straight or use gravity? Is a missed or terrain-hit rod permanently spent, and can fired rods ever be picked up?

**Why this matters:** The specification exposes gravity but assumes rods are not recoverable.

**Recommendation:** Use a fast, slightly gravity-affected projectile. Any successful launch consumes one use; missed rods are not recoverable.

**Answer:** follow the recommendation, but its not affected by gravity

## F4 — Valid targets — P0

**Question:** Can Bolt Shock affect every enemy, neutral creature, gatekeeper, and the player, or only hostile damageable enemies? Can it electrify breakables or the Resonance Core?

**Why this matters:** Detector suppression and stun have meaning only on actors with compatible systems.

**Recommendation:** Valid targets are living effect-receiving enemies/creatures, including gatekeepers. Breakables/Core receive only ordinary impact and do not consume an electrocuted status.

**Answer:** follow the recommendation

## F5 — Suppression memory policy — P0

**Question:** While electrocuted, should an enemy clear its current target/last-known position or merely pause it? When suppression ends, must it reacquire from new sight/sound instead of resuming stale pursuit?

**Why this matters:** The supplied documents currently allow either clear or suspend, but every enemy needs one consistent rule.

**Recommendation:** Clear target, sensory memory, and outgoing group alert. Resume neutral/recovery and reacquire normally after expiration.

**Answer:** follow the recommendation

## F6 — Attack interruption and resistances — P0

**Question:** Should an accepted Bolt Shock hit cancel every prepared attack? Does it stop a committed Bulwark charge and make a disabled Sky Hunter fall, hover, or keep gravity-free position?

**Why this matters:** These special movement states cannot safely use one generic “velocity = zero” result.

**Recommendation:** Cancel all wind-ups. Stop a Bulwark into a valid stunned/recovery state with reduced duration. A struck Sky Hunter enters controlled falling/disabled movement and recovers without affecting flockmates.

**Answer:** follow the recommendation, all flying enemies hit will stop flying and be affected by gravity, making them susceptible to fall damage

## F7 — Reapplication, stacking, and Continue — P0

**Question:** If the same target is hit twice, do stun, detector suppression, and electrical DOT refresh, stack, or remain unchanged? Should active electrocution persist through Continue?

**Why this matters:** Multiple uses could multiply lock duration or permanently disable sensors after load.

**Recommendation:** Refresh one effect; do not stack DOT/stun. Persist remaining electrocuted duration only if the shared status save can restore it safely; otherwise clear on load and restore a neutral recovery state.

**Answer:** follow the recommendation

## F8 — Empty Bolt Shock — P1

**Question:** Can an empty Bolt Shock still be thrown, sold, stolen, and lost? Does it keep the same item ID with `remaining_uses = 0`, or transform into a separate empty ID?

**Why this matters:** A separate ID changes catalog, art, economy, and save migration work.

**Recommendation:** Keep one `bolt_shock` ID with per-instance remaining uses. Empty primary gives feedback; throwing remains allowed.

**Answer:** the way to use a bolt shock & lacerator: intial state is unarmed, then it can be loaded using primary use, it fires using secondary use. it cannot be thrown even when empty or when not loaded, can be dropped from inventory. can be sold

---

# G. Shared Layer 2 enemy contracts

## G1 — Gameplay tags and Silver Weight eligibility — P0

**Question:** Approve these important tags: Primate/Hound/Stalker are `small_enemy`; Bulwark is `heavy_enemy`; Sky Hunter is `flying` and `flock_member` but not `small_enemy`?

**Why this matters:** Silver Weight instantly kills anything tagged `small_enemy`.

**Recommendation:** Approve the proposed tags. Give Bulwark and Sky Hunters explicit Silver Weight damage instead of instant death.

**Answer:** no, silver weight mechanism should not be instant death, but very big damage so that some small enemies die instatnly when hit, damage should be adjustable, and that every enemy can be hit by it

## G2 — Detector suppression coverage — P0

**Question:** Must Bolt Shock suppress sight, sound, disturbance reception, status/prey scans, proximity acquisition, and group-alert sending/receiving for every affected enemy?

**Why this matters:** Disabling only visible sensor nodes would leave Hounds, Stalkers, and coordinators active.

**Recommendation:** Yes. One shared suppressed state gates all acquisition and alert paths.

**Answer:** follow the recommendation

## G3 — Shared attack interruption — P0

**Question:** Should every new enemy expose a shared interrupt request with configurable resistance and return whether its current action was cancelled?

**Why this matters:** Lacerator and Bolt Shock need to interrupt without directly assigning enemy-specific states.

**Recommendation:** Yes. Wind-ups are interruptible; committed attacks opt into resistance or rejection.

**Answer:** follow the recommendation

## G4 — Sound versus new Disturbance system — P0

**Question:** May footsteps, landing, impacts, and resonance extend the existing sound event with optional intensity/category data, rather than building a second unrelated event bus?

**Why this matters:** The current sound event already carries position, radius, priority, type, source, and timestamp. A parallel system would duplicate most behaviour.

**Recommendation:** Extend/reuse the existing sound event. Hounds read intensity/category; ordinary listeners continue using priority/type.

**Answer:** follow the recommendation

## G5 — Layer 2 shop safety boundary — P0

**Question:** What must the safe-shop boundary block: enemy movement, target acquisition, pursuit memory, projectiles, charge paths, flock alerts, and damage hitboxes? Can enemies wait directly outside it?

**Why this matters:** Current Curse safe zones do not automatically create a complete combat sanctuary.

**Recommendation:** Use an authored boundary that prevents hostile entry, targeting across the boundary, damaging projectiles/hitboxes crossing inward, and active charges crossing. Enemies may wait outside but must return home after a timeout.

**Answer:** follow the recommendation, projectiles/hitbox can pass through

## G6 — Friendly fire and associated statuses — P0

**Question:** When same-species damage is rejected, should force, Bleed, Poison, stun, and other attached statuses also be rejected? Are any exceptions intended?

**Why this matters:** Rejecting damage but applying the attack's status can create invisible same-species friendly fire.

**Recommendation:** Reject damage and attached statuses together. Allow explicitly non-damaging world effects such as Driftseed or Dazzled according to eligibility.

**Answer:** follow the recommendation

## G7 — Persistent electrocuted state — P1

**Question:** Should detector suppression/stun be marked persistent, or treated as transient on Save & Menu for every enemy?

**Why this matters:** Current status saving can preserve timed effects, but restoring complex stunned states adds risk.

**Recommendation:** Save low electrical DOT remaining time only if convenient; clear movement stun and detector suppression on load into a neutral recovery state.

**Answer:** follow the recommendation

## G8 — Enemy drops and rewards — P1

**Question:** Do any Layer 2 enemies drop guaranteed items, random relics, money, or nothing? Does defeating the full Sky Hunter Flock give a reward?

**Why this matters:** Drop behaviour changes normal-run acquisition and motivation to kill optional creatures.

**Recommendation:** No bespoke drops in the first pass unless already designed. Use existing loot placers for relic acquisition; add drops only after behaviour works.

**Answer:** follow the recommendation

## G9 — Existing placer reuse — P0

**Question:** Should ordinary Layer 2 enemies use the existing deterministic placer with child spawn points, while a spawned group scene/coordinator handles Primate groups and the Sky Hunter Flock uses one required allocation/coordinator?

**Why this matters:** The supplied spec proposes a new spawner shape, but the project already has chance, quantity, weighted entries, stable IDs, spawn points, and allocation groups.

**Recommendation:** Reuse the existing placer. Add only the minimum group/anchor data the actual enemies require.

**Answer:** follow the recommendation

## G10 — Curse fairness responsibility — P1

**Question:** Is it acceptable for the Layer 2 Curse movement stop to overlap enemy telegraphs, provided attacks use scheduling/grace windows and remain avoidable? Or should major enemies pause their telegraph clock during a Curse stop?

**Why this matters:** Pausing every enemy from Curse code creates tight coupling, but unlucky overlaps may feel unfair.

**Recommendation:** Do not pause AI. Use telegraphs longer than the 0.5-second stop, attack-token spacing, safe cover, and player multi-hit grace.

**Answer:** nothing should change, the stop is meant to be dangerous

---

# H. Canopy Primate

## H1 — Perch transition movement — P0

**Question:** How should a Primate visibly move between connected floor, branch, and ceiling perches: jump/arc, climb along a path, crawl on surfaces, or move directly with placeholder animation?

**Why this matters:** Authored nodes choose destinations, but the physical transition still needs one movement rule.

**Recommendation:** For the jam, move along an authored straight or short waypoint path with collision checks; rotate/flip at the destination. No procedural climbing/navigation.

**Answer:** it moves like a frog, it jumps. there is no branch, only floor as the tree. it should also not perch, not hang on ceiling.

## H2 — Group ownership — P0

**Question:** Does each Primate placer create one independent group/coordinator, or do all Primates in the same section join one group?

**Why this matters:** Alert sharing, perch reservation, and attack tokens depend on group boundaries.

**Recommendation:** One coordinator per placer/spawn group. Nearby unrelated groups do not share perfect alerts.

**Answer:**

## H3 — Rock ammunition — P0

**Question:** Confirm that thrown Primate rocks are temporary projectiles and never become guaranteed collectible Throwable Rocks. Should Primates have unlimited rocks with cooldown?

**Why this matters:** Persistent attack ammunition would flood the world and economy.

**Recommendation:** Unlimited transient projectiles with cooldown; no drop chance in the first pass.

**Answer:** follow the recommendation, projectile disappears after hit

## H4 — Close-range behaviour — P1

**Question:** If no retreat perch exists and the player is close, does a Primate have a melee attack, shove, defensive delay, or only evasive movement?

**Why this matters:** The current spec rejects teleporting but leaves the fallback outcome open.

**Recommendation:** No new melee attack. Use a short evasive hop/movement followed by a defensive recovery delay.

**Answer:** follow the recommendation

---

# I. Tremor Hound

## I1 — Close-range confirmation sense — P0

**Question:** Is close confirmation a short sight cone blocked by Hushcap, a proximity sense that works through the cloud, or physical contact only?

**Why this matters:** The spec currently says “visually or physically,” which produces different counterplay.

**Recommendation:** Use short sight plus very small contact/proximity confirmation. Hushcap blocks sight but not near-contact confirmation.

**Answer:** follow the recommendation

## I2 — Player movement disturbance rules — P0

**Question:** Which player actions emit disturbance: normal walking, jumping, hard landing, Rope climbing, Rope jump-off, item use, and inventory movement? There is currently no separate run/crouch input.

**Why this matters:** “Standing still is quiet” is only meaningful if the noisy actions are explicit.

**Recommendation:** Reuse grounded walking events at low intensity; jump/landing and impacts are stronger; Rope climbing is quiet; Rope jump-off and item impacts emit normal events; inventory UI itself emits nothing.

**Answer:** follow the recommendation

## I3 — Event replacement policy — P1

**Question:** Can a new stronger disturbance replace the Hound's stored investigation target immediately? Can repeated weak footsteps eventually outrank one old strong impact?

**Why this matters:** Event scoring without replacement rules can make the Hound jitter or follow stale locations.

**Recommendation:** Replace only when the new score exceeds the stored score by a margin; age reduces old scores; add a short retarget cooldown.

**Answer:** follow the recommendation

## I4 — Pair behaviour — P2

**Question:** Should all first-pass Hound placers spawn one Hound only, even though the spec allows occasional pairs after tuning?

**Why this matters:** Pairs double pounce scheduling and sound-response readability work.

**Recommendation:** One per encounter for the initial implementation.

**Answer:** follow the recommendation

---

# J. Carrion Stalker

## J1 — How wounded prey is sensed — P0

**Question:** Can the Stalker detect Bleed/Poison through walls as a scent/status signal, or must it first have sight/proximity? How far does status sensing reach?

**Why this matters:** The spec explicitly leaves sight versus scent unresolved.

**Recommendation:** Status sensing works within a configurable radius but provides only a last-known position. The Stalker still needs a reachable route and close sight to attack.

**Answer:** follow the recommendation

## J2 — Eligible prey — P0

**Question:** Should the Stalker evaluate the player, Primates, Hounds, wounded Bulwarks, and grounded/disabled Sky Hunters? Should it ignore healthy airborne Sky Hunters it cannot reach?

**Why this matters:** Target scoring must not select permanently unreachable prey.

**Recommendation:** Yes. Only score actors with a valid reachable route; disabled/grounded Hunters may become prey.

**Answer:** follow the recommendation

## J3 — Bite Bleed — P1

**Question:** Should the Stalker's bite apply Bleed in the first pass, or only direct damage?

**Why this matters:** Guaranteed Bleed makes the Stalker recursively increase its own target priority and may create repeated lock-on.

**Recommendation:** Start with direct damage only. Keep `bite_applies_bleed` exported and enable only after playtesting.

**Answer:** bite inflicts bleed

## J4 — Healthy-player aggression — P0

**Question:** When the player is healthy and no wounded prey exists, should the Stalker remain neutral/shadowing, attack only at very short range, or hunt normally?

**Why this matters:** This determines whether it is an opportunistic ecosystem predator or a standard player chaser with bonuses.

**Recommendation:** Shadow or avoid at medium range; attack a healthy player only at short range, when cornered, or when no safer prey exists for a configurable time.

**Answer:** when no valid target exists, it becomes neutral, only attacking when attacked. its normal state is roaming

---

# K. Bulwark Beast

## K1 — Charge collision targets — P0

**Question:** Confirm that a charge can hit the player, other enemy species, breakable loot rocks, Resonance Core, and ordinary physics items, while permanent terrain only stops the charge and is never destroyed.

**Why this matters:** The Bulwark is intended as a directed world force, not only a player attack.

**Recommendation:** Confirm all listed interactions. Apply damage only to damageable actors/breakables; apply force to compatible physics objects.

**Answer:** follow the recommendation

## K2 — Same-species Bulwark displacement — P1

**Question:** If one Bulwark charges another, should damage be rejected but reduced physical displacement still occur?

**Why this matters:** The supplied spec marks this as optional.

**Recommendation:** Reject both damage and major displacement for the first pass to prevent Bulwarks shoving each other out of authored lanes.

**Answer:** follow the recommendation

## K3 — Heavy-object stop rule — P0

**Question:** Which objects may end a charge early: Silver Weight, Resonance Core, another Bulwark, or any object above an exported mass threshold? Are those objects also launched away?

**Why this matters:** The threshold is a major systemic counter and must be understandable.

**Recommendation:** Use one exported mass/impact threshold. Silver Weight and Resonance Core qualify by default. Transfer force to the object, then enter collision recovery.

**Answer:** follow the recommendation

## K4 — Relic response hierarchy — P0

**Question:** Confirm: Umbrella partially reduces damage but cannot stop the charge; Resin reduces acceleration/increases deceleration but does not immobilize; Bolt Shock can stop it with reduced stun duration; ordinary Lacerator damage cannot stop it.

**Why this matters:** These interactions define the Beast's intended counterplay.

**Recommendation:** Confirm exactly this hierarchy.

**Answer:** follow the recommendation, make umbrella damage reduction, and resin deceleration adjustable

---

# L. Sky Hunter Flock

## L1 — Activation and territory — P0

**Question:** Is the flock active across all exposed Layer 2 areas from first entry, only after reaching a trigger depth, or only in the bottom gauntlet?

**Why this matters:** A persistent layer-wide coordinator needs an activation rule and safe early onboarding.

**Recommendation:** Introduce it through an authored trigger after the first Layer 2 safe/onboarding area, then keep surviving members active across exposed regions. Never enter the shop safe zone.

**Answer:** follow the recommendation

## L2 — Starting group pressure — P2

**Question:** May the initial defaults be three members, one simultaneous attacker, and a configurable group attack-spacing delay?

**Why this matters:** Five members with multiple attacks is harder to read and debug before coordination is proven.

**Recommendation:** Start at three/one; export all values.

**Answer:** follow the recommendation, this will be determined by level designer

## L3 — Off-screen relocation — P0

**Question:** When the player changes route side, may off-screen flock members relocate to authored POIs near the active side? What minimum off-screen distance/time prevents visible teleporting?

**Why this matters:** Without relocation the “layer-wide” threat may remain stranded far from the player.

**Recommendation:** Allow relocation only when outside the camera plus a configurable margin and unseen for several seconds. Preserve health/status/member ID.

**Answer:** follow the recommendation

## L4 — Silver Weight and disabled flight — P0

**Question:** Should Silver Weight deal large configurable damage rather than instant-kill a Sky Hunter? When Driftseed or Bolt Shock disables flight, does the Hunter fall and collide with terrain, or hover with reduced movement?

**Why this matters:** Flock members are not tagged `small_enemy`; anti-flight effects need a physical outcome.

**Recommendation:** Heavy damage, not instant kill. Driftseed slows flight without falling; Bolt Shock causes controlled falling/grounded disable, then recovery takeoff.

**Answer:** follow the recommendation, follow according the rules i have specified

## L5 — Full-flock defeat reward — P1

**Question:** Does defeating the entire flock unlock anything, drop anything, alter the quest/ending, or only remove the persistent threat?

**Why this matters:** A big-enemy category may imply a reward even though the route remains non-boss-based.

**Recommendation:** No required progression reward. Permanent removal is the reward; optional money/relic drops can wait.

**Answer:** follow the recommendation

---

# M. Quest authority, shop, route, and ending

## M1 — Layer 2 quest authority identity — P1

**Question:** Who is the quest authority at the Layer 2 shop, why do they want the Resonance Core, and why do they possess the Moon Whistle and Bolt Shock?

**Why this matters:** Placeholder dialogue and quest prompts need at least a role/name and understandable exchange.

**Recommendation:** Define one shop authority character who studies resonance and rewards proof/retrieval with recognized Moon rank plus a stored defensive relic. A temporary role name is acceptable.

**Answer:** layer 2 gatekeeper is the quest giver

## M2 — Optional quest and route access — P0

**Question:** Confirm that the Resonance Core quest, Moon Whistle, Bolt Shock, and flock defeat are all optional; the player may reach and interact with the Layer 3 entrance without any of them.

**Why this matters:** Existing design says the reward helps with the gauntlet but is not a hard key.

**Recommendation:** Confirm. The optional quest changes safety/options, not gate access.

**Answer:**  follow the recommendation

## M3 — Quest-state stages — P0

**Question:** Approve these saved stages: `not_started`, `core_requested`, `core_owned_or_found`, `completed`, and `rewards_claimed`? Can finding the Core before speaking to the authority skip directly to handover?

**Why this matters:** The quest must remain idempotent and support exploration order.

**Recommendation:** Use the minimum flags needed for requested/completed/rewarded; allow early discovery and immediate handover after first conversation.

**Answer:**the quest is not a saved state, the player can find the item, and give it to the gatekeeper even if no interaction has been done. the item itself is the check, and reward is given at the dialogue confirmation

## M4 — Full-inventory reward fallback — P0

**Question:** If inventory is full during handover, where does Bolt Shock appear, and how is it protected from loss/theft before pickup?

**Why this matters:** The quest must never delete or duplicate its unique reward.

**Recommendation:** Spawn one persistent protected pickup at a fixed marker inside the shop safe zone and save its awarded state immediately.

**Answer:** follow the recommendation

## M5 — Layer 3 completion check — P0

**Question:** Is interacting with the Layer 3 entrance still the only build victory trigger, regardless of optional quest completion?

**Why this matters:** Quest logic must not accidentally hard-lock the ending.

**Recommendation:** Yes.

**Answer:** yes

## M6 — Optional ending acknowledgement — GDD

**Question:** Should the ending show different short text when the player earned the Moon Whistle, while using the same scene/credits flow?

**Why this matters:** This acknowledges the optional quest without requiring a second ending implementation.

**Recommendation:** One ending sequence with one optional acknowledgement line.

**Answer:** follow the recommendation

## M7 — Representative Layer 2 route — P1

**Question:** Describe the intended normal sequence from Layer 2 entry through inverted canopy, middle shop, Resonance Core branch, return to shop, final gauntlet, and Layer 3 entrance. Which steps may be skipped?

**Why this matters:** This becomes the manual acceptance route and exposes circular or unreachable progression.

**Recommendation:** Approve one concise route after answering E1/M2; implementation tests should follow it.

**Answer:** player go through the layewr 2 entrance, then go down to the inverted canopy, walk to the edge, shop if from east side, forest if from the west side. find the core if want to, return to get reward, and return to gauntlet to layer 3. or if they have enough items, can use simpler relics to go straight to the layer 3 gate

## M8 — Four-day presentation route — P1

**Question:** Which seed/route should be curated for the final presentation, and should debug controls grant Layer 2 relics, teleport to each encounter, and set quest stages?

**Why this matters:** A deterministic demonstration path is needed even if full balance remains unfinished.

**Recommendation:** Choose one known seed after maps contain the new placers. Add clearly labelled F3 grants/teleports rather than changing normal drop rates.

**Answer:** for presentation there is no set seed, the current mechanic should handle the random seed

---

# N. Cross-system interaction policy

## N1 — Items affecting world categories — P0

**Question:** Unless explicitly excluded, may Layer 1 and Layer 2 items affect enemies, neutral creatures, gatekeepers, breakables, physics items, and other species through shared damage, force, status, sound, light, sight obstruction, detector suppression, and interruption? Should permanent terrain remain unaffected?

**Why this matters:** This is the previously unanswered shared-item interaction question and prevents item scripts from hardcoding enemy names.

**Recommendation:** Yes. Permanent terrain is never damaged or status-affected; item/projectile-to-item interactions occur only where a shared physics/impact contract supports them.

**Answer:** follow the recommendation

## N2 — Required Layer 2 ecosystem chains — P1

**Question:** Mark these `required`, `allowed`, or `cut`: Primate impact lures Hound; Lacerator Bleed redirects Stalker; Bulwark collision lures Hound; wounded enemy redirects Stalker; Core redirects Primate/Hound/Hunters; Bolt disables one Hunter only.

**Why this matters:** Required chains need integrated acceptance tests; allowed interactions may rely on shared systems without bespoke polish.

**Recommendation:** Treat all as required except fine-grained Primate Core investigation, which may remain allowed.

**Answer:** follow the recommendation, stalker can make an enemy as an active target to hunt

## N3 — Interaction priority conflicts — P1

**Question:** When an enemy has both direct sight and a sound/status target, which wins? Specifically: should Primate short-range sight beat sound, Hound confirmed target beat ordinary disturbances, Stalker wounded prey beat sound, and marked/committed Hunters ignore new sound until recovery?

**Why this matters:** Shared sensors need enemy-specific but stable priority rules.

**Recommendation:** Confirm the priority order stated in the question.

**Answer:** primate is sight first, hound is sound, stalker is wound effect primarily since its sight and sound is very poor, and hunters ignore new sound until recovery unless they're affected/blocked by other relics

## N4 — Placeholder presentation requirements — P1

**Question:** Before final art, is a coloured placeholder plus visible telegraph, direction cue, state feedback, and distinct projectile enough for each enemy/relic?

**Why this matters:** The team needs readable playtesting without waiting for assets.

**Recommendation:** Yes. Mechanical readability is required; decorative polish is not.

**Answer:** follow the recommendation

---

# O. Previous unanswered GDD questions — non-blocking appendix

These questions were previously left unanswered. They are collected here so nothing is lost, but they must not delay the P0 Layer 2 implementation answers above.

## O1 — Full expedition loop — GDD

**Question:** Describe the full loop from Surface preparation through descent, collection/use, optional Surface return, Blue progression, Layer 2, optional Resonance quest, gauntlet, and ending. Which stages may be skipped?

**Recommendation:** Keep return optional moment-to-moment but necessary for safe progression; keep the Layer 2 quest optional.

**Answer:**

## O2 — Surface-return cadence — GDD

**Question:** What should encourage returning to Surface, and how often should a typical player return?

**Recommendation:** Use inventory capacity, weight, health, supplies, sale/delivery value, and ascent risk as soft pressure rather than a timer.

**Answer:**

## O3 — Death and permanent knowledge — GDD

**Question:** What fiction explains death ending the living run while learned relic descriptions remain known?

**Recommendation:** Preserve only knowledge and explain it briefly on the first death screen; deeper lore may remain undefined.

**Answer:**

## O4 — Replay motivation — GDD

**Question:** After one successful ending, what should motivate another run: route variations, seeds, item combinations, unknown relics, optional quest completion, or speed?

**Recommendation:** Use authored seeded variation and knowledge discovery; do not add a new meta-upgrade system.

**Answer:**

## O5 — East/west route information — GDD

**Question:** What information does the player receive before choosing east or west, and how should the routes differ in traversal, enemy density, and relic opportunity?

**Recommendation:** Give each route a readable identity while keeping both capable of reaching required progression.

**Answer:**

## O6 — Tutorial versus discovery — GDD

**Question:** Which systems are explicitly taught, and which are learned through experimentation?

**Recommendation:** Teach controls, inventory, Rope, shop, and mandatory progression. Let relic effects and systemic combinations be discovered safely.

**Answer:**

## O7 — Safe introduction of hazards — GDD

**Question:** How are theft, Bleed, Poison, Tracking Mark, large knockback, Curse triggers, and irreversible drops introduced without an unfair first failure?

**Recommendation:** Use early low-stakes examples, environmental framing, concise prompts, and strong telegraphs rather than large tutorial panels.

**Answer:**

## O8 — Setting summary — GDD

**Question:** What is the Abyss in this original setting, who lives around it, and why do people descend despite the danger?

**Recommendation:** One paragraph is enough for the GDD and artists; deeper lore can wait.

**Answer:**

## O9 — Player identity — GDD

**Question:** What is the player character's name, approximate age, training, motivation, relationship to the Surface community, and dialogue style?

**Recommendation:** Keep the biography short but give the expedition a personal goal.

**Answer:**

## O10 — Immediate New Game objective — GDD

**Question:** What exact first task is given: collect/deliver relics, earn Blue rank, investigate a person/place, or reach a depth?

**Recommendation:** Give one achievable first objective and reveal the deeper Layer 3 goal afterward.

**Answer:**

## O11 — Meaning of whistle ranks — GDD

**Question:** What do Red, Blue, and Moon Whistles mean socially and mechanically? Why does losing a physical whistle not erase earned rank?

**Recommendation:** Treat the object as a replaceable credential/tool and the rank as community-recognized achievement.

**Answer:**

## O12 — Relic origin and knowledge — GDD

**Question:** What are relics, why are their functions initially unknown, who buys them, and why does successful use reveal lasting knowledge?

**Recommendation:** Decide whether persistent knowledge is literal memory, notes, or a game abstraction and explain it consistently.

**Answer:**

## O13 — Surface shop character — GDD

**Question:** Who runs the Surface shop, what is their relationship with the player, and how do they explain buying, selling, delivery, and replacements?

**Recommendation:** One character handles all Surface services to minimize art/dialogue scope.

**Answer:**

## O14 — Senior Diver identity — GDD

**Question:** Who is the Senior Diver, why do they guard Layer 2 access, and why can the player bypass or fight them instead of only presenting Blue rank?

**Recommendation:** Make their rule and response understandable; keep systemic bypass as an intended alternative.

**Answer:**

## O15 — Representative Layer 1 run — GDD

**Question:** Describe one expected Layer 1 run from Surface preparation through Rope placement, item discovery, at least two enemy interactions, ascent Curse, Surface return, Blue progression, and the Senior Diver. Which moment best represents the game?

**Recommendation:** Use this as the GDD gameplay synopsis and Layer 1 integrated acceptance route.

**Answer:**

---

# P. Final four-day implementation handoff

## P1 — Answer priority — P0

**Question:** May programming begin after all P0 questions are answered, while P1/P2/GDD blanks use the recommendations and remain adjustable/documented?

**Why this matters:** Waiting for every lore and tuning answer would consume the remaining development time.

**Recommendation:** Yes. P0 answers lock behaviour; unanswered P1/P2 use recommendations and exported tuning; unanswered GDD remains visibly TBD.

**Answer:** follow the recommendation, if there is any conflict you should clarify and ask

## P2 — Explicit implementation greenlight boundary — P0

**Question:** After this questionnaire is answered and the Layer 2 implementation documents are updated, is that the greenlight to write Layer 2 code without another planning round?

**Why this matters:** The project has four days left and needs an unambiguous handoff.

**Recommendation:** Yes, provided contradictions in P0 answers are resolved first.

**Answer:** follow the recommendation
