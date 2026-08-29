# Layer 1 Enemy and Item Design Reference

> **Archived:** old concept baseline. Current contracts: [`../../implementation/`](../../implementation/) and [`../../enemy_implementation_handoff.md`](../../enemy_implementation_handoff.md).

> Status: current implementation reference for Layer 2 concept development.
> Baseline: `feature/contents`, 16 August 2026.
> This document describes what the current build actually supports. Numerical values are provisional tuning, not final balance.

## 1. Why This Document Exists

Layer 2 concepts should extend the existing game instead of becoming a separate combat system. This reference explains:

- the design philosophy behind the current enemies and items;
- what every implemented enemy and item currently does;
- the intended player experience and purpose of each piece of content;
- how enemies, items, effects, terrain, and progression interact;
- which roles are already occupied, so Layer 2 can introduce meaningful new problems and tools.

The authoritative high-level design remains [gdd_en.md](../../gdd_en.md). Technical contracts remain in [layer_1_enemies.md](../../implementation/layer_1_enemies.md), [layer_1_items.md](../../implementation/layer_1_items.md), and [effects.md](../../implementation/effects.md).

## 2. Core Content Philosophy

### 2.1 The player solves situations, not health bars

The player is deliberately vulnerable. Direct damage is possible, but most encounters should also support avoidance, distraction, manipulation, escape, or preparation. An enemy is successful when it changes how the player reads a room, chooses a route, or spends an item—not merely when it deals damage.

### 2.2 Every creature belongs to the world

Enemies react through shared world rules:

- sight and sight obstruction;
- sound position, radius, and priority;
- physical force and knockback;
- damage and species-aware friendly fire;
- status effects;
- loose item ownership;
- light and authored terrain.

Creatures should feel like inhabitants with understandable triggers. Neutral hazards do not become conventional chasing enemies simply because the player approached them.

### 2.3 Items are verbs

Items are not divided into a simple weapon/consumable hierarchy. Each item contributes one or more verbs such as:

- illuminate;
- lure;
- silence sight;
- bind;
- float;
- climb;
- heal;
- suppress the Curse;
- strike;
- steal or recover ownership;
- trade immediate safety for weight or value.

Primary and secondary actions are explicit per item. Right click is usually a throw, but it is not a universal rule.

### 2.4 Interactions should create short stories

The preferred outcome is an interaction chain, for example:

1. a Cave Spider marks the player;
2. the mark causes the Large Flyer to commit to the player;
3. the player throws a Rattlepod away from the escape route;
4. the Flyer investigates the louder location;
5. the player uses a Rope prepared earlier to ascend.

This is more valuable than adding four unrelated attacks.

### 2.5 Descent and ascent ask different questions

Descending rewards curiosity and collecting. Ascending adds the Curse, limited mobility, route memory, and pressure from enemies that were previously easy to pass. Items can therefore be useful even without defeating anything: a Rope changes the return route, a Numbing Pill buys ascent time, and Driftseed makes a dangerous fall survivable while increasing knockback risk.

### 2.6 Failure must be readable

Dangerous actions use telegraphs or recognizable triggers. The player should be able to learn why an encounter failed and make a better decision next time. Surprise is acceptable once; unreadable punishment is not.

## 3. Shared Implementation Model

### 3.1 Enemies

Each enemy has:

- an `EnemyDefinition` resource for identity, species, tags, health, base speed, and scene;
- a dedicated scene and small enemy-specific state machine;
- `EnemySupport` for health, statuses, tags, damage, force, death, and persistence;
- optional sight and sound sensors;
- exported tuning values editable in the Godot Inspector.

There is no universal behaviour tree. Shared systems carry information; the enemy script decides what that information means.

All implemented enemies are killable. Damage from the same species is rejected, while damage from a different enemy species is allowed. This permits deliberate friendly-fire setups without letting identical enemies erase their own group.

### 3.2 Items

Each item has an `ItemDefinition` resource containing its ID, descriptions, category, icon, weight, stacking, economy values, and primary/secondary behaviours.

An inventory item, a thrown real item, and a temporary projectile are different things:

