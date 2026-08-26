# Enemy Implementation Handoff

This is the working handoff for enemy design and implementation. It is written for a designer who is changing enemy behavior, tuning encounters, or proposing a new enemy.

It describes the current code and the intended design direction. Numerical values are implementation defaults, not final balance. When this document conflicts with the code, treat the code as the current truth and update this document when the behavior is deliberately changed.

Related references:

- [Layer 1 enemy and item design reference](layer_1_enemy_item_design_reference.md)
- [Map placer authoring reference](map_placer_authoring_reference.md)
- [Layer 2 world integration](implementation/layer_2_world_integration.md)
- [Enemy definition resources](../data/definitions/enemy_definition.gd)

## 1. Design philosophy

### Enemies create situations, not only damage

An enemy is successful when it changes the player's decision: route, timing, visibility, inventory, noise, or preparation. Damage is one tool, not the whole purpose.

Good enemy encounters support several answers:

- avoid or hide;
- break line of sight;
- make a sound somewhere else;
- use terrain or a rope;
- use an item as a tool, weapon, lure, light, or escape option;
- accept a resource loss to preserve health;
- attack the enemy when the player chooses to take the risk.

### Every enemy belongs to the shared world

Enemies should react to the same world signals as the player:

- sight and blocked sight;
- sound position, radius, intensity, and priority;
- physical force and terrain collision;
- damage, interruption, and cross-species interaction;
- status effects and electric disabling;
- persistent world state and out-of-bounds recovery;
- lights, darkness, and authored surfaces.

There is intentionally no universal behavior tree. Shared components provide information and common rules; the enemy script interprets those signals using a small explicit state machine.

### Designer control is part of the implementation

The intended workflow is that a designer can materially change an encounter without editing code. Enemy behavior is therefore split into three control levels:

| Level | Designer can change directly | Example |
| --- | --- | --- |
| Encounter tuning | Scene Inspector exports and placer fields | Attack range, telegraph time, patrol radius, damage, cooldown, spawn chance, quantity, SpawnPoints |
| Behavior composition | Entries, statuses, sound priorities, item definitions, terrain/light placement | Make a Spider more status-focused, make a Bulwark easier to stop with resin, place a Snail where its light changes a route |
| New behavior | State transitions, new sensors, new item ownership rules, new persistence fields | Add a new attack state, make an enemy steal a new category of object, add a new world signal |

The first two levels are designer-owned tuning. The third level needs programmer implementation, but should expose new decisions as Inspector fields once implemented. A programmer should not bury balance or encounter decisions as constants when they can safely be exported.

When proposing a behavior change, describe the player decision it creates, the trigger, the telegraph, the resolution, the counterplay, and the values that should be adjustable. This keeps the code reusable while allowing the designer to control the result.

### Telegraphs are contracts

Any attack that can seriously change the player's state should have a readable telegraph. A telegraph should:

1. identify the threat;
2. communicate the attack direction or target;
3. leave enough time for a reasonable response;
4. be cancellable by the interactions the design promises to support;
5. resolve against the state captured at the appropriate moment.

The player warning system displays a warning icon above the player and a freely orbiting pointer toward each enemy currently telegraphing an attack. Enemies call `player.warn_attack(self, duration)` to participate.

### Enemy identity is more than health

Each enemy should have a distinct pressure vector:

| Pressure | Current example |
| --- | --- |
| Resource ownership | Tongue Amphibian |
| Displacement | Knockback Bird |
| Space denial | Thorn Bloom |
| Light/noise tradeoff | Lantern Snail |
| Status escalation | Cave Spider |
| Layer-wide pursuit | Large Layer 1 Flyer |
| Progression gate | Senior Diver |
| Heavy commitment attack | Bulwark Beast |
| Coordinated ranged pressure | Canopy Primate |
| Predation on weakened actors | Carrion Stalker |
| Flock coordination | Sky Hunter |
| Sound investigation and pounce | Tremor Hound |

Do not give a new enemy an existing pressure without a reason to combine or invert it.

## 2. Shared enemy architecture

### Enemy scene and definition

An enemy normally has:

- a scene under `game/enemies/<layer>/`;
- a script with a small state machine;
- an `EnemySupport` child;
- a stable `species_id`;
- a `data/enemies/<id>.tres` `EnemyDefinition` resource;
- optional `SightSensor`, `SoundListener`, surface probes, hitboxes, or special nodes.

`EnemyDefinition` provides catalog identity, scene, species, tags, health, movement/damage metadata, detection range, and layer. The scene script owns behavior-specific values and state.

### `EnemySupport`

`game/enemies/enemy_support.gd` is the shared adapter for:

- health and death;
- status effects and the text effect indicator above the enemy;
- damage acceptance;
- force application;
- action interruption;
- electric stun and detector suppression;
- persistence registration and capture/restore;
- common out-of-bounds integration.

Enemy scripts should route public damage, force, status, persistence, and interruption through `EnemySupport` instead of duplicating those rules.

Important shared rules:

- Same-species enemy damage is rejected.
- Different enemy species can damage each other when their collision/impact path allows it.
- `electro_stunned` disables active behavior for the supported enemy and should cancel telegraphs/attacks where the enemy implements that contract.
- Effects are displayed as text above the enemy with their remaining duration.
- Persistent enemies must have a stable `persistent_id` before save/load is tested.

### Sensors and signals

- `SightSensor` emits `target_seen` and `target_lost`, checks line of sight, and uses a configurable origin/facing.
- `SoundListener` emits `sound_accepted` for sounds within its rules. Sound carries position, radius/intensity, priority, and sound type.
- `LightSource2D` registers authored/runtime light sources. Cave Spider reacts to nearby light; Lantern Snail owns a light.
- `ImpactData` applies damage, force, statuses, attack identity, and species identity through one shared path.
- `AttackGroupCoordinator` limits simultaneous attackers and broadcasts alerts.

### Public enemy contract

An enemy scene should expose these methods when applicable:

```text
apply_damage(info: DamageInfo) -> bool
apply_force(force: Vector2) -> void
apply_status(id: StringName, data: Dictionary = {}) -> bool
capture_state() -> Dictionary
restore_state(data: Dictionary) -> void
handle_world_out_of_bounds() -> void
interrupt_action(reason: StringName) -> bool
request_interrupt(strength: float, reason: StringName = "impact") -> bool
```

The last two are required for enemies with telegraphed actions. `get_interaction_prompt` and `interact` are used by interactable enemies such as Senior Diver.

## 3. Enemy roster

### 3.1 Tongue Amphibian / Frog

**ID:** `tongue_amphibian`  
**Script:** `game/enemies/layer1/tongue_amphibian.gd`  
**Role:** resource thief, distraction target, low-damage pressure.

#### Intended experience

The frog should make the player care about the physical location and ownership of items. It should roam near its placer, hop rather than walk, identify a reachable loose item, telegraph a tongue attack, steal one item, and retreat with that item. It continues attacking if the player is close; distance management only applies during non-attacking movement.

#### Current behavior

- Searches loose world items before choosing the player.
- Ignores items that are not pickupable by the player.
- Prefers the lowest-weight valid item, then nearest item as a tie-breaker.
- Can be configured to steal or refuse the Multitool.
- Can steal one item at a time.
- Shows the stolen item's icon above its head, above the status text.
- On damage, drops the carried item near the top of its head and starts the theft cooldown.
- Returns to its origin after stealing; if it leaves world bounds, the item is returned through the lost-item marker.
- Roams within `leash_distance` when no target exists.
- Uses random jump cooldown and random jump height. It has slight air control, but no walking design goal.
- Electric stun prevents jumping and active frog behavior.
- Tongue direction follows facing and is rotated by `tongue_angle_degrees`.

#### World and item interactions

- Loose items are targets only when they have `can_be_picked_up()` and pass the frog's steal filter.
- Player inventory theft uses player item ownership APIs, not a copied item.
- A stolen item remains in frog persistence state through save/continue.
- A hit drops a real world item and does not silently delete it.
- The Multitool restriction is the `can_steal_multitool` export.

#### Tuning exports

`move_speed`, `gravity`, `jump_velocity`, `air_control`, `tongue_range`, `tongue_angle_degrees`, `tongue_width`, `telegraph_seconds`, `cooldown_seconds`, `jump_cooldown_min`, `jump_cooldown_max`, `jump_height_randomness`, `theft_cooldown_seconds`, `can_steal_multitool`, `leash_distance`, `carried_drop_offset`.

#### Function map

- `_ready`: registers support/groups, initializes visuals and timers, connects sight/sound/damage signals.
- `_physics_process`: applies gravity, selects item/player/roam target, runs attack/retreat/jump movement, and updates facing/debug draw.
- `_nearest_loose_item`: scans valid loose items and selects the lightest candidate.
- `_perform_tongue`: steals a world item, player item, or whistle; damages the player only when no item is available.
- `_tongue_reaches`: performs the actual rectangular tongue collision query.
- `_move_toward`, `_move_away_from`, `_roam`: select horizontal movement direction.
- `_set_facing`: updates facing and sprite flip.
- `_setup_visual`, `_add_animation`, `_update_visual`, `_play_visual`: build and select frog animations.
- `_tongue_direction`: converts facing plus inspector angle into the attack vector.
- `_random_jump_cooldown`, `_random_jump_height`: apply per-jump variation.
- `_item_weight`, `_can_steal_item`: item prioritization and eligibility rules.
- `apply_damage`, `apply_force`, `apply_status`: shared enemy interaction wrappers.
- `_drop_carried`, `_refresh_carried_icon`: item release and overhead icon.
- `handle_world_out_of_bounds`: returns carried item and resets frog position.
- `capture_state`, `restore_state`: persist carried item and enemy support state.
- `_draw`: F3 gameplay visualization for tongue range/width.

### 3.2 Knockback Bird

**ID:** `knockback_bird`  
**Script:** `game/enemies/layer1/knockback_bird.gd`  
**Role:** aerial displacement threat and nest guardian.

#### Intended experience

