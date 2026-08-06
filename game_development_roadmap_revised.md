# Two-Week Godot Game Jam Development Roadmap

## Document Purpose

This is the production roadmap for the current jam build. It replaces the older three-week, phase-heavy plan.

The team should use this document as a shared task board. Work is organized by **aspect**, not permanently assigned to Programmer A or Programmer B. A developer may claim any ready aspect that matches their interest, but every claimed task must have one active owner and a stated integration point.

The roadmap assumes:

- Two beginner Godot programmers
- One project lead who can assist with programming
- Separate art and audio contributors
- Fourteen calendar days total
- Godot 4.x
- Keyboard and mouse as the required control scheme
- A fixed feature freeze beginning on Day 11

---

# 1. Production Rules

## 1.1 Priority Labels

- **P0 — Required:** The intended run cannot be completed or presented without it.
- **P1 — Important:** Strongly improves the intended experience, but may be simplified if P0 work slips.
- **P2 — Stretch:** Implement only after the complete game has passed an exported-build playthrough.

No P1 or P2 work should delay a broken P0 integration.

## 1.2 Task Ownership

Developers are free to choose what they work on under these rules:

1. Claim one clearly bounded task at a time.
2. Record the owner, expected output, and files likely to change.
3. Avoid having two people edit the same `.tscn` scene simultaneously.
4. Prefer separate child scenes, scripts, and Resources over edits to a shared main scene.
5. Integrate work into the playable build on the same day it becomes functional.
6. A task is not complete because it works in isolation; its acceptance test must pass in the main game.
7. If blocked for more than one hour, report the blocker and claim another ready task.

## 1.3 Definition of Done

A feature is done only when:

- It works in the exported build, not only in the editor.
- It has no repeated errors in the debugger.
- It uses placeholder art safely if final art is unavailable.
- It supports pause, scene changes, death, New Game, and Continue where relevant.
- Its data can be tuned without rewriting unrelated scripts.
- Its acceptance tests have been performed.
- Another team member has tested it once.

## 1.4 Scope Guardrails

The jam build does **not** require:

- Destructible terrain
- Procedural terrain generation
- A general behavior-tree editor
- Complex equipment statistics
- Crafting
- Branching dialogue
- A third playable layer
- Controller support unless all P0 work is complete
- Multiple save slots
- Localization
- Online features
- Advanced accessibility menus
- Elaborate boss phases
- More items or enemies than listed in this document

The Moon Whistle is the ending reward; Layer 3 is not playable.

---

# 2. Intended Player Experience: Boot to Close

The complete build must support the following sequence.

## 2.1 Boot

1. The executable opens without the Godot editor.
2. A short studio/team splash is optional and skippable.
3. The main menu appears with:
   - New Game
   - Continue, enabled only when a living run exists
   - Controls
   - Credits
   - Quit
4. If an autosave is invalid, Continue is disabled and the game remains usable.

## 2.2 New Game

1. If a living run exists, New Game requests confirmation before replacing it.
2. The current run and world are reset.
3. Previously learned item knowledge is retained.
4. A new seed is generated.
5. The world generator selects section variations and resolves deterministic placers.
6. The player begins at the surface with:
   - 100 health
   - 50g
   - Red Whistle in the dedicated whistle slot
   - Multitool
   - Empty backpack and hotbar apart from required starting equipment
7. A short, advanceable text-bubble introduction plays.

## 2.3 Living Run Loop

1. Buy supplies at the surface shop.
2. Descend into Layer 1.
3. Explore either east or west routes through authored sections.
4. Find, identify, use, carry, or sacrifice relics.
5. Avoid, manipulate, or fight creatures.
6. Place permanent-for-this-run ropes.
7. Ascend and experience the Layer 1 curse.
8. Sell relics at the surface and increase the delivery count.
9. At the configured delivery threshold, currently 10 item units, replace the Red Whistle with the Blue Whistle.
10. Pass or creatively bypass the senior diver at the Layer 1 gate.
11. Enter Layer 2 and traverse the inverted forest canopy.
12. Reach the safe shop halfway through Layer 2.
13. Continue through the lower Layer 2 hippo territory.
14. Pass the final Layer 2 gatekeeper.
15. Receive the Moon Whistle and show the jam ending.

The run continues through surface returns and repeated descents. A run ends only when the player dies or the player deliberately starts a New Game.

## 2.4 Pause, Autosave, and Close

- Autosave every 180 seconds during a living run.
- Also autosave after major progression, shop transactions, entering a layer, returning to the surface, and choosing Return to Menu.
- Pause menu:
  - Resume
  - Controls
  - Return to Menu
  - Quit to Desktop
- Return to Menu and Quit to Desktop must request a save before leaving gameplay.
- An operating-system close request should attempt one final save, but the three-minute autosave remains the protection against forced termination.
- Continue restores the same run, seed, selected sections, world changes, player state, shops, progression, and learned knowledge.

## 2.5 Death

1. Stop player input and active threats.
2. Evaluate per-run artifact-use counts.
3. Add newly learned descriptions to persistent knowledge.
4. Remove the living-run save and disable Continue.
5. Show a death screen listing newly learned relics.
6. Offer New Game and Main Menu.
7. Starting New Game resets money, inventory, world, ropes, shops, enemies, whistle progression, and seed while retaining knowledge.

## 2.6 Ending

1. The player passes the final Layer 2 gatekeeper.
2. A short text-bubble sequence plays.
3. The Moon Whistle replaces the Blue Whistle.
4. An ending screen confirms completion and shows credits or a brief closing message.
5. The player can return to the main menu or quit.

---

# 3. Locked Game Design Reference

## 3.1 World Layout

- Surface hub and surface shop
- Layer 1: 150 metres deep
- Layer 2: 150 metres deep
- Layer 1 gate at 150 metres
- Layer 2 shop at approximately 225 metres, halfway through Layer 2
- Final Layer 2 gatekeeper at approximately 300 metres

Each layer has:

- East and west sides
- Three seamless vertical section slots on each side
- Two authored variations for each slot
- Six selected sections per layer per seed
- Twelve authored section scenes per layer
- Twenty-four authored section scenes as the full target across both layers

