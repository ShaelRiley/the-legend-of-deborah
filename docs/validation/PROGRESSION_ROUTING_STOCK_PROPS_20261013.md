# Cross-floor routing and stock progression props — October 13, 2026

Parent main: `3893adc3d3f262d9c10548823d24edabd19119f9`.
Author's Dungeon-1 screenshot shows current floor 1/3, red-gate objective on
floor 2 and NO LEGAL ROUTE. Author also requires stock, all-angle key/map props.

## Diagnosis and implementation

Collected-floor topology cannot prove a path to an unfound floor. The parent
client searched that incomplete graph and incorrectly declared disconnection.
Unchanged parent server/client modules fail the focused two-realm regression:
`found floor could not route to unfound-floor objective`.
[Raw negative reproduction](PROGRESSION_ROUTING_STOCK_PROPS_20261013/parent_cross_floor_failure.log).

The existing bounded Compass transport now also supplies an ordinary collected
floor's map. Canonical Navigator computes the route using the complete server
graph and live progression/event/jail/arena locks. Only the existing bounded
breadcrumb through its first floor transition is transmitted. Unfound topology
remains private. The real client renderer uses that route and the collected
floor's native stair direction. Packet identity covers dungeon/build, player
cell/floor, stage and door state. Stale routes wait for the existing Magic
heartbeat; actual blocked paths remain blocked. No door bypass, teleport or
automatic map grant was added.

All four keycards now use `models/props_c17/BriefCase001a.mdl`; Jail Key uses
`models/props_c17/TrapPropeller_Lever.mdl`. The map retains its stock binder,
with clipboard fallback. Shared native bounds seat upright bodies exactly above
separately owned stock block pedestals. Model-local render bounds contain the
body and hints. Fixed gameplay touch anchors remain separate from model pivots;
Black-card and boss-key receipt checks use those same anchors. Custom procedural
body drawing and distance cutoffs retire. Ordinary stock textures/depth remain;
labels are hints. Bodies/blocks always transmit. Only low blocks are solid, and
they retire with their pickups. Failed required-prop creation is rejected before
native activation/registration instead of releasing an invisible pickup.

## Finite gate

[Receipt and exact changed-source hashes](PROGRESSION_ROUTING_STOCK_PROPS_20261013/receipt.json):
**23/23 pass; no source changes during validation.** Raw outputs are retained.

- Two-realm ascending/descending routes to unfound floors; bounded payload,
  exact stair guidance, no discovery/feat leak; movement/door/build staleness.
- 48 generated layouts, 146 floor-map paths and 576 canonical objective routes
  with ordered closed/open gates, Jail Key and rescue progression.
- 12 real full builds through the 28-event catalog and SQLite bridge, across
  Dungeons 1/20/21; 35 protected map paths and unchanged event counts.
- 18 actual prop cases across negative/zero/positive floor heights; all cards,
  key and map; 2160 native DrawModel calls across yaw/distance/height; fixed
  anchors, complete bounds, nonblocking bodies and owned collection cleanup.
- Retained map/Compass/Finder/Magic, origin bootstrap, jail/arena/Hector cache,
  stair recovery, Black-card/boss receipts, GPS, marker and source transport.
- Changed Lua, installer shell and changed Python syntax.

Identity coverage: 101 unique existing installer paths / 97 server / 42 client.
Static manifest coverage and real server/client transport pass. The complete
installer/VR subprocess test and full repository matrix were not run. The Jail
Key's retained gate now tests the author-requested stock body rather than its
superseded procedural geometry. Two new focused checks are registered in the
normal complete-matrix runner.

## Authority, attempts and native limits

Live GDD: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`; read 00, 01 and relevant
05/06/07 world/objective/UI/implementation rules. No routine GDD edits. Author's
explicit prop correction governs appearance; discovery, Magic and receipts remain.

Initial cross-floor fixture attempts failed on missing Geometry.StairRun and
math.AngleDifference boundaries; fixtures now supply the real geometry and
Source-compatible math. The first generated-route test referenced the wrong
Stages owner; corrected to ProgressionDirector.Stages. Scoped snapshot attempts
initially lacked full-build/receipt dependencies and the SQLite runner; those
attempts failed, then actual retrieved-dependency/SQLite gates passed. These
attempts are not claimed as successful validation.

Headless checks do not accept native GMod rendering, actual model dimensions,
contact/jumping, co-op or Steam Deck FPS. Fully quit/update/install main, restart
gm_flatgrass, follow the red-gate route across floors and orbit/collect each
stock pickup near/far and above/below. Workshop/VPS are unchanged. Preserve local
acceptance → Workshop parity → matching VPS release order.
