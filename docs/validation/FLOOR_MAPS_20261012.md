# Party-owned physical floor maps — 12 October 2026

Parent main: `297ed8c3bae1771b9eb2310e77a101d5f4daf0db`.
Author request: exactly one unique map pickup per physical floor, shared party ownership like keycards, no inventory, entrance-accessible placement before further door unlocks, keycard ditty, readable three-line notice, and the Level-1 Hermit tutorial.

## Implemented

The canonical minimap extends RunManager with current-graph/epoch/dungeon/seed stamped floor discovery. Touching a registered, nearby map as a living active Hero awards its floor once to the whole party. No inventory or wallet path is called. Respawns, replacement Heroes, reconnects and late arrivals receive current discoveries through existing lifecycle synchronization. New layouts/dungeons/campaigns reset discovery; duplicates and retired/forged/remote pickups cannot award it. Cash dungeons also have maps.

An isolated deterministic stream selects one map per physical floor within six same-floor graph steps of its first critical-path arrival (canonical BFS arrival for a gallery outside the spine). All progression, jail and boss door edges remain blocked in that proof. Side cells are preferred; entrance fallback remains available. The complete selected path is protected from event occupancy, hazards and blockades. Both ordinary loot selectors avoid it. Required map creation failures fail and clean the build. The existing Builder owns and retires all map entities; a Lua refresh cannot add another builder wrapper.

Each current-floor viewer must own that floor through party discovery. The server sends only discovered floors; both client chunk receivers validate discovery mask/build serial. An unfound floor closes the HUD and personal Magic session rather than exposing a cached map. Q/M and the VR/console action share this access authority. Existing Magic rate, modifiers, personal budget, regeneration and movement bonuses remain with their existing owners. Canonical topology encodes once per build; at most seven monotonic discovery subsets cache. No map-policy timer or recurring graph search is added.

The touch collectible is a small nonblocking animated paper fragment with a floor label. The major-FX lane reuses the keycard discovery cue and 58/22-pixel level-up fonts for a width-constrained four-second notice: **Use map with Q** / smaller **M works too** / **Map consumes magic**. Existing cue volume and reduced presentation apply. Ordinary level-up sound/timing remain. Hermit Level-1 and later reminder text, and all generated Manual chunks, agree.

## Design synchronization limitation

Live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY` was read 00 → 01 → task-relevant 05/06/07; the exact HUMAN tutorial anchor was located. Google accepted and read back the 00/01 floor-map amendment/pointer and body styles. Google rejected the subsystem/HUMAN writes with FAILED_PRECONDITION, including the tutorial mirror. The 00/01 pointers explicitly retain that limitation. No unrelated design text was erased or rebuilt. The author’s current instruction supersedes the old automatic Dungeon-1–20 policy and Dungeon-21+ exclusion; the live subsystem mirrors still need repair. See `FLOOR_MAPS_20261012/gdd_readback.json` and failures.md. Do not substitute a completion claim for this partial Doc write.

## Finite evidence

21 selected checks pass on one unchanged production/tool/manual snapshot. `checks.json` retains commands, status, timing and source hash; `source_manifest.json` retains every measured file hash. Changed Lua syntax, installer shell syntax and whitespace pass. Coverage includes 48 actual maze/progression/arena layouts with 146 all-doors-closed reserved paths; 12 RunManager/floor/event builds with the 28-event catalog and real SQLite (35 paths, unchanged 1d4 event counts); party acquisition/lifecycle/stale/remote rejection; hidden-floor server transport/cache invalidation and both decoders; Q/M/VR and 81 map preference/layout cases; literal notice/audio/size/order/read duration; existing Magic/Quantum movement, Wizard presentation, Neil/Black gate, loot/event ecology, guide dialogue/scrolling, Manual parity/reader, source manifests and performance capture/profile/transport.

Source coverage is 76 installer / 72 server-observed / 27 client sources at existing cadence. All prior friendly idle/lore work and the pending Steam Deck performance target remain. This is implemented and statically validated, not runtime-observed or accepted. No native Garry’s Mod executable is available here; native paper visibility, contact, co-op networking, notice legibility/audio and sustained frame time remain to be observed. No Workshop or VPS operation.

## One next native action

Fully quit GMod, pull/install main, and restart gm_flatgrass. Talk to the Hermit, deploy and press Q before finding the Floor-1 map; access must be denied. Touch the map near the entrance, observe the ditty/three lines, and press Q (M also works): only this floor opens and your Magic drains. A teammate/late arrival inherits that floor without an inventory item. On a new physical floor, Q is denied until its own map is found before further locks. Preserve the pending stationary Steam Deck comparison.
