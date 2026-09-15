# Campaign clock and TIME OVER — 2026-09-15

Development branch: `astra/equipment-update`; continuation baseline `af5b4f7`.
No main promotion, VPS deployment or Workshop publication is included.

## Authority

Read the live GDD entrypoint/index and relevant Core Loop / Lifecycle rules,
including LOD-TIMER-001, plus its exact Time Over HUMAN detail. The explicit
2026-09-15 handoff overrides two older GDD rules: the clock now belongs to the
whole campaign, and rescuing Deborah does not cancel or reset it. This is an
implementation of that handoff, not a routine rewrite of the live document.

## Implemented lifecycle

The successful staging deployment transaction starts one server SysTime deadline
immediately after the first Hero's teleport. It is absent before that moment and
cannot be restarted by later entrants, deaths, respawns, Soldiers, spectating,
intermissions, generated levels, or reconnects. It lives on campaign state, not
level state. One-second snapshots carry the campaign epoch, started flag,
remaining time and terminal/cinematic state; clients interpolate between them.
The production limit is fixed at 1,800 seconds. Warnings occur at 10, 5 and 1
minute, then 30 and 10 seconds, using existing announcements/dialogger observers.

A 20 Hz service checks the deadline independently of the game's simulation freeze.
`sv_hibernate_think` is temporarily enabled if necessary, then restored on failure
or reset. SysTime still catches up across any hibernation gap. Expiry checks also
precede CompleteLevel, AdvanceLevel, BuildCurrentLevel and TryActivatePlayer, so
an expired rescue cannot enter XP, wallet, celebration or next-level wrappers.

Expiry commits RunManager:FailCampaign immediately and uses its once-only
FinalizeCampaignRun/leaderboard authority. It clears the pending intermission and
prevents further gameplay. Native player moves, weapon removal and entity cleanup
run in Think, outside the Touch/damage frame that may discover expiry. Failure is
not implemented as player kills or additional life losses. If empty at expiry,
mark failure immediately and start presentation when a human reconnects.

## Presentation and engine budgets

- A 3-second camera pullback fits bounds computed from the actual generated cells,
  including Gordon's extra wing. The wall shell rises 900 units over two seconds
  for the magical suspension reveal; ordinary gameplay geometry is unchanged.
- At 4 seconds, failure propagates across the prison for seven seconds. Existing
  client container models tumble and scatter using deterministic absolute-time
  transforms. Their positions remain as a collapsed ruin after the sequence.
- Existing server geometry is removed in the same spatial wave, at most 96
  entities per service tick. The immutable wall manifest remains available to
  late clients until the canonical next build replaces it.
- At most 24 real server `prop_physics` stock cargo containers, created at most
  two per service tick, add gravity, tumbling and actual collisions. Mass 600,
  outward velocity 220 and upward velocity 100; no constraints or damaging blasts.
  At 22 seconds they are frozen in place. No thousands-of-bodies physics restart.
- 33 explosion beats at three per second span the structure. At most 24 fire/smoke
  sprites are drawn concurrently; reduced effects halves the retained beats.
  Stock one-shot alarm/explosion audio is mixed locally for the distant camera.
  No new emitters, lights, external models, sounds or Workshop dependencies.
- Owned HUD/camera/input callbacks are temporarily guarded, with exact callback
  restoration on reset. Ordinary HUD and held weapons are suppressed. TIME OVER
  occupies the top letterbox, with the restart prompt below after settlement.
  Existing menus close and pending victory cues are invalidated.
- SetupPlayerVisibility includes the exterior camera and the bounded physics
  actors. Late clients receive current phase and can reconstruct the same ruin
  without replaying elapsed explosion beats.

Restart requests use the existing `LOD_RestartCampaign` message and its
RestartFailedCampaign guard/epoch transaction. Requests are rejected until the
server says aftermath is ready; only the first simultaneous request schedules a
new campaign. E uses a fresh physical keypress and ignores held input from the
cutscene. Cleanup removes the native wreckage; NewCampaign resets level, state,
roster and timer, and the normal builder replaces the wall manifest. New staging
again waits for first Hero entry. Admin map cleanup does not regenerate a timed-out
campaign: client ruin remains, though native props removed by that command stay
removed. Map changes/server restarts use their ordinary fresh-campaign lifecycle.

## Verification

`python3 tools/test_checkpoint_g_integration.py`: all 90 suites pass, including
repository Lua syntax, geometry/enemies, equipment, lifecycle, RPG and prior
protected regressions. The new production-code harness verifies untimed staging,
Soldier rejection, exactly-once start, continuous deadlines through changed level
and freeze state, expired rescue rejection before rewards, empty-server failure,
late viewer initialization, once-only finalization, bounded physics and removal,
early/duplicate restart rejection, real NewCampaign cleanup, stable wreckage
transforms, real server/client packet round-trip and HUD restoration.

Source/Garry's Mod is not installed in this work container. Automated checks do
not establish camera readability, native collision performance, audio balance,
or real-client acceptance. The preceding branch's native-crash investigation and
release hold remain open; this feature does not claim to close them.

Engine API references checked: [SysTime](https://wiki.facepunch.com/gmod/Global.SysTime),
[visibility](https://wiki.facepunch.com/gmod/GM:SetupPlayerVisibility), and
[input commands](https://wiki.facepunch.com/gmod/GM:StartCommand).

## One integrated playtest

Fully quit Garry's Mod, then install this candidate:

```bash
cd ~/Downloads/the-legend-of-deborah && git fetch origin astra/equipment-update && git switch astra/equipment-update && git pull --ff-only origin astra/equipment-update && bash tools/install_dev.sh
```

On gm_flatgrass with a second client if available, leave one Hero in staging while
another enters: the shared clock must begin only on that entry. Continue through
one rescue into next-level staging and confirm it is still counting down. Enter
the next maze, then use this one-line host/admin console batch:

```text
lod_dev_timeout_in 10; lod_campaign_clock_status
```

The command shortens an already-started clock and marks this campaign unranked.
Watch both clients reach TIME OVER, including any spectator/staged client. Try E
during collapse: it must do nothing. After 22 seconds, inspect the persistent ruin
and have both clients press E: exactly one fresh Level 1 should appear, with no
stale camera/overlay and a fresh clock awaiting first deployment. Enter again to
confirm a new 30:00 countdown. Capture a short video plus `console_latest.txt` and
`rpg_summary_latest.txt`; use `lod_campaign_clock_status` if state is ambiguous.
