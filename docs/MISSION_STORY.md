# Mission Story

Status: confirmed first-version narrative. The Godot blockout implements both handoffs and a provisional exposure cue; exact historical identities and final presentation remain open. This document owns handoff conditions and story causality.

## Characters and Stakes

The player is a military scout. A fellow scout prepares extraction on the opposite side of an occupied town while the player enters a requisitioned residence used as an enemy command post.

Upstairs, a local person forced to maintain enemy telephone lines secretly provides copied counterattack plans. Delivering them can prevent friendly forces from being surprised. The original enemy documents remain in place. The contact stays behind to preserve cover; the player leaves alone.

## Mission Flow

| Stage | Confirmed behavior |
| --- | --- |
| Briefing | Establish the contact objective and opposite-side extraction direction |
| Infiltration | Learn routes and guard behavior; earlier detection can be recovered from |
| Secret handoff | Approach the upstairs contact covertly, interact, receive the packet within a few seconds, then update the objective to extraction |
| Exposure | Returning personnel discover signs of intrusion; a returning officer orders lockdown |
| Escape | Finite reinforcements change the same town; pressure is tense but forgiving |
| Final handoff | Reach the fellow scout's sheltered position with the packet and press one interaction button to finish |

## Two Different Handoff Conditions

**Upstairs contact:** pursuit and nearby local searches must have ended. Briefly breaking line of sight at the doorway is insufficient. While unsafe, the contact continues ordinary work and withholds the packet; give the player a short explanation without exposing the contact through an obligatory audible conversation. Earlier detection does not permanently disqualify the player.

**Extraction scout:** pursuers may remain outside. Do not require enemy clearance, search expiry or lifting the lockdown. The current blockout uses one E press inside a shelter; geometry and presentation remain provisional.

## Exposure Must Have a Cause

The alarm follows the completed secret handoff and discovery of intrusion, not missing original papers or automatic exposure of the contact. After a quiet approach, returning personnel find evidence; after earlier fighting, they confirm the breach. The current blockout stages a cut stair security seal, an arrival cue and an offscreen radio order about seven seconds after packet delivery. This is an Astra-reviewed implementation choice, not a user-confirmed historical detail; see [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md).

Arrival and orders need perceptible cues, such as vehicle sounds and shouting. The player remains free to move and choose an exit. Vehicles are staging, not a driving system. The event must handle early departure and attacks on returning personnel without relying on a killable officer inevitably surviving or forcing a long noninteractive scene.

## Mission NPC Protection

Both the contact and extraction scout are invulnerable to player and enemy damage. Their presence, location, routine behavior and interaction do not independently attract enemies, trigger alerts, or reveal the player. They are not bait or automatic enemy targets.

Guards still react to player sightings, gunfire, witnessed attacks and bodies nearby. Protection does not make the player invisible or invulnerable. No escort, friendly combat or NPC-protection objective is added.

## Deferred Details

See [DESIGN_REVIEW.md](DESIGN_REVIEW.md) for ownership. The user confirmed a fictional European town in 1944; exact region, month, factions, identities and historical framing remain open. Current dialogue, identification cues, interruption rules and exposure staging are provisional blockout decisions. An unfinished handoff must not silently become complete. Example dialogue and the previously suggested front-square/rear-yard layout are not locked requirements.
