# Open map panel before discovery; repair pickup display — 13 October 2026

Parent main: `df567c8dd970296314771d268a337196c5552c43`.
The author clarified that Q/M must open the minimap even without its floor's map:
show the missing-map message inside the normal panel, spend personal Magic and
retain map-up effects. The author also reported that collecting a map still left
that floor unavailable. This supersedes the previous close/deny rule.

## Implemented correction

The canonical minimap separates panel admission (`CanOpen`) from discovered-floor
layout access (`CanUse` / `HasAccess`). Eligible Heroes can toggle the existing
panel with Q, M or the VR/console action. An unfound floor displays **Map not
found** / **Find this floor's map** inside that panel. No topology, route, player
marker, stair, gate, jail or quadrant overlay renders there. Size/opacity still
apply to the entire panel; transparency does not stop its Magic cost.

Personal Magic admission now follows panel eligibility. Blank panels spend the
existing rate, suppress regeneration and activate existing movement/Quantum and
other map-up effects. Discovery and floor changes do not replace/refund the
personal Magic lease. Closing, exhaustion, heartbeat loss, death, role loss and
old life/run/build/pool identity still retire it through the existing authority.

The previous client needed current-floor discovery before requesting the first
map packet, but that packet alone delivered the server-resolved maze origin.
Client and server configs have independent origins; sharing a config in the old
codec fixture concealed this dependency. An offset upper floor could therefore
appear unfound after acquisition. Panel requests now always synchronize resolved
origin, layer count, build identity and the discovered subset, including a valid
zero-cell transfer when no floor is found. Empty metadata is cache-ready, avoiding
repeated empty transfers. Client floor clamping agrees with the server.

The real pickup immediately synchronizes party mirrors and pushes the new subset
to eligible Heroes, refreshing an already-open panel without requiring another
keypress. Packets and NW2 discovery can arrive in either order: rendering waits
for matching identities, then displays the correct floor. Layout filtering is
still exclusively party discovery; developer mode awards nothing. Shared touch
ownership, late/replacement Heroes, no inventory, door-free entrance placement,
globe/eye, ditty and three-line pickup notice remain. The Hermit and generated
Manual now explain the blank-panel cost/effects as well.

## Finite evidence and limits

31 selected checks pass against 34 frozen changed production, Manual and validator
files plus the unchanged pinned parent. Exact hashes, commands, outcomes, timing
and original failing outputs are in `FLOOR_MAP_PANEL_20261013/`. The two-realm
validator executes actual pickup, party policy, typed server/client transport,
both map receivers, logical-cell guards, HUD, Magic heartbeat/drain/forced close
and map-up movement. It verifies blank rendering, no cached layout/quadrant leak,
no empty transfer polling, acquisition while open, packet-before-NW2 ordering,
offset-origin acquisition before any Q/M (positive and gm_flatgrass-style negative
offsets), unchanged budget, floor changes, late Heroes, exhaustion and rebuild/death.

The parent fails both the blank-panel requirement and collected-map bootstrap;
those failures are retained. Existing checks cover 48 real layouts / 146 closed-
door paths; 12 full SQLite/28-event builds / 35 paths; keyboard focus/held keys;
81 map presentation cases; resource regeneration, movement, Quantum, Backpedal
and Strafe; notice/audio; globe; Hermit prompt/lore/idle/return; Neil/Black gate;
factions/cleanup; Manual parity; installer/source identity and performance capture.
Changed Lua parses, installer shell syntax and whitespace pass. Source coverage
is 78 installed / 74 server / 29 client, adding the Magic and logical-cell owners
at the existing verification cadence.

Live GDD navigation followed 00 → 01 → relevant 06/05/07. Google's narrow UI-rule
insert again returned `FAILED_PRECONDITION`; no current Doc update succeeded.
The explicit author clarification governs this correction; the failed request is
recorded in `gdd_write_receipt.json`. No unrelated design was replaced.

This is source implementation and finite headless validation, not native GMod
acceptance. No native executable is available here. Native input, co-op replication,
visibility/legibility and the outstanding Steam Deck >=40 FPS gate remain pending.
No Workshop/VPS deployment occurred.

## One next native action

Fully quit/update/install main and restart `gm_flatgrass`. Before finding the
floor map, press Q: the panel stays up with the reminder while Magic falls and
your applicable map-up effects activate. Touch the globe with the panel still
open: the floor layout replaces the reminder. On the next unfound floor the
same open panel returns to the reminder and continues spending Magic. M closes it.
