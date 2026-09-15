# Native crash audit — 2026-09-15

**Release remains blocked.** The code audit and automated repair checks are
complete; the fatal Source fault is not identified by a native stack trace and
the repaired build has not been accepted in Garry's Mod. Do not promote to main,
Workshop or the public server on the strength of these tests.

## Evidence and baseline

Audit baseline: `astra/equipment-update` at
`d59d2df2274cd11fb6311b7c3d89bef2a6b8ed9e`. Main remains
`8978796e886cdb5505d24ed0de085265fa99bac8`.

The recursive remote tree contains 366 production Lua files. Every one is
present locally and matches its remote Git blob, allowing only one extra
trailing newline introduced during source retrieval. There was no stale-code
content divergence in the audited checkout. This does **not** identify the
files actually loaded by the user's GMod process.

Newest evidence: `rpg_test_session(20260915-155357).txt` and
`console_latest(20260915-155356).txt`. The detailed session ends at sequence
1792, time 537.180, Shambler entity 1272, `HOSTILE_DEATH_STAGE stage=loot_enter`.
Its lethal AR2 hit occurred at 536.160; callback settlement, XP and corpse
presentation completed. Other enemies completed their loot handoffs earlier.
The preceding crash also ended at `loot_enter`, for a Soldier.

The new session has **no LOOT_NATIVE_STAGE records**, although d59 adds them
inside LootDirector, and no new flat-stat profile fields. Possible explanations
include an older installed build, mixed addon mounts, or the legacy entity
method executing without the director override. These remain alternatives,
not proven causes. The console shows both gm_crab_invaders and the development
addon, plus Workshop addons. Presence alone does not establish a conflict.
There is no native stack, dump, OOM report or fatal Lua traceback in these files.

## Audit coverage

The audit combined whole-tree source/API searches and syntax checking with
manual tracing of the following authorities and existing regression suites.
It is not a claim that a mock engine proves every native operation safe.

| Area | Inspected boundary and disposition |
| --- | --- |
| Hostile combat/death | OnKilled re-entry, borrowed DamageInfo lifetime, shared deferred corpse scheduler, loot conversion and removal; direct loot authority repaired |
| Entity/model/physics creation | Spawn/Activate/SetModelScale sites, scripted pickup/projectile/staging initialization, fixed-box maze geometry, corpse paths; unnecessary scaled activation removed |
| Player lifecycle | Starter touch, deployment, rescue/CompleteLevel and later advancement, death/reconnect inventory; starter retirement deferred |
| Client rendering | Generated IMesh ownership, mirror RenderView and render-target stack, afterimage model pools, wall visual model ownership, procedural weapon/magic presentation; cache and unwind repairs below |
| Resource/work limits | Existing dice-chain, projectile, penetration/pellet, encounter and presentation bounds; new global native-cache limits |
| Networking | Snapshot batching/deltas, bounded inventories and owner-checked transactions, topology payload limits, feedback acknowledgements and delayed callbacks; existing regression coverage retained |
| Persistence | Wallet/DFT transactional writes, rollback and replay handling, inventory life/role boundaries; existing production integration suites retained |
| Installation/evidence | Published-source parity, symlink installer and console capture, missing runtime identity; loaded receipts and installation record added |

Compiled model internals, graphics drivers, external addon code and the Source
engine are outside this repository audit. Native process RAM/VRAM cannot be
inferred from Lua heap size. The large, bounded wall-model population remains
a native memory-pressure measurement item; this audit does not silently change
maze geometry or visual density.

## Repairs

| Finding | Repair | What is established |
| --- | --- | --- |
| Loot delivery depended on patching an already-registered scripted entity class; a native prop_dynamic fallback remained | Base hostile resolves LootDirector at call time; remove class-table installer and fallback creation; add `loot_hidden` breadcrumb | Eliminates the load-order-dependent authority; does not prove it caused the force-close |
| Twelve additional activation calls remained on staging objects, potion/crowbar projectiles and the statue | Remove unnecessary Activate calls after Lua Spawn; retain explicit collision/movement setup | Removes exposure to a documented scaled-entity collision rebuild risk |
| Starter pickup removed itself during Touch/StartTouch | Mark claimed immediately, remove next tick | Duplicate grants remain blocked and native touch traversal can finish |
| Box/slab native meshes were cached indefinitely without Destroy or cleanup | Shared 256-entry LRU, Destroy on eviction, map cleanup/shutdown/refresh cleanup, reject nonfinite/inverted inputs | Native mesh retention is bounded and owned objects are reclaimed |
| Afterimages retained up to 32 free native models per model path without a global bound | Keep existing 12-trail/16-sample active limits; cap free models globally at 64; map cleanup | Arbitrarily many encountered model paths no longer grow free native model retention |
| Mirror errors could leave a render target, 2D camera or recursion flag active | xpcall around camera work, balanced unwind and throttled error retry | Injected Lua errors restore state; native faults are not catchable this way |
| Logs could not identify the installed/loaded repair | Installer records checkout SHA/dirty state and warns on duplicate filesystem gamemode mounts; runtime logs realm/build/component receipts, engine version/branch/architecture, entity count, Lua KB and mesh count | New evidence can distinguish the repaired modules from missing ones; installation SHA alone is not proof of loaded code |

Facepunch explicitly warns that calling Activate after SetModelScale can rebuild
collision and crash on complex models. That is a documented **risk**, not a
native fault attribution for these sessions:
[Entity:SetModelScale](https://wiki.facepunch.com/gmod/Entity:SetModelScale).
Native mesh release uses [IMesh:Destroy](https://wiki.facepunch.com/gmod/IMesh:Destroy).

## Validation

`python3 tools/test_checkpoint_g_integration.py`: **85/85 suites pass**,
including production Lua syntax checks. Installer shell syntax and diff checks
pass. New production-path tests exercise 2,000 distinct mesh requests,
eviction/reuse/refresh/map cleanup/shutdown, invalid geometry, two injected
mirror errors and recursive RenderView, duplicate starter touches, 100 model
families through afterimage pooling, and missing versus present build receipts.
The death test now uses the actual base-entity handoff with the director loaded
after the entity definition. Prior real loot initialization, overlap and
ownership tests remain active.

Lua mocks do not run collision meshes, GPU drivers, native model loading,
network transport or the engine. No GMod runtime was available to this audit.
The workspace execution service briefly disconnected; it recovered before the
successful final test run. That tooling incident is unrelated to the game logs.

## Native acceptance before release

Close GMod, update the development checkout and run `./tools/install_dev.sh`,
then restart on gm_flatgrass. The console and detailed log should automatically
contain `BUILD_IDENTITY build=stability-20260915-01`; server and client receipts
should show `missing=none`. Developer resource reports repeat every 30 seconds.
`lod_stability_status; lod_stability_client_status` also prints them on demand.

Next integrated check: play through repeated enemy kills and automatic drops,
rescue/return to staging, then deploy again. Include the previously failing
Shambler/Soldier lethal-hit and loot-conversion paths. Successful death streams
must progress through `loot_hidden`, `LOOT_NATIVE_STAGE`, `loot_complete`.
Native acceptance also needs sustained multiplayer play on the target low-end
client/server configuration, with stable resource use and no forced closes,
staging softlocks or lost/duplicated inventory. A single successful kill is not
sufficient evidence for public release after repeated intermittent crashes.

If force-close recurs, preserve the console and detailed session **before
relaunching**, plus the native crash dump if GMod produced one. The final stage,
loaded receipts and architecture should now narrow the remaining native fault.
Do not report the root cause closed without fresh runtime evidence.
