# SPOT-15 — Soldier F3 team menu

## Scope and authority

Parent gameplay checkpoint: `79b770d5b5effc9c329e5931b22dd3954fd60dfb`, tree
`6e4cf9256a1f6d522d552486eedaa9ad4fa23bb4`. Exact published child/tree/source and
independent run are supplied by the external publication receipt. An isolated
transport/workflow trigger is never gameplay ancestry. Preserve intervening main.

Read AGENTS, development plan, current handoff, SPOT brief, SPOT-14 validation and
test logging. Live GDD 00 -> 01 -> 06 Soldier/retention/revival/UI rules and the
relevant 07 authority were consulted. New SPOT-15 06/07 supplements were written
before dependent code and read back at revision
`ANLCKQklK1XQgaw9VSbVrWu1Jolg69vKKI1EOBbsIbHme1gANudn0CMeIRpIyNVnvJvzrMLudeA0c1wErPWWu_9DybRLx4QgxOAjT0FNOg`.
Normalized rules contained the relevant original detail; no broad HUMAN reread.
Direct native connector reads/writes preserved the existing tabs and paragraphs;
the optional file-backed control helper was unavailable in this runtime.

## Implemented contract

Human Soldiers, living or in their twenty-second replacement wait, can open F3
without needing a new Hero elimination prompt. Their two choices are RETURN TO
HERO QUEUE and SPECTATE ONLY. The ordinary eliminated-Hero three choices remain.
Explicit spectators can reopen F3 and requeue. A compact F3 HUD hint distinguishes
Soldier play, Soldier respawn wait and spectate-only. Soldier waiting no longer
shows the misleading ordinary-Hero choice-trio death hint.

Both exits share RunManager:SetHeroQueueMode. They retire SoldierProgression's
actual incarnation/XP, clear native weapons/ammo and transient body effects, free
the slot, invalidate pending native spawn work and cancel automatic replacement.
The exact dormant Hero state, saved inventory, progression, lives, original
elimination timestamp and account/dungeon state survive. Queue return grants no
life and banks no missed revival. Spectate-only stays outside revival and automatic
Hero admission, including reconnect and successful advance. Existing clear-time
life restoration still occurs; a new campaign uses fresh ordinary admission.
Positive-life return preserves that life, waits for the normal four-Hero slot when
full, and uses a fresh Hero Spawn when admitted.

Soldier death's existing readiness deadline is retained separately from cancelled
automatic respawn intent. Leaving the wait never skips the remaining twenty-second
Soldier re-entry lock. Hero resurrection eligibility is independent and immediate
on queue return. Slot limits, SMG, ammunition policy, movement, AI-equivalent
Soldier generation and automatic progression are unchanged. No SPOT-16/17 work.

RunManager's existing NW2 sync projects the queue and an exact context derived from
campaign epoch, Hero ordinal, native spawn serial and role. Contextual menu commands
reject stale views; legacy typed commands remain server-validated. Genuine build,
failed/cleared campaign, Tetris, quiz and expired-clock locks precede mutations.
The existing Multiplayer deferred revival callback now uses slot-active eligibility
rather than requiring the not-yet-spawned Hero to already be deployed. Production
integration tests exposed and exercise this repair.

Client controls use the existing Think owner, edge-trigger F3 and honor chat,
console, text-entry/binding focus and minigame/cinematic locks. Stale role/life views
and confirmations retire; an old callback cannot close a replacement frame. The
normal initial Hero-elimination prompt remains one-shot. Menus never pause play
or confer safety. Responsive paper/ink panels use at most 520 pixels, a 16-pixel
viewport margin, scrollable options, 40-pixel buttons, wrapped descriptions and
the existing shared fonts. The white outlined HUD hint sits at 60% screen height.
No new timer, network channel, persistent store, world scan or parallel owner.

## Validation and evidence

Pre-closeout gate01 passed **90/90** selected suites on unchanged source. It retains
all **87** SPOT-14 selections and adds actual-production server/menu tests plus the
existing Feather of Resurrection integration test. Focused checks passed **196
server + 229 client = 425 assertions**. Syntax covered **751 Lua files**. Both manual
readers/catalog agree: 166 chapters, 32 chunks, 151 entries (136 ordinary feats and
nine capstones, plus six fallback entries). No feat/catalog behavior changed.

```bash
python3 tools/test_spot15_gate.py --output /absolute/empty/evidence-directory \
  --suite-timeout 120 --workers 2
```

The final frozen local and independent gates must execute that same selection
against identical source; their exact receipts are external to avoid self-reference.
All pre-closeout attempts, raw logs, manifests and source-copy boundaries are in
`docs/validation/SPOT_15_ATTEMPTS.tar.xz`, SHA256
`c6936b28445a36c7302c0b8eac875f88fcdccb77da9eb079ca14afb49f3f7753`. HISTORY.md distinguishes failures, source manifests, original diffs and
available source copies. No failed/incomplete attempt was reclassified as a pass.
All 90 completed gate01 raw-log hashes were verified before archive creation.

The first legacy lifecycle run failed on an incomplete-build fixture; the fixture
now explicitly tests rejection there before its ready-state idempotency assertion.
Server attempt01 found the real slot/deployment revival bug. Attempt02 lacked the
native weapon GetPrimaryAmmoType adapter; attempt03 passed after that adapter was
completed. ui01 and lifecycle02 passed. Streaming launch was unavailable before any
command ran. Earlier SPOT-10/11/12/13/14 failures remain historical failures.

## Native and release boundary

These are headless production-boundary gates, not native GMod rendering/font/input,
network/co-op, timing, movement/rejoin, balance or full campaign-matrix acceptance.
The pre-existing full Gate-B perkDisplayName identity diagnostic is not claimed
fixed/passed. Preserve SPOT-14 clock and SPOT-13 unread/drag/SPOT-12 card checks.

On the exact installed gm_flatgrass build, use a human Soldier: F3 must show the two
role choices and a readable hint during play and respawn wait. Try queue return and
spectate-only in ordinary cooperative play; confirm equipment retirement, expected
revival/admission and that leaving a death wait does not skip its remaining delay.
Verify ordinary Hero choices and that reading the menu does not pause gameplay.
Record console_latest.txt + rpg_summary_latest.txt and a short exact-build note.
Detailed session only for timing diagnosis. No dedicated Razor retest or mandatory
near-expiry leave test. Native input/layout/co-op remain open until observed.

Local acceptance -> Workshop 3791535712 package/source parity -> matching VPS.
No Workshop or VPS operation occurred or is implicitly authorized. Next bounded
queue item is SPOT-16 pulse-rifle replacement; SPOT-17 movement and the deferred
roadmap remain separate checkpoints.
