# Delvers of the Abyss — Game Design Document

> **Status:** Post-jam living design source of truth<br>
> **Version:** 0.2 — 30 August 2026<br>
> **Authority:** English is authoritative. `gdd_id.md` is its Indonesian counterpart.<br>
> **Project state:** Playable prototype under continued development.

This document records the intended player experience and the plans worth preserving as development continues. It distinguishes shipped behavior from confirmed future work and distant ideas. Technical architecture and exact implementation contracts remain in the linked technical documents.

## Status vocabulary

| Label | Meaning |
| --- | --- |
| **Implemented** | Present in the current project and intended to remain. Bugs or balance problems may still exist. |
| **Confirmed** | Approved design direction, but not necessarily complete or playable. |
| **Provisional** | Useful current solution that may be renamed or redesigned. |
| **TBD** | No design should be invented until the project owner decides it. |

---

## 1. Executive summary

### High concept

*Delvers of the Abyss* is a single-player 2D systemic exploration game with roguelite and extraction elements. The player descends into a vast Abyss, experiments with unusual relics, prepares routes through dangerous terrain, and survives creatures that interact with sight, sound, force, statuses, items, and one another. Going down creates opportunity; carrying discoveries back up creates the real expedition.

### Public tagline

> A 2D exploration roguelite about descending into the Abyss, adapting with the environment, and surviving the climb back.

### Player fantasy

The player is a vulnerable but resourceful young Delver. Power comes from preparation, knowledge, and creative use of tools—not from a large combat move set. A successful player studies a situation, chooses what to carry, changes the environment, exploits creature behavior, and leaves a reliable path home before committing to greater depth.

### Current and long-term targets

- **Current prototype:** Surface hub and Layer 1, ending when the player reaches the Layer 2 gate. A successful run currently takes roughly 15 minutes.
- **First complete release target:** Surface plus two playable layers, with a normal successful run around 30 minutes.
- **Long-term vision:** an open-ended passion project that may add more unique layers and eventually approach the bottom of the Abyss. This vision is not a production promise.

### Inspirations and originality

The game is an original setting inspired by:

- *Made in Abyss*: descent, atmosphere, dangerous ascent, and progression into unknown layers;
- *Rain World*: ecology, creature behavior, vulnerability, and mood;
- *Spelunky*: replayable arrangements built from deliberate level design;
- *Risk of Rain 2*: run-based loot and progression pressure;
- *Noita* and *Terraria*: systemic tools, experimentation, and surprising interactions.

Current whistle-rank and Ascension Curse terminology is **provisional**. It describes working gameplay but must become original lore and naming before a release-ready version. The game must not require outside knowledge of any inspiration.

---

## 2. Design pillars

### 2.1 Creative relic use

Relics are tools, not single-answer keys. A relic does not solve a problem by itself; the player's observation and application make it useful. Strong relics should interact with several parts of the world or create tradeoffs instead of functioning only as weapons.

**Design test:** if an item has only one obvious target and no meaningful interaction outside that target, it needs a stronger systemic role.

### 2.2 World and creature interaction

Creatures belong to the environment rather than existing as combat obstacles in isolation. Sight, sound, light, terrain, loose items, force, status effects, and other species influence behavior. Every new enemy must fill a clear niche or combine existing niches in a new way.

**Design test:** an encounter should offer observation, avoidance, distraction, manipulation, or route planning in addition to direct damage.

### 2.3 Experimentation becomes knowledge

The player begins with only obvious information about unfamiliar relics. Using a relic reveals what it does and turns personal experimentation into persistent knowledge. Improper use still consumes the item when the item's fiction and rules require it; discovery carries risk.

**Design test:** experimentation should create an understandable result even when it is not the result the player wanted.

### 2.4 Plan the return

Descent is only half the journey. Rope placement, supplies, inventory weight, health, creature positions, and the Ascension Curse make return planning a core activity. A safe path down may be a dangerous path back up.

**Design test:** a level should create at least one meaningful return-route decision before rewarding deeper movement.

### Anti-pillars

The game is not intended to become:

- a combat-first platformer or traditional action-combat game;
- a Metroidvania built around permanent movement upgrades;
- a class-based or base-building game;
- a grind-heavy progression game;
- a procedural-terrain game;
- a deliberately punishing game based on opaque or unavoidable failure;
- a simulation whose AI or animation complexity exceeds its player-facing value.

---

## 3. Audience and intended experience

### Audience

The critical path targets general players who have played at least one platformer. Deeper systemic mastery should reward players who enjoy experimentation-heavy and ecology-driven games, but basic completion must not require genre expertise.

The game is English-first with an Indonesian localization. Dialogue is casual, sparse, and aimed at teenagers and older players.

### Emotional arc

| Expedition phase | Intended feeling |
| --- | --- |
| Surface preparation | Curiosity and anticipation |
| First descent | Wonder with controlled uncertainty |
| Creature encounter | Caution, observation, and pressure |
| Relic discovery | Experimentation and excitement |
| Inventory or route decision | Thoughtful sacrifice |
| Ascent | Familiar terrain made dangerous again |
| Safe return | Relief, ownership, and readiness to improve the next plan |
| Deeper gate | Desire to discover what comes next |

### Difficulty and fairness

Difficulty comes primarily from resource planning, route planning, creature combinations, and ascent risk. Threats must be readable. High-damage and high-knockback moves require visible warning. Loading, section transitions, and off-screen attacks must not create unavoidable damage.

Only death ends a run. The player must not be permanently softlocked by a lost item, failed quest, or unreachable route. Direct combat may make an area safer or produce a situational advantage, but ordinary creatures do not drop loot and provide no intrinsic farming incentive.

Violence remains stylized and non-graphic. Characters may strike or shoot creatures, and limited blood effects may appear, but graphic injury is outside the intended tone.

---

## 4. Product scope and current state

### 4.1 Current playable build — Implemented

The player can:

1. start a new run on the Surface;
2. obtain or purchase basic expedition supplies;
3. choose the east or west Layer 1 entrance;
4. traverse a seeded arrangement of handcrafted sections;
5. find and use Layer 1 relics;
6. avoid, manipulate, or kill Layer 1 creatures;
7. place Rope and prepare an ascent route;
8. experience and manage the Layer 1 Ascension Curse;
9. return to sell discoveries and restock, or continue downward;
10. pass, bypass, distract, or fight the Layer 1 gatekeeper;
11. finish the prototype by reaching the Layer 2 gate.

Layer 1 mechanics, items, and enemies are substantially implemented. Layer 1 is not considered content-complete until all west and east section variations are authored, decorated, balanced, and playable with minimal bugs.

### 4.2 Next milestone — Confirmed

Development order:

1. finish west Layer 1 section variations;
2. finish east Layer 1 section variations;
3. balance and stabilize the complete Layer 1 run;
4. begin a playable Layer 2 vertical slice;
5. complete and release stable slices one layer at a time.

Layer 1 completion is the highest priority after this documentation pass.

### 4.3 Layer 2 — Confirmed design, unfinished content

Current Layer 2 implementation documents confirm four relics—Plate Umbrella, Lacerator, Resonance Core, and Bolt Shock—and five creature categories—Canopy Primate, Tremor Hound, Carrion Stalker, Bulwark Beast, and Sky Hunter Flock. Their foundations exist, but final maps, presentation, balance, narrative integration, and a complete playable layer remain unfinished.

Layer 2 should be the point where the systems introduced safely in Layer 1 begin producing more demanding combinations. It may use a fundamentally different world structure; Layer 1's two-route, six-slot layout is a game-jam constraint, not a mandatory template for every future layer.

### 4.4 Beyond Layer 2 — TBD

The first complete release is scoped to two playable layers. Further layers, Layer 3's role, the bottom of the Abyss, and the final ending remain distant design work. They may expand the passion project later, but must not enlarge near-term scope.

### 4.5 Temporary content

The following should not be mistaken for final direction:

- all current audio;
- some character, background, and interface assets;
- AI-generated assets marked for possible replacement;
- current quest implementation and dialogue text;
- incomplete or undecorated maps;
- provisional borrowed terminology and lore.

The authored-section world-generation model is intended to remain, although later layers may use larger sections, more sections, or different structures.

---

## 5. Core gameplay

### 5.1 Moment-to-moment loop

