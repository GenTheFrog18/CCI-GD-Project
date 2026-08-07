# Artifact Idea Catalog

## Purpose

This document collects the artifact concepts proposed for team discussion. None of these ideas are assumed to be final. The team can compare them based on how interesting they are, whether they fit the art direction, and whether they are realistic to implement during the game jam.

## Current Design Constraints

- The game is a 2D side-scroller inspired by *Terraria*, *Noita*, *Rain World*, and *Made in Abyss*.
- The player character is physically weak. Artifacts should encourage avoidance, escape, indirect manipulation, and problem-solving.
- Direct-damage artifacts are allowed, but should be uncommon and inefficient. The throwable rock is the basic exception.
- The player currently has five backpack slots and two hotbar slots.
- Opening the inventory slows the player, blocks the middle of the screen, and darkens the rest of the view.
- Left click uses the active artifact. Right click throws it toward the cursor, with direction and velocity determined by cursor position and distance.
- Whether a thrown artifact is consumed or retrievable is determined individually.
- Artifacts may use charges, cooldowns, inventory capacity, health, other items, or another sacrifice as their limitation.
- Artifacts appear at designed spawn locations, sometimes hidden inside breakable rocks or obtained from the environment. Some living creatures can also be used as artifacts.
- Creatures do not drop artifacts when killed.
- Terrain cannot be destroyed.
- Only knowledge persists after death.
- An artifact's detailed description becomes available on future runs if the player uses it enough times during a run and then dies.

## Existing Baseline Artifacts

These were already part of the game concept and are included here as reference points.

### Throwable Rock

- **Left click:** Team-defined close interaction or preparation action.
- **Right click:** Throw the rock using the normal cursor-based trajectory.
- **Role:** The simple, readily understandable direct-damage option.
- **Limitations:** Less versatile and less powerful than special artifacts.

### Lantern Snail

- **Behavior:** Illuminates its surroundings and screams when agitated.
- **Consequences:** Its scream dazzles the player, distracts vision, and attracts the large enemy to its location.
- **Artifact use:** The player can pick it up and reposition or deliberately agitate it later.
- **Role:** A naturally systemic artifact that combines portable light, danger, distraction, and creature manipulation.

## Initial Core Candidates

### 1. Rattlepod

A plant pod whose seeds audibly shake inside it.

- **Left click:** Shake it, producing several short noises at the player's position.
- **Right click:** Throw it. After impact, it repeatedly rattles at the landing point.
- **Uses:** Lure or reposition sound-sensitive creatures, agitate wildlife remotely, distract creatures, or deliberately create chaos away from the player.
- **Risk:** The sound can attract threats the player did not anticipate. Using it by hand reveals the player's position.
- **Suggested limitation:** A small number of pulses before the pod becomes empty.
- **Estimated scope:** Low to medium.

### 2. Cling Resin

A container of thick natural adhesive.

- **Left click:** Pour a small sticky patch beside or beneath the player.
- **Right click:** Throw the container, creating a larger patch when it breaks.
- **Uses:** Slow creatures, affect tongues or projectiles, trap loose objects, or prepare an area before attracting something into it.
- **Risk:** The resin also slows the player and can obstruct an intended escape route.
- **Suggested limitation:** One container creates one or two patches.
- **Estimated scope:** Low to medium.

### 3. Gale Bladder

An inflated organic bladder that releases a powerful burst of air.

- **Left click:** Produce a directed gust toward the cursor.
- **Right click:** Throw it. It releases a radial gust when it collides with something.
- **Uses:** Push lightweight creatures, redirect loose objects, scatter hazards, alter thrown-object trajectories, or create space without dealing significant damage.
- **Risk:** The gust can scatter useful items or push hazards toward the player.
- **Suggested limitation:** Limited charges or one large burst.
- **Estimated scope:** Medium.

### 4. Hushcap

A fungus filled with dark, vision-obscuring spores.

- **Left click:** Crush it, creating a cloud around the player.
- **Right click:** Throw it, creating the cloud where it lands.
- **Uses:** Break lines of sight, hide movement, obscure a lure, or create confusion while sound continues to travel normally.
- **Risk:** The cloud also hinders the player's vision and does not stop sound-based detection.
- **Suggested limitation:** Single use.
- **Estimated scope:** Low to medium.

## Initial Stretch Candidates

### 5. Catcher Gourd

A hollow plant with a visibly open mouth.

- **Left click:** Hold it toward the cursor. It captures the next small physical projectile or loose object that enters it.
- **Right click:** Throw the gourd. It releases its stored object when it lands.
- **Uses:** Capture needles, web shots, rocks, or small dropped items and reposition them.
- **Risk:** It cannot capture large creatures or major attacks. A badly aimed release may harm the player.
- **Suggested limitation:** Holds only one object at a time.
- **Estimated scope:** Medium to high.

### 6. Foldshell

A large empty shell formerly occupied by a creature.

