# SPOT-03 — Razor / Manhack absence audit and repair

## September 26, 2026 author-observed supplement — partial native confirmation

Published SPOT-03 build: `780d3d3b50f1026ba4a15a535b7569b6b09e0f71`.
Shael reports two console testkit refusals (no safe placement nearby), followed
by successful placement on the third attempt. That Razor was visible, attacked,
dealt damage, took damage and was defeatable. **Visibility and basic combat pass
for that controlled instance only.** There was no noticed natural Razor before
the test, despite play beyond the Red Gate. Precise deployed blades, stairs,
Held interruption, sanctuary/gate blocking, multiplayer replication and ordinary
release sightings remain unverified.

Evidence below is the author's supplied handoff summary of prior-thread uploads
`console_latest(4).txt`, `population_latest.txt` and `rpg_summary_latest(4).txt`;
those raw attachments were not independently re-read in SPOT-04. The console
summary has two placement refusals followed by success; `lod_razor_status` was
zero planned/dormant/living/roaming before success and one living **non-roaming
encounter** Razor afterward. This is controlled-spawn evidence, not exposure.
The population upload identified the SPOT-03 build with all 34 installed/mounted
module hashes matching. Its Occupation dungeon had no planned Razor and none
among 60 roamers, with **developerMode=true / developerDense=true**. It does not
establish release-mode exposure or pacing acceptance. The RPG summary had **no
recorded validator result**; the manual fight is not an automated native pass.

The console's missing `npc\manhack\mh_engine_start1.wav` warning is a separate
audio observation, not proof of a lingering death loop. SPOT-04 traces that path
in the generic dive warning and Razor footstep bank; see its audio validation.
The immediate `blade=0` row has unresolved timing relative to preparation and
does not prove persistently folded blades or negate the visible combat report.

**Sequencing:** Shael explicitly moves on. No further dedicated Razor test or
confirmed natural sighting is a prerequisite. Collect sightings opportunistically
in normal play, optionally `lod_razor_status; lod_population_evidence`, separating
developer-dense sessions from release evidence. Do not force appearances or
retune density to erase a legitimate zero-Razor dungeon. This decision does not
claim every cause of the original absence report has been resolved.

## Original SPOT-03 publication record (preserved)

The following original automated and then-unverified native evidence describes
the publication checkpoint; the supplement above updates only the stated native
observations. SPOT-04 reruns are recorded separately in its own validation.

## Scope and evidence boundary

Author report: no Manhack-type enemy has ever been seen. This is native author
feedback, not proof of a missing registration, a universal spawn failure, or a
single cause. This checkpoint repairs demonstrated presentation setup and
attack/approach defects without increasing density or forcing release exposure.

Parent main: `84c47a12bf723590b4098bdf0d9ff299240a9670`.
The exact tracked source tree `c20ab34c64b1fa176bcf062768b89897807f8438` was
retrieved through isolated source-audit Actions run `36212362265`; all 2,114
tracked blobs were verified before editing. The final delivery receipt supplies
the verified child commit. The source-audit workflow is not part of this update.

Original production blobs:
- `sv_enemy_roster.lua`: `065b8050e8cbf42957d3bd1fabfe19fa92fdc378`
- `sv_hostile_animation.lua`: `02d81acf5e2b23a63893ea743583e3c25e8b6431`

## Actual production trace

**Identity.** Razor (`razor`) is the only registered ordinary EnemyRoster identity
using `models/manhack.mdl`. Redliner shares the generic dive attack but uses a
Combine model; it is not a second Manhack. Watcher and Seeker use Scanner and
Rollermine models respectively. A Manhack sound name alone does not establish a
Manhack-derived actor. No additional actual model-derived roster identity was
found in the production source.

**Selection and exposure.** `razor_cover` / Rotor Cover Break is one Razor plus
one Soldier, eligible from sector 2. `sv_encounter_ecology_catalog.lua` assigns
that directed template only to Hunting Grounds. The current B27 autonomous pool
also admits Razor in all six roaming motifs: base weight 2, Hunting Grounds
bias 6, sector-2+ arena/ambush homes. Existing limits remain eight non-basic
roamers per floor, one living roamer per non-basic identity per floor, global
64 roaming capacity and the shared 96-hostile ceiling. The older HUMAN paragraph
excluding all ordinary wandering Razors is superseded by the normalized B27
32-identity pool; it is not the current production rule.

**Admission and fallback.** The director filters motif templates through actual
EnemyRoster placement before selection, and placement is checked again at
spawning. Razor uses the ordinary clear center position at graph floor + 2.
Protected/transition/objective and physically obstructed homes remain rejected.
The existing rejected-specialist fallback substitutes an ordinary Shambler
without inflating the composition count. `plannedComposition` and the mutable
current composition are different evidence, neither a client sighting.

