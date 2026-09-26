# First-person motion and Sten report tails

Status: implemented in the source checkout on 26 September 2026. The movement change is in commit `01cb757`; the audio change is awaiting its separate commit. These are presentation and locomotion refinements, with final feel and sound acceptance still requiring a human play session. Mission rules and weapon damage, spread, recoil, ammunition and reload timing are unchanged.

## Ground movement and weapon gait

Horizontal velocity now approaches the existing input target at 22 m/s², brakes at 26 m/s², and reverses at 38 m/s². Walk, sprint and crouch still top out at 3.2, 5.2 and 1.45 m/s; aiming still applies the Sten's 0.62 movement multiplier. Entering a slower stance clamps velocity to its new cap immediately. Vertical jump, gravity and collision continue through `CharacterBody3D.move_and_slide()`.

The player passes post-slide horizontal distance to the viewmodel only while grounded. The gun advances half a gait cycle per footstep stride (1.25 m walking, 1.55 m sprinting, 0.95 m crouching), using the same distance measure as the footstep cue. Its bob fades in and out; held movement against a wall or movement in the air does not advance the cycle. This changes the weapon presentation, not the camera aim or view. Footstep distance now retains the remainder after a cue so cadence does not drift from discarded travel.

`tests/player_motion_regression.gd` passed 11 headless checks in a real collision fixture: floor settlement, acceleration, walk cap, stopping distance under 0.4 m, prompt reversal, sprint cap, immediate lower cap when leaving sprint, crouch and ADS caps, no blocked gait and no airborne gait. The existing stance regression passed 9 checks, and mission regression passed 40 checks before a concurrent guard-model import change temporarily made the shared checkout's mission test unloadable. A rendered route on the completed shared tree and a human feel check remain open.

## Automatic-fire reflection tails

The Sten's direct report already has four players, but its environmental response previously used one `AudioStreamPlayer`. Calling `play()` on every automatic shot restarted that player about every 0.105 seconds. The open-air tail lasts 1.5 seconds and its wall slap begins at 0.23 seconds, so a sustained burst cut it off before the slap. The player now preallocates 16 tail voices and selects them round robin. At the Sten's fire interval, a voice is reused after about 1.68 seconds, beyond even the slowest pitched open-air tail. Space classification, stream selection, pitch variation and the existing open/street/interior gains remain the same. The pool is fixed in size.

`tests/weapon_audio_regression.gd` passed 11 headless checks. During four successive shots, the first open-air tail was still playing at 0.284 seconds and four tails overlapped. A sampled offline sum of 20 reports and tails at the real firing interval peaked at 0.464 (open), 0.400 (street) and 0.414 (interior), below full scale before the audio bus. This verifies playback continuity and a sampled mix level, not speaker output or perceived realism. Rendered gameplay and a listening check remain open.
