# Repository Guidelines

## Project Structure & Module Organization

This is an early Godot 4.7 project. `project.godot` contains engine settings and `icon.svg` is the current asset. `docs/PLAN_INDEX.md` links the design documents; read `docs/GAME_VISION.md` for scope and `docs/DESIGN_REVIEW.md` for open decisions. `docs/GAME_ARCHITECTURE.md` and `docs/ENVIRONMENT_PIPELINE.md` describe proposals, not implemented code. No gameplay scenes, scripts, or tests exist yet. Add them under `scenes/`, `scripts/`, `assets/`, and `tests/` as implementation begins. Keep Godot's generated `.godot/` directory out of version control.

## Build, Test, and Development Commands

Open the directory in Godot 4.7, or run `godot --editor --path .` if the executable is on your `PATH`. Once a main scene exists, run `godot --path .` to play it. Use `godot --headless --path . --editor --quit` to check imports and editor errors. The Godot CLI is not currently on this machine's `PATH`. There is no build script or automated test command yet.

## Coding Style & Naming Conventions

Follow `.editorconfig`: UTF-8 text. For future GDScript, use Godot's standard tab indentation, `snake_case` for files, variables, and functions, and `PascalCase` for named classes and scene roots. Name scenes by purpose, such as `town_level.tscn` or `player.tscn`. Make small, reviewable edits to `project.godot`; prefer the editor for unfamiliar settings. Write all project-authored documentation in English, including revisions to older documents. Preserve original-language archival evidence. Keep confirmed decisions, proposals, and implemented behavior distinct. Production is now authorized. Astra owns direction and review; delegate execution, including asset research, to `gpt-6-sol` subagents with reasoning effort `high`.

## Testing Guidelines

No test framework or coverage target is configured. For each gameplay change, state the manual steps and observed result. When the mission loop exists, verify infiltration, intelligence pickup, reinforcement change, extraction, failure, and retry in an actual play session. A headless import check alone does not prove the game is playable. If automated tests are added, place them under `tests/` and document their runner here.

## Commit & Pull Request Guidelines

Use short, imperative commit subjects that describe one change, such as `Add player movement scene`. In pull requests, explain the behavior changed, cite the relevant design document or issue, list validation performed, and include screenshots or a short recording for visual or gameplay changes.

## Scope & Asset Provenance

Treat `docs/MILESTONES_AND_AGENTS.md` as a draft plan. Record user decisions before expanding the game's setting, visual direction, or milestone scope. For historical references and imported models, retain source, date, usage rights, and the original Blender file alongside any exported `.glb`.
