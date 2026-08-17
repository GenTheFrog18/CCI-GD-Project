# Layer 2 Enemies Implementation Contract

This file records implemented behavior, save boundaries, Inspector tuning, and the level-designer handoff. It must be updated in the same checkpoint as enemy code.

Stable IDs are `canopy_primate`, `tremor_hound`, `carrion_stalker`, `bulwark_beast`, and `sky_hunter`; the persistent flock ID is `layer_2_sky_hunter_flock`.

- Canopy Primate: grounded frog jumps, sight-first, one independent group per placer, coordinated transient rock throws.
- Tremor Hound: sound/intensity-first investigation of recorded event positions and committed pounce.
- Carrion Stalker: wounded-status prey scoring across player and other species; neutral roaming when no prey exists.
- Bulwark Beast: locked, high-damage charge with real deceleration/recovery.
- Sky Hunter Flock: persistent coordinated flying members; one-member attacks/effects; coexists with the transferred Layer 1 Large Flyer.

Shared rules use `EnemySupport`, accepted `ImpactData`, detector suppression, interruption, status effects, and `SoundEvent`. Same-species damaging impacts reject attached force/statuses. The shop blocks enemy bodies and targeting/damage while allowing projectile and hitbox nodes to pass physically.

Alarm Grazer and Glasswings are not implemented. Final art, audio, complex navigation, full boids, bespoke drops, and Curse-aware AI pausing are out of scope.
