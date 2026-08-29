# Enemy Design and Implementation Handoff

> **Audience:** enemy/encounter designer and programmer.
>
> **Status:** current code plus approved behavior, audited 30 August 2026. Designer may propose and tune programming behavior, but player-facing changes become authoritative only after GDD/implementation contract approval. Old specifications are preserved under [`reference/technical_history/`](reference/technical_history/).

## 1. Enemy design philosophy

Enemies are environmental problems before they are health bars. Each creature should:

- create one readable problem;
- interact with terrain, sound, sight, force, items, and effects;
- leave room for avoidance, distraction, manipulation, or combat;
- telegraph dangerous commitment;
- preserve player control except during brief explicit effects;
- avoid opaque instant failure and permanent softlocks;
- become more interesting through combinations, not only larger stats.

Combat is useful when it makes a route safer or earns something. It must not become the universal answer. Balance difficulty through setup, positioning, recovery windows, and world interaction before increasing damage/health.

## 2. Source of truth

| Concern | Authority |
| --- | --- |
| Player experience and future direction | `gdd_en.md` |
| Shared runtime architecture | `fondasi_teknis_godot.md` |
| Implemented behavior by layer | `implementation/layer_1_enemies.md`, `implementation/layer_2_enemies.md` |
| Identity/default health/tags | `data/enemies/<id>.tres` |
| Movement, timing, ranges, damage | Enemy scene/script Inspector exports |
| Placement/quantity/allocation | Placer instance in map section |
| Historical reasoning | `reference/technical_history/` |

If Inspector and definition duplicate a common value, `EnemySupport` loads definition health/tags at runtime. Test the actual scene before documenting a number.

## 3. Shared runtime contract

Enemy scene root owns its state machine and movement. `EnemySupport` owns:

- health/death and same-species damage filtering;
- status applications/ticks;
- direct-hit flash;
- electric interruption, detector suppression, disabled-flight fall damage;
- persistent health/status/position;
- status text and F3 health label.

Shared sensing:

- `SightSensor` handles cone/range/LOS.
- Player target point is `PlayerController.get_detection_origin()`.
- `SoundEvent` carries origin, radius, priority, type, and optional entity source.
- `SoundListener` accepts/ranks sound; AI chooses response.
- Hushcap/electric suppression must stop sensor updates.

Shared combat:

- attacks build `ImpactData`;
- receiver resolves damage, force, and status once;
- source actor cannot hit its own projectile;
- same species rejects damage centrally;
- heavy attack requests player warning before commitment;
- tick damage has no direct-hit reaction.

F3 range categories are independent: `enemy_ranges`, `placer_ranges`, `sight_ranges`, `sound_ranges`, `interaction_ranges`, `combat_hitboxes`, `item_debug`, `pathfinding`, `enemy_labels`, and `player_debug`. World bounds has a separate toggle.

## 4. Layer 1 roster

### Tongue Amphibian

Role: item thief that changes inventory priorities into an encounter.

Normal loop: pause/hop around placer, investigate sounds, optionally seek loose pickup, then attack player. Tongue locks aim and takes one item. Carried item is visible and drops above frog when hit. Theft cooldown creates downtime after recovery.

Important interactions:

- loose item must be player-pickupable;
- lower-weight loose items are preferred;
- idle item search never overrides active player interaction;
- electric stun blocks jump, attack, and theft;
- default `can_steal_multitool` is false;
- player theft and carried-item persistence move a real `ItemStack`, never clone it.

### Knockback Bird

Role: displacement threat whose terrain matters more than direct damage.

Normal loop: patrol nest circle, alert, telegraph, one swoop, randomized recovery, cooldown. Multiple birds coordinate attack spacing and repeated-hit bonus.

Important interactions:

- damage during swoop cancels commitment;
- attack force split is configurable;
- nest radius and group count come from Bird Nest Placer;
- natural patrol validates destination and maintains direction continuity.

### Thorn Bloom

Role: stationary radial trap and reusable terrain hazard.

Normal loop: idle, telegraph/explode, dormant invisible, regenerate. Needles travel physically, damage actors, add Bleed, and stick to terrain.

Important interactions:

- player needle i-frame prevents all overlapping needles resolving at once;
- needles can hit other species;
- Bleed duration and cap are needle tuning;
- Bloom state/reload persists; individual needles do not.

### Lantern Snail

Role: neutral moving light whose defensive flash affects sight-driven systems.

Normal loop: pause/crawl across connected surfaces, avoid player, override avoidance to flash when player is too close, then cooldown.

Important interactions:

- detonation checks LOS to player head;
- flash creates Dazzled and strong SoundEvent;
- Snail itself is Dazzled-immune;
- death drops one persistent Lantern Crystal using deferred spawn;
- surface movement needs continuous support and detached fallback.

### Cave Spider

Role: ranged status setup that escalates into one melee pursuit.

Normal loop: pause/crawl on surfaces, aim/fire, retry/reposition on misses. Successful projectile starts chase, one bite, then long scatter away before shooting again. Any hit also forces scatter.

Projectile applies damage, Spider Slow, Poison, and Tracking Mark. Tracking Mark feeds Large Flyer. Strong sound/light may make Spider flee. Electric stun blocks shooting.

### Large Flyer

Role: one persistent apex threat connecting distant Layer 1 encounters.

