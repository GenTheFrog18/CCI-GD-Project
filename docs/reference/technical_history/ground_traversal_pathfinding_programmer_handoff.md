# Optional Ground Traversal and Jump Pathfinding

> **Archived:** implementation proposal. Current architecture: [`../../fondasi_teknis_godot.md`](../../fondasi_teknis_godot.md).

**Engine:** Godot  
**System type:** General-purpose optional enemy movement mechanic  
**Status:** Implementation handoff  
**Primary use:** Enemies that need to walk across irregular solid terrain, jump gaps, change elevation, or safely fall to lower ground

This system is not specific to Layer 2 and must not become the default enemy movement behavior. Ordinary enemies keep their current movement scripts. An enemy opts into this mechanic by adding the reusable traversal component and explicitly requesting a traversal route.

The system uses existing static TileMap collision geometry as its only level-authoring source. Designers do not place platforms, jump points, launch markers, landing markers, or navigation nodes.

---

## 1. Goals

The system must:

- work with organic map geometry rather than rectangular platforms;
- combine collision geometry from multiple TileMaps in the same navigation scope;
- treat all collision as solid, including any one-way collision encountered in the future;
- support walking, upward jumps, horizontal gap jumps, downward jumps, and safe falling;
- use each enemy’s existing gravity, jump, speed, body shape, and physics values;
- keep jump arcs outside solid collision;
- share generated navigation data between enemies;
- avoid expensive per-frame full-map pathfinding;
- allow an enemy to opt in without changing unrelated enemy movement;
- return a clear failure result when no route exists;
- make actively chasing enemies fall back to a local search state when the target becomes unreachable;
- provide an F3 debug view for generated geometry, routes, and failed traversal attempts.

The system must not:

- require manual navigation authoring;
- assume the world has true platforms;
- teleport an enemy between surfaces;
- rewrite a jump arc after launch;
- force every enemy to use jump traversal;
- decide enemy behavior such as roaming, chasing, investigating, or attacking.

---

## 2. Opt-in integration

An enemy scene should opt in by adding a reusable component:

~~~text
Enemy
├── EnemySupport
├── Existing enemy movement/AI
└── GroundTraversal2D       optional
~~~

Enemies without GroundTraversal2D continue using their existing movement behavior.

The component becomes active only when the enemy AI makes a request such as:

~~~gdscript
ground_traversal.request_move_to(target_position, movement_reason)
~~~

Possible reasons include:

~~~text
ROAM
INVESTIGATE
CHASE
SEARCH
RETREAT
SCRIPTED
~~~

The reason is informational. The component does not decide what the enemy wants. It only plans and executes movement toward the requested location.

### Component responsibilities

GroundTraversal2D owns:

- route requests;
- collision-derived surface discovery;
- walk, jump, and fall route generation;
- movement-segment execution;
- landing validation;
- route failure reporting;
- local replanning;
- traversal debug information.

The enemy AI owns:

- choosing destinations;
- choosing roaming targets;
- deciding whether to chase, search, attack, or abandon a target;
- state transitions;
- animation selection;
- reaction to NO_ROUTE;
- deciding when the traversal component should be active.

The traversal component may control movement while a request is active, but it must report its state so the enemy keeps ownership of behavior and animation.

---

## 3. Navigation source: static TileMap collisions

The entire game map is static during gameplay. Navigation data should therefore be generated from collision geometry and cached rather than rebuilt continuously.

Some sections contain multiple TileMaps with collisions. The navigation builder must combine every relevant TileMap collision source in the current navigation scope into one collision query space.

The system must not depend on a specific TileMap node name. It should either:

- inspect TileMaps registered with a shared navigation provider; or
- discover relevant TileMaps under the current loaded section root.

The exact registration mechanism may follow existing project conventions, but the result must be a single combined collision source for navigation queries.

### Collision rules

- Collision geometry is authoritative.
- All relevant collision is treated as solid.
- One-way collision behavior is not required; if encountered, treat it as solid for navigation analysis.
- Jump arcs may not pass through solid collision.
- The enemy’s complete collision shape must be used for clearance checks, not only its center point.
- Dynamic actors are not part of the static navigation bake. They are handled by runtime collision checks.
- Gravity is always downward for this generalized mechanic.

