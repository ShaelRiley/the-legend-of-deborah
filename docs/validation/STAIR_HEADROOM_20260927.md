# Standing stair headroom — September 27, 2026

Parent: `aebd2bb0083bb0b13b043486665342dfc1c084f0`.
Author evidence: `2026-09-27 10-12-49(1).mkv`, reporting a stair ceiling that
required ducking. This is contradictory native traversal evidence, not acceptance.
Live GDD: 00 -> 01 -> world/navigation 05 and tuning 07; the narrow
`LOD-STAIR-HEADROOM-20260927` tuning supplement was written and read back.

## Repair and finite gate

The final runtime stair override, `sv_m1_stair_geometry.lua`, retracts the rear
crossover lip by 16 units (depth 64 -> 48). Its existing shared constant also moves
the rail opening. No player hull, stair rise/run, floor thickness, graph, material,
movement hook or entity-count change. The upper no-jump crossover remains 48 wide
for the unchanged 32-wide hull, with 8 units spare on each side.

A stationary 72-high hull fit the old geometry, but the full-footprint support
check found only 80 units under the lip. The conservative upright step envelope
requires 72 + 18 + 2 seam margin = 92. The repaired minimum is 96. This geometric
explanation is consistent with the report; it is not a native engine replay.

The regression loads the actual final builder override, standing hull authority
and static-box Initialize collision bounds. Baseline failed as intended:
`STAIR_HEADROOM_FAIL: S z=0 clearance=80; upright step envelope requires 92`.
Focused final test passes 98 rotation/elevation/endpoint/generated flights,
144354 hull samples and 89768 supported upper-loop samples. Generated coverage is
16 seeds / 74 flights, plus 24 explicit fixtures. Full upright body clearance,
solid floors, rail openings, legal approaches and no-jump circulation are checked.
The earlier focused pass had 144648 samples; the final test trims sampling beyond
the upper-deck limit and reads the actual player hull rather than duplicating it.

`tools/test_stair_headroom_gate.py` retains all 95 SPOT-17 selections and adds four
stair/navigation/hull checks: 99 selected, 757 Lua syntax files. The new regression
is also registered in `tools/test_checkpoint_g_integration.py`. Final aggregate
results and verified publication identity belong to the delivery receipt. The first three
aggregate invocations were interrupted by process time limits before a receipt;
all are incomplete, not passes. Their partial logs are preserved externally. These counts describe the gate contract, not a claim that an unrun gate passed.

## Native acceptance still required

Fully quit GMod, update/install the source, and start a fresh `gm_flatgrass` game.
Use `lod_m1_stair 1` when a quick stair approach is needed. Walk up, down and around
the upper landing without crouching or jumping; there must be no head snag or new
upper-route obstruction. A short observation/clip is enough for this defect;
request console_latest.txt and rpg_summary_latest.txt if another failure occurs.
No Workshop publication or VPS operation. Preserve all prior acceptance debts.
