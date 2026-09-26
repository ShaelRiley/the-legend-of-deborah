# SPOT-04 — enemy loop-audio lifecycle cleanup

## Scope, source and finite gate

Parent main: `780d3d3b50f1026ba4a15a535b7569b6b09e0f71`;
exact tree: `af02fe08d97c7eb953ab720c80da6c7c0e3394ae`.
The isolated read-only source snapshot, Actions run36229342028, supplied all2118
tracked blobs; every Git blob hash and the reconstructed tree were verified
before editing. No existing local workspace/uncommitted work was found. The
auxiliary snapshot/publication workflow is not included in the main checkpoint.
The delivery receipt supplies the independently verified child SHA.

The author's finite contract is enemy-owned loop silence after death/removal,
including valid corpses and stale callbacks, without global suppression of
living actors. The automated gate exercises actual production modules with
native/network boundaries doubled. It cannot prove audible sound, Source asset
decoding, native collision stability or multiplayer timing. This is one audio
bullet, not SPOT-05, population tuning or an existing-feat rebalance.

## Actual audio ownership trace

| Authority | Start and service | Original termination gap / retained scope |
| --- | --- | --- |
| cl_loop_audio.lua | Sole CreateSound authority; gas2, watcher2, fuse4; per-owner finite leases. | Valid/dead/dormant bodies could retain or renew patches; old generation used only seed:level. |
| cl_enemy_roster.lua | Nodule gas steam_loop1; ordinary gas draw renews its owner. | Existing RosterAlive draw guard did not immediately retire the already-owned patch. |
| cl_rpg_sixth_sense.lua | Server snapshot admits Watcher scanner loop; mounted terminal-loop fallback. | IsValid alone accepted the still-valid corpse and a late snapshot could renew it. |
| lod_magic_projectile/cl_init.lua | Bomb fuse leases steam2 on its own projectile. | Preserve caster-independent ownership; reject an old same-seed build's projectile. |
| sv_enemy_roster.lua | Beam sweeper's warning directly EmitSound laser_burn; attack has existing finite warning/sweep lifecycle. | No matching tracked stop on E.Cancel, death or lifecycle retirement. |
| sv_hostile_death_audio.lua / lod_hostile/init.lua | Existing legacy suppression and shared deferred death presentation. | Previously suppressed administrative blips, not the Beam resource; native mutations must remain outside lethal damage. |
| sh_audio.lua / sv_seeker_sound_safety.lua | Existing generation mute and Seeker asset filters. | StopSound generates SND_STOP; the old filters could reject or rewrite those stop events. |
| sv_seeker.lua / sv_combat_audio.lua | Current Seeker and hostile movement/pain/death cues are one-shots; Seeker has explicit old seek-loop stops. | No new native Seeker/Manhack ambient engine is added; death one-shots stay intact. |

A repository-wide search found one CreateSound owner and the listed loop paths.
GPS's existing PlayFile stream is player navigation speech, not enemy ambience;
it is outside this repair. Merely containing a sound name does not establish a
native loop or explain the author's original audible report. In particular, the
reported missing Manhack startup sample is a separate issue. The harness proves
missing stop/ownership branches, not the waveform looping behavior on a device.

