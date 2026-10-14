# Consultant-guided low-end optimization — 2026-10-14

Base: main `25bf66d319c6d9c691e2114891b7e65f37b7fa37`. User explicitly authorizes applying or rejecting any consultant recommendation. Live GDD navigation: 00 → 01 → 07 (performance/resource/presentation tuning), with 06 for lifecycle/UI. Gameplay, physical progression props, floor discovery, native cargo geometry, collision and AI timing remain the existing authorities. Source validation is separate from native acceptance.

## Implemented

- **F-01, corrected diagnosis:** repair stale performance-test source manifests. The baseline already allowed map/pedestal edicts; the observed low-end failures were missing recently required client source identities. Keep the separately owned native map/book/pedestal, which the author requested after repeated invisibility. Add changed renderer/audio/boss sources to installer and runtime verification: 114 installer, 110 server observer, 51 client capture entries.
- **F-10:** native cargo pool bounded to 2,048 idle models, default `lod_container_model_pool 1`; reuse across manifests, clear submaterials/material/color/skin/transform before rendering, explicitly destroy on preference Off/map cleanup/shutdown. Construction admits at most 48 models and 3.5 ms per Think including retries. A native operation cannot be preempted, so one operation may exceed the deadline. Section-material reconciliation also stops admitting work after 3.5 ms. Original manifest order and appearance remain.
- **F-04, safe alternative:** preserve the distinct native afterimage models introduced to repair Source same-frame transform caching. Cap body ghost draws to 16 per rendered frame across views, or 8 with Reduced Effects / frame time above 22 ms. Sparse overload samples span the entire push; retain finite lifetime, beams and native cleanup. Skip depth/sky passes. No matrix-based rig replacement.
- **F-07:** reuse request/output/filter and support/hull vectors in canonical Visible, MeleeSupported and MeleeRouteClear predicates. Separate scratch rows by nesting depth; clear actor/result ownership on success and native errors. Support, clearance, locks, dynamic blockers and life admission are still checked at the same cadence. Never reuse a borrowed result as a stored charge/collision receipt.
- **F-08, bounded first step:** default `lod_boss_binary_snapshots 1` uses native typed full keyframes at the existing cadence; removes synchronous JSON/LZMA from the modular boss snapshot path. Recursion ≤8, ≤2,048 nodes, string ≤4,096 bytes and conservative wire admission ≤60,000 bytes. Keep full keyframes for join/reset correctness, and the existing decoder plus server option 0 for rollback. This does not change legacy Gordon's separate presentation stream or add delta/projectile/roll-feed policy without native bandwidth evidence.
- **F-09, corrected subsystem:** combat loop leases attach Think only while sound patches exist and detach after final lease removal, including native failure/reentry/reset/reload. Combat sounds are independent of music enablement. Existing VR idle detachment, opt-in test/profiling and score resource owners remain.

## Advice declined or already satisfied

F-02's helper APIs and complete client maze graph do not exist as presented; discovered-floor minimap data cannot safely drive whole-world visibility. Radius/axial floor culling can erase visible diagonal rooms, stairs/grates, boss galleries, detached cameras and progression props. Previous native wall failures make such omissions material. Existing current-pass conservative frustum culling remains; no visibility gate based on unproven apertures.

F-03's trace deferral and off-floor AI dormancy would alter authored movement/attack/cancellation timing. Graph membership alone does not prove native support: existing regressions intentionally include missing, steep, embedded and wrong-height support. Preserve those physical probes. Allocation reduction is implemented at their common seam.

F-04's persistent weapon submaterials conflict with shared mutable tint shaders and scoped addon restoration. Existing friendly idle discovery and monster aura work are already cached/throttled. Do not change those accepted authorities solely from the audit.

F-05 topology is already rendered into a persistent target and composed as one quad; a second topology cache is redundant. Portrait target changes require separate native appearance/alpha evidence.

F-06 explicit mesh destruction already exists on LRU eviction, reload, map cleanup and shutdown. Branding already uses a tiny retargeted material pool, and hull section materials share texture resources. Creating additional material pools does not guarantee texture eviction. No unmeasured 685 MiB residency claim or cosmetic catalog conversion.

## Finite gate and baseline limits

New operation-count/lifecycle tests cover model reuse/deadline/count/reset, trace output-only/nested/error behavior, frame-wide ghost ceilings, and native full snapshots for all 18 modular boss modules. Existing enemy cohorts, boss mechanics/death/client lifetimes, audio, palettes, physical props, installer/observer/capture and complete Lua syntax are retained regressions. Exact scoped source receipt and suite logs accompany this checkpoint. The expanded untouched baseline was stopped after reproducing failures; it is not a complete matrix pass. Baseline failures include stale performance fixtures and an unrelated B29/cross-feat Dodge fixture assertion; the latter is not represented as fixed or as a demonstrated native defect.

Final frozen result: **90/90 focused suites pass; 923 Lua files parse; zero source changes during the gate**. [Receipt](CONSULT_OPTIMIZATION_20261014/final/receipt.json), [production proof](CONSULT_OPTIMIZATION_20261014/final/production-proof.json), exact source manifest and all 90 paired logs are preserved. The first scoped 87/90 attempt and partial baseline failures remain alongside it. The three scoped failures were corrected fixture API/source-coverage assumptions; production remained unchanged during the final gate. This is not a complete 333-suite matrix or a native performance pass.

## Native gate next

Fully quit GMod, update/install main, restart `gm_flatgrass`, run `lod_perf_start 180` and play normally through combat, map toggling, gates, a boss and a dungeon transition. Return `console_latest.txt` and `performance_client_latest.txt`; population/source evidence is requested automatically. Observe wall/prop visibility and audio retirement. ≥40 FPS, native rig/model appearance, actual wire bandwidth and frame-time improvement remain unmeasured. No Workshop/VPS deployment is part of this checkpoint.