The bird makes terrain matter. The danger is not only damage; it is where the player lands after being hit. A player should be able to read the patrol, understand the nest trigger, respond to the telegraph, and use a rope or terrain to reduce the cost of displacement.

#### Current behavior

- Patrols a circular region around `nest_position`.
- Uses destination validation and collision probes to avoid invalid flight paths.
- Enters alert wait when the player enters the nest trigger radius.
- Uses the attack coordinator so only the configured number of birds attacks at once.
- Captures the player's position at the end of the telegraph, then performs a dive.
- Uses the final dive animation frame for the dive presentation.
- Swoop hitbox is active only during the swoop.
- Applies horizontal/vertical knockback ratios and species-hit-window bonus damage.
- Electric disable cancels telegraph/swoop and returns to patrol.
- Ordinary force is ignored; valid damage/status effects still work.

#### World and item interactions

- `Driftseed` changes flight speed and increases received knockback through shared effect rules.
- Resin/ordinary slow should not be assumed to affect flying enemies.
- Silver Weight can damage the bird as a `small_enemy`.
- Rope and terrain are primary counterplay to the displacement threat.
- Hushcap can break sight and prevent attack setup.

#### Tuning exports

`patrol_radius`, `flight_radius`, `flight_speed`, `patrol_destination_refresh_min/max`, `patrol_min_distance`, `patrol_max_distance`, `patrol_direction_variance_degrees`, `patrol_steering_strength`, `max_destination_attempts`, `flight_blocking_collision_mask`, `nest_trigger_radius`, `telegraph_duration`, `swoop_speed`, `swoop_max_duration`, `recovery_duration`, `attack_cooldown`, `attack_group_maximum`, `attack_group_spacing`, `knockback_strength`, `horizontal_force_ratio`, `vertical_force_ratio`, `species_hit_window`, `species_hits_required`, `species_bonus_damage`.

#### Function map

- `_ready`, `_physics_process`: initialize the nest/coordinator and run the state machine.
- `_process_patrol`, `_process_alert_wait`, `_process_telegraph`, `_process_swoop`, `_process_recovery`: state behavior.
- `_enter_patrol`, `_enter_alert_wait`, `_enter_telegraph`, `_enter_swoop`, `_enter_recovery`, `_release_attack`: state and coordinator transitions.
- `_setup_attack_coordinator`: joins the shared attack group.
- `_choose_patrol_destination`, `_generate_patrol_candidate`, `_valid_patrol_candidate`, `_is_destination_path_clear`, `_patrol_area_center`, `_steering_alpha`: patrol path selection.
- `_player_in_nest`, `_face_target`, `_flight_multiplier`: target and movement helpers.
- `_set_swoop_hitbox`: activates the contact hitbox only during attack.
- `_setup_visual`, `_add_animation`, `_play_visual`: fly/dive presentation.
- `_on_target_seen`, `_on_target_lost`, `_on_swoop_body_entered`, `_on_damaged`: sensor, contact, and damage callbacks.
- `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds`: shared contract.

### 3.3 Thorn Bloom

**ID:** `thorn_bloom`  
**Script:** `game/enemies/layer1/thorn_bloom.gd`  
**Role:** stationary neutral hazard and space denial.

#### Intended experience

The Bloom is a readable environmental threat, not a chasing enemy. It should punish careless proximity, give the player a reason to route around it, and allow deliberate triggering from safety. Its projectiles should remain meaningful after the Bloom has gone dormant.

#### Current behavior

- Starts idle and has no sight/sound patrol behavior.
- Proximity, damage, or agitation triggers a telegraph.
- Fires a radial volley of needles, then becomes dormant/invisible.
- Needles deal damage and add adjustable Bleed, capped by `needle_bleed_cap`.
- Needles can damage enemies as well as the player.
- A player has adjustable spike invulnerability frames so one step cannot consume the whole volley.
- Needles disappear on actor contact or stick to terrain instead of becoming unstable world physics objects.
- Dormant state, reload timer, and fired state are saved.

#### Tuning exports

`trigger_radius`, `telegraph_seconds`, `reload_seconds`, `needle_damage`, `needle_lifetime`, `needle_speeds`, `radial_projectile_count`, `spike_iframe_seconds`, `needle_bleed_duration`, `needle_bleed_cap`.

#### Function map

- `_ready`, `_process`: initialize support/visual state and run trigger/reload timers.
- `receive_agitation`: accepts external activation.
- `_trigger`: enters telegraph/dormant cycle.
- `_fire`: creates the radial needle volley.
- `_setup_visual`, `_sheet_frame`, `_set_visual_state`: idle/explode/dormant presentation.
- `apply_damage`, `apply_force`, `apply_status`: damage/interaction wrappers.
- `capture_state`, `restore_state`: persist dormancy and cycle state.

### 3.4 Lantern Snail

**ID:** `lantern_snail`  
**Script:** `game/enemies/layer1/lantern_snail.gd`  
**Role:** mobile light source, neutral hazard, sound event, and crystal source.

#### Intended experience

The Snail is useful and dangerous simultaneously. Its light helps navigation, but proximity or agitation can cause a flash/scream that blinds the player and creates a strong sound event. Killing it removes the living light and produces a portable Lantern Crystal.