- `ItemStack` owns inventory quantity and serializable state;
- `ThrownItem` is a real, recoverable, persistent item in the world;
- `Projectile` is a temporary attack and cannot be collected;
- prepared relics temporarily transfer one inventory unit into an active held node.

Failed actions do not consume items. Real dropped items retain identity and can be stolen, collected, lost, or saved. Temporary projectiles and effect areas do not become inventory objects.

### 3.3 Weight

One weight value links several systems:

- inventory burden;
- movement after exceeding carry capacity;
- falling acceleration while overburdened;
- throw speed;
- thrown-item mass and force.

This makes carrying decisions part of traversal and combat instead of a separate economy-only statistic.

### 3.4 Effects

Effects use stable IDs and shared rules for duration, stacking, eligibility, persistence, ticking, and stat modifiers. Important current effects include:

| Effect | Main purpose |
| --- | --- |
| Bleed | Persistent chip damage that Bandage explicitly removes. |
| Poison | Delayed damage that Bandage does not remove. |
| Spider Slow | Short movement penalty from Cave Spider projectiles. |
| Tracking Mark | Makes the Large Flyer prioritize the player. |
| Dazzled | Obscures the player and disables enemy sight. |
| Resin Bound | Strong movement/jump reduction while inside a resin provider. |
| Driftseed | Slow fall/flight but increased knockback received. |
| Healing | Healing over time rather than instant recovery. |
| Curse Suppression | Stored protection that consumes ascent thresholds. |
| Layer 1 Curse | Temporary movement, healing, throw, and colour penalties. |
| Layer 2 Curse | Health-cap stacks, throw penalties, colour change, and movement interruptions. |

Flying enemies ignore ordinary slow and resin. Driftseed is the intentional anti-flight exception.

## 4. Current Enemy Roster

### 4.1 Tongue Amphibian

**Role:** resource thief and low-damage pressure enemy.

**Current behaviour:**

- Looks for nearby loose world items before targeting the player.
- Approaches a target, telegraphs a tongue action, and checks that terrain does not block the tongue.
- Takes one real item, not a copy.
- If stealing from the player, it prioritizes the active ordinary item, then other hotbar/backpack items, then the Multitool, then the physical whistle.
- Applies a one-second slow after successful theft.
- Deals only 1 damage if the player has nothing it can steal.
- Retreats toward its authored origin while carrying something.
- Drops its carried item after any accepted hit or on death.
- Returns a carried item to the authored lost-item marker if it leaves world bounds.

**Player experience:** it creates panic through loss of control over resources, not raw damage. The player decides whether to chase, strike once to recover the item, sacrifice the item, or manipulate the frog toward danger.

**System relationships:**

- Directly uses the real item ownership system.
- Loose thrown items can distract it from the player.
- A single Multitool/rock hit can recover the stolen item without requiring a kill.
- Other enemy attacks can also force a drop because cross-species damage is valid.
- The Senior Diver's return marker prevents important stolen objects from disappearing off-map.

**Design purpose:** teaches that items physically exist in the world and that enemies can change the player's plan without simply reducing health.

**Implementation:** `game/enemies/layer1/tongue_amphibian.gd`, `data/enemies/tongue_amphibian.tres`.

### 4.2 Knockback Bird

**Role:** spatial threat and cliff/nest guardian.

**Current behaviour:**

- Patrols around an authored nest or flight region.
- Remains neutral while the player is outside nest proximity.
- Locks one telegraphed swoop toward the player's captured position.
- Applies mostly horizontal and partly upward force on contact.
- Damage during a swoop cancels the attack into recovery.
- Two bird hits within two seconds deal additional damage through a species-wide player counter.
- Ignores ordinary physical force but accepts valid damage and statuses.

**Player experience:** one bird is primarily a displacement problem. A flock becomes dangerous through timing and terrain. The real threat is often the ledge, fall, Curse ascent loss, or another hazard behind the player.

**System relationships:**

- Driftseed slows its flight, but also makes the affected player receive more knockback.
- Hushcap can break sight and prevent clean attack setup.
- Silver Weight kills it as a `small_enemy` if the player can land the throw.
- Rope preparation reduces the cost of being displaced vertically.
- Resin and ordinary slow intentionally do not affect it.

