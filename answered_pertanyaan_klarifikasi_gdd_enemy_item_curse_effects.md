# GDD, Layer 1 Content, Ascension Curse, and Effects — Clarification Questionnaire

> **Status — 14 August 2026:** Open. Answer every **GDD BLOCKER** and **IMPLEMENTATION BLOCKER** before the English GDD and implementation documents are treated as final. No gameplay code should be written from this questionnaire alone.

This questionnaire gathers the remaining decisions needed for five connected tasks:

1. write the English Game Design Document (GDD);
2. translate it into clear Indonesian;
3. prepare separate implementation documents for Layer 1 enemies, Layer 1 items, the Ascension Curse, and effects;
4. implement all planned Layer 1 enemies and items with placeholder presentation;
5. stop immediately before final art integration and manual balance tuning.

Write answers directly after each **Answer:** label. Short answers are acceptable when they clearly select an option. If an earlier answer should replace a locked rule, state that explicitly instead of silently contradicting it.

Priorities:

- **GDD BLOCKER** — required for an accurate English GDD.
- **IMPLEMENTATION BLOCKER** — changes system ownership, interfaces, saved state, or core behavior.
- **BEFORE PLAYTEST** — a safe placeholder is possible, but the decision must be made before integrated testing.
- **TUNING LATER** — may use an Inspector/Resource default until manual balancing.

## Document authority

When existing documents conflict, use this order:

1. `fondasi_teknis_godot.md`;
2. `panduan_programming.md`;
3. `panduan_world_generation.md`;
4. answered decision-history questionnaires;
5. files under `docs/reference/`.

The reference folder contains useful ideas but also old rules. In particular, its universal throw rule, Multitool restrictions, three-pulse Rattlepod, Silver Weight hold input, and old final-gate flow are not automatically current.

## Decisions already understood

Unless an answer explicitly replaces them, these decisions are already locked:

- Godot 4.7.1, keyboard and mouse, 640×360 internal viewport, and Linux-first development.
- Player art is 32×32 px; item art may be 16×16 px; gameplay collision is authored separately from sprites.
- Five backpack slots, two hotbar slots, and one dedicated whistle slot.
- Left click requests an item's primary action. Right click requests its configurable secondary action. Most ordinary items default to throw; exceptions may disable or replace it.
- Game-jam item actions use a press contract. There is no general hold/release framework yet.
- `ThrownItem` represents a real inventory item. `Projectile` represents a temporary attack and cannot be picked up.
- Damage, force, statuses, and agitation share the impact pipeline. Theft remains a special ownership transfer.
- All enemies can die at zero health. There is no universal contact damage; attacks require active hitboxes or projectiles.
- Same-species enemy damage is blocked, while different species may damage one another.
- Player damage i-frames block repeated damage but not force.
- Enemy death and harvested sources persist for the living run. Living ordinary enemies restore at their placer with saved health and neutral AI state.
- Direct sight normally beats sound. Sound has separate radius and priority. Enemy sight requires an unobstructed line.
- The Multitool is an ordinary one-instance inventory item, but its secondary action is disabled instead of throw. Its primary action is the implemented cursor-directed thrust/tool use.
- Frog theft moves one real item instance. Priority is active ordinary item, other hotbar items, backpack items, Multitool, then whistle. One successful hit/impact makes the frog drop the stolen item.
- A first-harvest Lantern Snail starts with 2 HP; one Multitool harvest hit converts it to an item. A redeployed snail starts with 1 HP and dies instead of being harvested again. (change: killing a snail will harvest its shell and not the snail itself, the shell is the throwable item)
- Rattlepod activation and throwing are separate. An activated pod produces five targeting pulses across five seconds and disappears when finished. An unactivated throw behaves like an ordinary small object.
- Numbing Pills add five minutes of suppression per use. (with a maximum of 999 seconds)
- Bandage healing is not cancelled by ordinary damage.
- Driftseed currently targets the player and the boss/gatekeeper, not every enemy.
- Rope placement, climbing, extension, section crossing, and living-run persistence are already implemented foundations.
- Layer 3 is not playable. The build ends when the player interacts with its entrance.
- The optional Layer 2 shop gatekeeper asks for an undesigned quest relic, then gives two separate rewards: the Moon Whistle and an undesigned powerful relic. The powerful relic helps with the gauntlet before the Layer 3 entrance.

## Findings from the current project

- Production enemy resources do not exist yet. Current enemy scenes are a test amphibian and a projectile turret.
- Shared health, damage, force, projectile, sight, sound, status, persistence, deterministic placer, and player foundations exist and should be extended rather than replaced.
- Current item definitions are Multitool, Rope, Throwable Rock, and a debug heavy pack.
- `StatusController` currently supports one entry per effect ID, duration, four stack rules, tick damage, multiplicative modifiers, and optional persistence. It does not yet track effect source ownership or overlapping area providers.
- Current damage i-frames apply to all damage routed through `HealthComponent`, including damage-over-time unless implementation adds an explicit rule.
- `CurseProfile` exists only as minimal data. No complete runtime Curse tracker exists.
- Existing `Projectile` can carry damage, force, and status payloads, but production terrain responses, agitation reactions, and enemy-specific attack presentation remain unfinished.
- Existing archived item specifications contain unresolved or superseded rules. Answers below must produce one coherent design before implementation documents are written.

## External reference baseline

Modern GDD guidance does not prescribe one universal format. Useful documents are searchable, readable, tailored to their team, and commonly cover vision, goals, world, mechanics, characters, story, UI, audio, gameplay flow, technical needs, and assets:

- [Game Developer: How to Write a Game Design Document](https://www.gamedeveloper.com/design/how-to-write-a-game-design-document)
- [Game Developer: A GDD Template for the Indie Developer](https://www.gamedeveloper.com/design/a-gdd-template-for-the-indie-developer)
- [Unity Game Design Document Template](https://connect-prd-cdn.unity.com/20201215/83f3733d-3146-42de-8a69-f461d6662eb1/Game-Design-Document-Template.pdf)

For Made in Abyss, the reference Curse is associated with upward movement, becomes worse at deeper layers, and is commonly described as manifesting after roughly ten metres of ascent. This is reference material, not an automatic rule for this game:

- [Made in Abyss Wiki: The Curse of the Abyss](https://madeinabyss.fandom.com/wiki/The_Curse_of_the_Abyss)

---

# A. Document identity, authority, and scope

## A1 — Final game title and internal project name — GDD BLOCKER

What title should the GDD use? Is `CCI GD Project` only a repository/internal name, and does the game already have a final or working public title?

**Recommendation:** provide one public working title and keep `CCI GD Project` only as the repository name.

**Answer:** title is "Delvers of the Abyss", repo name stays the same

## A2 — GDD purpose and primary readers — GDD BLOCKER

Who must be able to use the GDD: the current jam team, supervisors/judges, future developers, artists/audio contributors, or public readers? Should it explain implementation constraints, or remain focused on player-facing design?

**Recommendation:** write for the whole jam team and supervisor, with design rules in the GDD and code details linked to separate implementation documents.

**Answer:** follow the recommendation

## A3 — GDD content boundary — GDD BLOCKER

Should the GDD describe only the presentation build, the larger intended game beyond the jam, or both with a clear `Jam Build` versus `Future Vision` split?

**Recommendation:** make the playable jam build authoritative and place future ideas in a clearly non-committed appendix.

**Answer:** the current gdd will focus on the jam build, as right now its not done it will be updated as development continues

## A4 — English and Indonesian authority — GDD BLOCKER

Should the English GDD be the master document and the Indonesian file a faithful translation, or should both be independently editable sources?

**Recommendation:** English is authoritative; Indonesian mirrors its headings, IDs, tables, numbers, and decisions exactly.

**Answer:** follow the recommendation

## A5 — Implementation-document language — GDD BLOCKER

Should the four later implementation documents be English, Indonesian, or bilingual?

**Recommendation:** use English for stable code/API terms, with brief Indonesian explanations only where the beginner programmer needs them.

**Answer:** english only

## A6 — New GDD versus existing technical documents — GDD BLOCKER

When design changes later, which document is updated first? Should the GDD become the design source of truth while `fondasi_teknis_godot.md` remains the technical source of truth?

**Recommendation:** GDD owns intended player-facing behavior; technical foundation owns architecture. Any contradiction must be resolved in both in the same documentation pass.

**Answer:**  follow the recommendation

## A7 — Made in Abyss relationship and terminology — GDD BLOCKER

Is this explicitly a Made in Abyss fan game, an original game strongly inspired by it, or an original setting that temporarily borrows terms such as layers, whistles, relics, and Curse of Ascension?

This affects naming, story, presentation, credits, and whether the GDD should describe borrowed lore or original equivalents.

**Recommendation:** state the relationship plainly and identify every term that must later be renamed if the project is original.

**Answer:** this is an original game strongly inspired by it. this game is also mainly inspired by terraria, noita, rainworld, and spelunky

## A8 — Questionnaire replacement rule — IMPLEMENTATION BLOCKER

If an answer here contradicts an older locked answer, should the new answer automatically replace it, or should it be marked `proposed` until you explicitly approve the updated GDD?

**Recommendation:** answers here become design decisions, but only the reviewed GDD and implementation documents become implementation authority.

**Answer:** follow the recommendation, but if there are a big contradiction you should always ask me 

---

# B. High concept and intended experience

## B1 — One-sentence logline — GDD BLOCKER

In one sentence, who is the player, what do they do repeatedly, what opposes them, and what is their ultimate goal?

**Recommendation:** describe descent, relic recovery, risky ascent, and reaching the Layer 3 entrance without listing every system.

**Answer:** (currently unnamed, make the character name in the gdd easily find and replaceable) is a curious child on her journey to uncover the mysteries of the abyss by creatively using relics to survive the dangers present and dive deeper.
something along those lines

## B2 — Genre labels — GDD BLOCKER

Which genre terms best set player expectations: 2D platformer, exploration game, extraction game, survival game, action-adventure, immersive simulation, roguelite, or another combination?

**Recommendation:** choose one primary genre and at most two supporting labels.

**Answer:** 2d exploration extraction rougelite

## B3 — Core fantasy — GDD BLOCKER

What fantasy should the player inhabit: vulnerable cave explorer, relic researcher, prepared expedition leader, clever creature manipulator, desperate survivor, or something else?

**Recommendation:** centre vulnerability and preparation; direct combat remains a costly fallback.

**Answer:** curious girl looking to uncover the secrets of the abyss and find her missing parents on the abyss

## B4 — Three design pillars — GDD BLOCKER

What three principles should decide cuts and conflicts? Examples: systemic relic interactions, dangerous return journey, readable creatures, persistent route preparation, or curiosity through experimentation.

**Recommendation:** select exactly three pillars and give one practical consequence for each.

**Answer:**  it focuses heavily on player's creativity in using the relics for their advantage, it focuses on enemy and world interaction instead of combat, it pushes player experimentation, it pushed players to think about their journey and how to get back safely

## B5 — Explicit anti-pillars — GDD BLOCKER

What should the game never become during this jam? Examples include combat-first action, inventory micromanagement, opaque instant deaths, grind-heavy economy, or random terrain generation.

**Recommendation:** include at least three anti-pillars so later tuning does not erase the intended identity.

**Answer:** its not a combat focused platformer or metroidvania, its not focused on player mechanics, no procedural terrain, it shouldnt be a grindfest, it shouldnt be a punishing game.

## B6 — Intended emotions across a run — GDD BLOCKER

What should the player feel during preparation, descent, discovery, dangerous encounters, ascent, surface return, death, and the ending?

**Recommendation:** provide a short emotional curve rather than one constant mood.

**Answer:** the player should feel curious at prep and first descent, careful at encounters, excited when making discoveries, thoughtful when having to make choices, and wanting to play more when they reach the end

## B7 — Target player and expected skill — GDD BLOCKER

Is the game aimed at players familiar with difficult platformers/systemic games, general game-jam visitors, Made in Abyss fans, or complete newcomers? How much failure and experimentation should be expected before understanding an item?

**Recommendation:** design the critical path for a newcomer while allowing expert shortcuts through systemic item use.

**Answer:** the game is targeted towards general gamejam visitors and players who have played at least one platformer game before

## B8 — Desired difficulty and fairness — GDD BLOCKER

Should difficulty come mainly from execution, resource planning, imperfect information, enemy combinations, the ascent Curse, navigation, or attrition? What kinds of failure feel fair or unfair?

**Recommendation:** prioritise telegraphed threats and planning pressure; avoid unavoidable damage from off-screen or immediately after a seam/load.

**Answer:** difficulty comes from resource planning, route planning, and enemies

## B9 — Expected session and run length — GDD BLOCKER

How long should a supervisor demo, first successful run, normal full run, and repeat run take? How often should the player reasonably return to the surface?

**Recommendation:** give broad minute ranges now; precise pacing remains a playtest variable.

**Answer:** 30 mins for a run sounds reasonable

## B10 — Why the game is fun — GDD BLOCKER

What should create the strongest repeatable fun: discovering relic functions, combining systems, escaping creatures, preparing return routes, mastering movement, economy choices, or story progression?

**Recommendation:** rank the top three. Implementation effort should follow that order.

**Answer:** combining systems, escaping creatures, preparing return routes

---

# C. Core loop, run structure, and progression

## C1 — Moment-to-moment gameplay loop — GDD BLOCKER

During an ordinary minute in Layer 1, what actions should the player cycle through? Describe movement, observation, item choice, interaction, avoidance/manipulation, and recovery.

**Recommendation:** describe a concrete minute of play rather than a feature list.

**Answer:** player walks, jumps, find a good place to place down a rope, climbs down that rope, encounter an enemy and use a relic to avoid that enemy.

## C2 — Full expedition loop — GDD BLOCKER

Confirm the intended long loop: prepare at surface, descend, explore, collect/use relics, prepare ascent, survive the Curse and enemies, sell/deliver, then descend farther. What may the player skip?

**Recommendation:** keep surface return optional in the short term but necessary for safe progression to the Blue Whistle.

**Answer:**

## C3 — Surface-return cadence — GDD BLOCKER

How much inventory/value should usually force or encourage a return? Should the player decide entirely, receive warnings, encounter capacity pressure, or reach explicit expedition milestones?

**Recommendation:** use capacity, health, supplies, and risk as soft pressure rather than a mandatory return timer.

**Answer:**

## C4 — Death and learning — GDD BLOCKER

What fiction and player-facing explanation connect death to permanently learned relic descriptions? Does death reset everything except knowledge exactly as current technical documents state?

**Recommendation:** preserve only knowledge across runs and explain the rule during the first death screen.

**Answer:**

## C5 — Winning and losing — GDD BLOCKER

Is death the only loss condition? Is interacting with the Layer 3 entrance the only win condition, even if the player skipped the optional Layer 2 quest and Moon Whistle?

**Recommendation:** keep death as the only run-ending failure and the entrance interaction as the build completion trigger.

**Answer:**

## C6 — Replay motivation — GDD BLOCKER

After one successful ending, what remains interesting: alternate section variations, east/west routes, item combinations, undiscovered descriptions, faster completion, or optional quest completion?

**Recommendation:** rely on seeded authored variation and knowledge discovery; do not add a new meta-upgrade system for replayability.

**Answer:**

## C7 — East/west route choice — GDD BLOCKER

Should east and west offer different risk, enemy composition, relic availability, traversal style, or only map variation? Can a player know the difference before committing?

**Recommendation:** give each route a readable identity while keeping both capable of supporting the complete progression loop.

**Answer:**

## C8 — Tutorial structure — GDD BLOCKER

Which systems must be explicitly taught, and which should be discovered: movement, cursor interaction, inventory, throwing, Rope, selling, knowledge, sound, sight, Curse, and whistle gates?

**Recommendation:** teach controls and mandatory progression; let relic effects be discovered through safe experimentation and unknown descriptions.

**Answer:**

## C9 — Information before danger — GDD BLOCKER

What warnings must appear before first exposure to theft, bleeding, poison, tracking, large knockback, Curse triggers, and an irreversible drop?

**Recommendation:** teach through safe early examples, environmental framing, or concise prompts instead of large tutorial panels.

**Answer:**

## C10 — Presentation-build path — GDD BLOCKER

For a short supervisor or presentation run, should debug/help features shorten delivery progress, reveal item descriptions, grant supplies, or provide a curated seed?

**Recommendation:** keep normal rules intact and provide a clearly labelled presentation/debug route rather than secretly changing production balance.

**Answer:**

---

# D. World, story, characters, and progression fiction

## D1 — Setting summary — GDD BLOCKER

What is the Abyss/place in this game's fiction, who lives around it, and why do people descend despite the danger?

**Recommendation:** provide one paragraph sufficient for artists and programmers; deeper lore can remain an appendix.

**Answer:**

## D2 — Player character identity — GDD BLOCKER

Who is the player character? Define name or role, age range, training, motivation, relationship to the surface community, and whether they speak.

**Recommendation:** keep biography short but make the expedition goal personal enough to support the ending.

**Answer:**

## D3 — Immediate objective at New Game — GDD BLOCKER

What exact task is the player given at the start: earn a Blue Whistle, recover relics, prove themselves, investigate something, reach Layer 3, or another goal?

**Recommendation:** state one immediate achievable goal and reveal deeper goals through progression.

**Answer:**

## D4 — Whistle meaning — GDD BLOCKER

What do Red, Blue, and Moon Whistles mean socially and mechanically? Why can frogs steal a whistle, and why can replacement services restore the earned tier?

**Recommendation:** distinguish physical whistle object from persistent earned rank in fiction and UI.

**Answer:**

## D5 — Relic origin and knowledge — GDD BLOCKER

What are relics, why are their functions initially unknown, who buys them, and why does experimental use reveal knowledge only after death unless the Info Book is used?

**Recommendation:** decide whether this is literal lore or a game abstraction and explain it consistently.

**Answer:**

## D6 — Surface shop character and role — GDD BLOCKER

Who operates the surface shop, what relationship do they have with the player, and how do they explain purchases, sales, delivery progress, and replacement equipment?

**Recommendation:** one character can handle all surface services to minimise dialogue and art scope.

**Answer:**

## D7 — Senior diver character — GDD BLOCKER

Who is the Layer 1 senior diver, why do they guard access, and why may the player fight or bypass them rather than only presenting the Blue Whistle?

**Recommendation:** make their rules and hostility understandable; do not portray a mandatory credential check as arbitrary combat.

**Answer:**

## D8 — Layer 2 shop gatekeeper/boss identity — GDD BLOCKER

Who is the optional quest authority at the Layer 2 shop? Why do they possess the Moon Whistle and powerful relic, and why are those rewards optional for reaching the Layer 3 entrance?

**Recommendation:** define this character separately from the Layer 1 senior diver and from the gauntlet creatures.

**Answer:**

## D9 — Quest relic and powerful relic — GDD BLOCKER

What are the quest relic and reward relic called, what do they look like, where is the quest relic found, and what exact gameplay advantage does the powerful relic provide in the gauntlet?

**Recommendation:** choose effects that reuse Layer 1 item/effect systems; avoid building a one-use framework only for the ending.

**Answer:**

## D10 — Ending scene and final message — GDD BLOCKER

What happens when the player interacts with the Layer 3 entrance? Define whether the player descends, stops at the threshold, receives text/credits, and whether optional Moon Whistle completion changes the ending text.

**Recommendation:** use one short ending sequence with an optional acknowledgement if the quest was completed.

**Answer:**

---

# E. Art, animation, UI, audio, and accessibility

## E1 — Overall visual direction — GDD BLOCKER

What visual mood, palette, lighting style, and environmental readability should distinguish the surface, Layer 1 open areas, Layer 1 caves, Layer 2, and the final gauntlet?

**Recommendation:** describe mood and readability goals, then link mood boards later rather than embedding unapproved art as fact.

**Answer:** bright and green cliff & meadows for layer 1 with dim caves, layer 2 upper side is an inverted forest where player traverse via upside down canopy, middle area is the layer 2 outpost/shop, and a dangerous forest, layer 2 bottom is a very dangerous area full of monsters

## E2 — Pixel-art scale contract — IMPLEMENTATION BLOCKER

Should all actor animations use 32×32 source cells and items use 16×16 sources, or may enemies and large creatures use larger canvases? Which integer scales are allowed at runtime?

**Recommendation:** keep world scale at 32 px per metre; allow larger enemy canvases while preserving nearest filtering and bottom-centre pivots.

**Answer:**  follow the recommendation

## E3 — Minimum enemy animation set — BEFORE PLAYTEST

For production enemies, which states require distinct animation before final art: idle, move, telegraph, attack, hit, carry, agitated, recover, and death?

**Recommendation:** require only states that communicate gameplay timing; placeholder shapes/colours may stand in for every state.

**Answer:** enemies only have these states: idle, moving, attack.

## E4 — Mechanical VFX language — GDD BLOCKER

How should players distinguish damage, force-only impacts, bleed, poison, slow, tracking, dazzle, sight obstruction, sound attraction, and Curse application?

**Recommendation:** assign each effect a consistent colour/icon/shape and avoid relying only on colour.

**Answer:** damage is done with flashing the player sprite with a red/white filter, while status effect is shown with an icon. some effects are screen filters

## E5 — HUD information hierarchy — GDD BLOCKER

Which information must always be visible, contextual, or inventory-only? Address health, money, weight, hotbar, whistle, delivery, active statuses, Curse distance/reference, item state, enemy marks, and autosave.

**Recommendation:** always show survival/action information; reveal detailed item and Curse numbers only when relevant.

**Answer:** health, hotbar, active status, autosave, enemy marks should all be visible on the main hud, the rest is shown in more detail in the inventory screen.

## E6 — Screen-obscuring effects and safety — IMPLEMENTATION BLOCKER

How intense may Hushcap overlay, Lantern Snail dazzle, Curse discoloration, camera shake, flashing, blur, or distortion become? Is a reduced-effects option required for presentation?

**Recommendation:** never use rapid full-screen flashes; provide tunable intensity and retain readable silhouettes/UI.

**Answer:** lingering effects that blocks vision will be a screen filter that makes seeing much harder, as if the user is seeing through the player's eyes, for flash effect its gonna be a quick fade to white with afterimage effects. no effect will block the hud or ui, reduced effect is not needed for jam

## E7 — Audio direction and gameplay priority — GDD BLOCKER

What overall music/ambience style is intended, and which gameplay sounds must remain unmistakable over it: enemy telegraphs, Rattlepod, snail scream, status application, Curse, item break, and gate progression?

**Recommendation:** implement one functional cue per important event before variations or decorative ambience.

**Answer:** audio has not been finalized

## E8 — Text style and accessibility — GDD BLOCKER

What reading level, tone, terminology, font size, dialogue speed, and text-skipping rules should both language versions use? Must important audio information also have visual feedback?

**Recommendation:** short plain-language text, player-advanced dialogue, and visual equivalents for gameplay-critical audio.

**Answer:** text and dialogue will be handled by another programmer

---

# F. Cross-system rules

## F1 — Actor categories and tags — IMPLEMENTATION BLOCKER

Which stable categories are required beyond `player`, `small_enemy`, `big_roamer`, and `boss`: neutral creature, gatekeeper, plant/hazard, projectile, loose item, breakable, or environmental source?

**Recommendation:** add only tags used by at least one current interaction and list each enemy's tags explicitly.

**Answer:** neutral creature is needed as a roaming entity on surface layer, an npc for layer 2 gatekeeper is needed, all hazard is lumped into the enemy category, breakable item spawner may be needed but depends on how the implementation is going to be

## F2 — Neutral creature hostility — IMPLEMENTATION BLOCKER

Are Lantern Snails and Thorn Blooms enemies, neutral creatures, hazards, or resources for targeting/faction purposes? Which attacks and effects may hit them?

**Recommendation:** treat classification and faction separately so a neutral creature can still receive damage, force, and agitation.

**Answer:** lantern snail and thorn bloom is considered a neutral hazard where they will not actively chase & attack the player but will attacm when the player comes close to them

## F3 — Source attribution and kill credit — IMPLEMENTATION BLOCKER

Must damage/status effects remember their original source for friendly-fire filtering, target retaliation, death feedback, and future scoring? How should environmental or source-less damage be represented?

**Recommendation:** carry source actor and species when available; allow null environmental source without special-case crashes.

**Answer:** follow the recommendation

## F4 — Item impact versus item special effect — IMPLEMENTATION BLOCKER

When a thrown item has both physical impact and a special effect, which occurs first? Can terrain impact activate an item, and can a body receive both impact damage and its status/area effect?

**Recommendation:** resolve physical impact once, then invoke the item behavior once with the same impact data.

**Answer:** most item can only be activated via primary use, when thrown in an activated state, it deals no thrown physical damage. when an item is thrown in an inactive state, it will deal physical damage. an item may have only an activated or only an inactivated state or have an inactivated state that can be activated

## F5 — Force without damage — IMPLEMENTATION BLOCKER

Can an impact apply knockback/agitation/status when damage is blocked by i-frames, same-species filtering, immunity, or zero damage? Which reactions should still happen?

**Recommendation:** keep force and agitation independent from accepted damage unless a specific attack says otherwise.

**Answer:**  follow the recommendation

## F6 — Target-priority hierarchy — IMPLEMENTATION BLOCKER

Lock the order among direct sight, proximity, spider mark, snail scream, direct repeated-sound target, ordinary high-priority sound, damage source, and scripted gate targets.

**Recommendation:** scripted combat target if active, direct sight/proximity, spider mark, allowed high-priority overrides, direct sound target, ordinary investigation.

**Answer:**  follow the recommendation, but this is not final and may need to be changed later, unsure yet

## F7 — Multiple simultaneous target overrides — IMPLEMENTATION BLOCKER

If two effects request different targets, should highest priority win, newest win on ties, or should a hard category order decide? What happens when the winning target becomes invalid?

**Recommendation:** compare explicit priority, then newest request, and immediately fall back to the next valid request.

**Answer:**  follow the recommendation

## F8 — Curse interaction with ordinary effects — IMPLEMENTATION BLOCKER

May Curse movement/healing/throw modifiers stack multiplicatively with item weight, poison/slow, Driftseed, inventory encumbrance, and prepared-item movement penalties? Is there a minimum controllable movement value?

**Recommendation:** define one modifier order and clamp final movement/throw values to safe minimums unless immobilisation is intentional.

**Answer:** immobilisation is intentional

## F9 — World-effect ownership and cleanup — IMPLEMENTATION BLOCKER

Should temporary clouds, resin patches, light fields, dazzle overlays, and itehments be owned by the layer runtime root, the item, or the affected actor? Which survive a layer transition or Continue?

**Recommendation:** temporary world effects belong to the current layer runtime root and are cleared on load unless explicitly marked persistent.

**Answer:** cloud and resin is an effect that applies when player is in an affected area so moving to another area should make it gone. in general, timed effects should be persistent accross load

## F10 — Shared interaction matrix — IMPLEMENTATION BLOCKER

For every Layer 1 enemy and implemented item/effect, should the later implementation documents contain an explicit matrix with `normal`, `immune`, `special reaction`, and `not applicable` cells?

**Recommendation:** yes. A matrix prevents item and enemy scripts from inventing contradictory one-off rules.

**Answer:**   follow the recommendation

---

# G. Layer 1 encounter and run pacing

## G1 — Layer 1 route identities — GDD BLOCKER

What encounter identity should east and west have? Specify which side favours caves/open air, theft, knockback, hazards, spiders, flyers, or safer resource gathering.

**Recommendation:** each route should emphasise different threats without excluding any progression-critical resource.

**Answer:** each route have 2 variations per section, each variaton is different. one emphasizes traversal and the other emphasizes enemy. but the west side will be more open while the east will be more compact. both should have the same difficulty but different hazard focus where the open areas are knockback & bug enemy, while compact area has lots of small enemies/hazards

## G2 — Enemy density per section — BEFORE PLAYTEST

How many ordinary enemies, hazards, ajor threats should an average section contain? What is the maximum simultaneous active count on this VM?

**Recommendation:** author density through placers and start below the maximum; tune only after a full-layer performance run.

**Answer:** will be managed by level designer

## G3 — Guaranteed versus random encounters — IMPLEMENTATION BLOCKER

Which enemies must appear at least once per run, which may be random, and which are fixed authored encounters? Is the large flyer guaranteed?

**Recommendation:** guarantee one safe teaching encounter for every essential mechanic; keep repeated threats probabilistic.

**Answer:** boss/gatekeepers are fixed, big enemies always spawn. others are random

## G4 — Encounter grouping — BEFORE PLAYTEST

Which species may intentionally spawn together? Identify desired combinations such as spider plus flyer, bird near a fall, Thorn Bloom near a narrow route, or frog near valuable loot.

**Recommendation:** introduce each enemy alone before using combinations that amplify it.

**Answer:** will be managed by level designer

## G5 — Ascent-specific encounter changes — GDD BLOCKER

Should enemies behave or spawn differently during ascent, or does ascent become harder only because the same living enemies, prepared hazards, lost resources, and Curse remain?

**Recommendation:** reuse persistent enemies and route state; do not spawn a hidden second encounter set unless clearly telegraphed.

**Answer:**  follow the recommendation

## G6 — Avoidance and non-combat completion — GDD BLOCKER

Must every Layer 1 enemy have a reliable avoidance, distraction, or traversal solution? Which threats may temporarily block progress until manipulated or defeated?

**Recommendation:** the complete descent and ascent must be possible without killing enemies, matching existing acceptance goals.

**Answer:**  follow the recommendation

## G7 — Rewards for risk — GDD BLOCKER

What rewards justify entering dangerous spaces: higher-value relics, rare sources, shortcuts, safer ascent routes, story, or Silver Weight chance? Should enemies ever guard guaranteed progression content?

**Recommendation:** reward danger with optional value or route advantage; never place the only required item behind an unavoidable unintroduced threat.

**Answer:**  follow the recommendation

## G8 — Recovery after a bad encounter — GDD BLOCKER

What escape opportunities should exist after theft, poison, bleeding, tracking, severe knockback, or loss of a key tool? When should the player be expected to retreat to the surface?

**Recommendation:** every persistent loss that can block progress needs a known recovery path or replacement service.

**Answer:** player can go to the surface, if they cant do that they may go to layer 2 shop, if they cant do that then the way out is game over. thats intentional

---

# H. Shared Layer 1 enemy contract

## H1 — Enemy definition fields — IMPLEMENTATION BLOCKER

Which fields must all production `EnemyDefinition` resources expose beyond current health, speed, damage, knockback, detection, layer, species, scene, and persistence? Consider tags, attack profile, sensing profile, audio/VFX hooks, fall immunity, and placer footprint.

**Recommendation:** keep common identity/tuning fields in the definition and enemy-specific values on the enemy scene/script.

**Answer:**  follow the recommendation

## H2 — Health and durability philosophy — BEFORE PLAYTEST

Should enemies be fragile but dangerous, durable obstacles, or different by role? Should low Multitool damage remain technically capable of killing every enemy?

**Recommendation:** all enemies remain killable, but big threats require impractical direct-tool commitment unless relics/environment help.

**Answer:**  follow the recommendation, enemies are durable but are different by role

## H3 — Common AI states — IMPLEMENTATION BLOCKER

Which shared concepts must every relevant enemy support: idle, patrol, investigate, alert/telegraph, attack, recover, chase, search, flee/retreat, return, carry, and dead?

**Recommendation:** define state meanings in the implementation document, but each enemy implements only states it uses.

**Answer:**   follow the recommendation

## H4 — Patrol bounds and ledges — IMPLEMENTATION BLOCKER

How should ground enemies behave at authored patrol bounds, cliffs, Rope openings, section seams, and blocked paths? May they jump or climb?

**Recommendation:** no general navigation system; use authored bounds and simple ground/ledge probes per enemy.

**Answer:** enemies cannot climb, but can jump if their pathfinding system allows it

## H5 — Aggro, leash, and return — IMPLEMENTATION BLOCKER

Can enemies chase across section seams? How far from their placer may they travel, and when do they abandon a target and return?

**Recommendation:** allow seamless nearby pursuit but enforce authored leash/return so encounters do not migrate through the whole layer.

**Answer:**  follow the recommendation except for big enemy, as big enemies can follow player through layers

## H6 — Attack telegraph standard — IMPLEMENTATION BLOCKER

What minimum information must every damaging attack show before becoming active: animation pose, colour, sound, aim line, projectile preview, or timing pause? May any Layer 1 attack be instantaneous?

**Recommendation:** all high-damage or high-knockback attacks require visible and audible telegraph; only minor reactions may be fast.

**Answer:**  follow the recommendation, mostly by animation pose. also an exclamation mark on top of the player when an enemy wants to attack is near a player

## H7 — Attack cancellation — IMPLEMENTATION BLOCKER

Can damage, force, slow, loss of sight, Hushcap obstruction, or target invalidation cancel an enemy telegraph/attack? If cancelled, does cooldown still begin?

**Recommendation:** death and explicit stun cancel; ordinary damage does not. Target loss after aim lock does not redirect the current attack.

**Answer:**  follow the recommendation

## H8 — Enemy hit reactions — IMPLEMENTATION BLOCKER

What reactions are shared after damage, heavy impact, agitation, slow, poison, or friendly fire: flash, recoil, target source, drop carried item, interrupt, or ignore?

**Recommendation:** keep visual feedback shared, but state changes remain enemy-specific.

**Answer:** flash, knockback, and target source. but tuere will be enemy specific interaction 

## H9 — Enemy status eligibility — IMPLEMENTATION BLOCKER

Which actor tags can receive bleed, poison, slow, incapacitation, tracking, Driftseed, Curse effects, and dazzle? Are plants and neutral creatures valid?

**Recommendation:** create an explicit eligibility table; do not infer immunity from sprite size or scene name.

**Answer:**  follow the recommendation

## H10 — Enemy death and drops — IMPLEMENTATION BLOCKER

Confirm that normal enemy death drops no relic. May enemies drop stolen/carried items, physical projectiles, ordinary rocks, or nothing? What happens to an active attack on death?

**Recommendation:** carried real items always drop safely; temporary projectiles/attack hitboxes clean up; no random relic death drops.

**Answer:**  follow the recommendation, but thorn bloom thorns thats stuck in the ground stays after plant is dead

## H11 — Offscreen activation and timers — IMPLEMENTATION BLOCKER

When a section becomes inactive, should AI, attack cooldowns, status durations, sound memory, and animations pause? What resumes when the section reactivates?

**Recommendation:** stop AI/scan/animation processing; preserve simple remaining persistent durations only where gameplay requires it.

**Answer:**  follow the recommendation

## H12 — Enemy save contract — IMPLEMENTATION BLOCKER

Besides alive/dead and health, which enemy-specific state must survive Continue: carried item, snail harvest state, Thorn Bloom charges, scream cooldown, or gate state? Which AI states must always reset?

**Recommendation:** save ownership and lasting resource state; reset target, path, telegraph, projectile, chase, and transient stun state.

**Answer:** carried item must be saved, snail is changed so refer to the change, targeting status is also saved. other than that things can be reset really its fine

---

# I. Tongue amphibian

## I1 — Encounter role and normal behaviour — GDD BLOCKER

Is the amphibian mainly a thief, territorial obstacle, ambusher, pursuer, or resource-pressure enemy? Where does it wait, patrol, and prefer to attack?

**Recommendation:** make theft its defining threat; ordinary movement and damage should support retrieval rather than overshadow it.

**Answer:**  follow the recommendation. the frog is a relatively harmless enemy on its own, but when paired with other enemy it becomes dangerous by disabling player's options for actions

## I2 — Detection and attack decision — IMPLEMENTATION BLOCKER

Does it use sight, sound, proximity, or all three? At what relative range does it investigate, chase, stop, aim its tongue, and give up?

**Recommendation:** reuse shared sight/sound components, approach to a configured tongue range, then stop for a readable telegraph.

**Answer:** it relies on sight more than sound, that means the sound detector has a hugher minimum priority value and sight is used more.  follow the recommendationa

## I3 — Tongue attack form — IMPLEMENTATION BLOCKER

Is the tongue an extending hitbox, ray/line query after telegraph, or physical projectile? Can terrain, Hushcap, another enemy, or a loose item block it? Does a miss leave recovery time?

**Recommendation:** use a short-lived extending/line hitbox that stops on terrain and locks its aim at telegraph start.

**Answer:**  follow the recommendation. it can do another attack after an adjustable cooldown. the hitbox should extend and retract, the size should be adjustable. it doesnt stop when going through the same species but will stop on another enemy/terrain/player. frog primarily targets an item on the ground

## I4 — Theft impact details — IMPLEMENTATION BLOCKER

On a successful tongue hit, does the player also take damage, exactly one second of slow, force, or only theft? If inventory is empty, does the attack still slow/damage? Can i-frames block theft?

**Recommendation:** theft is independent of damage i-frames; apply the documented one-second slow, low/no damage, and clear feedback about the stolen item.

**Answer:**  follow the recommendation, when the frog successfuly steals an item, it does not deal damage.

## I5 — Retreat and carried-item recovery — IMPLEMENTATION BLOCKER

Where does the amphibian retreat, how long does it carry the item, and can it escape permanently? Does touching the dropped item immediately recover it, and what happens if inventory is full?

**Recommendation:** retreat toward its placer within a leash, never delete the item, and drop a normal persistent world item after any accepted hit/impact.

**Answer:**

## I6 — Edge cases and systemic reactions — IMPLEMENTATION BLOCKER

What happens if the amphibian falls out of bounds while carrying an item, dies during the tongue attack, is slowed by resin, hears Rattlepod, is hit by another species, or is struck by Silver Weight? Is it tagged `small_enemy`?

**Recommendation:** tag it small; recover carried items at its safe placer before applying ordinary out-of-bounds/death cleanup.

**Answer:**

---

# J. Knockback bird

## J1 — Flock size and encounter role — GDD BLOCKER

Does one bird attack alone, or do birds always operate as a flock? What group size teaches the repeated-hit mechanic without creating unavoidable chain hits?

**Recommendation:** first encounter uses one bird; later encounters use small authored groups with staggered attack timing.

**Answer:**

## J2 — Flight and target acquisition — IMPLEMENTATION BLOCKER

Does the bird follow a fixed aerial patrol, perch, circle a region, or roam freely? Does it use sight, sound, proximity, or reactions to other birds?

**Recommendation:** use an authored flight region plus shared sight; sound may draw it to investigate but should not immediately produce a swoop through terrain.

**Answer:**

## J3 — Swoop sequence — IMPLEMENTATION BLOCKER

Define the states from acquiring a target through telegraph, dive, active hitbox, missed pass, pull-up, and cooldown. Is direction locked before the dive?

**Recommendation:** lock target position at telegraph end, perform one committed pass, then recover outside immediate melee range.

**Answer:**

## J4 — Individual hit result — IMPLEMENTATION BLOCKER

Does every bird hit deal zero damage plus knockback until the group threshold, or small damage and knockback plus bonus threshold damage? How strong should vertical versus horizontal force be?

**Recommendation:** individual hits primarily apply force; threshold adds damage so the flock identity stays clear.

**Answer:**

## J5 — Shared recent-hit window — IMPLEMENTATION BLOCKER

How many bird hits within how many seconds cause damage? Is the counter shared by all Layer 1 knockback birds, only birds from the same placer/flock, or each species variant? Does taking threshold damage reset it?

**Recommendation:** share one counter across the bird species, reset after threshold damage, and expose count/window/damage for tuning.

**Answer:**

## J6 — Reactions and failure safety — IMPLEMENTATION BLOCKER

Can birds be slowed, poisoned, distracted, blocked by Hushcap, killed by Silver Weight, or damaged by Thorn needles? What happens if knockback sends the player out of bounds?

**Recommendation:** tag birds small; shared reactions work normally, while authored encounter placement must keep a recoverable safe position.

**Answer:**

---

# K. Thorn Bloom

## K1 — Classification and visual role — GDD BLOCKER

Is Thorn Bloom a killable enemy, neutral defensive plant, harvestable resource, or persistent environmental hazard? Should players initially mistake it for scenery?

**Recommendation:** classify it as a neutral killable hazard with a strong readable armed/agitated state.

**Answer:**

## K2 — Agitation triggers — IMPLEMENTATION BLOCKER

What agitates it: any damage, physical impact, nearby movement, sound priority, player proximity, another needle, or selected events? Does agitation build gradually or trigger immediately?

**Recommendation:** physical impact/damage triggers immediately; ordinary sound alone does not, unless a specific item is meant to trigger it.

**Answer:**

## K3 — Needle firing pattern — IMPLEMENTATION BLOCKER

How many needles fire, in what directions, with what telegraph and delay? Does it aim at the source, fire radially, use fixed authored directions, or continue firing over time?

**Recommendation:** use a readable wind-up followed by a small radial/fan burst; keep count and spread in the scene Resource.

**Answer:**

## K4 — Needle collision and persistence — IMPLEMENTATION BLOCKER

Do needles fly straight or use gravity? Do they stop, stick, disappear, or become hazards after terrain/body impact? How many minutes should they remain, and may the player pick them up?

**Recommendation:** temporary non-pickup projectiles stick to terrain as visible hazards, then expire; do not save them through Continue.

**Answer:**

## K5 — Needle damage and bleed — IMPLEMENTATION BLOCKER

How much immediate damage and what bleed package should a needle apply? Can one burst apply bleed repeatedly, and do player i-frames block later needles while force/status still applies?

**Recommendation:** one accepted hit applies immediate damage plus one bleed application; same burst should not stack accidental repeated hits.

**Answer:**

## K6 — Cooldown, death, and interactions — IMPLEMENTATION BLOCKER

Can a Bloom fire repeatedly, run out of needles, calm down, or remain armed? What happens when it is killed, slowed, poisoned, hit by friendly fire, covered by Hushcap, or struck by Silver Weight?

**Recommendation:** give it a repeatable cooldown and no movement; death cancels wind-up but already-fired needles remain.

**Answer:**

---

# L. Lantern Snail creature

## L1 — World-creature activity — GDD BLOCKER

Does a calm world snail remain stationary, crawl, hide, react to light, or attempt to flee? Where should players find it, and what makes it feel alive before interaction?

**Recommendation:** keep movement minimal for scope; use light, idle motion, and reaction animation to communicate life.

**Answer:**

## L2 — Light behaviour — IMPLEMENTATION BLOCKER

How large and bright is its passive light? Does it illuminate while calm, carried in inventory, selected in hotbar, deployed, agitated, and cooling down?

**Recommendation:** light is active in world and when held/selected, not while buried in backpack unless the design explicitly wants inventory-wide light.

**Answer:**

## L3 — Agitation sources and wind-up — IMPLEMENTATION BLOCKER

What agitates a snail: primary use, direct damage, sufficient impact speed, nearby enemy attack, force without damage, or repeated handling? How long is the pre-scream warning?

**Recommendation:** primary use and hard impacts agitate; show a short visible tremble before the scream.

**Answer:**

## L4 — Scream sound event — IMPLEMENTATION BLOCKER

What radius, priority, pulse count, and target-override duration should the scream request? Can it override direct sight, ordinary sound targets, or an active spider mark?

**Recommendation:** one high-priority event attracts the large flyer, but spider mark remains higher priority until it expires.

**Answer:**

## L5 — Dazzle behaviour — IMPLEMENTATION BLOCKER

Who is dazzled: only the player holding/near the snail, all nearby actors, or sight-based enemies? Is dazzle a visual overlay, detection penalty, control penalty, or status effect?

**Recommendation:** begin as a short player-facing visual effect with no control loss; make intensity distance-based and accessibility-safe.

**Answer:**

## L6 — Harvest, death, and redeployment — IMPLEMENTATION BLOCKER

Confirm the 2 HP first-harvest and 1 HP redeployed rules. Can non-Multitool damage accidentally kill an unharvested snail? Does its corpse/drop anything, and can a first harvest occur during agitation?

**Recommendation:** only a valid Multitool utility hit converts the first snail; other lethal damage kills it without an item reward.

**Answer:**

---

# M. Cave spider

## M1 — Movement and habitat — GDD BLOCKER

Does the spider walk on floors only, cling to walls/ceilings, remain in a nest, or reposition between authored points? Where should it appear relative to caves and open routes?

**Recommendation:** use floor/wall authored perches for jam scope; do not build arbitrary surface-crawling navigation unless essential.

**Answer:**

## M2 — Detection and preferred range — IMPLEMENTATION BLOCKER

Does it use sight, sound, proximity, or web vibration? Does it keep distance, retreat, hold a perch, or chase after firing?

**Recommendation:** use shared sight/sound, hold an authored firing area, and reposition only within simple bounds.

**Answer:**

## M3 — Projectile sequence — IMPLEMENTATION BLOCKER

Define telegraph, aim locking, projectile speed, gravity, cooldown, maximum range, and terrain response. Can the shot be blocked by enemies or loose objects?

**Recommendation:** lock the player's position at telegraph start, use a visible straight projectile, and stop on first valid collision.

**Answer:**

## M4 — Combined hit payload — IMPLEMENTATION BLOCKER

Should one hit always apply small direct damage, slow, poison, and tracking mark together, or may some effects require separate attacks/chances?

**Recommendation:** one readable projectile applies the documented complete package; avoid random effect omission during first implementation.

**Answer:**

## M5 — Poison, slow, and mark timing — IMPLEMENTATION BLOCKER

Beyond poison's locked total of 25 damage over 10 seconds, what slow strength/duration and tracking-mark duration are intended? How do repeated hits refresh or stack each effect?

**Recommendation:** refresh slow and mark; define poison stacking separately in the effects section.

**Answer:**

## M6 — Flyer relationship and systemic reactions — IMPLEMENTATION BLOCKER

Does the spider communicate with any large flyer anywhere in the active layer, only one in the same encounter/route, or the nearest flyer? Is the spider `small_enemy`, and how does it respond to Hushcap, resin, Rattlepod, snail scream, friendly fire, and Silver Weight?

**Recommendation:** target only valid active flyers in the same route/encounter scope; tag the spider small.

**Answer:**

---

# N. Large Layer 1 flyer

## N1 — Number and territory — GDD BLOCKER

Does “one major open-air threat on the player's side” mean one flyer per east/west route, one total active flyer that changes side, or one per selected open-air section?

**Recommendation:** one persistent flyer per route, with authored territories that prevent both attacking the player together at the crossing.

**Answer:**

## N2 — Normal movement — IMPLEMENTATION BLOCKER

Does it patrol fixed points, circle a territory, perch, or roam? How does it avoid terrain and return after losing a target without full navigation/pathfinding?

**Recommendation:** use authored patrol points/rectangles plus obstruction probes; do not build a general flight navigation system.

**Answer:**

## N3 — Detection profile — IMPLEMENTATION BLOCKER

What normal/aggravated sight ranges and angles distinguish it from smaller enemies? Does it hear ordinary sounds, only high-priority sounds, snail screams, or spider marks?

**Recommendation:** strong long-range sight in open air, high minimum sound priority, and explicit snail/mark target overrides.

**Answer:**

## N4 — Attack form and 75 damage — IMPLEMENTATION BLOCKER

Is its attack a dive, bite, grab/drop, projectile, or sweeping pass? Does the documented 75 damage also apply knockback, and how long is its telegraph/recovery?

**Recommendation:** use one telegraphed committed dive/pass with 75 damage and controlled force; no grab system for first implementation.

**Answer:**

## N5 — Obstruction, caves, and lost target — IMPLEMENTATION BLOCKER

Can the flyer enter caves or narrow openings? What obstacle clearance makes a space safe, and should it wait outside, search, or immediately return after line of sight breaks?

**Recommendation:** authored cave ceilings/openings block pursuit; flyer searches last-known position within territory, then returns.

**Answer:**

## N6 — Threat classification and counterplay — IMPLEMENTATION BLOCKER

Is it tagged `big_roamer`, how much health should it have relative to ordinary enemies, and which items/effects meaningfully counter it? Can it be slowed, poisoned, distracted, or knocked back, and does Silver Weight only deal normal impact?

**Recommendation:** tag it big; allow shared effects with reduced/explicit response rather than blanket immunity, and do not allow Silver Weight instant kill.

**Answer:**

---

# O. Senior diver gatekeeper

## O1 — Gate and actor ownership — IMPLEMENTATION BLOCKER

Is the senior diver physically the gate interaction target, a separate actor beside a `WorldGate`, or both? Which node owns pass state, dialogue completion, and collision opening?

**Recommendation:** keep gate/progression state on `WorldGate`; senior diver requests it through a small public API.

**Answer:**

## O2 — Initial disposition and denial — GDD BLOCKER

Is the diver neutral until attacked, automatically hostile to a Red Whistle holder approaching the gate, or willing to warn and block first? What exact behaviour follows a denied interaction?

**Recommendation:** provide a warning/denial interaction before hostility so the credential rule is understandable.

**Answer:**

## O3 — Blue Whistle passage — IMPLEMENTATION BLOCKER

Does possession of Blue Whistle permanently open the gate, open it only while present, trigger one dialogue, or make the diver non-hostile? What if the physical whistle was stolen but the tier remains earned?

**Recommendation:** check earned whistle tier, persist gate passage once granted, and let replacement restore the physical item separately.

**Answer:**

## O4 — Hostility triggers and reset — IMPLEMENTATION BLOCKER

What makes the diver attack: player damage, forced bypass, entering a restricted zone, stealing, or repeated denial? Can hostility be reset by leaving, presenting Blue Whistle, using an item, or loading Continue?

**Recommendation:** attack/forced trespass causes lasting encounter hostility; a valid Blue Whistle interaction should still provide one safe de-escalation path unless the diver is dead.

**Answer:**

## O5 — Slow movement and fast attack — IMPLEMENTATION BLOCKER

What attack does the diver use, what makes it fast but fair, and how do slow movement, telegraph, active hitbox, damage, force, recovery, and chase range work together?

**Recommendation:** use one short-range committed strike with clear wind-up, small active window, and longer recovery.

**Answer:**

## O6 — Bypass, defeat, and item reactions — IMPLEMENTATION BLOCKER

Which non-Blue-Whistle solutions are intended: distraction, Hushcap, resin, Driftseed, knockback, Rope route, direct defeat, or another relic? Does killing the diver permanently open the gate, and is the diver tagged boss/gatekeeper rather than small?

**Recommendation:** Blue Whistle and defeat are reliable paths; systemic bypasses work when existing mechanics naturally permit them, without bespoke puzzle scripting.

**Answer:**

---

# P. Shared Layer 1 item contract

## P1 — Exact Layer 1 implementation roster — IMPLEMENTATION BLOCKER

Which items must be implemented in this work package? Confirm whether it includes all sixteen manifest entries, only items obtainable/usable in Layer 1, or only unfinished content after Rope, Multitool, Throwable Rock, and debug foundations.

**Recommendation:** implement/regression-test every item available before entering Layer 2; treat Moon Whistle and the undesigned quest/reward relics as later progression content.

**Answer:**

## P2 — Item identity and naming freeze — IMPLEMENTATION BLOCKER

Are the current IDs and English display names final? List any rename needed for Rope, whistles, Multitool, Bandage, Info Book, Numbing Pill, Sun Sphere, Throwable Rock, Lantern Snail, Rattlepod, Hushcap, Cling Resin, Driftseed, and Silver Weight.

**Recommendation:** freeze stable IDs before adding saves; display names may still be localised without changing IDs.

**Answer:**

## P3 — Primary/secondary design rule — IMPLEMENTATION BLOCKER

Should every item explicitly provide two behaviors, or may it inherit a generic throw secondary? For supply items, should an ordinary throw remain possible even when it has no special thrown effect?

**Recommendation:** each definition explicitly assigns primary and secondary behaviors; generic throw is a reusable Resource, not a hidden inventory fallback.

**Answer:**

## P4 — Activation, prepared state, and throwing — IMPLEMENTATION BLOCKER

For items activated before throwing, should primary move one unit into a prepared/active instance, with secondary throwing that same instance? May the player switch hotbar slots while it remains active?

**Recommendation:** stateful activation separates one unit, preserves its state, and continues independently when switching slots only if the item's rules require it.

**Answer:**

## P5 — Consumption moment and rollback — IMPLEMENTATION BLOCKER

Should an item be consumed on button press, successful spawn, valid target application, impact, or effect completion? What happens if scene insertion, target validation, or world bounds fail?

**Recommendation:** consume only after the irreversible world/status operation succeeds; failed actions retain the item and return feedback.

**Answer:**

## P6 — Stack compatibility and instance state — IMPLEMENTATION BLOCKER

Which states prevent stacking: activation, remaining duration/charges, durability, cooldown, harvest history, or attachment? May identical non-default states stack?

**Recommendation:** only stateless/default instances stack; any mutable per-instance state uses quantity one unless equality is explicitly proven safe.

**Answer:**

## P7 — World persistence classes — IMPLEMENTATION BLOCKER

Which item-created objects survive Continue: ordinary dropped items, active Rattlepod, deployed snail, Silver Weight, active Sun Sphere, attached Driftseed, placed Rope, or none of the temporary effects?

**Recommendation:** real retrievable items persist; short-lived fields/clouds/projectiles clear safely; persistent status remaining time lives on the affected actor.

**Answer:**

## P8 — Item effects on enemies and world objects — IMPLEMENTATION BLOCKER

Should every item use shared reactions only, or are any one-off interactions required? Confirm whether items may affect breakables, plants, projectiles, other thrown items, gatekeepers, neutral creatures, and terrain.

**Recommendation:** document explicit exceptions, otherwise use damage, force, status, sound, sight obstruction, agitation, and target override contracts.

**Answer:**

## P9 — Knowledge, use counting, and unknown feedback — IMPLEMENTATION BLOCKER

What counts as one discovery use: activation, valid effect, impact, full duration, or target affected? Should invalid uses reveal anything? Confirm individual thresholds for each relic.

**Recommendation:** count only successful signature effects; keep thresholds small and data-driven.

**Answer:**

## P10 — Item completion boundary — IMPLEMENTATION BLOCKER

For “almost finished,” must every item have debug grant, placeholder icon/world visual, normal and invalid-use feedback, save/load behavior, shop values, discovery, enemy interactions, tests, audio/VFX hooks, and Inspector tuning before final art and balance?

**Recommendation:** yes; defer only final sprites/animations/audio files and manual numeric fine tuning.

**Answer:**

---

# Q. Item-specific decisions

## Q1 — Existing foundation regression scope — IMPLEMENTATION BLOCKER

Should Rope, Multitool, Throwable Rock, and weighted throw systems remain functionally unchanged except for shared API integration and bug fixes discovered by the new content?

**Recommendation:** treat them as regression baselines; do not redesign working mechanics during content implementation.

**Answer:**

## Q2 — Rope inventory details — BEFORE PLAYTEST

Archived specs say stack 8, current Resource says stack 4, and each Rope weighs 8. What final provisional stack limit, shop stock, and guaranteed starting availability should item implementation use?

**Recommendation:** choose values through content planning, not code; keep current mechanics unchanged.

**Answer:**

## Q3 — Whistle object behaviour — IMPLEMENTATION BLOCKER

Do Red, Blue, and Moon Whistles have any primary/secondary action, sound event, or usable animation? When stolen, how does a dedicated-slot whistle become a carried/dropped world item and return to the slot?

**Recommendation:** no active action for this build; theft temporarily empties the physical slot while earned tier remains in `GameSession`.

**Answer:**

## Q4 — Multitool content responsibilities — IMPLEMENTATION BLOCKER

Beyond its implemented thrust, which new targets must support Multitool utility interaction: relic rocks, first-harvest snail, growth nodes, gates, or enemy-carried items? Does it directly break every harvest source?

**Recommendation:** add utility interfaces to targets; do not add item-ID checks to Multitool behavior.

**Answer:**

## Q5 — Throwable Rock final rules — BEFORE PLAYTEST

Should primary remain disabled, inspect/aim, or another action? Which hazards can rock impact agitate, may it ricochet, and should terrain/body impacts emit distinct sound events?

**Recommendation:** primary disabled with feedback; secondary retains generic throw, and impact may agitate plus emit one data-driven sound.

**Answer:**

## Q6 — Bandage use and healing lifecycle — IMPLEMENTATION BLOCKER

Can Bandage be used at full health when bleeding, at damaged health without bleeding, or only when either benefit applies? Define healing duration, tick cadence, repeated-use stacking, save behavior, and secondary throw.

**Recommendation:** valid if health is missing or bleed exists; remove bleed immediately, apply one refreshable persistent heal-over-time, and use generic throw secondary.

**Answer:**

## Q7 — Info Book scope and repeated use — IMPLEMENTATION BLOCKER

Does Info Book unlock only implemented relics, every catalog item, or future hidden items too? Can it be bought/used after all descriptions are known, and does secondary throw remain available?

**Recommendation:** unlock all items marked discoverable in the catalog, prevent wasteful use/purchase when none remain, save meta immediately, and allow ordinary throw.

**Answer:**

## Q8 — Numbing Pill suppression lifecycle — IMPLEMENTATION BLOCKER

Confirm that each use adds 300 seconds, does not remove old Curse effects/stacks, and uses ordinary throw as secondary. Does the timer run during inventory, dialogue, pause, menu, and inactive sections?

**Recommendation:** gameplay and inventory advance it; pause/menu stop it; remaining time persists through layer transition and Continue.

**Answer:**

## Q9 — Sun Sphere activation and throw — IMPLEMENTATION BLOCKER

Does primary activate it in the player's hand, deploy it at the player's feet, or create a held light? Does unactivated secondary throw activate immediately, only on first impact, or remain inert until primary activation?

**Recommendation:** primary prepares/activates one sphere; active secondary throws it. An unactivated throw stays physical until impact, then activates once.

**Answer:**

## Q10 — Sun Sphere lifetime and persistence — IMPLEMENTATION BLOCKER

Can an active sphere be picked up, moved, extinguished, or damaged? Does it become inert before disappearing, and must remaining light time survive Continue?

**Recommendation:** consumed deployment, no pickup after activation, fade then disappear, and clear active temporary light safely on load.

**Answer:**

## Q11 — Lantern Snail inventory behaviour — IMPLEMENTATION BLOCKER

Does a calm snail provide light in backpack, only selected hotbar, or only when deployed? Does primary deploy, squeeze while held, or both? How does secondary throw preserve scream cooldown/agitation state?

**Recommendation:** selected snail provides light; primary prepares/squeezes it, secondary throws the same living instance, and deployed state persists as a real item-creature conversion.

**Answer:**

## Q12 — Rattlepod exact active-state flow — IMPLEMENTATION BLOCKER

Does the first pulse occur immediately or after one second? Can an active pod be dropped, picked up, sold, or returned to inventory? Do multiple pods' pulses combine, and does impact add a separate sound?

**Recommendation:** pulse once per second including the first after one second; active pod cannot be recovered/sold and disappears after the fifth pulse.

**Answer:**

## Q13 — Hushcap deployment — IMPLEMENTATION BLOCKER

Does primary burst at the player and secondary create a cloud only on impact? Which surfaces/targets trigger it, can clouds overlap, and does being inside affect target acquisition or only line segments passing through?

**Recommendation:** one consumed cloud at player or first impact; overlapping clouds do not multiply visual penalty, and sight rays crossing any cloud are blocked.

**Answer:**

## Q14 — Cling Resin patch rules — IMPLEMENTATION BLOCKER

Define primary patch position/size versus thrown patch size, valid surfaces, duration, slow strength, overlap rule, affected actors, and whether projectiles/ThrownItems lose velocity while inside.

**Recommendation:** primary creates a small ground patch, thrown impact creates a larger patch, same effect refreshes rather than stacks, and lightweight moving payloads receive a velocity multiplier.

**Answer:**

## Q15 — Driftseed attachment and valid targets — IMPLEMENTATION BLOCKER

Confirm only player and boss/gatekeeper are valid. Does primary attach to player, secondary throw attach to the gatekeeper, and a miss remain recoverable or get consumed? How do reapplication, duration, visual attachment, and save work?

**Recommendation:** primary self-applies; a valid thrown hit applies to gatekeeper; misses become recoverable until valid impact; reapplication refreshes and remaining time persists.

**Answer:**

## Q16 — Silver Weight activation, throws, and value — IMPLEMENTATION BLOCKER

Press-only input conflicts with the archived “hold primary” rule. Should primary toggle a heavy stance, apply while selected, or last for a fixed duration? Does durability decrease on throw, first valid impact, or any terrain collision; may it multi-hit; what provisional sale formula applies at durability 1?

**Recommendation:** primary toggles prepared heavy state until secondary throw/switch; decrement on first meaningful impact, allow each target once, break after the second throw's impact, and scale sale value by remaining durability.

**Answer:**

---

# R. Curse of Ascension

## R1 — Original lore versus direct adaptation — GDD BLOCKER

Should this system use the names and fiction of Made in Abyss directly, or only adapt the idea of an upward-movement hazard into original lore? Which canon concepts—force field, depth-based symptoms, ten-metre threshold, safe pockets—exist in this game?

**Recommendation:** identify inspiration in credits/GDD, then define every gameplay rule independently so players do not need outside knowledge.

**Answer:**

## R2 — Intended gameplay purpose — GDD BLOCKER

What should the Curse make the player do differently: stop and rest, prepare medication, choose safer ascent paths, build Ropes, reduce carried value, accept temporary impairment, or race home? Is it primarily tension, resource cost, pacing, or punishment?

**Recommendation:** choose one primary and one secondary purpose; avoid effects that merely make controls randomly unpleasant without a planning response.

**Answer:**

## R3 — Who and what the Curse affects — IMPLEMENTATION BLOCKER

Does the Curse affect only the player, all humans, gatekeepers, neutral creatures, enemies displaced upward, carried Lantern Snails, or any living actor? Are world items/projectiles never affected?

**Recommendation:** implement player-only for jam scope unless an enemy interaction is essential to the design.

**Answer:**

## R4 — Trigger distance and world units — IMPLEMENTATION BLOCKER

Current `CurseProfile` defaults to 360 px, one viewport height, while 10 metres at 32 px/metre is 320 px. Which distance should be authoritative, and may each layer use a different threshold?

**Recommendation:** use a world-space pixel distance stored per profile, independent of viewport; start at 320 px if the ten-metre reference matters.

**Answer:**

## R5 — Depth-reference algorithm — IMPLEMENTATION BLOCKER

Should the tracker store the deepest world Y reached and trigger when the player's vital/body reference rises by the threshold, or accumulate every upward movement regardless of later descent? After a trigger, does the reference move to the trigger height or stay at deepest depth?

**Recommendation:** store a reference depth; trigger at each threshold crossed and advance the reference upward by exactly one threshold.

**Answer:**

## R6 — Ten-second stillness reset — IMPLEMENTATION BLOCKER

Existing design says staying sufficiently still for ten seconds resets reference to current depth. Does vertical stillness alone count while walking horizontally? How much movement tolerance is allowed, and is repeatedly resting every threshold an intended safe strategy?

**Recommendation:** use vertical movement tolerance, reset only while grounded/climbing safely, and treat staged resting as intended counterplay.

**Answer:**

## R7 — Which upward movement counts — IMPLEMENTATION BLOCKER

Should jumping, Rope climbing, enemy knockback, moving platforms, scripted transitions, teleports, out-of-bounds recovery, and loading into a higher position count as ascent? Existing acceptance notes say ordinary jumping must not trigger the Curse.

**Recommendation:** count continuous world traversal, but grant transition/load/recovery grace and set threshold above normal jump height.

**Answer:**

## R8 — Multiple thresholds and rapid ascent — IMPLEMENTATION BLOCKER

If one frame/teleport crosses multiple thresholds, should all Curse applications occur, one occur with debt retained, or extra distance be discarded? Is there a minimum interval between applications?

**Recommendation:** apply each legitimately crossed threshold with a short queued presentation interval; ignore exempt teleports instead of discarding ordinary ascent debt.

**Answer:**

## R9 — Layer package selection — IMPLEMENTATION BLOCKER

Which package applies when ascent begins in Layer 2 but crosses into Layer 1: the layer at the deepest reference, current player position at each trigger, or the harsher layer touched? Does Layer 2 include all Layer 1 symptoms plus its own?

**Recommendation:** use the layer at the trigger position and explicitly define whether packages replace or extend one another.

**Answer:**

## R10 — Safe zones, seams, and transitions — IMPLEMENTATION BLOCKER

Are surface, shops, gate rooms, section seams, and Layer 3 entrance Curse-free? On layer transition/Continue, should reference restore exactly, reset to arrival, or receive temporary grace?

**Recommendation:** shops/surface reset safely; seamless section seams do nothing; explicit layer transitions restore reference with short no-trigger grace.

**Answer:**

## R11 — Numbing Pill and ascent debt — IMPLEMENTATION BLOCKER

While suppression is active, does the reference continue tracking descent/ascent? When suppression ends, does accumulated ascent trigger immediately, get discarded, or establish a new reference at current depth?

**Recommendation:** keep updating deepest/current reference but consume suppressed thresholds without effects; suppression ending must not cause delayed burst punishment.

**Answer:**

## R12 — Layer 1 Curse package — IMPLEMENTATION BLOCKER

Define what “random maximum-movement-speed modification,” reduced healing, reduced maximum throwing distance, and screen discoloration mean. Are modifiers always penalties, what ranges/durations apply, and do repeated triggers refresh, reroll, stack, or replace each component?

**Recommendation:** each trigger rolls penalties within profile ranges, refreshes one Layer 1 Curse effect, and never increases speed or reduces control below a safe clamp.

**Answer:**

## R13 — Layer 2 Curse package — IMPLEMENTATION BLOCKER

Confirm health-cap reduction of 10% base health per application to a 50% maximum. Does current health clamp immediately, or only future healing? What chance causes the 0.5-second stop, does it detach Rope/cancel actions, and do throwing/discoloration penalties stack?

**Recommendation:** cap healing only without deleting current health; explicit stop uses control lock but does not cancel item state unless stated; health-cap stacks persist for the run.

**Answer:**

## R14 — Recovery, feedback, persistence, and debug — IMPLEMENTATION BLOCKER

When do temporary Curse penalties end: fixed duration, rest, descent, surface return, death, or medicine? Which HUD/VFX/audio warn about reference progress and application? What exact tracker/profile/effect state saves, and which debug controls are required?

**Recommendation:** save reference, layer, suppression, health-cap stacks, and persistent penalty time; provide distance/profile overlay plus force-trigger/suppress/reset debug actions.

**Answer:**

---

# S. Effects framework and individual effects

## S1 — Final effect roster — IMPLEMENTATION BLOCKER

Confirm which concepts are true `EffectDefinition` statuses: bleed, poison, slow, incapacitation, tracking mark, dazzle, healing-over-time, Curse suppression, Driftseed, Layer 1 Curse penalties, and Layer 2 health-cap stacks. Which remain world areas or AI target requests instead?

**Recommendation:** statuses own actor duration/modifiers; world areas own occupancy; sight/sound/target overrides remain their specialised systems.

**Answer:**

## S2 — Effect source and provider ownership — IMPLEMENTATION BLOCKER

Must each active effect remember source actor/species, source item, world-area provider, and application time? If two resin patches apply the same effect, may exiting one remove the other?

**Recommendation:** track provider/source tokens for area effects; a provider removes only its own contribution.

**Answer:**

## S3 — Stack, refresh, replace, and immunity rules — IMPLEMENTATION BLOCKER

Should stack behavior live entirely in each `EffectDefinition`, and can one effect use different rules by source? What feedback appears when an effect is ignored because of immunity or maximum stacks?

**Recommendation:** one explicit rule per effect ID; use separate IDs when sources need genuinely different behavior.

**Answer:**

## S4 — Modifier aggregation order — IMPLEMENTATION BLOCKER

Should movement, gravity, knockback received, healing, throw range, and health-cap modifiers combine multiplicatively, additively, strongest-only, or by priority? At what point are safety clamps applied?

**Recommendation:** multiply ordinary modifiers, add explicit health-cap stacks, then clamp once in the shared player/actor query.

**Answer:**

## S5 — Tick damage and i-frames — IMPLEMENTATION BLOCKER

Should poison/bleed ticks bypass normal impact i-frames, use a separate damage channel, or be blocked when ticks occur too close together? Can damage-over-time kill, trigger hit flashes, target retaliation, or bird-hit counters?

**Recommendation:** status ticks bypass impact i-frames, may kill, and show status feedback without applying physical hit reactions or unrelated counters.

**Answer:**

## S6 — Effect clocks, pause, and save — IMPLEMENTATION BLOCKER

Which effects advance during inventory, dialogue, paused game, inactive sections, menus, and loading? Should persistent timers save remaining seconds or absolute timestamps?

**Recommendation:** gameplay/inventory advance; pause/menu/loading stop; save remaining seconds for deterministic Continue behavior.

**Answer:**

## S7 — Effect removal and death cleanup — IMPLEMENTATION BLOCKER

Which events clear effects: expiry, leaving an area, Bandage, surface rest, layer transition, death, New Game, target death, or source destruction? May one cleanse remove only part of an effect stack?

**Recommendation:** define removal per effect; death/New Game clear run effects, while Continue restores only definitions marked persistent.

**Answer:**

## S8 — HUD, VFX, and inspectability — BEFORE PLAYTEST

For each effect, what icon, stack count, timer, progress, colour, screen treatment, actor VFX, and audio cue must be visible? Should unknown relic-caused effects hide their name but still communicate mechanics?

**Recommendation:** always communicate consequence and duration; unknown status labels may be descriptive rather than revealing item lore.

**Answer:**

## S9 — Bleed — IMPLEMENTATION BLOCKER

Define total damage, duration, tick interval, stack/refresh rule, valid actors, and whether movement worsens it. Does Bandage remove every bleed stack immediately, and can bleeding kill the player?

**Recommendation:** one refreshable bleed effect, fixed tick damage, lethal if ignored, and Bandage removes it completely.

**Answer:**

## S10 — Poison — IMPLEMENTATION BLOCKER

Poison must deal 25 total damage over 10 seconds. Choose tick cadence, rounding, stacking/reapplication, valid actors, lethality, and whether another item can cleanse it.

**Recommendation:** five ticks of 5 damage, refresh duration without adding another 25-damage stack, lethal, and not removed by Bandage.

**Answer:**

## S11 — Slow — IMPLEMENTATION BLOCKER

Should spider slow and Cling Resin slow use one effect ID? How do duration-based spider slow and provider-based resin occupancy coexist, and may slow reduce movement to zero?

**Recommendation:** separate `spider_slow` and `resin_slow` providers, combine multiplicatively, and clamp to a controllable minimum.

**Answer:**

## S12 — Incapacitation and control locks — IMPLEMENTATION BLOCKER

What exactly does incapacitation block: movement input, jumping, item actions, interaction, climbing, camera, or all gameplay input? Does it zero velocity, detach Rope, cancel active actions, and persist through Continue?

**Recommendation:** use a timed control-lock reason, preserve physics/force, detach only when the attack explicitly launches, do not save transient incapacitation.

**Answer:**

## S13 — Spider tracking mark and target override — IMPLEMENTATION BLOCKER

Define mark duration, refresh/stack rule, eligible targets, HUD/VFX, save behavior, and cleanup. Does it continuously notify flyers, or do flyers query/request the marked target when active?

**Recommendation:** one refreshable persistent mark; active relevant flyers receive/query a shared high-priority target override without direct spider-to-flyer references.

**Answer:**

## S14 — Dazzle, healing, suppression, Driftseed, and Curse effects — IMPLEMENTATION BLOCKER

For each remaining effect, specify whether it is a status or presentation-only state, stack/refresh rule, persistence, valid actors, modifier keys, and removal. In particular: can healing-over-time stack; can dazzle affect AI; can suppression be dispelled; does Driftseed refresh; do Layer 1 penalties use one combined effect or separate effects?

**Recommendation:** healing refreshes one effect, dazzle begins presentation-only, suppression and Driftseed are persistent timed statuses, and separate Layer 1 effect IDs expose clear tuning/UI.

**Answer:**

---

# T. Cross-system acceptance and implementation handoff

## T1 — Approved representative Layer 1 run — GDD BLOCKER

Describe one expected run from surface preparation through descent, item discovery, at least two enemy interactions, ascent Curse, surface return, Blue Whistle progress, and senior-diver gate. Which moments best demonstrate the game's identity?

**Recommendation:** use this narrative as the GDD gameplay synopsis and later integrated acceptance route.

**Answer:**

## T2 — Required systemic scenarios — IMPLEMENTATION BLOCKER

Confirm required combinations: frog theft/recovery, bird knockback near a fall, rock agitating Thorn Bloom, spider mark attracting flyer, snail scream competing with mark, Hushcap breaking sight, resin slowing actors/projectiles, Driftseed changing knockback, Silver Weight killing small enemies, and Curse modifying healing/throwing.

**Recommendation:** mark each `required`, `allowed`, or `out of scope`; every required scenario gets one automated or manual acceptance case.

**Answer:**

## T3 — Debug and test environments — IMPLEMENTATION BLOCKER

Should implementation add one shared Layer 1 test arena with spawn/grant/effect/Curse controls, or separate scenes per enemy/item? Which F3 overlays and state labels are required?

**Recommendation:** one shared arena plus small isolated scene checks; reuse current debug menu and foundation smoke runner.

**Answer:**

## T4 — Performance limits — BEFORE PLAYTEST

What target FPS and representative maximum counts should pass on this VM for active enemies, projectiles, stuck needles, temporary areas, lights, and status effects?

**Recommendation:** target stable 60 FPS; define a stress case slightly above intended encounter density without premature architecture changes.

**Answer:**

## T5 — Save/transition acceptance — IMPLEMENTATION BLOCKER

Which states must be tested across Save & Menu, Continue, layer transition, death, and New Game? Include stolen items, living enemies, dead enemies, active statuses, Curse reference, persistent thrown items, and transient-effect cleanup.

**Recommendation:** require round-trip tests for lasting ownership/state and explicit absence tests for transient attacks/clouds/projectiles.

**Answer:**

## T6 — Documentation outputs and filenames — GDD BLOCKER

After answers, may the next documentation pass create `gdd_en.md`, `gdd_id.md`, plus separate Layer 1 enemy, Layer 1 item, Ascension Curse, and effects implementation files under a new `docs/implementation/` directory? Should any different names/location be used?

**Recommendation:** use those six focused files and link them from `docs/README.md`; do not create one unmaintainable implementation monolith.

**Answer:**

## T7 — “Almost finished” handoff — IMPLEMENTATION BLOCKER

Confirm the programming handoff point: complete behavior, placeholder presentation, data Resources, debug tools, save/load, tests, and art/audio hooks; then stop before final sprites/animations/audio integration and your manual variable tuning.

**Recommendation:** approve this exact boundary and list any feature intentionally allowed to remain incomplete.

**Answer:**

## T8 — Final review and programming greenlight — IMPLEMENTATION BLOCKER

Who reviews the English GDD, Indonesian translation, and four implementation documents? Is another explicit message from you required before any gameplay code is written?

**Recommendation:** you approve all six documents, then provide a separate programming greenlight. Documentation approval alone does not authorise code.

**Answer:**