1. **Observe:** read terrain, exits, loose objects, creatures, light, and available anchors.
2. **Prepare:** choose a direction, ready a relic, or place Rope before committing.
3. **Traverse:** move, jump, climb, and manage weight through authored geometry.
4. **Interact:** distract, slow, illuminate, bind, mark, launch, steal from, or damage actors through shared systems.
5. **Recover:** collect useful items, create distance, treat effects, and reassess the return route.
6. **Commit or retreat:** spend resources to continue deeper or turn value and knowledge into a safer future run.

### 5.2 Expedition loop

1. Begin on the Surface with the Multitool and available money.
2. Visit the shop, buy supplies, and use intended Surface loot to improve preparation.
3. Choose an east or west entrance. The routes provide variation without promising radically different progression or rewards.
4. Descend through selected authored sections, gathering relics and placing Rope where the return would otherwise become dangerous.
5. Outsmart creatures with the carried tools, accepting that carrying every useful object is impossible.
6. Decide between going deeper and returning based on health, inventory space, weight, remaining supplies, known threats, and route safety.
7. Ascend through the prepared route while managing Curse thresholds and creatures in reverse terrain contexts.
8. Return to the Surface, sell relics, buy supplies, review learned descriptions, and plan the next run—or continue deeper without cashing out.

Surface return is soft pressure, never a timer. Weakness, low health, full inventory, weight, and depleted supplies encourage retreat. The Curse exists to give ascent its own challenge, not to force a fixed return schedule.

### 5.3 Representative run

An ideal Layer 1 run begins with several Ropes and a deliberate choice of route. The player finds a useful but unfamiliar relic, uses sound or terrain to avoid one creature, then combines a second relic with an enemy's behavior to pass another encounter. They place Rope before a long drop, leave behind a valuable item because weight and slots matter, and later use that prepared Rope to break the ascent into safe rests. Near the Surface, they choose whether to risk one more recovery or protect the value already carried.

The defining moment is not killing a creature. It is recognizing that a relic, creature, and piece of terrain form a solution the game never explicitly prescribed.

---

## 6. Run progression, persistence, and economy

### Run state

A living run preserves generated sections, placer results, world items, creature deaths and health, carried items, money, whistle status, relevant effects, and progression flags through Save & Continue. Temporary projectiles, active attack phases, and short-lived effect areas restore into safe states rather than resuming mid-collision.

### Death

Death is the only run-ending failure. It resets run inventory, money, world state, route state, and run progression. Persistent meta knowledge survives through discovered item descriptions, together with selected lifetime statistics. Ordinary Save & Continue is not death and retains the living run.

The fiction explaining retained knowledge is **TBD**. Until written, the GDD treats persistent descriptions as the player's accumulated understanding rather than supernatural character power.

### Permanent progression

Permanent progression should emphasize:

- relic knowledge and descriptions;
- access and whistle rank;
- story and dialogue flags;
- unlocked services or routes where needed;
- non-power statistics about previous runs.

Permanent stat grinding is not part of the current vision.

### Economy

Money currently exists to purchase expedition supplies. Sell value creates a reason to extract useful discoveries rather than consume everything. Delivery and quest systems are provisional and should not become mandatory grind without a later design decision.

The economy should answer one question: **what resource makes the next expedition safer or more flexible?** Money that cannot change preparation has no meaningful role.

### Replay value

Replay comes from, in priority order:

1. different relic combinations;
2. route and section variation;
3. systemic creature encounters;
4. incomplete relic knowledge;
5. optional objectives and more efficient planning.

---

## 7. Player, controls, and inventory

### Player capabilities

The player can run, perform a variable jump, steer in the air, interact through the cursor, use or throw the selected item, place and climb Rope, manage inventory, and use a physical whistle. The movement set stays understandable; item and environment mastery provide most advanced expression.

### Controls

| Action | Default input |
| --- | --- |
| Move | `A` / `D` or left/right arrows |
| Jump | `Space` |
| Rope movement | `W` / `S` or up/down arrows |
| Interact / pick up | `E` |
| Primary item action | Left mouse button |
| Secondary item action | Right mouse button |
| Hotbar selection | `1`, `2`, or mouse wheel |
| Inventory | `Tab` |
| Pause / close | `Esc` |
| Fullscreen | `F11` |