**Design purpose:** makes authored geometry part of the enemy encounter and teaches that force can matter more than damage.

**Implementation:** `game/enemies/layer1/knockback_bird.gd`, `data/enemies/knockback_bird.tres`.

### 4.3 Thorn Bloom

**Role:** stationary neutral hazard and area denial.

**Current behaviour:**

- Does not see, hear, chase, or patrol.
- Triggers from proximity, damage, or physical agitation.
- Telegraphs, then fires six gravity-affected needles: three to each side.
- Each needle deals 10 provisional damage and applies Bleed.
- Needles disappear on actor impact or stick to terrain.
- The volley reloads after five provisional minutes.
- Killing the Bloom cancels an uncompleted attack, but already-fired needles remain.

**Player experience:** it asks the player to notice spacing and decide whether to trigger it safely, route around it, destroy it, or use its volley against another creature.

**System relationships:**

- Bandage is the direct response to Bleed.
- Hushcap does not matter because the Bloom has no sight.
- Sound distractions do not matter because it has no hearing.
- Physical impacts can deliberately trigger it from safety.
- Its needles can participate in cross-species damage situations.

**Design purpose:** proves that not every enemy should use player detection and provides a predictable environmental weapon.

**Implementation:** `game/enemies/layer1/thorn_bloom.gd`, `game/projectiles/thorn_needle.gd`, `data/enemies/thorn_bloom.tres`.

### 4.4 Lantern Snail

**Role:** moving neutral hazard, light source, sound event, and relic source.

**Current behaviour:**

- Crawls slowly near its authored origin and attempts to follow connected surfaces.
- Acts as a world light source.
- Becomes agitated by close player proximity, accepted damage, strong physical impact, or nearby sound.
- Telegraphs before screaming.
- The scream emits a priority-9 sound and applies distance-scaled Dazzled through line of sight.
- Has only 2 health in current data.
- Death drops one persistent Lantern Crystal.

**Player experience:** the Snail is useful and dangerous at the same time. It may illuminate a space, expose the player through noise, blind nearby actors, or become a valuable relic if killed.

**System relationships:**

- Its scream can redirect sound-sensitive creatures.
- Dazzled disables enemy sight, so deliberately triggering it may help the player.
- Its light repels Cave Spiders.
- Killing it creates the Lantern Crystal, transferring an enemy behaviour into player-controlled item form.
- A Rattlepod or other sound can trigger it and create a second, stronger sound event.

**Design purpose:** demonstrates ecological chain reactions and gives killing a meaningful tradeoff: remove a living light/hazard to gain a portable flash/lure.

**Implementation:** `game/enemies/layer1/lantern_snail.gd`, `data/enemies/lantern_snail.tres`.

### 4.5 Cave Spider

**Role:** ranged status applier and setup enemy for a larger threat.

**Current behaviour:**

- Moves along its configured gravity surface near an authored origin.
- Uses short-range sight and reacts to high-priority sound.
- Stops and gives a 0.7-second warning before firing.
- Fires a temporary projectile rather than a collectible item.
- The projectile deals 3 provisional damage and applies Spider Slow, Poison, and Tracking Mark together.
- Nearby active light makes it move away.
- Priority-8-or-higher sound makes it abandon its target and retreat away from the sound source.
- Silver Weight kills it as a `small_enemy`.

**Player experience:** the immediate projectile is modest; the combined statuses create the real emergency. The player becomes slower, takes delayed damage, and is promoted to the Large Flyer's highest-priority target.

**System relationships:**

- Sun Sphere creates the light response.
- Rattlepod and Lantern Crystal/Snail events can force it away.
- Bandage cannot remove Poison, so avoidance remains important.
- Tracking Mark directly links this small enemy to the Layer-global Flyer.
- Hushcap blocks sight and prevents a clean shot.

**Design purpose:** teaches that enemy combinations are more dangerous than isolated statistics. It converts a local mistake into layer-wide pressure.

**Implementation:** `game/enemies/layer1/cave_spider.gd`, `game/projectiles/projectile.gd`, `data/enemies/cave_spider.tres`.

### 4.6 Large Layer 1 Flyer

**Role:** persistent layer-wide apex threat.

