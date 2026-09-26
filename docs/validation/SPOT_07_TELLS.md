# SPOT-07 — observer-specific Fake Gordon tells

## Authority and isolated scope

September 26, 2026. Actual canonical parent:
`c9ddf8cb7d1952ce831d2fdb361c4092ebb85f7d`, tree
`95b9937b6dce2a618a6d0fd0f532a83334384776`. A credential-free actual shallow
checkout was exported by independent GitHub run **36258687818**, and its commit,
complete tree and clean working directory were verified before editing. The
infrastructure-only `checkpoint/spot07-c9ddf8cb` branch is not a gameplay parent
and must never be merged into main.

Live GDD 00/01 and relevant 03/05/06/07/HUMAN rules were read. New SPOT-07
sections in 05/07 were reconciled and read back before gameplay edits; their
revision and the finite acceptance contract are in [the gate](SPOT_07_TELLS_GATE.md).
Existing SPOT-06 candidate sections were not duplicated. Optional fart-on-hit was
considered and omitted: recognition is visual, without another audible identity
channel or new sound asset. Existing-feat balance and SPOT-08/09 are untouched.

## Implemented presentation and authority

A living, deployed cooperative Hero receives private recognition only within
`max(0, derived wisMod / 2) * Maze.CellSize`. No rounding: with the existing
384-unit square, +1 reaches 192 units and +3 reaches 576. Zero/nonpositive or
nonfinite Wisdom grants no observation. Distance is inclusive 3D origin distance,
not a graph/square/planar approximation. A separate eye-to-body visibility trace
rejects solid starts and intervening world/actor cover; hitting the observed
clone itself is permitted. The client's actual current distance/visibility,
role/life, phase, cloak and native retirement are checked again before art.

Within that Hero's range, a fake has a subtly green body and pig mask, protruding
pink tongue and an intermittent wink. Each 2.4-second cycle chooses either eye
from an isolated named cosmetic RNG stream; two initial mixing advances avoid
first-draw correlation between neighboring cycle labels, then one binary choice
is made. The eyelid closes for .35 seconds. Full/reduced effects preserve the
same tongue, eyelid and tint semantics. No extra model or native entity is added.
Body modulation multiplies existing class/status tint by .86/1/.90 and restores
prior render state even when DrawModel raises an error. Missing face attachments
or bones fail safely instead of drawing floating art.

An actually admitted shared hit-stun supplies a distinct sideways upper-body/arm
recoil lasting at most .35 seconds and no longer than the existing stun. A
rejected/duplicate stun cannot refresh it. It adds no damage, roll, stun duration,
invulnerability or HP. Retiring the recoil preserves an active ordinary SPOT-06
taunt pose; archetype replacement clears its bone manipulation. Actual phase-one
follow-up remains 1.2 seconds from the first effective visible hit, nonrenewable
and bounded by reveal+4 seconds. Hidden/arriving stun admission, released fuses,
unreleased-shot cancellation and all shared Held/Muted/Push rules are unchanged.

The existing .2-second Warden service sends at most four private clone records
per eligible observer, with fixed server-time .4-second leases. The private wire
has no client-to-server request handler. Canonical derived stats and exact
run/epoch/campaign/level/seed/graph, Warden/clone-state membership and native owners
admit records on the server. Generic native visual-life tokens apply to real and
fake Wardens alike; observer tokens bind Hero state/profile/shared life/ordinal.
The client accepts at most .05 seconds of future clock skew but does not draw
before the packet's sent time; the .45-second lease-length validity ceiling
allows float serialization tolerance and never extends the server deadline.

Death/removal, stale owners, failed/cleared/unready worlds, freeze/no targets,
role/incarnation changes, cloaking, phase changes, cleanup and expired snapshots
suppress observations. New statistics/visibility are sampled at the .2-second
service cadence; remote updates are not a zero-latency claim. Cached visibility
is evaluated at most once per admitted actor per frame. Up to four previously
recoiling actors are revisited for cleanup; no full-world render scan, per-actor
hook, permanent discovered-clone cache or additional prop allocation is used.

The old unconditional network name `Fake Gordon Clone` and clone ordinal were
removed; all display as `Gordon the Warden`. Server-only clone membership and
identity remain. Ordinary boss-bar/HP inference and legitimately acquired
Omniscience information are unchanged; this is not an anti-cheat guarantee.
Clone count/HP, all three phases, sixteen-hazard cap, resupply, lethal callback
ordering, Gordon -> Hector -> Jail Key -> rescue, XP and rewards are preserved.

## Evidence and limits

First complete local preflight: **130/130 focused production assertions,
50/50 selected suites and 734 Lua-file syntax checks**, all source unchanged.
That preflight's before/after source SHA256 is
`71df5ee71ed0c702c9e77d5ab16c9af461ef3270ac676b104e9931d3676d0cce`.
It predates these documentation receipts and is not the final published tree.
The exact final source must be frozen and rerun locally and independently;
final source/parent/tree/child SHA and run ID belong in the delivery receipt.

`tools/test_spot07_gate.py` retains all 47 SPOT-06 selected suites and adds
`validate_spot07_tells.lua`, monster identity and Wisdom-information suites.
B29 uses existing `--runtime`, not the additional twenty-seed exposure sweep.
Each suite has a 45-second bound with at most four concurrent workers. Per-suite
logs, hashes and source-before/after receipts live outside the source tree.
This is **not a full campaign-matrix pass and not native acceptance**.

The focused test executes real Warden admission, private encoder/decoder,
canonical derived-stat lookup, shared hit-stun/hurt-pose wrappers, mask/body art,
and pose/cleanup. Boundary doubles supply Source entities, clocks, traces and
render operations; they do not simulate native networking/geometry or establish
visual placement, game feel, frame cost or multiplayer acceptance. Failed and
superseded attempts are recorded in `SPOT_07_ATTEMPTS.txt`, not relabeled passes.

The legacy Warden fixture now asserts server-only clone ordinal, no public fake
ordinal, ordinary display name and generic visual lifetime. Its clone count,
HP, phase and progression checks remain. The canonical `docs/manual/book.json`
and both generated renderings describe personal Wisdom-gated recognition and
unchanged stun duration. Manual content/transport tests pass. No PDF was created.

## Native acceptance remains open

Fully quit/restart GMod before installing this revision; do not validate a mixed
hot load. Observe ordinary clones from Dungeon 4 onward; developer test exposure
must remain separately labeled and does not prove release pacing/population.
Use two deployed Heroes with different Wisdom and compare the same visible
clone. Verify half-square/exact/outside distance, cover and the upper gallery,
zero/negative Wisdom, cloak and all three phases. Check that only the eligible
Hero sees the wink/tongue/tint/recoil; real Gordon remains ordinary. Compare
full/reduced effects, native mask placement, taunt/recoil transition, ordinary
hit-stun and the SPOT-06 follow-up deadline. Verify death, role change, rejoin,
PVS loss, reset and network/frame behavior. No new sound requires listening.

Provide a visual report or clip with the exact installed/mounted revision,
console_latest.txt and the available same-session rpg_summary_latest.txt; record
logger mode because a staging-only/release-disabled RPG log is not gameplay
coverage. Prior native gates remain open. No Workshop publication, VPS deployment
or restart is authorized or performed by this checkpoint. Release order remains
local acceptance -> Workshop item 3791535712 parity -> matching VPS.