Keyboard and mouse are implemented. Controller support is planned but remains uncommitted until the interaction and cursor model has a tested controller equivalent.

### Inventory

- Five backpack slots.
- Two dedicated hotbar slots.
- One physical whistle slot.
- Stack rules depend on the item and its mutable state.
- Item weight affects movement, jumping, falling, throwing, and the decision to extract or leave something behind.

This small inventory is intentional and should not be casually expanded. The player must compare immediate utility, future safety, sale value, and weight. Capacity upgrades are not currently planned.

### Item actions

Left click requests the selected item's primary behavior. Right click requests its explicit secondary behavior, often a physical throw. Items may override or disable either action. Real items retain identity and state in the world; temporary attacks use non-pickup projectiles.

### Rope

Rope is both traversal equipment and route memory. Placement commits a limited resource to a location, creates a return path, persists for the living run, and allows climbing while holding active items. Maps should present valuable anchor decisions without making one exact placement mandatory.

---

## 8. World structure and generation

### Surface

The Surface is the preparation and recovery hub. It contains the shop, starting supplies, dialogue/NPC functions, both Layer 1 entrances, and progression services. It should feel safer and more legible than the Abyss without removing the anticipation of descent.

### Authored variation

Terrain is handcrafted. A seed selects section variations and deterministic placer results; it does not procedurally generate terrain. This preserves intentional traversal and encounter composition while giving repeat runs different routes and item/enemy arrangements.

For the current Layer 1 structure:

- east and west routes each use six section slots;
- every slot chooses from compatible authored variations;
- terrain, entrances, exits, safe positions, and major progression actors remain deliberately authored;
- placers determine eligible enemies or loot from designer-controlled entries;
- required unique content uses allocation rules so every generated route remains completable;
- the player always starts on the Surface.

East and west provide variation, but are not currently intended to have radically different identities or progression rewards.

### Future layers

Future layers may use different route counts, larger sections, additional sections, hubs, or traversal structures. They must retain authored readability, deterministic saves, and protection against softlocks. New world-generation complexity needs clear player value before it is accepted.

---

## 9. Relics and supplies

### Item philosophy

Every relic is a physical object with several possible values: immediate use, interaction potential, route safety, sale value, delivery value, weight, and knowledge. A new relic is worth adding when it creates decisions or interactions that existing tools cannot provide cleanly.

The player initially receives only obvious information. Successful signature use reveals a discoverable item's description. Incorrect use may still spend a consumable; risk makes experimentation meaningful.

### Layer 1 roster — Implemented

| Item | Primary design role |
| --- | --- |
| Multitool | Reusable close tool/attack and breakable interaction; cannot be thrown. |
| Rope | Persistent route preparation and climbing. |
| Rock | Simple physical force and throw reference. |
| Bandage | Removes Bleed and applies healing that can accumulate up to its duration cap. |
| Info Book | Reveals remaining discoverable descriptions. |
| Numbing Pill | Temporarily suppresses Curse thresholds at an added duration cost. |
| Sun Sphere | Mobile light that can be activated before or by impact while retaining world momentum. |
| Lantern Crystal | Throwable line-of-sight flash and sound lure obtained from Lantern Snails. |
| Rattlepod | Repeated high-priority sound source for distraction and targeting. |
| Hushcap | Sight-suppressing cloud with player overlay feedback. |
| Cling Resin | Blue slowing area that controls actors and loose-object movement. |
| Driftseed | Alters descent, gravity, knockback, and eligible flying targets. |
| Silver Weight | Very heavy, high-impact tool with visible damaged states and finite use. |
| Red / Blue Whistle | Physical rank item and high-priority sound source. Terminology is provisional. |

### Layer 2 roster — Confirmed, unfinished

| Relic | Intended role |
| --- | --- |
| Plate Umbrella | Cursor-directed defense that trades mobility and stability for protection. |
| Lacerator | Limited-ammunition gravity projectile that creates persistent dangerous balls and Bleed. |
| Resonance Core | Unique heavy quest relic whose impacts create tiered sound and force. |
| Bolt Shock | Finite-use reward weapon that interrupts, electrocutes, suppresses sensors, and disables flight. |
| Moon Whistle | Provisional physical progression credential tied to the Layer 2 exchange. |