**Current behaviour:**

- Exists as one living actor across Layer 1 rather than one copy per section.
- Roams between authored points of interest.
- Requires four seconds of continuous ordinary sight before committing to the player.
- Tracking Mark immediately satisfies the target lock.
- High-priority sound redirects its search unless the player is marked.
- Gives a warning, then commits to a fast dive toward a captured position.
- Deals 75 provisional damage and force on a successful dive.
- Has 500 provisional health.
- Ignores ordinary force/slow, accepts Poison, distraction, Driftseed, and Silver Weight damage.
- If alive, transfers into the Layer 2 shop area with persistent health/status but reset transient AI.

**Player experience:** its presence makes open space feel exposed. The four-second sight requirement gives the player time to break line of sight, use terrain, or create a distraction. A Tracking Mark removes that comfort.

**System relationships:**

- Cave Spider Tracking Mark is its strongest player-target override.
- Rattlepod, Lantern Crystal, Whistle, and Snail screams can redirect it when the player is unmarked.
- Hushcap breaks sight lock.
- Driftseed reduces flight speed.
- Silver Weight deals 200 damage instead of instantly killing it.
- It persists into Layer 2, allowing Layer 1 decisions to alter a later encounter.

**Design purpose:** gives the whole layer memory and continuity. It pressures route planning without becoming a conventional mandatory boss.

**Implementation:** `game/enemies/layer1/large_flyer.gd`, `game/world/large_flyer_poi.gd`, `data/enemies/large_layer1_flyer.tres`.

### 4.7 Senior Diver

**Role:** systemic gatekeeper and progression check.

**Current behaviour:**

- Guards a restricted authored zone beside an otherwise usable route.
- Recognizes earned Blue Whistle rank from progression state, even if the physical whistle is missing.
- Warns and knocks back an unranked trespasser entering the restricted radius.
- Chases while it retains sight, then returns to its post after three seconds without sight.
- Telegraphs a short grab at close range.
- A successful grab locks the player for one second, confiscates map-origin items, and returns the player to the Surface.
- Does not confiscate starting, purchased, progression, or other non-map-origin items.
- Can be distracted, bypassed, or defeated; death never hard-locks the gate.

**Player experience:** the Diver creates a social/progression obstacle that still obeys gameplay systems. The player may earn authorization, find a route, distract the guard, accept confiscation risk, or fight.

**System relationships:**

- Whistle rank is progression data; the physical whistle is a real stealable item. The two concepts are deliberately separate.
- Hushcap can break sight during a bypass.
- Rattlepod, Lantern Crystal, or Whistle can create a distraction.
- Driftseed is eligible because the Diver has the `gatekeeper` tag.
- Item origin determines what is confiscated.

**Design purpose:** validates that progression, inventory provenance, and systemic AI can coexist without a single hard-key solution.

**Implementation:** `game/enemies/layer1/senior_diver.gd`, `data/enemies/senior_diver.tres`.

## 5. Current Item Roster

### 5.1 Permanent Tools and Progression Objects

#### Red and Blue Whistles

**Implementation:** a dedicated physical slot emits a priority-10 sound with a large radius. The physical whistle can be stolen or dropped. Earned rank is stored separately, so losing the object does not erase progression.

**Purpose:** combines fiction, progression, and the sound ecosystem. It is the strongest general sound tool but may attract or redirect more than the player intended.

**Key relationships:** distracts sound listeners; can trigger a Lantern Snail; can redirect the Large Flyer if the player is not marked; Blue rank neutralizes the Senior Diver's restricted-zone hostility.

#### Multitool

**Implementation:** primary action creates a short cursor-directed thrust. It deals 1 provisional damage and 40 force, breaks/harvests compatible sources, and briefly slows player movement. It cannot be thrown through secondary action, stacked, or sold, but it can be moved, dropped, stolen, lost, and replaced or purchased.

**Purpose:** dependable low-power utility. It prevents the player from being completely helpless while ensuring relics remain the interesting solutions.

**Key relationships:** recovers items from the Tongue Amphibian, triggers Thorn Bloom/Lantern Snail, damages ordinary enemies slowly, and opens breakable loot sources.

#### Rope

