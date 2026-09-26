# SPOT-11 — four-choice ordinary feat drafts

## Pre-code decision and finite gate

Author request: the single SPOT-11 bullet in `briefs/SPOT_UPDATES.md` and the
uploaded SPOT-11 handoff. Gameplay parent verified before editing:
`85db2ed5ce287e7dbd96197676af4799922a6bf6`, tree
`de96ff49254a961cdbb8dc7f1a1bc76f34981776`. All 2167 tracked entries were restored
from the independent SPOT-10 source archive and matched their Git blob IDs; the
authentic commit object and exact tree were restored, not synthetic ancestry.
Direct container Git transport was unavailable; connector reads verified main.

Read AGENTS, DEVELOPMENT_PLAN, SPOT_UPDATES, SPOT_10_SECOND_PASS_IMPLEMENTED,
TEST_LOGGING and live GDD 00 -> 01 -> 04/06/07. The exact HUMAN eligibility
paragraph (475052..478376 before editing) confirms ordinary-first, legal neutral
fallbacks, intrinsic qualification, no duplicate IDs and no illegal filler.
The author expressly changes the old count of three; this is not a capstone or
feat-effect rebalance. Live normalized draft rules must be reconciled before
source changes. The already-approved D-J section is retained without duplication.

### Contract

- New ordinary slots at levels 1/3/6/9/12/15/18 target four distinct eligible IDs.
  Draw ordinary candidates first; fill only from eligible existing neutral
  fallbacks. Keep all prerequisites, actor/capability restrictions, weights,
  rank replacement and stable named RNG streams.
- Genuine combined pools of 1-3 produce exactly that many distinct choices, with
  exactly one result. No duplicate filler or eligibility relaxation. A truly
  empty combined pool stores an explicit exhausted, resolved, no-award slot:
  no selected ID, no stack/ability gain, no crash or impossible blocking choice.
  It is not counted as a chosen feat. This is a bounded exceptional case, not a
  new fallback perk. Stored empty hands do not reroll on reopen either.
- Store `offerLimit=4` on newly generated hands. Existing valid hands, including
  unversioned three-card pending/resolved hands, retain their exact IDs, order,
  seed and result. Do not add a fourth card to a pending hand. Existing canonical
  removed-ID repair retains its historical three-slot target for unversioned
  hands; new hands repair toward their recorded four-slot target, legally only.
- A nonempty hand can commit exactly once, in chronological ordinary-slot order.
  Preserve duplicate/stale-level rejection, Hero/Soldier authority and dormant
  Hero persistence across death, role change, rejoin and dungeon transition.
  Automatic AI/human-Soldier selection considers all stored offers; it is seeded
  and idempotent, with no human-Soldier choice UI. Level-20 class capstones remain
  the exact fixed class trio. Magic Form/Content choices are unaffected.
- Snapshot and responsive scrolling sheet show every offer and selected state;
  four cards use two columns when width permits, otherwise one. Existing
  capstone layout remains unchanged. Manual and validator counts must agree.

### Finite validation frozen before implementation

Add focused production-path tests for all three classes and actor scopes,
ordinary levels/capstones, actual fourth-offer commit and automatic selection,
distinctness/qualification/fallback caps, pools 0..4+, seed isolation, exact
legacy-hand preservation and bounded canonical repair, once-only/stale/role
contracts, snapshot and real client-layout callbacks at narrow/wide widths.
Retain all 72 SPOT-10 D-J selected suites, plus relevant progression/UI/lifecycle
regressions. Run full Lua syntax and manual parity; assert no source changes
during each final staged gate. Store raw failed attempts honestly. Repeat the
same frozen tree independently before a non-forced child publication.

These gates are finite headless evidence, not the full campaign matrix, native
balance, native Derma readability or Source co-op transport acceptance. Native
acceptance uses a fully restarted exact installed build on gm_flatgrass, normal
feat opportunities and console_latest.txt + rpg_summary_latest.txt plus a short
observation. No dedicated Razor test; no Workshop or VPS action authorized.

## Results

The implemented source passed the pre-closeout gate: **79/79 selected suites,
726 focused progression assertions + 329 focused client assertions (1055 new
numbered assertions), and 744 Lua-file syntax checks**, unchanged during the gate.
All 72 prior D-J selections remain; the seven additions cover drafts, four-card
client callbacks, full Character Sheet, Magic grants, Skeleton profiles and both
Skeleton event integration/lifecycle paths. SQLite suites use their existing real
SQLite harness, not the plain Lua runner. See SPOT_11_PRE_CLOSEOUT.json.

