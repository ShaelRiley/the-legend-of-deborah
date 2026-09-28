# Low-end static renderer follow-up

Baseline: main `c55a4a4aea77994e8c80725b621e0ef86f856e81`.
Authority: live GDD 00 -> 01 -> 07, LOD-IMPL-004. The repeated Steam Deck
slowdown report authorizes this follow-up to the earlier palette/rear-plane pass.

## Finite scope and gate (defined before production edits)

Extend the existing TexturedBox cache and generated static-geometry draw hook.
Reuse unchanged per-entity mesh queries and transforms, without exceeding the
existing 256 native mesh ceiling. Invalidate on dimensions, UV inputs, kind,
transform, eviction, cleanup and Lua refresh. Preserve world-planar UVs, material
fallback, color, render-state restoration, grates and false-floor visibility.
Reject only enclosing spheres wholly outside a known perspective view; retain
unknown/orthographic/off-center views and every camera/plane-intersecting sphere.
Use the active render camera, actual aspect-adjusted FOV and aspect, including
rotated and nested views. No distance cap or occlusion guess.

Compare production operation counts before/after using the same synthetic scene.
Verify emitted vertices/UVs and draw transforms against uncached public methods;
exercise cache pressure, mutation, full updates and native ownership. Run all Lua
syntax checks and the canonical relevant low-end, Crate, geometry, lifecycle,
camera, event-hazard and startup regressions. Preserve failed attempts. This is a
selected integration gate, not the complete campaign matrix or native acceptance.

No game rules, enemy populations, AI cadence, collision, saved graphics/music
preferences or native resource ceilings change. Source publication only. Native
Steam Deck FPS, frame pacing and fan/thermal behavior require local observation;
retain local acceptance -> Workshop -> matching VPS release order.

API reference: https://wiki.facepunch.com/gmod/Structures/ViewSetup documents the
active camera origin/angles, aspect and already aspect-adjusted `fov`.

## Paired production work counts

`tools/test_low_end_render.lua --baseline <old mesh source> <old entity source>`
and the ordinary test mode execute the same production draw hooks. In the fixed
120-entity, 120-frame stationary scene after warmup, formatted cache keys fall
from 21,600 to zero and native Matrix allocations from 14,400 to zero. Both draw
all 120 entities per frame with 61 peak native meshes. In the fixed 600-box view
(100 visible, 200 outside lateral/vertical planes, 300 behind), submissions fall
from 300 to 100. Those scene distributions are synthetic; the fractions are not
claims about an ordinary maze or native FPS.

The cache keeps the existing 256-mesh ceiling and LRU semantics. A weak per-owner
record borrows entries; eviction marks the borrowed handle unusable, and cleanup
or Lua refresh clears the records. Material and color remain resolved live.
An independent projected-corner oracle covers 960 box/view combinations across
four aspect ratios and four FOVs; all 173 cases with a visible projected corner
remain drawn. Existing rear-only and unknown-camera tests remain in the gate.

Reproduce the selected integration gate with:

```bash
python3 tools/test_low_end_render_gate.py --output ../low-end-render-gate --workers 2 --suite-timeout 120
```

The gate includes current empty-map and immediate-staging-reset regressions and
all repository Lua syntax, without re-running unrelated full campaign sweeps.
Final selected gate: **32/32 passed; 808 Lua syntax checks**. Before/after
source hashes match, with zero files changed during the run.
`low_end_render/receipt.json` and `gate-logs.tar.gz` retain the results and raw
logs; `tested-files.json` records the validated gameplay/tool files. Only
coordination text and these evidence files were added after the gate. No native
performance or full campaign-matrix acceptance is claimed.

## One next native test

Fully quit Garry's Mod, install the published main with the normal development
installer, and play an ordinary `gm_flatgrass` route through staging, a full
camera turn, stairs in both directions and combat. Observe smoothness and any
missing floor/stair surfaces. Use the same resolution/effects preferences for
comparison. Existing Options -> Reduced effects (Steam Deck / slower PCs) is
available separately. Return `console_latest.txt` and `rpg_summary_latest.txt`
with the observation. Native frame time, fan/temperature and co-op acceptance are
not established by these headless probes. Workshop/VPS remain unchanged.
