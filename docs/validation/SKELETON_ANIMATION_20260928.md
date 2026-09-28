# Skeleton stock-player animation repair — 2026-09-28

Author request: repair T-posing skeletons with GMod's existing player animations;
source push is expressly preauthorized. Base: `main`
`9d3c2027c5b17fa88c8756eb8e33e8ced79df4c3`.

Live GDD read through 00 → 01 → 05 LOD-BIG-SKELETON-001 and 07
LOD-BIG-SKELETON-001 / LOD-IMPL-001–004. This repairs presentation; it does not
change authored combat, movement, copied builds, event selection or resources.

## Defect and repair

Skeletons already use `models/player/skeleton.mdl`, but inherited NPC activity
requests and fallback idle-name scanning can select an unsuitable player pose.
Both constructors also changed model after native initialization without resetting
its animation. Motion V2 supplied only NPC `move_yaw`, leaving player `move_x/y`
at their defaults while native locomotor velocity intentionally remains zero.

The shared resolver now translates skeleton requests into stock HL2MP activities
with class/copied-weapon holds, and uses a complete player idle as fallback.
Player attack gestures remain overlays rather than replacing the base sequence.
Model and held-weapon changes invalidate the existing bounded per-entity cache.
Equivalent NPC activity names cannot repeatedly restart a player cycle.

Both spawn paths apply player idle immediately after the model swap. Motion V2's
existing BodyUpdate supplies the player's forward movement blend from its own
recorded motion, clears it on holds, preserves stun/death, and advances once.
No BodyMoveXY, extra timer, custom rig, downloaded animation or new asset is added.
NPC flinch fallbacks retain a valid complete player pose for skeletons; other
hostiles retain their existing resolver, motion and hurt/death paths.

## Evidence

`SKELETON_ANIMATION_20260928_CHECKS.json` records **15/15 selected suites** and
**811 Lua syntax checks**, with no files changing during the final gate and
SHA-256s for every changed implementation/test file. Coverage includes all three
event classes, copied weapon switches, zero-native-velocity movement, steady
cycle caching, activity aliases, attack overlays, hit-stun/recovery/death,
both model-swap spawn paths, Razor, normal enemies, skeleton lifecycle/rewards,
staging bootstrap, B29 movement dispatch, native-resource and death bookkeeping.

The new native-boundary test fails against the parent source with
`invalid or additive idle used as body`. This demonstrates the unsafe Lua
fallback using simulated model APIs; it is not a native screenshot reproduction.
Review also caught and repaired running/idle activity-alias cycle restarts.
Their failed regression outputs are retained in the receipt, alongside final
passing results. No implementation or test edits followed the final gate.

Reproduce the finite gate:

```bash
python3 tools/test_skeleton_animation_gate.py --workers 4 --suite-timeout 120 --output /tmp/lod-skeleton-animation-check
```

Use a fresh output directory. Primary API references:
[player animation families and nine-way poses](https://wiki.facepunch.com/gmod/Player_Animations),
[ACT constants](https://wiki.facepunch.com/gmod/Enums/ACT), and
[gesture overlays](https://wiki.facepunch.com/gmod/Entity:AddGestureSequence).

## Native acceptance

Pending: fully quit GMod, install this source, then observe event skeletons and
a fallen-player copy on `gm_flatgrass` through spawn, pursuit, stopping, attacks
and damage. Confirm animated limbs and no reference pose or repeated-cycle
stutter. Headless tests do not certify native appearance or frame time.
Retain local acceptance → Workshop package parity → matching VPS release order.