---

## 4. Navigation scope and caching

Use a shared navigation cache for the currently loaded section.

Do not create a separate complete graph for every enemy. Do not rebuild the entire map whenever one enemy requests a route.

Recommended strategy:

1. The current section owns or exposes one shared navigation cache.
2. The cache scans static collisions once, or incrementally as needed.
3. Surface samples are generated only in the relevant loaded scope.
4. Jump and fall transitions are generated lazily when a route needs them.
5. Successful and failed transition tests are cached.
6. Every opt-in enemy reuses the same geometry cache.
7. The cache is discarded when the section unloads.

This is the selected least-resource strategy for the static map: shared section-level geometry, lazy traversal links, and no per-enemy full-world graph.

Because the map is static during gameplay, normal navigation data does not need runtime invalidation. It may be rebuilt when a section loads, a section variation changes, or development tools request a rebuild.

---

## 5. Generated surface representation

The system should generate temporary in-memory surface samples from collision boundaries. These are data records, not manually placed scene nodes.

Each sample should contain at least:

~~~gdscript
class_name GroundSurfaceSample

var position: Vector2
var normal: Vector2
var tangent: Vector2
var surface_id: int
var clearance_valid: bool
~~~

The builder should identify locations where an enemy movement profile can stand under downward gravity:

- solid support exists below the body;
- the body has sufficient headroom;
- the surface angle is within the profile’s allowed walkable angle;
- the body is not embedded in another collision shape.

The system must support irregular surfaces rather than reducing every shape to rectangles.

### Sampling

Use a coarse configurable sample spacing rather than one sample per pixel. A starting range of one-half to one TileMap cell is reasonable, but the value must remain adjustable.

After sampling:

- merge nearby redundant samples;
- simplify nearly collinear runs;
- preserve samples near corners, ledges, gaps, and slope changes;
- preserve enough samples to identify valid launch and landing locations.

The graph should be sparse enough for efficient pathfinding but dense enough that an enemy can find a usable launch and landing position on organic terrain.

---

## 6. Movement profiles

The shared geometry can be used by different enemies through a movement profile.

The profile should read existing enemy values wherever possible instead of introducing a second source of truth.

~~~gdscript
class_name GroundTraversalProfile

var body_shape: Shape2D
var body_width: float
var body_height: float
var walk_speed: float
var gravity: float
var jump_velocity: float
var horizontal_jump_speed: float
var air_control: float
var max_walkable_slope: float
var max_safe_fall_height: float
var can_jump: bool
var can_fall: bool
~~~

The profile may be built from the parent enemy’s existing script/resource values. If an enemy does not have a jump value, it cannot use jump transitions until one is supplied by its existing movement configuration.

The component must not silently override an enemy’s existing gravity or jump physics. If a traversal-specific override is needed, it must be explicit in the Inspector or movement resource.

Two enemies using the same terrain may have different routes because of body size, jump height, jump distance, movement speed, air control, slope tolerance, and safe fall height.

---

## 7. Generated movement connections

The navigation graph should contain movement connections of three types:

~~~text
WALK
JUMP
FALL
~~~

### Walk connections

Connect neighboring surface samples when:

- the enemy-sized body can move between them;
- the movement path has enough clearance;
- the surface transition is within the profile’s walkable slope/step limits;
- static collision does not block the swept body.

The walk test should use a swept body or equivalent collision query rather than only a line between sample centers.

### Jump connections

Jump connections are generated automatically when needed.

For a candidate launch and landing pair:

1. Confirm the launch sample is reachable by walking.
2. Confirm the landing sample has enough space for the enemy body.
3. Calculate an arc using the enemy’s existing gravity, jump velocity, horizontal movement speed, and air control.
4. Sweep or sample the complete enemy collision shape along the arc.
5. Reject the connection if any point of the arc intersects solid collision.
6. Confirm the arc ends at a valid landing surface.
7. Confirm the landing movement will not embed the body in terrain.
8. Cache the valid connection for the current movement profile.

The system must support jumping upward, horizontally across gaps, and downward to lower ground. It must also support landing on uneven or organic collision boundaries.

The arc must remain outside solid collision for the entire jump, not only at launch and landing.

### Fall connections

