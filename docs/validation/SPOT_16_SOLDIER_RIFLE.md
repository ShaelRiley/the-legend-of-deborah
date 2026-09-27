# SPOT-16 — Human Soldier pulse rifle

## Frozen scope and gate (before implementation)

Recovered from the stalled thread on September 26, 2026 (America/Chicago).
Baseline main: `258c0ef6c46c2554987a7ec77862ab45433e5fcc`;
exact tree: `6d416b19a58d78ed80d888a9a8d29d12bf6d46b3`.
Restored every one of the 2,194 tracked entries from SPOT-15 Actions artifact
10921754619, including historical gitignored evidence, and verified the original
commit object. An initial ordinary git-add omitted ignored history and was rejected;
rebuilding the index from the published tree restored exact identity before editing.
No unpublished SPOT-16 implementation was recovered. The live GDD already contains
its contract in 06 and tuning/finite gate in 07; no duplicate amendment was written.

Implement only SPOT-16: current human Soldier `weapon_ar2`, committed three-round
baseline burst per primary press, shared burst/rate feats and physical damage,
role/incarnation-owned infinite ammo, zero reserve, no reload or stock secondary orb,
INFINITE HUD. Preserve Hero/AI firearms, secondary Magic policy, SPOT-15 queues,
revival, dormant Hero data and the complete earlier spot queue. SPOT-17 movement,
jumping and rooting remain separate.

The saved tuning is 0.45 s warning, 0.09 s scheduled spacing, 0.25 s recovery,
shared +0..3 burst rounds. Freeze aim at commitment. Each Soldier service emits
at most one due round; lateness greater than 0.20 s cancels rather than catches up.
Bind the exact run/state/graph/seed, player state, life, progression and owned rifle.
Cancel on death, disconnect, exit/replacement, weapon change/loss, staging, observer,
build/failure/clear/freeze, expired clock, minigame or attack-prohibiting status.

Finite checks: execute actual final loadout, primary and network input, base and
compatibility rifle methods, service and rate plan. Cover baseline/feat counts,
zero-ammo permission without writes/debits, finite Hero cost, physical attack/source,
all cancellation boundaries, no catch-up and no movement edits. Retain the 90
SPOT-15 selections plus focused Soldier rifle/client and existing burst cleanup tests, manual parity and
all Lua syntax. Preserve failed attempts/raw output. Freeze the final candidate,
run an independent exact-source gate and publish one non-forced child of the
verified baseline (stop if main changes). No Workshop/VPS actions.

## Evidence limits

Native gm_flatgrass primary input/prediction, warning/audio, INFINITE layout,
cooperative combat/attribution, cadence and balance remain pending. Headless native
boundary stubs do not establish Source engine acceptance. Existing full Gate-B
`perkDisplayName` diagnostic and earlier native acceptance debt remain open.

## Implemented source and finite verification

RunManager issues only the human Soldier AR2 with zero native clip/reserve, then
binds its existing PlayerWeaponSpecials state after authoritative deployment.
Soldier retirement, native disconnect and weapon switching retire pending burst and
cadence state. The base emitter and final economy/rate/aim compatibility chain
share the exact-source check. The former duplicate economy emitter now delegates
to the existing exception-safe emitter, preserving attack-event and lag-state cleanup.
No new scheduler, packet type, combat resolver, movement owner or persistent store.

The existing AR2 activation packet includes the existing team-context string only
for Soldiers; stale Soldier requests cannot spend a restored Hero's ammunition.
Client/server input suppresses native rifle fire and Soldier reload; secondary
Magic retains its existing input policy. The primary HUD explicitly says INFINITE.
Automatic capability selection describes a d10 burst rifle without obsolete SMG
heat or reload capability. A later legacy SMG-capability wrapper was repaired too.
Final ammo regeneration does not schedule/refill disposable Soldier reserves.
Derived ammo feat formulas and all ordinary Hero regeneration assertions remain.

Focused attempt 07 passes 988 server and 32 client production-boundary assertions
(1,020 new SPOT-16 assertions; inherited SPOT-15 assertions are additional, not
counted again). Actual loadout, base/final rifle, universal aim, rate feats, current
network context, source/d10 contract, reentrant exit and exception cleanup execute.
The existing burst-cleanup regression also passes. Canonical manual and both
readers remain 166 chapters / 32 chunks / 151 catalog entries (136 ordinary feats,
nine capstones and six fallback entries).

The final gate contract is 93 selected suites and all 753 Lua files, with
--suite-timeout 120 --workers 2. It is not the full campaign matrix. The final
frozen-source local result, independent Actions result, exact child/tree/parent and
non-forced main readback belong to the external publication receipt, not an assumed
pre-publication pass in this source document.

## Honest recovery and attempt history

Server attempts 01/02 failed because the inherited equipment test had left a
Float-only RNG boundary; restoring the complete deterministic RNG adapter repaired
the test, not gameplay. Attempt 03 omitted the native disconnect weapon-cleanup
hook; both actual disconnect-hook orders are now exercised. Attempt 04 found a
real late SMG-capability override, repaired in production. Attempt 05 passed 954.

Aggregate gate 01 passed 91/92 on an unchanged exact snapshot:
b19edc96c7dfe1ebf7efa73978dcfce6e10d017e83b5d9a09001f9cfd469e460.
Its failing SPOT-10 regression still required finite Soldier ammo regeneration.
SPOT-16 explicitly supersedes that expectation: the regression now proves no
Soldier refill while retaining every original Hero recovery assertion and every
shared derived formula. Corrected SPOT-10 validation passes 665 assertions.
Attempt 06 added the actual universal-aim wrapper (973 server, 32 client); attempt
07 adds final-wrapper native failure/reentrant-exit cleanup (988 + 32).

Raw attempts, gate-01 receipt/logs and its exact source overlay against the authentic
SPOT-15 parent are retained in the delivered recovery evidence archive. Early
focused attempts have raw output but no complete contemporaneous source snapshots;
do not call them exact-source replays. The final local and independent gates each
retain their own exact snapshot and all raw-log hashes. No earlier failure is
converted into a pass. See SPOT_16_ATTEMPT_LOGS.json for raw pre-freeze log hashes.

## Next native observation and next source checkpoint

On the installed exact gm_flatgrass build, enter Soldier play normally. Confirm
AR2 and INFINITE; tap/release once for the visible tell and three baseline rounds,
hold without repeated bursts, and verify reload changes nothing. Exit with F3
during a committed burst and confirm no later shots or Soldier gear on Hero return.
Observe ordinary Hero rifle ammunition and Magic input. Burst feats may increase
round count. Record console_latest.txt + rpg_summary_latest.txt and a short build
and observation note; detailed session only for timing diagnosis.

Next source checkpoint is SPOT-17 only: reconcile/root committed Soldier attacks
and movement restrictions approximating AI Soldiers, prioritizing readable Hero
experience. SPOT-16 itself changes no movement, jump or rooting behavior. Preserve
prior native acceptance debt and local acceptance -> Workshop parity -> matching
VPS release order; neither deployment action is authorized here.
