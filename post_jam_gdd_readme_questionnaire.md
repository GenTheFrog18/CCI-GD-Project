# Delvers of the Abyss — Post-Jam GDD and README Questionnaire

> **Status:** Awaiting project-owner answers.
>
> **Purpose:** Gather only the decisions and facts that cannot be determined reliably from the repository. These answers will be used to replace the outdated GitHub README and revise the English and Indonesian GDDs into living post-jam documents.

## How to answer

- Write your response directly after each `**Answer:**` label.
- Short answers are acceptable. `Follow recommendation`, `unknown for now`, and `not applicable` are valid answers.
- If the recommendation is close but not exact, edit it instead of starting from nothing.
- Answer **REQUIRED** questions first. The README or GDD would misrepresent the project without them.
- **IMPORTANT** questions may remain provisional, but they affect future design or public expectations.
- **OPTIONAL** questions may remain `TBD` until the relevant work begins.
- When describing the game, separate what is playable **now** from what is intended **later**.

## Priority labels

- **REQUIRED — IDENTITY:** needed to identify the project honestly.
- **REQUIRED — README:** needed for a useful public GitHub page.
- **REQUIRED — GDD:** needed for a coherent design source of truth.
- **IMPORTANT — DIRECTION:** needed to guide continued development.
- **OPTIONAL — FUTURE:** safe to mark provisional without blocking the first documentation pass.

## Decisions already preserved

These are established by the current GDD, answered questionnaires, project files, and implemented game. Do not answer them again unless a question below asks you to revise one.

- The public working title is **Delvers of the Abyss**. `CCI GD Project` remains the repository/internal project name.
- This is an original game strongly inspired by *Made in Abyss*, *Terraria*, *Noita*, *Rain World*, and *Spelunky* rather than a direct adaptation.
- It is a single-player 2D exploration/extraction roguelite built with Godot 4.7.1.
- English is the authoritative GDD language; Indonesian is a faithful counterpart. The questionnaire questions are in English.
- The intended audience starts with players who have basic platformer familiarity.
- The established pillars are creative relic use, world/creature interaction, experimentation and knowledge, and planning a safe return.
- It is not intended to become a combat-first platformer, Metroidvania, procedural-terrain game, grind-heavy game, or deliberately punishing game.
- The current project uses authored terrain, seeded section selection, deterministic placers, a Surface hub, Layer 1, and an unfinished continuation beyond the Layer 2 gate.
- Current mechanics, controls, enemies, items, Curse behavior, dialogue behavior, and technical architecture will be documented from the implementation and their dedicated specifications instead of being re-asked here.
- The root README will be bilingual. The living GDD will remain `gdd_en.md` plus `gdd_id.md`.

## Format basis

There is no single mandatory GDD structure. For this project, the final GDD will be a searchable living document: vision first, then player experience, loops, systems, world/content, narrative, presentation, scope, and production direction. Detailed programmer specifications stay in their existing documents.

The README will remain a concise public entry point and link to the longer GDD and technical documentation.

