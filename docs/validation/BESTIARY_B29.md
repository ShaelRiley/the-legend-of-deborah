# Bestiary B29 — Safe arrival and graduated combined pressure

## Evidence state and current symptom

Baseline `main`: `fc8951840a69e52a0dd4d73ac309480a9b958b98` (B28). This is a
**locally testable implementation with a passing finite headless gate**, not native
acceptance. The latest author report is immediate Dungeon-1 portal-arrival mobbing
after population restoration. This supersedes restoration-only acceptance. No
newer native incident log was available; older B27 uploaded logs describe the
keycard-only encounter failure and cannot establish the new mob's counts or timing.

Live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, 00 → 01 → 05/06/07,
`LOD-B29-ENTRY`, contains the author-delegated design and tuning. The initial finite
gate was recorded before gameplay edits; implementation refinements are explicitly
candidate tuning, not historical game law. Publication response identifies exact
remote SHA. Workshop and VPS are not part of this checkpoint.

## Confirmed audit findings; not an invented native diagnosis

Actual deployment is `BuildReport.startPos`, `CellCenter(graph.Start) + Z12`, after
the production floor anchor. `graph.Start` is a coordinate record; the canonical
neighbor-bearing cell is `graph.Cells[CellKey(graph.Start)]`. Previously safe/quiet
tags restricted placement but did not establish persistent movement, acquisition,
pursuit or damage boundaries. Wandering and directed actors had no shared opening
admission limit. Native coroutine/Watcher dispatch and later special-move wrappers
could bypass an early MotionV2-only policy. Cached navigation needed to preserve
an optional filtered-path argument. These are confirmed code gaps. Placement,
convergence and premature activation are plausible overlapping contributors, but
the new native session's proportions are **unknown**.

B28's generated-collision floor support and visibility repairs are retained. The
historical reconstructed negative-height layout's 791 static floor/wall boxes,
18 optional groups and40 roamers remain headless regression facts, not this
mobbing incident's observed census.

## Design and implementation

`sv_entry_safety.lua` is one graph/run-owned authority, not a third population
director. Existing directors retain actor creation, homes, compositions and rewards.
Existing graph traversal retains closed gates; no progression edges are removed.

| Area | Candidate rule |
| --- | --- |
| Sanctuary | Start plus legal same-floor one-edge neighbors, at most5 cells; exclude objective/gate/stair/boss reservations from expansion. Exact world/deck membership. |
| Persistent spatial safety | Acquisition, ordinary movement, special sweeps, recovery moves and harmful combat settlement use the same boundary; conservative24-unit hostile XY margin. |
| Reciprocal combat | No hostile damage, harmful status or push through protected occupants; no outgoing ordinary attacks or owner-proxy damage from safety. No healing service or clock pause. |
| No waiting mob | No initial/replacement home or autonomous patrol within3 start-graph edges. Unadmitted enemies take finite outward/home paths rather than waiting on the threshold. |
| Opening distribution | At most1 living roaming home at depth4–5 and1 at6–9. Prefer initial homes4–5 and7–9. Early patrol territories4–6 /6–11; deeper patrols10+. Optional directed homes10+. |
| First contacts | Basic first-band actors; next band can add Reaper, Drubber, Caromer or Afterburst. First contact1 actor. Later local quotas2/3/4/6 require both additional contacts and depth6/10/15/20. |
| Established pressure | Five completed contacts and current depth24+; checkpoint destinations beyond entrance retain existing fight contracts. Backtracking shallower does not authorize a larger opening volley. |
| Combined locality | New acquisition within3 traversable edges; all active opening Heroes within4 share each actor's reservation; committed pursuit up to6. Safe/staged Heroes do not consume remote groups' quota. |
| Contact separation | Admission window1 second; no refill during the contact. Dead members reserve4 seconds for projectile tail, then4 seconds respite after cohort closure. Avoidance must advance2 cells and separate beyond6 edges to count. |
| Complexity | First contact Shambler/Runner/Soldier; second may include at most1 readable specialist; later limited contacts at most1 specialist. Lungers cannot initiate against the immediately departing apron occupant. |
| Lifecycle | Exact State/Graph/seed/level/epoch/run ownership. Actual committed deployment starts diagnostics. Completion/high-water persist by identity through death/reconnect; no staging timer. State reset retires HUD and records. Freeze shifts contact deadlines. |
| Presentation | Five-or-fewer NW2 centers, gold boundary lines and `SANCTUARY — COMBAT DISABLED IN BOTH DIRECTIONS`; no new physical entity, material or Crate surface edit. |

The top-level native hostile coroutine, Watcher/Seeker services, MotionV2,
pathfinding, roster/spawn authorities, special jumps/charges/latches, pushback,
recovery and canonical damage/status seams consult this authority. Objective
compositions may activate unchanged but their actors still share admission.
Native perception/telegraphs/attack formulas still decide what an admitted actor
actually does. Reservation is not proof an attack occurred.

No broad population budget reduction, replacement-rate acceleration, new enemy,
health/damage/reward retuning, ceiling increase or checkpoint/boss destination
change. Preserve Crate presentation, P1–P4, the32-identity autonomous pool and the
existing96-hostile ceiling /64-wanderer cap.

