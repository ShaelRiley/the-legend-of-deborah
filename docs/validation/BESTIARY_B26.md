# Bestiary B26 — Production population recovery

Author report: dungeons feel empty; encounters are mostly Shamblers, Runners and
Soldiers, with only one or two other types. Audited source baseline:
`3f86f99630178df667a8ac3c3410a618931a5962` (main).

## Findings and remedy

1. **The entire final exploration sector was rejected.** The real Neil/Gordon
   progression adds a fourth (Black) gate and moves CoreCell into Gordon's reserved
   court. The encounter sector map excludes that court, but B22 still tried to
   reach CoreCell while staying in sector four. Every cell in the sector acquired
   disconnected/unreachable pacing and lost both ordinary encounter and roaming
   home eligibility. Use `Gates[4].beforeCell` instead; retain CoreCell for genuine
   legacy three-gate graphs. No gate is unlocked or navigation check bypassed.
2. **Release budgets/slot counts were too sparse.** Old threat budgets were
   4/6/8/9, with at most 1/2/2/2 discretionary encounters per sector. Developer
   mode doubled budgets and loosened spacing, hiding the release baseline.
   The author-requested retune is 8/16/18/20 threat and 2/4/4/4 separate encounters.
   Opening-sector pressure stays lower. Existing squad compositions and party
   scaling are unchanged; this is not a blanket horde-size multiplier.
3. **Core-only homes could exhaust the remaining budget first.** Most specialist
   templates require arena/ambush homes. Stable-partition the already seeded
   candidate order to offer those roles before travel/reward fallback homes,
   still within existing probe/pressure/spike passes. Physical preflight,
   singleton specialists, companions, spacing and native revalidation remain.
4. **Previous coverage did not reproduce current production topology.** B20–B25
   campaign fixtures exercised the base three-gate progression with gates open,
   without the Neil/Gordon wrappers. Their many-campaign exposure results did
   not certify fresh, closed-four-gate per-dungeon diversity or native sightings.
   B26 explicitly loads both wrappers and keeps all four gates closed.

The larger roster is wired into the unified spawner. Missing includes and the
obsolete three-ID base spawner were checked and are not the production cause.
Roaming remains its deliberate 14-identity subset; support/trap/companion actors
are not made solitary wanderers. No enemy attack, health, tier, XP or drop change.
Preserve MajorSpacingCells=4, active target80/hard ceiling96, the original motif
roaming targets/probabilities/cadence and all boss/progression reservations.

## Paired evidence

Sixteen fixed campaign seeds `sample*7919`, solo Dungeon1, actual four-gate
progression and all gates initially closed. `tools/measure_bestiary_population.lua`
is compatible with baseline and repaired source. Run with
`python3 tools/run_lua54.py tools/measure_bestiary_population.lua`.
The early `specialists` output label means bodies outside exactly
Shambler/Runner/Soldier, not exclusively B1–B19 additions.

| Measured planned quantity | Baseline | Endpoint only | Endpoint + budgets | Final repair |
| --- | ---: | ---: | ---: | ---: |
| Sector4 pacing ready | 0/16 | 16/16 | 16/16 | 16/16 |
| Discretionary encounters, total | 59 | 96 | 199 | 189 |
| Mean discretionary encounters/dungeon | 3.6875 | 6 | 12.4375 | 11.8125 |
| Distinct non-core types, per-dungeon sum | 36 | 55 | 104 | 130 |
| Mean distinct non-core types/dungeon | 2.25 | 3.4375 | 6.5 | 8.125 |
| Non-core bodies, total | 47 | 81 | 173 | 174 |

Final per-dungeon minimum non-core type count5, versus1 at baseline. All six
motifs appear. The final dedicated regression records631 planned squad bodies
and654 initial roaming spawns across the16 samples; these are aggregate headless
counts, **not simultaneous populations, native sightings or player experience**.
Different plans can still have different densities, and physical admission may
safely defer or replace a planned actor.

## Validation

`tools/test_bestiary_b26.lua` passes20 production-layout plans plus same-seed
replays: the16 primary samples and additional Dungeon8/two-Hero and Dungeon20/
four-Hero cases. It checks closed/open gates, restored endpoint, boss/safe/quiet/
recovery reservations, budgets/spacing/singletons, actual roaming spawn admission,
release/dev separation and read-only observation. Native physics/entities are
boundary doubles. Historical campaign seeds/exposure thresholds and spacing assertions were not weakened.

Canonical integration: final outcome is recorded in
`BESTIARY_B26_INTEGRATION.log`; publication is gated on completed validation.
No native Source acceptance or Workshop/VPS deployment is claimed.

Fixture-development corrections before the final targeted run: numeric config
comparison replaced a Lua integer/float string-format comparison; the production
Warden include needed the standard `istable` boundary double. An interrupted
fixture invocation was not counted as a pass. The production regression is a
fixed bounded20-plan sample, with the historical larger campaign gates retained.
The first full matrix exposed B21's old-budget control assumption: with spacing
on it still admitted exactly1 encounter, while disabled spacing now admitted4,
not the fixture's expected2. The fixture now explicitly sets its original6-threat,
2-slot sector budget for BOTH arms and restores release tuning afterward. Both
original exact-count assertions remain intact; the corrected B21 rerun passed.
This is a test-isolation correction, not a production spacing relaxation.

Per-seed before/final measurements are in `BESTIARY_B26_SAMPLES.csv`. The response
archive `LoD-B26-audit-evidence.zip` retains full raw baseline, intermediate,
final, targeted, initial integration and fixture-correction output. The repository
integration log is an explicitly labeled evidence summary, not rewritten raw
stdout. See it for completed counts and exact raw-output hashes.

## Native acceptance and handoff

The live GDD05/07 contains the author-requested B26 repair/tuning, and the manual
now explains per-dungeon group selection and the populated pre-Black hunt.
`lod_population_status` is a normal-release admin/server diagnostic. It reports
`revision=b26`, developerDense, sector pacing/counts/budget, original planned
composition, current composition after safety substitutions, and living actors
separately. It does not spawn, clean up, consume RNG or rewrite the plan.

After installing this revision, on a disposable local test run:

```text
lod_developer_mode 0
lod_regenerate
```

Regeneration replaces the current dungeon and marks the run unranked. Once the
build is ready, use `lod_population_status` and `lod_encounter_distribution`, then
play through all gates and the Neil/Brute hunt normally. Confirm revision b26,
developerDense=false, sector4 pacing ready, meaningful non-core sightings and
separate fights, no unsafe substitutions/softlocks, and acceptable frame time.
Capture console/RPG evidence; repeat with a teammate. An existing already-planned
dungeon does not retroactively acquire the repair. Do not treat a planned roster
as proof that those actors spawned or were encountered.

Preserve the release order: local acceptance of this candidate, matching Workshop
publication/parity, then VPS deployment with persistent data/configuration and
rollback. Prior build acceptance is historical, not acceptance of B26. Deferred
Low-End PC Optimization (September28–October4), Big Loot, Event System and the
comprehensive systems audit stay deferred; retain P1–P4 and approved Crate assets.
