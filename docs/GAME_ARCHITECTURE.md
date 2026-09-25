# Gameplay Rules and Runtime Architecture

Status: game-design baseline with an implemented Godot architecture and a packaged first playable blockout. Confirmed rules here govern the current blockout; file interfaces and tuning are recorded in [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md). The expanded route has completed an input-driven rendered zero-kill run through the exact packaged PCK; first-time human navigation and pacing remain to be measured.

## Mission and System Boundaries

Use the confirmed loop in [GAME_VISION.md](GAME_VISION.md). [MISSION_STORY.md](MISSION_STORY.md) owns the different secret-contact and extraction handoff rules. [STEALTH_AND_GUARD_BEHAVIOR.md](STEALTH_AND_GUARD_BEHAVIOR.md) owns perception and local search.

Mission progress, local guard awareness and persistent lockdown are separate concepts. Completing the packet handoff updates the objective to extraction; returning personnel then discover intrusion and trigger lockdown. Receiving the packet does not clear prior awareness, and ending a local search does not lift lockdown.

The current director implements `INFILTRATE` → `INTEL_SECURED` → `EXTRACTED`, plus `FAILED`, and keeps `lockdown` separate. These implementation labels preserve the confirmed handoff/discovery distinction.

## Guards and Reinforcements

One ordinary guard archetype serves as moving patrol, fixed sentry or post-alarm reinforcement. No sniper, heavy or special-ability classes are included.

After the alarm, one finite contingent enters and controls selected intersections. Do not spawn continuously or indefinitely replace casualties. Clearing all enemies is unnecessary; combat can reduce local pressure. The contingent need not arrive simultaneously. Numbers, equipment, arrival timing and positions remain for later design and tuning.

Combat is not mandatory. Provide a viable evasion route to completion; do not gate progress on kills or cleared encounters. Alarm and reinforcement escalation still occur.

Extraction is **tense but forgiving**. Encounters should allow recoverable mistakes and opportunities to escape immediate danger, consistent with full-mission retries.

## Weapon and Close-Range Kills

- Primary weapon: submachine gun. Historical model and asset remain unselected.
- Firing consumes a finite magazine. An empty magazine requires a reload before firing again; reserve ammunition is unlimited.
- No ammunition scavenging, corpse looting for ammunition or supply pickups.
- Bypassing, shooting and close-range stealth kills are available during infiltration.
- Gunfire alerts nearby guards. Unwitnessed stealth kills do not attract guards like gunshots; witnessed attacks and discovered bodies still matter.
- No body carrying. Later patrols may discover a body, so killing a guard does not permanently make a route safe.

The current blockout offers an F prompt for a nearby clear-line rear takedown, R reload and brief shot/reload feedback. Distances, damage, timing and animation remain provisional tuning and presentation details.

## Health and Full Restart

Health regenerates automatically out of combat. The current provisional implementation waits seven seconds without damage and checks active guard threats, not the persistent lockdown flag, before restoring health. Exact timing and rate remain subject to playtesting; this implementation choice is not a separate user-confirmed rule.

There are no checkpoints. Death restarts the mission with initial player position, health and ammunition; enemies, bodies, awareness, NPC interactions, packet availability, alarm and reinforcements reset. Previous-run searches and delayed events must not continue. Regeneration cannot revive the dead player.

## Navigation and Feedback

Provide a short briefing, landmarks and a simple current-objective direction cue. The player chooses routes. The objective changes from the contact to extraction after packet delivery and resets on retry. The current HUD displays bearing, distance, elevation and interaction feedback; the visual presentation remains provisional. Towers and bridges are examples, not approved assets.

## Current Technical Responsibilities

| Module | Responsibility and file |
| --- | --- |
| `Main` | Startup, scene assembly, pause and result flow: `scripts/core/main.gd` |
| `TownLevel` | Environment, collision, routes and encounter locations: `scripts/world/town_level.gd` |
| `Player` | Movement, view, health, inputs and provisional SMG: `scripts/player/player.gd` |
| `Guard` | Perception, duty, search, combat and damage: `scripts/actors/guard.gd` |
| `MissionDirector` | Authoritative phase, handoff, alarm and completion: `scripts/core/mission_director.gd` |
| `HUD` | Read-only mission feedback and menus: `scripts/ui/hud.gd` |

The weapon behavior currently lives in `Player`; there is no separate `Weapon` node. [LEVEL_LAYOUT.md](LEVEL_LAYOUT.md) records the blockout's routes, landmarks and encounters. These module boundaries are implemented code, while future art and broader scope remain proposals.

## Acceptance Checks

- Recover from detection, satisfy secret-contact conditions and complete the packet handoff.
- Observe meaningful, finite post-handoff escalation while retaining player control.
- Reach the opposite-side shelter and finish despite remaining pursuers, including a run without killing enemies.
- Neither mission NPC dies, attracts enemies independently, or reveals player position.
- Reload is required when empty; reserves never run out. Health recovery behaves consistently with its eventual specification.
- Death before/after the alarm and consecutive retries produce clean, completable runs.

The expanded packaged route completed a rendered zero-kill extraction in 202.66 game seconds. Integration tests cover handoff interruption, alarm, combat-allowed extraction, death and repeated retry; rendered probes also covered magazine exhaustion, health recovery, failure and retry. This is input-driven route evidence, not a first-time human playthrough or proof of the intended ten-minute pace. See [QA_REPORT.md](QA_REPORT.md). A diagram, asset download or successful import alone is not playable evidence; see [DESIGN_REVIEW.md](DESIGN_REVIEW.md).
