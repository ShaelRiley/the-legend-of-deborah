# Bestiary B27 — Inhabited adventure pacing

## Author direction and scope

B26 was directionally correct but insufficient: many varied wandering monsters,
more frequent directed encounters, and the original NES Legend of Zelda as the
qualitative pacing inspiration. Target recurrent small tactical contacts,
exploration, reward and brief respite, rather than continuous hordes or long empty
traversals. No measured Nintendo timing or literal screen-to-cell equivalence is
claimed. Baseline: main `0084bbbad45e44c8f753ff25b7a13cda2a58b743`.

This is the explicit population/pacing follow-up, not the deferred comprehensive
systems audit. Existing directors, navigation, MotionV2, combat, tiers, rewards,
progression, lifecycle and resource ceilings retain authority. No new enemy
identity, asset dependency, damage/HP multiplier or per-enemy service is added.

## Why B26 still felt empty and repetitive

B26 intentionally did not change roaming. Its six motif pools admitted only
3–6 different roaming identities per dungeon, despite a14-identity total pool.
Some motifs allowed just one specialist identity, with a one-per-floor identity
limit and a four-specialist total cap. The64-body global capacity was not evidence
that players would see a varied, locally active population.

Percentage-based pacing reserved entire long route projections and their side
branches. Random home selection could emphasize remote branches over the route
players actually needed. Initial native creation failures were treated like
ordinary deaths and inherited the slow20-second probabilistic replenishment path.

The deeper audit also found two real movement gaps. A legal standing-room home
could have no permitted initial patrol edge. Separately, pursuit/perception AI
could receive a valid patrol route but return through encounter-only idle behavior
before consuming it. Counting created actors or routes alone did not establish
moving wanderers. The corrections and their distinct tests are below.

## Implemented changes

### Roaming variety and actual motion

Every recognized motif now biases a common audited32-identity autonomous pool;
it no longer strictly excludes all identities outside its small motif list.
Favored identities have weight6 and other audited identities weight2 before
existing prevalence/no-immediate-repeat handling. Unknown motifs retain the
actual legacy fallback. Unregistered or injected identities cannot bypass the
explicit autonomous eligibility set.

Audited identities: Shambler, Runner, Soldier, Deadcrab, BioBlaster, Watcher,
Seeker, Flamer, Siphoner, Caromer, Reaper, Redliner, Drubber, Afterburst, Blitzer,
Sniper, Razor, Arc Caster, Gaoler, Silencer, Repulsor, Pincer, Harrier, Waylayer,
Pavise, Repriser, Reeler, Forker, Fencer, Listener, Shy and Accumulator.

At most eight non-basic roamers per floor and one living roaming instance of
each non-basic identity. Reaper/Drubber/Caromer/Afterburst may enter sector1
arena/ambush homes; other new specialists retain sector2+ tactical homes.
Flamer retains sector2+; the five basics, Watcher and Seeker retain ordinary
eligibility. Every applicable native placement/escape/role restriction remains.
Stationary, ceiling/wall-attached, ally-dependent, corpse-dependent, boss and
event-only actors are not indiscriminately turned into solitary roamers; they
remain available through directed encounters or their existing special owners.

Spawn homes must have a traversable same-floor first patrol edge to a non-safe,
non-stair neighbor. Actual target-free Pincer/Harrier/Waylayer AI now consumes the
existing roaming route. Listener can patrol with no auditory target. Shy can
patrol only while unwitnessed, retaining its observed stop and original sensory
attack acquisition. Sensory investigation and attack tells, fixed recovery,
interruption, control permissions and authored non-wandering behavior remain.
Ambient patrols never acquire hidden Hero positions.

### Population and replenishment

Motif targets are20/floor for Hunting/Occupation and18 for the other four motifs.
The actual floor target is capped at20 and floor(64 / physical wandering floors),
so four-floor layouts still cap at16/floor and the private boss gallery never
creates another roaming allocation. The hard global hostile ceiling remains96;
normal hostile target80 and named/progression reservations remain unchanged.

Track uncreated initial seats separately from combat deaths. After the bounded
initial attempts, retry at most one uncreated seat per floor per second. No
catch-up, nearby-Hero fallback, stale-owner revival or death-triggered instant
replacement. Once initial seats are created, ordinary deaths retain their exact
20-second opportunities and motif probabilities, with existing endless scaling.
Blocked native hulls/floors still defer, and the release census now discloses each
floor's actual population, target, deficit, pending initial seats and admission
results. Diagnostics do not mutate population or consume RNG.

### More contacts, not larger hordes

Reaper/Drubber/Caromer/Afterburst also enter sector1 arena/ambush directed
selection through their original templates, matching their early roaming
eligibility. This repairs motifs whose opening selection was otherwise forced
into core-only fallback groups. All other specialists retain prior directed
eligibility; original singleton/companion and native placement rules remain.


Sector directed budgets:12/24/27/30, formerly8/16/18/20. Maximum separate groups:
4/6/6/6, formerly2/4/4/4. Preserve4-cell major spacing, existing full template
compositions, singleton specialists, companions, probe scaling and objective
fights. No blanket body-count multiplier inside each squad.

After existing seeded ordering, distribute candidate homes across four route-
progress bins and prefer two near-route homes (branch detour<=3) for each deeper
branch home when available. Apply this through current pacing passes and roaming
candidate selection. Cap entrance quiet and goal recovery projections at two
route cells each. Deep branches (detour>=4) can become spikes even if their
junction projects into respite. Protected start/checkpoint/resupply/boss/objective/
transition homes remain excluded. Gates, disconnected routes and the B26 Black-
Gate endpoint fix remain intact. These are spatial preferences, not timers that
spawn enemies whenever the player has been unoccupied for a prescribed interval.