**Spawning and dispatch.** The unified `sv_encounter_spawn_variance.lua` spawn
order includes Razor. It assigns the archetype/configuration/context before
native Spawn, preserves placement and uses MotionV2 SnapSpawn. The actual
`lod_hostile` initializer and MotionV2 behavior dispatcher reach EnemyRoster's
Prepare/Tick/Begin/Attack path. No absent registration or universal no-spawn
branch was demonstrated. Ordinary idle patrol and pursuit consume the existing
WanderingDirector and graph/stair route authorities; no private flight AI exists.

**Movement and attacks.** The old Begin path could stop pursuit to charge merely
because a target was in range and a ray could see it, despite a blocking dive
hull or an incompatible deck/stair elevation. It repeatedly attempted an
unusable planar attack rather than consuming a legal route. The released dive
also did not separately reject Held's movement prohibition, and serviced one
last movement/contact step before checking an already expired deadline. The
focused production-module harness reproduces these failures.

**Rendering.** The client has a Razor-specific 42-unit visual lift, updated
render bounds and the shared body/identity drawing path. No Razor-only hidden
render branch was found. However, the custom entity never executes the native
Manhack blade initialization, and the generic idle resolver can select the
packed idle pose. Valve's primary [Manhack source](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/hl2/npc_manhack.cpp)
uses `StartEngine` to set bodygroup 1 to 1 and uses `ACT_FLY` for an active
Manhack. This supports repairing the omission; it does not prove the entire
model was invisible in the author's session. Native model decoding, animation,
PVS/client visibility and approved-looking presentation remain unobserved here.

## Repair at existing authorities

`EnemyRoster:Prepare` deploys the stock blade bodygroup once, with model/bodygroup
availability guards. The check also works for already prepared actors after a
module reload. `HostileAnimation` chooses the existing fly activity/sequence
for a real Razor's idle and attack warning, invalidating an old cached packed
idle. Ordinary other archetypes and their animation resolver behavior remain.
No new native NPC, asset dependency, skin, color, scale or ambient loop is added.

A Razor-only preflight validates target/control permission, compatible floor
and elevation, graph-safe direct travel and the existing dive hull before
committing. Rejected attempts route through the existing waypoint/stair system
for 0.5 seconds before retrying. The check is bounded to one hull query and at
most ceil(fireRange / 24) graph segments per attempt. It uses a 4-unit source
floor-alignment tolerance and 48-unit target-height tolerance; these are
implementation guards, not new attack damage/range/speed bonuses. It does not
replace the shared movement, support, leash, gate or B29 authority.

The actual attack now stops a Razor dive on Held and refuses a movement or
contact step at or after its released deadline. The existing 0.65-second warning,
780-unit/second straight dive for up to 0.65 seconds, 2d6+4 physical packet once
per target, 1.8-second recovery, frozen heading and shared damage pipeline stay
intact. Redliner and other generic attack identities are not changed by these
Razor-only guards. This is not a general new floor-support or gap-navigation
system, and engine doubles do not certify native collision.

No encounter selection, motif membership, spawn weights, actor count, authored
combat values, rewards, feat balance or approved Crate appearance was changed.
SPOT-04's lingering enemy-death audio audit remains a separate next checkpoint.

## Fresh automated evidence

```sh
python3 tools/run_lua54.py tools/validate_spot03_razor.lua
python3 tools/run_lua54.py tools/validate_spot02_climber.lua
python3 tools/test_checkpoint_g_integration.py
```

The focused validator loads actual production modules with deterministic engine
boundary doubles: **55 passed, 0 failed**. Against the two original production
files, the identical final validator gives **26 passed, 29 failed**. Those 29
include the six absent new diagnostic checks and overlapping assertions; they
are not 29 independent gameplay defects or 29 native observations. The baseline
can be reproduced by extracting the original two files into a directory and
setting `LOD_SPOT03_BASELINE` to it when running the final validator.

Coverage includes model identity and unchanged attack references; blade and
idle/warning initialization; previously cached idle; clear/blocked direct
approaches; different decks and unfinished stairs; missing edges, closed/open
gates and protected cells; warning, frozen heading, sidestep, shared damage and
one-hit deduplication; deadline, Held and changed-obstruction interruption;
B29 movement denial; recoverable approach retry; actual directed eligibility,
placement, unified creation and count-preserving fallback; release diagnostic
access and read-only semantics. Native Source calls are stubbed, not observed.

Climber's independent production-module regression was freshly rerun:
**44 passed, 0 failed**. SPOT-01's prior 50 focused passes remain inherited;
this is not a fresh repeat of that exact earlier harness.

