# Repository Guidelines

## Project Structure & Module Organization

This is a Godot 4.7.2 project with a first playable, packaged mission with provisional visual art. `project.godot` points to `scenes/main.tscn`. `scripts/core/` owns startup and mission state, `scripts/player/` movement and combat, `scripts/world/` the town, `scripts/actors/` guards, and `scripts/ui/` the HUD. Required game assets live under `assets/`; `tests/` holds standalone Godot runners. `docs/PLAN_INDEX.md` links confirmed design, implementation decisions, and current evidence. Keep Godot's generated `.godot/`, local `reference/`, and `build/` out of version control.

## Build, Test, and Development Commands

On this Mac, Godot 4.7.2 is `/Users/quan/Downloads/Godot.app/Contents/MacOS/Godot`; it is not on `PATH`. Open the project in Godot or run that executable with `--path .` to play. Use `--headless --path . --editor --quit` for import checks. Run `bash tools/build_macos.sh` for a self-contained local app; see `docs/PACKAGING.md`. The build script creates `build/.gdignore` so editor scans skip package output.

## Coding Style & Naming Conventions

Follow `.editorconfig`: UTF-8 text. For GDScript, use Godot's standard tab indentation, `snake_case` for files, variables, and functions, and `PascalCase` for named classes and scene roots. Name scenes by purpose, such as `town_level.tscn` or `player.tscn`. Make small, reviewable edits to `project.godot`; prefer the editor for unfamiliar settings. Write all project-authored documentation in English, including revisions to older documents. Preserve original-language archival evidence. Keep confirmed decisions, proposals, and implemented behavior distinct. Production is authorized. Astra owns direction and review; delegate execution, including asset research, to `gpt-6-sol` subagents with reasoning effort `high`.

## Testing Guidelines

No external test framework or coverage target is configured. Run Godot with `--headless --path . --script res://tests/mission_regression.gd`, `guard_regression.gd` and `player_stance_regression.gd` for state, AI and stance integration checks. `tests/rendered_playthrough.gd`, `rendered_failure_retry.gd` and `rendered_combat.gd` are controlled gameplay probes; `rendered_visual_review.gd`, `character_visual_review.gd` and `rendered_guard_review.gd` inspect presentation. Run rendered scripts with `--path . --script res://tests/<file>.gd` and a graphics display. State manual steps and observed results for each gameplay change. The current visual package passed an input-driven zero-kill extraction through its exact PCK, not a human manually navigating the mission. Combat and failure/retry checks of the same PCK are still being completed; native briefing, Begin, Pause and Restart smoke passed; see `docs/QA_REPORT.md`. Headless tests alone do not prove playability.

## Commit & Pull Request Guidelines

During implementation, push commits to the active GitHub branch at meaningful completed increments so the user can inspect progress. Astra chooses the boundary, such as a finished function, coherent change, or feature, and delegates the Git operation. One agent stages, commits, and pushes shared-worktree changes at a time; stage only the reviewed files for that increment. Do not wait for a whole milestone or commit every tiny edit. Use short, imperative commit subjects that describe concrete work, such as `Add player movement scene`. Report actual validation and identify incomplete work; do not include secrets, generated caches, the local `reference/` directory, or another agent's unfinished edits. In pull requests, explain the behavior changed, cite the relevant design document or issue, list validation performed, and include screenshots or a short recording for visual or gameplay changes.

## Scope & Asset Provenance

Treat `docs/MILESTONES_AND_AGENTS.md` as a draft plan. Record user decisions before expanding the game's setting, visual direction, or milestone scope. For historical references and imported models, retain source, date, usage rights, and the original Blender file alongside any exported `.glb`.