## Matched production measurements

Sixteen fixed solo Dungeon1 campaigns, seeds sample*7919, all six motifs, actual
Neil/Gordon four-gate generation, gates initially closed. Both arms use the same
measurement script; native entities, hulls and support are boundary doubles.

| Measure | B26 baseline | B27 candidate |
| --- | ---: | ---: |
| Mean separate directed groups, excluding objectives |11.8125|18|
| Mean created initial roaming bodies |40.875|52.25|
| Mean distinct created roaming identities |4.25|18.25|
| Range of distinct roaming identities/dungeon |3–6|15–22|
| Initial bodies created / target, all samples |654/656|836/842|
| Required-route positions within2 graph edges of potential contact |909/1562|1174/1562|
| Potential route-contact coverage |58.19%|75.16%|
| Mean longest uncovered route run, cells |9.875|7.75|
| Worst uncovered route run, cells |19|24|

A potential contact is a planned encounter home OR an actually created initial
roaming home, not a sighting or combat event. These measures do not certify
perceived timing, pursuit convergence, native motion, co-op balance or frame time.
Five individual samples have longer maximum uncovered runs, and the worst
case increases19→24 cells despite the aggregate improvement; there is no universal per-seed improvement claim. Six initial seats
remain safely uncreated in the candidate and are eligible for the bounded retry,
not silently counted as enemies. See `BESTIARY_B27_SAMPLES.csv` for every pair.

## Validation and retained failures

Final canonical matrix outcome and exact frozen-source receipts are in
`BESTIARY_B27_INTEGRATION.md`; all raw logs are in the response evidence archive. No native acceptance or
Workshop/VPS publication is implied.

B27 exercises all32 actual placement/spawn paths and shared patrol compilation,
all6 full motif pools, unauthorized-ID exclusion, floor/global caps, initial-seat
failure/retry/death separation, no catch-up, freeze/inactive/reset, diagnostics
purity and seeded candidate membership/order. B3/B11 additionally exercise the
actual AI dispatch for the five identities whose specialized controllers could
hold despite a route; Shy's witness stop and recovery are explicit assertions.
Existing B3/B11 combat, controls, lifetime and MotionV2 proofs remain intact.

The first complete canonical matrix finished222/223 passing; the only failure
was B20's unchanged minimum25% reduction in consecutive-dungeon template returns.
Initial candidate1041 vs1161 yielded10.3359%; an isolated0.001 recent-weight trial
still failed at975 vs1161 (16.0207%). That scalar-only trial was rejected. The
existing0.10 penalty remains; the four explicit early directed identities instead
remove core-only opening restrictions. The corrected640-dungeon comparison passes
at113 vs223 (49.3274%), all54 exposure floors and mean53.781/min52 coverage.
Within-dungeon template repeats6227 vs6195 do not improve; no universal diversity
claim. Final223-check coverage is green across the219-pass matrix plus three
explicit historical-fixture corrections and the actual-repository Git diff rerun;
this is not one zero-failure wrapper run. No production/manual changes followed
the final matrix. Full evidence and exact hashes are in the integration report.

Changed old expectations only where this user explicitly revised design:
B22 now checks the exact capped respite boundaries; B23 checks32-pool eligibility,
24 new min-sector rules and8-specialist/global64 caps; B25 checks increased rather
than reduced motif targets; B26 checks new count/budget/revision ceilings. No
historical campaign seeds or exposure thresholds were reduced. The distribution
fixture's sector exceptions are limited explicitly to Caromer, Reaper, Drubber
and Afterburst; all original companion/singleton/physical assertions remain. Ordinary20-second
replacement, RNG isolation, gate/geometry/lifecycle/companion and tier assertions
remain. The initial Bioblaster patrol-exit failure and pre-repair probe outputs
are retained. The first partial integration was stopped after11 passing suites
when the deeper dispatch gap was found; it is not final acceptance evidence.

The complete source tree was reconstructed from the verified B26 tree, with
source-hash-checked spans and canonical manual regeneration, then byte-verified
on an isolated GitHub branch. Main publication must use the same verified tree
plus reviewed documentation and a non-forced parent preserving newer work.

## Local acceptance

Install the published repair, then start a disposable local test on gm_flatgrass.
In the existing developer install, use the single console batch:

```text
lod_developer_mode 0; lod_regenerate
```

This replaces the current dungeon and marks the run unranked. Once ready:

```text
lod_population_status; lod_encounter_distribution
```

Confirm revision b27/developerDense=false, fourth-sector pacing ready and the new
per-floor roaming census. Then play through the normal gate order, including the
Neil/Brute hunt. Observe actual moving types rather than only planned names;
check small recurring contacts, distinct room fights, useful breathing spaces,
branch exploration, no sudden overwhelming convergence and acceptable frame time.
Shy should stop when witnessed; ordinary sensory/pursuit warnings and control
states must remain. Repeat with a teammate and retain console_latest.txt plus
rpg_summary_latest.txt. Recorded headless distributions are not a guaranteed
number of sightings or a reason to waive this playtest.

Local acceptance of this changed candidate precedes matching Workshop publication
and then VPS deployment. Keep all persistent data/configuration, rollback,
accepted Crate assets and P1–P4 improvements. Deferred optimization, Big Loot,
Event System and comprehensive audit order remains unchanged.
