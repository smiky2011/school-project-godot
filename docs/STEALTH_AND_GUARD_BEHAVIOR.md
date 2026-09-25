# Stealth and Guard Behavior

Status: confirmed game-design direction, recorded 2026-09-25. No gameplay implementation or map layout is specified here. All project-authored documentation, including earlier documents, uses English; discussion with the user may remain in Chinese. This document is authoritative for the detection and search decisions below; older architecture proposals must not override them.

## Intended Experience

The outbound journey emphasizes observation, judgment, and action. Players watch patrols, recognize openings, and choose between bypassing guards, close-range stealth kills, and shooting. Route alternatives should offer understandable tradeoffs: direct streets expose the player, side alleys trade distance for concealment, and building passages may involve close encounters. Exact routes and guard placement are for later level design.

Mistakes are recoverable. Detection does not immediately fail the mission or trigger the post-contact town-wide lockdown.

## Visible Vision Cones

- Display guards' forward vision areas directly on the ground during infiltration.
- Use relatively short range and a moderate angle, leaving opportunities to approach from the side or behind. Exact distances and angles are not yet fixed.
- Cones are translucent with readable boundaries and follow the guard's observation direction.
- Walls and other sight-blocking obstacles truncate the visible area. Guards cannot see through them.
- Use pale yellow for normal visibility, transitioning toward orange as suspicion rises. Show detection progress as well, so feedback does not depend on color alone.
- Entering a cone builds suspicion instead of causing immediate detection. Give the player a brief opportunity to retreat behind cover; close frontal exposure produces faster detection.
- A cone communicates visual detection, not hearing. Gunshots can still attract attention outside it.

## Guard Response Loop

| Stage | Guard behavior | Player opportunity |
| --- | --- | --- |
| Patrol | Follow a patrol route with visible vision feedback. | Observe gaps, bypass, or approach from behind. |
| Suspicion | Stop and look toward the possible sighting while detection progress rises. | Break line of sight before identification. |
| Confirmed detection | Open fire and call nearby guards, creating a local encounter. | Fight or break visual contact and escape. |
| Search | Investigate the last seen position and nearby areas. | Hide, relocate, or wait for the search to end. |

After an unsuccessful search, guards return to patrol. Losing sight of the player does not grant knowledge of the player's new position. Search must feel like an investigation rather than instant forgetting or omniscient pursuit.

## Local Alert Versus Town-Wide Lockdown

Local combat, gunshots, witnessed attacks, and discovered bodies cause local reactions. Discovering a body prompts a nearby search, not immediate knowledge of the player's location or automatic mission-wide lockdown. Unwitnessed close-range stealth kills do not attract guards like gunshots. Body carrying is outside the first version.

The narrative escalation follows the upstairs contact and intelligence handoff: returning enemy personnel discover signs of intrusion and initiate lockdown. The original enemy documents have not gone missing; the contact provides a secretly copied intelligence packet. See `MISSION_STORY.md`.

Once triggered, town-wide lockdown persists even if an individual search ends. Guards still need sensory evidence to locate the player. Returning to patrol does not reset the mission or remove the lockdown.

## Contact and Extraction

The upstairs meeting requires pursuit and nearby search to end; final extraction does not. Exact handoff rules and NPC protection are owned by [MISSION_STORY.md](MISSION_STORY.md). Extraction is tense but forgiving, with finite reinforcements; see [GAME_ARCHITECTURE.md](GAME_ARCHITECTURE.md).

## Open Design Details

- Vision distance and angle; detection buildup and decay; search duration and extent.
- How quickly nearby guards receive information and which guards respond.
- Exact visibility feedback during combat and lockdown, and for guards on different floors.
- Responses to renewed sightings, repeated body discoveries, and interrupted suspicion.
- Normal-duty behavior after unsuccessful searches during lockdown, including how fixed sentries resume their posts.

Ownership of these details is recorded in [DESIGN_REVIEW.md](DESIGN_REVIEW.md). The now-authorized production team owns drawings and implementation.

## Experience Acceptance Criteria

A first-time player can read a guard's visible area and understand increasing suspicion. Brief exposure followed by cover can avoid confirmed detection. A spotted player can survive, break contact, and continue toward the contact. Searching guards investigate evidence rather than tracking through walls. Ending a local search after the handoff does not lift lockdown. A full mission restart restores guard, suspicion, search, contact, and lockdown conditions to their initial state.
