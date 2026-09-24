# Handoff — Bestiary B17

Resume **The Legend of Deborah** and complete **Bestiary checkpoint B17 only**,
including authorized design, implementation, validation, documentation, commit
and verified non-forced push to `main`.

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`.
Latest checkpoint: **Add Bestiary Halter and Pacer movement discipline**.
The publication response supplies the exact verified SHA; fetch current main,
confirm this checkpoint and preserve intervening work. B16's parent is
`5f817c2eb3e99a14156fd3d783359a998d4f5fbb`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

I authorize implementation, necessary refactoring, design/tuning decisions,
compatible existing assets, naming, UX, tests, diagnostics, documentation, live
GDD amendments, focused parallel delegation, commits and non-forced pushes to
main. Resolve ordinary ambiguities. **Do not deploy to the VPS or publish to
Steam Workshop.**

Read AGENTS.md, the active/newest DEVELOPMENT_PLAN.md checkpoint, this handoff,
BESTIARY_EXPANSION.md and briefs/BESTIARY_UPDATE.md. Live GDD00→01→needed tabs,
including LOD-ROADMAP-ECOSYSTEM-001 and relevant LOD-BESTIARY rules through
B16-001. Exact HUMAN anchors only for required missing detail. Missing historical
art is not blocking. No chat archaeology or repeated broad audit.

## Current B16 implementation

Halter/STOP and Pacer/KEEP MOVING warn1.6s and judge the final0.4s against25% of
canonical legitimate walk speed. Every FinishMove observation passes through the
existing DodgeMovement qualifications into a bounded exact-demand observer;
there is no second movement classifier. Any violation permits one physical1d6+2
hit; require≥0.3s distinct coverage, no sample gap>0.15s and final sample within0.1s.
Unknown/stale/forced/non-walk/movement-prohibited Hero state cancels, including
recently expired force samples. Range360/same legal supported cell; obey, break
cover/range/cell or interrupt. Source Held/Muted permit stationary physical actions;
morale/hit-stun/attack prohibition cancel. Actual Hero-hull escapes/support,
fixed deadlines/recovery, exclusive per-Hero reservation across both modes,
cap16, exact source/Hero progression/status-life and dungeon/campaign ownership.
The existing native packet guard validates single admission and exact
recipient/attacker/inflictor across mitigation; no B15 faction permit is granted.

Production singleton Halter+Soldier and Pacer+Runner, append ordinals54/55,
registry57 normal+4 named bosses. Full/reduced literal instruction, distinct
glyph/countdown/final-judgment cue and server-snapshot tether. Manual160chapters/
32chunks. Frozen baseline18, target63; **57/63 implemented,39/45 additions,
6 remaining**. No cosmetic/affinity/boss/event/summon inflation. Native acceptance
remains pending.

## Complete B17 — next remaining-roster cohort

Select two underrepresented tactical identities through a targeted ledger/shared-
authority gap review. Author finite counterplay, tuning and production gates
before implementation. Target59/63 only if both meaningfully qualify; prefer
new interaction/topology decisions over copies of prior cohorts. Preserve
solo-safe geometry, exact-life ownership, canonical combat/status/progression/
rewards and bounded service. No private pools, permanent losses, hidden tracking,
unavoidable control/damage or extra bodies. Remaining breadth and whole-phase
campaign-aware encounter themes/novelty/topology/pacing remain inside Bestiary.
Do not begin Big Loot or Events.

Preserve prior cohorts, bosses, Gordon→Hector→Deborah, sole staging successor,
Abundance and Level21 cash. B4 Block remains one capped roll; B5 released shots
survive ordinary interruption but retire on life replacement; B6 traps disarm on
interruption/support loss; B7 beats/backstep/recovery cannot extend or catch up;
B8 only sealed defeat receipts burst; B9 canceled channels cannot create pulls/
guards or transfer screens; B10 stalls cannot catch up motion/damage or leave
trails; B11 has no hidden pursuit/camera checks/stale hearing/cloaked memory or
morale suppression; B12 no replacement ailments/lives/reservation theft or enemy
hulls for Hero escape; B13 no warning transfer/spent pinned links/newer-attack
erasure; B14 no overdraw/repeat debit/drain/refill/replacement-pool transfer or
cast feats from drain/recharge; B15 exact packet-only allied fire, first-body/
world cover, simultaneous admission and no fabricated Hero XP; B16 no opposing
orders, skipped inter-service motion samples, forced/stale motion judgments,
failed-authorize damage, replacement-life warning/damage, new-token erasure,
late/catch-up judgment or extended error recovery. No duplicate authorities.

## Validation truth and cadence

One fresh canonical run passed **all197 suites with zero failures** after final repairs; no gameplay/config/test edits followed. Full result and matrix: validation/BESTIARY_B16.md and
BESTIARY_B16_INTEGRATION.txt. Three new B16 suites cover behavior/production/
visuals. Unchanged512 plans/32 mazes/parties1–4/dungeons1–5 produce4939 encounters;
all48 sampled identities pass25planned/20legal/5early; Halter30/28/5 and
Pacer33/33/6. All four trials (three failures), exact initial four tickets each
and fixed-length donor transfers are preserved in BESTIARY_B16_EXPOSURE.md.
Do not resample without changed selection risk. Preserve validated ticket order;
whole-phase campaign-aware director redesign is still required. Live GDD
00/01/03/05/07 authored design/tuning/evidence/continuation are read-back verified
in the checkpoint record. Boundary doubles are not Source observation/acceptance.

Reserve final third for validation, repairs, documentation and publication.
Targeted tests while editing, then one coherent canonical run:
`python3 tools/test_checkpoint_g_integration.py`. Repair attributable failures;
broaden only for concrete shared-authority risk. Update/read-back verify live
GDD, manual, ledger, plan and handoff with counts/evidence/native checks/next slice.
Keep explicit progression validator registry synchronized with all IDs.
Commit and publish immediately after green validation.

After ordered phases, test gm_flatgrass actual STOP/GO timing/motion/force/Held/
slow/crouch, real support/hulls/gates/Walls/false floors, Block/Dodge/HP/XP/drops,
full/reduced warnings/audio, death/revival/disconnect/late join, freeze/reset/
same-seed rebuild and1–4-player network/balance plus prior cohorts and complete
campaign. Evidence console_latest.txt+rpg_summary_latest.txt; session log only
for ordering. No human runtime or deployment gate precedes the ordered phases.

If CLI push credentials are unavailable, use authenticated GitHub blob/tree/
commit/ref tools; verify every blob and exact complete tested tree, advance main
non-forced, fetch and verify SHA/parent/tree. Preserve newer work; never force.
Order: Bestiary→Big Loot→Event System→systems integration/emergence audit→low-end
PC performance audit→final crash/progression-safety audit→human playtest.
Finish B17 only. End with verified SHA, scope/tests/progress/native checks and
next continuation prompt.
