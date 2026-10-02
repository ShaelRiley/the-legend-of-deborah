# Gordon phase-one dancefloor checkpoint

Parent: `f1a6c6708acb1afff72c3487fe96b73c17298d9c` (MS3 sixteen-bar source integration).
Scope: the author's request for fourfold post-shot exposure, more frequent and longer taunts, new dances and physical court-crossing movement. Source changes only; no Workshop publication or VPS deployment.

## Implemented behavior

The old two-second post-warning salvo budget included three 0.22-second gaps. Its nominal quiet tail was therefore 1.34 seconds, not two seconds. The new quiet opening lasts **5.36 seconds after the actual fourth orb release**: exactly four times that baseline. The pre-completion salvo budget becomes 6.02 seconds. A 13-second absolute cap from reveal keeps delayed volleys finite while accommodating the full final-shot window.

Every completed volley now enters a traveling dance instead of firing again. Standalone taunts last **6.4 seconds** instead of 0.8, with their minimum cooldown reduced from six to three seconds. Effective hits cancel unreleased shots but neither truncate nor renew the promised visible/dance deadline. Ordinary hit-stun retains its fixed, nonrenewable 1.2-second follow-up allowance. No damage multiplier or immunity was added.

Four citizen-rig moves rotate through shoulder shimmy, hip shake, swaggering disco strut and arm-sweep flourish; the flourish changes every 1.6 seconds. Captions follow Gordon. Movement is real, server-owned Motion V2 travel toward the farthest same-floor court endpoint, with court-only path filtering and half-second bounded route retries. Blocked routes hold safely. Shared Held/movement restrictions, clone ownership, freeze, target loss, phase transitions and death remain authoritative. The original bomb/crowbar phases and shared damage/progression/reward systems are unchanged.

The two focused modules load immediately after the existing Warden owners. Both original Warden files remain untouched. Loader changes are limited to the two includes and one client-distribution declaration; original loader bytes were verified against their Git blob hashes before editing.

## Validation performed

`python3 tools/test_warden_dancefloor.py` loads selected actual production Warden state, phase, lifecycle and volley methods, then runs the new server/client modules. It requires the system Lua 5.4 shared library. An optional `--phase-source` argument permits an independently retrieved production-method excerpt.

Local result: **19/19 focused behavior checks**, **four Lua syntax checks**, and server/client load-order/distribution assertions passed. Actual output is in `WARDEN_DANCEFLOOR_TEST_OUTPUT.txt`. This session used the retrieved production-method excerpt because a full repository checkout was unavailable. Engine motion/navigation, rendering, entities and selected subsystem boundaries are mocked. The full repository integration matrix, real Source collision, citizen-rig appearance, native difficulty and Steam Deck frame-time acceptance were **not** run or established.

Coverage includes actual-release timing including a late fourth shot; early and repeated hits; nonrenewing deadlines; standalone audio onset; all four clone slots; move rotation; bounded court routing and blocked paths; Held/hit-stun; freeze/target loss/invisibility; stale owner/cycle and death; later bomb/crowbar behavior; non-Warden delegation; client pose variety/cache; private clone recoil priority; missing bones/model replacement; and cleanup/seating/caption expiry.

## Design synchronization and next gate

Live GDD tabs 00/01 and the targeted SPOT-06 world/tuning rules were read. A revision-guarded, additive amendment to tabs 05/07 was attempted. Google rejected the write with HTTP 400 `FAILED_PRECONDITION` ("Precondition check failed."). The live GDD was not updated; the exact requested text is preserved in `WARDEN_DANCEFLOOR_GDD_AMENDMENT.md` for reconciliation. Existing historical plans and MS3 evidence are preserved.

Next native action: update/install this exact source checkpoint, fully restart Garry's Mod, and fight Gordon on `gm_flatgrass`. Check the longer opening after his fourth orb, sustained damage opportunities during dances, visible floor-crossing shimmy/shake/strut motion, correct hurt/phase transitions and normal bomb/crowbar phases. Native acceptance precedes any Workshop publication and matching VPS release.
