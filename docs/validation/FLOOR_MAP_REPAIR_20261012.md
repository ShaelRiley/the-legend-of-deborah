# Floor-map runtime report repair and Hermit prompt — 12 October 2026

Parent main: `47f4e74e4790155b149de323d956ca155585b622`.
The author reported an edge-on map pickup and Q/M revealing floors whose maps had
not been found, then requested the same large interaction indicator for the Hermit
as the portal/statue. This is a source/static repair; native acceptance is pending.

## Root cause and correction

The development installer enables developer mode. The previous minimap retained
developer exceptions in server authorization, compatibility masks, topology
filtering and client access. Strengthened production-code fixtures reproduce all
three failures on the parent: server discovery, client cached-floor display and
server topology disclosure. Their original failing outputs remain in
`FLOOR_MAP_REPAIR_20261012/parent_*_failure.log`.

All map exceptions are removed. Developer mode uses the actual party discovery
mask and current-floor ownership. Q, M and the VR/console action close an unfound
floor's map and notify **Map not found — find this floor's map**. Server requests
also deny it, send only discovered floors, and omit undiscovered jail coordinates.
The existing personal Magic authority rejects forged opens and immediately loses
its movement/drain lease when entering an unfound floor. Found maps retain their
normal cost, cache and party lifecycle.

The paper drawing is replaced with one lazy shared 224-triangle colored globe
(18-unit radius, 16 segments, 8 rings). A bold eye above it faces each viewer in
pitch and yaw. Its polygons are cached; each pickup reuses its Matrix. Expanded
render bounds include the eye and nearby label at every orientation. Existing
six-cell body/two-cell label culls, ordinary depth and Reduced Effects apply.
Refresh/shutdown destroys the mesh. Shared touch ownership, no inventory,
entrance-accessible placement, tutorial, keycard ditty and large pickup notice
remain with the previous authorities.

The existing `LOD_StagingInteractionPrompt` HUD hook now also shows
**Press E to Talk to the Hermit**, using the rebound Use key and the same
38-pixel font/outlined placement as other staging interactions. It requires the
aimed-at guide within the existing 112-unit talk reach and an alive staged Hero;
deployment, Soldier/eliminated state, menus and open dialogue suppress it. The
existing revealed speaker name becomes Hector only after the guide label changes.
No dialogue interaction, reward, animation or parallel prompt system is added.

## Finite evidence

24 selected checks pass against 14 frozen changed production/validator files and
the exact unchanged parent tree. Commands, outcomes and timing are in `checks.json`;
`source_manifest.json` records the parent and changed-source hashes. Coverage:
developer on/off and real Magic admission/revocation; 48 production layouts / 146
all-doors-closed map paths; 12 full SQLite/28-event builds / 35 reserved paths;
Q/M/VR exact denial and cached-floor closure; transport and both decoders; closed
outward globe geometry, 24 eye viewpoints, complete billboard bounds, reuse and
cleanup; one Hermit prompt and all previous staging prompt variants; pickup notice
and cue; existing map movement/Quantum, lore UI, friendly idle, Hermit return,
Neil/Black gate, factions, cleanup and performance/source identity regressions.
Changed Lua syntax, installer syntax and whitespace also pass. Installer/server
coverage remains 76/72; client capture now covers the HUD root too (28 sources).

Live GDD navigation followed 00 → 01 → relevant 05/06/07. Narrow current-turn
subsystem inserts, 00/01 inserts/styles and one exact 00 paragraph replacement all
failed with Google's `FAILED_PRECONDITION`. Readback confirms the prior 00/01
party-map amendment remains unchanged; these new corrections were not saved to
the live Doc. The explicit author instructions govern this repair. The write
receipt and exact partial state are preserved in `gdd_write_receipt.json`.

No native Garry's Mod executable is available here. Static geometry/engine doubles
do not prove native visual quality, input, pickup contact or co-op networking.
Prior Steam Deck performance acceptance remains pending. No Workshop/VPS operation.

## One next native action

Fully quit/update/install main and restart `gm_flatgrass`. Approach and aim at the
Hermit: the large Use prompt should appear. Deploy and press Q before touching the
floor map: the requested denial must appear. Find the globe near the entrance,
view it from different sides, then touch it and use Q/M. That floor opens with
personal Magic drain; the party inherits it. On the next unfound floor Q/M denies
again, including in the installed developer mode.
