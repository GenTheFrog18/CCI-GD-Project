# Layer 1 Enemies Implementation Contract

> **Status:** current runtime contract. `EnemyDefinition` owns identity/default health/tags; scene exports own AI tuning.

## Shared behavior

- Every damageable enemy delegates health, status, hit flash, electric disable, debug label, and ordinary save state to `EnemySupport`.
- Enemy AI remains per scene; no universal behavior tree.
- Heavy/committed attacks call player threat warning before resolution.
- F3 categories independently show body hitbox, sensing, roam/patrol range, navigation, state text where supported, and current/max health.
- Hushcap/electric suppression stops sensor updates. Direct damage flashes enemy once for `EnemySupport.hit_flash_duration`.
- Continue restores durable health/status/item state but resets transient target, telegraph, route, and cooldown state to safe behavior.

## Tongue Amphibian

Role: roaming item thief.

- Idles by timed hops around its placer and may steer slightly in air; it has no walking slide.
- Sound investigation changes hopping direction toward event/entity source.
- During idle only, chases pickupable loose items inside `item_detection_range`; player interaction overrides this.
- Tongue telegraph stops movement/jumping, locks facing plus adjustable angle, and uses an editor/debug-visible range shape.
- Steals one eligible item, preferring lower weight loose items. It never takes non-pickupable world objects.
- Player theft order comes from inventory contract. `can_steal_multitool` is currently false by default.
- Carries only one item; icon appears above status text. Damage drops it above frog head.
- After carried item is removed/dropped, theft cooldown blocks attacking. Electric stun also blocks jumping, attacking, and stealing.
- If intended horizontal movement produces no displacement for four seconds, roaming direction flips.

## Knockback Bird

Role: nest-bound displacement enemy.

- Bird Nest Placer spawns a deterministic group inside circular patrol radius.
- Natural patrol keeps directional continuity, validates target against flight space, and periodically chooses a new local destination.
- Player near nest triggers alert, telegraph, one locked swoop, randomized recovery position, then cooldown.
- Attack applies force split by configurable horizontal/vertical ratio. Species-wide repeated-hit window can add bonus damage.
- Damage during swoop interrupts into recovery.
- Bird cannot be placed as ordinary ground enemy; nest owner supplies position, range, and attack-group settings.

## Thorn Bloom

Role: stationary regenerating radial hazard.

- States: Idle, Exploding, Dormant.
- Proximity or accepted impact starts telegraph, then emits adjustable radial needle count/speeds.
- Dormant sprite disappears; after reload timer Bloom returns to Idle. State/timer persists.
- Needle damages player or other enemy, applies configurable Bleed duration, and adds Bleed up to needle cap (default 80 s).
- Player needle i-frame prevents one overlap from consuming every needle.
- Needle disappears on actor hit or sticks to terrain until lifetime expires.
- Death cancels future Bloom behavior; already-fired needles remain transient.

## Lantern Snail

Role: neutral light creature and proximity flash hazard.

- Alternates pause and crawl like Spider roaming, with editable roam distance/timings.
- Surface controller follows connected floors, walls, and ceilings using normal/tangent probes and detached fallback.
- Avoids player during ordinary movement, but attack/telegraph overrides avoidance whenever player is inside trigger radius and cooldown is ready.
- Detonation—not telegraph start—raycasts to player head. Blocked LOS prevents Dazzled.
- Flash emits high-priority sound and applies distance/LOS-based dazzle. Snail is immune to its own Dazzled behavior.
- Death defers one persistent Lantern Crystal drop to avoid physics-query flush errors.

## Cave Spider

Role: surface-crawling ranged setup enemy that escalates after a hit.

- Alternates idle pause and short crawl over connected floor/wall/ceiling geometry.
- Sight aims at player detection point; projectile spawns above head relative to current surface orientation and rotates along velocity.
- Spider body/source is excluded from its projectile.
- Miss retries, then may approach a midpoint/firing position.
- Successful projectile applies damage, Spider Slow, Poison, and Tracking Mark, then Spider chases without firing.
- At melee range it telegraphs/bites, then scatters far away from player before returning to firing behavior.
- Any accepted player damage interrupts current state and scatters away to firing distance.
- Strong Rattlepod/Snail sound and nearby light can cause flee.
- Electric stun blocks projectile firing.

## Large Flyer

Role: one persistent Layer 1 apex threat.

- Allocation group creates one run-wide actor. It roams authored POIs, then patrols/pauses within each POI radius.
- Main cone requires continuous sight threshold. During valid sight it creates a same-range 360° detector; both count toward threshold.
- After threshold, tracking mark, dangerous proximity, or direct damage, roaming/POI signals cannot override player pursuit.
- Lost player creates a search POI around last player position and roams that radius; reacquisition attacks immediately.
- Attack uses setup, committed dive, hit, randomized recovery travel, and cooldown patrol around player rather than returning to old POI.
- Direct player hit forces immediate attack path. Successful player strike also receives configurable knockback; player enemy-hit swing cooldown provides broader anti-stunlock protection.
- Bolt Shock interrupts, suppresses sensors, disables flight, and allows landing fall damage through `EnemySupport`.
- Health/status and special transfer state persist. Legacy Layer 2 arrival support remains implemented but is outside normal current build.
- F3 shows state, health, body hitbox, sight, search/POI, and roam ranges independently.

## Senior Diver / Gatekeeper

Role: solid restricted-zone authority beside Layer 2 gate.

- Idle faces configurable authored direction, then last known player position; detector transforms follow facing.
- First-sight dialogue occurs once per game. Trespass/escalation dialogue cannot start before first-sight dialogue ends.
- Grab dialogue remains independent and may trigger anywhere when grab resolves.
- Restricted-zone trespass, whistle state, strong sound, or direct player damage can cause chase/attempted grab. Direct hit immediately aggravates and overrides whistle protection.
- Solid body slows player by configurable multiplier on collision; player cannot pass through.
- Warned grab applies short lock, confiscates relic-category items, and sends player to Surface. Gate itself remains usable and defeat cannot permanently softlock progression.

## Persistence

Ordinary enemies save alive/dead, health, persistent effects, and position through `EnemySupport`. Frog additionally saves carried real item. Flyer/flock owners save their special durable state. AI resumes neutral/roaming after Continue instead of resuming a half-finished attack.