#### Current behavior

- Walks on connected floor, wall, or ceiling surfaces using forward/support probes.
- Uses a sprite-scale export for easy visual tuning and is horizontally flipped for the authored orientation.
- Flees from a detected player unless it is actively telegraphing/resolving its attack.
- Is immune to Dazzled.
- Proximity can trigger the flash even if sight state is otherwise awkward, provided cooldown is clear.
- Damage triggers hit animation; death disables its light and drops a persistent Lantern Crystal.
- Telegraphs before the flash/scream and performs the final head-raycast/sight check at detonation.
- The scream applies distance-scaled Dazzled through valid line of sight and emits a high-priority sound.

#### World and item interactions

- Its `LightSource2D` repels Cave Spider.
- Its scream can agitate/redirect sound-reactive enemies.
- Lantern Crystal reproduces the portable flash/noise interaction as an item.
- The dropped crystal is a real persistent world item and must not trigger as if picked up while merely touching the ground.

#### Tuning exports

`move_speed`, `roam_distance`, `trigger_radius`, `telegraph_seconds`, `scream_cooldown`, `scream_radius`, `scream_priority`, `flash_duration`, `sound_trigger_radius`, `sprite_scale`, `adhesion_speed`, `surface_probe_distance`, `surface_probe_radius`, `surface_offset`, `normal_turn_speed`, `normal_change_epsilon_degrees`, `detach_grace_seconds`, `flee_speed_multiplier`, `walkable_collision_mask`.

#### Function map

- `_ready`, `_on_died`, `_physics_process`: setup, death/drop, and state loop.
- `_move_on_surface`, `_update_surface_from_collision`, `_update_probes`, `_forward_surface_normal`, `_support_surface_normal`, `_surface_angle`, `_rotate_normal_toward`, `_reset_surface`: surface walking and transitions.
- `receive_agitation`, `_start_flee`, `_scream`, `_drop_crystal`: agitation, avoidance, attack, and item conversion.
- `_setup_visual`, `_add_animation`, `_play_animation`: idle/walk/hit presentation.
- `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds`: shared contract.

### 3.5 Cave Spider

**ID:** `cave_spider`  
**Script:** `game/enemies/layer1/cave_spider.gd`  
**Role:** ranged status setup and escalation trigger.

#### Intended experience

The Spider's projectile is more dangerous for what it enables than for immediate damage. A hit slows the player, applies delayed damage, and marks the player for the Large Flyer. Light and strong sound are counter-signals that make the Spider abandon its attack and move away.

#### Current behavior

- Walks on connected surfaces using the same constant-support principle as the Snail.
- Sees the player, telegraphs, and fires a temporary projectile.
- Projectile applies `spider_slow`, `poison`, and `tracking_mark`.
- Nearby active light causes fleeing.
- Priority-8-or-higher sound causes fleeing and cancels attack.
- Silver Weight can kill it as a `small_enemy`.
- Surface detachment has a grace period; a missing support surface eventually causes falling.

#### Tuning exports

`move_speed`, `gravity_direction`, `attack_range`, `telegraph_seconds`, `cooldown_seconds`, `projectile_speed`, `projectile_damage`, `roam_distance`, `adhesion_speed`, `surface_probe_distance`, `surface_probe_radius`, `surface_offset`, `normal_turn_speed`, `normal_change_epsilon_degrees`, `detach_grace_seconds`, `walkable_collision_mask`.

#### Function map

- `_ready`, `_physics_process`: setup and AI loop.
- `_move_on_surface`, `_update_probes`, `_forward_surface_normal`, `_support_surface_normal`, `_update_surface_from_collision`, `_surface_angle`, `_rotate_normal_toward`, `_reset_surface`: adhesion and terrain transitions.
- `_nearest_light`, `_active_sound_threat`, `_on_seen`, `_on_target_lost`, `_on_sound`, `_begin_flee`, `_cancel_attack`: sensing and escape behavior.
- `_fire`: creates the status projectile.
- `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds`: shared contract.

### 3.6 Large Layer 1 Flyer

**ID:** `large_layer1_flyer`  
**Script:** `game/enemies/layer1/large_flyer.gd`  
**Role:** persistent layer-wide apex pressure.

#### Intended experience

The Flyer gives Layer 1 memory. The player may leave one section, but a mark, sound, or unresolved pursuit can continue to affect the route. Ordinary sight should require time and can be broken; a Tracking Mark is an intentional hard priority.

#### Current behavior

- Roams authored `LargeFlyerPOI` points.
- Maintains prioritized requests from tracking, sight, sound, snail, and distractions.
- Requires continuous ordinary sight lock before committing; Tracking Mark bypasses that delay.
- Telegraphs and dives toward a captured target position.
- Applies heavy damage/force on contact.
- Ignores ordinary force but accepts supported statuses and Silver Weight damage.
- Persists across the Layer 1 route and resets transient AI when restored/transferred.

#### Tuning exports

