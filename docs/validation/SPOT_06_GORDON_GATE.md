# SPOT-06 finite gate — defined before implementation

Parent: `664762a55d096c628ed5a2faff6da6c97c16cf03` (SPOT-05).
Scope: Gordon phase one only. Live GDD 00 → 01 → 05 LOD-SPOT-06 and 07
LOD-SPOT-06 candidate rules were read during recovery. Those rules already existed
in the stalled thread's live design; this recovery does not duplicate or replace them.

## Observable contracts

Execute the real Warden, hit-feedback and client-presentation modules against
boundary doubles. Prove a first positive visible hit opens one 1.2-second window;
later hits cannot extend it or the reveal+4.0-second ceiling. Invisible/arriving
ordinary hit-stun cannot pin/reveal him; damage and shared status rules remain.
The independent Warden service must enforce deadlines even while AI is stunned.
Cancel unreleased shots without replaying or prematurely expiring released ones.

Prove 3-second physical relocation, a fixed .45-second destination warning that
restarts after displacement, then the separate .65-second attack warning and four
orbs. Departure lasts .45 seconds. No SetPos teleport or damage immunity is added.
Taunts last .8 seconds with a shared 6-second cooldown, 4-second context horizon,
one speaker, and an ordinary attack appearance between taunts.

Exercise exact run, epoch, campaign seed, run ID, dungeon level/seed, graph,
Warden record, actor-state, native owner and phase-cycle ownership. Cover phase
exit, death/removal, reset/replacement, failure/clear/unready, freeze/no targets,
shared Held/Muted/Push restrictions, and no duplicate progression or rewards.

Transport no more than two finite cues per actor / ten total through the existing
.2-second snapshot. Late joins see only current cues, no replayed sound. Test actual
client decoding, expiry, two-second snapshot timeout, 6000-unit culling, cleanup,
and distinct departure/arrival geometry retained in reduced effects.

## Fixed selection

`python3 tools/test_spot06_gate.py --output /tmp/lod-spot06-gate`
retains SPOT-05's 33 Lua suites and adds nine: focused SPOT-06, Warden encounter,
Warden health, Hector encounter, Hector health, Hector presentation, Deborah
finale presentation, native resource lifecycle and native Shotgun path. Manual,
population manifest, Crate assets, whitespace and all-Lua syntax make **47 suites**.
Four workers maximum; 45 seconds per suite; per-suite logs/receipts written on
completion, unchanged-source snapshots, and earlier attempts retained. B29 uses
`--runtime`, not the extra twenty-seed exposure sweep. No full-matrix claim.

Reconcile canonical manual and both generated renderings. Run the exact frozen
candidate independently in GitHub, verify its tree and non-forced main parent/SHA.
Native Source timing, visibility, audio, combat feel and cooperative acceptance
remain separate. No Workshop/VPS actions, force-spawn testing or adjacent queue work.
