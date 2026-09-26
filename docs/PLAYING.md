# Play the First Mission

Status: a self-contained visual-production build is available locally. The current visual package completed an exact-PCK input-driven zero-kill run; remaining checks are tracked in [QA_REPORT.md](QA_REPORT.md). See [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md) for provisional tuning and confirmed design boundaries.

Double-click `build/1944 Town Mission.app` to play the self-contained local Mac build; it does not need Godot installed or the source project after packaging. To play from source instead, open this project in Godot 4.7.2 and press Play Project (F5), or run `/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot` with `--path "/path/to/personal project"`. The game starts with a briefing. Begin the mission to capture the pointer. Esc pauses and releases it; use Resume or Esc to return. The pause and result screens also offer a full restart and Quit.

| Action | Controls |
| --- | --- |
| Move / look | WASD / mouse; arrow keys also look for a trackpad or keyboard-only session |
| Sprint / crouch / jump | Shift / hold Ctrl or toggle C / Space |
| Fire / aim / reload | Left click or G / right click or H / R |
| Contact handoff | Hold E continuously while close, on the same floor, visible and safe |
| Extraction handoff | Press E once at the sheltered scout, even under pursuit |
| Quiet rear takedown | F while directly behind a nearby guard with a clear line |

The goal is the upstairs contact in the requisitioned residence. A safe three-second exchange gives the player copied plans, then the objective cue points to the fellow scout at the opposite side of town. Returning personnel discover a cut stair seal and order a persistent lockdown with finite reinforcements. The scout accepts the packet even if guards remain active. A no-kill run is supported; kills do not fail the mission. Death or Retry reloads the entire scene.

The HUD shows direction, distance and floor relation to the current objective; local suspicion, combat/search state and noise; health, ammunition and reload; interaction readiness/progress; and story subtitles. Guard vision cones are visible on the ground. The visible Sten, clothed mission actors and modeled houses have replaced their earlier placeholders. Other town elements and animation remain provisional; guard walking uses baked stride morphs, and finger poses are simple. Human playtesting remains open.

Movement pacing remains provisional. Known pre-art input-driven routes took about 3:23 through the packaged covered passage and 3:28 through the source direct-west route; neither measures a first-time human run. The revised visual build completed an automated covered route in 3:23. The intended roughly ten-minute human pace remains unverified. See [QA_REPORT.md](QA_REPORT.md) and [PLAYTEST_REPORT.md](PLAYTEST_REPORT.md).

For implementation checks, run Godot with `--headless --path . --editor --quit` for import and `--headless --path . --script res://tests/mission_regression.gd`, `guard_regression.gd` or `player_stance_regression.gd` for state, AI and stance regression. `rendered_guard_review.gd` captures staged idle, actual patrol stride and corpse frames in the town; it is visual inspection, not route play. Headless checks alone do not establish playability. The current visual PCK completed contact, alarm and zero-kill extraction; its exact-PCK evidence and remaining human acceptance limit are in [QA_REPORT.md](QA_REPORT.md).
