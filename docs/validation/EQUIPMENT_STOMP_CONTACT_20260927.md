# Heavy Plumber contact repair — September 27, 2026

Author report: Boots of the Heavy Plumber never produce a stomp. Gameplay baseline
is `38adbce415ae6dd388c28a450bb9cd3b7a8248d2`; preserve its Soldier/Reckless repair
and the earlier standing-stair/SPOT-17 work. Publication identities are in the
external delivery receipt, not a guessed child SHA in this note.

## Authority and correction

Live GDD 00 -> 01 -> 03, `LOD-HEAVY-PLUMBER-001`, read September 27. Feet must be
at the target's collision top **at contact**. The old resolver tested the final
FinishMove origin instead. A modeled first top collision followed by a changed
final position failed this gate despite valid native first-hit geometry.

Use the actual `TraceHull.HitPos` for the at-contact top check. Keep the current
FinishMove origin for full-footprint floor/lock/hazard and ceiling preflight,
and for the rebound. Never rewind or teleport to the earlier impact. Missing
impact geometry fails closed. The original first-hit, descending-speed, normal,
source/life, damage-faction, sample-age/displacement, cooldown and one-excursion
checks remain. Damage is still canonical physical 2d6 + STR, zero Magic; blocking
or dodging does not suppress a valid self-bounce. Unsafe bounce geometry still
consumes the contact without damage or launch.

No jump-height, damage, descent threshold, bounce tuning, target-acquisition,
movement, status or progression authority has been added or changed.

## Evidence and limits

`tools/test_stomp_contact.lua` executes the actual registered SetupMove callback
from `sv_rpg_gate_d.lua` and the actual registered FinishMove callback, with native
input/movement/trace boundary doubles. The old production resolver fails its
first-impact-versus-final-position assertion; the repair passes. It also rejects
missing/below-top/side/start-solid/all-solid geometry, prevents replay/teleport,
and preserves unsafe-ceiling flight consumption. Existing
`tools/test_heavy_plumber.lua` retains its ownership, one-flight, defenses,
throwable/Muted, floor/lock/hazard and lifecycle cases; its trace double now
supplies the engine's HitPos field rather than omitting it.

This is a reproducible headless contract defect, **not** a captured Source-engine
reproduction of the author's session. No native acceptance is claimed. The
aggregate gate and external receipt establish only selected frozen-source tests.
An early new-fixture attempt lacked native `WaterLevel` / movement `KeyDown`;
those boundary methods were supplied before the baseline failure was recorded.

## Native observation

Fully quit GMod before installing the exact published source. In a deployed Hero
run on gm_flatgrass, `lod_heavy_plumber_testkit` equips the real boots and marks
the run unranked. First touch solid non-actor ground; then descend onto an enemy
from above its collision top. This is passive, not an arrow recipe or an attack
button. Use sufficient starting height for a downward landing, not a side bump.
Expect one Heavy Stomp feed event, damage subject to normal defenses, and a safe
upward rebound without Magic debit. The rebound cannot retrigger; touch solid
ground before another stomp. Retain ordinary ceiling/floor/locked-route checks.
Record the exact build, observation, console_latest.txt and rpg_summary_latest.txt.
Workshop and VPS actions remain outside this repair.
