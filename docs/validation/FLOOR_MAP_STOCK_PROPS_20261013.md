# Stock physical map book and pedestal — 13 October 2026

Parent main: `a2ab35a46a976dc6b198b2c55b06f34dbca1cd95`.
Exact source candidate: `d53c3756571429a6d09d3392ed9ff753dda1a66a`; tree `ced8ed34a2bd3eb78564f732c4b6fad83840aefb`.
The author reports the custom globe remains invisible on approach and expressly
requests default physical props for both the pedestal and the map.

The floor-map entity now renders an upright stock blue binder with the stock
clipboard as a model-availability fallback. A second real, solid, stationary
entity uses the stock Hunter half-block as its low pedestal. Both use native
model geometry and original dimensions, with no model scaling, procedural globe
mesh or custom body distance cull. Stock rendering is brightened, and complete
orientation-safe bounds include the retained eye and floor-label hints.

Both props stay in the same reserved map cell. Their x/y offset is
min(72, CellSize*0.2), leaving the canonical arrival/walking center clear. The
native pedestal bottom rests on the resolved floor; model bounds determine its
top, and the book stands just above it. The shared typed PickupPosition is the
same server-authoritative touch/hint anchor, independent of model pivots.
Existing range, polling, party ownership, sound/notice, discovered-floor masks,
personal map Magic, Internal Compass and the door-free floor-map plan remain.

The book owns its pedestal removal; the existing builder tracks both entities.
Creation failure removes the incomplete map and fails the build cleanly.
Both entities transmit to Map Finder on other floors. The feat draws cached
native helper models for book and pedestal without recursively drawing a scripted
entity; death/role/depth guards and lighting/depth restoration remain. Collection,
refresh and shutdown retire owned helper models. No new recurring gameplay timer
or world scan was introduced. There are at most two real props per physical floor,
plus two client helpers per map only when needed by Map Finder.

The local executor is unavailable this turn. Fourteen changed Lua files parsed
with the upstream luaparse parser before publication. The existing low-end CI job
was extended to run the new prop/rendering checks, real map-panel/Compass pickup
checks, SQLite builds and changed production syntax; the checkout pins the exact
PR head SHA. The new validators are also registered in the existing complete
matrix. Source coverage is 94 installed / 90 server / 38 client.

**17 selected CI checks pass** in run 38450969612, job 115481463850, on the exact
candidate above. Full job output, checkout identity, successful steps and exact
Git blob identities are preserved in `FLOOR_MAP_STOCK_PROPS_20261013/`.
Checks execute actual production prop methods against explicit native model and
collision providers, then actual native DrawModel/rendering paths, 24 hint
viewpoints, distant/other-floor Finder and teardown. Other checks exercise real
pickup-to-party-to-client behavior, unchanged Magic/Compass, 12 full SQLite builds
and 35 reserved paths, installer hashes, source transport, renderer/performance
evidence and accepted Crate constraints.

These are headless/native-boundary checks, not a GMod visual or physics observation.
The stock model extents supplied by the fixture do not certify installed engine
assets. Native visibility, collision, cooperative replication and the existing
Steam Deck FPS gate remain pending. The broader matrix already failed on the
unchanged parent (run 38435824490); no full-matrix pass is claimed here.

Live GDD navigation followed 00 → 01 → relevant 06/07 rules. The scoped physical
prop/tuning mirror returned FAILED_PRECONDITION. Its exact proposal and rejection
remain in the preflight receipt; no successful live Doc update is claimed.
The explicit author correction governs this source repair. No Workshop/VPS
operation occurred.

One next native action: fully quit/update/install main, restart gm_flatgrass and
approach the map. Confirm the stock book and low gold block remain visible while
circling them, then touch the book and observe the ordinary shared unlock.
