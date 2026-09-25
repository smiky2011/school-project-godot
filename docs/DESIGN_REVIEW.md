# Design Review and Open Decisions

Reviewed: 25 September 2026. The first-version gameplay framework is coherent enough for a design baseline. It is not an implementation-ready technical specification.

## Corrections Made

- Removed duplicate mission summaries and assigned each document a clear responsibility.
- Updated stale proposal labels: finite reinforcements and the objective change after packet delivery are confirmed.
- Distinguished secret contact from final extraction: local pursuit/search must end only for the upstairs meeting.
- Preserved the distinction between NPC protection, player detection and the later intrusion-discovery event.
- Follow-up decisions: 1944 confirmed; free assets only; no fixed deadline; a locally playable Mac game; combat is not mandatory. Exact region and factions remain open.
- Kept technical names, maps and production experiments as deferred proposals.

## User Decisions Still Needed

| Decision | Why it matters |
| --- | --- |
| Region/month, factions and real versus composite town | The year is fixed at 1944; Normandy/France was not explicitly selected |

Budget and delivery are settled: free assets only, notify the user about registration-gated free resources, no fixed deadline, and a locally playable Mac game. Combat-free completion is allowed; no kill gate may be added.

These need not all be answered now. No existing rule is reopened by listing them.

## Astra: Propose and Document Before Implementation

- Secret-contact readiness boundary and behavior if pursuit resumes during the few-second handoff; never grant the packet for an unfinished exchange.
- Credible intrusion evidence after either a quiet approach or earlier combat. Handle early player departure or attacks on returning personnel without depending on an invulnerable enemy officer.
- End-of-search behavior for fixed sentries: preserve the confirmed return to normal duty without silently converting every post into a moving patrol.
- Out-of-combat regeneration eligibility during persistent lockdown; guard vision feedback during combat and across floors.
- Reload and stealth-kill interaction details; extraction shelter and completion transition, without adding an enemy-clearance condition.
- Layout, shared-route usefulness, signage, concise dialogue, HUD and technical interfaces under the confirmed design.

These are bounded specification tasks, not confirmed solutions. Production has since been authorized under the team delegation policy. Escalate any proposal that changes the experience, story or scope.

## Astra: Tune and Verify During Later Production

Vision range/angle, suspicion gain/decay, hearing and information sharing, search duration/radius, damage, regeneration timing, magazine size, reload duration, guard counts and finite reinforcement timing. Test ten-minute pacing and tense-but-forgiving escape rather than treating initial values as final.

Measure resolution, frame rate, graphics cost and imports on the M4 Pro / 24 GB target; propose an achievable performance target for review. No performance claim is established yet.

## Audit Evidence

All eight existing design documents and the contributor guide were reviewed. Edits affect documentation only; relative Markdown links and English-language consistency were checked. No gameplay, drawing or performance test was performed. Research source records and user-selected imagery remain unchanged.
