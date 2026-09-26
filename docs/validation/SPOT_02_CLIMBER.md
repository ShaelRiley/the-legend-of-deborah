# SPOT-02 — Climber junction traversal and recovery

## Scope and evidence boundary

Author report: no Climber has ever been seen. This checkpoint repairs two
reproduced navigation failures and supplies release-safe evidence collection.
It does not establish that those failures alone explain all missing sightings.
No population, motif, damage, attack cadence, reward, or cosmetic tuning changes.

Baseline main: `fc559b3b83b4a84ea18842ef40192d97e69dbd14`.
Original `sv_climber.lua` Git blob: `7cf159ad1699ec50168fdc6d6a91f8e6bd3a058b`.
That blob matched the local original bytes before editing.

## Source audit

The identity is registered in EnemyRoster, included in the unified spawn order,
and rendered as a small pink fast-zombie-derived actor. The current Wall Hunt
composition is Climber + Shambler. It is eligible from sector 1 in arena/ambush
roles, but current ecology limits this template to Hunting Grounds. Climbers are
not ordinary wanderers. Absence in a different motif is therefore not by itself
proof of a broken spawn. These selection rules are unchanged here.

EnemyRoster placement supplies a clear closed-wall lane; the actual unified
spawner passes that placement into MotionV2. SnapSpawn explicitly preserves
wall-lane placement rather than snapping it to the floor. The audit did not
find a missing registration or a demonstrated universal spawn failure.

Confirmed defects in the original Climber module:

1. Route search could represent only cells with closed-wall lanes. A legal
   four-way junction has none, so pursuit could not cross it or start inside it.
2. After an interrupted/missed leap or detached latch, return-to-wall searched
   only the current cell. In a wall-free junction it remained in that state
   indefinitely, even with reachable real walls nearby.

## Repair at the existing movement authority

`RouteLanes` permits a physically clear center connector only when all four
planar edges have actual graph neighbors. It is travel-only: Lanes/NearestLane
and production placement never treat it as a wall or spawn home. Blocked real
wall lanes cannot be replaced by invented open space. Search caches lane probes
within one bounded request, retains the existing 256-state limit, follows actual
neighbors and CanTraverse, and breaks equal-distance lane ties deterministically.

Pursuit keeps the home-domain leash. Recovery has no Hero target and searches
from the actor's current cell within the same bounded radius, so a former victim
carrying it beyond its home leash does not prevent local return to a real wall.
Both paths use the existing swept Step function, EntrySafety movement admission,
and canonical stair itinerary. No teleport, graph edge or navigation owner is
added. Stale pursuit routes retire when a leap begins or is interrupted, and on
detachment. Failed recovery retries retain the existing 0.8-second interval.

The live GDD was read via 00 -> 01 -> 05/07 and exact HUMAN Climber placement.
The existing geometry-valid movement and readable-wall-placement rules remain
unchanged; the live GDD was not edited for this implementation repair.

## Fresh validation

Run from repository root with a Lua interpreter:

```sh
lua tools/validate_spot02_climber.lua
```

The actual production module is loaded with deterministic engine-boundary stubs.
Fresh result: **44 passed, 0 failed**. Both production and harness syntax loads
passed under system Lua 5.4. Native GMod/LuaJIT execution was unavailable.

The identical final harness against the original source gives **25 passed,
19 failed**. This includes the absent new diagnostic checks, not nineteen
independently discovered gameplay defects. The initial movement-only 36-check
reproducer gave 25 passes and 11 failures before the repair.

Coverage: one/two open junctions; starting pursuit inside a junction; detached
and interrupted recovery; recovery beyond the original home leash; real-wall
completion; blocked center and blocked wall lanes; closed/open gates; sanctuary,
apron, resupply and boss exclusions; pursuit leash; native-trace Hit/StartSolid
refusal; gate changes after planning; ordinary corridors; morale direction;
canonical stair dispatch; Held/hit stun; throttled failed recovery and reopening;
shared latch damage; bite interruption; sanctuary detachment; diagnostic access
control, category separation and read-only behavior.

This is not a fresh full repository integration run, a production seed/exposure
sample, Source collision/animation proof, multiplayer proof, or native acceptance.
The connector-only environment did not provide the complete repository/native
engine needed for the canonical integration gate. B29's previous tests and
SPOT-01's 50 passes are inherited evidence, not fresh results of this checkpoint.

## Finite native acceptance

On a local development build of this revision, deploy outside the sanctuary and
find an ordinary open junction. Run this single console line:

```text
lod_enemy_roster_testkit climber; lod_climber_status
```

The existing admin/developer testkit supplies one legally placed Climber through
the actual placement/spawn pipeline and marks the run unranked. It preserves
population limits and may ask for another legal location. Observe recognizable
wall movement, pursuit through the open junction, and return to a real wall after
interrupting a leap or detaching a latch. Confirm no wall/gate/sanctuary bypass.
Run `lod_climber_status` again after the interaction and after killing it.

The new status command is admin/server-console only and available in release
mode; it does not spawn anything or alter ranking. It prints the current motif,
current composition, dormant units, living encounter actors, placement counters,
and each living Climber's route/return/leap/latch state. Composition may have
been mutated by existing fallback; placement counters are cumulative admission
attempts, not current population or sightings. A debug spawn does not prove
ordinary release selection. Collect status in a fresh release-mode dungeon too;
record the motif rather than inferring every dungeon must contain a Climber.

Evidence: `console_latest.txt` and `rpg_summary_latest.txt`; include a brief visual
observation or clip for model/motion acceptance. Native sightings and all native
criteria above remain pending. Workshop publication and VPS deployment were not
performed. SPOT-03 Manhack absence is the next separate checkpoint.