The local frozen gate and independent runner must repeat this selection after all
closeout files are staged. Their source hashes, exact tree, authentic child commit,
run identity and non-forced main verification belong in the external publication
receipt; this document does not pretend to contain its own future commit hash.

Live GDD edits were revision-guarded and read back: LOD-FEAT-002/003 and the
Skeleton hand reference in 04, the exact HUMAN eligibility paragraph, and the
finite gate in 07. Existing D-J approval and the Level-20 capstone trio were not
rewritten. Generated manual readers have the same updated ordinary draft contract.

### Preserved failed and incomplete attempts

SPOT_11_ATTEMPTS.tar.xz preserves exact raw bytes and per-entry SHA256 values.
The initial retained run was **71/72**, failing snapshot_delivery's old three-card
assertion. Its correction now proves four distinct delivered cards and commits the
fourth for Fighter, Rogue and Wizard. The first completed expanded run was
**78/79**: the Soldier-sheet fixture counted opportunities instead of committed
results. It now explicitly tests two selected hands plus an exhausted no-award
slot; it does not weaken the production count to conceal exhaustion.

Focused iteration 1 exposed a real late automatic-commit wrapper discarding the
success result; both rank-replacement and Magic-grant wrappers now propagate and
gate on that result. Iteration 2 corrected a real-growth fixture that accidentally
qualified one fewer fallback than intended. Iteration 3 marked a historical
removed-ID fixture as historical rather than already canonical. Iteration 4 passed
716 assertions. Iteration 5 exposed the pre-existing Gate-B identity diagnostic's
obsolete perkDisplayName assumptions; the draft-shape helper is shared by B/C,
but the final focused gate executes complete Gate C and does not claim complete
Gate-B identity validation. The final draft count is 726 after positive/negative
real Gate-C checks for legacy, small, empty and malformed hands.

Three early aggregate launches were interrupted by foreground tool timeouts and
have no completed receipts. Their partial successes are not aggregate passes.
The first also ran two SQLite suites with the wrong launcher; later runs use the
existing SQLite bridge without changing those suites. A streaming-session launch
was unavailable and did not execute a gate. The first completed expanded receipt
is the 78/79 attempt above; the following complete pre-closeout gate is 79/79.
None of this supersedes SPOT-10's preserved preflight or fixture failures.

### First independent runner timeout and explicit budget correction

Independent run **36280170654**, attempt 1, tested the previously frozen tree
`b10f2f95bb5af90f36f94676dbe1991f74ab05ea` and completed **78/79**. The unchanged
full `test_event_skeleton_blockade.lua` hit the harness's 45-second wall-clock
limit (return code 124); the other 78 suites passed, all 744 Lua files parsed,
and source-before/source-after matched. Publication was skipped. This is a
failed independent gate, not a pass or a native performance finding.

`SPOT_11_INDEPENDENT_TIMEOUT.tar.xz` preserves its raw output, receipt, failing
suite and artifact provenance. The correction exposes an explicit bounded
`--suite-timeout` choice of 45 (unchanged default) or 120 seconds and records the
budget/worker count. It changes no test assertion, seed, selection or gameplay.
The final source must be re-staged and the entire 79-suite gate rerun locally and
independently with `--suite-timeout 120 --workers 2`. Exact final tree/hash and
publication evidence remain external; the earlier local 79/79 and independent
78/79 are tied to their own source and never relabeled.

### Native acceptance still open

On the exact updated local build, fully restart Garry's Mod on gm_flatgrass.
At a new ordinary opportunity, confirm four legible, distinct cards, then choose
the fourth: one selection resolves the hand and the sheet/deployment state updates.
An existing pending trio must retain its IDs, order and fingerprint across reopen,
death/rejoin and role changes; the next newly earned hand may have four. In normal
co-op, Soldier control remains automatic/read-only and must not alter the dormant
Hero hand. Reopen at a narrow and wide resolution; scrolling must reach all cards.
Do not force an impossible empty pool or dedicated Razor test in normal play.

Return console_latest.txt + rpg_summary_latest.txt and a short observation from
that installed build. A detailed session is only for timing diagnosis. These
headless tests are not native balance/movement/Derma/co-op acceptance or the full
campaign matrix. No Workshop/VPS action occurred; preserve local acceptance ->
Workshop 3791535712 package/source parity -> matching VPS.
