# Town Level Blockout

Status: production layout for the first playable mission. The user confirmed a fictional European town in 1944; region, month, and factions are not fixed. Dimensions and encounter positions here are provisional and require a real playthrough. Primitive geometry carries no historical asset claim.

## Spatial plan

Coordinates use metres; north is negative Z. The playable core is about 52 m east–west by 80 m south–north. The player enters at the southern town edge near `(0, 35)`. A crooked main street runs toward a small public courtyard around `(0, 0)`. A sheltered western alley and an eastern yard/building passage reconnect north of the courtyard. They offer longer, more concealed routes than the central street. The requisitioned residence is north-central, with a usable entrance and stairs to the contact on its upper floor. The extraction scout waits in a sheltered position east of the northern street, beyond the residence; the player does not return to the entry point.

```text
                         NORTH / EXIT
          rear lane ─── residence ─────── scout shelter
              │       contact ↑                 │
          west alley ── courtyard ── east yard / passage
              │         landmark                 │
              └──── southern approach ──────────┘
                           ENTRY
```

The courtyard has a low stone pump/plinth landmark. Surviving stone building fronts, one damaged corner, recessed doors and a few road barriers establish town scale without fixing a particular nation. Plain signs use neutral functional words. The layout preserves broad sightlines at the junction so the player can observe a guard route on approach and reuse that knowledge during the reinforced escape.

The blockout uses four [CC0 Poly Haven samples](ASSET_PROVENANCE.md): plastered stone, stone wall, a restricted muddy approach patch and one colliding crate in a noncritical southern nook. Wall textures use roughly three-metre world-space tiles. These are representative import/material tests, not a locked national architectural style or final town art. A cloudy sky and soft directional light provide functional visibility.

## Playable routes and sightlines

| Route | Approach tradeoff | Escape use |
| --- | --- | --- |
| Main street and courtyard | Shortest route, clear landmark, exposed to a central patrol and sentry. Low walls provide breaks in sight. | Reinforcements occupy its junction but cover and cross-streets still allow a dash. |
| Western alley and rear lane | Longer, narrow and concealed with cover; a patroller can investigate noise or a body. | A no-kill bypass around the courtyard, reconnecting behind the residence. |
| Eastern yard and roofed building passage | Alternates an open yard and a narrow walk-through in a damaged corner building; contact approach is less direct. | Connects the north lane to the extraction shelter without entering the central junction. |

The residence entrance faces the north side of the courtyard. Interior stairs reach the upper contact without a jump, key or combat gate. The extraction shelter has an obvious protected recess and requires only the final interaction, regardless of nearby threats. Guards do not target either protected NPC. Ground-level cover and walls use real collision and truncate guard vision and gunfire. The upper contact is separate vertically from ground guards so ground-level cones do not imply sight through the floor.

## Encounter proposal to test

Initially one ordinary guard patrols the central street/courtyard, one holds the residence approach, and one patrols an eastern junction. Their routes leave the western alley usable by observation and timing. A one-time finite pair enters after the scripted lockdown and covers the central junction and north lane, while the western/eastern bypasses remain possible. Patrol, sentry and reinforcement are roles of the same guard archetype. No guard is spawned on the staircase or inside the contact room.

Pacing is unmeasured: the compact geometry alone is unlikely to take 6–10 minutes to cross at normal FPS walking speed. The world imposes no travel timer or forced wait. Measure cautious play before tuning patrols or expanding the map. Test actual traversal, sightline fairness, ramp reachability, contact safety, the shared junction, the reinforced no-kill bypass and final interaction in a rendered play session. Revise positions and dimensions based on observed movement rather than treating this draft as a measured historical plan.

## Town extension — Astra-approved layout, staged implementation

The functional blockout was completed in a rendered collision-driven no-kill run: 141.52 m travelled, 45.46 seconds game time, 82 health at extraction. That proves the loop and ramp work in this test, while showing that the current map is far shorter than the roughly ten-minute intended mission. Astra approved the following topology as an **implementation direction within the user-confirmed scope**. Geometry, encounter balance and pace still require validation. Keep the current courtyard, residence, contact room, roofed eastern passage and script API at their coordinates.

Implementation stage (southern district): the entry was moved to `(-48,198)`. Five staggered plot bands, connected lanes, one roofed workshop walk-through, neutral junction signs, a chimney landmark and three additional ordinary guards now connect the southern edge to the existing core. The contact, extraction and existing central geometry remain at their baseline coordinates; the north district and two additional post-alarm guards are still pending. Godot import, a 158-cell ground navigation path from new entry to the central seam, and 28 synthetic guard checks passed. No rendered route or pacing result for the extension has been recorded yet.

Extend the same town to roughly x = -65..65 and z = -205..205 (130 m across, 410 m north–south). Place a southern entry around `(-48, 198)` and the extraction shelter around `(44, -198)`. The current x≈-27..27, z≈-43..43 core remains the central district. South of it, an entry district has small homes, a workshop yard, plot alleys and a gently bending 6–9 m street. North of it, a workers' street, yard, back lane and sheltered town edge create a second series of crossings. Typical enclosed house fronts remain about 8–12 m wide. The central court may stay broad as a landmark; normal new streets should not inherit its open width. Bends follow building plots and reconnecting streets. Multiple through routes remain public streets or believable alleys rather than forced zigzags or closed mazes.

The sample **cautious no-kill path** below is a set of public QA waypoints and a distance hypothesis, never an automatic player path or required order. The approach travels `(-48,198)` → `(-50,166)` → `(-20,151)` → `(-8,126)` → `(-42,113)` → `(-44,80)` → `(-11,63)` → `(-12,37)` → `(-3,-15)` → contact `(4.6,-28.2)`: approximately **294 m** by straight segments. The escape travels contact → `(-10,-40)` → `(-48,-54)` → `(-48,-87)` → `(-11,-103)` → `(25,-121)` → `(25,-148)` → `(-14,-163)` → `(-14,-188)` → scout `(44,-198)`: approximately **325 m**. Combined waypoint distance is **619 m** before cornering, doors and observation. These coordinates describe topology and should be adjusted to the actual street centerlines during QA. Both routes use connected lanes through three districts; a more exposed main-street line stays shorter and viable. The west rear lane rejoins beyond the central courtyard, while the eastern building passage links toward the northern streets. The alarm makes the north lane crossing and later junctions riskier, but none is a kill or wait gate.

Encounter starting proposal: retain the three central guards, add three ordinary guards across the southern district and two in the northern district, giving eight initial guards. Expand the one-time post-alarm contingent from two to four ordinary guards: one at the existing north residence crossing, one at the central court, one near the north workers' junction around `(5,-95)`, and one near the northern edge crossing around `(18,-155)`. Alternate alleys and cover should make every encounter evadable without killing. Guard positions, patrol lengths and the exact additions require rendered no-kill playtesting. No new enemy archetype or mission objective is proposed.

At the provisional 3.2 m/s walking speed, the nominal 619 m path alone takes about 3.2 minutes of uninterrupted walking; crouch is 1.45 m/s and sprint is 5.2 m/s. The intended 6–10 minute cautious run depends on observation, route choice, interaction and recoverable guard encounters. This layout must be measured on the target Mac, including a direct route, a no-kill route, contact safety, reinforced extraction, health/failure balance, frame rate and restart. Do not add a countdown or forced delay to meet a duration target.
