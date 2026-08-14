# Ascension Curse Implementation Contract

The player owns one persistent tracker. Scale is 32 px/metre; default band is 320 px. Because Godot Y grows downward, ascent is `reference_y - player_y`.

Reference follows new deepest positions. Curse application never moves it upward. Track greatest crossed band so descending/reclimbing does not retrigger; crossing several bands queues each. Vertical motion within 32 px for ten seconds counts as rest even while walking horizontally. Grounded or safe Rope rest resets reference/band to current position.

Surface and authored safe zones reset. Transition/load/recovery uses arrival position plus short grace. Jump, knockback, Rope, and continuous traversal count only when crossing a full band.

Numbing Pill adds 300 seconds to 999. Crossing under suppression applies no Curse, subtracts 20 seconds in Layer 1 or 40 in Layer 2, resets reference/band to current position, and retains any remaining suppression.

Layer packages replace one another; Layer 2 does not include Layer 1:

- Layer 1: one adjustable 20-second refresh/reroll effect reducing movement, healing, throw range, and changing colour; never grants benefit.
- Layer 2: refresh one 40-second throw/colour penalty; add an independent 40-second 10% health-cap stack to maximum five; once/second roll adjustable 5% for 0.5-second control lock and Rope detach. Existing health is not deleted; only healing is capped.

Save layer, reference, crossed band, rest progress, grace, suppression, package modifier/duration, and each cap timer. Gameplay/inventory advances timers; pause/menu/loading stops. F3 draws reference and supports reset, clear effects, add healing, and force current-layer Curse.
