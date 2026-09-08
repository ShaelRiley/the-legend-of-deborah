# The Legend of Deborah — Development Protocol

This file governs **how an AI development agent works on The Legend of Deborah**. It is intentionally procedural. It is not a game-design document, implementation ledger, feat catalog, status report, or replacement development plan.

Its purpose is to prevent drift, needless rediscovery, speculative implementation, and conversational state loss while keeping development efficient enough to finish the game.

## 1. Authority hierarchy

When sources disagree, classify the disagreement before acting.

### Design authority

The exact live Google Doc **The Legend of Deborah — Garry's Mod Game Design Document** is authoritative for intended game behavior.

Google Doc ID: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`

Do not substitute an old local export, Word copy, remembered rule, historical chat, implementation comment, test document, or development-plan paraphrase for the live GDD.

Do not invent missing rules, feat behavior, prerequisites, percentages, dice, scaling formulas, timings, authored content, or exceptions.

### Implementation authority

GitHub repository `ShaelRiley/the-legend-of-deborah`, branch `main`, is authoritative for what the game currently implements.

Do not infer current implementation state from an old handoff, chat transcript, stale local checkout, or planning document when `main` can answer the question.

### Runtime authority

Current reproducible runtime evidence is authoritative for what the current build actually does.

Prefer the canonical evidence workflow in `docs/TEST_LOGGING.md`. Logs and finite validators are stronger evidence than recollection or visual impression for mechanical behavior; screenshots remain appropriate for visual/layout defects.

Runtime evidence can prove that implementation behavior differs from design, but it does **not** rewrite design authority by itself.

### Planning authority

`docs/DEVELOPMENT_PLAN.md`, `docs/DEVELOPMENT_STATUS.md`, implementation matrices, gate documents, issue trackers, and handoffs are coordination instruments. They may describe intended sequencing or historical state, but they cannot override the live GDD, GitHub `main`, or newer runtime evidence within their respective domains.

## 2. Reconciliation rule

Never quietly choose among contradictory sources.

When a material conflict appears:

1. Identify whether it concerns **design intent**, **current implementation**, **observed runtime behavior**, or **work sequencing**.
2. Consult the corresponding authority above.
3. State the discrepancy succinctly in the working record or handoff.
4. Correct the lower-authority artifact only when doing so is within the current task.
5. If the live GDD itself is internally contradictory or genuinely silent on a behavior that must be authored, do not fabricate a resolution. Isolate the affected work, preserve the contradiction, and continue independent work where possible.

Historical plans and chats are evidence of prior reasoning, not constitutional authority.

## 3. Standard development loop

For each bounded development unit:

1. **Orient.** Confirm current `main` HEAD and working scope. Read only the repository files, live-GDD passages, status artifacts, and recent evidence needed for the unit.
2. **Reconcile.** Compare the relevant GDD requirement with the current implementation and existing tests before changing code.
3. **Define a finite gate.** State what observable condition will prove the unit correct. Avoid open-ended “test generally” instructions.
4. **Implement narrowly.** Modify the smallest canonical gameplay seam that can satisfy the requirement. Prefer one authoritative mechanism over duplicated special cases.
5. **Validate statically.** Run syntax/static checks and targeted validators available for the changed subsystem before pushing.
6. **Commit and push.** Leave `main` in a coherent, testable state. Do not claim a push occurred unless the remote update actually succeeded.
7. **Give finite runtime instructions.** Tester instructions must be short, deterministic where practical, and aimed at falsifying the exact behavior just changed.
8. **Ingest evidence.** Read the returned logs/screenshots rather than relying on the tester's summary alone when the evidence is available.
9. **Adjudicate.** Mark the unit accepted only when its explicit gate passes. If it fails, diagnose from evidence and repair the same unit before advancing unless the failure proves unrelated.
10. **Record durable state.** Update only the coordination artifact that actually needs updating. Do not create a new status document when an existing canonical one suffices.

The default cadence is therefore:

**inspect → reconcile → finite gate → implement → static validation → commit/push → runtime test → evidence → accept/repair**

## 4. Scope discipline

### One coherent family at a time

Prefer a small feature family, defect cluster, or system seam that can be implemented and tested as one unit. Do not mix unrelated cleanup, balance changes, presentation work, and architecture changes into the same batch merely because they are nearby in the code.

### No opportunistic design

Implementation work is not permission to redesign adjacent systems. If a desirable change is not required by the live GDD or the active task, preserve it as a candidate rather than silently incorporating it.

### No speculative refactors

Refactor when necessary to establish a canonical authority, remove demonstrated duplication, repair an architectural defect, or make the active feature safely implementable. Do not spend scarce development effort polishing abstractions that have no present acceptance consequence.

### Preserve accepted behavior

A previously accepted runtime behavior is a regression constraint unless newer authoritative design explicitly changes it. New work should retain existing validators and add a narrower validator where practical.

## 5. Evidence discipline

Use `docs/TEST_LOGGING.md` as the canonical runtime-evidence procedure.

A mechanical feature is not “done” because code exists. Distinguish explicitly among:

- **designed** — present in the live GDD;
- **implemented** — present on GitHub `main`;
- **statically validated** — repository checks pass;
- **runtime observed** — evidence shows the behavior occurred;
- **runtime accepted** — the finite acceptance gate passed without contradictory evidence.

Do not collapse these states.

When a test fails, preserve the evidence. Do not rewrite history by editing an old acceptance record to imply the failing run never occurred.

## 6. Tester-interface rules

The human tester should receive the least burdensome procedure that can establish the needed fact.

- Use `gm_flatgrass` for canonical runtime testing unless the live project explicitly changes the required map.
- Give one next test action when one is sufficient.
- Keep console-command batches on **one line separated by semicolons**.
- Prefer project testkit commands and finite validators over long sequences of manual console setup.
- Request only the evidence files needed to adjudicate the gate.
- Do not make the tester rediscover repository state, filenames, paths, or setup already known to the project.
- Separate required actions from optional diagnostics.

## 7. Compute economy

Expensive agent effort should go to repository inspection, design reconciliation, implementation, validation, and diagnosis — not reconstructing history that durable sources already encode.

Default behaviors:

- Read targeted files first; expand scope only when evidence demands it.
- Search before opening large files wholesale.
- Reuse existing test infrastructure instead of creating redundant validators.
- Prefer modifying an existing canonical document over creating another overlapping plan/status ledger.
- Do not produce long narrative progress reports unless they materially improve the next development action.
- Do not repeatedly re-audit already accepted units without new contradictory evidence.
- When a broad reconciliation is required, perform it once, produce a concise canonical result, then resume bounded implementation.

## 8. Handoff contract

A handoff exists to let the next agent resume work without archaeology. It should be concise and contain only current operational truth.

Every substantial development handoff should state:

1. repository and branch;
2. exact current remote HEAD or commit that the tester should have;
3. design authority (the exact live GDD);
4. what was just implemented;
5. what has actually been runtime accepted versus merely implemented;
6. unresolved defects or contradictory evidence;
7. the next bounded objective and its finite acceptance gate;
8. any specific evidence package the next test should return;
9. preserved constraints that are easy to regress and directly relevant to the next unit.

Do not paste obsolete history merely for completeness. If an old handoff conflicts with GitHub, the live GDD, or newer evidence, say it is stale and proceed from the higher authority.

## 9. Security invariants

Never place secrets in source, chat-visible diagnostics, screenshots, or documentation.

In particular, do not expose or commit:

- Steam GSLTs;
- VPS, Steam, OVH, or other account passwords;
- private SSH keys;
- recovery codes;
- payment credentials.

Consult the project infrastructure documentation for the current safe deployment procedure. Avoid diagnostics that print secret-bearing full process command lines.

## 10. Definition of progress

Progress is not measured by lines of code, number of commits, number of feats mentioned, or amount of planning produced.

A development unit advances the project when it reduces the distance between:

**live GDD intent → coherent implementation on `main` → finite reproducible runtime proof.**

Prefer closing one uncertainty completely over opening several partially implemented fronts.

## 11. Generalization boundary

This protocol is intentionally specific to finishing The Legend of Deborah while avoiding duplication of its mutable design.

Do **not** turn Deborah-specific implementation contingencies into universal Garry's Mod doctrine during active development. A general `develop-garrysmod-games` skill should be distilled after The Legend of Deborah reaches release-candidate maturity, when reusable practices have survived implementation, dedicated-server operation, multiplayer validation, Workshop distribution, regression testing, and release qualification.

Until then:

- the live GDD says **what Deborah should be**;
- GitHub `main` says **what Deborah currently is**;
- runtime evidence says **what the build actually does**;
- this protocol says **how to move those three toward agreement efficiently**.

That separation is deliberate. Preserve it.