Layer 2 acquisition, quest, and reward flow remain subject to later narrative and map integration. Current technical behavior is documented; it is not proof that the layer is content-complete.

---

## 10. Creatures and encounter design

### Shared philosophy

Creatures communicate their current intent through movement, facing, animation, telegraphs, sound, and debug-visible sensors during development. Each species owns a recognizable niche. Killing removes danger but normally gives no loot. Non-combat solutions must remain viable on required routes.

Creature behavior uses shared contracts for health, damage, force, effects, sight, sound, target priority, persistence, and hit feedback. Species-specific logic should remain as simple as its visible behavior allows; the project does not aim to reproduce simulation-heavy procedural AI.

### Layer 1 creatures — Implemented

| Creature | Encounter niche |
| --- | --- |
| Tongue Amphibian | Roams, investigates sound, prefers loose items, and may steal one real player item. |
| Knockback Bird | Defends a nest and turns terrain danger into its primary threat through swooping force. |
| Thorn Bloom | Neutral stationary hazard that bursts into radial bleeding needles when agitated. |
| Lantern Snail | Crawls connected surfaces, avoids the player, emits light, and produces a line-of-sight flash/sound response. |
| Cave Spider | Uses sound and sight, fires a slowing/poisoning/tracking projectile, chases a marked target to bite, then retreats. |
| Large Flyer | Persistent layer-wide hunter that observes, searches, pursues, and commits to a high-damage dive. |
| Senior Diver | Gatekeeper encounter allowing credential, dialogue, distraction, bypass, grab/confiscation, or combat outcomes. |

### Layer 2 creatures — Confirmed, unfinished

| Creature | Encounter niche |
| --- | --- |
| Canopy Primate | Grounded spacing and coordinated gravity-rock throws. |
| Tremor Hound | Locates sound sources, searches terrain, confirms nearby prey, and pounces. |
| Carrion Stalker | Selects wounded, bleeding, poisoned, or low-health prey. |
| Bulwark Beast | Telegraphs and commits to a powerful horizontal charge with a recovery window. |
| Sky Hunter Flock | Several independently damageable flyers coordinated by shared attack spacing and persistence. |

Layer 2 should combine these niches rather than simply increase health and damage.

---

## 11. Systemic interaction, effects, and the Curse

### Shared interaction language

The game should prefer shared verbs over one-off scripted solutions:

- **Damage:** reduces health and may kill.
- **Force:** changes movement and can make terrain dangerous independently of damage.
- **Sight:** requires range, facing where applicable, and an unobstructed line to the player's detection point.
- **Sound:** carries position, radius, and priority, allowing investigation or target override.
- **Status:** changes an actor over time and remains visible through text/timers.
- **Agitation:** causes neutral creatures or hazards to react without making every reaction a chase.
- **World ownership:** keeps real items recoverable, stealable, sellable, and saveable.

These contracts let one tool affect several creatures without custom pairwise code.

### Effects

Important effects include Bleed, Poison, Slowness, Resin Bound, Incapacitated, Tracked, Dazzled, Healing, Curse Suppression, Driftseed, Electrocuted, and layer-specific Curse packages.

- Repeated Poison duration adds up to 15 seconds.
- Repeated spider Slowness adds up to 10 seconds.
- Repeated Tracked duration adds up to 20 seconds.
- Bandage Healing adds up to 50 seconds.
- Tick damage produces one hit flash; direct damage produces two rapid player flashes.
- Enemies show active effect text and duration above their heads.
- Hushcap prevents enemy sight detectors from updating while affected.
- Electrical effects interrupt relevant creature abilities: frogs cannot jump or steal, spiders cannot fire, and disabled flyers fall.

Exact numbers remain data-driven and may change during balancing.

### Ascension Curse

The Curse turns upward travel into route and pacing pressure. It tracks the player's deepest reference point and applies a package when newly crossed ascent bands are reached. Resting near the same vertical position resets the reference; safe zones reset it deliberately. Numbing Pills consume thresholds safely at a time cost.