## Finite gate fixed before implementation

1. Real production generation/build with generated collision AABBs, including
   B28's negative-height replay and negative support/visibility controls. Sixteen
   fixed Dungeon-1 seeds (`7919 * 1..16`) plus levels2/5/10/21.
2. Zero hostile homes/patrol admission in sanctuary/apron, positive protected
   actual arrival, correct deck discrimination; prolonged staging and six
   replacement cycles do not consume/bypass protection.
3. Actual successful deferred portal deployment; bilateral native damage/status/
   push seams; special swept ingress; native coroutine/MotionV2/cached navigation
   withdrawal instead of boundary queuing. No movement while frozen.
4. Mixed-source contact quotas1/2/3/4/6, no refill, tail/respite, progression,
   staggered/nearby/separated Heroes, safe return, reconnect and exact owner reset.
5. Per sample: >=12 roamers, >=6 distinct roaming identities, >=10 deep roamers,
   >=4 optional groups, valid progression/ecology bounds and unchanged ceilings.
6. Preserve applicable B28/Bestiary/geometry/lifecycle/manual/combat regressions.
   Native welcome/readability/difficulty and Source-engine collision remain pending.

## Final frozen execution

**42 selected checks passed,0 failed**, from228 registered canonical suites;
this is **not a fresh full228-suite matrix**. All22 B28 selected checks are retained,
with the current all-Lua syntax inventory, plus20 directly applicable checks.
Commands, exit codes, timing and stdout/stderr hashes are in
`BESTIARY_B29_CHECKS.json`. Reproduce with:

```sh
python3 tools/test_bestiary_b29_checkpoint.py --output /tmp/lod-b29-checks --jobs 3
```

The runner refuses a nonempty output directory to preserve failures. The final
snapshot covers1889 gameplay/asset/tool/manual files, unchanged before/after:
`f3ea6916816c0eb7dd2a66bb7df75a5337cd5a19e6e851fa32c110168115a863`.
Documentation and receipt publication do not alter that frozen source set.

New tests are `test_bestiary_b29.lua`, `_dispatch.lua`, `_combat.lua`. They execute
production generation, full Build/M3 planning and actual deferred deployment,
native coroutine, MotionV2, cached path and combat methods with headless native
boundaries. The traces intersect actual generated geometry boxes; they are not
permissive always-clear or tag-only doubles. Native Source/GMod entities, timing,
rendering and final engine collisions are still doubled: **no engine smoke test
or subjective playtest is claimed**.

Across the20 final generated samples: **36–60 living roamers**,
**14–24 distinct roaming identities**, **12–21 optional directed groups**,
and **34–58 roamers beyond the two opening home bands**. All20 had exactly1 home
in each opening band; sanctuary size2–4. Full-build static box counts
829–1292 include stairs, unlike B28's historical floor/wall-only791 fixture.
Raw rows: `BESTIARY_B29_SAMPLES.csv`. Optional group counts are planned legal
encounters, not proof they all activated in native play.

Preliminary fixture failures are not rewritten as passes: canonical Start lookup,
nearby-count expectation, full-builder entity double, cyclic test-state copying
and dispatch Hero-list injection were corrected. An initial final-run orchestrator
failed before tests on B28's compact syntax-command receipt; the corrected fresh
run passed42/42. Earlier interrupted sample runs and exploratory logs remain in
the response evidence archive. No gameplay/manual changes followed the frozen pass.

## Release evidence and local acceptance

Automatic release `population_latest.txt` now exposes entry version
`b29-entry-safety`, boundary cells, live function bindings, per-deployment exit and
first-attack offsets, contacts/cap/respite, nearby counts/source overlap, admitted
members, engaged targets and denial counters. Source verification expands8→34
files. Snapshot reads do not advance gameplay or RNG. Existing10-second polls,
30-second heartbeat and64-record bound remain; `entry_progress` captures state
serial changes on that poll. First attack is positive incoming damage intent
passing entry admission **before ordinary defenses**, not necessarily HP loss.
Sampling can miss short between-poll events; zeros alone are not native proof.

Install exact candidate, fully restart GMod, use `gm_flatgrass` and a disposable
local unranked dungeon. The installer enables developer mode for tooling; in the
console run `lod_developer_mode 0; lod_regenerate` to test production population.
Take ordinary time in staging, deploy normally, stay in the outlined sanctuary
15–20 seconds, leave normally and play through several opening contacts/first gates.
Observe zero protected harm, no threshold queue, a small initial fight, breathing
room and populated varied exploration beyond it. A later co-op trial must cover
staggered arrivals and separated groups under native movement/combat.

Upload **`console_latest.txt` + `population_latest.txt`** from
`garrysmod/data/legend_of_deborah/`, matching the same installed revision/session.
Do not request the old B27 logs as this acceptance evidence. No manual population
census or debug enemy spawning is required.

Release order remains local acceptance → Workshop publication/parity → matching
VPS deployment. This checkpoint does not publish Workshop or restart the VPS.
Deferred: Low-End PC Optimization, **September28–October4,2026** → Big Loot →
Event System → comprehensive systems audit. Preserve completed P1–P4.