The generator does not create terrain. It chooses one authored variation for each fixed slot, instantiates it at a fixed position, and activates the placers inside it.

### Jam-safe content order

1. Graybox one valid variation for all twelve required slots across both layers.
2. Make the entire surface-to-ending route playable.
3. Author the second variation for each slot.
4. If time is short, reuse or lightly redress a completed variation rather than leaving a broken connection.

## 3.2 Player and Inventory

- Base health: 100
- Five backpack slots
- Two hotbar slots
- Stack limit: 8 units of the same item
- Whistles use a dedicated slot and can replace one another.
- Opening the inventory:
  - Slows the player
  - Blocks the middle of the screen
  - Darkens the remaining view
- Left click uses the active hotbar item.
- Right click throws the active item.
- Throw direction follows the cursor.
- Throw strength is based on cursor distance, clamped to a tunable minimum and maximum.
- The multitool performs close interactions, breaks relic rocks, harvests Lantern Snails, and deals low close-range damage.
- Direct combat is possible but intentionally weak compared with relic use and avoidance.

## 3.3 Economy and Shops

Starting money: 50g.

### Surface shop

- Purchases relics at 100% base value.
- Selling item units increments the Blue Whistle delivery progress.
- Sells the standard supply stock.
- Stock may be unlimited for jam simplicity unless a specific item requires a limit.

### Layer 2 shop

- Safe area.
- Purchases relics at 75% of surface value.
- Use `round(base_value * 0.75)` for integer prices unless playtesting selects another rule.
- Has manually configured limited stock.
- Stock quantities persist for the entire run and through Continue.
- Does not need to count toward Blue Whistle progress because the player already passed the Layer 1 gate.

### Tunable progression values

- Blue Whistle threshold begins at 10 delivered item units.
- Whether stacked units count individually remains a playtest variable, not hardcoded logic.
- All prices and shop stock quantities must be editable in Resources or Inspector fields.

## 3.4 Item Manifest

| Item | Source or Price | Use | Sale Value | Persistence Notes |
| --- | --- | --- | ---: | --- |
| Rope | Surface shop, 20g | Places approximately five metres of climbable rope; consumed and cannot be recovered | Not a relic sale | Placed rope remains for the run and must save |
| Red Whistle | New Game | Layer 1 credential | — | Dedicated slot; replaceable at surface |
| Blue Whistle | Awarded after delivery threshold | Passes Layer 1 senior diver | — | Replaces Red Whistle |
| Moon Whistle | Final Layer 2 reward | Ending reward | — | Replaces Blue Whistle |
| Multitool | Starting equipment | Break rocks, harvest snails, close interaction, weak attack | — | Starting tool |
| Bandage | Surface shop, 50g | Stops bleeding and slowly restores 50 health, modified by healing penalties | — | Consumable |
| Info Book | Surface shop, 30g | Immediately unlocks all item descriptions | — | Knowledge persists after New Game |
| Numbing Pill | Surface shop, 120g | Suppresses ascension curse for approximately five minutes | — | Consumable; duration must save |
| Sun Sphere | Common Layer 1 relic | Thrown short-duration illumination | 20g | Consumable |
| Throwable Rock | From broken relic rocks | Basic thrown damage and physical interaction | Cannot be sold | Recoverability decided by collision result |
| Lantern Snail | Caves and Layer 2 | Portable light; agitation causes scream, dazzle, and large-enemy attraction | 50g | Harvest with multitool |
| Rattlepod | Cliffsides | Creates sound at the player or thrown location | 30g | Limited pulses or consumed behavior |
| Hushcap | Cave entrances | Creates a sight-obscuring cloud at player or impact point | 30g | Usually consumed |
| Cling Resin | Trees in Layers 1–2 | Creates a sticky slowing area affecting valid bodies and projectiles | 50g | Container consumed when deployed |
| Driftseed | Trees in Layers 1–2 | Reduces gravity and increases knockback vulnerability on attached target | 30g | Duration and recoverability data-driven |
| Silver Weight | Rare, maximum one per run | Makes holder heavy; thrown weight kills small monsters; breaks after two throws | 150g | Durability and world position must save |

## 3.5 Knowledge Rules

- Every relic has a permanent description-knowledge flag.
- Unknown relics rely on visual clues and player experimentation.
- Each relic has a small per-run use threshold.
- On death, relics that reached their use threshold become permanently known.
- Partial use progress does not carry into the next run.
- The Info Book immediately marks every relic description as known.
- Knowledge is stored separately from the living run so New Game cannot erase it.

## 3.6 Layer 1 Enemy Manifest

| Enemy | Required Behavior | Shared Systems |
| --- | --- | --- |
| Tongue amphibian | Fires tongue, steals an item, slows player for one second, retreats with item; may steal whistle only when no inventory item remains | Ranged attack, inventory theft, item recovery |
| Knockback bird | Swoops and deals knockback; repeated bird hits inside a time window cause damage | Flying mover, group-hit window |
| Thorn bloom | Stationary; releases needles when agitated; needles persist for minutes, cause damage and bleeding | Agitation, projectile, persistent hazard |
| Lantern Snail | Illuminates; screams and dazzles when agitated; attracts large flyer; can be harvested | Light, agitation, sound event, harvest interaction |
| Cave spider | Shoots slowing projectile, deals small damage, applies 25 total poison damage over 10 seconds, and marks player for flyer pursuit | Ranged attack, slow, poison, target mark |
| Large Layer 1 flyer | One major open-air threat on the player's side; follows line of sight and chases; attack deals 75 damage | Flying chase, obstruction checks, target override |
| Senior diver gatekeeper | Guards Layer 2 entrance; passes Blue Whistle holder; otherwise slow movement and fast attack; can be fought or bypassed with relics | Dialogue/gate state, ground combat, target reactions |

## 3.7 Layer 2 Enemy Manifest