Layer 1 currently applies a temporary package affecting movement, healing, throw reach, and color. Layer 2 has a separate confirmed package involving throw/color penalties, temporary health-cap stacks, and occasional movement interruption. Layer packages do not combine.

The warning system tells the player when upward movement reaches 70% of the next Curse threshold. This keeps failure readable without removing the need to plan rests.

The Curse's original in-world cause, public understanding, and final name are **TBD**. It is currently treated as a natural property of the Abyss and a known occupational danger.

---

## 12. Narrative and world

### Premise

People live at the edge of the Abyss because relic recovery supports their economy. Artifacts are sold to other nations, making descent a livelihood despite its danger. Relics are believed to come from a past civilization, but their maker and the Abyss's exact nature remain unknown.

The protagonist descends for the first time without supervision, driven by curiosity, the mystery of the Abyss, and the legacy of a missing parent who became a legendary Delver and went where return may have been impossible.

### Protagonist — Provisional

The game-jam build calls the protagonist **Elenara**. This is not her final name. Her exact personality, age, and long-term arc are **TBD**. Established direction:

- she is a curious young person beginning unsupervised delving;
- she has little practical relic knowledge at the start;
- her parent was a legendary Delver;
- she has been entrusted to an older mentor;
- dialogue remains minimal and casual rather than constant exposition.

### Old Man

The Old Man is a retired member of the protagonist's parent's Delver group. The parent entrusted their child to him. He now trains and mentors new Delvers but refuses to explain why he retired or reveal everything he knows. “The Wanderer” was a placeholder identity and is not canon.

### Surface shopkeeper

The current shopkeeper is functionally a seller NPC. Name, personality, relationship, and story purpose remain **TBD**.

### Layer 1 gatekeeper

The gatekeeper is an experienced provisional Blue-rank Delver entrusted with securing travel into and out of Layer 2. The encounter supports multiple approaches because player freedom is a core value: recognized rank, dialogue, distraction, bypass, direct conflict, or suffering the gatekeeper's grab and confiscation response.

### Layer 2 authority

A second legendary Delver is planned as a mysterious Layer 2 authority who knows information about the protagonist's parent. The current optional Resonance Core exchange and its rewards provide a functional base, but final characterization, dialogue, and quest meaning remain **TBD**.

### Narrative delivery

Story should come primarily from concise dialogue, environments, item descriptions, creature behavior, and player discovery. Mandatory rules must not be hidden only in flavor text. Cutscenes should be rare and justified by information that gameplay cannot communicate.

All current dialogue serves a functional prototype purpose and is not final canon. Shadow was a placeholder and should not appear as a distinct canonical character without a new design.

### Ending — TBD

The first complete release should establish a satisfying Layer 2 stopping point, but its exact ending is not designed. The distant ambition is to reach the bottom of the Abyss; neither its truth nor the missing parent's fate should be invented until narrative work resumes.

---

## 13. Presentation, UI, audio, and accessibility

### Visual direction

The intended world is fantastical-medieval with elements of science fiction and speculative biology. Upper-layer creatures begin with recognizable natural forms; deeper creatures may become increasingly unfamiliar. Environments should produce awe, scale, beauty, and danger while keeping interactable silhouettes and threat telegraphs readable.

The current project uses pixel art at a 640×360 internal viewport with nearest-neighbor rendering. This resolution and art pipeline are implemented constraints, but individual assets may be replaced.

### Interface

The interface should feel like an object from the expedition world while remaining readable. The current book-like inventory and illustrated menu language are the preferred direction. The HUD communicates health, selected items, whistle, money, weight, active effects, interaction prompts, Curse warning, and telegraphed threats.

### Feedback

- Direct player damage: two rapid white flashes; tick damage: one flash.
- Enemy damage: one adjustable white flash.
- Health bar flashes in the same direct/tick pattern.
- High-risk enemy actions show a warning icon and directional enemy pointer.
- Active statuses show names and durations.
- F3 debugging can reveal selected sensors, patrol ranges, hitboxes, health, states, sound targets, world generation, and test controls without forcing every range on simultaneously.

### Audio

