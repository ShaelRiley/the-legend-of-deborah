# The Legend of Deborah — AI Development Protocol

This file governs **how an AI development agent works on The Legend of Deborah**. Keep it procedural and compact. It is not the game-design document, implementation ledger, feat catalog, runtime history, or development plan.

## 1. Authority hierarchy

### Design authority

The exact live Google Doc **The Legend of Deborah — Garry's Mod Game Design Document** is authoritative for intended game behavior.

Google Doc ID: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`

Do not substitute an old local export, Word copy, remembered rule, historical chat, implementation comment, feat matrix, test document, or development-plan paraphrase for the live GDD. Do not invent missing rules, feat behavior, prerequisites, percentages, dice, scaling formulas, timings, authored content, tuning, or exceptions.

### Implementation authority

GitHub repository `ShaelRiley/the-legend-of-deborah`, branch `main`, is authoritative for what the game currently implements.

### Runtime authority

Current reproducible runtime evidence is authoritative for what the current build actually does. Use `docs/TEST_LOGGING.md`. Runtime evidence may prove implementation differs from design; it never silently rewrites design.

### Sequencing authority

`docs/DEVELOPMENT_PLAN.md` is the current coordination source for **what to implement next**. `docs/DEVELOPMENT_STATUS.md`, `docs/RPG_IMPLEMENTATION_GATES.md`, `docs/RPG_GATE_E_FEAT_MATRIX.md`, old handoffs and historical plans preserve evidence/inventory but may contain superseded sequencing or old design assumptions.

When sources conflict, classify the conflict as design, implementation, runtime, or sequencing and obey the corresponding authority.

## 2. Mandatory low-compute GDD navigation

Never orient by reading the complete GDD from top to bottom.

Use this exact path:

1. `00 — AI ENTRYPOINT`
2. `01 — AI RULE INDEX`
3. only the normalized subsystem tab(s) required by the active task
4. one exact `HUMAN — Complete GDD` anchor, featId, enemy name, formula name, or authored row **only when the AI tab explicitly leaves that detail as HUMAN-DETAIL**

Normalized subsystem tabs:

- `02 — RPG & LEVELING`
- `03 — COMBAT, MAGIC & STATUS`
- `04 — FEATS & IDENTITY`
- `05 — CORE LOOP & WORLD`
- `06 — MULTIPLAYER, LIFECYCLE & UI`
- `07 — IMPLEMENTATION & TUNING`
- `90 — DEFERRED / FUTURE`

The normalized AI tabs are authoritative where they explicitly cover a rule. `HUMAN — Complete GDD` is the author-facing full design and exact-detail fallback. If a later human edit changes game law, mirror it into the relevant normalized AI rule before dependent implementation continues.

Do not read `docs/RPG_GDD_RULES_BASELINE.md` as a copied rule source; it is now only a navigation redirect.

## 3. Standard development loop

For each bounded checkpoint:

**orient → reconcile → define finite static/runtime gate → implement at canonical seam → validate → commit/push → later runtime evidence → accept/repair**

Specifically:

1. Confirm current remote `main` HEAD and clean working tree.
2. Read the current `docs/DEVELOPMENT_PLAN.md` checkpoint and only its needed GDD AI tabs.
3. Inspect existing production modules and tests before adding code.
4. Reconcile current GDD requirement with current implementation.
5. Define a finite observable condition proving the checkpoint.
6. Modify the smallest shared authority that can satisfy the requirement. Prefer extension over parallel systems.
7. Run syntax/static checks and targeted validators for all changed authorities plus relevant accepted regressions.
8. When the checkpoint is coherent and static gates pass, commit and push immediately. Never hold completed checkpoints uncommitted while consuming scarce compute.
9. Use runtime testing at the cadence specified by the current development plan. Do not invent extra manual gates merely because older plans used them.
10. Preserve evidence and update only the coordination artifact that actually needs it.

## 4. Scope discipline

### Shared-authority work is allowed when explicitly planned

The ordinary default is one coherent family/defect/system seam at a time. However, when the explicit current user direction and `docs/DEVELOPMENT_PLAN.md` define an **integrated cross-system tranche**, checkpoint by shared architecture rather than artificially fragmenting the same authority into many family-by-family changes.

This exception is deliberate for the current RPG-completion program: actor Levels, statuses, elements, Magic, feats, human Soldiers and UI share core authorities and should be integrated through those authorities, with checkpoint commits between them.

### No opportunistic design

Implementation is not permission to redesign adjacent systems. If a value is not fixed by design, it may be chosen only when the live GDD explicitly marks it `IMPLEMENTATION-TUNABLE`; record every such chosen value in GDD tab `07 — IMPLEMENTATION & TUNING`.

An unspecified value is not permission to invent one.

### No speculative refactors

Refactor only to establish a canonical authority, remove demonstrated duplication, repair an architectural defect, or safely implement the active checkpoint. Do not spend scarce compute polishing abstractions without acceptance consequence.

### Preserve accepted behavior

Previously runtime-accepted behavior is a regression constraint unless newer live design explicitly changes it. Existing validators should remain and be reused where practical.

## 5. Evidence states

Never collapse these states:

- **designed** — present in the live GDD;
- **implemented** — present on GitHub `main`;
- **statically validated** — repository checks pass;
- **runtime observed** — evidence shows behavior occurred;
- **runtime accepted** — the finite acceptance gate passed without contradictory evidence.

A feature is not runtime-accepted because code exists or a static harness passes.

Preserve failed evidence. Do not rewrite old acceptance history to hide a failing run.

## 6. Tester interface

The human tester should receive the least burdensome procedure that proves the needed facts.

- Canonical runtime map: `gm_flatgrass`.
- Give one next test action when one suffices.
- Console command batches should be one line separated by semicolons.
- Prefer project testkits/validators and logs over long manual setup.
- Default evidence package: `console_latest.txt` + `rpg_summary_latest.txt` from the canonical Legend of Deborah data directory; request `rpg_session_latest.txt` only when detailed event order/timing is needed.
- Screenshots are appropriate for visual/layout defects; logs are preferred for mechanics.
- Do not make the tester rediscover paths, filenames, setup, or repository state already known to the project.

## 7. Compute economy

Expensive agent effort belongs in code inspection, design reconciliation, implementation, validation and diagnosis—not archaeology.

- Read targeted files first; expand only when evidence demands it.
- Use the normalized GDD tabs, not the human monolith.
- Use `docs/DEVELOPMENT_PLAN.md` before historical status/gate documents.
- Search exact feat IDs/anchors rather than scanning catalogs narratively.
- Reuse existing production seams and test infrastructure.
- Prefer one event-driven/shared resolver over per-feat or per-enemy recurring hooks.
- Do not repeatedly re-audit already accepted units absent new contradictory evidence.
- At a compute limit, finish/validate/commit the current checkpoint rather than beginning another.
- Never spend remaining compute writing a long prose report instead of preserving a valid working commit.

## 8. Handoff contract

A substantial handoff should contain only current operational truth:

1. repository/branch;
2. exact remote HEAD;
3. exact live GDD identity and which normalized tabs governed the work;
4. checkpoint just implemented;
5. what is merely implemented/static vs runtime-observed/accepted;
6. unresolved defect or contradictory evidence;
7. next checkpoint and finite gate;
8. evidence package needed next;
9. directly relevant accepted-regression constraints.

Do not paste obsolete history for completeness. Point to durable files instead.

## 9. Branch/write discipline

`main` is the accepted implementation branch. Hybrid Antigravity work follows `docs/ANTIGRAVITY_PROTOCOL.md` and may write only its authorized experimental branch until promotion. Never claim a commit/push succeeded without verifying the remote result.

Do not modify the live GDD during routine implementation unless the active task explicitly includes a design correction or a genuine internal contradiction is discovered. If the GDD is genuinely silent on required authored behavior, isolate the gap instead of fabricating a rule.

## 10. Security invariants

Never expose or commit secrets, including Steam GSLTs, VPS/Steam/OVH passwords, SSH private keys, recovery codes or payment credentials. Avoid diagnostics that print secret-bearing full process command lines.

## 11. Definition of progress

Progress reduces the distance between:

**live GDD intent → coherent implementation on `main` → finite reproducible runtime proof.**

Lines of code, number of commits, number of feat names touched, and amount of planning are not progress by themselves.

Until release-candidate maturity:

- live GDD says **what Deborah should be**;
- GitHub `main` says **what Deborah currently is**;
- runtime evidence says **what the build actually does**;
- this protocol says **how to move them toward agreement efficiently**.
