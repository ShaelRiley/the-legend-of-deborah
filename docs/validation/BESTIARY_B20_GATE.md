# B20 finite gate — authored before implementation

Scope: a production EncounterDirector dungeon motif and campaign-memory selection
path over existing authored templates. Six tactical motifs restrict discretionary
roster availability; common templates are safety fallbacks, objectives unchanged.
Recent theme exclusion (last two dungeons), recent template/enemy/family penalties,
unseen-content pressure and within-dungeon template suppression replace duplicate
selection tickets. Existing sector/role eligibility and physical admissions remain.
No enemy additions, wanderer changes, density/elite/reinforcement tuning, new
macro-pacing, new topology classifiers, loot/events or later audits in this slice.

RunManager owns a bounded history receipt, committed only after the complete maze
build succeeds. Planning does not advance history. Cleanup preserves it; new
campaign state resets it even with the same seed. A same-level rebuild replaces
its receipt from the same pre-level history. Stale plans cannot commit into a new
campaign/level/graph. No entity or graph references belong in history.

Validation: actual planner and lifecycle boundary tests, repeatability and RNG
isolation, preserved objective and budget/hostile ceilings, exact old eligibility
membership after duplicate-ticket removal; deterministic 32-campaign x20-dungeon
sample with parties1–4. Require all six motifs in aggregate, no motif repeating
within two successful levels, each campaign at least36/54 sampled specialist
identities planned, every sampled specialist >=25 planned /20 physically legal /
5 sector1–2 appearances across sample (same exposure floors as B19). Measure
coverage, family/template frequency, consecutive-level roster overlap, same-theme
streaks, template repeats and history-enabled vs memory-disabled comparison.
Retain the B19 512-plan baseline and any B20 failed trials; explicitly distinguish
new campaign metrics from old independent-floor measurements. Native Source
collision, balance and perceptual variety remain unobserved.

Final gate: canonical tools/test_checkpoint_g_integration.py; update explicit
validator registry, live GDD00/01/05/06/07, manual, ledger, plan and handoff;
commit and verify non-forced main push. Bestiary whole-phase exit remains pending
for topology-aware composition, macro-pacing and full ecology including wanderers.