A lower surface may be reachable by falling without a jump.

For a candidate fall:

1. Confirm the enemy can leave the current surface safely.
2. Trace downward through empty space.
3. Find a valid lower landing surface.
4. Confirm the body will not hit an intermediate solid edge.
5. Estimate the fall damage using the shared fall-damage model.
6. Accept the fall only when the estimated damage is no greater than 10% of the enemy’s maximum health.

The 10% rule is a safety cap, not a target. A fall with zero damage is preferred over one near the limit.

~~~gdscript
fall_damage_estimate <= enemy_max_health * 0.10
~~~

If the shared damage system cannot estimate fall damage, the fall must be treated as unsafe until an estimate is available.

Fall damage itself remains owned by the shared damage system. The traversal component only decides whether a fall is acceptable for routing.

---

## 8. Route planning

Use A* or an equivalent lightweight graph search over generated surface samples and movement connections.

The route cost should consider:

- walking distance;
- jump duration;
- fall duration;
- jump difficulty or clearance margin;
- estimated fall damage;
- previously failed transition penalties;
- optional enemy-specific preference weights.

The planner should generally prefer:

1. safe walking;
2. safe short falls;
3. reliable jumps;
4. difficult or narrow jumps only when necessary.

The planner must be able to return:

~~~gdscript
enum RouteResult {
    SUCCESS,
    NO_ROUTE,
    TARGET_INVALID,
    START_INVALID,
    TEMPORARILY_BLOCKED,
}
~~~

### Target projection

The requested destination may be any world position. The planner should project it onto the nearest valid surface sample reachable by the enemy profile.

Examples:

- A disturbance position in empty air projects to the nearest searchable ground surface.
- A player position on a higher ledge becomes a route target on that ledge.
- A player position on an unreachable surface returns NO_ROUTE.
- A roaming target that cannot be reached causes the enemy to choose another roaming target.

The planner must not teleport the enemy to the projected destination.

### Local replanning

The planner should replan only when needed:

- the route request changes;
- the target changes surface region;
- a route segment fails;
- a static collision query invalidates the route;
- an adjustable grounded replan interval expires.

It should not perform a full path search every physics frame.

---

## 9. Movement execution

The component executes one route segment at a time.

Example route:

~~~text
walk along irregular ground
→ walk toward launch region
→ perform upward arc jump
→ land on lower slope
→ walk to destination
~~~

### Grounded movement

While grounded:

- move toward the next generated surface sample or launch region;
- use the enemy’s existing horizontal speed and acceleration rules where possible;
- perform runtime collision checks against static geometry and active actors;
- allow replanning when the route becomes invalid.

### Jump execution

When the enemy reaches a valid launch condition:

- verify the launch area one more time;
- verify the arc is still collision-free;
- apply the committed jump velocity;
- enter a traversal-jump state;
- prevent route replacement until the jump resolves;
- use the enemy’s existing gravity and air-control values;
- monitor collision and landing.

Once launched, the target may move, but the current arc must not be rewritten. A new route may be requested after landing.

### Fall execution

When the enemy begins a planned fall:

- commit to the fall transition;
- do not steer toward a different route while falling;
- monitor the expected landing region;
- confirm grounded state after contact;
- report success or failure.

The component must not force an enemy to fall through solid collision. It may leave a surface only where the collision geometry and movement profile allow it.

### Host movement interface

The component should control traversal movement while active, but the parent enemy remains responsible for the final body integration and animation callbacks.

One suitable interface is:

~~~gdscript
func get_traversal_body() -> CharacterBody2D
func apply_traversal_velocity(velocity: Vector2) -> void
func perform_traversal_move_and_slide() -> void
func notify_traversal_animation(action: StringName) -> void
~~~

The exact API may follow the existing project framework. The important rule is that two independent scripts must not fight over velocity or call movement integration unpredictably in the same frame.

---

## 10. Dynamic obstacles

The TileMap navigation cache describes static geometry. Players, enemies, relics, and other movable objects are handled at execution time.

Runtime collision behavior:

- a temporary actor may block walking or landing;
- the traversal component detects the block through normal physics;
- the route is delayed, locally replanned, or marked temporarily invalid;
- the static graph is not rebuilt for a temporary actor;
- a jump arc is rejected if an active blocker occupies its launch or landing space.

