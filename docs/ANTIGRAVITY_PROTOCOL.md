# The Legend of Deborah — Antigravity Hybrid Development Protocol

This protocol governs Google Antigravity/Gemini work performed on the experimental Git branch `hybrid/antigravity`. It supplements `AGENTS.md`; it does not replace the live GDD, repository authority, or runtime-evidence rules.

## 1. Purpose

Antigravity is a bounded implementation and local-test worker. Sol/Astra remain responsible for architecture, design reconciliation, difficult diagnosis, acceptance adjudication, and promotion to `main`.

The objective is to convert inexpensive Antigravity compute and local-computer control into auditable implementation progress without allowing speculative design or unreviewed code onto `main`.

## 2. Absolute branch boundary

Antigravity may work only on:

`hybrid/antigravity`

Unless a Sol/Astra task explicitly says otherwise, Antigravity must not:

- commit, merge, cherry-pick, rebase, reset, or push `main`;
- force-push any branch;
- deploy or restart the public server;
- publish the Workshop item;
- alter the live GDD;
- create additional development branches;
- merge newer `main` changes into the hybrid branch on its own initiative.

Before changing files, run `git fetch origin`, confirm the current branch is `hybrid/antigravity`, record `HEAD`, and confirm the working tree is clean. If the hybrid branch has fallen behind `origin/main`, report that condition rather than choosing a reconciliation strategy independently.

## 3. Authority and design restraint

Follow `AGENTS.md` in full.

The live Google Doc **The Legend of Deborah — Garry's Mod Game Design Document** remains design authority. GitHub `main` remains authoritative for the accepted implementation baseline. The hybrid branch is proposed implementation only until reviewed and promoted.

If requested behavior is not determined by the active task, the live GDD, or an existing canonical implementation seam, stop that affected portion and report the ambiguity. Do not invent feats, prerequisites, percentages, dice, timings, formulas, balance, authored content, state semantics, or exceptions.

Do not opportunistically refactor, rename APIs, retune constants, fix unrelated warnings, or redesign adjacent systems.

## 4. Batch contract

Each assigned Antigravity batch has a task ID such as `AG-001` and should represent one coherent development unit.

For an implementation batch:

1. Orient to the task and relevant files only.
2. Reconcile the requested behavior against the live GDD and current code.
3. State the finite acceptance gate before editing.
4. Implement narrowly.
5. Run static checks appropriate to changed files.
6. Run local Garry's Mod validation whenever the behavior is runtime-testable.
7. Repair failures within the same task before advancing.
8. Commit exactly one coherent task commit using a message beginning with the task ID.
9. Push only `hybrid/antigravity` with a normal non-forced push.
10. Generate the Antigravity audit bundle.

Do not batch several unrelated accomplishments merely to increase throughput.

## 5. Local Garry's Mod computer-control testing

Antigravity is expected to use its control of Shael's local computer to perform routine runtime QA that would otherwise require manual testing.

For runtime-testable work, Antigravity should ordinarily:

1. Run `./tools/install_dev.sh` after the branch is current.
2. Start Garry's Mod fresh when a clean engine console is useful.
3. Use the canonical test map `gm_flatgrass` unless the active task explicitly requires otherwise.
4. Execute the finite console/testkit commands specified by the task.
5. Control the player, weapons, enemies, menus, and other ordinary local game interactions needed to exercise the mechanic.
6. Use `lod_rpg_test_mark <short note>` at diagnostically useful moments.
7. Run `lod_rpg_validate` when applicable.
8. Finish with `lod_rpg_test_finish <task-label>` so canonical RPG evidence is republished.
9. Inspect the resulting evidence itself before claiming the runtime gate passed.
10. Capture a screenshot only when visual/layout/rendering evidence adds information that logs cannot establish.

The canonical runtime files are defined in `docs/TEST_LOGGING.md`. The audit-bundle script automatically copies the usual current evidence from `garrysmod/data/legend_of_deborah/` when present.

A log-provable mechanical behavior should not be accepted solely from visual observation. Conversely, a visual-quality judgment should not be pretended to be mechanically proven by logs.

## 6. When human testing is still required

Escalate to Shael rather than fabricating confidence when the gate requires:

- subjective visual, audio, feel, readability, or aesthetic judgment;
- a genuinely second human or multi-client interaction that Antigravity cannot reproduce faithfully;
- hardware behavior inaccessible to Antigravity;
- an interaction Antigravity cannot execute reliably after a bounded attempt;
- a security-sensitive action involving private credentials or secret-bearing diagnostics.

Human testing is an exception path, not the default routine QA path.

## 7. Runtime evidence discipline

Use `docs/TEST_LOGGING.md` as canonical evidence procedure.

Default evidence for RPG/Gate-E work:

- `console_latest.txt`
- `rpg_summary_latest.txt`

Add `rpg_session_latest.txt` for timing, event-order, or unexplained behavior. Screenshots are supplemental for visual defects.

Do not claim PASS while the evidence contains an unexplained contradictory error or failed validator relevant to the task.

Never include secret-bearing full process command lines. In particular, do not expose the private Steam GSLT or other credentials.

## 8. Audit bundle

After each exchange, run:

`./tools/dev/make_antigravity_bundle.sh <TASK_ID> [VALIDATION_LOG] [AGENT_REPORT]`

The ignored `antigravity_bundle/` directory contains the review package. Its core files are:

- `00_manifest.txt` — bundle contents and runtime-evidence count;
- `01_state.txt` — branch, SHAs, divergence from `main`, status, recent commits;
- `02_changes.txt` — branch diff summary and current-commit file inventory;
- `03_validation.txt` — mechanical repository checks plus the optional agent-supplied validation transcript;
- `04_agent_report.md` — constrained Antigravity report;
- canonical Garry's Mod runtime evidence files when present;
- one explicitly selected runtime screenshot when supplied through `LOD_RUNTIME_SCREENSHOT`.

The bundle is review evidence, not source code, and must never be committed.

## 9. Report rules

Use `tools/dev/antigravity_report_template.md`.

The most important fields are:

- Design decisions made
- Assumptions made
- Human-only validation still required
- Known failures
- Known uncertainties
- Out-of-scope changes

Prefer `None` only when it is literally accurate. Reporting an assumption is better than silently encoding it in code.

## 10. Review outcomes

Sol/Astra will adjudicate each batch as one of:

- **PASS** — evidence supports the finite gate; proceed to the next assigned batch.
- **PASS WITH FOLLOW-UP** — the batch is accepted but leaves a bounded nonblocking item.
- **REPAIR REQUIRED** — remain on the same task and correct the defect.
- **REJECT** — the batch is unsuitable; preserve evidence and follow explicit rollback/recovery instructions.

Antigravity must not self-promote a batch to `main` regardless of its own confidence.

## 11. Promotion to main

Promotion is a separate Sol/Astra-controlled release gate. Before merging, the reviewer should compare the complete hybrid branch against the then-current `main`, review the accepted batch history and runtime evidence, run any necessary regression gates, repair genuine defects, and only then merge or otherwise promote the reviewed commits.

The public server continues to consume `main`; therefore experimental work remains inert with respect to the public deployment until explicitly promoted.
