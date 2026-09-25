# Bestiary B28 — Native population-query repair

Baseline: `d384b986daa5c6f839df72d3f2a754503ff64102`.
Author's B27 native acceptance verdict: **FAILED**. Monsters were encountered
only at keycards, not elsewhere. The requested action was "fix it", not "exit".
B28 preserves B27's population design; it does not raise another density slider.

## Runtime evidence and its limits

Uploaded `console_latest(3).txt` / `console.log` have identical content. The
server/client DATA install label is B27. The trace records campaign1515962883,
master level seed163197061, layout seed1756475100, layout attempt3, maze attempt2,
520 validated base cells and two wandering floors. Both before and after
regeneration the wandering service announces target40 but prints **no successful
wanderer-spawn line**. In the audited implementation every registered wanderer
prints such a line. A target is not a created population.

There is no population census in that upload. The RPG summary/session stops at
staging (45 events, final event at50.025s), before dungeon ingress. The logger's
`developerEnabled()` test follows the live developer convar, so the previous
release-mode test instruction also disabled RPG evidence. Historical gate/combat
records in the rolling archive and morning die history are not this playtest.
The short stability tail records later loot work but is not a complete encounter
census. The user's two-gate account is not independently established by that tail.

The install label is read from DATA, not a digest of executing modules; simultaneous
filesystem/Workshop mounts are visible but shadowing is **not proven**. Missing
native admission counters prevent a categorical attribution of every rejected
spawn. The following two physical-query mismatches reproduce the reported pattern
under the repository's already-documented SOLID_BBOX ray-miss boundary.

## Repair at the physical-query seams

Generated `lod_static_box` floors/walls use collision bounds without per-box
VPhysics meshes. The existing M1 support audit and Magic Wall placement already
use a small feet hull because thin support rays are unreliable for these slabs.
Wandering admission still used a thin ray. B28 applies the established small
feet hull and movement collision group, retaining its original28-unit sweep,
4-unit deck-height tolerance, minimum normal.z0.7, full-body clearance and actor
filter. Missing, steep, embedded and wrong-height support still rejects spawns.
The first8 successful checks per graph also record whether the original line
probe disagrees, without making that line an admission fallback.

Discretionary encounter start-visibility also relied only on a thin ray. B28
preserves ordinary ray occlusion, then checks a narrow physical hull only when
the ray reports clear. Only an earlier hit on `lod_static_box`, `lod_gate` or
`lod_jail_door` can establish the missing generated cover; ambiguous StartSolid,
world/prop grazing hits and genuinely clear sightlines cannot manufacture cover.
Keycard squads bypass this discretionary visibility filter and the wandering
support filter, explaining why that class of encounter can survive both faults.
No combat ray, model, geometry, floor, attack, reward or density tuning changed.

## Finite regression and observation gate

`test_bestiary_b28.lua` first tests the ray-miss/hull-hit boundary, every retained
support rejection, visible starts, ordinary cover and generated-only corrective
occlusion. Substituting each original B27 production method independently causes
the corresponding regression assertion to fail. Original failed output is kept.

The test then loads the real graph-integrity and progression-safety wrappers
omitted from B26/B27's old fixtures. It reproduces the exact uploaded seeds and
attempts, including520 base cells plus19 reserved court cells. The actual floor
and merged-wall compilers emit791 boxes at the uploaded negative world height.
A geometric AABB trace double models their bounds and the documented missing-ray
boundary; it does not invent support from encounter tags. Corrected production
code plans18 non-objective groups and creates40/40 roaming actors in this model.
These are **not native engine counts, sightings, collision acceptance or timing**.
Stairs/doors/native AI continue to require the actual playtest.

A pre-existing B23 fixture chose an arbitrary `pairs()` arena and assumed every
roaming identity could legally use it. One selected run failed Waylayer's real
junction requirement. The fixture now chooses a deterministic home passing all
actual placement contracts. All192 pool membership assertions and every safety,
companion, cap and timing check remain; no production eligibility was loosened.
Its support double now models the correct hull rather than an always-hit line.

Fresh selected-regression results are summarized in `BESTIARY_B28_CHECKS.json`;
complete stdout/stderr, source hashes, negative controls and the publication patch
are in `LoD-B28-native-population-evidence.zip`. This bounded repair does not claim
a fresh full225-check canonical campaign matrix. Native acceptance remains open.

## Evidence that survives release mode

New independent autorun `lod_population_observability.lua` records automatically
on the first ready poll, gate changes, every30 seconds and shutdown; polling is
at10 seconds and disk retention64 records. `population_latest.txt` and console
receive plan counts, separately spawned objective/discretionary counts, living
roamers, per-floor deficits/rejections, probe disagreement and progression.
The installer atomically records eight SHA256 source hashes. The observer compares
mounted GAME bytes once per Lua session and separately checks the live support/
visibility bindings. Missing manifests and mixed mounts report unverified rather
than trusting the install label. It neither enables developer mode nor spawns,
changes AI, resets a dungeon, networks data or consumes RNG.

## Next native gate

Close GMod, pull/install the published repair, relaunch, then on a disposable run:
`lod_developer_mode 0; lod_regenerate`. Regeneration replaces the dungeon and marks
it unranked. Play normally; no extra diagnostic command is required. Upload
`console_latest.txt` and `population_latest.txt` from the same existing DATA folder.
Confirm revision b28, source.verified=true, both nativeProbes bindings true,
developerDense=false, nonzero actual roamers, non-objective encounters and useful
real contact pacing. Any remaining native rejection is now directly attributable.

Workshop/VPS remain untouched. Preserve local acceptance → Workshop parity → VPS,
all player data/configuration, approved Crate work and the deferred roadmap.