When a transition fails:

- record the transition and failure reason;
- apply a temporary failure cooldown;
- increase its route cost or exclude it temporarily;
- request an alternate route;
- return NO_ROUTE if no alternate route exists.

Possible failure reasons:

~~~text
LAUNCH_BLOCKED
ARC_BLOCKED
LANDING_BLOCKED
LANDING_INVALID
FALL_UNSAFE
TARGET_MOVED
MOVEMENT_INTERRUPTED
~~~

---

## 11. Chase failure and search fallback

If an enemy is actively chasing a target and the traversal system returns NO_ROUTE, the enemy must not simply remain pointed at the unreachable target.

The enemy should:

1. record the last position where it still had a valid route toward the target;
2. cancel the unreachable chase request;
3. enter its own SEARCH state;
4. center the search area around that recorded reachable position;
5. perform the enemy’s normal search/idle behavior within that area;
6. abandon the search after the enemy-specific search duration;
7. select another behavior or roaming destination.

The traversal component reports the failure and the last valid route position. The enemy AI decides how the search state looks and how long it lasts.

~~~gdscript
signal route_failed(result, last_reachable_position, failure_reason)
~~~

If no last reachable position exists, use the enemy’s current valid grounded position as the search center.

The search fallback applies only to an enemy that was actively chasing something. Other route requests use their own failure behavior:

- roaming: choose another roaming target;
- investigation: discard or select another disturbance;
- retreat: choose another safe route or remain in place;
- scripted movement: report failure to the script owner.

---

## 12. Target movement and route updates

For a moving target:

- replan while the enemy is grounded when the target changes surface region or the route becomes inefficient;
- do not replan in the middle of a committed jump or fall;
- after landing, project the target’s current position again;
- if the target is no longer reachable, return NO_ROUTE and use the chase-search fallback;
- never convert a target position into omniscient movement through solid collision.

For a fixed target such as a disturbance location:

- preserve the recorded position;
- do not follow the source after the event occurs;
- replan only when the route fails or static geometry says the target projection changed.

---

## 13. Optional Inspector configuration

The component must remain optional and easy to add. A designer should be able to add the child component and connect it to the existing enemy movement values without writing a new pathfinding system.

Suggested Inspector properties:

~~~gdscript
@export var enabled: bool = true
@export var movement_profile_source: NodePath
@export var use_existing_gravity: bool = true
@export var use_existing_jump_values: bool = true
@export var sample_spacing: float
@export var walkable_slope_limit: float
@export var grounded_replan_interval: float
@export var route_failure_cooldown: float
@export var max_safe_fall_health_fraction: float = 0.10
@export var allow_upward_jumps: bool = true
@export var allow_horizontal_jumps: bool = true
@export var allow_downward_jumps: bool = true
@export var allow_safe_falls: bool = true
@export var debug_color: Color
~~~

The component must not expose or require a patrol rectangle, territory area, home point, manually placed jump point, or manually placed platform node.

---

## 14. Example enemy integration

### Enemy with no traversal mechanic

~~~text
Enemy scene
└── Existing movement script
~~~

No behavior changes occur.

### Enemy with traversal enabled

~~~text
Enemy scene
├── Existing AI script
├── Existing movement values
└── GroundTraversal2D
~~~

Enemy AI:

~~~gdscript
func pursue_target(target_position: Vector2) -> void:
    if ground_traversal.request_move_to(target_position, &"chase") == OK:
        state = CHASE

func _on_route_failed(last_reachable_position: Vector2) -> void:
    search_center = last_reachable_position
    state = SEARCH
~~~

The enemy still decides whether it is chasing, searching, attacking, or roaming. GroundTraversal2D only handles the route and movement segments.

---

## 15. Debug visualization

F3 debug mode should display the generated data without requiring manual scene authoring.

Show:

- collision-derived walkable surfaces;
- generated surface samples;
- walk connections;
- jump connections and their simulated arcs;
- fall connections;
- current route;
- current movement segment;
- launch and landing clearance checks;
- current movement profile values;
- failed links and their cooldowns;
- last reachable chase position;
- route failure reason.

Debug drawing should support filtering by:

- selected enemy;
- selected movement profile;
- selected section;
- only current route;
- only invalid/failed links.

---

## 16. Persistence and loading

The traversal mechanic is transient navigation behavior. It does not need to persist a route or an in-progress jump.

On save/load:

- preserve the enemy’s normal persistent state through the existing enemy save system;
- discard the current route;
- discard the current generated movement segment;
- do not resume an in-progress jump halfway through;
- restore the enemy at a valid grounded position when possible;
- reset the component to an inactive or neutral state;
- allow the owning enemy AI to request a new route after load.

The static section navigation cache may be rebuilt or reused when the section loads.

---

## 17. Acceptance tests

### General integration

- [ ] An enemy without GroundTraversal2D behaves exactly as before.
- [ ] An enemy can opt in by adding the reusable component.
- [ ] The component works with multiple TileMaps containing collision in one section.
- [ ] No manually placed platforms, jump points, or navigation nodes are required.
- [ ] The component does not decide enemy AI states.
- [ ] The component does not create competing velocity or movement integration with the parent enemy.

### Collision-derived geometry

- [ ] Static TileMap collision is the authoritative navigation source.
- [ ] Irregular and organic ground geometry produces usable surface samples.
- [ ] Slopes and surface changes are handled according to the movement profile.
- [ ] All collision, including future one-way collision, is treated as solid.
- [ ] Samples require body clearance and valid support.
- [ ] Multiple enemies reuse the same section-level geometry cache.

### Walking

- [ ] Walk routes follow actual collision geometry.
- [ ] The body shape, not only its center point, is checked for clearance.
- [ ] Grounded replanning does not run every physics frame.
- [ ] Temporary blockers cause local delay/replanning rather than a full geometry rebuild.

### Jumping

- [ ] Upward jumps can be generated automatically.
- [ ] Horizontal gap jumps can be generated automatically.
- [ ] Downward jumps can be generated automatically.
- [ ] Existing enemy gravity and jump values are used.
- [ ] The full collision shape is swept or sampled along the arc.
- [ ] No accepted arc intersects solid collision.
- [ ] Launch and landing positions are validated immediately before execution.
- [ ] A jump cannot be sharply redirected after launch.
- [ ] Target movement does not rewrite an active jump arc.
- [ ] A failed jump receives a temporary failure penalty.

### Falling

- [ ] Safe lower surfaces can be reached by falling.
- [ ] Unsafe fall heights are rejected.
- [ ] The estimated fall damage does not exceed 10% of enemy maximum health.
- [ ] If fall damage cannot be estimated, the fall is rejected.
- [ ] Fall damage itself is applied only by the shared damage system.

### Route failures

- [ ] An unreachable destination returns NO_ROUTE.
- [ ] A roaming enemy chooses another roaming destination after NO_ROUTE.
- [ ] An actively chasing enemy stores its last reachable chase position.
- [ ] An actively chasing enemy enters its own search state when the target becomes unreachable.
- [ ] Search centers around the last reachable position, or the current valid position if none exists.
- [ ] Failed routes do not create infinite retry loops.

### Debug and persistence

- [ ] F3 displays surfaces, routes, jump arcs, fall links, and failures.
- [ ] Save/load does not resume a damaging or invalid jump.
- [ ] Loaded enemies return to valid neutral movement before requesting new routes.
- [ ] Navigation cache behavior is deterministic for the same static map and movement profile.

---

## 18. Recommended implementation order

1. Add the optional GroundTraversal2D component and parent movement interface.
2. Build a shared section-level collision source combining all relevant TileMaps.
3. Generate and cache collision-derived walkable surface samples.
4. Implement body-clearance and walk-connection tests.
5. Read existing enemy movement profiles without duplicating their values.
6. Implement lazy jump-arc generation using existing gravity and jump values.
7. Implement safe-fall detection using the 10%-of-max-health damage cap.
8. Implement A* route planning over walk, jump, and fall connections.
9. Implement committed movement-segment execution and landing validation.
10. Add failed-link penalties and route failure results.
11. Add the chase-to-search fallback callback.
12. Add F3 debug rendering.
13. Test the mechanic on one simple enemy before connecting additional enemies.
14. Reuse the same component for Tremor Hound and future enemies only after the generic tests pass.