- **Hold left click:** Hide inside it, becoming harder to notice but unable to move and unable to see clearly.
- **Right click:** Throw or place it as temporary physical cover.
- **Uses:** Hide from sight-based threats, block small projectiles or tongues, or create temporary cover without changing terrain.
- **Risk:** Powerful creatures can knock it away, and hiding leaves the player stationary.
- **Suggested limitation:** Reusable with a cooldown or durability.
- **Estimated scope:** Medium.

### 7. Stillwater Gland

A transparent sac whose contents visibly move in slow motion.

- **Left click:** Break it around the player.
- **Right click:** Throw it, creating a field at the landing point.
- **Uses:** Slow creatures, projectiles, and possibly status-effect progression within an area.
- **Risk:** The player is also slowed inside the field.
- **Suggested limitation:** Single use and short duration.
- **Estimated scope:** High because several kinds of timers may need consistent handling.

### 8. Bloodbell

A rare bell-like artifact that is armed using the player's blood.

- **Left click:** Sacrifice health to arm it.
- **Right click:** Throw it. Predatory creatures temporarily treat it as a high-priority target.
- **Uses:** Redirect hunters, pull threats into another system, or create a costly emergency escape.
- **Risk:** It costs health and may gather several threats into one dangerous location.
- **Suggested limitation:** Health cost plus a limited active duration.
- **Estimated scope:** High unless creatures already share a target-priority system.

## Additional Candidate Set

### 9. Echo Husk

A shell that stores and reproduces sound.

- **Left click:** Record the strongest nearby sound for a short period.
- **Right click:** Throw it. It replays the recorded sound at its landing point.
- **Uses:** Reposition the apparent source of a lantern snail's scream, a bird call, breaking rock, heavy landing, or creature attack.
- **Risk:** It may reproduce an unexpectedly dangerous sound or reveal the player's route.
- **Difference from Rattlepod:** The Rattlepod makes a reliable generic noise; the Echo Husk requires the player to find and capture a useful sound.
- **Estimated scope:** Medium if the game has shared sound-event signals.

### 10. Snarevine Reel

A coiled living vine that rapidly anchors itself.

- **Left click:** Anchor one end at the player's current position.
- **Right click:** Throw the other end, creating a line between the two anchors.
- **Uses:** Trip, interrupt, or briefly tether creatures; catch loose objects; detect that something passed through an area.
- **Risk:** The player can also cross the line and become tangled. A powerful creature may snap it immediately.
- **Suggested limitation:** Only one active vine at a time.
- **Estimated scope:** Medium.

### 11. Mourning Sponge

A sponge-like organism that absorbs harmful conditions.

- **Left click:** Absorb part of one status effect currently affecting the player.
- **Right click:** Throw it. The sponge bursts and spreads the stored effect around its landing point.
- **Uses:** Interact with poison, bleeding, slowing effects, tracking marks, and future status effects.
- **Risk:** If the sponge is held for too long, the stored effect returns to the player.
- **Suggested limitation:** Stores only one effect and removes only part of it.
- **Estimated scope:** High unless status effects already share a common framework.

### 12. Driftseed

A large seed that floats upward and pulls at nearby debris.

- **Left click:** Attach it to the player, reducing gravity while increasing received knockback.
- **Right click:** Throw it. It attaches to the first lightweight creature or movable object struck.
- **Uses:** Reduce falling speed, lift loose artifacts, change throwing arcs, make small creatures easier to push, or create unusual movement routes.
- **Risk:** Birds, attacks, and gusts can launch an affected player much farther than intended.
- **Suggested limitation:** Single use or a short attachment duration.
- **Estimated scope:** Medium.

### 13. Mud Effigy

A crude figure that unfolds into the player's silhouette.

- **Left click:** Create a stationary copy at the player's feet.
- **Right click:** Throw the folded effigy. It unfolds where it lands.
- **Uses:** Distract sight-based creatures, draw one attack, or test how a creature responds before the player approaches.
- **Risk:** It cannot fool sound-based creatures and breaks after one attack.
- **Possible extension:** It could inherit a tracking marker currently affecting the player, but this is not necessary for the basic version.
- **Estimated scope:** Medium.

### 14. Weightstone

A dense stone that unnaturally increases weight.

- **Left click:** Make the player heavy, slow, difficult to knock back, and unable to jump normally while using it.
- **Right click:** Throw it. It sticks to a creature or movable object and greatly increases its weight.
- **Uses:** Resist knockback, pull flying creatures downward, keep objects from moving, weigh down part of a trap, or sharply alter a thrown object's arc.
- **Risk:** Its movement penalties can leave the player unable to escape.
- **Suggested limitation:** Reusable with a cooldown or active while held.
- **Estimated scope:** Low to medium.

### 15. Snaproot

A root that violently straightens when touched.

