# Bestiary B21 — topology-aware composition and spatial pacing

Base: verified remote main `27853c2f7fde54ad377c86c398456b5b9ba33ce8`.
Scope and finite gate authored before gameplay edits in BESTIARY_B21_GATE.md.
Roster remains63 normal+4 named; frozen baseline18,45 additions. No new enemies.

## Implemented result

The existing EncounterDirector now consumes traversable geometry during motif
selection. Existing EnemyRoster.Placement filters specialist templates before
weighting; only an empty admitted motif permits common fallback. Physical checks
are repeated at actual spawn, retaining ordinary-body substitution if geometry
changes. No cohort's physical escape or role/sector restriction was loosened.

Topology preferences use legal same-sector planar approaches, corners/junctions,
straight corridor reach (up to3 edges), a clear240-unit firing ray at48-unit
height along that same corridor, the existing conservative256-node same-floor
alternate-route proof, vertical edges at/one planar neighbor from the candidate,
and navigable objective distance. Locked gates and event-blocked edges are not
traversable; disconnected stacked cells do not imply vertical access. Existing
specialist landing/transition exclusions still apply. Navigator and EnemyRoster
remain the traversal and admission authorities; no parallel topology is created.

Apply the strongest qualifying multiplier, never stack them:

| Tactical role | Geometry | Multiplier |
| --- | --- | ---: |
| Ambush | Corner | 2 |
| Pursuit | Proven alternate route | 2 |
| Climber | Reachable vertical approach | 2 |
| Line fire | At least2 straight edges, same-direction physical lane | 2 |
| Area/trap | Two planar exits, no proven alternate | 1.5 |
| Support/companion | Junction or objective distance4–6 | 1.5 |
| Control/position/projectile/reaction/melee | At least2 planar approaches | 1.25 |
| Other | Any otherwise eligible/admitted candidate | 1 |

Ignore basic escorts when evaluating specialist squads; common squads score
all members. Keep B20's theme, novelty and independent per-cell RNG authority.
Selection diagnostics report measured geometry, preference and rejected templates.

**Spacing defect repaired:** the previous planner prefiltered each sector's
candidate list before placing any discretionary encounters. It did not recheck
that list after placement. Now every admission rechecks minimum4 graph cells from
all prior encounters, including objectives. This creates actual spacing between
home positions without changing objective fights, threat scaling, maxima,
first-encounter exception,0.5 allowance or target80/ceiling96. Pursuit/wanderers
can still converge; this is not a global promise of quiet space during combat.

## Automated evidence

One fresh final canonical run passed **all210 suites with zero failures**; no
gameplay/config/test edits followed. Complete terminal matrix is retained in
BESTIARY_B21_INTEGRATION.txt. All engine traces/entities remain boundary
doubles; no Source runtime observation or acceptance is claimed.

- New B21 production fixture suite covers actual graph topology, closed gates,
  blocked event edges, loops versus branches, vertical reach, objective distance,
  obstructed firing lines, and real selector outcomes with equal history/RNG.
- Physical rejection removes unsafe specialists, common fallback remains legal,
  later clear geometry is re-evaluated, and actual spawn repeats admission and
  substitutes ordinary bodies if the geometry becomes blocked.
- Stale-candidate regression forces a short candidate corridor: one placement
  under production spacing, two affordable placements with spacing disabled.
  The test explicitly proves affordability, so budget refusal cannot hide the bug.
- Real generated closed-gate planning repeats deterministically with bounded
  threat, current spacing and admitted templates. B20 receipts/lifecycle continue
  to cover failed builds, rebuild/override, new campaign and Level21 history.
- Existing32x20 sequential paired campaigns retain every threshold and seed.
  Added spacing and full-template physical admission assertions run on both
  memory and control plans. The control forwards graph/cell context so both use
  identical topology and differ only in template-history scoring.
- Existing512 independent plans retain all geometry/companion/singleton checks.
  All prior combat/status/HP/XP/drops, bosses, finale, succession, Abundance and
  Level21 regressions remain in the canonical gate.

## Measured campaign sample

BESTIARY_B21_CAMPAIGN_INITIAL_LOG.txt and BESTIARY_B21_CAMPAIGN_INITIAL.txt
retain the complete targeted campaign sample. Same32 campaigns x20 dungeons,
parties1–4,60 themed+6common template providers, canonical layout retries.

