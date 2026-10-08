# Steam Deck — aligned HUD text work

This checkpoint removes repeated font selections and measurements from aligned
HUD labels. Across 1,200 labels, both counts fall **12,000→1,200** while all
12,000 native glyph draws remain identical. Hardware FPS benefit is unmeasured;
the latest installed-parent capture averages **29.6510 active FPS**, below the
sustained 40 FPS target.

The baseline is published main `0a10367a3d0c3a6e12198df978b13376a483f8e7`.
Fresh live GDD 00 → 01 → 06/07 governs this implementation-only checkpoint,
revision `ANLCKQnrYkXEQkWhbY2lFbkh3C5XrRI-q4oBgGMtvVIvs78hQeS96NzZ3OIRtG4TjIZ4DGBr3d0o_ye6s_-butEXqxYjMR0xgyBfcEiqPQ`.
No design or tuning change is required.

The October 8 UTC / October 8 local capture verifies clean `0a10367`, all 15
client and 46 population hashes, complete 179.9-second client/server profiles,
fully idle VR and zero Lua errors. It records 5,080 active frames over
171.326405 seconds, median 30.672 ms, p95 53.305 ms and p99 92.372 ms.
The native scene has 1,284 walls and 36 recorded living wanderers; the preceding
capture had 1,614 walls and a different population/layout. The FPS difference
does not isolate the prior optimization. The entry snapshot has no recorded
admission decisions and cannot accept every sanctuary branch.

The portrait callback averages 0.94064 ms per paint; the feed averages 1.17870
ms. CPU timings are inclusive, overlap and include diagnostic overhead; GPU
time is unmeasured. Portrait captions still use the stock outlined helper's
ten font selections and measurements per label.

The existing shared `UI:HUDText` native path now supports the known horizontal
and vertical alignments. It measures the selected live font once per label,
adds each outline offset before subtracting alignment dimensions, then rounds
exactly as Facepunch's primary `draw.lua` does. It retains all nine outline
glyphs plus foreground, exact color/alpha values and the original return
contract. Caller-owned coordinate caches include the current alignment
dimensions; font metrics are never remembered between paints. Custom text
conversion, unknown alignments and partial APIs retain the stock fallback.
Existing left/top feed work is unchanged. Portrait models, animation/sample
cadence, captions, wrapping, layout, statuses, life/role cleanup, gameplay,
population, geometry and saved graphics preferences remain unchanged.

The production-backed probe loads the exact published parent and candidate
UI/feed sources. Their drawing traces match across **750 scenarios**, including
all nine alignments, Unicode/kerning, IEEE rounding boundaries, live font
changes, coordinate ownership, custom conversion, alpha and API fallback.
Trace SHA-256:
`0660a9b9d7ba938fb66785f5852227ae218a8ee9b9f7570c634672219a5ddcf6`.

| Work across 1,200 aligned labels | Published parent | Candidate |
| --- | ---: | ---: |
| Native font selections | 12,000 | 1,200 |
| Native text measurements | 12,000 | 1,200 |
| Outline Color allocations | 1,200 | 0 |
| Coordinate ceil operations | 24,000 | 24,000 |
| Native glyph submissions | 12,000 | 12,000 |

The exact parent fails the new work bound. The existing 42,000-draw feed probe
retains zero measurements and unchanged work counts. Portrait lifecycle/status
regressions now draw captions through the actual shared UI helper. Operation
counts establish removed work, not a hardware FPS gain.

The frozen final source passes **20/20 focused checks, 314/314 canonical suites and 885 Lua parses**. All 2,563 source files remain unchanged during both gates. Every canonical and focused command/receipt and all 628 matrix stream hashes plus 20 focused log hashes are independently checked. Only documentation/evidence packaging follows; all three changed code/test hashes are rechecked before publication. The adjacent checks JSON and ZIP preserve raw native uploads, live normalized GDD tabs, primary Facepunch draw source, exact parent/candidate sources, paired drawing traces/work counts, the expected failing parent work gate, final full/focused commands, receipts, raw streams and source manifests. No failed or interrupted candidate gate contributes accepted results.


Fully quit GMod, update/install main, restart gm_flatgrass and use:

```bash
cd ~/Downloads/the-legend-of-deborah && git pull --ff-only origin main && bash tools/install_dev.sh
```

```text
lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile
```

Leave the game open through the final server reply. Return
performance_client_latest.txt and console_latest.txt. Require verified final
source, complete profiles, idle VR, no new Lua errors, unchanged portrait,
weapon/status/readout appearance, world visuals and gameplay, and sustained
>=40 FPS. Native acceptance remains open. No Workshop or VPS action is included.
