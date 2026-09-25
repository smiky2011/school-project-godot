# Design Document Index

Status: first-version game-design baseline, reviewed 25 September 2026. Technical architecture is still proposed. The user has authorized the Astra-led team to begin production; this is not a claim that implementation has started.

## Read in This Order

| Document | Owns |
| --- | --- |
| [GAME_VISION.md](GAME_VISION.md) | Core experience, confirmed scope and exclusions |
| [MISSION_STORY.md](MISSION_STORY.md) | Characters, both handoffs, exposure and NPC protection |
| [STEALTH_AND_GUARD_BEHAVIOR.md](STEALTH_AND_GUARD_BEHAVIOR.md) | Vision cones, detection, search and recovery |
| [GAME_ARCHITECTURE.md](GAME_ARCHITECTURE.md) | Combat, health, retry and proposed system boundaries |
| [ART_DIRECTION.md](ART_DIRECTION.md) | Selected references and proposed visual interpretation |
| [DESIGN_REVIEW.md](DESIGN_REVIEW.md) | Audit findings and ownership of open decisions |
| [ENVIRONMENT_PIPELINE.md](ENVIRONMENT_PIPELINE.md) | Asset-first production proposal |
| [MILESTONES_AND_AGENTS.md](MILESTONES_AND_AGENTS.md) | Confirmed delegation policy and proposed milestones |

## Team Configuration

Astra (`gpt-6-astra`) owns planning, architecture, coordination and acceptance. Delegate execution—including free-asset research, screening, downloads, setup, drawings, implementation, testing, documentation and packaging—to Sol (`gpt-6-sol`) subagents with reasoning effort `high`; explicitly set these values when dispatching. See [the working agreement](MILESTONES_AND_AGENTS.md) for ownership and fallback rules.

## Asset Strategy

Use existing online assets first. Search, license-check and validate suitable assets before proposing custom modeling. Godot handles assembly; Blender/MCP are optional tools for necessary adaptations. See [ENVIRONMENT_PIPELINE.md](ENVIRONMENT_PIPELINE.md).

## Latest Confirmed Constraints

Year: 1944; exact region/factions remain open. Free assets only; notify the user about free resources requiring registration. No fixed deadline; deliver a locally playable game on the target Mac. Combat is optional: a no-kill completion must be viable without suppressing the scripted alarm.

## Rules

All project-authored documentation uses English; original archival evidence retains its source language. Conversation may remain Chinese.

The vision is the top-level constraint; specialist documents own details. Confirmed decisions override older proposals, but conflicts must be reported, not silently resolved by changing the design. New numbers, interfaces and staging ideas remain provisional until reviewed or tested. Major creative/scope changes return to the user; routine implementation belongs to the later team within its authorization.

Research, plans, assets and playable results are different evidence levels. The [reference guide](../reference/README.md) and [gallery](../reference/gallery.html) distinguish source types and access limits. G01-07 through G01-12 are the selected core images; do not restore user-removed images automatically.
