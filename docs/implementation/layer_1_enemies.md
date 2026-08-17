# Layer 1 Enemies Implementation Contract

## Shared Contract

`EnemyDefinition` owns identity, tags, common health/speed/detection, scene, and persistence. Enemy-specific tuning remains exported on its scene/script. Each enemy implements only required states; no common behaviour tree or navigation system. Shared contracts cover damage, force, status, source attribution, death, hit feedback, and persistence. High-damage/knockback attacks request the player warning before activation.

Final visual animation names are only `idle`, `move`, and `attack`; internal telegraph/recover/search/flee/carry/return reuse them.

## Tongue Amphibian

`small_enemy`. Prefer reachable loose item; otherwise steal active ordinary item, other hotbar, backpack, Multitool, then physical whistle. Tongue locks aim, extends/retracts, passes same species, and stops on other enemy/terrain/item/player. Theft ignores i-frames, deals no damage, and slows one second; empty inventory takes adjustable 1 damage. Any accepted hit/death drops carried item. Out-of-bounds item goes to authored gatekeeper return marker.

## Knockback Bird

`small_enemy`, `flying`. Nest placer spawns 1–3 in an authored flight region. Neutral outside nest proximity. Lock one swoop then recover; damage during swoop cancels into recovery. Hit applies 70% horizontal/30% vertical force. Two species-wide hits within two seconds deal adjustable 10 damage and reset.

## Thorn Bloom

`neutral_creature`, `hazard`. Immobile/killable, no sight/sound. Proximity or physical impact winds up six gravity needles: three each side with adjustable fan/range. Needle deals adjustable 10 damage plus bleed, disappears on actor or sticks to terrain five minutes. Full volley returns after five minutes. Death cancels wind-up; existing needles remain and are not saved.

## Lantern Snail

`neutral_creature`, `hazard`. Two health; surface-normal movement crawls connected floors/walls/ceilings near placer. World light. Proximity, hard impact, or small-radius sound agitates. Scream makes adjustable high-priority sound and distance-scaled LOS dazzle. Any valid death drops one persistent `lantern_crystal`.

## Cave Spider

`small_enemy`. Roams authored surfaces; low-priority sound is primary, short sight scans every 0.5 s. Approach on current surface, fire with visible aim, then use ground movement while locked. Projectile applies damage, spider slow, poison, and tracking mark together. Strong Rattlepod/Snail sound and light cause fleeing. Silver Weight normally kills it through its adjustable 200 damage.

## Large Flyer

`flying`, `big_roamer`, `layer_global_actor`. One living instance, adjustable 500 health, no ordinary slow/knockback. Select authored POI every 15 s; require four seconds continuous sight. Spider mark outranks Snail/Rattlepod requests; explicit priority, newest tie, fallback on invalid. Transparent authored blockers stop movement but not sight. Lost target searches then roams. Committed dive deals adjustable 75 damage. Accept poison, distraction, Driftseed, and 200 Silver Weight damage. Bolt Shock disables flight, applies gravity, and permits fall damage. Cross Layer 1 sections. If alive, transfer at the Layer 2 shop marker with health/status and coexist with the Sky Hunter Flock; reset transient AI and reacquire.

## Senior Diver

`gatekeeper`. Separate NPC beside always-usable gate. Earned Blue rank prevents hostility even if physical whistle is missing. Restricted-zone trespass knocks back/chases; three seconds without sight returns to authored post. Short warned grab locks one second, confiscates map-found inventory, and teleports to surface. Distraction, bypass, and defeat work; death never locks gate.

## Save

Save alive/dead, health, carried real item, persistent status, and flyer transfer. Reset target, patrol phase, telegraph, attack, search, chase, stun, and projectile. Dead placer enemies stay dead; living ordinary enemies restore at authored origin.
