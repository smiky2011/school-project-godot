# QA Report

Status: the current visual package built from commit `16943312f250fc6f6d241ab3baafe1ca5436cbcd` passed its exact-PCK rendered zero-kill route, combat smoke and native briefing/Begin/Pause/Restart smoke. Failure/retry checks of this same PCK are still in progress. Tests run on the target MacBook Pro M4 Pro (24 GB), macOS 26.6.2, Godot 4.7.2, Metal Forward+, 1280 × 720.

## Current visual package

The new `build/1944 Town Mission.app` contains `Game.pck` SHA-256 `16fa734717a5ee7532449a78f24d120449b67c2fc65fad3eced3c770c0de96b2`. `BUILD_INFO.txt` records the pushed commit above and `dirty=true` solely because unrelated local `CLAUDE.md` is untracked; game and packaging inputs match the commit. From `/private/tmp`, the bundled runtime loaded this exact PCK with external mission, guard and stance scripts: 40, 31 and 9 synthetic checks respectively passed. These confirm logic and resource loading, not rendered route completion.

The exact PCK then passed the covered route in a rendered Metal window using InputMap walking, looking and interaction through real collision and live guards. The contact handoff took 3.017 seconds and completed at game time 94.835 seconds. The lockdown order occurred at 103.55 seconds, with guards changing from eight to twelve. A single E press at the scout delivered the packet at 202.75 seconds, after 565.37 m of travel, with zero kills, no sprint and 100 health. [Spawn](media/visual_pack_16fa7347_spawn.png), [upstairs contact](media/visual_pack_16fa7347_contact.png), [sheltered scout](media/visual_pack_16fa7347_scout.png) and [delivery result](media/visual_pack_16fa7347_result.png) are selected frames from that new-PCK run. Its raw log and remaining frames are in ignored `build/qa/final_16fa7347/covered/`. This is an automated known route using player inputs, not a first-time human navigation test.

Across 198 one-second FPS samples, mean was 119.26 and minimum 101. Across 23,575 rendered-frame intervals, median was 8.373 ms and the 95th percentile 11.155 ms. Four 172–218 ms intervals followed screenshot saves by 3–5 ms; screenshot capture is the likely cause. These measurements describe this controlled 1280 × 720 run, not all gameplay or total process memory.

The same PCK passed a rendered combat smoke using normal player look, aim, fire and R reload inputs against a moving south-west patrol. The first bullet registered a hit and spent one round; three aimed shots killed the guard. Automatic fire then emptied the 30-round magazine, dry trigger left it at zero, and R restored 30 rounds in 1.933 seconds. Health remained 100. The revised external runner reads the guard's live position and steers through mapped look controls to keep a physical center-ray sightline; it never assigns player or guard transforms. Its first attempt used an obsolete fixed angle and failed to hit the patrol after the architecture changed. That was a test-driver aiming failure, corrected without changing or rebuilding the PCK. Raw evidence is ignored `build/qa/final_16fa7347/combat/aimed_run.log` and its four frames.

The outer `.app` also opened through ordinary macOS `open` with normal graphics permissions, outside the sandbox. Native CUA observed the briefing, clicked Begin and saw the street HUD (100 health, 30 rounds), pressed Esc and saw Pause, then clicked Restart Mission and returned to a fresh briefing. Short CUA W, Right, H and mouse-drag pulses produced no measurable movement, look or aim, so this smoke does not establish held-input gameplay control; the rendered InputMap route above covers continuous movement separately. A sandboxed `open` attempt first failed with LaunchServices `-10827`, then the normally launched package opened successfully. Failure/retry checks for this SHA are being recorded separately under `build/qa/final_16fa7347/`.

The staging import exited successfully but logged two tangent-generation diagnostics while importing the guard GLB. Seven of its eight meshes have UVs; the sole UV-less mesh is a solid-color belt with no normal map. Attributing both messages to that belt's two morph targets is an inference from GLB structure. Earlier Metal guard idle, moving and corpse frames showed no visible belt or clothing failure. Sandbox certificate, user settings and snapshot-directory diagnostics also appeared; they are not evidence of a successful gameplay run.

## Preceding blockout package evidence and scope

