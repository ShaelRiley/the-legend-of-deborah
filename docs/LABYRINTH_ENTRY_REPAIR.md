# Labyrinth entry repair candidate

Branch: `astra/equipment-update`, based on remote
`d1dc306cf23bc3098f2b6a30b80ab3030a4ce72e`.
Main remains `8978796e886cdb5505d24ed0de085265fa99bac8`.

The uploaded current session begins at 12:14:56 UTC on 2026-09-15 and ends at
event 139 / game time 66.495 after DFT recreation and its equipment/wallet
snapshots. It contains no attack, damage or death events, Lua traceback, native
stack or orderly shutdown. The author reports a forced close on labyrinth entry;
the old logs have no portal-stage instrumentation. Do not infer that the previous
Soldier death candidate fixed the crash, or that this new crash occurred in combat.
DFT recreation now completes in this evidence; the earlier SQL error is absent.

Evidence SHA-256:

- `rpg_test_session(20260915-121839).txt`: `0fe1aa9c1115900a98b4745bad257018b328818c42f54f96f7b7f6d16dd84d3d`
- `console_latest(20260915-121839).txt`: `a10caf7d0f4d04f2923fd726cfcd85248774cce45a52bc25c45c7439183fedc0`

## Change and limits

Both portal input routes share `Staging:DeployPlayer`. It previously changed the
player's position, synchronized state and spawned native pickups synchronously
inside KeyPress/Use. KeyPress is predicted, and the engine documents SetPos
limitations during movement processing:
[KeyPress](https://wiki.facepunch.com/gmod/GM:KeyPress),
[SetPos](https://wiki.facepunch.com/gmod/Entity:SetPos).
Queue the transition for the next timer turn, after input processing unwinds.
Keep the player staged until commit; preserve normal prerequisites, loot and
CryptoDirector participation. Coalesce repeated input and cancel requests when
the player, character, active slot, run, level, seed or admission conditions change.
Developer ingress retains its existing separately authorized console path.

`STAGING_DEPLOY_STAGE` now records queued, begin, before/after teleport,
after player sync, after static loot and complete (or cancelled). The last complete
marker is after the existing crypto wrapper returns. These use the current
developer logger and its session mirror, without per-frame traffic or disk writes.
This repairs an unsafe execution boundary; a native crash has **not** been
reproduced or causally established in the headless environment.

The statue was incorrectly hardcoded to Alyx and shiny gold. It now uses
`LOD.Config.Models.Deborah` (reserved Female_01), stock granite and a neutral gray
tint. Place it beyond the portal, opposite the Hermit, with an 80-unit lateral
offset limited by room width. Freeze the closest crossed-arm citizen idle frame
by measured hand/shoulder geometry across the three LineIdle sequences, rather
than assuming a model-specific numeric sequence ID. Apply lowered brows, narrowed
lids and downturned mouth flexes. Pose evaluation runs once after model spawn;
no ragdoll, extra client model or recurring bone callback is added. The developer
log records the selected sequence and whether hand geometry crossed. Actual
model appearance, including arm pose and granite UV appearance, needs Source
visual acceptance. Wallet prompt and use validation remain intact.

The live GDD read followed 00 → 01 → 06; LOD-UI-009 was updated and read back to
reflect the author's placement/model/granite/pose correction. Other gameplay
rules and the earlier Soldier diagnostics are preserved.

## Validation and next action

All 76 integrated automated suites pass. The production ingress harness proves
no teleport or loot spawn during input handling, one queued transition, successful
normal admission, and cancellation across 13 changed-state cases. Existing
presentation checks prove opposite-portal placement and the rebound Use prompt.
These are headless checks, not native-crash or visual acceptance.

Fresh-start gm_flatgrass, inspect Deborah, then enter the portal normally.
If it force-closes, preserve `console_latest.txt` and `rpg_test_session.txt` before
reopening Garry's Mod. The added stage events will narrow server transition
failure versus a fault after completed deployment. If those complete and the
process still closes silently, a native crash dump is needed to identify the
engine/renderer fault rather than continuing speculative gameplay changes.