Primary API/source checks:
[Facepunch StopSound](https://wiki.facepunch.com/gmod/Entity:StopSound) identifies
SND_STOP; [EntityEmitSound](https://wiki.facepunch.com/gmod/GM:EntityEmitSound)
and [EmitSoundInfo](https://wiki.facepunch.com/gmod/Structures/EmitSoundInfo)
describe stop flags and original/resolved sound identifiers. Client
[EntityRemoved](https://wiki.facepunch.com/gmod/GM:EntityRemoved) and
[NotifyShouldTransmit](https://wiki.facepunch.com/gmod/GM:NotifyShouldTransmit)
distinguish temporary transmission/full updates from true removal. Valve's
[Stalker source](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/hl2/npc_stalker.cpp)
explicitly stops its beam sounds in KillAttackBeam. Its
[Manhack source](https://github.com/ValveSoftware/source-sdk-2013/blob/master/src/game/server/hl2/npc_manhack.cpp)
precaches and emits NPC_Manhack.ChargeAnnounce for its charge announcement. These
references support API behavior and the stock soundscript name, not a claim that
the author's installed asset bytes or native audibility were tested here.

## Repair at the existing authorities

LoopAudio checks replicated retirement/death and gas-alive state, dormancy and
existing topology build serial before either starting or renewing. Think stops
a dead owner's patch without waiting out the old lease. Stop detaches ownership
before native calls; repeat/reentrant cleanup is safe and native exceptions are
reported. True entity retirement and old module references cannot restart a
patch. Temporary PVS/full-update loss stops playback but allows a returning live
owner to renew. Build identity prevents same-seed old actors, including a late
previously unseen owner, from joining the new scene. Fuse checks use the
projectile's stamped build rather than caster health. Existing limits, leases,
closest-owner admission, volumes, pitch, sound level and paths remain.

HostileDeathAudio now owns the existing raw Beam sound by exact actor and attack.
Bind occurs once at native initialization, retaining exact RunManager state,
level seed, campaign epoch/run, topology build, and ready graph where available.
Actors created during a pending build bind the exact existing build serial and
do not borrow the previous graph. Start rejects stale/dead/unready/inactive,
expired or future-scheduled work. Canonical E.Cancel stops the current sound,
while the bounded sounding-owner maintainer handles expiration/replacement and
invalid lifecycle. Death is sealed synchronously with a pure Lua flag; native
StopSound and the new retirement replication wait for the shared deferred death
presentation or a later Think. No new audio mutation is added to the lethal
native stack. OnRemove, builder cleanup, existing build/campaign mute, map
cleanup and shutdown retire only owned actors. Repeated retirement is inert.
Native stop events bypass all three relevant audio filters even when generation
is silent. This is not a world-wide stopsound or blanket death-sound suppression.

The invalid `npc/manhack/mh_engine_start1.wav` reference was present in generic
Dive warning (Razor and Redliner) and Razor's already asset-filtered footstep bank.
The warning now uses `NPC_Manhack.ChargeAnnounce`, the authored stock charge cue;
the missing footstep entry is removed. This does not initialize an engine loop
or change dive timing, damage, blade pose, movement, density, rewards or visuals.
The mounted soundscript/file resolution and audible result remain native-pending.
Full GMod restart is required for this candidate's new lifetime fields.

## Fresh automated evidence

```sh
python3 tools/run_lua54.py tools/validate_spot04_audio.lua
python3 tools/run_lua54.py tools/validate_spot03_razor.lua
python3 tools/run_lua54.py tools/validate_spot02_climber.lua
python3 tools/test_checkpoint_g_integration.py
```

The focused production-module harness has **74 passes / 0 failures**. The same
final harness against the unchanged parent gives **18 passes / 56 failures**;
several failures are missing new APIs and overlapping cases, not 56 distinct
native bugs. Coverage includes actual client SixthSense snapshot dispatch,
leased gas/fuse owners, valid corpse silence calls, late callbacks, removal,
PVS/full-update return, exact same-seed replacement, staging/failure/clear,
shutdown/hot reload, caps, leases, idempotence, native exceptions and reentrancy.
Server cases use actual E.Begin/Cancel/Finish, native hostile constructor entry,
OnKilled/deferred presentation/OnRemove and build/campaign wrapper modules.
Boundary mocks assert that new audio NW writes/StopSound do not occur inside
lethal damage. Intentional one-shot death feedback and another living owner's
loop are independently asserted. Full native audio is not executed.

Fresh Razor **55/55**, Climber **44/44** and the independent SPOT-01 target-identity
harness **50/50** pass. All **731 Lua files** pass syntax.
The expanded registered matrix has **230 suites**: **227 passing suites, one unchanged-parent harness failure, and two campaign-wide suites not run** (coverage across the bounded matrix and explicit reruns, not a full 230-suite pass).
Exact per-suite commands, receipts and all nonpass outputs are retained in
[SPOT_04_AUDIO_GATE.txt](SPOT_04_AUDIO_GATE.txt).

The first focused run had72 passes/2 fixture failures: missing string.EndsWith,
and an overbroad sentinel that prohibited inherited roster-telegraph NW writes,
not just the new audio mutations. Both fixture corrections are explicit; the
original output is retained. Four integration fixtures initially lacked the
new native SetNW2Int method in their projectile doubles. Adding that boundary
stub, without changing their gameplay assertions, gives fresh passes for
Fighting Streets, AG011, Watermelon and Super Ball. The initial matrix runner
also accidentally excluded the syntax command because it contained the two
omitted campaign filenames; a standalone exact syntax-suite rerun passed all731.
These initial failures/runner mistakes are retained, not erased. The teammate-UI
Color-global failure reproduces unchanged on the exact parent and remains a
failed, unrelated harness check. The B25 32x6 paired sampler timed out at90 seconds alongside concurrent suites,
then passed unchanged in an isolated bounded240-second rerun. B23 32x20 campaign
wandering and B20 campaign coverage were deliberately not run. Full-matrix
success is not claimed.

No native acceptance is claimed. SPOT-03's original229-suite accounting and B29's earlier42 selected results
remain historical; fresh reruns above are identified separately. This commit
changes no SPOT-01 UI, combat values, B28/B29 policy, population/selection,
Bestiary identities, Crate appearance or P1-P4 optimization.

## One compact local listening gate — not another Razor test

Fully quit GMod, install this verified main candidate through tools/install_dev.sh,
and start `gm_flatgrass` fresh. Use an isolated local developer/admin run; testkit
spawns mark it unranked and can legitimately refuse unsafe placement. Keep game
sound audible, optionally lowering music for listening. Do not change global
sound suppression to manufacture a pass.

1. Enable `lod_developer_mode 1`, deploy beyond sanctuary into a legal open area,
   then run `lod_enemy_roster_testkit nodule; lod_enemy_roster_testkit nodule`.
   Move to another legal location only after a placement refusal. Locate both
   living Nodules and confirm audible gas/hiss; silence already present is not a
   cleanup pass. The two-owner gas cap makes two enough.
2. Kill just one. While its death-presentation body remains, its hiss must stop;
   the other living Nodule must continue. An intentional one-shot death cue is
   allowed. Stay near the bodies so leaving sound range cannot fake success.
3. With the survivor still audible, run `lod_regenerate`. Old hostile removal
   and reset must leave no lingering hiss. Deploy and spawn one new Nodule to
   confirm fresh-generation living ambience resumes. This is combined native
   removal/reset evidence; the independent OnRemove path is covered headlessly.
4. Exercise the separate server path with `lod_enemy_roster_testkit beamsweeper`:
   hear its warning/sweep, then kill it during that commitment; its sustained
   sound must stop while ordinary death feedback remains. Run
   `lod_rpg_test_finish SPOT04-audio` after the listening observations.

Send `console_latest.txt` + `rpg_summary_latest.txt` and a short listening report
(or clip) stating living/dead/other-living/reset/Beam results. The uploader path
is `garrysmod/data/legend_of_deborah/` on the Steam Deck. A generic RPG validator
result would not be an audio validator or proof of audibility. Watcher-specific
native SixthSense sound, full client/server/PVS timing and multiplayer isolation
remain separately unverified unless actually exercised. Natural Razor sightings
are opportunistic only; no forced Razor placement is needed for SPOT-04/05.

## Design, sequencing and delivery

Read the exact live GDD through00 ->01 ->06 and use the explicit author sound
contract. This repairs existing presentation/lifecycle requirements with no
new authored balance values; no live GDD edit was needed. SPOT-03's dated
supplement preserves the successful controlled fight, developer-dense evidence,
missing-sound warning and unresolved blade timing without manufacturing a native
automated pass. Next is **SPOT-05 Die Logger audit**. No Workshop publication or
VPS deployment/restart is authorized here. Preserve local acceptance -> Workshop
package/source parity -> matching VPS. The deferred roadmap remains Low-End PC
Optimization September28-October4,2026 -> Big Loot -> Event System -> systems audit.
