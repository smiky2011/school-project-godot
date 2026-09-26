# Design Document Index

Status: the first playable mission has a packaged visual-production increment with modeled town houses, textured Sten, clothed contact and scout, and an animated guard gait. The current package passed exact-PCK input-driven zero-kill extraction, combat, failure/retry and native menu checks; [QA_REPORT.md](QA_REPORT.md) records the package identity and performance caveat. First-time human navigation, listening, weapon feel and the intended ten-minute pace remain unverified. Design commitments below remain distinct from provisional implementation choices.

## Read in This Order

| Document | Owns |
| --- | --- |
| [GAME_VISION.md](GAME_VISION.md) | Core experience, confirmed scope and exclusions |
| [MISSION_STORY.md](MISSION_STORY.md) | Characters, both handoffs, exposure and NPC protection |
| [STEALTH_AND_GUARD_BEHAVIOR.md](STEALTH_AND_GUARD_BEHAVIOR.md) | Vision cones, detection, search and recovery |
| [GAME_ARCHITECTURE.md](GAME_ARCHITECTURE.md) | Combat, health, retry and implemented system boundaries |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Selected references and proposed visual interpretation |
| [DESIGN_REVIEW.md](DESIGN_REVIEW.md) | Audit findings and ownership of open decisions |
| [ENVIRONMENT_PIPELINE.md](ENVIRONMENT_PIPELINE.md) | Asset policy, imported materials, authored houses and remaining workflow limits |
| [MILESTONES_AND_AGENTS.md](MILESTONES_AND_AGENTS.md) | Confirmed delegation policy and proposed milestones |

## Implementation and Evidence

| Document | Owns |
| --- | --- |
| [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md) | Astra-reviewed interfaces, provisional tuning and staging choices |
| [LEVEL_LAYOUT.md](LEVEL_LAYOUT.md) | Current blockout geometry, routes and encounter locations |
| [PLAYING.md](PLAYING.md) | Controls and local run instructions |
| [PACKAGING.md](PACKAGING.md) | Self-contained macOS build procedure and its limits |
| [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) | Imported free assets and usage rights |
| [VISUAL_PRODUCTION.md](VISUAL_PRODUCTION.md) | Current town-art implementation, rendered frames and review limits |
| [ENVIRONMENT_ASSET_SCREENING.md](ENVIRONMENT_ASSET_SCREENING.md) | Authored houses, source materials and architecture previews |
| [WEAPON_CHARACTER_ASSETS.md](WEAPON_CHARACTER_ASSETS.md) | Sten and first-person grip-hand source and attribution |
| [CHARACTER_PRODUCTION.md](CHARACTER_PRODUCTION.md) | Contact, guard and scout visuals, editable sources and motion limits |
| [FIRST_PERSON_MOTION.md](FIRST_PERSON_MOTION.md) | Grounded player acceleration, viewmodel gait and overlapping Sten reflection tails |
| [RUNTIME_ENVIRONMENT.md](RUNTIME_ENVIRONMENT.md) | Target-machine runtime observations |
| [QA_REPORT.md](QA_REPORT.md) | Source and packaged playthrough evidence, performance and acceptance limits |
| [SHOOTER_BENCHMARKS.md](SHOOTER_BENCHMARKS.md) | AAA weapon and asset practice compared with this project |
| [CLAUDE_HANDOFF.md](CLAUDE_HANDOFF.md) | Claude Code session (26 Sep): weapon feel, visual style pass, validation and open items |
| [PLAYTEST_REPORT.md](PLAYTEST_REPORT.md) | Route observations and pacing interpretation |

`scenes/main.tscn` starts the mission. `scripts/core/main.gd` creates the level, player and director; the director owns mission phase and lockdown separately. Automated runners live in `tests/`. The preceding blockout's source direct-west route completed in 207.88 game seconds; its exact packaged PCK's covered route completed in 202.66 game seconds. The later visual PCK completed in 202.75 seconds. The current animated-guard PCK completed a corrected covered route in 204.225 game seconds, with zero kills, no sprint and a single-press final handoff. These used mapped movement and real collision; they are known automated routes, not measured first-time human play sessions or proof of the intended ten-minute pace. Current source commit, PCK hash, performance and acceptance limits are in [QA_REPORT.md](QA_REPORT.md).

## Team Configuration

Astra (`gpt-6-astra`) owns planning, architecture, coordination and acceptance. Delegate execution—including free-asset research, screening, downloads, setup, drawings, implementation, testing, documentation and packaging—to Sol (`gpt-6-sol`) subagents with reasoning effort `high`; explicitly set these values when dispatching. See [the working agreement](MILESTONES_AND_AGENTS.md) for ownership and fallback rules.

## Asset Strategy

Use suitable free online assets first, with license and import checks. The user explicitly authorized custom Blender work where free models could not produce the grounded, coherent 1944-town look. Godot assembles and tests the result. Two authored exterior house variants and their editable Blender source, a textured Sten and three clothed human visuals are now integrated; their acceptance boundaries are in the asset and QA records above. The level is still an art-in-progress mission environment.

## Latest Confirmed Constraints

The user confirmed a fictional European town in 1944, without locked factions; exact region and month remain open. Free assets only; notify the user about free resources requiring registration. No fixed deadline; deliver a locally playable game on the target Mac. Combat is optional: a no-kill completion must be viable without suppressing the scripted alarm.

## Rules

All project-authored documentation uses English; original archival evidence retains its source language. Conversation may remain Chinese.

The vision is the top-level constraint; specialist documents own details. Confirmed decisions override older proposals, but conflicts must be reported, not silently resolved by changing the design. New numbers, interfaces and staging ideas remain provisional until reviewed or tested. Major creative/scope changes return to the user; routine implementation belongs to the later team within its authorization.

Research, plans, assets and playable results are different evidence levels. The [reference guide](../reference/README.md) and [gallery](../reference/gallery.html) distinguish source types and access limits. G01-07 through G01-12 are the selected core images; do not restore user-removed images automatically.
