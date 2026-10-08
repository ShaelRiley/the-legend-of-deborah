# Steam Deck combat-feed span work reuse — October 8, 2026 UTC

## Native evidence and governing authority

The supplied complete three-minute capture verifies clean main
`8bac44ab36922d3d169f613cd3b6d1fd739be4de`. Active play contains 2,902 frames
over 130.105771 seconds: **22.304929 FPS**, median 38.212 ms, p95 82.537 ms,
p99 120.064 ms and maximum 415.867 ms. There are 798 frames over 50 ms and
73 over 100 ms. Native walls remain at 1,556. Preferences stay fixed; both
CPU profiles complete. Client presentation verifies 15 sources and population
verifies 45, with no missing/mismatched files. Lua errors stay zero. VR remains
fully idle with no hooks, recurring timers, overrides or native resources.

This generated workload differs from the earlier 4af3b40 capture, including
wall count and active/death-menu time. The FPS and callback means are not an
isolated source comparison. Sustained >=40 FPS remains unmet. The current
combat-feed HUD callback averages 1.239278 ms over 3,944 total rendered frames
(27.183011 ms/second). Generated static geometry still averages 2.036548 ms
per callback over 7,888 calls. The complete render phase averages 19.024890 ms.
Timings are inclusive and include profiling overhead; nested rows overlap and
GPU work is unmeasured. Do not add them into a total CPU budget.

The exact live GDD is `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
The unchanged revision is
`AHj4eMRd4acJKKEDgqukO9zGvoMQvxlbUMdF6nZCAXYFhQm-CNvzGIub5PLIO_oXk6fEWbrk_V-_2bJc4m1wqQvkXjzdDNhY5wQfHSd7Pg`.
Previously read 00 → 01 → 07 governs bounded event/cache implementation;
06 LOD-UI-003/-004 governs strict canonical HUD/history parity. No GDD,
authored tuning, game rule, preference or renderer change is included.

## Implementation and finite gate

Extend the existing DrawLines/HUDText seam. Each layout span owns one reusable
Color and its last exact rounded outline coordinates. Color changes preserve
the engine Color constructor's numeric conversion and upper bound, without
mutating shared palettes. Round each original x/y plus offset separately;
ceil(x) plus an offset is not equivalent at floating-point boundaries. Position
changes rebuild the owned coordinates immediately. Existing metric, width,
text, semantic-span, font, screen and reload invalidation remain in use.

The selected-font token exists only inside one immediate DrawLines call.
Every new paint starts by establishing its own font, and stock/non-native
fallback returns no token. Preserve all nine outline submissions followed by
the foreground at the same positions, with the same string/font/color/alpha,
including fade. History retains its ordinary native text path. HUD tail order,
truncation, event retention, ACKs, expiration and dice explosions remain intact.
Cache ownership follows the existing bounded layouts; retired layouts/spans
remain garbage-collectable. No global text, position or font cache is added.

Facepunch's primary [SetFont documentation](https://wiki.facepunch.com/gmod/surface.SetFont)
identifies the current font as surface state; it must not be assumed across
paints. Its [Color source](https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/util/color.lua)
defines the conversion/bounds used by the reused Color updates.

The exact published parent and candidate produce identical canonical records
for **313 drawing scenarios**, covering Unicode, kerning, wrapping, fractional
and extreme floating-point positions, HUD/history, alpha/fade, fonts, position
and live palette mutation, tail/ACK ordering and explosions. Both trace files
have SHA256 `e49cbde19dd8a0c94156050978e1aad86c3f82132e704569f186a689b835691e`.
The parent fails the candidate's new finite work bound.

| Warmed 600-frame feed work | Published parent | Candidate |
| --- | ---: | ---: |
| Native text draws | 42,000 | 42,000 |
| Native text measurements | 0 | 0 |
| Font selections | 4,200 | 600 |
| Color allocations | 4,200 | 0 |
| Coordinate rounding calls | 84,000 | 0 |

These are headless work counts, not hardware FPS savings.

The frozen candidate passes **20/20 focused checks, 313/313 canonical suites and 884 Lua syntax files**. All 2,556 source files remain unchanged during both gates. Every canonical command, individual receipt and all 626 matrix stream hashes are independently checked. Only documentation/evidence packaging follows; production/test hashes are rechecked before publication. The adjacent checks JSON and ZIP preserve raw native uploads, parent/candidate sources and traces, the expected failing parent work gate, complete/focused commands, receipts, raw outputs and source manifests.


## Next native gate

Fully quit GMod, pull/install verified main, restart gm_flatgrass and play
for three minutes with the same Proton/windowed/graphics configuration:

`lod_wall_batches 0; lod_reduced_effects 1; lod_third_person 0; lod_map_scale 1; lod_map_opacity 1; lod_perf_start 180 profile`

Leave GMod open until the final server profile reply is saved. Return
performance_client_latest.txt and console_latest.txt. Require exact source,
complete CPU profiles, idle VR, no new Lua errors and intact feed/history,
fade, colors, notifications and world visuals. Native presentation and
sustained >=40 FPS remain acceptance gates. Workshop/VPS are outside this work.
