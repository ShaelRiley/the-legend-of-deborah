# Steam Deck checkpoint — reduced-effects hostile aura orbit

## Current native evidence

The October 9 18:11:37 UTC capture tests clean published main
`7853634ae455a213b84cbe04e10b2435d3130b89`. All 48 recorded installed/mounted
population-module hashes match that exact parent. Client capture source
verification passes 16/16; preferences are fixed; VR remains fully idle at both
endpoints; client/server Lua-error counts are zero. The final server profile is
received, with 273 client and 370 server rows over approximately 180 seconds.
Raw console and capture files are retained in the adjacent evidence archive.

Active FPS is **28.0046**, median **31.784 ms**, p95 **58.836 ms**, p99
**86.092 ms**. All 36 five-second windows remain below 40 FPS (maximum 38.758).
The scene starts with 1,434 native wall models and 36 living wanderers, versus
1,604 walls and 58 wanderers in the preceding older-source capture. Different
generated workloads prevent attributing the FPS difference to either published
optimization. Sustained >=40 FPS remains unmet; appearance/gameplay acceptance
also requires the tester's observation. Existing engine material/font warnings
are preserved, not silently relabeled as Lua errors.

The inclusive hostile Draw row averages 0.113480 ms over 47,059 calls. The
generated geometry hook averages 1.899055 ms over 10,068 calls. Inclusive rows
overlap, include diagnostic overhead, and do not measure GPU cost. This does
not claim that aura trigonometry dominates the frame.

## Bounded implementation

Fresh live GDD navigation follows **00 -> 01 -> 05/07**, notably world/accepted
presentation constraints and LOD-IMPL-001 through -006. This is implementation
caching only; no authored rule or tuning is changed.

Extend `cl_monster_identity.lua`'s existing aura presentation. Reduced Effects
already fixes the orbit to two stationary points. Cache their exact computed
X/Y offsets per actor and radius. Continue every native state, position, center,
preference and visibility read, color/vector allocation and sprite submission.
Full-effects animation keeps its original calculation. Radius changes are
observed exactly; NaN retains the ordinary path. Math-helper/pi replacement is
checked before each sprite, including replacement inside a preceding sprite
callback. Nested rendering, retries and Lua refresh preserve the original trace;
weak keys cannot retain retired actors. No model, collision, gameplay,
population, graphics setting or timing changes.

Add the modified presentation module to the existing installer and mounted
source verification: **53 installed hashes, 49 population modules, 17 client
capture modules**. Preserve the existing hashing cadence outside the draw path.

## Finite verification

The unchanged published parent and candidate emit identical **255,405-row**
native-input/sprite traces across **218 branch/boundary/callback/lifecycle cases**
and **13,920 stable-radius draws of 58 moving actors**:

| Work in the stable workload | Published parent | Candidate |
| --- | ---: | ---: |
| Trigonometric calls | 55,680 | 232 |
| Native input reads | 167,040 | 167,040 |
| Vector allocations | 97,440 | 97,440 |
| Color allocations | 13,920 | 13,920 |
| Sprite submissions | 27,840 | 27,840 |

Trace SHA256: `b0ffc354b7a095b053ab6a50b33c7629f0e7941dfa1a42fca3771cacd5c2b2d1`.
The published parent passes trace comparison and is rejected by the candidate
work bound. Cases retain size/radius/distance boundaries, default size, status
priority/live colors, typed/untyped bodies, hidden/cloaked/dead/Soldier paths,
full-effects phases, custom helpers, between-sprite mutations, nested draws,
NaN, native errors/retry, refresh, full update/reincarnation and weak retirement.

**11/11 selected checks pass** on identical frozen source, including the paired
work gate, monster identity/status/portrait, performance capture/profile,
population transport/installer, resource lifecycle and saved-options
regressions; seven changed/new Lua files parse. Every retained successful raw
stream and command receipt is hash-verified. The prior 317-check/887-file
checkpoint remains committed evidence and is not rerun. This is a targeted
gate, not a new full-matrix claim or native FPS certification.

The first probe's incorrect eight-vector fixture expectation and a parallel
output-directory setup failure are retained in `aura_gate_attempt01`. Actual
unchanged parent/candidate allocation work is seven vectors per draw. The first
targeted runner also named a nonexistent status-presentation test; its failed
receipt remains, and the corrected existing status-elements command passes on
the same frozen source. Neither failed preparation attempt counts as a pass.
Only documentation/evidence packaging follows; all production/tool hashes are
rechecked before publication.

Evidence: adjacent `_native.json`, `_checks.json`, and `.tar.xz`. Archive SHA256:
`4a7dc19d96e6049dc9bb45696dd8b83faa75ab1495602b5f4fab73ec57ba7618`.
For reproduction, extract `aura_evidence/parent-cl_monster_identity.lua`, then run
`tools/test_monster_aura_orbit_work.lua --probe <parent> <trace>` and `--gate
<candidate> <trace>` through `python3 tools/run_lua54.py`; compare trace bytes.
The archive retains all exact commands, source snapshots and receipts.

## Next native gate

Fully quit GMod, pull/install verified main, restart `gm_flatgrass`, then run:

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile
```

Play normally and leave GMod open through the final server reply. Return
`performance_client_latest.txt` and `console_latest.txt`. Require the exact
installed/mounted source, complete profiles, fixed preferences, fully idle VR,
no new Lua errors, unchanged appearance/gameplay and sustained >=40 FPS. The
candidate's native FPS remains unmeasured. No Workshop or VPS operation.
