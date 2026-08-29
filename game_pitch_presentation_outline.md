# Game Pitch Presentation Outline

## Recommended format

- **Length:** 7–10 minutes
- **Slides:** 10–12, with gameplay footage or screenshots on most slides
- **Audience:** Indonesian game-jam audience; present in Bahasa Indonesia where possible
- **Rule:** explain the player experience first, then the features that create it

## Slide 1 — Title and hook

Show the game logo, strongest cave screenshot, and a short tagline.

Suggested tagline:

> **Turun ke dalam. Beradaptasi. Kembali membawa relic.**

Say the game name, genre, and the one-sentence promise in under 20 seconds.

## Slide 2 — The elevator pitch

Suggested pitch:

> This is a pixel-art cave exploration adventure where the player, a Delver,
> descends into a dangerous underground world to recover valuable relics and
> return safely. Every item changes how the player handles light, sound,
> movement, or enemies, so every expedition becomes a risk-versus-reward
> decision.

Keep this slide focused on what makes the game immediately understandable:

- Explore a hostile cave.
- Use relics and supplies creatively.
- Avoid or fight reactive enemies.
- Decide when to turn back with your discoveries.

## Slide 3 — Player fantasy and core question

Explain who the player is and what creates tension.

- The player is a Delver entering places that are dangerous and unfamiliar.
- The cave reacts to light, sound, proximity, and player mistakes.
- Combat is useful, but survival and returning with the relic matter more.
- The central question is: **“How much farther can I safely go?”**

Use one short gameplay clip here instead of a dense feature list.

## Slide 4 — Core gameplay loop

Present this as a simple loop:

```text
Prepare at the surface
        ↓
Descend into the cave
        ↓
Explore, traverse, and locate relics
        ↓
Use items while managing light, sound, and threats
        ↓
Collect valuable discoveries
        ↓
Return to the surface and progress
        ↺
```

Mention that the tension comes from the return trip: a valuable discovery is
only useful if the player gets it back safely.

## Slide 5 — The signature mechanic: relics with consequences

Show a small item montage or a 2-column item example table.

| Example | Player use | Consequence or trade-off |
|---|---|---|
| Sun Sphere | Creates light and reveals the environment | Changes visibility and can affect encounters |
| Rattlepod / sound items | Creates a sound event or distraction | Enemies may investigate the sound |
| Hushcap | Helps conceal the player | Affects detection while inside its area |
| Cling Resin | Slows loose items and movement in its area | Can control space but also makes movement harder |
| Rope | Enables traversal and recovery options | Gives the player more route choices |
| Shock or offensive relics | Damages or controls enemies | Has timing, range, and resource trade-offs |

The key message: there is no single best loadout. The player creates a plan
from tools that alter the rules of the cave.

## Slide 6 — Enemies as a reactive ecosystem

Describe enemies by the decisions they force, not only by their attacks.

- **Frog:** roams, steals loose pickupable items, and hops away with them;
  the player can interrupt the theft or recover the item.
- **Cave Spider:** uses sight and projectiles, can chase into melee range, then
  retreats to a safer firing position.
- **Lantern Snail:** avoids the player, traverses connected terrain, and uses
  a dangerous flash when threatened.
- **Thorn Bloom:** looks harmless while idle, then explodes into radial needles
  that create a temporary hazard and inflict bleed.
- **Knockback Bird:** patrols, telegraphs a dive, attacks, and repositions.
- **Gatekeeper:** connects exploration, dialogue, relic delivery, and access to
  the next layer.

Only show enemies that are present and reliable in the pitch build. A short
clip of one enemy interacting with an item is stronger than six static enemy
portraits.

## Slide 7 — Exploration, atmosphere, and readability

Show the cave, darkness, lighting, surface/cave contrast, and traversal.

Explain that the world is dangerous because information is limited:

- Darkness makes the player choose when to spend light.
- Sight and sound detectors make noise and visibility meaningful.
- Status effects communicate danger and persistence.
- Ropes and terrain create multiple routes through the same space.
- Telegraphs and debug-friendly enemy behavior are designed to keep threats
  readable rather than random.

## Slide 8 — Story and progression

Keep the story summary short and visual.

- The Delver is sent below the surface to recover relics from the cave.
- Surface characters, including the Old Man and Gatekeeper, frame the journey
  and provide context for the player’s discoveries.
- Relic deliveries and surface progression give each expedition a purpose.
- The Layer 2 gate is the current end goal for the presentation build.

Avoid explaining unfinished future content as if it is already playable.

## Slide 9 — Guided demo plan

Use this as the live presentation sequence, targeting 2–3 minutes:

1. Start at the surface and briefly show preparation or the shop.
2. Enter the cave and demonstrate darkness/light.
3. Use one relic that creates a meaningful trade-off, such as sound or light.
4. Show an enemy reacting to the player or to the item.
5. Collect a relic or supply and demonstrate the risk of carrying it out.
6. Return to the surface or reach the Layer 2 gate.
7. End on the strongest visual moment, not on a menu.

Prepare a recorded backup clip in case the live build misbehaves.

## Slide 10 — What makes the game stand out

Use three memorable points:

1. **Items change the rules of the world.** They are tools for planning,
   traversal, information, and survival—not just inventory numbers.
2. **Enemies interact with the same world as the player.** They can react to
   sound, sight, items, terrain, and status effects.
3. **The return creates the tension.** Finding something valuable is only half
   the objective; bringing it home is the real test.

## Slide 11 — Current build and scope

Be honest and concise about what is playable tonight.

### In the presentation build

- Playable surface and Layer 1 cave exploration
- Core item/relic interaction systems
- Enemy detection, telegraphs, attacks, and status effects
- Surface dialogue and progression through the Gatekeeper
- Layer 2 gate as the end-goal destination

### Possible future expansion

- More cave layers and map variety
- More relic combinations and enemy interactions
- Additional narrative, upgrades, and progression depth

Replace these bullets with exact tested features before presenting.

## Slide 12 — Team, ask, and closing

Show team names and roles, then state what you want from the audience:

- Feedback on the core loop
- Playtesters and level-design feedback
- Support for continued development
- Publishing, funding, or collaboration opportunities

Close with the tagline and one final screenshot:

> **The cave gives you power, but it always asks for something in return.**

## Optional appendix slides

Use these only if questions require them:

- Controls and onboarding
- Item interaction chart
- Enemy behavior chart
- Map progression and layer structure
- Technical choices and performance improvements
- Development roadmap

## Quick presentation advice

- Put gameplay on screen within the first minute.
- Keep each slide to one idea and very little text.
- Use Bahasa Indonesia for the spoken pitch and subtitles if the audience is
  primarily Indonesian.
- Say the player action and consequence together: “I throw this to make noise,
  and now the frog investigates it.”
- Do not list every feature. Demonstrate the smallest sequence that proves the
  game’s identity.
- End with a clear ask, even if the ask is simply “please play and give us
  feedback.”