**Implementation:** primary places or extends a climbable rope at a valid nearby anchor. Placement checks reach, terrain, world bounds, and a clear vertical column. Each unit provides up to 160 px. Secondary throws the rope as a real object. Placed ropes persist through saves and scene transitions.

**Purpose:** lets preparation alter future traversal. It is mainly an ascent and recovery tool, not an emergency grappling hook.

**Key relationships:** counters vertical displacement from birds, creates escape routes before risky encounters, and reduces the traversal cost of the Ascension Curse.

### 5.2 Ordinary Object

#### Throwable Rock

**Implementation:** primary uses a weak held thrust. Secondary throws a persistent recoverable object with cursor-scaled speed, 2 base damage, weight-based force, and a visible trajectory preview.

**Purpose:** teaches the physical item/throw system with a cheap, understandable object.

**Key relationships:** agitates neutral hazards, recovers stolen items by hitting the frog, provides cross-species force/damage, and can become bait because it remains a loose item.

### 5.3 Supplies

#### Bandage

**Implementation:** cannot be used at full health. Successful use removes Bleed and applies Healing. The shared effect heals 2 health per second, but the current Bandage resource overrides its duration to 10 seconds, so the running implementation heals 20 total. Its description and implementation contract still say 25 seconds/50 total; this is a known content-data mismatch to resolve during tuning. It does not remove Poison. Secondary throws the unused Bandage as a real item.

**Purpose:** rewards surviving long enough to recover and distinguishes wound treatment from universal cleansing.

#### Info Book

**Implementation:** reveals all currently discoverable relic descriptions that remain unknown. It fails without consumption if everything is already known. Knowledge is meta progression. Secondary throws the unused book.

**Purpose:** gives the player a way to convert a run resource into understanding and supports experimentation without requiring external documentation.

#### Numbing Pill

**Implementation:** adds 300 seconds of Curse Suppression up to 999 seconds. Suppression is consumed by ascent thresholds rather than deleting the Curse system. Secondary throws the unused pill.

**Purpose:** preparation tool for the return journey. It buys safety but still asks the player to manage ascent pacing and inventory space.

### 5.4 Relics

#### Sun Sphere

**Implementation:** primary consumes one dormant sphere into a prepared 20-second held light. Secondary then throws the active light. Throwing an inactive sphere first deploys its light on impact. Active light fades near expiry and is registered as a world light source.

**Purpose:** portable visibility and creature control with a short life and a choice between keeping the light close or placing it elsewhere.

**Key relationships:** repels Cave Spiders and can change how a dark encounter is approached. Because it is a light rather than a sound, it solves a different problem from Rattlepod.

#### Lantern Crystal

**Implementation:** primary creates an immediate 180 px line-of-sight flash/lure around the player and consumes the crystal. Secondary throws it; first impact creates the same effect and consumes the world item. It emits a priority-9 sound over a 500 px radius and applies distance-scaled Dazzled for up to four seconds.

**Purpose:** powerful but brief crowd manipulation. Its position matters because walls block the flash.

**Key relationships:** comes from killing a Lantern Snail; disables enemy sight; triggers sound listeners; redirects the Large Flyer if the player is unmarked; can create both an escape window and a new attraction point.

#### Rattlepod

**Implementation:** primary activates one pod into a prepared object that emits ten priority-8 sound pulses at two pulses per second. The active pod can be thrown. An inactive pod is only a low-damage recoverable physical object. Active pods dropped by inventory/slot/save changes continue in the world rather than returning as an unspent inventory unit.

**Purpose:** sustained area control through sound. Unlike the Crystal's single flash/lure, it repeatedly holds attention at a chosen location.

**Key relationships:** drives Cave Spiders away, redirects the Large Flyer when unmarked, can agitate Lantern Snails, and draws other sound listeners. Repeated pulses may deliberately cause cascading reactions.

#### Hushcap

**Implementation:** primary creates a 48 px sight-blocking cloud at the player for 12 seconds. Secondary throws it and creates a larger 72 px cloud at first impact. The effect area is temporary and not restored after Continue.

**Purpose:** controlled sight denial. It allows escape, bypass, or prevention without damaging an enemy.

