# Game Vision — WWII Town FPS

Status: first-version design baseline. Gameplay rules are confirmed below; technical implementation is not complete. Production is now authorized for the Astra-led team under the confirmed delegation policy; implementation is not yet verified.

## Core Promise

A short, atmospheric first-person WWII mission set in a small interconnected occupied town. The player infiltrates the town to recover intelligence from an enemy command post. The town supports multiple approaches through streets, alleys and buildings. After the intelligence is taken, enemy reinforcements alter the state of the same environment, turning the player's knowledge of the town into the key to escaping. Combat is the primary mechanic, but positioning, exploration and route choice matter.

## Confirmed Experience

| Area | First-version decision |
| --- | --- |
| Format | Single-player, offline, first-person mission; about ten minutes per successful run, excluding retries, without a mission countdown |
| Story | A scout meets a local contact upstairs in a requisitioned residence and receives copied enemy counterattack plans |
| Infiltration | Observe, bypass, shoot or use close-range stealth kills; detection is recoverable |
| Secret meeting | A few-second handoff requires pursuit and nearby searches to have ended; the contact stays behind |
| Escalation | Returning enemy personnel discover intrusion and order persistent town-wide lockdown; the player retains control |
| Extraction | Tense but forgiving; escape through the opposite side using knowledge gained on the approach |
| Victory | At the fellow scout's sheltered position, deliver the packet with one interaction press; remaining pursuers or alert do not prevent completion |
| Guards | One ordinary archetype in patrol, sentry and reinforcement roles; one finite reinforcement contingent, without endless replacement |
| Detection feedback | Short forward ground-level vision cones, gradual suspicion, local combat, last-seen-position search, then return to patrol if unsuccessful |
| Weapon | Submachine gun, finite magazine, required reload when empty, unlimited reserve ammunition |
| Recovery | Automatic out-of-combat health regeneration; death restarts the entire mission, without checkpoints |
| Mission NPCs | Both are invulnerable and do not independently attract enemies; player actions remain detectable |
| Guidance | Briefing, environmental landmarks and a simple objective-direction cue; the player chooses routes |
| Target | Local macOS MacBook Pro M4 Pro, 24 GB memory; performance targets are not yet measured |

## Visual and Spatial Direction

The six preferred references are G01-07 through G01-12. See [ART_DIRECTION.md](ART_DIRECTION.md) for observations and proposed interpretation. A believable inhabited town, connected routes and purposeful damage support the core promise. Selecting these images does not approve every pictured weapon or vehicle.

The year 1944 is confirmed. Exact region, month, factions and real-versus-composite town remain undecided; approval of the year alone does not select Normandy or France. Route overlap must make approach knowledge useful during escape without requiring a return to the entry point.

## Budget, Delivery and Combat Choice

Use free assets only. Paid assets, subscriptions and paid acquisition routes are excluded. Tell the user if a suitable free resource requires registration; do not create an account on their behalf without coordination. Existing assets remain the first choice; Blender is optional for necessary adaptation.

There is no fixed deadline for now. The deliverable is a game playable locally on the user's Mac, not merely screenshots, video or source files. Packaging and launch details can be chosen during production; no additional platform is committed. No deadline does not authorize expanding scope.

Combat is optional: support completion without killing enemies or requiring combat encounters to be cleared. The alarm and finite reinforcements still occur; evasion remains a valid solution during extraction.

## First-Version Exclusions

No body carrying, ammunition collection, escort or NPC-protection objectives, friendly combat system, special enemy classes, endless reinforcements, driving, or second mission. Later expansion requires a scope decision; checkpoints are not a promised later feature.

## Document Ownership

- [Mission story](MISSION_STORY.md): narrative cause, both handoffs and mission NPCs.
- [Guard behavior](STEALTH_AND_GUARD_BEHAVIOR.md): perception, search and stealth feedback.
- [Gameplay architecture](GAME_ARCHITECTURE.md): combat, health, retry and future system boundaries.
- [Design review](DESIGN_REVIEW.md): remaining decisions and review findings.

These are design commitments, not implementation evidence. Later production should prove the complete loop in a blockout before representative art and wider scope; see [milestones](MILESTONES_AND_AGENTS.md).
