# Gameplay Rules and Proposed Architecture

Status: game-design baseline, not a finished technical architecture. Detailed interfaces, drawings and implementation belong to the now-authorized production phase, under the team delegation policy.

## Mission and System Boundaries

Use the confirmed loop in [GAME_VISION.md](GAME_VISION.md). [MISSION_STORY.md](MISSION_STORY.md) owns the different secret-contact and extraction handoff rules. [STEALTH_AND_GUARD_BEHAVIOR.md](STEALTH_AND_GUARD_BEHAVIOR.md) owns perception and local search.

Mission progress, local guard awareness and persistent lockdown are separate concepts. Completing the packet handoff updates the objective to extraction; returning personnel then discover intrusion and trigger lockdown. Receiving the packet does not clear prior awareness, and ending a local search does not lift lockdown.

Proposed implementation labels are `INFILTRATE` → `INTEL_SECURED` → `EXTRACTED`, plus `FAILED`. These are examples, not fixed interfaces; they must preserve the handoff/discovery distinction.

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

A rear approach and interaction prompt are proposed for stealth kills. Exact eligibility, range, animation and interruption rules remain open, as do reload initiation, partial-magazine behavior, duration, damage and recoil.

## Health and Full Restart

Health regenerates automatically out of combat. Disengagement criteria, delay, rate, cap and interruption behavior need specification. **Proposal:** use immediate threats rather than global lockdown as the regeneration condition; requiring lockdown to end could disable recovery throughout extraction. This specific eligibility rule is not confirmed.

There are no checkpoints. Death restarts the mission with initial player position, health and ammunition; enemies, bodies, awareness, NPC interactions, packet availability, alarm and reinforcements reset. Previous-run searches and delayed events must not continue. Regeneration cannot revive the dead player.

## Navigation and Feedback

Provide a short briefing, landmarks and a simple current-objective direction cue. The player chooses routes. The objective changes from the contact to extraction after packet delivery and resets on retry. Marker style, distance display and interaction presentation remain open. Towers and bridges are examples, not approved assets.

## Proposed Technical Responsibilities

| Module | Responsibility |
| --- | --- |
| `Main` | Startup, menus/loading and result screens |
| `TownLevel` | Environment placement, collision, navigation and encounter locations |
| `Player` | First-person movement, view, health and inputs |
| `Weapon` | Shooting, ammunition, reload and hit feedback |
| `Enemy` | Perception, patrol/sentry duties, search, combat and damage |
| `MissionDirector` | Authoritative mission progress, escalation and completion |
| `HUD` | Display objectives and feedback without owning mission progress |

These names and signal-based coordination are proposals. Do not treat them as existing code. Later encounter records should identify routes, landmarks, cover, initial guards, reinforcement changes and likely player misunderstandings before choosing a data format.

## Future Acceptance Checks

- Recover from detection, satisfy secret-contact conditions and complete the packet handoff.
- Observe meaningful, finite post-handoff escalation while retaining player control.
- Reach the opposite-side shelter and finish despite remaining pursuers, including a run without killing enemies.
- Neither mission NPC dies, attracts enemies independently, or reveals player position.
- Reload is required when empty; reserves never run out. Health recovery behaves consistently with its eventual specification.
- Death before/after the alarm and consecutive retries produce clean, completable runs.

A diagram, asset download or successful import alone is not playable evidence. Remaining work is classified in [DESIGN_REVIEW.md](DESIGN_REVIEW.md).