| Enemy | Required Behavior | Shared Systems |
| --- | --- | --- |
| Monkey group | Keeps distance, throws rocks, repositions away from player, operates in small groups; small damage and knockback | Ranged-kiting state machine, group spacing |
| Strong knockback bird | Reuses Layer 1 bird foundation with stronger knockback or tighter attack timing | Bird scene plus Layer 2 data profile |
| Small Layer 2 flyers | Several active at once; spread out; acquire player on sight; each hit deals 25 damage | Flying chase, separation steering, sight targeting |
| Charging hippo | Lower Layer 2; telegraphed charge; deals 50 damage, large knockback, and one-second incapacitation | Ground charge state machine, stun effect |
| Final gatekeeper | Blocks the ending route; one reliable pass condition is mandatory; passing awards Moon Whistle | Gate state, dialogue, ending trigger |

The final gatekeeper does not need multiple boss phases. The project lead must lock its single required pass condition by the end of Day 2. A creative bypass or combat solution is P1 unless it reuses existing systems with little extra work.

## 3.8 Ascension Curse

The curse system tracks a depth reference using world coordinates, not viewport resolution.

- Record the lowest position reached.
- Moving upward by one configured screen-height distance from that reference applies the current layer's curse package.
- If the player remains sufficiently still for 10 seconds, reset the reference to the current depth.
- Descending updates the lowest position and does not apply curse.
- Numbing Pill suppresses curse application for approximately five minutes.

### Layer 1 package

- Screen discoloration
- Random maximum-movement-speed modification
- Reduced healing
- Randomly reduced maximum throwing distance

### Layer 2 package

- Add one health-cap stack per curse application.
- Each stack reduces the maximum healable health by 10% of base maximum health.
- Cap the reduction at 50%, leaving at least 50 healable health.
- Randomly stop the player for 0.5 seconds.
- Apply screen discoloration.
- Reduce maximum throwing distance.

All ranges, durations, probabilities, colors, and multipliers must live in per-layer `CurseProfile` Resources. The project lead must lock usable prototype values by the end of Day 3.

## 3.9 Story Scope

Story is delivered through simple player-advanced text bubbles.

Required sequences:

- New Game introduction
- Surface shop or first-descent explanation
- Blue Whistle award
- Senior diver gate interaction
- Layer 2 shop greeting
- Final gatekeeper interaction
- Moon Whistle ending
- Death/new-knowledge summary

No branching dialogue is required. Portraits, typewriter effects, voice acting, choices, and localization are P2.

---

# 4. Godot Project Architecture

The architecture should make content addition predictable without becoming a large framework.

## 4.1 Suggested Folder Structure

```text
res://
  autoload/
  core/
  data/
    items/
    enemies/
    effects/
    shops/
    dialogue/
  player/
  items/
    behaviors/
    world/
  enemies/
    shared/
    layer_1/
    layer_2/
  world/
    surface/
    layer_1/
    layer_2/
    placers/
    generation/
  ui/
  audio/
  art/
  debug/
  tests/
```

Do not reorganize folders repeatedly after content integration begins.

## 4.2 Minimal Autoloads

Use no more than the following unless a clear need appears:

- `GameSession`: current run state, progression, seed, money, whistle, deliveries, and high-level signals.
- `SaveManager`: meta save, run save, autosave timer, validation, atomic writes, and load order.
- `ContentCatalog`: lookup of item, enemy, effect, shop, and dialogue Resources by stable ID.
- `SceneRouter`: main menu/gameplay transitions and transition overlay.
- `AudioManager` is optional; use it only if shared volume/music control needs it.

Gameplay logic should remain in scenes and components rather than accumulating in Autoloads.

## 4.3 Stable IDs

Every persistent object needs a manually visible stable ID:

- Section slot: `layer1_east_02`
- Section variation: `layer1_east_02_b`
- Placer: `layer1_east_02_b_loot_03`
- Rope: generated unique run ID
- Story trigger: `story_blue_whistle_award`

Changing a node name must not silently change its persistence identity.

Add a debug validator that reports duplicate or blank persistent IDs when the world loads.

## 4.4 Data Resources

### `ItemDefinition`

Required fields:

- Stable item ID
- Display name
- Unknown and known descriptions
- Icon and world sprite
- Maximum stack size
- Surface sale value
- Purchasable price, if any
- Discovery-use threshold
- Consumable/retrievable rules
- Behavior Resource or behavior scene
- Audio and VFX hooks

### `EnemyDefinition`

Required fields:

- Stable enemy ID
- Scene
- Maximum health
- Contact or attack damage
- Knockback strength
- Movement values
- Detection range
- Layer availability
- Persistence rule
- Audio and VFX hooks

Enemy-specific scripts may expose additional tuning values. Do not force every behavior into one enormous Resource.

### `EffectDefinition`

- Stable effect ID
- Duration
- Stack rule
- Maximum stacks
- Tick behavior
- UI icon/color
- Save rule

### `ShopDefinition`

- Shop ID
- Buy-price multiplier
- Stock item IDs and quantities
- Whether stock is limited
- Whether selling counts toward delivery progression

### `DialogueSequence`

- Sequence ID
- Ordered text lines
- Optional speaker name
- Optional portrait
- Whether gameplay pauses
- Whether completion persists

## 4.5 Item Behavior Interface

Use one generic inventory and one generic thrown-item scene.

Each special item behavior should expose only what it needs:

- `can_use(context) -> bool`
- `use(context) -> UseResult`
- `can_throw(context) -> bool`
- `on_thrown(thrown_item, context)`
- `on_impact(thrown_item, collision)`
- `capture_state() -> Dictionary` when persistent state exists
- `restore_state(data)` when persistent state exists

The generic `ThrownItem` owns trajectory, collision, pickup eligibility, and persistent world identity. The behavior owns the unique result, such as light, noise, spores, resin, gravity change, or Silver Weight durability.

## 4.6 Enemy Foundation

Use small shared components and simple per-enemy state machines. Do not build a behavior tree.

Recommended shared nodes/scripts:

- Health and damage receiver
- Hitbox/hurtbox
- Knockback receiver
- Status receiver
- Sight detector using raycasts
- Sound-event listener
- Navigation/ground probe helper
- Item-interest target
- Persistent-state adapter

Recommended reaction methods:

- `hear_sound(event)`
- `apply_force(vector)`
- `apply_slow(amount, duration)`
- `set_target_override(target, duration)`
- `become_agitated(source)`
- `receive_thrown_item(item, impact)`

