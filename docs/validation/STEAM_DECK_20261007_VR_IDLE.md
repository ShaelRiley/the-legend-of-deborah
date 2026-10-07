# Steam Deck — idle VR runtime, 2026-10-07 UTC

Base: clean main `1e67e3fbac939166a10e6f856e4355ef2086e732`; its four Actions
workflows succeeded. The author requests this pass before testing that HUD build:
unused VR compatibility must consume no recurring runtime work and resume when a
VR player connects. Sustained >=40 FPS on Steam Deck/Proton/windowed/Arch Desktop
remains the target. The preceding clean native capture measured 24.86 active FPS;
there is no new target-hardware measurement for either this or the HUD pass yet.

Authority: live GDD identity `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`,
read 00 → 01 → required 06/07 lifecycle/UI, existing authority, server authority,
determinism, low-end/event-driven performance and finite validation rules. Revision
`ANLCKQmUlHpIXlUgqqjCRjeDq_RX5wfx7ceBkFwsdpnj5ZxQkzwWH2SxmdIiMnmRGrSLjqw2kDKEAZWGg9e2Cg8ohbKLMunfHqqeJwdRdA`.
This implements the current user's explicit lifecycle direction; no gameplay
tuning or live-GDD design amendment is introduced.

## Finite condition and implementation

In a settled desktop-only session, require zero registered VR runtime hooks,
zero repeating VR timers, zero outstanding one-shot VR jobs, zero owned native
motion controllers/physics proxies/held hands, no retained shared desktop method
overrides and no local headset tracking. Activation uses existing
join/start events; suspension uses last exit/disconnect. Passive net receivers,
one-time initialization and finite teardown remain necessary for that lifecycle.
There is no presence-scanning Think hook and no idle diagnostic polling.

Inspection found always-registered server player scans/physics ticks, client
input/UI/pose callbacks, logger/manual-pickup/model polling and an eager native
module load. The unchanged pinned upstream archive now receives a separate
deterministic, fail-closed overlay. All addon hook/timer users receive local scoped
APIs; the global engine registrars remain untouched. Shared aim/model/Derma/halo/
portal bindings return to their exact original owner when idle, without stomping
newer owners. Real lifecycle cleanup runs before suspension. Finite exit cleanup
jobs settle once; a new VR lifetime cancels stale session-setting/input restores.
The canonical dropped-NPC deletion still finishes once for its world object,
even across an intervening VR join. Invalid disconnects
remove owned physics proxies; delayed creation checks the same still-live owner.
Both held hands release through canonical `vrmod.Drop` before presence is erased.
The final release stops/removes the native pickup motion controller; ordinary
world props survive and another VR player's held physics stays active. Invalid
disconnect entities remain available to teardown even when lookup returns nil.

No-VR Deborah input/Think hooks are absent. Five quick-menu entries, tracked input,
HUD preference restoration, mandatory death/respawn guards, Tetris stick centering,
cinematics, ordinary desktop controls and mixed-player behavior retain their
existing authorities. Local tracking keeps support awake across death/registration
gaps. A remote VR join does not load the local desktop native module. Explicit
native start errors/cancellation settle idle rather than leaving startup polling.

Both development installation and the dedicated launcher use the offline overlay.
A pristine old pinned copy upgrades atomically; modified/additional/duplicate
files block replacement and remain intact. Repeat verification makes no writes.
The archive/license/models/materials remain byte-exact. All 139 mounted addon Lua
and two bridge hashes are checked once when diagnostics are explicitly requested,
then cached for that Lua lifetime. Readiness also requires the idle runtime version.
The existing opt-in performance capture copies actual idle counts in start/end
resources, server CPU-profile resources and five-second client windows; ordinary
runtime heartbeats do not call the VR diagnostics. Private pickup/controller/proxy
ownership is counted only by explicitly requested snapshots, without a new scan
in normal gameplay.

## Evidence and limits

The focused production-path harness executes real pinned server join/rejoin/exit,
disconnect, pickup, model/aim, proxy and logger bodies plus client/native startup
bodies. Across 4,800 simulated idle frames per realm it observes zero VR runtime
callbacks/timers, with zero server player scans. It covers two VR players and a
desktop teammate, duplicate joins, last invalid disconnect, reactivation, queued
proxy cancellation, native module deferral, failed/cancelled starts, exact trailing
nil return parity, newer owners and foreign-hook restoration. Real three-proxy
creation still works and all three are retired after an invalid disconnect.
The real held-prop registration/drop/controller bodies also prove two-hand exit,
remaining-player isolation, invalid last disconnect with no entity lookup, empty
controller retirement and survival of dropped world props. Dropped-NPC cleanup
also completes exactly once across a new VR lifetime and then returns to idle.

The 139 patched Lua files pass a syntax probe. Plain Lua lacks GLua `continue`;
the harness substitutes a failing trap only in unexecuted pose loops and excludes
the unused client network half from the server probe. Executed startup/server
lifecycle bodies are the actual patched production bytes. These boundaries do
not certify Source/OpenXR/Steam Deck execution, stereo rendering or native FPS.
Existing VR and non-VR controller/HUD/Tetris/gameplay regressions remain in the gate.

The publication gate is the complete frozen integration matrix with matching
before/after source digests, full Lua syntax and independently verified receipts
and raw log hashes. **313/313 suites and 884 Lua syntax files pass**, plus all
139 mounted overlay Lua syntax probes and the 14-check focused VR gate.
All 2,529 frozen source hashes, 313 individual receipts, 626 raw stdout/stderr
hashes and canonical suite commands were independently verified. Before/after
digest: `1dc65361a1f675c12f277a0f8c8f783f140cf2ad575e547a3ab1643c187ef00d`.
The [matrix verification](STEAM_DECK_20261007_VR_IDLE_matrix.json) and
[complete raw evidence](STEAM_DECK_20261007_VR_IDLE_complete.zip) retain the
frozen manifest, changed-source bytes, targeted logs and all complete/partial
receipts. Archive: 1,438 entries, 1,248,639 bytes, SHA256
`6b2bec739ba1fb013f29bd64dcfeb5f440df8768241bbd9fedbe4a574649a713`.
Only result/evidence documentation is finalized after the frozen run; production,
overlay, installer and test bytes remain identical to that gate.

Two earlier matrices were interrupted (exit 130, no observed
failures): inspection found the held-prop motion controller outside hook/timer
ownership, then the need for dropped-NPC deletion to survive a new VR lifetime.
Their partial evidence is preserved separately; neither counts as a complete
pass. Prior HUD optimization evidence remains unchanged.

## Next native action

Fully quit GMod, pull/install main and restart `gm_flatgrass`. Deploy, then run:

`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`

Keep the established graphics/resolution/Proton/windowed settings. Play three
minutes with no VR player, checking the prior HUD/feed/history and accepted walls;
leave the game open for the final server reply. Return the same
`performance_client_latest.txt` and `console_latest.txt`. The capture automatically
records idle counts and source parity; no extra tester command or headset partner
is needed for this performance pass. Actual headset join/stereo/controller/remote
avatar acceptance remains a separate open native gate. Workshop/VPS remain held.
