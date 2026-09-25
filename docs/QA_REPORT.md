# QA Report

Status: packaged route and native-window acceptance passed. Tested on 25 September 2026 on the target MacBook Pro M4 Pro (24 GB), macOS 26.6.2, Godot 4.7.2, Metal Forward+, 1280 × 720.

## Evidence and scope

| Check | Method and observed result | Evidence |
| --- | --- | --- |
| Import and source parsing | Godot headless editor import and script checks exited successfully. | `build/qa/headless_import.log` |
| Mission state regression | 40 synthetic checks exercise interaction, alarm, reinforcement, extraction and retry logic; all passed against the packaged PCK. This does not exercise walking or rendering. | `tests/mission_regression.gd`, `build/qa/packaged_mission_regression.log` |
| Guard regression | 31 synthetic guard checks passed against the packaged PCK. This does not prove the route is playable. | `tests/guard_regression.gd`, `build/qa/packaged_guard_regression.log` |
| Expanded direct-west source route | Rendered 3D window, ordinary InputMap look/move/interact, real CharacterBody3D collision, live guards: reached contact, held E, lockdown subtitle/event appeared, guards 8→12, delivered packet at opposite shelter with zero kills. Audio cues are implemented but hardware output was not recorded in this run. | `build/qa/rendered_direct_west.log`, `build/qa/direct_west_pass/` |
| Covered route through exact final PCK | PASS. Rendered InputMap walking/look through the covered southern passage, upstairs contact and northern district. Contact held E; lockdown changed guards 8→12; one physical E tap at the shelter delivered the packet. Zero kills, 100 health, 565.37 m, 202.66 game seconds. The earlier 35-second timeout on a 120 m walk was a test-driver error, fixed with a distance-based limit and rerun against the same PCK. | `build/qa/covered_pck.log`, `build/qa/covered_pck_timeout.log`, [spawn](media/covered_spawn.png), [lockdown](media/covered_lockdown.png), [result](media/covered_delivery.png) |
| Combat | Rendered InputMap movement/fire: first shot hit, magazine 30→0, one guard died, dry fire held at zero, R reloaded to 30 in 1.933 seconds. | `tests/rendered_combat.gd`, `build/qa/rendered_combat.log`, `build/qa/combat/` |
| Failure and retry | Rendered walk into sentry fire ended in visible MISSION FAILED. Native CUA clicked Retry; fresh mission restored briefing, 100 health, 30 rounds, eight guards. | `tests/rendered_failure_retry.gd`, `build/qa/rendered_failure_retry.log`, `build/qa/07_failed.png`, `build/qa/08_retry_briefing.png` |
| Native controls | The final `.app` opened its ORDERS / 1944 briefing from its outer launcher. CUA clicked Begin Mission and saw the street plus health/ammo HUD, pressed Esc and saw Mission Paused, then clicked Restart Mission and saw a fresh briefing. The window remains there for the user. In a separate rendered source route, one native CUA E press at the shelter produced EXTRACTED. | Authored CUA window observations; `build/qa/rendered_native_extract.log` for the separate extraction press |

The rendered route scripts programmatically select waypoints and call the same InputMap actions available to a player. They never set player transforms, disable guards or bypass collision. They call `main.start_mission()` to enter gameplay, so they are **input-driven rendered playthroughs**, not claims of a human manually navigating the whole route. Native CUA checks cover visible menu/pause/retry and the final E press separately. The packaged PCK contains game content only; test scripts run externally and are not shipped.

The exact package under test is `build/1944 Town Mission.app`; its `Game.pck` SHA-256 is `4e45aaeae9ad5e322de470dcde646ffc67fe4640c00c284c19639bc1edceabc2`. `BUILD_INFO.txt` records source commit `cc328875f5fc79e473e99f2d858a16bf18883d0b` and `dirty=true` because documentation/QA files were uncommitted when built; the gameplay and packaging inputs matched the commit. The bundled executable was run from `/private/tmp` with `--main-pack` and the absolute path of the external QA script, proving the test loaded the shipped PCK rather than checkout resources.

To repeat the full rendered packaged route on this Mac, run the following from a terminal with the display available. It takes about 3½ minutes and writes screenshots to the ignored `build/qa/` directory:

```sh
PROJECT_ROOT="/Users/quan/Documents/ISK/Grade 10/personal project"
cd /private/tmp
QA_ROUTE=covered QA_OUTPUT_DIR="$PROJECT_ROOT/build/qa/covered_pck" \
  "$PROJECT_ROOT/build/1944 Town Mission.app/Contents/Resources/Godot.app/Contents/MacOS/Godot" \
  --main-pack "$PROJECT_ROOT/build/1944 Town Mission.app/Contents/Resources/Game.pck" \
  --script "$PROJECT_ROOT/tests/rendered_playthrough.gd"
```

For source-checkout synthetic and rendered runner commands, see [AGENTS.md](../AGENTS.md). The test driver uses distance-derived waypoint deadlines; it does not modify movement speed, health, guards or collision.

During the packaged route, 198 one-second FPS samples after the first five game seconds ranged from 108 to 145 FPS (mean 130.41). Across 25,792 observed render-frame intervals, median was 7.672 ms and the 95th percentile was 9.691 ms. Four intervals exceeded 50 ms (55.8–121.4 ms); each occurred 2–3 ms after the test script saved a PNG, so screenshot capture is the likely cause. There were no one-second FPS samples below 30. The earlier source run's isolated 2 FPS sample did not recur; its cause is unconfirmed. The Godot static-memory monitor peaked at 102.16 MiB; this is **not** total process RSS. These measurements are from one 1280 × 720 rendered route with no concurrent GUI run, after initial warmup, and do not replace broader hardware profiling.

The installed Godot app's original nested signature is invalid according to `codesign --verify`; the self-contained local wrapper is ad-hoc signed and opened on this Mac. It is not notarized for distribution to other machines. Generated `build/qa/` files are ignored by Git; selected screenshots are copied to `docs/media/` for the repository.