Each enemy uses an explicit small state enum such as `IDLE`, `PATROL`, `AIM`, `ATTACK`, `RECOVER`, `CHASE`, or `FLEE`. Only implement states that enemy requires.

## 4.7 Deterministic World and Placer Generation

World generation steps:

1. Read the run seed.
2. For each of the twelve fixed section slots, choose variation A or B using a deterministic RNG stream.
3. Instantiate the selected scene at the slot's fixed transform.
4. Validate seamless entry and exit anchors.
5. Resolve each placer using a seed derived from `run_seed + persistent_id`.
6. Check saved state before spawning anything.
7. Register persistent objects with `SaveManager`.

Enemy and loot placers require:

- Stable persistent ID
- Spawn chance
- Weighted content pool
- Quantity range for loot
- Optional layer/progression condition
- Deterministic result
- Collected/defeated state check

Reloading the same seed must not reroll a placer.

## 4.8 Save Architecture

Use two logical save files.

### Meta save

- Save version
- Known item-description IDs
- Settings needed outside a run

### Living-run save

- Save version and active-run flag
- Run seed
- Selected section variations
- Player position, side, layer, health, and current effects
- Money
- Backpack, hotbar, item quantities, and item instance state
- Current whistle
- Delivery count and progression flags
- Numbing Pill remaining time
- Curse reference position and Layer 2 health-cap stacks
- Surface and Layer 2 shop stock
- Collected loot and harvested-source IDs
- Defeated enemy IDs
- Runtime state for important living enemies when required
- Placed rope positions and IDs
- Persistent dropped/retrievable item positions and durability
- Completed story-trigger IDs
- Gatekeeper states

Temporary projectiles, short-lived clouds, and one-frame combat states do not need saving. On Continue, close transient UI and restore the player in a safe neutral control state.

Writes should use a temporary file followed by replacement so interruption does not destroy the previous valid save.

---

# 5. Aspect Work Packages

Developers may claim any work package whose dependencies are satisfied.

## A. Project Boot, Menus, and Export — P0

### Goal

Make the game reliably boot, transition, pause, and close.

### Tasks

- Create project settings and Input Map.
- Create main menu, controls panel, credits panel, pause menu, death screen, and ending screen.
- Implement SceneRouter transitions.
- Implement New Game confirmation when a living run exists.
- Enable Continue only for a valid living-run save.
- Handle operating-system close request through SaveManager.
- Configure window size, stretch mode, mouse behavior, and export preset.
- Produce an exported build on Day 1 and at least once daily afterward.

### Inputs and outputs

- Calls `GameSession.start_new_run()` and `SaveManager.load_run()`.
- Gameplay scene emits return-to-menu, death, and ending requests.
- Does not directly edit inventory, world, or enemy state.

### Acceptance tests

- Clean boot reaches menu.
- New Game reaches surface.
- Pause freezes gameplay and resumes correctly.
- Return to Menu saves and enables Continue.
- Quit works in the exported build.
- Invalid save does not crash the menu.

## B. Run Lifecycle, Autosave, and Persistence — P0

### Goal

Keep one living world stable until death or deliberate New Game.

### Tasks

- Implement meta and run save schemas with version numbers.
- Implement 180-second autosave timer.
- Implement event saves at shops, layer transitions, progression changes, menu return, and quit.
- Add registration API for persistent objects.
- Save and restore player, world, inventory, shops, gates, dialogue, ropes, and item-instance state.
- On death, transfer only newly learned knowledge into meta save and invalidate the living run.
- On New Game, retain meta knowledge and reset everything else.
- Add atomic-write behavior and invalid-save fallback.
- Add debug actions for force save, force load, clear run, and clear all data.

### Dependencies

- Needs agreed state dictionaries from other aspects.
- Can begin with placeholder dictionaries before content exists.

### Acceptance tests

- Close after collecting an item; Continue preserves it and does not respawn the source.
- Continue preserves selected section variations.
- A placed rope returns in the same position.
- Silver Weight durability and world position survive Continue.
- Shop stock and money survive Continue.
- Death removes Continue but preserves learned descriptions.
- New Game produces a new seed and Red Whistle.

## C. Player Controller, Camera, Damage, and Interaction — P0

### Goal

Create a reliable child-sized controller that supports cautious movement rather than power combat.

### Tasks

- Horizontal movement, acceleration, deceleration, jump, fall, slopes, and one-way platforms if used.
- Camera follow across seamless vertical sections with sensible look-ahead.
- Health, damage, brief hit protection, knockback, incapacitation, and death signals.
- Short-range multitool attack and interaction ray/area.
- Interaction prompt for shops, sources, gates, story triggers, and recoverable items.
- Control locks for inventory, dialogue, stun, pause, ending, and death.
- Hooks for animation, footsteps, hit flash, camera shake, and sound.
- Expose movement and damage values for tuning.

### Interface contract

- Status system changes movement/healing/throwing through named modifiers.
- Inventory asks the player to use or throw the selected item.
- Enemies call one damage API rather than editing health directly.

### Acceptance tests

- Player can traverse graybox sections both downward and upward.
- Knockback cannot push the player through terrain.
- One-second hippo stun disables input and then reliably returns control.
- Inventory and dialogue cannot leave movement permanently locked.
- Death triggers once.

## D. Inventory, Hotbar, Throwing, and Discovery — P0

### Goal

Support the defining item-focused gameplay with minimal UI complexity.

### Tasks

- Five backpack slots and two hotbar slots.
- Maximum stack size of eight.
- Add, remove, split only when required, move between backpack/hotbar, select active slot, and reject full inventory.
- Inventory overlay that slows player, blocks screen centre, and darkens the rest.
- Generic item pickup and drop.
- Left-click use and right-click throw.
- Cursor-distance throw strength with configurable clamp.
- Generic thrown-item scene with collision, impact, retrieval, consumption, and persistent instance state.
- Dedicated whistle slot and replacement flow.
- Per-run artifact-use counts and permanent known-description lookup.
- Info Book unlock-all behavior.
- Clear feedback for full inventory, unusable item, depleted item, and newly known description.

### Acceptance tests

