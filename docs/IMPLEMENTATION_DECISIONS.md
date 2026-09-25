# First Playable Mission: Implementation Decisions

Status: Astra-reviewed production decisions for the locally packaged first playable blockout. The underlying experience is defined by [GAME_VISION.md](GAME_VISION.md), [MISSION_STORY.md](MISSION_STORY.md), and [STEALTH_AND_GUARD_BEHAVIOR.md](STEALTH_AND_GUARD_BEHAVIOR.md). Distances, times, health, ammunition and enemy counts below are provisional tuning values, not user-confirmed creative choices.

The user has confirmed a fictional European town in 1944 with no locked factions. Exact region and month remain unselected; this blockout does not assert either.

## Runtime ownership

`Main` owns a fresh `TownLevel`, `Player`, and `MissionDirector`, plus presentation. It creates level and player before calling `director.setup(player, level)`, `player.setup(director)`, and `level.setup(director, player)`, then places the player at `level.get_spawn_transform()`. A full scene reload resets the mission, delayed exposure event, guards, ammo, health and NPC interactions. Results and failure disable player controls. Pause releases the mouse; resume recaptures it.

The director alone owns mission phase (`INFILTRATE`, `INTEL_SECURED`, `EXTRACTED`, `FAILED`) and a separate persistent `lockdown` flag. Guards own local awareness; a local fight never sets lockdown. The level owns geometry, the two invulnerable mission NPC positions, and a finite one-time reinforcement spawn. HUD reads state and displays it; it never advances the mission.

## Contact and extraction

The contact is ready only when no guard is in `COMBAT`, no guard is searching within 24 metres of the contact, and nearby suspicion above 0.35 has subsided. Within 3 metres of the upstairs contact, holding E for 3 seconds transfers the copied packet. Releasing E, leaving range or losing safety cancels the whole exchange. The original papers and contact stay in place. The objective changes to extraction immediately on completed handoff.

About seven seconds later, returning personnel discover a cut security seal on the stair access and a surviving offscreen radio order locks down the town. This applies whether the player fought earlier, attacked guards, or left early. An audible arrival/radio cue and readable subtitle explain the cause; the event never takes control away. If the player reaches extraction before the scheduled order, the causal discovery and order play before victory. Reinforcements appear once. One E press within 3 metres of the sheltered fellow scout completes extraction even during combat, search or lockdown. Zero-kill completion is supported; killing does not fail the mission.

## Player and guards

The player uses WASD, mouse look, Shift to sprint, Ctrl/C to crouch, Space to jump, E to interact, F for eligible rear stealth kills, R to reload and left click to fire the automatic submachine gun. Right click aims; arrow keys offer keyboard look for a trackpad. The first weapon is an explicit placeholder pending free-asset evaluation. Thirty rounds fit one magazine, reserve ammunition is unlimited, and an empty magazine cannot fire until reloaded. Gunfire reports a 24 metre noise to the director. Guards react to hits through their own `take_damage` method. The director counts player kills.

Provisional movement speeds for the expanded route blockout are 3.2 m/s walking, 5.2 m/s sprinting and 1.45 m/s crouching. These remain pacing hypotheses. A known input-driven packaged route took 202.66 game seconds, which does not measure first-time human pace or add a stamina rule.

Health regenerates at 10 points per second after seven seconds without damage while no guard actively threatens the player. Persistent lockdown by itself does not suppress healing; death cannot regenerate. Guard tuning, combat damage and pacing remain subject to human playtest feedback; input-driven rendered route and combat observations are recorded in [QA_REPORT.md](QA_REPORT.md).

## Feedback and validation

The HUD gives a short briefing, objective bearing, distance and height, health, ammunition, reload, local suspicion/guard state, noise, interaction reason and progress, subtitles, and completion time/kills with retry. Mission NPCs are invulnerable, do not detect the player, and do not create alerts. Headless import and runtime checks are necessary but cannot establish playability. The exact PCK completed an input-driven rendered infiltration, handoff, escalation and extraction; separate rendered/native checks covered failure and retry. Full manual human navigation is still unmeasured; see [QA_REPORT.md](QA_REPORT.md).
