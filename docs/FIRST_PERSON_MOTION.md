# First-person motion and Sten report tails

Status: implemented and included in the current packaged PCK on 26 September 2026. The movement change is in commit `01cb757`; the audio change is in `9241ba7`. These are presentation and locomotion refinements, with final feel and sound acceptance still requiring a human play session. Mission rules and weapon damage, spread, recoil, ammunition and reload timing are unchanged.

## Ground movement and weapon gait

Horizontal velocity now approaches the existing input target at 22 m/s², brakes at 26 m/s², and reverses at 38 m/s². Walk, sprint and crouch still top out at 3.2, 5.2 and 1.45 m/s; aiming still applies the Sten's 0.62 movement multiplier. Entering a slower stance clamps velocity to its new cap immediately. Vertical jump, gravity and collision continue through `CharacterBody3D.move_and_slide()`.

The player passes post-slide horizontal distance to the viewmodel only while grounded. The gun advances half a gait cycle per footstep stride (1.25 m walking, 1.55 m sprinting, 0.95 m crouching), using the same distance measure as the footstep cue. Its bob fades in and out; held movement against a wall or movement in the air does not advance the cycle. This changes the weapon presentation, not the camera aim or view. Footstep distance now retains the remainder after a cue so cadence does not drift from discarded travel.

`tests/player_motion_regression.gd` passed 11 checks in a real collision fixture on both headless and rendered Metal runs: floor settlement, acceleration, walk cap, stopping distance under 0.4 m, prompt reversal, sprint cap, immediate lower cap when leaving sprint, crouch and ADS caps, no blocked gait and no airborne gait. The exact current PCK also passed motion (11), stance (9) and mission (40) checks using its bundled runtime. Its covered input-driven route completed with zero kills; details and performance caveats are in [QA_REPORT.md](QA_REPORT.md). A human feel check remains open.

## Automatic-fire reflection tails

The Sten's direct report already has four players, but its environmental response previously used one `AudioStreamPlayer`. Calling `play()` on every automatic shot restarted that player about every 0.105 seconds. The open-air tail lasts 1.5 seconds and its wall slap begins at 0.23 seconds, so a sustained burst cut it off before the slap. The player now preallocates 16 tail voices and selects them round robin. At the Sten's fire interval, a voice is reused after about 1.68 seconds, beyond even the slowest pitched open-air tail. Space classification, stream selection, pitch variation and the existing open/street/interior gains remain the same. The pool is fixed in size.

`tests/weapon_audio_regression.gd` passed 11 checks on headless and rendered Metal runs, and 11 with the bundled runtime and exact current PCK. In the rendered Metal test, the first open-air tail was still playing at 0.352 seconds while six tails overlapped. A deterministic sampled sum of 20 Sten reports and tails at the real firing interval peaked at 0.464 (open), 0.400 (street) and 0.414 (interior), below full scale before the audio bus. This verifies playback continuity and one sampled mix, not every random pitch/variant combination, speaker output or perceived realism. A human listening check remains open.
