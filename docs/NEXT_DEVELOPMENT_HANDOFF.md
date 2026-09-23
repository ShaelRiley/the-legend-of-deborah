# Handoff — Bestiary B1

Resume development of **The Legend of Deborah** and complete **one substantial,
bounded Bestiary checkpoint**, including validation, commit and verified non-forced
push to `main`.

Repository: `ShaelRiley/the-legend-of-deborah`.
Last gameplay checkpoint: `b8c737d27386be9ff5d74e53e39eaf94a9e5875c`,
`Add Deborah finale celebration and campaign-bound staging succession`.
A subsequent documentation checkpoint establishes this roadmap; verify current
remote main before editing and preserve all intervening work.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

## Authorization and phase order

I authorize implementation, necessary shared-authority refactoring, game-mechanics
and tuning decisions, compatible existing/base-game assets, naming, UX, tests,
diagnostics, documentation, live GDD amendments, focused parallel delegation,
commits and non-forced pushes directly to main. Resolve ordinary ambiguities.
Do not deploy to the VPS or publish to Steam Workshop; never overwrite newer work,
force-push, expose secrets or weaken acceptance to obtain a green result.

The required order is **Bestiary Update → Big Loot Update → Event System Update →
full systems integration/emergence audit → low-end PC performance audit → final
crash/progression-safety audit → my human playtest**. Complete each major phase
through significant, independently bankable chunks. Outstanding native acceptance
remains documented and does not block this authorized development sequence.

## Recover efficiently

1. Verify remote main and working-tree state. Read AGENTS.md and the active roadmap
   plus newest checkpoint in docs/DEVELOPMENT_PLAN.md.
2. Read docs/briefs/BESTIARY_UPDATE.md. The other complete source briefs are retained
   alongside it; do not audit those systems now. Historical SHA/roster examples
   are not the current baseline.
3. Follow live GDD 00 → 01 → only relevant subsystem tabs, including
   LOD-ROADMAP-ECOSYSTEM-001; retrieve exact HUMAN detail only where necessary.
4. Inspect actual normal-enemy definitions, shared AI/combat/status authorities,
   encounter placement/admission, lifecycle and relevant tests. Reuse completed
   work and existing diagnostics. Missing historical chats/images are unnecessary.

## B1 deliverable

Establish and record the gameplay-meaningful normal-enemy baseline, counted IDs,
inclusions/exclusions, tactical gaps and approximately 3.5× whole-phase target.
Freeze that baseline; cosmetics and trivial numerical permutations do not count.

Choose and implement a coherent first cohort of several tactically distinct enemy
identities using existing mechanics and assets. Add only necessary shared
support; integrate the cohort into valid production encounter/placement paths.
Deliver playable behavior and meaningful tests, not just a taxonomy or unused
registry. Select a scope large enough to matter and small enough to finish this
session. Complete only B1; do not attempt the entire 3.5× expansion, director
overhaul, Big Loot or Event Update in the same checkpoint.

Preserve canonical combat/status/XP/drop authorities, faction unity, deterministic
RNG isolation, topology and progression safety, active-hostile ceilings, equipment
and multiplayer lifecycles, Gordon → Hector → Deborah, the finale, the sole
Deborah staging successor/Abundance, and Level21+ SECURE THE BAG.

Prove distinctive tactics, production selection and placement, authoritative
combat/rewards, bounded workload, death/disconnect/reset/partial-spawn cleanup and
same-seed reproducibility. Record substantive decisions in the live GDD and
verify readback. Update the manual for player-facing changes.

## Bank the result

Reserve roughly the final third of the session for validation, fixes, documentation
and publication. Stop adding scope when that reserve is reached. Use targeted tests
while editing; once coherent, run:
`python3 tools/test_checkpoint_g_integration.py`
Fix attributable failures without bypassing real boundaries. Avoid repeated full
runs unless a remaining shared-system risk requires them. The inherited baseline
is 156 passing suites; native acceptance remains pending, not implied by mocks.

Update DEVELOPMENT_PLAN.md with B1 scope, count against the frozen target, evidence,
remaining native checks and a concrete B2. Preserve the ordered roadmap. Commit
and publish immediately when green. Recheck remote main; if CLI credentials remain
absent, use authenticated GitHub blob/tree/commit/ref operations with a non-forced
update and exact tested-tree verification. Fetch and verify afterward.

End with the verified SHA, implemented scope, test result, expansion progress,
remaining native checks and next bounded checkpoint. Do not begin B2 in this turn.