- Items stack to eight and overflow safely.
- Opening inventory creates the intended danger and closes cleanly.
- Throw direction and strength feel consistent at different window sizes.
- Throwable items do not duplicate after pickup or Continue.
- An unknown item shows the unknown description; a known item shows full text.
- Frog theft never selects the whistle while another inventory item exists.

## E. Item Behaviors and Environmental Sources — P0

### Goal

Implement every listed item through the common foundation.

### P0 implementation order

1. Multitool and breakable relic rock
2. Throwable Rock
3. Rope
4. Bandage
5. Sun Sphere
6. Rattlepod
7. Hushcap
8. Cling Resin
9. Driftseed
10. Lantern Snail and harvesting
11. Numbing Pill
12. Silver Weight durability and small-monster kill
13. Info Book
14. Whistle definitions

### Environmental-source tasks

- Breakable relic rock may reveal a relic placer and also produce rocks.
- Rattlepod and Hushcap growth nodes are harvestable once per run.
- Resin tree nodes are harvestable once per run.
- Driftseed tree nodes are harvestable once per run.
- Lantern Snail harvest requires the multitool and converts the creature to an item without treating it as a kill drop.
- No enemy drops relics on death.

### Acceptance tests

- Every item can be granted from debug UI, picked up, used, thrown where appropriate, sold where appropriate, and saved.
- Each artifact affects the player, enemies, or world through shared reaction APIs rather than enemy-specific hardcoding where possible.
- Silver Weight kills only enemies tagged as small, survives one throw, and breaks on the second.
- Bandage stops bleed and heals slowly for a total of 50 before modifiers.
- Numbing Pill duration survives Continue.

## F. World Assembly, Sections, Placers, and Ropes — P0

### Goal

Build the seeded authored world without procedural geometry.

### Tasks

- Create fixed slot markers for east/west and three positions per layer.
- Define the section scene contract: size, origin, entry anchors, exit anchors, collision bounds, camera bounds, placer parent, and dynamic-object parent.
- Create deterministic A/B selection from run seed.
- Implement enemy and loot placers with stable IDs, chance, and weighted pools.
- Build the surface hub, Layer 1 gate, Layer 2 midpoint shop space, and final gate space.
- Create a graybox variation for every required slot before second variations.
- Add rope placement validation and climbable rope behavior.
- Save placed ropes and prevent recovery.
- Validate that both east and west routes connect from surface to ending.

### Acceptance tests

- Same seed produces the same twelve selected sections and placer results.
- Different seeds can choose different variations.
- Every selected seam is traversable without a collision gap.
- A section can be replaced without changing world-generator code.
- Placer results do not reroll after Continue.
- Ropes remain until death or New Game.

## G. Enemy Framework and Layer 1 Content — P0

### Goal

Create the shared enemy contract and all Layer 1 threats.

### Recommended order

1. Shared damage, hitbox, knockback, sight, sound, status, and persistence components
2. Knockback bird
3. Tongue amphibian and item theft
4. Thorn bloom and persistent needles
5. Lantern Snail creature state
6. Spider projectile, poison, and tracking mark
7. Large flyer and obstruction-based chase
8. Senior diver gatekeeper

### Implementation notes

- Bird group damage should use one shared recent-hit window on the player.
- Stolen items become recoverable world items carried by the amphibian.
- The amphibian chooses a whistle only if no ordinary inventory item exists.
- Needle lifetime is tunable and need not survive Continue if saving it is too costly; clear transient needles safely on load.
- The flyer must use raycasts or obstruction tests and cannot attack through solid terrain.
- Spider tracking mark requests flyer target priority through a shared target-override signal.
- Senior diver uses a simple state machine and checks the whistle slot through the gate interaction.

### Acceptance tests

- Every enemy works in a dedicated test arena and one real section.
- Every enemy reacts to noise, force, slow, obstruction, or agitation when appropriate.
- No enemy requires a unique change in the inventory system.
- One complete Layer 1 descent and ascent is possible without combat.
- Blue Whistle allows passage through the gate.

## H. Layer 2 Enemies and Final Gatekeeper — P0

### Goal

Make Layer 2 a knockback-focused traversal threat using reused foundations.

### Tasks

- Monkey ranged-kiting AI with group spacing and thrown rocks.
- Layer 2 bird as a data variant of the existing bird.
- Small flyer group using shared flying chase plus separation.
- Hippo states: idle/patrol, telegraph, charge, collision, recovery.
- Hippo hit applies 50 damage, large knockback, and one-second incapacitation.
- Final gatekeeper interaction and one reliable pass condition.
- Moon Whistle award and ending signal.

### Scope rule

The final gatekeeper may reuse senior-diver components. Do not build a second elaborate boss framework. The pass condition must be locked by Day 2 and functional by Day 9.

### Acceptance tests

- Monkeys maintain distance without walking off intended canopy surfaces.
- Flyer groups spread out enough to avoid becoming one overlapping blob.
- Hippo charge is visible before it becomes dangerous.
- Knockback cannot permanently strand the player outside level bounds.
- The Layer 2 shop-to-ending route is completable.
- Passing the final gatekeeper awards the Moon Whistle exactly once.

## I. Status Effects and Ascension Curse — P0

### Goal

Support only the statuses needed by current content and make ascension readable.

### Required statuses

- Bleed
- Poison: 25 total damage over 10 seconds
- Slow
- One-second incapacitation
- Spider tracking mark
- Numbing Pill curse suppression
- Driftseed gravity/knockback modifier
- Layer 1 curse modifiers
- Layer 2 health-cap stacks

### Tasks

- Implement effect add, refresh, stack, tick, remove, save, and UI signals.
- Implement one configurable curse-distance tracker independent of screen resolution.
- Implement 10-second stillness reference reset.
- Implement Layer 1 and Layer 2 `CurseProfile` Resources.
- Apply healing through one function that respects healing multiplier and Layer 2 cap.
- Apply throwing through one function that respects range modifiers.
- Ensure pill suppression pauses new curse applications without corrupting the depth reference.
- Add readable feedback for poison progress, bleed, stun, tracking, pill duration, and curse application.

### Acceptance tests

