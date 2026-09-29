# Enemy close defense and attack animation repair — 2026-09-28

Author request: repair rare creatures that walk into Heroes without attacking,
restore visible attacks, and prevent indefinite crowbar flinch locks. Base:
`main` `863f7fe4ff98a758d98f8945f88d43d9537d69f7`.

Live GDD navigation: 00 → 01 → 03 combat/status and 07 implementation/tuning.
The current author direction supersedes older no-melee descriptions for this
last-ditch defense. Google rejected the guarded GDD amendment with HTTP 400
`FAILED_PRECONDITION`; the exact proposed text is preserved in
`ENEMY_CLOSE_DEFENSE_GDD_AMENDMENTS.json`. It has **not** been written to the GDD.

## Repair

Some specialist controllers lack a close attack or require primary-attack
geometry/resources that cannot be satisfied at contact. Native behavior now
offers a stationary physical defense before archetype wrappers consume the tick.
It uses the existing EnemyRoster commitment service, target refresh, actor-life
bindings, dice, Block/Dodge and native damage admission. Existing primary attack
commitments keep their controller. Shamblers and Runners keep their ordinary
melee attack; its missing animation request is repaired.

Fallback tuning: 96-unit center-to-center reach, frozen forward 120-degree arc,
0.4-second warning, 0.2-second release grace and 1.2-second recovery. Existing
physical melee profiles retain their damage; others use size-scaled physical
1d4+1. No casting resource or elemental rider is inherited. Cover, movement out
of the sector, source displacement, disabling statuses, arrival protection and
invalid actor/encounter/world life still block damage. Held/Muted allow a
stationary physical strike. An open grid-cell boundary cannot silently disarm it.

Every hostile now shares Gordon's existing three-second melee-stagger recovery.
The first eligible hit still flinches with ordinary duration/CHA/feat modifiers;
intervening crowbar hits still deal damage without cancelling every retaliation.
Firearm, shotgun, Magic and disabling-status rules retain their existing paths.

The model resolver rejects idle/walk/run fallbacks for attack requests and tries
stock attack activities/sequences. Skeletons retain complete player base poses
with melee gestures. Devices without a skeletal swing show a brief cosmetic jab
and the same fixed strike warning. No extra recurring hook, timer, projectile or
physics movement is introduced. The canonical manual and its client chunks are
regenerated together.

## Evidence

`ENEMY_CLOSE_DEFENSE_20260928_CHECKS.json` records the final finite gate:
**47/47 selected suites**, **813 Lua syntax checks**, and no source changes during
execution. Coverage includes all 63 normal archetype paths, repeated crowbar
pressure, named-actor ownership/reveal guards, fixed geometry and exact lifetimes,
reentrant damage, held/muted physical damage, retained primary attacks, skeleton
animation, bosses, Bestiary B3–B19/B29, arrival safety, death/resources and manual
parity. These are headless production-code tests with Source boundaries doubled.

The new regressions fail against the unchanged parent production source with
`melee silently selected idle: melee_gunhit` and
`arccaster walked into Hero without attacking`. Parent diagnostics and final
implementation/test hashes are preserved in the receipt. This is a Lua-boundary
reproduction, not an in-engine screenshot or playtest. No implementation or test
edits followed the final gate.

Reproduce with a fresh output directory:

```bash
python3 tools/test_enemy_close_defense_gate.py --workers 4 --suite-timeout 120 --output /tmp/lod-close-defense-check
```

## Native acceptance

Pending: fully quit GMod, install the verified source and play close combat on
`gm_flatgrass`. Approach a rare ranged/support enemy and maintain crowbar pressure;
confirm a visible counterattack lands when its warning is ignored, while stepping
outside the arc or behind cover evades it. Include a device and a skeleton when
encountered. Use `lod_enemy_roster_testkit arccaster` in developer mode if a targeted
unranked spawn is needed. Preserve `console_latest.txt` + `rpg_summary_latest.txt`
for failures, and a short video for animation/timing defects.

Headless checks do not certify native animation timing, balance or frame time.
Retain local acceptance → Workshop parity → matching VPS release order. This is
a source checkpoint; deployment is outside its scope.