- **Left click:** Plant it beside or beneath the player.
- **Right click:** Throw it. It plants itself where it lands.
- **Uses:** Create an improvised jump, launch loose objects, interrupt a creature, redirect movement, or propel something into another hazard.
- **Risk:** It launches the first valid thing that touches it, including the player.
- **Suggested limitation:** Single trigger.
- **Estimated scope:** Medium.

### 16. Scrying Shell

A shell that senses movement by sending out visible pulses.

- **Left click:** Emit a pulse around the player, briefly outlining nearby movement and hidden objects.
- **Right click:** Throw it. It continues pulsing remotely for a short duration.
- **Uses:** Detect movement in dark caves, locate dropped items, identify suspicious breakable rocks, or warn that a large creature is approaching.
- **Risk:** The pulses are audible and may agitate or attract creatures.
- **Presentation:** Reveal vague silhouettes or rings rather than exact identities.
- **Estimated scope:** Low to medium.

### 17. Hunger Idol

An artifact that becomes bait only after consuming something valuable.

- **Left click:** Consume the artifact in the other hotbar slot to arm the idol.
- **Right click:** Throw it. Creatures treat it as something interesting to investigate, steal, or attack.
- **Uses:** Create a powerful distraction, lure scavengers, or deliberately bring creatures together.
- **Risk:** The player sacrifices something that could have been used or sold.
- **Possible scaling:** The consumed item's value or rarity could affect the idol's attraction strength.
- **Estimated scope:** High because creatures need a shared system for evaluating interesting targets.

### 18. Grudge Nut

A hard nut that stores physical force.

- **Left click:** Open it toward the cursor so it absorbs the next strong physical impact from that direction.
- **Right click:** Throw it. It releases the stored force in a short blast when it lands.
- **Uses:** Store force from a creature's charge, bird impact, strong gust, falling object, or large projectile and redirect it later.
- **Risk:** The player may need to deliberately expose themselves to danger. Weak impacts produce weak results.
- **Role:** An uncommon indirect-damage option whose strength must first be earned from the environment.
- **Suggested limitation:** One stored impact with a capped maximum force.
- **Estimated scope:** Medium to high.

## Example Artifact Combinations

These are examples of systemic interactions, not required scripted combinations.

- Throw a Rattlepod into a Hushcap cloud so creatures investigate something they cannot clearly see.
- Place Cling Resin and use a Gale Bladder to push creatures or loose hazards into it.
- Hide a lantern snail inside a Hushcap cloud and agitate it to create a confusing light-and-sound source.
- Use a Gale Bladder to redirect thrown rocks, planted needles, dropped artifacts, or web shots.
- Use a Snaproot to launch a Rattlepod, rock, lantern snail, or other physical artifact.
- Attach a Driftseed to something before pushing it with a Gale Bladder.
- Use a Weightstone to resist a Gale Bladder or to make a launched object fall sharply.
- Record a lantern snail or creature with an Echo Husk, then replay it behind a Snarevine or Cling Resin patch.
- Store an unwanted condition inside a Mourning Sponge and throw it into an area where creatures are already gathering.
- Charge a Grudge Nut with an enemy impact and release the force somewhere else rather than fighting directly.

## Suggested Shared Interaction Properties

Artifacts will feel more systemic and require fewer one-off enemy scripts if creatures and objects respond to shared properties:

- **Sound:** Produce, hear, investigate, or become agitated by sound events.
- **Sight:** Detect visible targets, lose targets in obscured areas, and react to decoys.
- **Force:** Receive impulses, resist knockback, change weight, and store physical impacts.
- **Movement areas:** Apply sticky, slow, spring, or other area effects to any valid body.
- **Interesting targets:** Allow creatures to evaluate the player, artifacts, decoys, and bait through a common priority system.
- **Status effects:** Represent poison, bleeding, slow, and tracking markers through compatible data if status-transfer artifacts are selected.
- **Physical projectiles:** Give needles, web shots, rocks, and thrown items enough shared behavior to be caught, pushed, slowed, or launched.

## Jam-Scope Discussion Notes

- The catalog is intentionally larger than the recommended final roster.
- Low- and medium-scope artifacts are better starting points for prototypes.
- High-scope artifacts should be selected only when they reuse a system the team already needs.
- Artifacts that depend on the same shared property can be compared as alternatives. For example, the Rattlepod and Echo Husk are two different approaches to sound manipulation.
- A small number of highly interconnected artifacts will probably produce more interesting play than a large number of isolated artifacts.

## Simplified Knowledge Unlock

Partial usage progress does not need to persist between runs.

1. Track a temporary use count for each artifact type during the current run.
2. When the player dies, compare each count with that artifact's discovery threshold.
3. Permanently unlock the detailed description for every artifact that reached its threshold.
4. Discard all temporary counts when the next run begins.
5. Keep thresholds small, usually one or two meaningful uses in the same run.

This preserves the intended experiment–die–understand loop without requiring partial progress across several runs.
