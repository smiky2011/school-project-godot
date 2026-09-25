# Play the First Mission

Status: playable blockout under integration and playtest. See [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md) for provisional tuning and confirmed design boundaries.

Open this project in Godot 4.7.2 and press Play Project (F5), or run the Godot executable with `--path "/path/to/personal project"`. On the target Mac, the currently available executable is `/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot`. The project starts with a briefing. Begin the mission to capture the pointer. Esc pauses and releases it; use Resume or Esc to return. The pause and result screens also offer a full restart and Quit.

| Action | Controls |
| --- | --- |
| Move / look | WASD / mouse; arrow keys also look for a trackpad or keyboard-only session |
| Sprint / crouch / jump | Shift / hold Ctrl or toggle C / Space |
| Fire / aim / reload | Left click or G / right click or H / R |
| Contact handoff | Hold E continuously while close, on the same floor, visible and safe |
| Extraction handoff | Press E once at the sheltered scout, even under pursuit |
| Quiet rear takedown | F while directly behind a nearby guard with a clear line |

The goal is the upstairs contact in the requisitioned residence. A safe three-second exchange gives the player copied plans, then the objective cue points to the fellow scout at the opposite side of town. Returning personnel discover a cut stair seal and order a persistent lockdown with finite reinforcements. The scout accepts the packet even if guards remain active. A no-kill run is supported; kills do not fail the mission. Death or Retry reloads the entire scene.

The HUD shows direction, distance and floor relation to the current objective; local suspicion, combat/search state and noise; health, ammunition and reload; interaction readiness/progress; and story subtitles. Guard vision cones are visible on the ground. The weapon model and much of the town are deliberate blockout geometry while asset selection and playtesting continue.

Movement pacing and the expanded route are provisional. No ten-minute run time has been measured yet.

For implementation checks, run Godot with `--headless --path . --editor --quit` for import, `--headless --path . --quit-after 120` for startup, and `--headless --path . --script res://tests/mission_regression.gd` for state and interaction regression. These checks do not establish that the mission is playable. Manual acceptance must traverse the contact, alarm, extraction, death and retry, including a zero-kill path.