- Poison deals exactly 25 total damage over 10 seconds at normal conditions.
- Bandage stops bleed but not poison.
- Layer 2 health cap never falls below 50 health.
- Staying still for 10 seconds resets the curse reference as designed.
- Descending does not accidentally trigger curse.
- Save/Continue preserves persistent effects and safely resets transient stun.

## J. Shops, Currency, Delivery Progression, and Gates — P0

### Goal

Complete the economic loop and whistle progression.

### Tasks

- Currency display and transaction API.
- Surface shop buy/sell UI.
- Layer 2 limited-stock shop with 75% buy price.
- Item sale values read from `ItemDefinition`.
- Surface delivery count updated by configurable item-unit rule.
- Blue Whistle threshold event and text bubble.
- Whistle replacement and surface replacement service.
- Senior diver Blue Whistle check.
- Final gatekeeper completion state and Moon Whistle award.
- Save all money, stock, delivery, and gate states.

### Acceptance tests

- Player starts with 50g and cannot buy without enough money.
- Selling at surface uses full value.
- Selling at Layer 2 uses rounded 75% value.
- Limited stock cannot be purchased twice after depletion or Continue.
- Delivery threshold is tunable without changing shop code.
- Blue and Moon Whistles award once and replace the current whistle.

## K. HUD, Inventory UI, Dialogue, and Feedback — P0

### Goal

Make every necessary rule understandable to a first-time jam audience.

### Required HUD

- Health and reduced-healing cap
- Money
- Two hotbar slots with quantities and active selection
- Backpack/inventory overlay
- Whistle slot
- Active status icons or compact text
- Numbing Pill remaining duration
- Delivery progress before Blue Whistle
- Interaction prompts
- Autosave indicator

### Dialogue system tasks

- `DialogueSequence` Resource and reusable bubble scene.
- Advance input, skip/fast advance, speaker name, and optional portrait.
- Gameplay lock while required dialogue is active.
- Persistent one-time trigger support.
- Required sequences from Section 3.9.

### Feedback tasks

- Damage flash and direction
- Knockback/stun indication
- Inventory-full notice
- Item pickup/use/throw feedback
- Unknown versus known description presentation
- Curse onset and active modifiers
- Shop transaction result
- Gate denial or success
- Newly learned knowledge on death

### Acceptance tests

- A new audience member can find controls without explanation from a developer.
- Text bubbles never permanently lock the player.
- UI remains legible during screen discoloration and Hushcap effects.
- Inventory danger is visible but does not hide its own controls.
- Ending and death screens always accept input.

## L. Art, Animation, Audio, and Presentation Integration — P1 after placeholders

### Goal

Allow contributors to work independently without blocking code.

### Asset contract

- Programmers provide placeholder scenes and required animation names early.
- Artists deliver sprites at agreed scale and pivot/origin conventions.
- Collision shapes remain programmer-owned unless explicitly coordinated.
- Enemy scenes expose animation states: idle, move, telegraph, attack, hit, death as needed.
- Items require inventory icon, world sprite, and optional thrown sprite.
- UI assets support nine-patch scaling where appropriate.
- Audio files use stable event names rather than being called directly from unrelated scripts.

### Required audio

- Menu confirm/cancel
- Player movement and landing
- Multitool use
- Item pickup, use, throw, and break
- Player damage, healing, poison, bleed, and curse
- Enemy telegraphs and attacks
- Lantern Snail scream
- Shop transaction
- Whistle/progression award
- Ending cue

### Safety and readability

- Avoid harsh full-screen flashes.
- Ensure screen discoloration, Hushcap, and snail dazzle stack without making the game completely unreadable.
- Keep attack telegraphs visible against both meadow and inverted-forest backgrounds.

## M. Debug Tools, QA, Balance, and Builds — P0

### Goal

Make the full game testable within minutes rather than requiring repeated long runs.

### Debug tools

- Choose or display seed
- Teleport to surface, each section slot, both shops, both gates, and ending
- Give any item and set quantity
- Set money
- Set delivery count and whistle
- Apply or clear any status
- Force curse trigger
- Spawn or remove any enemy
- Show enemy detection and state
- Show placer IDs/results
- Show persistent-object IDs
- Force autosave/load
- Kill player
- Clear run save while retaining knowledge
- Clear all save data

### Balance data

Keep these editable without code changes:

- Prices and shop stock
- Delivery threshold/counting rule
- Enemy damage, health, speed, detection, knockback, cooldowns, and group sizes
- Item durations, charges, throw values, durability, and sale values
- Curse distance, stillness time, durations, ranges, and multipliers
- Loot and enemy spawn chances

### Acceptance tests

- A tester can reach any encounter in under one minute using debug tools.
- The exported build contains no visible debug UI by default.
- A full New Game-to-Moon Whistle playthrough succeeds.
- The same seed reproduces a reported layout and placer set.

---

# 6. Adding New Content

These processes are intentionally short. If adding content requires editing unrelated systems, stop and repair the foundation first.

## 6.1 Adding a New Item

1. Duplicate the item Resource template.
2. Assign a unique stable ID, names, descriptions, icon, sprite, stack size, price, sale value, and discovery threshold.
3. Choose an existing behavior or create one small behavior script/scene implementing the item interface.
4. Configure use, throw, impact, consumption, retrieval, and persistent-state rules.
5. Register the Resource in `ContentCatalog`.
6. Add the item to one or more loot/source pools.
7. Test through debug grant, pickup, stacking, use, throw, sale, autosave, Continue, death, and New Game.
8. Add art/audio hooks without changing inventory code.

## 6.2 Adding a New Enemy

1. Duplicate the closest enemy scene template.
2. Assign an `EnemyDefinition` with a unique ID and tuning data.
3. Reuse shared health, hitbox, sight, sound, status, knockback, and persistence components.
4. Write only the small state machine unique to the enemy.
5. Implement relevant shared reactions such as sound, force, slow, obstruction, or target override.
6. Add animation and audio hooks.
7. Add the enemy to a placer pool; never edit the world generator for an enemy addition.
8. Test in an arena, then in one real section.
9. Test death, Continue, relic interaction, and out-of-bounds recovery.
10. Tune through Resource values rather than code constants.

## 6.3 Adding a Section Variation

