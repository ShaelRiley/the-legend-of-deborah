# Steam Deck checkpoint: physical-footstep native field access

Parent: `0fe2df6ac8fcbecaf9fea712d6d43fdf83ad4508` on
`ShaelRiley/the-legend-of-deborah`, branch `main`. The containing commit is the
candidate. Implementation and headless validation are complete; the candidate's
native Steam Deck performance and sustained >=40 FPS acceptance remain open.

## Current native evidence

The October 9 UTC capture is complete and records the exact clean parent install,
15 verified client modules and 46 verified population modules, with no missing or
mismatched sources. The existing manifest did not include `sv_enemy_variance.lua`;
this checkpoint adds it for the next capture. The server profile was received
before termination. Client/server profiles cover 179.9962/180.0162 seconds;
configuration is unchanged, VR is fully idle and recorded Lua errors remain zero.

| Native scene | Active FPS | Median | p95 | p99 | Wall models | Initial living wanderers |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Previous, `8868d20` | 30.3866 | 30.271 ms | 50.162 ms | 84.058 ms | 1,270 | 36 |
| Current, `0fe2df6` | 21.3329 | 40.331 ms | 75.604 ms | 121.233 ms | 1,604 | 58 |

The generated scene differs, so this comparison does not isolate the preceding
source change's FPS effect. Current campaign/seed/layout seed are
503742237/1756771794/1440911994. The physical-footstep Think hook averages
0.2561 ms over 11,940 calls. Generated static geometry averages 2.3608 ms;
BeforeAI and close-defense services remain significant. Timings are inclusive,
overlap, include profiler overhead and omit GPU time; they are not additive frame
budgets. The game remains below its native sustained >=40 FPS target.

## Implementation and exact finite gate

The existing physical-footstep hook reads owned Lua values from the native
entity table during adjacent comparisons. Native `Entity:GetTable` supplies
the entity's stored Lua fields ([official API contract](https://wiki.facepunch.com/gmod/Entity%3AGetTable)).
The hook retains ordinary entity lookup for inherited/missing values and legacy
actors. A span borrows only when all later required values are owned. It
reacquires after position/velocity/distance callbacks; it keeps no table or
value across ticks. Native writes, validity, position/velocity polls, distance
arithmetic, the 80-unit cap, one roll per completed step, RNG sequence,
activation/death/latch behavior, registry order and refresh/lifecycle are retained.
The RNG callback and all other variance/scaling remain unchanged.

Installer and mounted-source verification now cover the changed module:
51 installed hashes and 47 watched runtime modules. Hashing retains the existing
once-per-session cadence; no new recurring service is added. Population,
combat, graphics preferences and approved models/floors/grates/overlays are preserved.

The actual published parent and candidate produce byte-identical state,
native-write, movement and RNG traces across 159 exact boundary, default,
inheritance, fallback, callback/table-replacement and lifecycle scenarios plus
13,920 moving-hostile ticks. Tests cover the strict speed threshold around 8,
distance/80-unit boundaries, vertical motion, zero/missing targets, death,
activation, latch/leap, invalid/removal, inherited false values, custom GetTable,
native table replacement during all getter/vector/RNG callbacks, Lua refresh and
changing registry membership. The real production RNG is executed.

| Measured work in 58 actors × 240 ticks | Published parent | Candidate |
| --- | ---: | ---: |
| Entity lookups | 143,376 | 58,812 |
| Added native table queries | 0 | 27,840 |
| Added native type queries | 0 | 13,920 |
| Lookup + table + type crossings | 143,376 | 100,572 |
| Native writes | 32,016 | 32,016 |
| Position polls | 13,920 | 13,920 |
| Velocity polls | 13,920 | 13,920 |
| RNG draws | 1,044 | 1,044 |

The combined crossing count falls 29.8544%, counting every added table/type
query. These are headless work counts, not elapsed-time or FPS gains. The actual
unchanged parent fails the new work bound while passing the behavior probe.
Both traces contain 76,598 lines/3,378,864 bytes, SHA256
`a42b6451b0afa466211d9efc0f6c26dbca676cf069f99bceacf7e60c527dc687`.

## Frozen validation and evidence

The final complete gate passes 316/316 canonical suites and parses 886 Lua files,
with the canonical 600-second limit and two workers. The 2572-file
source snapshot is unchanged throughout the gate, SHA256 `b6f74f750526836f15786d2cc812161b2f52c60c73c51cee0821d18965f16f9a`.
Every suite's exact command, individual receipt and all 632 raw stdout/stderr
streams are independently verified against the aggregate receipt and current
suite registry. All changed source/test bytes match the frozen manifest. This
includes installer/hash verification, population transport/identity caching,
variance/progression, audio/lifecycle, renderer and all retained regressions.

The first matrix was explicitly interrupted before extending the source manifest;
its partial receipts/streams are retained as incomplete evidence and are not
counted toward the final pass. The next partial run exposed two incomplete
source-count fixtures, causing seven dependent suite failures. Their failures
are retained; the corrected fixtures pass all seven affected suites before the
final complete frozen run in `matrix-verified`. The exact parent work-bound failure is retained
as the intended negative control. Documentation and evidence packaging follow
the final frozen gate; production and test hashes are rechecked before publication.

Fresh live-GDD navigation followed 00 → 01 → 05/07 in document
`1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, revision
`ANLCKQnrYkXEQkWhbY2lFbkh3C5XrRI-q4oBgGMtvVIvs78hQeS96NzZ3OIRtG4TjIZ4DGBr3d0o_ye6s_-butEXqxYjMR0xgyBfcEiqPQ`.
LOD-IMPL-001/002/005 and B29's spatial/lifecycle constraints govern this
implementation-only change. No authored tuning or design amendment is made.

[Complete evidence archive](STEAM_DECK_20261009_PHYSICAL_STRIDE.tar.xz) contains
both current native logs, preceding comparison logs, paired production traces,
negative control, all final matrix receipts/streams, interrupted evidence,
scoped GDD, source bytes/patch, verification and reproducing helper scripts.

## Next native gate

Fully quit Garry's Mod, then:

```bash
cd ~/Downloads/the-legend-of-deborah && git pull --ff-only origin main && bash tools/install_dev.sh
```

Restart `gm_flatgrass` and enter one console line:

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile
```

Keep GMod open through the final server reply; return `performance_client_latest.txt`
and `console_latest.txt`. Require the containing clean commit, 15 verified client
and 47 verified population modules including `sv_enemy_variance.lua`, unchanged
appearance/gameplay and physical-step behavior, complete profiles, idle VR,
zero new Lua errors and sustained >=40 FPS. No Workshop publication or VPS action.
