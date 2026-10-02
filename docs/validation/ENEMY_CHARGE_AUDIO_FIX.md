# Enemy charge audio lifetime repair — 2026-10-02

## Scope and finding

Parent: `58b26f7af97ee8c01aab3ccf559b2d5ebe2fff08` (Gordon dance-floor checkpoint).
User report: Vortigaunt, Stalker and other enemy models leave indefinitely repeating spatial sound after death.

The existing server audio owner tracked only `npc/stalker/laser_burn.wav`.
The shared roster's arc/bolt/pulse warning, Siphoner/Accumulator resource casts,
and recovery/protection/cleansing support casts emit `npc/vort/attack_charge.wav`
without registering it for cleanup. These are server Entity:EmitSound calls, not
the client CSoundPatch resources already covered by SPOT-04. The support path has
its own `EnemySupport.Pending` / `LODSupportCast` record, not `LODRosterAttack`.
Source evidence: `sv_enemy_roster.lua` Begin/Finish, `sv_enemy_resources.lua`
BeginResource/StepResource, and `sv_enemy_support.lua` Begin/Resolve/Cancel.
This identifies and reproduces the missing ownership in a headless fixture;
no native audio recording or in-game reproduction was available in this session.

## Repair

Extend `sv_hostile_death_audio.lua`, the existing canonical owner. Charge cues
belong to the exact active roster attack or support cast and stop at release,
cancellation, replacement, or the authored ready/deadline boundary. Death,
removal, build/campaign retirement, mute, freeze and shutdown also stop them.
The Beam cue retains both its warning and its full released sweep.

Preserve original and resolved sound identifiers, including spatial prefixes.
Replacing an identifier stops the previous owned cue; duplicate starts cannot
stack copies. Stop flags and pitch/volume changes pass. Detach before native
cleanup and reject reentrant starts; retain the existing deferred lethal-stack
boundary and old hot-reload row compatibility. Previously untracked charge
sounds on still-existing actors receive an actor-specific retirement stop.

One sustained-cue row per sounding actor; no new world scans, per-enemy timers,
assets, client modules, gameplay tuning or music changes. Independent death and
combat one-shots, other living actors and projectile-owned sounds are not globally
silenced. Existing managed client gas/Watcher/fuse ownership is unchanged.
This restores finite audio behavior; there is no new player rule or manual change.

## Focused validation

Use the repository's unchanged Lua 5.4 runner:

```sh
python3 tools/run_lua54.py tools/validate_enemy_charge_audio.lua
python3 tools/run_lua54.py --syntax gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_death_audio.lua tools/validate_enemy_charge_audio.lua
```

Actual result: **62 passed, 0 failed**, plus both changed/new Lua files passed
syntax compilation. These tests load the complete production server audio module
with native sound/NW boundaries doubled. They cover seven ordinary charge-using
identities, three support-cast kinds, live-corpse cleanup, source isolation,
replacement/reentrancy, generation identity, exact deadlines, duplicate starts,
SND_STOP, script/prefix handling, Beam-sweep preservation and hot reload.
They do not execute full combat AI or decode/play the stock assets.

The same new suite against the exact unchanged parent audio module reports
9 passed / 53 failed. These are targeted test failures demonstrating the ownership
and guard gaps, not 53 distinct in-game bugs. The parent module's Git blob was
verified as `796da27dafae60c96aec9c7e4141737a85a5d7b4` before comparison.

Validated production blob: `c97cd809cf330562cabcb5c4788c9c2234088688`.
Validated new regression blob: `e027a9076d44f103edeafa9a3412ca73ae6f9c02`.
Unchanged official runner blob: `5442e60780907c408114c6cd660294e94d50a9f0`.

Run this targeted gate in addition to normal release checks. The complete
repository integration matrix and the earlier full SPOT-04 suite were not rerun.
No native GMod/Steam Deck audibility, full-game performance or hosted deployment
acceptance is claimed.

## Native acceptance and release boundary

Fully quit GMod, pull the source checkpoint, run `bash tools/install_dev.sh`, then
start a fresh LoD session on `gm_flatgrass`. Kill a charging Vortigaunt and Stalker
while leaving another nearby attacker alive; check that their old positions stay
silent while the survivor, ordinary death cue and music remain audible. Include
a support-casting enemy and a Beam Sweeper during ordinary play. The Beam sound
must last through its sweep but not persist after cancellation/death. Existing
orphan sounds from an older process are not evidence that new source loaded;
a full restart is required for this acceptance pass.

Native acceptance remains open. Preserve local acceptance → verified Workshop
package parity → matching VPS release. No Workshop publication, VPS deployment
or restart was performed by this repair.