| Metric | Memory | Same motif schedule, template history disabled |
| --- | ---: | ---: |
| Encounters | 6232 | 6242 |
| Mean specialist coverage /54 | 47.562 | 40.750 |
| Minimum campaign coverage /54 | 43 | 35 |
| Cross-level template returns | 164 | 277 |
| Within-level template repeats | 571 | 574 |
| Exact consecutive template sets | 0 | 0 |
| Consecutive roster Jaccard | 0.206213 | 0.199360 |

All54 specialists pass25planned/20legal/5early. All six motifs occur with counts
109/104/114/99/106/108 and no repeat within two committed dungeons. Mean coverage
is16.72% above paired control. Compared with B20's historical48.500/min41,
mean coverage falls slightly and minimum coverage rises; B21 is not a claim of
improvement on every diversity statistic. Native sightings remain unmeasured.

Of4312 discretionary memory selections,2372 receive a topology preference:
alternate194, chokepoint107, corner103, firing lane689, maneuver1107,
support approach168, vertical4;1940 remain neutral. Those selected-candidate
preflights reject432 motif templates. This count excludes rejected candidates
which never became encounters. All sampled pairs satisfy current spacing and
all selected specialist compositions pass the existing physical admission.
The final same-direction firing-lane refinement leaves this sample's uniform
240-unit-clear trace behavior unchanged; the final integration reruns the same
campaign gate against final production code.

## Retained failed/incomplete evidence

1. BESTIARY_B21_BOOTSTRAP_FAILURE.txt: new topology code initially appended cell
   objects instead of keys to its planar-exit list; repaired before campaign work.
2. BESTIARY_B21_TARGETED_CONTROL.txt: initial counterfactual spacing fixture failed
   to prove its second randomly selected squad was affordable. Restricting that
   fixture to the real patrol template isolates spacing without changing production
   tuning or thresholds. BESTIARY_B21_TARGETED_FINAL.txt passes the corrected test.
3. BESTIARY_B21_INTEGRATION_ABORTED.txt is the untouched empty redirected output
   of a prematurely launched buffered integration attempt, interrupted via SIGINT
   (exit130) after the fixture failure was noticed. It supplies no acceptance
   evidence. The final run uses unbuffered output and a complete terminal matrix.

## Design, manual and continuation

Live GDD00→01→05/06/07, LOD-BESTIARY-B21-001. Initial trusted read found no
protected controls; narrow connector readbacks confirm implemented design/tuning.
Final evidence and routing readback are recorded after the canonical gate.
Manual remains164 chapters/32chunks; source SHA256
`f8b7f1f650e15ea43458cd245f1d0ab9d2ea8fc3d79e6afb743eccf1f101c808`.
The existing ecology chapter explains geometry preferences and home spacing.
No extra actor IDs or progression registry changes are needed; new suite is
registered in the canonical integration runner.

Next B22: bounded macro-pacing through the existing EncounterDirector. Author
finite phrases of quiet/probe/pressure/recovery and optional/objective context,
with deterministic campaign proof and unchanged entity/threat/progression limits.
Wandering-population ecology and whole-phase exit proof also remain Bestiary
obligations. Do not declare Bestiary complete or begin Big Loot/Events/audits.

Native checks after all ordered phases/audits: gm_flatgrass actual motif/topology
recognizability, collision/support/escape at gates/stairs/Walls/false floors,
actual placement and ordinary substitutions, pursuit/wandering convergence,
full/reduced tells/audio,1–4-player network/balance, lifecycle/late join/reset and
Gordon→Hector→Deborah/staging/Abundance/Level21. Evidence console_latest.txt plus
rpg_summary_latest.txt; session log only for event order. No VPS/Workshop changes.

Final connector readbacks verified all00/01/05/06/07 B21 rules, current210-suite
result and B22 continuation. Final live revision:
`ANLCKQkNGJISQUMuPGTXYWHakUcanNFon2WafOnfmOfQ09t0QHqx_qiiIO0BlmnDsZ4PX4WGFBQfgzhv7Aqn77qGsjpsGZmkCBBLQaGw1A`.
