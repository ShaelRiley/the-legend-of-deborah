# Complete ordinary enemy roster — development checkpoint

Branch: `astra/equipment-update`; starting remote `90477d7acc61091710c9ba18e49f1920073b1bc0`.
GDD authority: live 00 → 01 → 05/07, exact HUMAN archetype and encounter-grammar
rows. The author explicitly permits the missing tuning decisions for this pass.
Values are recorded in live tab 07. No main promotion or live deployment.

## Roster reconciliation

| State | Enemies |
| --- | --- |
| Existing, preserved | Shambler, Runner, Soldier, Deadcrab, Bio Blaster, Blitzer, Sniper, Watcher, Seeker |
| Added | Climber, Nodule, Flamer, Big Crab, Sentry, Razor, Arc Caster, Lurker, Beam Sweeper |
| Existing named encounters, preserved | Neil, Brute, Gordon the Warden |
| Explicitly deferred by GDD | Heavy (beyond v1) |

The playable v1 roster now has 18 ordinary archetypes and three named enemies.
This is roster implementation completion, not acceptance of the entire Enemy
milestone, adaptive soundtrack, or the outstanding native-crash investigation.

## Animation repair

The Sniper requested generic ACT_RUN/ACT_IDLE_ANGRY without checking Combine
model support. Shared `_SetActivity` passed unsupported activities directly into
StartActivity. Morale retreat called Motion V2 without selecting a movement
animation, so a stale/flinch pose could survive the transition.

The shared model-aware resolver now checks sequence IDs and names, rejects
reference/ragdoll/bind poses, tries appropriate model-supported activities and
named cycles, and caches resolution per model/activity. Motion V2 selects the
movement animation for every movement path, including retreat. Snipers request
Combine rifle movement/idle explicitly; Zombie run requests can fall back to
walking. Flinch validation uses the same reference-pose rejection.

Engine basis: [SelectWeightedSequence](https://wiki.facepunch.com/gmod/Entity:SelectWeightedSequence)
returns -1 for unavailable activities. The repair never submits an invalid
sequence to the native animation setter. Stock model sequences still need visual
acceptance in Garry's Mod; the harness simulates unsupported activity metadata.

## New behavior and integration

| Enemy | Behavior and answer |
| --- | --- |
| Climber | Pink fast zombie follows closed wall lanes, validated corners and legal stair connectors; finite leap and manually attached face latch. Keep shooting; hit stun delays bites without detaching. Dedicated hit volume respects intervening world geometry. |
| Nodule | Inverted floor Barnacle, bounded green gas and hiss. One shared poison-type damage event per second in exactly its cell; no automatic Poisoned status. Exit or kill it. |
| Flamer / Big Crab | Shared short fire cone after ignition warning. One damage packet and Immolated save opportunity per exposed target per commitment. Big Crab has oversized client presentation and ordinary death/loot. |
| Sentry | Stationary frontal finite-projectile fire, weak rear coverage. Requires a graph alternate approach or optional reward location. |
| Razor | Graph pursuit, rotor warning, fixed-direction swept dive, recovery. Walls/locked edges stop the dive; evade laterally. |
| Arc Caster | Frozen radius-112 electrical mark, charge, Raw-magic eruption. Vacate the mark, break sight, or interrupt. |
| Lurker | Validated ceiling anchor and clear lateral escape; finite non-homing venom glob, modest damage and one shared Poisoned save. No grab, tether or private poison timer. |
| Beam Sweeper | Validated fixed facing and clipped sweep lane, charge, horizontal 90-degree sweep, recovery. Crouch, cover or rear pocket; one damage packet per player. Only unreleased charge is interrupted by hit stun. |

All new enemies use stock assets and existing RPG progression, class/feat,
element, status, damage-reporting, XP, ordinary-drop, and cleanup authorities.
Nodule gains its missing progression template. Stationary hazards never multiply
inside one cell during party/depth template enrichment. Physical placement
rejects protected/objective/transition cells and inadequate counterplay; rejected
candidates become cheaper ordinary bodies rather than unsafe hazards.

New templates enter from Sector 2; Razor, Arc Caster and Beam Sweeper from Sector
3. Only Flamer joins wandering weights (3). The others are authored encounters.

New projectiles are bounded Lua records, not native physics entities: maximum
64, shared service up to 40 Hz, snapshots at 10 Hz only while populated or clearing.
Attack geometry and status attempts are server-owned. Client effects have
bounded counts, distance culling and reduced-effects variants. No downloads,
dynamic lights, unbounded particle emitters or per-frame mesh/model allocation.

## Verification and finite native test

**89 automated suites pass.** The added suite executes animation fallback/cache
and recovery, all nine production spawn paths, population caps, fair placement
rejection, fire/venom rider contracts, fixed marks/LOS cancellation, beam
crouching and hit deduplication, wall routing/blocked movement, latch lifecycle,
gas cell/death boundaries, frozen simulation and old-run projectile retirement.
Existing equipment, combat, progression, named encounters and crash-hardening
regressions remain green. The Instruction Booklet contains three new bestiary
pages explaining the threats.

After installing this development build on `gm_flatgrass`, enter an open sector:

```text
lod_developer_mode 1; lod_enemy_roster_testkit flamer; lod_enemy_animation_status
```

Use one enemy at a time, replacing `flamer` with `climber`, `nodule`, `bigcrab`,
`sentry`, `razor`, `arccaster`, `lurker`, or `beamsweeper`. The command chooses a
nearby valid cell, preserves the hostile reserve and marks the run unranked.
An unsuitable location is refused; move to an open junction/reward branch.
The original `lod_enemy_update_testkit` still supplies Sniper/Blitzer.

Observe Sniper travel and a Zombie retreat without a reference pose. Check each
new threat's warning, counterplay, hurt recovery, death and ordinary pickup.
`lod_enemy_animation_status` reports actual model/sequence/playback for visible
runtime evidence. Preserve `console_latest.txt` and `rpg_summary_latest.txt`;
include the detailed session for a forced close. Native visual/co-op and crash
acceptance remain outstanding; static tests do not authorize live release.
