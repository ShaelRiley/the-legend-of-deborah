# Dungeon collapse clock and TIME OVER — updated 2026-09-16

Development branch: `main`; build `collapse-recovery-20260916-01`.
No VPS deployment or Workshop publication is included.

## HUD follow-up

The ordinary countdown now occupies a dedicated upper-left row at `(22, 72)`,
below the run/card readout. It no longer shares the objective's upper-right top
band or grows leftward into long/wrapped goal text. TIME OVER letterbox placement
is unchanged. The production timer harness records the normal draw call and locks
its anchor and alignment.

## Authority

Read the live GDD entrypoint/index and relevant Core Loop / Lifecycle rules,
including LOD-TIMER-001. The 2026-09-16 author correction supersedes the earlier
campaign-wide countdown. The normalized rule now explicitly gives every dungeon
a fresh 1,800 seconds, paused after rescue and throughout return staging.

## Implemented lifecycle

The successful staging deployment starts a server SysTime deadline immediately
after the first Hero's teleport into each dungeon. Successful rescue clears that
deadline, restores hibernation ownership, resets warning state and broadcasts
30:00 paused. Victory/intermission, generation and next staging do not consume it.
Later entrants, deaths, respawns, Soldiers, spectating, reconnects and regeneration
of an uncleared dungeon do not reset an active deadline. The clock is stored on
campaign state but its deadline belongs to the current uncleared dungeon.
One-second snapshots carry the campaign epoch, started flag,
remaining time and terminal/cinematic state; clients interpolate between them.
The production limit is fixed at 1,800 seconds. Warnings occur at 10, 5 and 1
minute, then 30 and 10 seconds, using existing announcements/dialogger observers.

A 20 Hz service checks the deadline independently of the game's simulation freeze.
`sv_hibernate_think` is temporarily enabled if necessary, then restored on failure
or restart/reset. During a collapse, ownership continues through the automatic
restart deadline, including an empty server. SysTime still catches up across any hibernation gap. Expiry checks also
precede CompleteLevel, AdvanceLevel, BuildCurrentLevel and TryActivatePlayer, so
an expired rescue cannot enter XP, wallet, celebration or next-level wrappers.

Expiry commits RunManager:FailCampaign immediately and uses its once-only
FinalizeCampaignRun/leaderboard authority. It clears the pending intermission and
prevents further gameplay. Native player moves, weapon removal and entity cleanup
run in Think, outside the Touch/damage frame that may discover expiry. Failure is
not implemented as player kills or additional life losses. If empty at expiry,
mark failure immediately and start presentation when a human reconnects.

## Presentation and engine budgets

- A 3-second camera pullback frames bounds computed from the actual generated cells,
  including Gordon's extra wing, from opposite the native Flattywood sign.
  Downward pitch40, FOV110, a 160,000-unit far plane and stand-off1.6× bounds
  radius preserve the prison
  foreground and sign backdrop instead of the former overhead view. The wall shell rises 900 units over two seconds
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
RestartFailedCampaign guard/epoch transaction. Requests are rejected until five seconds after the server finishes the
collapse and bounded cleanup. Twenty seconds after that same completion point,
the server automatically invokes the existing restart authority. Only the first
accepted request schedules a campaign; repeated service ticks and simultaneous
clients cannot duplicate it. E uses a fresh keypress and ignores held input from
the cutscene. Both countdowns use server snapshot durations, interpolated locally. Cleanup removes the native wreckage; NewCampaign resets level, state,
roster and timer, and the normal builder replaces the wall manifest. New staging
again waits for first Hero entry. Admin map cleanup does not regenerate a timed-out
campaign: client ruin remains, though native props removed by that command stay
removed. Map changes/server restarts use their ordinary fresh-campaign lifecycle.

## Verification

`python3 tools/test_checkpoint_g_integration.py`: all 104 suites pass, covering
repository Lua syntax, geometry/enemies, equipment, lifecycle, RPG and prior
protected regressions. The new production-code harness verifies untimed staging,
Soldier rejection, exactly-once start per dungeon, reset after successful rescue,
paused intermission/staging, unchanged deadlines during regeneration/freeze,
expired rescue rejection before rewards, empty-server failure,
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
cd ~/Downloads/the-legend-of-deborah && git fetch origin main && git switch main && git pull --ff-only origin main && bash tools/install_dev.sh
```

On gm_flatgrass with a second client if available, leave one Hero in staging while
another enters: the shared clock must begin only on that entry. Continue through
one rescue into next-level staging and confirm it stays at 30:00, with every
weapon and item retained. Enter
the next maze, then use this one-line host/admin console batch:

```text
lod_dev_timeout_in 10; lod_campaign_clock_status
```

The command shortens an already-started clock and marks this campaign unranked.
Watch both clients reach TIME OVER, including any spectator/staged client. Try E
during collapse and the first five seconds of aftermath: it must do nothing.
Inspect the ruin, prison framing and Flattywood backdrop. Allow 20 seconds of
aftermath without input: exactly one fresh Level 1 should appear. In a second
run, have both clients press E after five seconds: the same reset should occur, with no
stale camera/overlay and a fresh clock awaiting first deployment. Enter again to
confirm a new 30:00 countdown. Capture a short video plus `console_latest.txt` and
`rpg_summary_latest.txt`; use `lod_campaign_clock_status` if state is ambiguous.

## Native-map framing evidence

The stock-map BSP mirrored at
https://github.com/sbarisic/libTech/blob/568d0653a9d7832d7a91253db701c88714dc46ec/libTech/content/maps/gm_flatgrass.bsp
contains GM_CONSTRUCT/FLATSIGN faces centered near (-5099.77,236.30,-15432).
Its sky_camera origin is (32,0,-15040), scale16. The resulting apparent sign
center is (-82108.37,3780.76,-6272), on the negative-X side of the prison. Only
this derived camera bearing is used; no BSP or external assets are shipped.

## Client geometry after resynchronization

[Facepunch's OnRemove contract](https://wiki.facepunch.com/gmod/ENTITY:OnRemove)
explains that a client full update can remove an entity locally without another
Initialize call when it returns. The prior floor/gate registries dropped those
entities permanently. Full-update removals now preserve registry membership;
NotifyShouldTransmit(true) restores it, including keycards and the jail door
which shared the same defect. Real removal still deregisters; render hooks skip
invalid entities. Static-box bounds refresh on transmission recovery.
Regression: `tools/test_geometry_fullupdate.lua`. Native reproduction: on a
local developer session with cheats enabled, `cl_fullupdate` must retain the
floor and gate visuals without rejoining or rebuilding the dungeon.
