# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Repository rules (style, commits, documentation language, asset provenance, agent roles) live in AGENTS.md and apply here too:

@AGENTS.md

## Commands

Godot 4.7.2 is not on `PATH`; use the full path. All commands run from the repository root.

```sh
GODOT='/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot'
"$GODOT" --path .                                   # play
"$GODOT" --headless --path . --editor --quit          # import / parse check
"$GODOT" --headless --path . --script res://tests/mission_regression.gd
"$GODOT" --headless --path . --script res://tests/guard_regression.gd
QA_OUTPUT_DIR=/abs/writable/dir "$GODOT" --path . --script res://tests/rendered_playthrough.gd
bash tools/build_macos.sh                            # -> build/1944 Town Mission.app
```

- Each test file is a standalone `extends SceneTree` runner; run one at a time. They exit with `quit(0)` on pass and `quit(1)` on failure.
- Headless state checks: `mission_regression`, `guard_regression`, `player_stance_regression`. Rendered gameplay probes (need a display, no `--headless`): `rendered_playthrough`, `rendered_failure_retry`, `rendered_combat`. Rendered presentation reviews: `rendered_visual_review`, `character_visual_review`, `rendered_guard_review`. Rendered runners write screenshots to `QA_OUTPUT_DIR` (an absolute writable directory); some fail without it.
- There is no linter or external test framework.
- `build_macos.sh` exports from a staging mirror of `scenes/`, `scripts/` and `assets/` that keeps only runtime file types. It skips `source/`, `previews/` and any folder containing `.gdignore`, so Blender work files and raw downloads stay out of the package.

## Architecture

The game structure is built in code; imported art arrives only through the presentation layer described below. `scenes/main.tscn` is a single `Node3D` with `scripts/core/main.gd`; there are no other authored scenes. `main.gd` instantiates the level, player, mission director, and HUD with `Script.new()`, wires them together through `setup(...)` calls, and registers every input action at runtime in `_register_inputs()`. `project.godot` has no `[input]` section, so add new actions there in code.

- **`scripts/core/mission_director.gd`** is the central state machine and hub. `phase` is a string: `INFILTRATE` → `INTEL_SECURED` (after the held-E contact handoff) → `EXTRACTED`, or `FAILED`. `lockdown` is a separate flag for the scripted alarm and reinforcements. Guards call into it (`report_noise`, `report_detection`, `guard_killed`), the player calls it (`player_died`, `try_stealth_kill`), and the HUD polls its fields (`interaction_text`, `subtitle_text`, `handoff_progress`, `get_local_awareness()`). It emits `mission_finished` and `story_cue`, which `main.gd` handles.
- **`scripts/world/town_level.gd`** procedurally builds the town from boxes/materials, owns the guard list, spawn/contact/extraction positions, `spawn_reinforcements()`, and a coarse grid pathfinder (`get_ground_path`) that guards use in place of NavigationServer. Geometry that should block guard paths must be created with `_box(..., navigation_blocker = true)`. `docs/LEVEL_LAYOUT.md` describes the intended geometry.
- **`scripts/actors/guard.gd`** is a `CharacterBody3D` with string states (`PATROL`, `SUSPICIOUS`, `SEARCH`, `COMBAT`, `DEAD`), vision-cone detection with suspicion build-up, noise hearing, body discovery, and witness notification. Tunables are constants at the top of the file.
- **`scripts/player/player.gd`** is a first-person `CharacterBody3D` with movement, crouch, and hitscan firing. Weapon numbers (recoil pattern, spread, reloads, damage) come from `scripts/player/weapon_profile.gd`; world effects are in `scripts/fx/`, synthesized sounds in `scripts/audio/sound_synth.gd`.
- **`scripts/ui/hud.gd`** builds all UI controls in code: briefing, gameplay HUD, pause, and result menus. It calls back into `main.gd` (`start_mission`, `resume_mission`, `retry_mission`, `quit_game`).

Gameplay and visuals are split. Collision, pathfinding and rules stay in the scripts above. Art is attached by visual-only presentation scripts: `scripts/world/town_presentation.gd` and `service_wing_visual.gd` place modeled house GLBs and textures over `town_level.gd`'s collision boxes; `scripts/player/weapon_presentation.gd` is the Sten viewmodel with gloved hands; `scripts/characters/` holds the guard body and weapon models. Colliding props must register their footprints with the level's pathfinding grid before it is built. Changing a visual must not change collision or navigation, and gameplay changes belong in the core scripts. Imported art lives under `assets/` (Blender-authored houses in `assets/environment/`, downloaded packs in `assets/vendor/`), with provenance in `docs/ASSET_PROVENANCE.md`.

The town's look is layered on top of that: `town_atmosphere.gd` (sky, sun, post-processing), `facade_variation.gd` (per-house materials and roof details), `town_ground.gdshader` (blended ground), `town_dressing.gd` (props, rubble, vegetation, ruins) and `town_backdrop.gd` (hedgerow, fields, horizon). Dressing is seeded and must call `_solid_box()` for anything solid so guard pathing sees it; `KEEP_CLEAR` protects areas the tests use. Render `tools/art/render_style_review.gd` to compare with `reference/games/G01-*`. Session history and open items: `docs/CLAUDE_HANDOFF.md`.

Cross-script references are mostly untyped (duck-typed `var director`, `var level`), so renaming a method or field requires a grep across `scripts/` and `tests/`. The regression tests read director and guard fields directly (`director.phase`, `guard.state`, `guard.suspicion`, and so on).

Pausing uses `get_tree().paused`. Gameplay nodes are `PROCESS_MODE_PAUSABLE`, and `main` plus the HUD are `PROCESS_MODE_ALWAYS`. Retry reloads the whole scene.

## Design Documents

Start with `docs/PLAN_INDEX.md`. It maps each design area to its owning document and separates confirmed decisions from provisional implementation choices (`docs/IMPLEMENTATION_DECISIONS.md`). Current evidence and known limits are in `docs/QA_REPORT.md` and `docs/PLAYTEST_REPORT.md`. Core constraint: combat is optional and a zero-kill completion must stay viable without suppressing the scripted alarm.
