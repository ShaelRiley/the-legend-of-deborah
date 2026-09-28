# Music System source gate

Baseline: `c5ece210be12077c321264ad4abb81821fe8d9a5` on main. Current author direction
explicitly changes the live GDD’s prior server default to OFF.

Final finite gate: **33/33 suites pass**, including **795 Lua syntax checks**.
The source digest was identical before and after the gate; exact command/results,
log hashes and digest are in `music/receipt.json`. `music/evidence.zip` preserves
all three runs and their logs. The first run was 31/33: a legacy movement fixture
lacked a userinfo method and the runner referenced an incorrect unread-test name.
Default-safe option access and the correct existing unread test resolved them.
The final pass includes a delayed-victory/rapid-toggle regression and rejects
unrecognized uploaded asset metadata before it can reach game state.

New production-facing contracts cover:

- role omissions, custom/default/universal resolution, valid partial catalogs,
  immutable versions, deterministic distinct/small-set assignments and frozen plans;
- calm staging/portal continuity, genuine stair geometry/reversal, grounded floor
  changes, pressure smoothing and the effective authoritative clock;
- actual native URL callback ordering through engine doubles, buffered seeking,
  four slots/two transfers, shared-asset reuse, simultaneous floor/tension changes,
  pending callback invalidation, fallback, private block starts and Off/On behavior;
- boss/Hector handoff, rescue-only one-shot receipts, missed/duplicate fanfare
  suppression, auto/interlude/off policies and next-floor staging continuity;
- original seven-role Vorbis generation, real ffprobe/ffmpeg decoding, HTTPS uploader
  contract, authenticated service, unsafe ZIP/hash/grid/loop/metadata rejection,
  atomic catalog publication, immutable versions and legacy role inheritance;
- saved Always Run semantics without changing the physical modifier or Soldier rules.

Accepted regressions reused include logger/audio, Warden/Hector/finale, clock and
Hourglass, damsel staging, native-resource lifecycle, SPOT-17 movement, Dodge,
unread-menu behavior, snapshots and manual content/transport. This is a finite
selected gate, not a claim that the entire repository matrix ran.

**Native acceptance remains open.** No Garry’s Mod process, Windows/Linux/Deck
playback, live HTTPS origin, cold-cache co-op bandwidth, visual UI review or native
memory measurement was performed here. The defaults are ready for audition, not
an accepted 32-block album. `sound.PlayURL` cannot cancel a request before callback;
Off counts/discards those requests and schedules no new transfer.

The GDD revision-guarded update returned HTTP 400 `FAILED_PRECONDITION`.
Readback revision was unchanged. `MUSIC_GDD_AMENDMENTS.json` preserves the exact
pending server-default/tuning changes; no successful design-document update is
claimed. Source publication is verified separately by the delivery commit and
remote readback. No Workshop/VPS deployment occurred.
