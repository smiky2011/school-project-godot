# Design Document Index

Status: first-version design baseline with a locally packaged first playable Godot blockout. The expanded mission has passed an input-driven rendered zero-kill route through the exact packaged PCK; full manual human navigation and the intended ten-minute pace remain unverified. Design commitments below remain distinct from provisional implementation choices.

## Read in This Order

| Document | Owns |
| --- | --- |
| [GAME_VISION.md](GAME_VISION.md) | Core experience, confirmed scope and exclusions |
| [MISSION_STORY.md](MISSION_STORY.md) | Characters, both handoffs, exposure and NPC protection |
| [STEALTH_AND_GUARD_BEHAVIOR.md](STEALTH_AND_GUARD_BEHAVIOR.md) | Vision cones, detection, search and recovery |
| [GAME_ARCHITECTURE.md](GAME_ARCHITECTURE.md) | Combat, health, retry and implemented system boundaries |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Selected references and proposed visual interpretation |
| [DESIGN_REVIEW.md](DESIGN_REVIEW.md) | Audit findings and ownership of open decisions |
| [ENVIRONMENT_PIPELINE.md](ENVIRONMENT_PIPELINE.md) | Asset-first policy, sample imports and pending production workflow |
| [MILESTONES_AND_AGENTS.md](MILESTONES_AND_AGENTS.md) | Confirmed delegation policy and proposed milestones |

## Implementation and Evidence

| Document | Owns |
| --- | --- |
| [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md) | Astra-reviewed interfaces, provisional tuning and staging choices |
| [LEVEL_LAYOUT.md](LEVEL_LAYOUT.md) | Current blockout geometry, routes and encounter locations |
| [PLAYING.md](PLAYING.md) | Controls and local run instructions |
| [PACKAGING.md](PACKAGING.md) | Self-contained macOS build procedure and its limits |
| [ASSET_PROVENANCE.md](ASSET_PROVENANCE.md) | Imported free assets and usage rights |
| [RUNTIME_ENVIRONMENT.md](RUNTIME_ENVIRONMENT.md) | Target-machine runtime observations |
| [QA_REPORT.md](QA_REPORT.md) | Source and packaged playthrough evidence, performance and acceptance limits |
| [PLAYTEST_REPORT.md](PLAYTEST_REPORT.md) | Route observations and pacing interpretation |

`scenes/main.tscn` now starts the mission. `scripts/core/main.gd` creates the level, player and director; the director owns mission phase and lockdown separately. Automated runners live in `tests/`. The expanded source direct-west route completed in 207.88 game seconds; the exact packaged PCK's covered route completed in 202.66 game seconds, with zero kills and a single-press final handoff. Both were input-driven rendered playthroughs through normal movement and collisions. These times describe known automated routes, not a measured first-time human play session or proof of the intended ten-minute pace. See [QA_REPORT.md](QA_REPORT.md).

## Team Configuration

Astra (`gpt-6-astra`) owns planning, architecture, coordination and acceptance. Delegate execution—including free-asset research, screening, downloads, setup, drawings, implementation, testing, documentation and packaging—to Sol (`gpt-6-sol`) subagents with reasoning effort `high`; explicitly set these values when dispatching. See [the working agreement](MILESTONES_AND_AGENTS.md) for ownership and fallback rules.

## Asset Strategy

Use existing online assets first. Search, license-check and validate suitable assets before proposing custom modeling. Godot handles assembly; Blender/MCP are optional tools for necessary adaptations. See [ENVIRONMENT_PIPELINE.md](ENVIRONMENT_PIPELINE.md).

## Latest Confirmed Constraints

The user confirmed a fictional European town in 1944, without locked factions; exact region and month remain open. Free assets only; notify the user about free resources requiring registration. No fixed deadline; deliver a locally playable game on the target Mac. Combat is optional: a no-kill completion must be viable without suppressing the scripted alarm.

## Rules

All project-authored documentation uses English; original archival evidence retains its source language. Conversation may remain Chinese.

The vision is the top-level constraint; specialist documents own details. Confirmed decisions override older proposals, but conflicts must be reported, not silently resolved by changing the design. New numbers, interfaces and staging ideas remain provisional until reviewed or tested. Major creative/scope changes return to the user; routine implementation belongs to the later team within its authorization.

Research, plans, assets and playable results are different evidence levels. The [reference guide](../reference/README.md) and [gallery](../reference/gallery.html) distinguish source types and access limits. G01-07 through G01-12 are the selected core images; do not restore user-removed images automatically.