`roam_speed`, `chase_speed`, `dive_speed`, `sight_lock_seconds`, `search_seconds`, `poi_interval`, `poi_recency_weight`, `poi_distance_weight`, `telegraph_seconds`, `dive_seconds`, `attack_damage`, `attack_force`, `attack_hit_radius`, `attack_cooldown`, `recovery_seconds`, `priority_decay_per_second`, `tracking_mark_priority`, `snail_priority`, `distraction_priority`, `sight_priority`, `sight_request_seconds`, `sound_request_seconds`.

#### Function map

- `_ready`, `_physics_process`, `_process_committed_state`, `_process_roaming`: persistent AI state and movement.
- `_begin_attack`, `_recover`, `_refresh_tracking_mark`, `_refresh_sight_request`: target commitment and attack lifecycle.
- `_on_seen`, `_on_lost`, `_on_sound`, `_sound_priority`, `receive_agitation`: world signal translation into requests.
- `_begin_search`, `_choose_poi`: roam/search selection.
- `_upsert_request`, `_select_request`, `_request_valid`, `_find_request`, `_remove_request`: prioritized request management.
- `_flight_speed_multiplier`, `_clock`: shared timing/effect helpers.
- `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `_reset_transient_ai`, `handle_world_out_of_bounds`: persistence and shared contract.

### 3.7 Senior Diver

**ID:** `senior_diver`  
**Script:** `game/enemies/layer1/senior_diver.gd`  
**Role:** progression gatekeeper and item-provenance test.

#### Intended experience

The Diver is a systemic gate, not a mandatory boss. Blue rank authorizes passage, while other players can distract, hide, fight, or accept confiscation/return consequences. Progression authorization and possession of the physical whistle are separate concepts.

#### Current behavior

- Holds a restricted radius around its post.
- Detects the player through sight and warns/knocks back unauthorized trespassers.
- Chases while sight is maintained, investigates authorized sound types, and returns to post after losing the target.
- Telegraphs and resolves a close-range grab.
- Locks the player, confiscates map-origin inventory items, drops them at `LostItemReturn`, and transitions the player to Surface.
- Blue whistle rank prevents trespass hostility.
- Death cancels the grab and does not permanently block progression.

#### Tuning exports

`move_speed`, `gravity`, `restricted_radius`, `grab_range`, `telegraph_seconds`, `grab_lock_seconds`, `lost_seconds`, `trespass_knockback`, `investigation_speed`, `investigation_seconds`, `return_drop_spacing`.

#### Function map

- `_ready`, `_physics_process`: setup and state loop.
- `_process_chase`, `_process_grab_telegraph`, `_resolve_grab`, `_process_lost_target`, `_process_investigation`, `_move_to_post`: gatekeeper states.
- `_warn_trespass`, `_apply_motion`: player displacement and physics.
- `_on_seen`, `_on_lost`, `_on_sound`: target and distraction signals.
- `_grab_valid`, `_valid_target`, `_is_authorized`, `_clear_target`, `_cancel_grab`: grab safety and authorization.
- `_return_confiscated_items`, `_on_died`: inventory consequence and death cleanup.
- `get_interaction_prompt`, `interact`: player conversation/feedback.
- `_find_world_run`, `_move_multiplier`: transition and status helpers.
- `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds`: shared contract.

## 4. Layer 2 enemies

Layer 2 enemies are more coordinated and more willing to exploit player state. They still need readable telegraphs and multiple possible responses.

### 4.1 Bulwark Beast

**ID:** `bulwark_beast`  
**Script:** `game/enemies/layer2/bulwark_beast.gd`  
**Role:** heavy charger and lane control.

It patrols around its origin, reacts to sight, strong sound, and damage, then telegraphs a committed horizontal charge. The charge damages and forcefully displaces actors, applies `incapacitated` to the player, and stops on terrain collision or timeout. It resists ordinary force while charging. Resin can increase charge deceleration, making resin a meaningful environmental counter.

Tuning: `patrol_radius`, `patrol_speed`, `charge_telegraph_duration`, `charge_speed`, `maximum_charge_duration`, `charge_damage`, `charge_force`, `player_incapacitation_duration`, `natural_deceleration`, `collision_recovery_duration`, `resin_deceleration_multiplier`, `strong_sound_priority`.

Functions: `_ready` setup; `_physics_process` state loop; `_begin_telegraph` captures direction and warns; `_handle_charge_collisions` resolves terrain/actor collisions; `_begin_recovery` enters cooldown; `_on_seen`, `_on_sound`, `_on_damaged` acquire charge targets; `interrupt_action` handles electric/impact cancellation; `request_interrupt` delegates support; `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds` implement the shared contract.

### 4.2 Canopy Primate

**ID:** `canopy_primate`  
**Script:** `game/enemies/layer2/canopy_primate.gd`  
**Role:** coordinated ranged harassment.

The Primate hops within `patrol_bounds`, tracks the player through sight, broadcasts an alert, and maintains a preferred range. It requests the one available attack slot in its group, aims with a telegraph, then fires a gravity-affected rock projectile. After firing it enters recovery. The projectile deals damage and force, but is not a collectible world item.

Tuning: `patrol_bounds`, `gravity`, `jump_speed`, `move_speed`, `preferred_distance_min`, `attack_range`, `aim_duration`, `attack_cooldown`, `group_alert_duration`, `projectile_speed`, `rock_damage`, `rock_force`, `spawn_group_id`.

Functions: `_ready` setup and group registration; `_physics_process` movement/aim/recovery; `_on_seen` acquires and broadcasts target; `_fire` creates the projectile; `interrupt_action` cancels aiming; `request_interrupt`, `apply_damage`, `apply_force`, `apply_status` delegate support; `capture_state`, `restore_state` persist group identity/support state; `handle_world_out_of_bounds` resets to origin.

### 4.3 Carrion Stalker

**ID:** `carrion_stalker`  
**Script:** `game/enemies/layer2/carrion_stalker.gd`  
**Role:** opportunistic predator that turns player mistakes into danger.

The Stalker scans effect receivers rather than only the player. It scores nearby non-same-species actors by distance, Bleed, Poison, and low health. Healthy prey is not a valid target until it damages the Stalker. Once committed, it shadows the prey, telegraphs a bite, lunges, applies damage/force/Bleed, then retreats.

Tuning: `patrol_radius`, `patrol_speed`, `shadow_speed`, `bite_speed`, `prey_scan_interval`, `prey_scan_radius`, `target_switch_score_margin`, `minimum_target_commitment_time`, `bleeding_score_bonus`, `critical_health_threshold`, `critical_health_score_bonus`, `poison_score_bonus`, `bite_prepare_duration`, `bite_duration`, `bite_damage`, `bite_force`, `bite_bleed_duration`, `retreat_duration`.

Functions: `_ready` setup; `_physics_process` status/gravity/state loop; `_scan_prey` finds candidates; `_prey_score` ranks wounded/poisoned/bleeding actors; `_move_and_consider_attack` patrols/shadows and starts bite; `_try_bite` resolves ImpactData; `_begin_retreat` exits attack; `_on_damaged` retaliates against an attacker; `interrupt_action` cancels preparation; `request_interrupt`, `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds` implement shared behavior.

### 4.4 Sky Hunter and Sky Hunter Flock

**IDs:** `sky_hunter`, `layer_2_sky_hunter_flock`  
**Scripts:** `game/enemies/layer2/sky_hunter.gd`, `sky_hunter_flock.gd`  
**Role:** coordinated aerial group.

The flock owner, not an individual placer, controls member count, activation, attack coordination, death persistence, and save/restore. The flock activates when the Layer 2 activation zone is crossed. Individual Hunters roam, receive shared alerts, chase sight targets, reserve one attack slot, telegraph, dive, hit once, and recover toward their origin.

Flock tuning: `starting_member_count`, `maximum_simultaneous_attackers`, `minimum_group_attack_spacing`, `spawn_spacing`. Member tuning: `roam_speed`, `chase_speed`, `attack_speed`, `attack_telegraph_duration`, `attack_duration`, `attack_damage`, `attack_force`, `recovery_duration`, `preferred_member_separation`.

Flock functions: `_ready` registers owner and creates members; `activate_near` enables the encounter near the current route; `_spawn_member` creates/restores one member; `notify_member_died` saves dead IDs; `capture_state` and `restore_state` persist the group; `_living_members` lists active members.

Member functions: `_ready`, `setup`, `_physics_process`, `_update_flight`, `_separation_velocity`, `_try_hit`, `_recover`, `_release_attack`, `_on_seen`, `_on_lost`, `_on_sound`, `interrupt_action`, `request_interrupt`, `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds`.

Do not place individual `SkyHunter` nodes through ordinary enemy placers. Place/use the flock owner already authored in the Layer 2 root.

### 4.5 Tremor Hound

**ID:** `tremor_hound`  
**Script:** `game/enemies/layer2/tremor_hound.gd`  
**Role:** sound hunter and close-range pounce threat.

The Hound patrols its authored horizontal bounds. Sound is scored by priority, intensity, and distance; the best sound creates an investigation point. When the player is close, the Hound confirms the target, telegraphs, pounces, and applies damage/force on collision. It searches briefly after investigation and recovers after a pounce.

Tuning: `patrol_bounds`, `gravity`, `patrol_speed`, `investigation_speed`, `close_confirmation_radius`, `pounce_prepare_duration`, `pounce_speed`, `pounce_duration`, `pounce_damage`, `pounce_force`, `recovery_duration`, `search_duration`.

Functions: `_ready` setup; `_physics_process` state/gravity/collision loop; `_on_sound` scores and begins investigation; `_recover` enters recovery; `interrupt_action` cancels preparation; `request_interrupt`, `apply_damage`, `apply_force`, `apply_status`, `capture_state`, `restore_state`, `handle_world_out_of_bounds` implement the shared contract.

## 5. Test-only actors

These are for debug rooms and should not be treated as production enemy design:

- `game/enemies/test/test_amphibian.tscn`: simple test enemy for damage/force/status checks.
- `game/enemies/test/projectile_turret.tscn`: stationary projectile source for testing projectile collision, damage, and player response.

Their purpose is instrumentation, not balance. Do not use them as a template for production AI unless a behavior is intentionally promoted into a real enemy.

## 6. World and item interaction matrix

| System | Expected enemy-facing behavior |
| --- | --- |
| Sight | Use `SightSensor`; respect blocked line of sight and the player's head detection origin. Dazzled/suppressed detectors should prevent acquisition. |
| Sound | Use `SoundListener`; interpret priority/type in the enemy script. A sound is a location and event, not automatically a target. |
| Light | Register `LightSource2D` sources. Spider flees from active light; Snail owns a light; darkness does not automatically disable all enemies. |
| Damage | Use `ImpactData`/`EnemySupport`; set source actor, species, damage, force, attack kind, and statuses. |
| Force | Ordinary enemies accept support force. Flying/global/heavy enemies may intentionally ignore or modify it. Document exceptions. |
| Status | Use stable effect IDs. Shared support owns duration and effect text. Enemy scripts may interpret a status as a state interrupt. |
| Items | A thrown item is a real world object. It can be picked up, stolen, saved, lost, or used to trigger an enemy. A projectile is temporary and cannot be collected. |
| Electric | Supported enemies enter disabled behavior, lose active attacks where implemented, and should not jump/fly/continue a telegraph while stunned. |
| Terrain | Grounded enemies require floor support. Surface walkers require continuous terrain. Flyers need valid clear-air placement and blockers only when authored. |
| Persistence | Stable IDs, `capture_state`, and `restore_state` are required for enemies that can be placed, killed, carry items, or alter progression. |
| Bounds | `handle_world_out_of_bounds` must recover the enemy and any important carried/dropped item instead of allowing permanent loss. |

### Item design patterns

- Multitool: low-damage utility, breaks sources, recovers stolen items, and triggers hazards.
- Rope: changes traversal and mitigates vertical displacement.
- Hushcap: breaks sight and creates a temporary safe reading of a room.
- Rattlepod/Whistle: creates sound, redirects listeners, and can trigger Snail/Diver/Flyer interactions.
- Lantern Crystal: portable light/flash/noise interaction derived from the Snail.
- Silver Weight: high-force/high-damage answer to small enemies and a costly answer to large enemies.
- Bandage: removes Bleed, not Poison; status combinations should preserve meaningful choices.

## 7. Enemy placer system

### What a placer is

A placer is a `Marker2D` with `DeterministicPlacer` attached. It stores a recipe instead of containing the gameplay instance directly:

```text
run seed + persistent ID
  -> activation chance
  -> quantity
  -> entry selection
  -> SpawnPoint selection
  -> saved manifest result
  -> runtime enemy/breakable/item instance
