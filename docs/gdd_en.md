# Delvers of the Abyss — Game Design Document

> Status: Jam-build design source of truth. English is authoritative. Unanswered narrative decisions are marked `TBD — lead answer required` and collected in `pertanyaan_lanjutan_gdd.md`.

## 1. Purpose and High Concept

This document explains the player-facing design to the jam team, supervisors, artists, programmers, audio contributors, and testers. Technical ownership lives in `fondasi_teknis_godot.md` and `docs/implementation/`.

`PLAYER_NAME` is a curious child who descends into the Abyss to uncover its mysteries and search for her missing parents. She survives by preparing routes, studying creatures, and creatively combining relics rather than relying on direct combat.

- Primary genre: 2D exploration.
- Supporting genres: extraction roguelite and systemic survival adventure.
- Target run: approximately 30 minutes.
- Audience: game-jam visitors with basic platformer familiarity.
- Inspirations: Made in Abyss, Terraria, Noita, Rain World, and Spelunky. The setting is original, not a direct adaptation.

## 2. Design Pillars

1. **Creative relic use:** items solve situations instead of serving only as weapons.
2. **World and creature interaction:** sight, sound, force, statuses, terrain, and other creatures matter more than damage races.
3. **Experimentation and knowledge:** unknown relics invite safe experiments and become understandable across runs.
4. **Plan the return:** descent is only half the expedition; the player must prepare an ascent through enemies and the Curse.

This is not a combat-focused platformer, Metroidvania, grind-heavy progression game, procedural-terrain game, or deliberately punishing game.

## 3. Intended Experience

Preparation and first descent create curiosity. Encounters create caution. Discovering a useful interaction creates excitement. Inventory, route, and return decisions should feel thoughtful rather than overwhelming. Difficulty comes from resources, routes, creatures, and ascent risk; failure should be readable and preventable through preparation or knowledge.

## 4. Core Gameplay

An ordinary Layer 1 sequence is:

1. observe an authored section and its creatures;
2. choose a safe Rope anchor and prepare the return route;
3. descend, collect supplies/relics, and choose what is worth carrying;
4. avoid, distract, manipulate, or fight a creature with relics;
5. manage health, weight, statuses, and supplies;
6. ascend carefully, rest to reset Curse progress, and return or continue deeper.

The full expedition loop, return cadence, death fiction, replay framing, tutorial order, and presentation route remain `TBD — lead answer required`.

## 5. Run and Progression

- Seeded generation selects authored section variations and deterministic placer results; terrain is never procedural.
- West is open and emphasizes knockback/flying threats. East is compact and emphasizes numerous small threats/hazards.
- Each slot may have traversal-focused and enemy-focused variations at comparable difficulty.
- Gatekeepers and major threats are fixed. Ordinary encounters may be random placer results.
- Every required route can be completed without killing ordinary enemies.
- Death ends the living run. Knowledge survives; run inventory, world state, and progression reset.
- The jam build ends when the player interacts with the Layer 3 entrance. Layer 3 is not playable.

Death, victory, surface-service, whistle, and relic-knowledge fiction remains `TBD — lead answer required`.

## 6. World

### Surface

Preparation/recovery hub with shops, replacement services, information, and entrances to both Layer 1 routes. Character details are `TBD — lead answer required`.

### Layer 1

Bright green cliffs and meadows with dim caves. West is open/exposed; east is compact/hazard-dense. It teaches Rope preparation, sound and sight manipulation, creature combinations, and the first Curse package.

### Layer 2

The upper area is an inverted forest traversed through upside-down canopy. The middle contains an outpost/shop and dangerous forest. The bottom is a monster gauntlet before Layer 3.

An optional quest authority asks for an undesigned relic and rewards a Moon Whistle plus a separate powerful relic. They make the gauntlet safer but are not hard keys. Their identities are `TBD — lead answer required`.

## 7. Player

The protagonist is a curious girl searching for the Abyss's mysteries and her missing parents. Name, exact age, training, surface relationships, and dialogue style are `TBD — lead answer required`; `PLAYER_NAME` is deliberately easy to replace.

Core abilities are movement, variable jump, cursor-directed item use, interaction, inventory management, weighted throwing, Rope placement, and Rope climbing. The player is vulnerable; preparation and items create power.