Normal loop: select authored POI, locally patrol/idle, acquire player after sight threshold, chase, setup/dive, randomized recovery around player, cooldown. Lost target creates search POI around last player position.

Priority:

1. direct player damage / dangerous proximity;
2. Tracking Mark;
3. high-priority distraction/sound;
4. continuous cone/360 sight;
5. authored POI roaming.

Once committed to player, POI signal cannot cancel chase. Bolt Shock disables flight and may create fall damage. F3 state text is required because this AI has many transitions.

### Senior Diver / Gatekeeper

Role: systemic restricted-zone authority, not a hard key.

Normal loop: face authored/last-known direction at post, react to trespass/sound/attack, chase, warned grab, confiscate relics, return/reset. Blue rank changes normal hostility, but direct hit immediately aggravates.

Gatekeeper is solid and slows player during body contact. Dialogue ordering prevents first-sight and trespass dialogue overlap. Defeat or bypass must not make Layer 2 gate inaccessible.

## 5. Layer 2 foundation roster

Layer 2 is not normal current progression. These actors exist for continued development/testing.

### Canopy Primate

Grounded jumping ranged enemy. Maintains preferred distance, aims, throws gravity rock, recovers. Placer-owned coordination group prevents every Primate attacking together.

### Tremor Hound

Sound-driven ground hunter. Ranks sound, targets entity source centre, travels with `GroundTraversal2D` plus local fallback, searches with stop/go roaming, confirms nearby player, pounces, then retreats during recovery. Proximity detection may confirm target but must never freeze movement/gravity.

### Carrion Stalker

Wounded-prey hunter. Scores nearby actors using Bleed, Poison, and health ratio, commits to target, prepares bite, applies Bleed, retreats. Target switching requires score margin and minimum commitment time.

### Bulwark Beast

Heavy charger. Patrols, telegraphs, locks direction, charges until collision/time, then decelerates through long recovery. Resin changes deceleration; strong sound can agitate. Charge must have readable lane and recovery.

### Sky Hunter Flock

One persistent owner creates several independently damageable flying members. Shared coordinator limits attackers and spacing. Electric stun affects one member. Flock owner saves dead IDs and survivor state.

## 6. World and item interaction matrix

| System | Expected enemy interaction |
| --- | --- |
| Multitool/physical hit | Damage or special breakable interaction; accepted hit may interrupt AI. |
| Throwable impact | Shared damage/force based on payload. |
| Silver Weight | Heavy 200 damage through normal health; no tag-based instant kill. |
| Bolt Shock | Direct damage, electric DOT, attack interrupt, detector suppression; flying fall. |
| Hushcap | Detector suppression; enemy sight/sound does not update inside cloud. |
| Cling Resin | Ground actor speed/jump/knockback modifier; flying actor immune. |
| Driftseed | Valid actor gravity/flight/knockback modifier. |
| Rattlepod | Strong repeated SoundEvent; response depends on species. |
| Lantern flash | LOS/head-based Dazzled plus strong sound. |
| Spider projectile | Damage + Slow + Poison + Tracking Mark. |
| Terrain/fall | Ground support, wall/ceiling traversal, charge collision, or fall damage according to actor. |
| Combat safe zone | Hostile acquisition and accepted impact reject protected player. |

Adding an interaction to every enemy separately is usually wrong. Put generic response in `EnemySupport`, status, sensing, or impact receiver; keep species decision in AI.

## 7. Enemy placer

Ordinary enemy uses `DeterministicPlacer` preset. Designer controls:

- activation chance and quantity;
- weighted enemy entries;
- one or more SpawnPoints;
- initial facing;
- patrol bounds/range where supported;
- spawn/attack coordination group;
- stable persistent ID.

Quantity may exceed SpawnPoint count because results choose markers with replacement. Overlap is designer responsibility. One SpawnPoint is valid for several results only when actor physics can separate safely.

Special placement:

- Knockback Birds use Bird Nest Placer and circular `patrol_radius`.
- Large Flyer uses unique allocation placer plus authored POIs/blockers.
- Sky Hunters come from flock owner.
- Thorn Bloom and Snail may use ordinary placer but need terrain suitable for their movement/hazard.

## 8. Designer workflow

1. State intended player problem and counterplay.
2. Identify existing shared interaction before proposing new code.
3. Edit scene export/Resource for tuning; do not hardcode a balance number.
4. Place encounter with terrain that makes its role readable.
5. Test alone, with one relevant item, and with one enemy combination.
6. Enable only needed F3 categories.
7. Record behavior change in layer implementation contract.
8. Ask owner approval for changes to core identity, progression, narrative, or GDD pillars.

Designer can influence programming behavior by defining states, transitions, telegraph, recovery, priorities, and world interactions. Programmer adapts that intent to existing contracts instead of copying proposal pseudocode literally.

## 9. Acceptance checklist

- Enemy has one clear role and at least one non-combat response.
- Detection uses player head and respects LOS/suppression.
- Attack has telegraph and cannot resolve repeatedly from one overlap.
- Direct hit, electric stun, death, save/load, and out-of-bounds have safe behavior.
- Persistent ID is unique; transient target/state is not saved.
- F3 shows health and only requested ranges.
- Placement supports movement/attack geometry.
- Smoke test covers registration and one critical branch.