**Key relationships:** breaks sight-dependent attacks from the Cave Spider, Large Flyer, Senior Diver, and other visual hunters. It does nothing to Thorn Bloom and does not silence sounds.

#### Cling Resin

**Implementation:** primary creates a 36 px patch at the player; secondary throws it and creates a 64 px patch at first impact. The patch lasts 20 seconds. While inside, eligible actors use 0.25 movement speed, 0.1 jump strength, and 0.5 knockback received. Leaving removes only that patch's provider contribution.

**Purpose:** strong ground control with placement risk. It can protect a route or trap a grounded actor, but also hinders the player.

**Key relationships:** grounded enemies and the player are affected; flying enemies explicitly reject Resin Bound. Reduced knockback can be useful as well as harmful near bird encounters.

#### Driftseed

**Implementation:** primary consumes it to give the player 30 seconds of reduced falling gravity and a 140 px/s fall-speed cap while preserving normal ascent. It also increases knockback received by 50 percent. Secondary throws it; a valid small, flying, or gatekeeper target consumes it and receives the status, while a miss remains recoverable. Flight speed is reduced to 60 percent.

**Purpose:** dual-use mobility relic with an explicit tradeoff. It rescues falls and suppresses flying movement but makes force threats more dangerous.

**Key relationships:** slows Knockback Birds and the Large Flyer; affects the Senior Diver; does not become generic jump enhancement; creates a dangerous combination when the player is near birds or ledges.

#### Silver Weight

**Implementation:** primary toggles a prepared heavy state. While held active, movement is multiplied by 0.45 and jump strength by 0.35. Secondary throws it at a lower weight-adjusted speed. A meaningful impact kills `small_enemy` targets and deals 200 damage to the Large Flyer. The first impact converts the full item into `silver_weight_damaged`; the next meaningful impact destroys it. It has weight 12, occupies one item per slot, and has the highest current relic value.

**Purpose:** scarce decisive force with severe mobility, carrying, and durability costs. It is the closest Layer 1 item to a weapon, but its weight and two-use life prevent it from replacing the systemic toolkit.

**Key relationships:** hard-counters small enemies, heavily damages but does not instantly kill the apex Flyer, increases inventory burden, and becomes risky to carry during ascent.

## 6. Interaction Networks

### 6.1 Sound network

| Source | Priority/pattern | Typical use |
| --- | --- | --- |
| Ordinary throw | Low, single event | Local investigation or physical agitation. |
| Rattlepod | Priority 8, ten pulses | Sustained distraction and chain-reaction setup. |
| Lantern Crystal | Priority 9, single flash/lure | Strong reposition plus Dazzled. |
| Lantern Snail | Priority 9 scream | Dangerous world-generated lure and flash. |
| Whistle | Priority 10 | Strongest general-purpose attention command. |

Sound is not automatically beneficial. A louder tool wins attention but may activate more creatures and reveal the chosen position.

### 6.2 Sight and light network

- Hushcap creates an obstruction instead of globally disabling AI.
- Dazzled temporarily disables sight on affected enemies.
- Sun Sphere and Lantern Snail register as light sources.
- Cave Spiders actively move away from nearby light.
- Large Flyer and Senior Diver attacks require sight unless another system, such as Tracking Mark, overrides normal acquisition.

### 6.3 Force and terrain network

- Knockback Birds turn cliffs and hazards into damage multipliers.
- Rocks and Multitool provide small, reusable force.
- Silver Weight provides decisive force at a high cost.
- Resin halves received knockback while drastically limiting movement.
- Driftseed prevents dangerous fall speed but increases received knockback.
- Rope changes recovery options after displacement.

### 6.4 Status network

- Thorn Bloom creates Bleed; Bandage removes it.
- Cave Spider creates Slow, Poison, and Tracking Mark simultaneously.
- Bandage heals and removes Bleed but does not solve Poison.
- Tracking Mark connects the Cave Spider to the Large Flyer.
- Driftseed is both player mobility and targeted anti-flight control.
- Dazzled helps against sight but not proximity-only or non-sensory hazards.

### 6.5 Ownership and economy network