| Check | Method and observed result | Evidence |
| --- | --- | --- |
| Import and source parsing | Godot headless editor import and script checks exited successfully. | `build/qa/headless_import.log` |
| Mission state regression | 40 synthetic checks exercise interaction, alarm, reinforcement, extraction and retry logic; all passed against the packaged PCK. This does not exercise walking or rendering. | `tests/mission_regression.gd`, `build/qa/packaged_mission_regression.log` |
| Guard regression | 31 synthetic guard checks passed against the packaged PCK. This does not prove the route is playable. | `tests/guard_regression.gd`, `build/qa/packaged_guard_regression.log` |
| Expanded direct-west source route | Rendered 3D window, ordinary InputMap look/move/interact, real CharacterBody3D collision, live guards: reached contact, held E, lockdown subtitle/event appeared, guards 8→12, delivered packet at opposite shelter with zero kills. Audio cues are implemented but hardware output was not recorded in this run. | `build/qa/rendered_direct_west.log`, `build/qa/direct_west_pass/` |
| Covered route through that exact PCK | PASS. Rendered InputMap walking/look through the covered southern passage, upstairs contact and northern district. Contact held E; lockdown changed guards 8→12; one physical E tap at the shelter delivered the packet. Zero kills, 100 health, 565.37 m, 202.66 game seconds. The earlier 35-second timeout on a 120 m walk was a test-driver error, fixed with a distance-based limit and rerun against the same PCK. | `build/qa/covered_pck.log`, `build/qa/covered_pck_timeout.log`, [spawn](media/covered_spawn.png), [lockdown](media/covered_lockdown.png), [result](media/covered_delivery.png) |
| Combat | Rendered InputMap movement/fire: first shot hit, magazine 30→0, one guard died, dry fire held at zero, R reloaded to 30 in 1.933 seconds. | `tests/rendered_combat.gd`, `build/qa/rendered_combat.log`, `build/qa/combat/` |
| Failure and retry | Rendered walk into sentry fire ended in visible MISSION FAILED. Native CUA clicked Retry; fresh mission restored briefing, 100 health, 30 rounds, eight guards. | `tests/rendered_failure_retry.gd`, `build/qa/rendered_failure_retry.log`, `build/qa/07_failed.png`, `build/qa/08_retry_briefing.png` |
| Native controls | That `.app` opened its ORDERS / 1944 briefing from its outer launcher. CUA clicked Begin Mission and saw the street plus health/ammo HUD, pressed Esc and saw Mission Paused, then clicked Restart Mission and saw a fresh briefing. In a separate rendered source route, one native CUA E press at the shelter produced EXTRACTED. | Authored CUA window observations; `build/qa/rendered_native_extract.log` for the separate extraction press |

The rendered route scripts programmatically select waypoints and call the same InputMap actions available to a player. They never set player transforms, disable guards or bypass collision. They call `main.start_mission()` to enter gameplay, so they are **input-driven rendered playthroughs**, not claims of a human manually navigating the whole route. Native CUA checks cover visible menu/pause/retry and the final E press separately. The packaged PCK contains game content only; test scripts run externally and are not shipped.

The exact older PCK under test had SHA-256 `4e45aaeae9ad5e322de470dcde646ffc67fe4640c00c284c19639bc1edceabc2`. Its `BUILD_INFO.txt` recorded source commit `cc328875f5fc79e473e99f2d858a16bf18883d0b` and `dirty=true` because documentation/QA files were uncommitted when built; the gameplay and packaging inputs matched the commit. The bundled executable was run from `/private/tmp` with `--main-pack` and the absolute path of the external QA script, proving the test loaded that shipped PCK rather than checkout resources.

To run the same route driver against the current package on this Mac, run the following from a terminal with the display available. It writes screenshots to ignored `build/qa/`; the timing and result must be assessed for the current PCK separately:

```sh
PROJECT_ROOT="/Users/quan/Documents/ISK/Grade 10/personal project"
cd /private/tmp
QA_ROUTE=covered QA_OUTPUT_DIR="$PROJECT_ROOT/build/qa/covered_pck" \
  "$PROJECT_ROOT/build/1944 Town Mission.app/Contents/Resources/Godot.app/Contents/MacOS/Godot" \
  --main-pack "$PROJECT_ROOT/build/1944 Town Mission.app/Contents/Resources/Game.pck" \
  --script "$PROJECT_ROOT/tests/rendered_playthrough.gd"
```

For source-checkout synthetic and rendered runner commands, see [AGENTS.md](../AGENTS.md). The test driver uses distance-derived waypoint deadlines; it does not modify movement speed, health, guards or collision.

During the older packaged route, 198 one-second FPS samples after the first five game seconds ranged from 108 to 145 FPS (mean 130.41). Across 25,792 observed render-frame intervals, median was 7.672 ms and the 95th percentile was 9.691 ms. Four intervals exceeded 50 ms (55.8–121.4 ms); each occurred 2–3 ms after the test script saved a PNG, so screenshot capture is the likely cause. There were no one-second FPS samples below 30. The earlier source run's isolated 2 FPS sample did not recur; its cause is unconfirmed. The Godot static-memory monitor peaked at 102.16 MiB; this is **not** total process RSS. These measurements are from the older PCK at 1280 × 720 with no concurrent GUI run, after initial warmup; they do not profile the visual build.

The installed Godot app's original nested signature is invalid according to `codesign --verify`; the self-contained local wrapper is ad-hoc signed and opened on this Mac. It is not notarized for distribution to other machines. Generated `build/qa/` files are ignored by Git; selected screenshots are copied to `docs/media/` for the repository.