1. Duplicate the correct slot template, not an unrelated section.
2. Preserve the required origin, dimensions, seam anchors, and bounds.
3. Author static terrain and collision.
4. Place enemy, loot, source, story, and gate markers with unique IDs.
5. Confirm both descent and ascent paths.
6. Confirm at least one route does not require randomly absent loot.
7. Validate the seam against both neighbouring variation possibilities.
8. Run the section validator.
9. Test with relevant flyer, knockback, rope, and curse behavior.

---

# 7. Fourteen-Day Schedule

The schedule is milestone-based. Tasks within a milestone may be claimed freely.

## Day 1 — Project and Export Foundation

- Lock repository workflow, folder structure, Input Map, resolution, and scene ownership.
- Create menu, gameplay shell, surface placeholder, and player placeholder.
- Create minimal Autoloads and data templates.
- Produce and share the first exported build.
- Lead locks final gatekeeper pass condition or chooses the simplest placeholder condition.

**Exit condition:** Everyone can run the project and exported build; New Game reaches a controllable placeholder player.

## Day 2 — Player, Inventory Skeleton, World Slot Contract

- Reliable movement, camera, health, damage, interaction, and pause.
- Five-slot backpack, two-slot hotbar, pickup, use, and throw skeleton.
- Section template, fixed slot positions, A/B selection skeleton.
- Enemy and loot placer templates.
- Meta/run save schemas drafted.

**Exit condition:** Player can pick up and throw one item while moving through two connected graybox sections.

## Day 3 — First Vertical Slice

- Multitool, breakable rock, Throwable Rock, rope, and bandage.
- One enemy using shared damage/knockback.
- Surface shop prototype and money.
- Basic autosave and Continue.
- Curse tracker with placeholder profile.
- Lead locks curse tuning ranges and Layer 2 gatekeeper rule.

**Exit condition:** Exported build supports New Game, buy, descend, collect/use, ascend, curse, sell, save, menu, and Continue in a small slice.

## Day 4 — Item and Effect Foundations

- Generic thrown-item behavior.
- Status foundation: bleed, poison, slow, stun, mark, modifiers.
- Sun Sphere, Rattlepod, Hushcap, and Cling Resin.
- Inventory danger overlay and known/unknown descriptions.
- Deterministic placer results and persistent collected IDs.

**Exit condition:** Four relics work against the first enemy in the integrated build and survive save rules.

## Day 5 — Layer 1 Graybox and Core Enemies

- One graybox variation for every Layer 1 slot.
- Amphibian, bird, thorn bloom, and Lantern Snail.
- Driftseed and snail harvesting.
- Persistent ropes across the route.
- Start Layer 1 art and audio replacement.

**Exit condition:** Surface-to-Layer-1-gate route is physically traversable on both sides.

## Day 6 — Layer 1 Threat Loop

- Spider, poison, tracking mark, and big flyer.
- Obstruction and cave safety tests.
- Senior diver gate interaction.
- Delivery count and Blue Whistle award.
- Silver Weight behavior and durability.

**Exit condition:** A player can complete repeated surface excursions, earn Blue Whistle, and pass the Layer 1 gate.

## Day 7 — Layer 1 Integration Day

- Full Layer 1 playtest with economy, curse, items, enemies, and persistence.
- Repair blockers before adding Layer 2 complexity.
- Implement missing feedback and debug shortcuts.
- Create one clean exported milestone build.

**Exit condition:** Layer 1 is a complete small game with no critical blocker.

## Day 8 — Layer 2 Graybox and Shop

- One graybox variation for every Layer 2 slot.
- Inverted-canopy movement and rope tests.
- Safe midpoint shop with limited stock and 75% sale pricing.
- Layer 2 curse profile and health cap.
- Layer 2 story/shop bubbles.

**Exit condition:** Player can travel from Layer 1 gate to the final Layer 2 gate placeholder and return to the midpoint shop.

## Day 9 — Layer 2 Enemies and Ending

- Monkey, stronger bird data variant, small flyer group, and hippo.
- Final gatekeeper pass condition.
- Moon Whistle award and ending screen.
- Enemy/item reactions tested in inverted terrain.

**Exit condition:** Complete graybox New Game-to-ending route exists using debug progression.

## Day 10 — Feature Completion

- Finish all remaining P0 item behaviors, story bubbles, UI, persistence fields, and content placements.
- Validate all section seams.
- Validate full save/Continue and death/new-knowledge flow.
- Disable or defer unfinished P1 systems.

**Exit condition:** All P0 systems exist; no new P0 architecture begins after today.

## Day 11 — Feature Freeze and Content Integration

- Feature freeze.
- Integrate final or near-final art, animation, audio, and VFX.
- Create second section variations only if the complete route remains stable.
- Run first non-developer playtests.

**Exit condition:** Exported build is presentation-complete even if some variation content is reused.

## Day 12 — Balance and Persistence Testing

- Tune prices, spawn chances, damage, knockback, item use, curse, and delivery count.
- Test multiple seeds.
- Test autosave during shops, enemy encounters, item throws, and layer changes.
- Test long run, death, and New Game knowledge carryover.

**Exit condition:** No known critical progression, persistence, or crash bug.

## Day 13 — Release Candidate

- Complete at least three full exported-build runs using different seeds.
- Test on another machine.
- Fix only critical/high bugs and quick presentation problems.
- Finalize controls, credits, audio levels, and ending.
- Prepare presentation route and backup save if allowed by jam rules.

**Exit condition:** Release candidate can be submitted immediately.

## Day 14 — Submission and Demonstration

- Freeze code except submission-blocking fixes.
- Produce final export and backup export.
- Verify clean install, New Game, Continue, death, and ending.
- Package required files and submit early.
- Rehearse the short audience demonstration.

**Exit condition:** Submission is uploaded and independently launch-tested.

---

# 8. Dependency and Parallel-Work Guide