## 8. Inventory and Items

- Five backpack slots, two hotbar slots, and one physical whistle slot.
- Left click uses the item's explicit primary behaviour; right click uses its explicit secondary behaviour.
- Activated throws deal no ordinary physical damage. Inactive throws may deal physical impact damage.
- Real world items use persistent `ThrownItem`; temporary attacks use non-pickup `Projectile`.
- Weight affects burden, post-capacity movement, falling acceleration, throw speed, and impact mass.
- Knowledge grows only from successful signature uses. Info Book reveals remaining discoverable descriptions.

Layer 1 content includes Red/Blue Whistles, Multitool, Rope, Throwable Rock, Bandage, Info Book, Numbing Pill, Sun Sphere, Lantern Crystal, Rattlepod, Hushcap, Cling Resin, Driftseed, and Silver Weight.

## 9. Layer 1 Creatures

- **Tongue Amphibian:** weak alone; prefers loose items, otherwise steals one real player item and retreats.
- **Knockback Bird:** protects an authored nest and pushes the player into terrain danger; two flock hits within two seconds deal damage.
- **Thorn Bloom:** stationary neutral hazard releasing persistent bleeding needles when approached or struck.
- **Lantern Snail:** luminous neutral hazard that screams/dazzles visible actors when disturbed; death drops Lantern Crystal.
- **Cave Spider:** sound-sensitive surface crawler whose projectile slows, poisons, and marks the player for the flyer.
- **Large Layer 1 Flyer:** persistent open-air threat patrolling authored points and performing a deadly committed dive.
- **Senior Diver:** gate guardian recognizing earned Blue rank but allowing systemic distraction, bypass, or defeat.

All are killable. Combat is costly and optional. Neutral hazards react but do not pursue.

## 10. Ascension Curse

The Curse makes upward travel a planning and pacing problem, not arbitrary punishment.

- Track the deepest point; apply one package for each newly crossed ten-metre ascent band.
- Ten seconds within one metre of vertical movement resets the reference.
- Numbing Pills safely consume thresholds at an additional duration cost.
- Layer 1 temporarily modifies movement, healing, throw range, and colour.
- Layer 2 instead applies temporary health-cap stacks, throw/colour penalties, and occasional movement stops.
- Surface and authored safe zones reset safely.

## 11. Effects and Systemic Interaction

Damage, force, status, agitation, sight obstruction, sound, and target overrides are shared contracts. Content uses these contracts unless a documented exception exists.

Effects include bleed, poison, spider slow, resin binding, incapacitation, tracking mark, dazzle, healing, Curse suppression, Driftseed, and both Curse packages. Flying enemies ignore ordinary slow; Driftseed is the explicit exception.

## 12. UI and Feedback

Main HUD: health, hotbar, physical whistle, active status names, money, weight, prompt, autosave feedback, and threat marker. Inventory details remain in the inventory panel.

- Damage: brief red/white sprite flash.
- Status: readable names below health.
- Dazzle/Curse: overlays that never cover HUD.
- Attack warning: `!` above the player plus a directional triangle.
- F3 debug panel: top right.

## 13. Art, Animation, Audio, Accessibility

- Internal viewport 640×360; approximately 32 px/metre.
- Player art 32×32; item art may be 16×16 with integer scaling and separate collision.
- Enemy animation labels are only `idle`, `move`, and `attack`; internal AI states may reuse them.
- Bottom-centre actor pivots, nearest-neighbour filtering.
- Final audio direction is not locked. Gameplay cues must communicate attacks, whistle, movement, activation, and distractions.
- High damage/knockback requires visible warning. Screen effects never cover HUD. Reduced-effects mode is outside jam scope, so defaults remain short/readable.

## 14. Boundaries and Success

Godot 4.7.1, keyboard/mouse, Linux-first, authored terrain, deterministic placement, placeholder presentation, and data-driven tuning are authoritative. Final art/audio/balance, complete narrative, Layer 2 roster, quest/reward relics, and playable Layer 3 are outside this package.

The build succeeds when a new player can prepare, descend, combine relics, survive at least two systemic encounters, experience/counter the Curse, return with value, pass or bypass the senior diver, reach Layer 2, and understand why decisions succeeded or failed.
