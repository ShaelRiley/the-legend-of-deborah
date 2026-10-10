# October 10 native evidence: complete reports, moving-view pair

Tested published build: `db51ecc024472b6b273af7f55cece5bc7b843c63`, clean.
Uploads: `console_latest(20261010-182052).txt` and
`performance_client_latest(20261010-182052).txt`. Remote main and the clean
checkout independently matched that build before diagnosis. Live GDD navigation
was 00 → 01 → 05/07, read-only.

**Performance remains below 40 FPS.** Both phases completed and the final server
profile arrived. The player moved and fought during the pair, so its FPS
difference cannot measure profiling overhead or an optimization's effect.
This checkpoint banks evidence and sequencing only; no game, tool, tuning,
population, appearance, preference or manual source changes.

| Active sample | Unprofiled | Profiled |
| --- | ---: | ---: |
| Frames / active seconds | 1,245 / 50.275198 | 1,529 / 44.420709 |
| FPS | 24.7637 | 34.4209 |
| Median / p95 frame ms | 35.357 / 73.336 | 26.760 / 44.156 |
| p99 / maximum frame ms | 133.797 / 512.085 | 65.246 / 179.319 |
| Active five-second windows ≥40 FPS | 0 of 12 | 1 of 10 |
| Endpoint displacement, Source units | 2,567.371 | 2,967.775 |
| Living bodies in population snapshot | 36 | 29 |

Profiled windows 6/7 have zero active seconds, so their displayed zero is not
zero gameplay FPS. All-frame profiled FPS is 31.6202 over 59.993344 seconds.
Views change position, pitch and yaw in both phases. The first population mirror
precedes deployment; the second has an active Hero outside the sanctuary and two
cleared first-sector contacts. Console deployment, combat, level-up and replacement
events corroborate the changed workload. The command's explanatory text says
"stationary sample" but does not establish that the tester stayed stationary.

Verification passes:

- All 54 recorded population/module hashes match mounted bytes, installed bytes,
  the exact published Git source and current checkout. Both phases report all
  19 client sources verified, zero missing/mismatched. The installer covers 58
  sources; only the 54 hashes actually recorded here were independently compared.
- Complete 270-row client and 369-row server profiles, all calls completed,
  including valid zero-call rows. Client reason `complete`, server reason
  `client-stop`, final transport `server_status=received`; durations 60.016400 /
  60.008937 seconds. Console lines 234–237 contain the final report/save.
- No configuration changes, preparation timeout, hidden batched walls or source
  mismatches. Native renderer, 1280×800, fixed wall batches 0, reduced effects 1,
  third person 0, map size/opacity 1; fps_max 60, vsync 0, shadows 1, picmip 0.
- All 32 embedded VR samples are idle with zero players, resources, recurring
  timers, hooks, pending work and overrides. Each reports 139 addon sources and
  two bridges verified. All eight embedded error counters and every console
  build counter are zero; no actual Lua error is present. Binding names inside
  telemetry are not errors. Native material warnings remain preserved and do
  not prove that appearance is accepted.
- Same campaign `654759237`, level 1, population seed `536325463`, layout seed
  `337421413`, two floors and 1,476 native wall models. Initially 18 living
  wanderers per floor, 36 total; 49 planned encounter bodies. The second mirror
  has 13/16 living wanderers and deficits 5/2. Server profile seed is the layout
  seed, not a contradictory new generation.

The largest client inclusive row is PreRender-to-PostRender: 29,599.509 ms /
1,896 calls (15.612 ms each). Static geometry is 7,407.158 ms / 3,794 calls;
branding 1,560.979 ms / 3,794; hostile Draw 1,487.460 ms / 14,993. Server admission
is 1,887.272 ms / 120,446 calls; close defense 1,657.940 ms / 61,455. These rows
overlap, include instrumentation overhead and leave GPU/native work unmeasured.
Inspection confirms existing exact-view/support/mesh/render-state caches and
callback-preserving AI optimizations. The moving comparison does not justify
replacing them with broader caches or changing graphics/population to meet a
claimed FPS gain. Obtain the missing controlled overhead comparison first.

[Replay archive](STEAM_DECK_20261010_PROFILE_PAIR_NATIVE.tar.xz), 120,572 bytes,
SHA256 `b0cba8b5d9f4bb0b9d9101101f699d8dc4476d1ab34de65e4fdb98e2a6d0bb4c`,
contains the original uploads, standalone verifier, deterministic results, raw
stdout/stderr, receipt and manifests. Verification JSON SHA256
`c05aff65be239d9d5d9772c827e4c3c037ebf83fc1a4e2e9aa04ed9789fc5fa4`.
The first verifier incorrectly required every registered row to have positive
calls; that fixture failure and its exact source are retained. Allowing valid
zero-call rows fixes the verifier without changing or discarding runtime evidence.
All archived streams are hash-checked; the verifier parses and whitespace passes.
All 2,010 tracked game/Lua/tool files remain byte-identical. No completed
historical game suite was rerun for this documentation-only checkpoint.

Extract the archive, then replay against the repository:

```bash
python3 native_pair_20261010/verify_capture.py native_pair_20261010 /path/to/the-legend-of-deborah
```

Next native action: reuse the verified installed build (this checkpoint changes
only documentation). On gm_flatgrass, deploy once and stay inside the arrival
sanctuary facing the maze. Run:

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_compare 60
```

Close the console; do not move, aim, attack or open menus through both phases
(about two minutes plus warmups). Keep GMod open through the final server reply.
Return performance_client_latest.txt + console_latest.txt. Verify identical view,
exact source, configuration, workload, complete profiles, idle VR and errors
before attributing the difference. This stationary diagnostic still does not
certify sustained traversal/combat ≥40 FPS. Native equipment/Magic control and
appearance acceptance await observations. No Workshop or VPS operation.
