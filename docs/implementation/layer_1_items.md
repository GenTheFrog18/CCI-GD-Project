# Layer 1 Items Implementation Contract

## Shared Rules

- Every definition explicitly assigns primary and secondary behaviour.
- Failure never removes, duplicates, or changes an item.
- Activation transfers one real unit to a prepared/world owner. Completion destroys it; cancellation returns/drops it by item rule.
- Active throws have no ordinary physical damage. Inactive throws use configured impact.
- Only default/stateless instances stack. Acquisition origin participates in compatibility.
- Successful signature effects count discovery; invalid use does not.
- Real inactive drops persist. Temporary fields and spent active items do not.

| Item | Primary | Secondary/special |
| --- | --- | --- |
| Red/Blue Whistle | dedicated-slot high-priority sound | physical slot may be stolen/dropped |
| Multitool | existing thrust/tool | disabled |
| Rope | existing placement/extension | generic throw |
| Throwable Rock | held thrust | physical throw |
| Bandage | reject at full health; remove bleed; heal | generic throw |
| Info Book | reveal remaining discoverable descriptions | generic throw |
| Numbing Pill | add 300 s suppression to max 999 | generic throw |
| Sun Sphere | prepare active light | active throw; inactive impact activates |
| Lantern Crystal | LOS dazzle/lure at player, consume | physical throw then dazzle/lure, consume |
| Rattlepod | active pod, 2 pulses/s, 10 pulses | active throw; inactive physical/recoverable |
| Hushcap | cloud at player | cloud at first impact |
| Cling Resin | small patch | larger impact patch |
| Driftseed | apply to player | valid target consumes; miss recoverable |
| Silver Weight | prepare heavy | multi-hit; full ID becomes damaged ID, second breaks |

Active Rattlepod drops on inventory/shop/slot change/Save & Menu and is not restored. Temporary light/cloud/resin clears on Continue. Driftseed and actor statuses save duration. `silver_weight` and `silver_weight_damaged` are separate maximum-stack-one IDs.

Use shared damage, force, status, sound, sight, agitation, and target contracts. Flying actors ignore ordinary/resin slow but accept Driftseed. Silver Weight kills `small_enemy` and deals adjustable 200 damage to the large flyer.

Map drops, enemy drops, purchases, starting equipment, and replacements record origin. Senior diver removes only map-found items. Harvest/growth sources are persistent, configurable, two-hit Multitool targets.