- [GitHub: About READMEs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)
- [Game Developer: A GDD Template for the Indie Developer](https://www.gamedeveloper.com/design/a-gdd-template-for-the-indie-developer)
- [Unity: Game Design Document Template](https://connect-prd-cdn.unity.com/20201215/83f3733d-3146-42de-8a69-f461d6662eb1/Game-Design-Document-Template.pdf)
- [GitBook: How to Write a Game Design Document](https://www.gitbook.com/blog/how-to-write-a-game-design-document)

---

# A. Public identity and project positioning

## A1 — Final public tagline — REQUIRED — IDENTITY

**Question:** What short sentence should appear directly beneath the title on GitHub? It should explain the player fantasy and distinguishing loop without listing features.

**Recommendation:** “A 2D exploration roguelite about descending into a living Abyss, experimenting with strange relics, and surviving the climb back.”

**Answer:**

## A2 — Public project summary — REQUIRED — IDENTITY

**Question:** In one paragraph, how would you describe the game to somebody who has never seen it? What should they understand before anything else?

**Recommendation:** Mention Elenara's descent, systemic relic use, interacting creatures, route preparation, dangerous ascent, and the unfinished post-jam status.

**Answer:**

## A3 — Current project-status wording — REQUIRED — README

**Question:** How honestly should the README label the current state: post-jam prototype, playable vertical slice, early alpha, work in progress, or another description? What is presently stable enough to promise?

**Recommendation:** Use “post-jam playable prototype under continued development” and explicitly state that Layer 1 is the current content focus while later layers remain incomplete.

**Answer:**

## A4 — Long-term product ambition — REQUIRED — GDD

**Question:** What do you ultimately want this project to become: a polished short free game, a larger commercial indie game, a portfolio project, an open-ended hobby project, or something else?

**Why this matters:** The GDD cannot define sensible scope or milestones without knowing the intended destination.

**Answer:**

## A5 — Public genre labels — REQUIRED — IDENTITY

**Question:** Should the current “2D exploration/extraction roguelite” description remain the public genre label? If not, what exact labels should replace it?

**Recommendation:** Keep it unless “roguelite” creates an expectation of permanent stat upgrades that the game does not intend to provide.

**Answer:**

## A6 — Public inspiration statement — IMPORTANT — DIRECTION

**Question:** Which inspirations should the README name publicly, and what should it say the game takes from each? Are there any inspirations you prefer not to advertise?

**Recommendation:** Name inspirations briefly and describe design influence without implying shared canon, affiliation, or copied content.

**Answer:**

## A7 — Unique promise — REQUIRED — GDD

**Question:** If a player remembers only one thing that makes *Delvers of the Abyss* different from other 2D exploration games, what should it be?

**Recommendation:** Focus on treating relics, creatures, terrain, sound, sight, force, and status effects as one interacting problem-solving system.

**Answer:**

## A8 — Project name permanence — IMPORTANT — DIRECTION

**Question:** Is **Delvers of the Abyss** intended to be the permanent release title, or should the documents call it a working title?

**Answer:**

---

# B. Audience, release, and public access

## B1 — Primary audience after the jam — REQUIRED — GDD

**Question:** Who is the long-term primary audience now that the jam is over? Describe their likely age range, game experience, tolerance for failure, and interest in systemic experimentation.

**Recommendation:** Prioritize general players with platformer familiarity, while allowing deeper mastery for players who enjoy *Noita*, *Rain World*, and extraction-style planning.

**Answer:**

## B2 — Intended content rating and boundaries — REQUIRED — GDD

**Question:** What age rating or content boundary should development target? How graphic may injury, bleeding, creature death, horror, child endangerment, and the parents' story become?

**Answer:**

## B3 — Supported languages — REQUIRED — README

**Question:** Which languages are or will be supported inside the game, and which language is primary for dialogue and UI? Is an English in-game translation actually planned or only the documentation?

**Current evidence:** Current authored dialogue and item descriptions are primarily Indonesian, while many development labels remain English.

**Answer:**

## B4 — Current playable platforms — REQUIRED — README

**Question:** Which exported builds are you willing to call supported now: Windows, Linux, web, or another platform? Which platforms are future targets only?

**Answer:**

## B5 — Distribution page and downloadable build — REQUIRED — README

**Question:** Where should players obtain the game? Provide the itch.io, GitHub Releases, game-jam page, or other public link. If no build should be public yet, say so.

**Answer:**

## B6 — Price and release model — IMPORTANT — DIRECTION

**Question:** Is the intended game free, pay-what-you-want, paid, open source with free builds, or undecided?

**Answer:**

## B7 — Minimum hardware expectations — IMPORTANT — README

**Question:** What hardware should the game reasonably support? Is the four-core VM used during development an actual minimum-performance target or only a stress-test environment?

**Recommendation:** Treat the VM as a useful low-end target, but do not publish exact minimum specifications until tested on named hardware.

**Answer:**

## B8 — Input-device support — IMPORTANT — README

**Question:** Should keyboard and mouse remain the only promised input method, or is controller support part of the intended release scope?

**Answer:**

## B9 — Accessibility commitment — IMPORTANT — DIRECTION

**Question:** Which accessibility features are non-negotiable for the continued project? Consider remapping, text size, readable fonts, reduced flashes, reduced screen shake, color-independent cues, subtitles, difficulty assists, and controller support.

**Recommendation:** At minimum, retain readable telegraphs and text, add reduced-flash/screen-effect options, and avoid communicating critical information by color alone.

**Answer:**

---

# C. Current build and future scope

## C1 — Honest current-playable boundary — REQUIRED — README

**Question:** What can a new player complete in the current build without debug tools? Identify the actual start, current goal, ending point, and any known blocker that prevents a normal completion.

**Answer:**

## C2 — Definition of “Layer 1 complete” — REQUIRED — GDD

**Question:** Which work must be finished before you personally consider Layer 1 complete? Separate missing content from balance, polish, narrative, map, accessibility, and technical cleanup.

**Answer:**

## C3 — Next development milestone — REQUIRED — GDD

**Question:** What is the next concrete milestone when development resumes, and what player-visible outcome marks it complete?

**Recommendation:** Choose one milestone smaller than “finish Layer 2,” such as a polished Layer 1 release candidate or one complete Layer 2 vertical slice.

**Answer:**

## C4 — Intended 1.0 world scope — REQUIRED — GDD

**Question:** How many playable layers should the complete game contain? Give each planned layer's name or theme if known, and clearly distinguish committed layers from distant ideas.

**Answer:**

## C5 — Layer 2 status and commitment — REQUIRED — GDD

**Question:** Which existing Layer 2 designs are still canon and intended for implementation? Which enemies, relics, maps, quests, or mechanics are only proposals?

**Answer:**

## C6 — Layer 3 and deeper layers — OPTIONAL — FUTURE

**Question:** Is Layer 3 intended to become playable? If yes, what role should it serve in the larger game? If the answer is not designed yet, explicitly mark it `TBD` rather than inventing details.

**Answer:**

## C7 — End goal of the complete game — REQUIRED — GDD

**Question:** What ultimately ends a full game or expedition in the long-term version? Is finding the parents the final objective, one stage of a larger story, or only the protagonist's initial motivation?

**Answer:**

## C8 — Features explicitly excluded — IMPORTANT — DIRECTION

**Question:** Beyond the existing anti-pillars, what attractive but out-of-scope features should future contributors not assume are planned? Examples include multiplayer, base building, crafting trees, procedural terrain, class systems, or permanent stat upgrades.

**Answer:**

## C9 — Existing features that may be removed — IMPORTANT — DIRECTION

**Question:** Are any current systems considered jam compromises rather than part of the intended game? Identify anything that should be redesigned or removed instead of documented as permanent.

**Answer:**

## C10 — Development priority order — REQUIRED — GDD

**Question:** Rank the next major priorities after documentation. Suggested categories: Layer 1 completion, bugs/performance, maps, narrative, UI/accessibility, Layer 2 systems, art/audio polish, and tooling.

**Answer:**

---

# D. Player experience and expedition structure

## D1 — Complete expedition loop — REQUIRED — GDD

**Question:** Describe the intended full loop from launching a new run through returning to the Surface and beginning the next expedition. Which steps are mandatory, and which may skilled players skip?

**Recommendation:** Include preparation, route choice, descent, relic discovery, creature interaction, risk/weight decisions, ascent, selling/delivery, knowledge updates, and deeper progression.

**Answer:**

## D2 — Reason to return to the Surface — REQUIRED — GDD

**Question:** What should usually make the player turn back instead of continuing downward? How often should a healthy normal run return, and should this be soft pressure or a hard rule?

**Recommendation:** Use health, inventory weight, supplies, acquired value, route safety, and Curse risk as soft pressure rather than a timer.

**Answer:**

## D3 — Run length targets — IMPORTANT — DIRECTION

**Question:** The old GDD targets roughly 30 minutes. Does that mean a Layer 1 expedition, a complete current-build run, or the eventual full game? Give rough targets for a first run, successful Layer 1 trip, and full 1.0 completion if known.

**Answer:**

## D4 — Death, saves, and permanent knowledge — REQUIRED — GDD

**Question:** What should death reset in the intended game, what survives, and how does the fiction explain retained relic knowledge? Should ordinary save-and-continue remain distinct from death?

**Current baseline:** The old design resets run inventory, world state, and progression on death while preserving knowledge.

**Answer:**

## D5 — Failure conditions — REQUIRED — GDD

**Question:** Besides reaching zero health, can a run be lost through time, unrecoverable progression items, failed quests, the Curse, or another condition? What failures should never permanently ruin a save?

**Answer:**

## D6 — Long-term progression model — REQUIRED — GDD

**Question:** Outside a living expedition, what permanent progression should exist: relic knowledge only, whistle rank, story flags, unlocked services, routes, equipment, stats, or something else?

**Recommendation:** Keep permanent power limited and emphasize knowledge, access, and story progression unless the game's identity has changed.

**Answer:**

## D7 — Replay motivation — REQUIRED — GDD

**Question:** After a player completes the currently available content once, what should motivate another run? Rank the intended sources of replay value.

**Recommendation:** Authored section variations, route choice, different relic combinations, systemic encounters, incomplete knowledge, and optional objectives.

**Answer:**

## D8 — Route choice information — IMPORTANT — DIRECTION

**Question:** What should players know before choosing east or west, and how meaningfully should the routes differ in traversal, creatures, resources, and risk?

**Answer:**

## D9 — Tutorial versus discovery — REQUIRED — GDD

**Question:** Which mechanics must the game teach directly, and which should players discover through experimentation? What information is too important to hide in dialogue or item experimentation?

**Answer:**

## D10 — Intended difficulty and fairness — REQUIRED — GDD

**Question:** What should make the game difficult after the jam? Define what kinds of failure are fair, what kinds are unacceptable, and how forgiving the first expedition should be.

**Current baseline:** Difficulty should come mainly from resources, route planning, enemies, and ascent risk—not opaque instant deaths or demanding combat execution.

**Answer:**

## D11 — Combat's intended place — IMPORTANT — DIRECTION

**Question:** When should fighting be the best choice rather than avoidance or manipulation? What should prevent combat from becoming either useless or the universal solution?

**Answer:**

## D12 — Representative run — REQUIRED — GDD

**Question:** Describe one ideal run that best represents the game: Surface preparation, route choice, Rope placement, relic use, at least two creature encounters, a Curse decision, return or deeper descent, and the ending of that expedition. Which single moment best expresses the game's identity?

**Answer:**

---

# E. World, narrative, and characters

## E1 — Nature of the Abyss — REQUIRED — GDD

**Question:** What is the Abyss in this original setting? State what is common knowledge, what experts believe, and what must remain mysterious to the player.

**Answer:**

## E2 — Surface society — REQUIRED — GDD

**Question:** Who lives around the Abyss, how does it shape their culture and economy, and why do people continue descending despite the danger?

**Answer:**

## E3 — Protagonist canon — REQUIRED — GDD

**Question:** Is **Elenara** the final protagonist name? Define her approximate age, personality, training, abilities before the game begins, relationship to the Surface community, and how much she speaks during play.

**Current evidence:** Existing dialogue uses Elenara, while the old GDD deliberately retained `PLAYER_NAME` as replaceable.

**Answer:**

## E4 — The missing parents — REQUIRED — GDD

**Question:** Who are Elenara's parents, why did they enter the Abyss, what does Elenara believe happened, and what is the truth currently planned by the writer?

**Answer:**

## E5 — Inciting incident — REQUIRED — GDD

**Question:** Why does Elenara begin this expedition now rather than earlier or later? What is the first concrete task given to the player after New Game?

**Answer:**

## E6 — Delvers and whistles — REQUIRED — GDD

**Question:** What is a Delver in this setting? Explain the social and mechanical meaning of Red, Blue, and Moon Whistles, who grants them, and what authority recognizes them.

**Answer:**

## E7 — Relic origin and knowledge — REQUIRED — GDD

**Question:** What are relics, who or what created them, why are they found in the Abyss, and why does the player initially lack complete descriptions of their functions?

**Answer:**

## E8 — Ascension Curse fiction — REQUIRED — GDD

**Question:** Why does upward movement cause the Curse, what do people in the world understand about it, and what long-term consequence exists beyond its current gameplay effects?

**Answer:**

## E9 — The Wanderer/Old Man — REQUIRED — GDD

**Question:** Who is the Old Man currently called The Wanderer? Define his real role, relationship with Elenara and her parents, knowledge of the Abyss, reason for withholding information, and intended story arc.

**Answer:**

## E10 — Shadow — IMPORTANT — DIRECTION

**Question:** Is Shadow still a planned distinct character? If yes, define their identity and narrative purpose. If not, confirm that the placeholder should be removed from canon.

**Answer:**

## E11 — Surface shopkeeper — REQUIRED — GDD

**Question:** Who runs the Surface shop, what is their relationship with Elenara, and why do they buy, sell, deliver, or replace expedition equipment?

**Answer:**

## E12 — Senior Diver/Gatekeeper — REQUIRED — GDD

**Question:** Who is the Layer 1 gatekeeper, what are they protecting, why do they recognize whistle rank, and why may the player bypass, distract, fight, or be grabbed by them instead of following one mandatory solution?

**Answer:**

## E13 — Layer 2 quest authority — OPTIONAL — FUTURE

**Question:** Is the optional Layer 2 quest authority still planned? If yes, who are they, what do they want, why do they possess the rewards, and how does their quest fit the main story?

**Answer:**

## E14 — Quest and reward relics — OPTIONAL — FUTURE

**Question:** What are the Layer 2 quest relic and powerful reward relic? Describe their names, appearance, origin, gameplay purpose, and narrative meaning, or mark them `TBD`.

**Answer:**

## E15 — Layer themes and story progression — REQUIRED — GDD

**Question:** For every committed layer, what is its visual/ecological identity, main gameplay lesson, major narrative revelation, and reason the player continues deeper?

**Answer:**

## E16 — Intended ending — REQUIRED — GDD

**Question:** What ending or major reveal is currently intended for the complete game? If the final truth must remain private, provide the version that collaborators need in order to build toward it and label confidential details clearly.

**Answer:**

## E17 — Story delivery — IMPORTANT — DIRECTION

**Question:** What proportion of the story should come from dialogue, environmental details, item descriptions, creature behavior, quests, and explicit cutscenes? How much ambiguity should remain?

**Recommendation:** Keep mandatory explanations concise and let relics, environments, and creature interactions carry much of the worldbuilding.

**Answer:**

## E18 — Dialogue language and voice — REQUIRED — GDD

**Question:** Define the desired dialogue voice: formal or conversational Indonesian, intended reading age, use of English game terms, humor level, and whether Elenara has internal monologue. Should future English localization preserve Indonesian names and terms?

**Answer:**

## E19 — Existing dialogue canon — REQUIRED — GDD

**Question:** Which existing prologue, Old Man, and Gatekeeper dialogue files are canon today? Should outdated or detached sequences be treated as archive material rather than summarized in the GDD?

**Answer:**

---

# F. System and content philosophy

## F1 — Relic roster growth — IMPORTANT — DIRECTION

**Question:** What makes a new relic worth adding? Must each relic solve several systemic situations, or may some serve a narrow traversal, combat, economy, or story purpose?

**Answer:**

## F2 — Relic knowledge progression — IMPORTANT — DIRECTION

**Question:** How much should players know before first using a relic, how should successful experimentation reveal information, and can incorrect experimentation permanently waste a rare item?

**Answer:**

## F3 — Inventory pressure — IMPORTANT — DIRECTION

**Question:** What decisions should the five backpack slots, two hotbar slots, item weight, and value create? Should future progression ever increase capacity, or is the small inventory a permanent constraint?

**Answer:**

## F4 — Economy purpose — REQUIRED — GDD

**Question:** What is money ultimately for? Define the intended roles of selling, delivery value, shop stock, replacement services, supplies, and progression purchases.

**Answer:**

## F5 — Enemy design rule — IMPORTANT — DIRECTION

**Question:** What must every new enemy contribute beyond dealing damage? Define how readable behavior, ecology, world interaction, items, other enemies, and non-combat solutions should influence approval of a new enemy design.

**Answer:**

## F6 — Consequences of killing creatures — IMPORTANT — DIRECTION

**Question:** Should killing enemies provide loot, safety, knowledge, money, moral consequences, ecological changes, or usually only remove a threat? How strongly should the game discourage routine extermination?

**Answer:**

## F7 — Authored versus randomized content — IMPORTANT — DIRECTION

**Question:** The current game randomizes authored section variations and placer results rather than terrain. Is this the permanent world-generation model? What should always be fixed, and what may vary between runs?

**Answer:**

## F8 — Layer design template — IMPORTANT — DIRECTION

**Question:** Should every future layer follow the same broad structure—two routes, six section slots, layer-specific Curse, hub/gate, relic set, and creature ecosystem—or may later layers use fundamentally different structures?

**Answer:**

## F9 — System complexity ceiling — IMPORTANT — DIRECTION

**Question:** When a realistic systemic interaction conflicts with readability or development cost, which should win? Give one example of complexity the game should deliberately avoid.

**Answer:**

---

# G. Art, audio, UI, and tone

## G1 — Final visual direction — REQUIRED — GDD

**Question:** Describe the intended final visual identity beyond “pixel art.” Include mood, color, silhouette readability, detail level, environmental density, and how beauty should coexist with danger.

**Answer:**

## G2 — Current asset status — REQUIRED — README

**Question:** Which current art, animation, UI, fonts, backgrounds, and audio should be described as final, temporary, commissioned, team-created, or placeholder?

**Answer:**

## G3 — Creature visual philosophy — IMPORTANT — DIRECTION

**Question:** Should creatures appear natural, alien, cute, horrific, or mixed? How visibly should their anatomy and animation communicate behavior before they attack?

**Answer:**

## G4 — Music direction — IMPORTANT — DIRECTION

**Question:** What should music communicate on the Surface, during descent, in caves, during pursuit, during ascent/Curse pressure, and at major gates? Should music be continuous, sparse, adaptive, or mostly ambient?

**Answer:**

## G5 — Sound-design identity — IMPORTANT — DIRECTION

**Question:** Beyond functional sound detection, what should the game's soundscape feel like? Which sounds must remain especially recognizable for accessibility and gameplay?

**Answer:**

## G6 — UI presentation direction — IMPORTANT — DIRECTION

**Question:** Should the interface feel like an in-world expedition journal, a clean game overlay, or a mixture? Which current UI scenes establish the style that future menus should follow?

**Answer:**

## G7 — Motion and screen effects — IMPORTANT — DIRECTION

**Question:** What limits should apply to camera movement, pixel snapping, shake, flashes, overlays, and parallax so the game remains atmospheric without causing nausea or obscuring gameplay?

**Answer:**

---

# H. README ownership, credits, and participation

## H1 — Public author/team name — REQUIRED — README

**Question:** What individual or team name should the README credit as the creator? Should it list real names, GitHub usernames, roles, or a studio/team identity?

**Answer:**

## H2 — Contributor credits — REQUIRED — README

**Question:** List every contributor who should be credited and their role. Include programmers, designers, artists, writers, audio contributors, map designers, testers, mentors, and game-jam teammates. State any names that must remain private.

**Answer:**

## H3 — Game-jam origin — REQUIRED — README

**Question:** What was the event's official name, theme, date, team name, placement/result if any, and submission link? Which of those facts should appear publicly?

**Answer:**

## H4 — Code license — REQUIRED — README

**Question:** Under what license may other people use the source code? If you do not want to grant reuse rights yet, confirm that the repository should state “all rights reserved” until a license is chosen.

**Recommendation:** Do not guess or add an open-source license without the owner's explicit choice.

**Answer:**

## H5 — Asset licenses and attribution — REQUIRED — README

**Question:** Who owns the art, audio, fonts, dialogue, and other assets? Which assets came from third parties, and what exact attribution or license does each require? May repository visitors reuse them?

**Answer:**

## H6 — Contribution policy — REQUIRED — README

**Question:** May outsiders open pull requests or contribute designs, code, translations, maps, or testing? If yes, what should they do before starting? If not, should the README say the repository is public for viewing only?

**Answer:**

## H7 — Bug reports and support — REQUIRED — README

**Question:** Where should players report bugs or request help: GitHub Issues, a form, Discord, email, or nowhere yet? Provide the public link or contact.

**Answer:**

## H8 — Public roadmap — IMPORTANT — README

**Question:** Should the README show a short roadmap, link to another document/project board, or avoid promises until development resumes? Which milestones may be public?

**Answer:**

## H9 — Screenshots, logo, and trailer — REQUIRED — README

**Question:** Which logo, banner, screenshots, GIFs, gameplay video, or trailer should the README display? Give file paths or links where possible, and identify anything too outdated to use.

**Answer:**

## H10 — Installation for players — REQUIRED — README

**Question:** Should players be instructed to download a packaged build, clone and run the Godot project, or both? If packaged builds exist, where are they and are there platform-specific steps?

**Answer:**

## H11 — Setup for developers — REQUIRED — README

**Question:** What should a new developer install or know beyond Godot 4.7.1? Include any required export templates, Git LFS, external tools, fonts, private assets, branch workflow, or known version restrictions.

**Answer:**

## H12 — Public contact and links — IMPORTANT — README

**Question:** Which public links should appear: itch.io, GitHub profile or organization, portfolio, social media, Discord, email, game-jam page, devlog, or donation page?

**Answer:**

---

# I. Production direction and document authority

## I1 — Decision ownership after the jam — REQUIRED — GDD

**Question:** Who has final authority over game design, narrative, programming architecture, art direction, and release decisions now? How may the new enemy designer or future contributors propose changes?

**Answer:**

## I2 — Expected development model — IMPORTANT — DIRECTION

**Question:** Will continued development be primarily solo, the same jam team, occasional collaborators, or an open team? How much time do you realistically expect to spend on it?

**Answer:**

## I3 — Milestone philosophy — IMPORTANT — DIRECTION

**Question:** Should development prioritize small playable releases, complete one layer at a time, implement all planned systems before polish, or follow another sequence?

**Recommendation:** Complete and release stable vertical slices one layer at a time, keeping the main branch playable.

**Answer:**

## I4 — Primary risks — REQUIRED — GDD

**Question:** What do you believe is most likely to prevent completion or make the game worse? Consider scope, solo workload, content volume, map production, performance, unclear narrative, balancing systemic interactions, asset production, and technical debt.

**Answer:**

## I5 — Playtesting plan — IMPORTANT — DIRECTION

**Question:** Who can test the game, how often, and what evidence should decide whether a mechanic or layer is working? What feedback from the final presentation should not be forgotten?

**Answer:**

## I6 — Success criteria — REQUIRED — GDD

**Question:** What would make continued development successful even if the game never becomes a large commercial release? Give player-experience, creative, technical, community, or release goals that matter to you.

**Answer:**

## I7 — Living-GDD update policy — REQUIRED — GDD

**Question:** When implementation and the GDD disagree, should the intended design in the GDD be corrected first, or should shipped behavior become authoritative until intentionally redesigned? Who approves a design change?

**Recommendation:** The GDD owns approved intent; implementation documents own technical contracts. Record intentional changes in both, but label accidental implementation differences as bugs rather than silently rewriting the design.

**Answer:**

## I8 — Private information boundary — REQUIRED — README

**Question:** Is any answer in this questionnaire private and forbidden from the public README or repository-visible GDD? Clearly identify spoilers, personal contact details, unreleased plans, or contributor information that must be omitted.

**Answer:**

---

# J. Final approval answers

## J1 — README audience priority — REQUIRED — README

**Question:** Rank the README's readers: players, potential collaborators, recruiters/portfolio reviewers, game-jam judges, and developers setting up the project.

**Answer:**

## J2 — GDD audience priority — REQUIRED — GDD

**Question:** Rank the GDD's readers: yourself returning later, programmers, enemy/content designers, writers, artists/audio contributors, testers, and public readers.

**Answer:**

## J3 — Acceptable provisional content — REQUIRED — GDD

**Question:** When an **IMPORTANT** or **OPTIONAL** answer remains blank, may the first GDD use the recommendation and clearly label it provisional, or must every blank remain `TBD — owner answer required`?

**Recommendation:** Never invent canon. Use recommendations only for process and presentation; leave creative facts and release commitments as explicit `TBD`.

**Answer:**

## J4 — Anything the documents must not miss — REQUIRED — GDD

**Question:** What important truth about the game, its history, or your intention has not been asked anywhere above?

**Answer:**

---

## What happens after this is answered

The completed questionnaire will be used to:

1. replace the root `README.md` with a concise bilingual public project page;
2. revise `gdd_en.md` into the authoritative living post-jam GDD;
3. mirror it accurately in `gdd_id.md`;
4. update `docs/README.md` so document authority is unambiguous;
5. preserve detailed mechanics and programming contracts in their existing specialized documents instead of duplicating them into the GDD.

No unanswered creative fact will be silently invented.
