# Steam Deck HUD text checkpoint — October 6, 2026

Parent: clean main `7de6a8359af27713526a4d0108c110bac3bee9ed`.
Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, navigated
00 → 01 → 06 LOD-UI-003/004/005 and 07 LOD-IMPL-001–004.
No design or tuning amendment is required.

## Native evidence

Capture 9 independently matches every installed/mounted population source to
the parent (42/42), including all eight renderer sources. It completes both CPU
reports, with zero client/server end Lua errors and no configuration changes.
It measures 24.86 active FPS over 165.78 seconds, median 35.727 ms, p95 68.876 ms;
4,112 of 4,122 active frames exceed 25 ms. Native walls remain enabled. This maze
has 1,340 wall models, two floors and 39 living wanderers at the population
snapshot (40 successful initial admissions). Capture 8 had 1,648 walls and a
different generated workload; the aggregate FPS change is not a controlled code
comparison. Sustained >=40 FPS still fails.

The combat-feed HUD callback costs 8,610.98 inclusive CPU ms across 4,474 calls,
mean 1.925 ms. Static geometry remains the largest measured game render row,
22,603.83 ms / 8,948 calls. Inclusive CPU rows overlap and include diagnostic
overhead; neither proves GPU cost or a prospective FPS gain.

## Finite source gate, defined before implementation

Retain the existing shared feed/history layout and UI text authority. Cache each
drawn semantic span's exact whole-string advance within its bounded layout;
invalidate on text/font, screen-size and Lua-refresh changes. For existing
left/top HUD text, submit the same native text draws with one font selection,
without measuring dimensions that cannot affect alignment. Preserve the stock
nine outline offsets (including center), foreground, ceil-rounded placement,
colors, alpha, font, text and draw order. Other alignments keep the existing
native helper. Do not change any event, lifetime, history cap, receipt/ACK,
congestion policy, font definition, effect or gameplay rule.

The stock drawing contract was inspected in the primary Facepunch source:
https://github.com/Facepunch/garrysmod/blob/master/garrysmod/lua/includes/modules/draw.lua
(`SimpleText` and `SimpleTextOutlined`). The one-pixel outline performs nine
outlined submissions and one foreground submission; each currently reselects
the font and measures text.

Require paired unchanged-parent/candidate native-call traces across fractional
positions, wrapping, semantic roles, UTF-8, fading, congestion and HUD/history;
unchanged transport/history regressions; bounded per-span caches and invalidation;
and an independently verified frozen integration gate. Work-count reductions
are synthetic evidence, not native performance acceptance. Extend existing
source fingerprints to cover the changed UI/feed authorities.

## Source evidence and limits

The paired production test covers 201 trace groups, including all alignments,
fractional/near-integer coordinates, UTF-8/overlong text, whitespace, semantic
colors, fading, HUD congestion/expiry and existing dice-explosion effects. The
unchanged parent files are retained byte-for-byte as test fixtures. Over 600
warmed HUD tails, native text submissions stay 42,000; text measurements fall
46,200 → 0, font selections 46,200 → 4,200 and Color allocations 8,400 → 4,200.
The tests also exercise screen/font/text/span/Lua-refresh invalidation and old
history-panel line references. Existing canonical Die Logger, feedback, AG011,
capture/profile and repeat-installer regressions pass.

The first complete-gate attempt was interrupted after its source-count tests
exposed remaining 42-source expectations in B28's missing-manifest case and the
population-transport fixture. Both now require the complete 44-source record,
with all existing mismatch, missing-source, caching, JSON/wire/console and DATA
failure assertions retained. Corrected focused B28 and transport checks pass.
The interrupted attempt and its failures remain in the archive; they are not
discarded or represented as a passing complete gate. The publication gate uses
the corrected frozen source in a fresh evidence directory.

The candidate keeps a per-span exact advance, never a global text dictionary.
The existing ten-entry HUD, 1,000-entry history and 50-row history page remain.
Each layout owns its latest text/font/epoch metrics; discarded layouts do not
remain in a strong global cache. Non-left/top text and environments with partial
native surface doubles retain the prior helper. The render/population installer
and observer lists agree at ten/44 sources, including both changed authorities.

The complete frozen gate must pass before publication. Its independently
verified result is [the matrix receipt](STEAM_DECK_20261006_HUD_TEXT_matrix.json).
The [complete archive](STEAM_DECK_20261006_HUD_TEXT_complete.zip) retains individual
suite receipts, raw stdout/stderr and hashes, frozen source manifests, original
native captures, parent bytes and paired/targeted evidence. Source checks and
native-call doubles do not certify actual Source rasterization or Steam Deck FPS.

## Next native gate

After source publication, fully quit GMod, update/install main, restart
gm_flatgrass and deploy before running:

`lod_wall_batches 0; lod_reduced_effects 1; lod_perf_start 180 profile`

Keep the established Proton/windowed/resolution/graphics settings. Play the
complete three minutes and keep the game open for its final server reply. Verify
the lower-right feed and L history retain readable wording, color, wrapping,
outline and fade, with intact world surfaces and no new Lua errors. Return the
same performance_client_latest.txt + console_latest.txt. Sustained >=40 FPS
remains open. Workshop/VPS deployment remains held.