| Work | Can start immediately | Depends on | Avoid editing simultaneously |
| --- | --- | --- | --- |
| Player movement | Yes | Input Map | Player root scene |
| Menu/UI mockups | Yes | Resolution choice | Main UI scene |
| Item data | Yes | ID conventions | Content catalog file |
| Enemy test arenas | Yes | Damage interface | Shared enemy base |
| Section grayboxing | After slot contract | Section dimensions | Same section scene |
| Art production | After scale/animation contract | Placeholder scene list | Programmer collision scenes |
| Audio production | Yes after event list | Event naming | Audio bus setup |
| SaveManager | After state schema | Stable IDs | Autoload save script |
| Shops | After inventory/money API | Item definitions | Shop UI scene |
| Curse | After player modifiers | Effect interface | Player stats script |
| Enemy placers | After section/ID contract | Content catalog | Generator script |
| Story bubbles | After input/control lock | Dialogue Resource | Main dialogue scene |

The project lead should keep a short list of **ready, unclaimed tasks** so a developer can switch work without waiting for a new assignment.

---

# 9. Required Test Matrix

## 9.1 Boot and Flow

- First boot with no save
- New Game with no knowledge
- New Game with known relics
- Continue after three-minute autosave
- Return to menu during gameplay
- Quit from gameplay
- Forced close shortly after autosave
- Invalid/corrupt run save

## 9.2 Persistence

- Collected placer remains empty
- Harvested plant remains harvested
- Defeated enemy remains dead
- Living important enemy restores safely
- Rope restores at correct position
- Dropped Silver Weight restores with correct durability
- Shop stock and money restore
- Selected section variations do not reroll
- Dialogue and gate triggers do not repeat incorrectly
- Death removes run but preserves knowledge
- New Game resets world and Red Whistle

## 9.3 Player and Inventory

- All five backpack and both hotbar slots filled
- Stack reaches eight and overflow is rejected or placed safely
- Inventory opened during enemy attack
- Use and throw with near and far cursor positions
- Pickup while inventory is full
- Frog theft with normal items present
- Frog theft with only whistle available
- Recover stolen whistle or obtain surface replacement
- Bandage during bleed, poison, and curse-reduced healing

## 9.4 Items

- Every item used with valid and invalid targets
- Every throwable impacts terrain, enemy, and player-adjacent space
- Temporary effects clean up
- Retrievable item does not duplicate
- Silver Weight first and second throws
- Info Book unlocks all descriptions
- Numbing Pill saves remaining time
- Lantern Snail harvest, scream, dazzle, lure, pickup, and sale

## 9.5 Enemies

- Each enemy alone and in intended groups
- Noise, sight, slow, force, weight, and obscuration reactions
- Birds near lethal falls
- Spider mark followed by flyer pursuit
- Flyer obstruction and lost sight
- Monkey group spacing and ledge handling
- Small flyer separation
- Hippo telegraph, charge, wall impact, knockback, and stun
- Both gatekeepers' pass and denial paths

## 9.6 Economy and Progression

- Exact starting 50g
- Full-price surface sale
- Rounded 75% Layer 2 sale
- Limited Layer 2 stock persistence
- Delivery threshold with stacks
- Blue Whistle awarded once
- Whistle replacement after loss
- Moon Whistle and ending awarded once

## 9.7 World and Curse

- Every A/B seam combination that can occur
- Both east and west routes
- Descent and ascent through every section
- Curse does not trigger during ordinary jumping or descent
- Ten-second stillness reset
- Layer 1 curse modifiers
- Layer 2 health-cap stacks to 50%
- Five-minute pill across a layer transition
- Ropes do not create out-of-bounds shortcuts

---

# 10. Cut Order if Schedule Slips

Cuts must preserve a complete run.

## Cut first

1. Additional VFX, portraits, typewriter text, and decorative UI animation.
2. Advanced audio variation.
3. Creative alternate solution for the final gatekeeper; retain one reliable pass condition.
4. Exact saving of transient enemy AI state; restore surviving enemies at safe placer states.

## Cut second

5. Replace unfinished second section variations with completed variations or light redresses.
6. Reduce monkey group size and small-flyer count rather than cutting their identity.
7. Simplify senior diver combat while preserving Blue Whistle passage.
8. Simplify item-enemy special reactions to the shared essentials: sight, sound, slow, force, and damage.

## Cut only as emergency fallback

9. Reuse Layer 1 bird directly in Layer 2 without new visuals.
10. Make the final gatekeeper a dialogue/gate interaction instead of combat.
11. Use static shop stock instead of randomized stock, while keeping limited quantities.

## Never cut

- Boot, New Game, Continue, pause, autosave, death, and ending
- One complete route through both layers
- Surface economy and Blue Whistle progression
- Senior diver Blue Whistle gate
- Layer 2 midpoint shop
- Final gatekeeper and Moon Whistle ending
- Core inventory and item use/throw loop
- Rope traversal
- Both layer curse packages
- Enough enemies to communicate each layer's identity
- Export and clean-machine testing

---

# 11. Daily Team Check

At the start of each session:

- What is the current playable milestone?
- Which P0 task is ready and unclaimed?
- Which shared files are currently claimed?
- Is anyone blocked by an interface or missing asset?

At the end of each session:

- What became playable in the main build?
- What broke?
- What remains unintegrated?
- Does the exported build launch?
- Can the latest milestone still be completed?
- Which critical/high bugs are open?
- What is tomorrow's single integration priority?

The project lead should play the integrated build daily, maintain scope, lock unanswered values quickly, and prevent optional polish from hiding broken progression.

---

# 12. Final Completion Standard

The jam build is complete when:

- The exported game boots to a usable menu.
- New Game creates a seeded world with Red Whistle, multitool, and 50g.
- Continue restores a living run after autosave.
- Knowledge survives death and New Game while everything else resets.
- Both layers assemble from authored seamless sections.
- Deterministic enemy and loot placers behave consistently.
- The player can use, throw, carry, stack, sell, and learn the complete item roster.
- Layer 1 supports surface-return progression and Blue Whistle acquisition.
- The senior diver permits Blue Whistle passage.
- Layer 2 contains its midpoint shop and planned enemy identities.
- Both ascension curses work and communicate their consequences.
- The final gatekeeper can be passed reliably.
- The Moon Whistle and ending are awarded exactly once.
- No critical bug blocks a complete exported-build playthrough.
- The submission is tested on a machine other than the primary development machine.
