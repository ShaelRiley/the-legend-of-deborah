# Internal Compass, Map Finder and relentlessly proud GPS — 13 October 2026

Author additions began on main `4cd2232a99d3a996f67d0ba7b47df4eb5cc03ec2`.
The published Jail Key/Hermit portrait checkpoint was integrated before final
verification; this checkpoint's parent is `95597c0c0352d40ee428410e634fcc03e62b2809`.

## Implemented author rules

**Internal Compass**, `WIS_INTERNAL_COMPASS`, is an ordinary single-rank feat
gated at **Wisdom 15**, with no prerequisite. With the existing Magic map panel
open, an unfound floor shows the holder's ordinary current-objective breadcrumb
trail and player marker; walls, gates, quadrants, jail and other maze overlays
remain hidden. The server sends only bounded route coordinates, including the
next stair cue, through a typed private channel. It reuses the canonical route,
normal breadcrumb range and Cartographer bonus. It grants no party discovery and
does not change map Magic drain, regeneration suppression, or map-up effects.
Nonholders retain the in-panel missing-map reminder. Finding the shared map
returns to ordinary layout rendering.

**Map Finder**, `WIS_MAP_FINDER`, is an ordinary single-rank feat gated at
**Wisdom 13**, with no prerequisite. In world view, the holder sees the actual
uncollected globe/eye pickups and floor labels through walls and ceilings,
including other floors. The at-most-seven pickups transmit outside the ordinary
PVS and register once in a weak client collection; the finder has no world scan
or new timer. Depth is restored even if the drawing callback fails. This passive
effect requires neither the panel nor Magic and grants no map ownership. The
existing pickup, shared collection and all-angle normal drawing remain intact.

Both feats use existing eligibility, qualification, ownership, derived-state,
NW2 and sheet authorities. Their normal draft inclusion does not reroll stored
hands. The catalog now contains 114 ordinary feats, six neutral fallbacks and
nine capstones; the generated native/browser Manual and edited card text agree.

**GPS** retains its Wisdom 17 gate, Hero scope, private speech, enabled acquisition,
G toggle and zero Magic cost. It assesses actual travel velocity on the legal
current-objective route. Wrong-way movement interrupts praise and sends a
correction on the next existing **0.20-second** update. Correct movement cycles
**16** overly affectionate lines, with only **0.25 seconds** after each phrase.
Nearby enemies or attack input do not silence moving feedback. Looking sideways
does not cause a correction. The original guarded idle directions retain their
one-second trigger and four-second post-phrase pause. Life, role, spectator,
staging, body, run and toggle cancellation still stop old speech callbacks.

The eight fictional staff writers and their line decisions are recorded in
`../lore/room/gps_navigation_praise_20261013.md`. The authored lines are delivered
by a new offline Flite kal synthetic bank: 577,245 bytes, mono 22,050 Hz, 72.06
seconds. Sample-derived markers select complete clips using the existing single
client speech channel. The direction bank remains the source for corrections.
`tools/build_gps_praise.py` reproduces the praise asset without a voice service.

## Shared route correction

Native include order installed the optimized private BFS before the later Warden
traversal decorator. Its cached route could bypass the closed jail or arena.
The exact existing progression-door policy is now a shared traversal helper;
optimized BFS consumes it and its jail/arena/boss/Hector signature. Changing a
door invalidates route trees in the same tick. No independent pathfinder or
unbounded cache was added. The parent reproduces the closed-jail bypass using
the same validator and its two original production modules; that failing output
is retained beside the passing actual-include-order check.

## Finite evidence and limits

**41 selected checks pass**, against **59 frozen changed source, audio, Manual,
writer and validator files** plus the pinned parent. Commands, per-file hashes,
timings and original outputs are in `NAVIGATION_FEATS_20261013/`. Two-realm tests
execute real pickup, party policy, typed packets, HUD, Magic heartbeat and
movement effects. They prove trail-only discovery, bounded/stair/closed-gate
behavior, route identity checks and removal, acquisition while open, both origin
signs and the original no-map panel. Finder tests cover distant/other-floor
drawing, nonownership, native depth passes, dead/role exclusions, pickup removal
and unconditional depth restoration.

GPS tests cycle all 16 authored lines and exercise fast praise interruption,
velocity versus camera direction, return to praise, nearby enemies/attack,
idle/life/run/toggle cancellation and actual private client bank selection.
The shipped MP3 is decoded to prove every clip is audible, complete and
nonoverlapping. Other selected regressions cover feat gates/drafts/snapshots,
Magic lifecycle, map movement/Quantum/Backpedal/Strafe, quantized and hostile
route caches, Warden/Hector, placement across 48 layouts and 12 real-SQLite full
builds, Hermit prompts/portrait, the new Jail Key pedestal, cleanup, Manual parity,
installer/transport and performance evidence. Changed Lua, shell and whitespace
checks pass. Source identity covers **91 installed / 87 server / 36 client** files.

The initial marker fixture incorrectly returned true for every new NW2 flag;
its failure is retained and the fixture now explicitly gives unowned feats false.
The full integration matrix was accidentally selected, stopped and timed out at
its finite 90-second limit; its partial evidence remains and is not counted as
a passed check. After a player-facing GPS description edit, only affected
catalog/Manual/GPS/source/marker checks were repeated. The initial manifest and
receipt are preserved; unchanged authorities retain their original evidence.

Live GDD navigation followed 00 → 01 → relevant 04/05/06 rules. Google rejected
the narrow Internal Compass author-rule write with `FAILED_PRECONDITION`; no
live Doc write succeeded. The exact proposed rule and subsequent author additions
are retained in `gdd_write_receipt.json`. The user's explicit changes govern this
source checkpoint; the live mirrors remain pending.

This is source implementation with headless validation, not native GMod
acceptance. Native voice timing, visual legibility, through-ceiling visibility,
co-op replication and the existing Steam Deck ≥40 FPS gate remain pending. No
Workshop/VPS operation occurred.

## One next native action

Fully quit/update/install main and restart `gm_flatgrass`. With the feats owned,
open Q on an unfound floor to see only the breadcrumb while Magic falls; close
it and look toward/above other-floor map globes through walls. Walk along the
objective route to hear repeated praise, reverse to interrupt it with a correction,
and press G to silence/re-enable GPS. Collecting a globe still unlocks that floor
for the whole party and replaces its blank panel with the ordinary maze.