```

The same seed and persistent ID produce the same result. Continue restores the saved result; it does not reroll.

### Normal generated-world flow

1. `WorldGenerator.build_manifest` instantiates layer templates.
2. It validates every section, placer, entry, and persistent ID.
3. It resolves allocation groups.
4. Each ordinary placer calls `resolve(run_seed)`.
5. The manifest stores content ID and selected SpawnPoint index.
6. `WorldLayer.instantiate_manifest` restores the saved result and calls `spawn_resolved(runtime_root)`.
7. Spawned objects receive compatible fields such as persistent ID, item ID, spawn group, patrol bounds, and spawn position.

### Standalone foundation test room flow

`foundation_test_room.gd` finds descendant `DeterministicPlacer` nodes and runs the same `resolve(GameSession.run_seed)` and `spawn_resolved(self)` path before restoring saved objects. This is why placers can now be tested by pressing F6 on the room itself or using the F3 debug-room button.

### Shared Inspector fields

| Field | Meaning |
| --- | --- |
| Persistent Id | Stable globally unique identity and deterministic seed input. Never reuse or casually rename. |
| Spawn Chance | Chance that the whole placer activates. `1.0` is always active. |
| Entries | Weighted `WorldSpawnEntry` resources. Each entry contains content ID, scene, and positive weight. |
| Minimum/Maximum Quantity | Number of results when active. Quantity is allowed to reuse a SpawnPoint; repeated results get occurrence suffixes. |
| SpawnPoint children | Exact authored candidate positions. Direct `Marker2D` children are discovered automatically. |
| Allocation Group | Candidates with the same non-empty group compete; only one wins. Leave blank for ordinary enemies. |
| Required Allocation | A winning unique candidate ignores ordinary chance failure. Use only for supplied required templates. |
| Spawn Group Id | Shared coordination identity for compatible enemies. Blank falls back to the placer ID. |
| Attack Group Maximum/Spacing | Limits simultaneous coordinated attackers where the spawned enemy supports it. |
| Facing | Horizontal orientation: `1` normal, `-1` flipped. |
| Patrol Bounds | Enemy-specific local patrol/flight rectangle passed to compatible scenes. |
| Drop Scatter Radius/Height | Loot placement controls passed to compatible breakable/drop scenes. |

### Authoring rules

- Give every placer a globally unique stable ID, including across A/B variations.
- Put SpawnPoints as direct children of the placer and do not reorder them after saves are released.
- Do not set quantity above the number of SpawnPoints when using section generation.
- Place grounded enemies on valid support, flyers in clear air, and loot over safe floor.
- Keep ordinary enemy placers under a section's `Placers` organization node.
- Do not place Large Flyer, Senior Diver, or Sky Hunter members as ordinary enemies; use their special authored systems.
- Use `EnemyPlacer` for ordinary Layer 1 enemies, `BirdNestPlacer` for bird groups, `LargeFlyerPlacer` for the Layer 1 global flyer, and `Layer2EnemyPlacer` for ordinary Layer 2 enemies.
- Use `LootPlacer` with `BreakableLoot` when the reward should be behind a breakable source. Use direct `WorldItem` for a visible pickup or unique relic.

### Common placer failures

| Symptom | Likely cause |
| --- | --- |
| Nothing spawns | Chance failed, wrong variation selected, saved Continue manifest, missing entry, blank ID, or standalone scene not being used. |
| Quantity error | Maximum exceeds authored SpawnPoint count in generated sections. |
| Duplicate ID | Same persistent ID exists in another selected or possible variation. |
| Wrong content | Entry Content Id does not match its Scene or item/enemy definition. |
| Enemy appears in bad place | SpawnPoint has wrong support, air clearance, patrol bounds, or seam position. |
| Unique content duplicates | Allocation group/required flag was changed or candidates are missing from possible layouts. |

## 8. Designer workflow

### Tuning an existing enemy

1. Identify the enemy's role and desired player decision before changing numbers.
2. Tune exported scene values first.
3. Use the foundation test room or a section test runner with a known seed.
4. Test sight blocked/unblocked, sound types/priorities, item interactions, status effects, terrain edges, and electric interruption.
5. Check the warning pointer and overhead effect text.
6. Test death, save/continue, out-of-bounds recovery, and cross-species damage.
7. Update this handoff and the relevant specialized spec when behavior intentionally changes.

### Designer behavior-change template

Use this short format when a new behavior is needed:

```text
Enemy:
Player decision this should create:
Trigger/input:
Target selection:
Telegraph and duration:
Resolution: damage / force / status / item / movement / world event
What cancels it:
Counterplay:
Inspector values needed:
Save/load impact:
Placement requirements:
```

The implementation should then follow this order:

1. Reuse existing sensors, `ImpactData`, `EnemySupport`, status IDs, and attack coordination where possible.
2. Add only the smallest new state or callback needed.
3. Export the values the designer needs to tune.
4. Add a debug visualization for important ranges, hitboxes, patrol areas, and telegraphs.
5. Add a foundation-room or isolated smoke scenario before balancing.

Do not solve a local enemy request by changing a shared system's semantics without checking every other enemy that uses it.

### Adding an enemy

The minimum implementation should define:

- enemy ID, species ID, tags, layer, and `EnemyDefinition`;
- scene with collision, visual, `EnemySupport`, and required sensors;
- explicit states and transitions;
- telegraph/attack resolution and cancellation rules;
- item, terrain, light, sound, and status responses;
- save/load and out-of-bounds behavior;
- a placer or special placement contract;
- a test-room fixture or smoke scenario.

Do not start with a general-purpose AI framework. Start with the smallest state machine that expresses the enemy's unique pressure, then reuse shared sensors/support/coordinators.

### Acceptance checklist

- [ ] Player can identify what the enemy is doing and why it is dangerous.
- [ ] At least two meaningful counterplay options exist.
- [ ] Telegraphs use the dynamic player warning system.
- [ ] Blocked sight and player head detection are respected.
- [ ] Sound is filtered by type/priority intentionally.
- [ ] Damage, force, status, electric, and same-species rules are explicit.
- [ ] Enemy item interactions use real ownership/world-item APIs.
- [ ] Terrain support and transition behavior are tested.
- [ ] SpawnPoint placement and placer quantity are valid.
- [ ] Persistent state survives save/continue where required.
- [ ] Enemy does not become permanently lost outside world bounds.
- [ ] F3 debug visualization is added for any important range/hitbox.
- [ ] Automated smoke checks and a manual encounter check pass.

## 9. Source-of-truth map

| Concern | Source |
| --- | --- |
| Enemy identity/tags/stats | `data/enemies/*.tres` |
| Enemy state and behavior | `game/enemies/**/*.gd` |
| Enemy scene nodes/collision/sensors | `game/enemies/**/*.tscn` |
| Shared health/status/force/persistence | `game/enemies/enemy_support.gd` |
| Sight/sound contracts | `game/player/sight_sensor.gd`, `game/world/sound_listener.gd` |
| Damage and status delivery | `game/items/impact_data.gd`, `game/player/status_controller.gd` |
| Placer resolution | `game/world/deterministic_placer.gd`, `game/world/world_generator.gd` |
| Runtime placer spawning | `game/world/world_layer.gd` |
| Map authoring rules | `docs/map_placer_authoring_reference.md` |
| Layer 1 design roles | `docs/layer_1_enemy_item_design_reference.md` |
| Layer 2 placement/integration | `docs/implementation/layer_2_world_integration.md` |