- Tongue Amphibian moves real items between owners.
- Thrown items remain recoverable and can become frog targets.
- Lantern Snail death creates a valuable player relic.
- Senior Diver confiscates only map-origin items.
- Relics compete between immediate use, surface sale value, delivery value, weight, and inventory space.
- Silver Weight is powerful but heavy and degrades, making its economic value part of the use decision.

## 7. Enemy-to-Tool Readability Matrix

This table lists meaningful responses, not mandatory counters.

| Enemy | Avoid/escape | Manipulate | Direct response | Important trap |
| --- | --- | --- | --- | --- |
| Tongue Amphibian | Keep distance, block tongue with terrain | Offer/throw a loose item | Hit once to recover theft | Dropped valuables can attract it. |
| Knockback Bird | Leave nest region, use cover, prepare Rope | Break sight with Hushcap | Driftseed or Silver Weight | Driftseed on player increases bird knockback. |
| Thorn Bloom | Stay outside trigger radius | Trigger remotely toward another actor | Destroy before/after volley | Sound and Hushcap do nothing. |
| Lantern Snail | Avoid proximity/noise | Trigger scream to dazzle/lure others | Kill for Lantern Crystal | Removing it also removes a living light. |
| Cave Spider | Break sight, use terrain | Light or priority-8 sound drives it away | Multitool/rock/Silver Weight | One hit can create three statuses and attract Flyer. |
| Large Flyer | Break four-second sight lock, use Hushcap | Loud sound redirects when unmarked | Driftseed, Poison, Silver Weight | Tracking Mark overrides normal distraction priority. |
| Senior Diver | Stay outside restriction or earn Blue rank | Distract and break sight | Bypass or defeat | Grab confiscates map-origin loot and returns player. |

## 8. Example Systemic Encounter Chains

### 8.1 Snail alarm escape

The player throws a rock near a Lantern Snail. The Snail screams, dazzling a nearby Cave Spider and creating a priority-9 sound. The Spider retreats and the Large Flyer searches the scream location. The player crosses while sight is disrupted.

### 8.2 Bad Driftseed decision

The player uses Driftseed to descend safely into an exposed nest. Falling is controlled, but the increased knockback makes the first bird swoop launch the player farther than expected. A Rope placed before descent would have changed the recovery.

### 8.3 Spider escalation

A Cave Spider projectile hits the player. Poison creates delayed health pressure, Slow reduces escape speed, and Tracking Mark causes the Flyer to prioritize the player. A normal Rattlepod distraction no longer overrides the mark, so the player must break the encounter another way or survive until the mark expires.

### 8.4 Resource theft decision

The player throws a valuable relic, misses, and the item settles nearby. A Tongue Amphibian targets the loose relic instead of the player and retreats with it. The player can chase, strike once, use another enemy's attack to force a drop, or abandon the value.

### 8.5 Resin at a ledge

The player places Resin near a bird encounter. Movement and jumping become poor, but knockback is halved. The same patch can be protection from displacement or a trap that prevents escape, depending on placement.

## 9. Guidance for Layer 2 Concepts

Layer 2 should deepen the network, not merely increase health and damage.

### 9.1 Requirements for a strong new enemy concept

A Layer 2 enemy should ideally:

1. occupy a role not already fully covered;
2. use at least two existing shared channels such as sight, sound, force, status, light, ownership, terrain, or Curse;
3. have a readable trigger and consequence;
4. allow at least one non-kill response;
5. interact with multiple old items, including at least one unexpected use;
6. combine differently with another enemy instead of only stacking damage;
7. expose tuning through data/Inspector values;
8. remain understandable when encountered during ascent pressure.

Promising unexplored roles include:

- an enemy that changes terrain access temporarily;
- a creature that consumes, transforms, or carries effect areas;
- a predator that hunts other creatures before targeting the player;
- an enemy that reacts to player weight or vertical movement;
- a creature that creates temporary safe zones at a cost;
- an enemy that manipulates Curse pacing without directly applying the Curse;
- a coordinated pair with different sensory rules;
- a guardian whose weak point is created by another creature's behaviour.

### 9.2 Requirements for a strong new item concept

A Layer 2 item should ideally:

1. provide a new verb or a new tradeoff, not a stronger copy of a Layer 1 item;
2. work on several enemies or world situations;
3. have distinct primary and secondary decisions where useful;
4. participate in weight, ownership, persistence, and economy rules;
5. have a clear inactive-throw result;
6. state whether activation consumes, prepares, transforms, or deploys the real item;
7. interact with at least one Layer 1 creature so old content remains relevant;
8. support descent, ascent, or both intentionally.

Promising unexplored verbs include:

- swap positions;
- anchor against movement;
- reflect or redirect a projectile;
- temporarily invert or rotate gravity for an object;
- preserve or transfer a status;
- create a decoy silhouette without sound;
- carry an effect area with the player;
- reveal hidden routes or creature intentions;
- alter item weight temporarily;
- convert one environmental danger into another.

### 9.3 Roles already occupied

Avoid making a direct replacement unless the different cost creates a real decision:

| Existing role | Current content |
| --- | --- |
| Cheap physical projectile | Throwable Rock |
| Basic close utility/damage | Multitool |
| Permanent route preparation | Rope |
| Healing and Bleed treatment | Bandage |
| Curse protection | Numbing Pill |
| Portable light/Spider repellent | Sun Sphere |
| One-shot flash and strong lure | Lantern Crystal |
| Sustained sound distraction | Rattlepod |
| Sight obstruction | Hushcap |
| Ground slow/knockback resistance | Cling Resin |
| Slow fall and anti-flight | Driftseed |
| Heavy decisive impact | Silver Weight |
| Theft/resource disruption | Tongue Amphibian |
| Aerial knockback | Knockback Bird |
| Stationary projectile hazard | Thorn Bloom |
| Reactive flash/lure creature | Lantern Snail |
| Ranged status setup | Cave Spider |
| Layer-wide apex hunter | Large Flyer |
| Systemic progression guard | Senior Diver |

### 9.4 Layer 2 combination target

Layer 2 should contain encounters where the player recognizes old rules but must recombine them. Good escalation examples are:

- sound solves one enemy but wakes another;
- light creates safety from one creature but reveals the player to another;
- a health-cap Curse stack makes slow attrition more threatening than burst damage;
- movement-stop moments make prepared terrain/cover important;
- an enemy relocates loose items, changing frog bait and item recovery;
- the transferred Large Flyer interacts with a new Layer 2 creature instead of simply retaining more health.

The powerful quest relic should make the final gauntlet safer through systemic leverage, not serve as a hard key or instant screen clear.

## 10. Content Review Checklist

Before approving a Layer 2 concept, answer:

- What decision does this content ask from the player?
- What readable event starts its danger or benefit?
- Which existing systems does it use?
- Which existing enemies/items react to it?
- Can it be avoided or manipulated without killing?
- What changes during ascent?
- What is its cost in time, position, weight, health, inventory, knowledge, or attention?
- Can the player understand failure after seeing it once?
- Does it create at least one interaction chain?
- Is it still distinct when all provisional numbers are removed from the description?

If the final answer is only “it deals more damage” or “it is a stronger version,” the concept needs another interaction.

## 11. Main Source Locations

| Content | Definition | Runtime implementation |
| --- | --- | --- |
| Enemy identity/data | `data/enemies/*.tres` | `data/definitions/enemy_definition.gd` |
| Layer 1 enemies | Individual `.tres` files | `game/enemies/layer1/` |
| Shared enemy support | — | `game/enemies/enemy_support.gd` |
| Item identity/data | `data/items/*.tres` | `data/definitions/item_definition.gd` |
| Item behaviours | Embedded in item resources | `game/items/behaviors/` |
| Persistent real item | Item definition/world scene | `game/items/world/thrown_item.gd` |
| Prepared relic | Item behaviour settings | `game/items/world/prepared_relic.gd` |
| Temporary projectile | Attack configuration | `game/projectiles/projectile.gd` |
| World effect areas | Item shapes/durations | `game/items/world/world_effect_area.gd` |
| Status effects | `data/effects/*.tres` | `core/status/status_controller.gd` |
| Sight and sound | Sensor configuration | `core/sensing/` |
| Damage/force/status payload | — | `core/combat/impact_data.gd` |
