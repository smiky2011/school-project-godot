# Design Document Index

Status: the first playable mission has an implemented architecture and a new packaged presentation increment: modeled houses, clothed characters, animated guard and player shadow, selected StG 44 viewmodel, and revised impact feedback. The clean `be1ca7d` package is 624 MB with `Game.pck` SHA-256 `5895e9a8ac09ed1a28518deafd729ccf3c5ce62e9f6d87e6fc24528c1a9a110a`; exact-PCK core, input-driven zero-kill route, combat, failure/retry and native outer-app menu checks passed. The preceding animated-guard package also passed input-driven checks; see [QA_REPORT.md](QA_REPORT.md). The user reported good feel and sound in that earlier build. A documented first-time human full-mission clear and intended ten-minute pace remain unverified. Design commitments below remain distinct from provisional implementation choices.

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
| [WEAPON_CHARACTER_ASSETS.md](WEAPON_CHARACTER_ASSETS.md) | Selected StG 44 viewmodel/source/attribution, grip hands and historical Sten |
| [CHARACTER_PRODUCTION.md](CHARACTER_PRODUCTION.md) | Contact, guard and scout visuals, editable sources and motion limits |
| [PLAYER_BODY_PRESENTATION.md](PLAYER_BODY_PRESENTATION.md) | Player world-body shadow, gait/crouch evidence and upper-body limitations |
| [FIRST_PERSON_MOTION.md](FIRST_PERSON_MOTION.md) | Grounded player acceleration, viewmodel gait and overlapping weapon reflection tails |
| [RUNTIME_ENVIRONMENT.md](RUNTIME_ENVIRONMENT.md) | Target-machine runtime observations |
| [QA_REPORT.md](QA_REPORT.md) | Source and packaged playthrough evidence, performance and acceptance limits |
| [SHOOTER_BENCHMARKS.md](SHOOTER_BENCHMARKS.md) | AAA weapon and asset practice compared with this project |
| [CLAUDE_HANDOFF.md](CLAUDE_HANDOFF.md) | Claude Code session (26 Sep): weapon feel, visual style pass, validation and open items |
| [PLAYTEST_REPORT.md](PLAYTEST_REPORT.md) | Route observations and pacing interpretation |

`scenes/main.tscn` starts the mission. `scripts/core/main.gd` creates the level, player, player-body presentation and director; the director owns mission phase and lockdown separately. Automated runners live in `tests/`. The current `be1ca7d` PCK completed a known input-driven zero-kill covered route in 204.233 game seconds, after 568.367 m, with no sprint and 100 health. Earlier PCKs took 202.66 seconds for the blockout, 202.75 for the later visual build and 204.225 for the animated-guard build's corrected route. These used mapped movement and real collision; none is a first-time human play session or proof of ten-minute pacing. See [QA_REPORT.md](QA_REPORT.md) for exact package identities and acceptance limits.

## Current architecture and quality boundary

| State | Area | Evidence or remaining work |
| --- | --- | --- |
| Implemented; current PCK route and retry verified | Single mission state, contact handoff, lockdown, finite guards, zero-kill extraction and full retry | Current exact-PCK core regressions, rendered route, CUA-operated failure/retry and native outer-app menu checks passed. [QA_REPORT.md](QA_REPORT.md) separates automated inputs from human play. |
| Implemented in current source/package | Player stance and movement, StG 44 first-person model and magazine/bolt presentation, guard AI, layered shot tails and skinned guard gait | Focused source Metal reviews and current exact-PCK combat passed; the 30-round, hitscan combat values remain provisional. [WEAPON_CHARACTER_ASSETS.md](WEAPON_CHARACTER_ASSETS.md) gives source and review evidence. |
| Implemented in current source/package | Shadow-only player world body and world StG mount; travelling cosmetic tracer and revised wall impact placement | Focused rendered/geometry checks, packaged visual-resource and near-wall probes, and exact-PCK combat integration passed; see [PLAYER_BODY_PRESENTATION.md](PLAYER_BODY_PRESENTATION.md) and [QA_REPORT.md](QA_REPORT.md). Human perception of the effects during ordinary play remains open. |
| Open quality acceptance | Documented first-time full-mission human clear, intended ten-minute human pace, school-PC performance and final art | Upper-body ADS/reload and large pitch motion are not yet reflected in the player shadow. P5 quality acceptance remains open in [MILESTONES_AND_AGENTS.md](MILESTONES_AND_AGENTS.md). |
| Confirmed user decision | Weapon identity and silhouette | After reviewing candidates, the user selected the period StG 44; it is integrated for the player and recorded in [GAME_VISION.md](GAME_VISION.md). Guards retain Sten visuals. |

## Team Configuration

Astra (`gpt-6-astra`) owns planning, architecture, coordination and acceptance. Delegate execution—including free-asset research, screening, downloads, setup, drawings, implementation, testing, documentation and packaging—to Sol (`gpt-6-sol`) subagents with reasoning effort `high`; explicitly set these values when dispatching. See [the working agreement](MILESTONES_AND_AGENTS.md) for ownership and fallback rules.

## Asset Strategy

Use suitable free online assets first, with license and import checks. The user explicitly authorized custom Blender work where free models could not produce the grounded, coherent 1944-town look. Godot assembles and tests the result. Two authored exterior house variants, the attributed player StG 44 and guard Sten, clothed mission/guard characters and a shadow-only player body have editable sources and rights records. Their acceptance boundaries are in the asset and QA records above. The level remains an art-in-progress mission environment.

## Latest Confirmed Constraints

The user confirmed a fictional European town in 1944, without locked factions; exact region and month remain open. Free assets only; notify the user about free resources requiring registration. No fixed deadline; deliver a locally playable game on the target Mac. Combat is optional: a no-kill completion must be viable without suppressing the scripted alarm.

## Rules

All project-authored documentation uses English; original archival evidence retains its source language. Conversation may remain Chinese.

The vision is the top-level constraint; specialist documents own details. Confirmed decisions override older proposals, but conflicts must be reported, not silently resolved by changing the design. New numbers, interfaces and staging ideas remain provisional until reviewed or tested. Major creative/scope changes return to the user; routine implementation belongs to the later team within its authorization.

Research, plans, assets and playable results are different evidence levels. The [reference guide](../reference/README.md) and [gallery](../reference/gallery.html) distinguish source types and access limits. G01-07 through G01-12 are the selected core images; do not restore user-removed images automatically.
