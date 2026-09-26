# Gameplay Rules and Runtime Architecture

Status: game-design baseline with an implemented Godot mission architecture and a packaged presentation update. The clean `be1ca7d` build contains the selected StG 44 viewmodel, an animated player-body shadow and revised combat effects (`Game.pck` SHA-256 `5895e9a8ac09ed1a28518deafd729ccf3c5ce62e9f6d87e6fc24528c1a9a110a`, 624 MB app). Exact-PCK core, input-driven zero-kill route, combat, failure/retry and native outer-app menu checks passed. Confirmed rules govern the mission; file interfaces and provisional tuning are in [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md). First-time human full-mission navigation and pacing remain to be measured.

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

- Primary weapon direction: the user selected the 1944 StG 44 silhouette after reviewing candidates. The attributed model is now the player's first-person and world-shadow weapon; guards retain their Sten visual. Weapon origin does not determine the player's faction; the fictional town's factions remain open. See [WEAPON_CHARACTER_ASSETS.md](WEAPON_CHARACTER_ASSETS.md).
- The 30-round magazine, unlimited reserve, damage, firing interval and accepted handling/reload feel remain provisional values from the previous implementation. Firing resolves damage with an immediate raycast; the visible travelling tracer is cosmetic, not a simulated projectile with flight time or drop. Rifle-specific ballistic and audio decisions remain open.
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
| `Player` | Movement, view, health and inputs: `scripts/player/player.gd`; StG 44 viewmodel: `scripts/player/weapon_presentation.gd`; world-space body and weapon shadow: `scripts/player/player_body_presentation.gd` |
| `Guard` | Perception, duty, search, combat and damage: `scripts/actors/guard.gd`; velocity-driven fieldwear and held Sten visuals: `scripts/characters/` |
| `CombatFx` | Cosmetic travelling tracers, surface impacts and decals: `scripts/fx/combat_fx.gd`; authored townhouse facade projection: `scripts/world/townhouse_impact_geometry.gd` |
| `MissionDirector` | Authoritative phase, handoff, alarm and completion: `scripts/core/mission_director.gd` |
| `HUD` | Read-only mission feedback and menus: `scripts/ui/hud.gd` |

Weapon firing and hit resolution live in `Player`; model, grip hands and cosmetic effects live in presentation nodes. Guards use an in-place skinned walk and idle on a MakeHuman-derived rig, driven by actual horizontal speed; see [CHARACTER_PRODUCTION.md](CHARACTER_PRODUCTION.md). The player now has a shadow-only, rigged world body with movement-direction and crouch poses, and its world StG 44 follows a hand bone. Camera-bound hands, sleeves and rifle do not cast a second detached shadow. Upper-body aim/reload and large camera-pitch matching remain open; see [PLAYER_BODY_PRESENTATION.md](PLAYER_BODY_PRESENTATION.md). The townhouse impact receiver projects cosmetic marks from coarse collision to visible masonry while avoiding openings; it does not change collision, hit damage or guard decisions. [LEVEL_LAYOUT.md](LEVEL_LAYOUT.md) records the blockout's routes, landmarks and encounters.

## Acceptance Checks

- Recover from detection, satisfy secret-contact conditions and complete the packet handoff.
- Observe meaningful, finite post-handoff escalation while retaining player control.
- Reach the opposite-side shelter and finish despite remaining pursuers, including a run without killing enemies.
- Neither mission NPC dies, attracts enemies independently, or reveals player position.
- Reload is required when empty; reserves never run out. Health recovery behaves consistently with its eventual specification.
- Death before/after the alarm and consecutive retries produce clean, completable runs.

The current `be1ca7d` PCK completed a covered input-driven zero-kill extraction in 204.233 game seconds, 568.37 m of travel, no sprint and 100 health; a separate exact-PCK combat probe passed aimed hits, magazine exhaustion, dry fire and R reload. A live-sentry failure followed by CUA-operated Retry restored a fresh briefing, 100 health, 30 rounds and eight guards. The native release app displayed the briefing, game HUD with StG 44, pause screen and fresh briefing after Restart; see [QA_REPORT.md](QA_REPORT.md). The preceding animated-guard PCK's similar 204.225-second result is historical evidence, not this run. Source Metal reviews show the StG viewmodel, player shadow and a visible tracer/wall mark under controlled conditions. These checks are not a first-time human full-mission playthrough or proof of the intended ten-minute pace. School-PC performance, final art and human acceptance remain open. A diagram, asset download or successful import alone is not playable evidence; see [DESIGN_REVIEW.md](DESIGN_REVIEW.md).
