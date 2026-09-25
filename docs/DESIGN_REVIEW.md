# Design Review and Open Decisions

Original design review: 25 September 2026. Production has since delivered an expanded, locally packaged first playable blockout. This file distinguishes unresolved user choices from Astra's provisional technical decisions; current interfaces are in [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md).

## Corrections Made

- Removed duplicate mission summaries and assigned each document a clear responsibility.
- Updated stale proposal labels: finite reinforcements and the objective change after packet delivery are confirmed.
- Distinguished secret contact from final extraction: local pursuit/search must end only for the upstairs meeting.
- Preserved the distinction between NPC protection, player detection and the later intrusion-discovery event.
- Follow-up decisions: a fictional European town in 1944; free assets only; no fixed deadline; a locally playable Mac game; combat is not mandatory. Exact region/month and factions remain open.
- Kept technical names, maps and production experiments as deferred proposals.

## User Decisions Still Needed

| Decision | Why it matters |
| --- | --- |
| Region/month and factions | The town is fictional and European in 1944; Normandy/France and specific forces were not selected |

Budget and delivery are settled: free assets only, notify the user about registration-gated free resources, no fixed deadline, and a locally playable Mac game. Combat-free completion is allowed; no kill gate may be added.

These need not all be answered now. No existing rule is reopened by listing them.

## Astra: Baseline Choices Documented for Implementation

- Secret-contact readiness boundary and behavior if pursuit resumes during the few-second handoff; never grant the packet for an unfinished exchange.
- Credible intrusion evidence after either a quiet approach or earlier combat. Handle early player departure or attacks on returning personnel without depending on an invulnerable enemy officer.
- End-of-search behavior for fixed sentries: preserve the confirmed return to normal duty without silently converting every post into a moving patrol.
- Out-of-combat regeneration eligibility during persistent lockdown; guard vision feedback during combat and across floors.
- Reload and stealth-kill interaction details; extraction shelter and completion transition, without adding an enemy-clearance condition.
- Layout, shared-route usefulness, signage, concise dialogue, HUD and technical interfaces under the confirmed design.

The blockout implements provisional answers to these bounded tasks; see [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md) and [LEVEL_LAYOUT.md](LEVEL_LAYOUT.md). Their numeric values and presentation require playtesting, and they are not new user-confirmed requirements. Escalate any proposal that changes the agreed experience, story or scope.

## Astra: Tune and Verify During Production

Vision range/angle, suspicion gain/decay, hearing and information sharing, search duration/radius, damage, regeneration timing, magazine size, reload duration, guard counts and finite reinforcement timing. Test ten-minute pacing and tense-but-forgiving escape rather than treating initial values as final.

One 1280 × 720 packaged-route sample on the M4 Pro / 24 GB target averaged 130.41 FPS, with 108 FPS as the lowest one-second sample after warmup. This is a bounded measurement, not a final performance target or broad hardware profile; see [QA_REPORT.md](QA_REPORT.md).

## Audit Evidence

The original 25 September design audit reviewed eight design documents and the contributor guide; that audit changed documentation only and performed no gameplay or performance test. Later implementation and rendered zero-kill runs are separate evidence. The exact packaged PCK completed a 202.66-second covered route, with target-machine performance recorded in [QA_REPORT.md](QA_REPORT.md); human first-time pacing and final visual acceptance remain open. Research source records and user-selected imagery remain unchanged.
