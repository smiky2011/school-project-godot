# Milestones and Multi-Agent Working Agreement

Status: production start authorized by the user; delegation policy confirmed. No subagents, MCP production, modeling, or gameplay implementation have been started under this plan. GPT-6 Astra is the intended planning/review lead; the user owns creative direction and scope. Execution work is delegated to GPT-6 Sol subagents with high reasoning effort, as specified below. Delegation does not guarantee lower usage; parallel work can increase cost through repeated context and integration.

The user has now authorized production. This supersedes the earlier design-only restriction; authorization is not evidence that production has begun. The Astra-led team may proceed within the agreed scope without asking for the same start approval again.

Open decision ownership is consolidated in [DESIGN_REVIEW.md](DESIGN_REVIEW.md). Routine implementation and tuning do not require repeated creative approval; changes to the agreed experience or scope do.

## Confirmed Model and Delegation Policy

- **Lead: GPT-6 Astra (`gpt-6-astra`).** Act as the project's coordinating brain: own architecture, task decomposition, interfaces, dependency order, design consistency, integration decisions and acceptance review.
- **Execution subagents: GPT-6 Sol (`gpt-6-sol`) with reasoning effort `high`.** Explicitly request these settings when dispatching implementation work; do not rely on inherited defaults. Astra's own reasoning effort is not specified by this policy.
- Delegate all substantial execution work: online asset search and screening, license/provenance checks, downloads and organization, environment checks, map drawings, asset adaptation/import, coding, integration edits, documentation maintenance, debugging, test runs, playthrough evidence and packaging. Astra owns decisions and judgments: direction, architecture, task briefs, tradeoffs, integration approval and acceptance review. Astra may inspect outputs and evidence as needed for those judgments, but must not absorb delegated execution merely for convenience. Do not merely relay completion claims.
- Use separate file ownership and parallelize only independent work. Respect the runtime's available concurrency; do not create extra work merely to keep agents busy.
- If the requested model/settings cannot be selected, report the limitation before substituting. Do not claim that a prose prompt alone configured the runtime.

Apply this policy when production runs. Updating this policy does not itself launch workers.

Asset budget is zero: use free resources only and notify the user about registration requirements. No paid assets or acquisition services. There is no fixed deadline; deliver a locally playable Mac game without expanding scope.

## Decision Boundaries

| User decides | Astra may do | Subagents may do |
| --- | --- | --- |
| Historical/visual direction, combat feel, story, milestone scope | Commission research, judge options/costs/risks and choose within authorization | Research, document or produce within an approved brief without changing the goal |
| Scope-changing or otherwise consequential resource/technology choices | Choose routine implementation details within authorization; propose interfaces and validation experiments | Investigate within assigned files/time; report evidence and issues |
| Milestone acceptance and expansion | Review playable results, quality and remaining issues; recommend acceptance or rework | Submit actual files, validation records and incomplete work |

If a brief is infeasible, sources conflict, or a major creative change is needed, return a proposal to Astra and the user. Efficiency is not authorization to change location, rewrite the mission, remove route choices, or expand scope.

## Roles and Handoffs

- **Astra / design and integration:** maintain consistency, convert decisions into bounded briefs, review history/layout/assets/runtime evidence, and report tradeoffs. Dispatch the next phase after milestone approval; existing user authorization should not be requested again.
- **Research agent:** record sources, dates, rights, observations, and inference limits; deliver candidate references, not an unapproved final art direction.
- **Level design agent:** later develop spatial proposals and testable approach/extraction routes, sightlines, combat spaces and landmarks. An abstract node graph alone is not a grounded spatial proposal.
- **Asset integration agent:** search and evaluate existing assets first, validate imports and provenance, and report functional gaps. Use Blender only for necessary adaptations; propose custom modeling only after demonstrating a required gap. Do not redesign streets independently.
- **Godot gameplay agent:** implement mission, player, weapon, guard and level integration within the architecture brief; prioritize actual playability and testable state.
- **QA agent:** play the full loop and report navigation, pacing, feedback and technical problems; distinguish editor checks, automated tests and real playthroughs.

These are responsibilities, not a requirement to run six agents simultaneously. Assign one writer to each shared file; others submit separate artifacts or suggestions. An assigned subagent performs integration edits under Astra's review.

## Proposed Milestones

| Stage | Deliverables | Acceptance evidence | User review |
| --- | --- | --- | --- |
| P0: design constraints | Setting candidates, pacing, target machine/time, updated design documents | Selected direction and exclusions are explicit | Visual direction and scope |
| P1: references | Indexed historical images, game/environment cases, visual specification | Core images trace to place/date; game images are not treated as history | Core references; six have now been selected |
| P2: spatial proposal | Later reference-informed layout sketch, approach/extraction explanation, dimension hypotheses | Credible town relationships and shared-space mission logic | Routes, landmarks, objective placement |
| P3: technical sample | One corner assembled from selected assets, provenance, necessary conversions, import and performance record | Scale, materials, collision and import work; actual MCP benefits/issues documented | Whether to expand asset production |
| P4: MVP | Godot blockout with the minimum complete loop | Real playthrough of infiltration, contact handoff, escalation, extraction and retry | Playtest feedback |
| P5: vertical slice | Representative finished quality in a compact area | Player feedback, performance, visual consistency and remaining risks | Final expansion scope |

P3 and P4 may overlap later; detailed models must not substitute for route validation. Scope after P5 depends on actual results and the user's decisions. The first reference collection already exists; current P1 discussion uses G01-07 through G01-12 as the user's core preferences.

## Delegation Brief Template

Each task specifies `objective`, `approved_inputs_and_references`, `allowed_files`, `out_of_scope`, `deliverables`, `acceptance_method`, `time_or_cost_limit`, and `conflict_reporting`.

Example: “Using G01-09/G01-10, compare compatible existing wall/building assets for one corner. Submit sources, licenses, import results and gaps. Do not custom-model by default or change routes.”

## Progress Reporting

For each phase, report confirmed decisions, actual files, verification evidence, unresolved issues, and choices needing the user. Unapproved ideas remain labeled proposals. Preserve the student's own design explanations, playtest observations and revision reasons as learning evidence for the school project.

During implementation, publish progress to GitHub by pushing commits at meaningful completed increments. Astra decides when a finished function, coherent change, or feature is ready and delegates one agent to stage, commit, and push the reviewed files. Only one agent performs Git writes in the shared worktree at a time. Do not wait for an entire milestone or commit every tiny edit. Use a concrete commit subject, link or identify the pushed commit in the progress report, state the validation actually performed, and identify work still incomplete. Exclude secrets, generated caches, the local `reference/` directory, and other agents' unfinished edits.