The registered 229-suite integration matrix was bounded for this spot checkpoint.
**226 suites passed; one suite failed and two were not completed.** The original
sequential invocation completed suites 1-17, then was stopped during the long
B23 32x20 campaign sampler without a result. The remaining registered commands
were run unchanged, except that B20's campaign-coverage sampler was not started.
Those two campaign-wide suites are **not completed**, not passes.

Suite 76, Spell Availability & Teammate Identity (`tools/test_refresh_ui.lua`),
fails because its headless environment has no global `Color` when loading the
unchanged `cl_teammate_identity.lua:8`. The identical command was rerun against
the exact parent tree and fails at the same line with the same missing-global
error. This is a pre-existing test-harness blocker, not demonstrated native
breakage or a SPOT-03 regression. It remains failed; it is not silently waived
or repaired as part of this unrelated bullet.

All-source Lua syntax, B29 full-build/dispatch/bilateral-combat checks, remaining
Bestiary production/behavior/presentation checks and Crate regressions passed.
[The exact suite receipt](SPOT_03_RAZOR_GATE.txt) records every result and the
frozen runtime/test hashes. **A full 229-suite pass is not claimed.**

## Limited exposure, measured without forcing a Razor

[The retained 20-build baseline sample](SPOT_03_RAZOR_EXPOSURE.csv) uses actual
production full generation and roaming initialization from parent main, with
compiled generated geometry and engine doubles. It keeps the existing B29
sample: sixteen Dungeon-1 seeds i * 7919, plus the existing Dungeon-2/5/10/21
cases. Only observation counters were added; no seed, RNG, selection or
admission policy was changed. `tools/test_bestiary_b29.lua` now prints these
same Razor counters for reproducible future comparisons.

Six of 20 builds had at least one planned directed Razor or initialized roaming
Razor; fourteen had neither. Across the sample there were six planned directed
Razor units and seven initialized roaming Razor actors. Planned directed units
are not necessarily activated actors, and initialized doubles are not sightings.
This finite sample demonstrates both a functioning production route and limited
exposure; it is not a universal probability estimate or the author's session.
The sample also retains 36-60 roamers and 14-24 identities, with exactly one
roaming home in each of the two restricted opening bands. No density retune was
used as a substitute for diagnosis.

## Release-safe diagnostics and finite native gate

`lod_razor_status` is available to admins/server console in release mode. It
performs no spawning, targeting, RNG use, trace, ranked-state change or gameplay
write. It reports the current motif, original planned Razor units, current
composition, dormant units, living and roaming actors, and any other living
Manhack-model identity. Existing placement counters are labeled as cumulative
session attempts, not current actors. Up to sixteen actor rows show model,
blade bodygroup, server NoDraw, source, position, route, target, attack and last
approach-rejection reason. Server NoDraw is explicitly not client visibility.

In an isolated local developer-mode run of this exact candidate on
`gm_flatgrass`, join as an admin, deploy outside the arrival sanctuary and run:

```text
lod_enemy_roster_testkit razor; lod_razor_status
```

The testkit requires `lod_developer_mode 1` and a living eligible admin Hero;
the status command itself does not require developer mode. The existing
testkit uses production admission/spawning and
marks an admitted test unranked; occupied or illegal geometry/capacity may
require another legal location. Observe deployed blades and stable hovering
while idle/charging, graph pursuit around a blocking low obstacle and through
an ordinary stair route, then a warned straight dive that can be sidestepped.
Check wall/gate/sanctuary blocking and Held interruption. Run the status command
again after interaction/death. This is a finite controlled behavior test, not
ordinary release exposure.

For ordinary release evidence, use the status command without the testkit in a
fresh release-mode dungeon, explore eligible sector-2+ homes and record the
motif plus actual sighting/absence. A single zero-Razor dungeon is compatible
with current selection. Preserve `console_latest.txt` and
`rpg_summary_latest.txt`, plus a short visual observation/clip for appearance.

Native GMod/LuaJIT execution, collision, model/animation, co-op replication,
ordinary sightings and opening feel remain **unverified**. The author-reported
absence is not declared fully resolved. Workshop publication and VPS deployment
were not performed. Local acceptance -> Workshop package/source parity ->
matching VPS remains the release order.

## Live design reconciliation

Read live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY` through
00 -> 01 -> relevant 05 rules and 07 roster implementation/attack values, plus
exact HUMAN Razor encounter and graph-bound traversal paragraphs. The repair
implements those existing contracts; no new authored behavior or existing-feat
rebalance was introduced, and no live GDD edit was needed. Preserve SPOT-02's
limited Climber evidence, B28/B29, P1-P4 and the unchanged deferred roadmap.