All current audio is temporary. Final sound direction is **TBD**. The desired soundscape should feel large, awe-inspiring, and mysterious. Music should eventually be adaptive. Gameplay-critical movement, sound sources, relic activation, telegraphs, impacts, and creature responses must remain recognizable even before final music exists.

### Accessibility

Confirmed direction, not yet complete:

- readable text and telegraphs;
- critical information not communicated by color alone;
- reduced-flash and reduced-screen-effect options;
- restrained camera shake, parallax, and pixel movement to avoid nausea;
- future input remapping and controller investigation;
- subtitles/text for important audio information where practical.

Exact accessibility scope remains provisional and should grow from playtesting rather than promises the project cannot yet support.

---

## 14. Production direction

### Development model

Development is primarily solo, with occasional help from members of the game-jam team. The project owner has final authority over design, narrative, programming, art direction, and release decisions. Contributors may propose changes, but an approved GDD update defines intended player-facing behavior.

### Milestone policy

Build stable vertical slices one layer at a time and keep the main branch playable. Do not implement distant systems solely because a future layer might need them. Prefer simple authored solutions over simulation complexity when both create the intended player experience.

### Main risks

1. Solo workload.
2. Asset production and replacement cost.
3. Accumulating technical debt.
4. Content volume required by handcrafted map variations.
5. Balancing interactions without making them unreadable.

### Playtesting

Friends and collaborators are the initial test group. Testing should answer:

- Can a new player understand how to begin an expedition?
- Can they identify at least one non-combat solution to an enemy?
- Do they understand why an item interaction succeeded or failed?
- Does Rope placement matter on the return journey?
- Does the Curse create planning instead of confusion?
- Can they reach the current endpoint without debug tools or a softlock?
- Do movement, pixel rendering, flashes, or overlays cause discomfort?

Presentation feedback says the project has potential but is not simple to enter. Onboarding and clarity therefore matter before adding more content.

### Success

The project succeeds if it becomes the game its owner wished existed and creates a memorable experience for even a small number of players. Commercial scale is not required. Creative pride, a coherent systemic identity, and a stable playable release are valid success outcomes.

---

## 15. Open design ledger

These items remain deliberately unresolved:

- final protagonist name, age, personality, and voice;
- exact nature and origin of the Abyss;
- original replacement for borrowed whistle ranks and Curse terminology;
- missing parent's full history and fate;
- final Surface shopkeeper identity;
- Layer 2 authority, quest narrative, and final rewards;
- final Layer 2 structure and maps;
- Layer 2 stopping point and ending;
- any playable Layer 3 or deeper-layer commitment;
- final music and audio direction;
- motion-effect and accessibility settings;
- contributor credits, third-party attribution, and itch.io URL;
- final replacement plan for temporary and AI-generated assets.

Do not turn a `TBD` into canon merely because an implementation needs a label. Use a clearly provisional placeholder and return the narrative/design decision to this ledger.

---

## 16. Document authority and references

When documents disagree:

1. This GDD owns approved player-facing intent.
2. `fondasi_teknis_godot.md` owns shared technical architecture.
3. `panduan_programming.md` owns implementation workflow and code rules.
4. `panduan_world_generation.md` owns map and placer authoring contracts.
5. `docs/implementation/` owns implemented enemy, item, effect, Curse, and Layer 2 contracts.
6. Answered questionnaires preserve decision history.
7. `docs/reference/` is archival and cannot override current decisions.

An accidental difference between code and this document is a bug, not an automatic design change. Intentional changes must update the GDD and the affected implementation document together after owner approval.

Key references:

- [Technical foundation](fondasi_teknis_godot.md)
- [Programming guide](panduan_programming.md)
- [World-generation guide](panduan_world_generation.md)
- [Layer 1 items](implementation/layer_1_items.md)
- [Layer 1 enemies](implementation/layer_1_enemies.md)
- [Ascension Curse](implementation/ascension_curse.md)
- [Effects](implementation/effects.md)
- [Layer 2 relics](implementation/layer_2_relics.md)
- [Layer 2 enemies](implementation/layer_2_enemies.md)
- [Layer 2 world integration](implementation/layer_2_world_integration.md)

Full technical-document reconciliation is scheduled as a separate audit after this GDD/README pass.
