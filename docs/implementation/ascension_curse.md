# Ascension Curse Implementation Contract

> **Status:** current runtime contract. Tuning authority is `game/player/player.tscn`, `game/player/curse_tracker.gd`, and `data/effects/curse_*.tres`.

## Tracking

Player owns one `CurseTracker`. Godot Y grows downward, so ascent is `reference_y - player_y`. Reference follows new deepest positions and never moves upward merely because Curse was applied.

Default trigger band is 320 px. `crossed_band` prevents descending then reclimbing the same band from rerolling Curse. Crossing multiple complete bands processes each threshold.

Rest within `stillness_tolerance` for `stillness_seconds` resets reference/band. Surface, `CurseSafeZone`, layer transition, Continue placement, and out-of-bounds recovery reset or grant transition grace through the same tracker API.

## Warning

At `warning_threshold_ratio` of the next band, default 70%, HUD shows the warning icon above player and text `Naik terlalu cepat, akan terkena curse` in the status area.

Warning remains while player moves upward. Stopping starts `warning_stop_delay`, default 1 s. Crossing the threshold or resetting the reference clears warning immediately. Warning is presentation only and does not change Curse math.

## Suppression

Numbing Pill applies `curse_suppression`. Crossing a band while suppressed:

1. does not apply layer Curse;
2. subtracts the package duration from suppression;
3. advances/reset threshold state so the same climb is not retriggered.

Current consumable behavior adds 300 s up to 999 s.

## Layer packages

- Layer 1 applies/refreshes one 20 s `curse_layer_1`: movement ×0.75, healing ×0.6, throw range ×0.7, plus presentation colour.
- Layer 2 applies/refreshes one 40 s `curse_layer_2_penalty`, adds one independent 40 s `curse_layer_2_health_cap` stack up to five, and rolls once per second for an adjustable short control stop.
- Layer packages replace the relevant layer behavior; Layer 2 does not silently include Layer 1 modifiers.

Layer 2 exists as implementation foundation but is outside normal current progression.

## Save and debug

Save stores reference, crossed band, rest progress, transition grace, warning-relevant motion state, and persistent effect applications. UI warning itself is rebuilt.

F3 categories can draw Curse reference/threshold and provide reset, clear effects, healing, and force-current-layer-Curse actions.

## Acceptance

- Descend/reclimb within an already crossed band does not reroll.
- Warning begins at configured ratio and clears after configured stop delay.
- Rope, jump, and knockback count only when they cross a full band.
- Safe transition/recovery never creates an immediate false Curse.
- Suppression consumes the crossed band and remaining suppression persists through Continue.
- Layer 2 cap stacks independently and does not delete current HP directly.
