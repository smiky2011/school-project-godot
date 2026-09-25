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
