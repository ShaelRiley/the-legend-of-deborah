# Author-directed spot updates — September 25, 2026

This queue precedes the regularly scheduled development plan. Shael delegates
high-level game-design decisions needed for development and production. Complete
one coherent bullet per independently validated, non-forced push; do not batch
unrelated bullets into a single gameplay commit. Keep acceptance limits explicit.

## Ordered queue

| ID | Requested result | Status |
| --- | --- | --- |
| SPOT-01 | Replace stock player nickname/health-percent and the old three-row LoD display with `Username as Character Name` and `current/max HP`. Use shared identity/character/resource colors; only the HP suffix changes green/yellow/orange/red. | Implemented; 50 focused checks freshly pass in SPOT-04; native multiplayer acceptance pending. |
| SPOT-02 | Audit and repair absent Climbers. Trace eligibility, selection, admission, placement, movement and visibility; the author has never encountered one. | Implemented; 44 focused checks freshly pass in SPOT-04; native sightings/acceptance pending. |
| SPOT-03 | Audit and repair absent Manhack-type enemies across the applicable roster, not just one name. The author has never encountered any. | Implemented; 55 focused checks freshly pass in SPOT-04; one controlled native instance passed visibility/basic combat. Other native gates and natural release sightings remain open; no dedicated retest prerequisite. |
| SPOT-04 | Stop enemy looping ambient sounds on death and all relevant removal/reset transitions; preserve living-enemy audio. | Implemented; 74 focused checks pass; native audibility/lifecycle acceptance pending. |
| SPOT-05 | Audit and update the die logger: restore important missing events, remove routine noise such as Magic reaching 100, and retain useful consistent semantics/history. | Next. |
| SPOT-06 | Improve Gordon phase one: longer follow-up-hit window without infinite loops; clear departure and destination teleport cues; quicker, more frequent and contextual taunts. | Queued. |
| SPOT-07 | Within max(0, Wisdom bonus / 2) squares, reveal Fake Gordon with a randomized-eye wink, tongue and subtle but noticeable tint. Consider a brief fart on hit and give fakes a distinctive hit-stun. | Queued. |
| SPOT-08 | Add a turret in a random corner of Gordon's arena every five dungeon levels. Resolve scaling/corner occupancy explicitly when implementing. | Queued. |
| SPOT-09 | Add Damsel's Revenge consumable. In Gordon's arena it gives the stationary, jailed Damsel a random gun and lets her shoot Gordon. On normal rescue, stop her combat, drop the gun at her feet for collection and clean up ownership/callbacks. | Queued. |
| SPOT-10 | Identify obsolete or weak feats and propose specific changes with current-code evidence. Present proposals to Shael, then implement only approved revisions. | Approval-gated audit; no rebalance approved yet. |
| SPOT-11 | Increase each feat draft from three choices to four, respecting eligibility and small pools. | Queued; explicitly authorized. |
| SPOT-12 | Color spellbook cards and backdrops as well as text so availability is evident at a glance. | Queued. |
| SPOT-13 | Show an unread-update exclamation mark over Spellbook, Character Sheet and Inventory; clear the corresponding marker when that updated page is viewed. | Queued. |
| SPOT-14 | Add Time Management, prerequisite INT 17: add the holder's Intelligence bonus to the dungeon timer while present. State time units, eligible presence, stacking and join/leave anti-exploit rules when implementing. | Queued; explicitly authorized. |
| SPOT-15 | Let human Soldiers open the team menu with F3 at any time to return to the Hero queue or spectate; add a visible hint. | Queued. |
| SPOT-16 | Give human Soldiers a pulse rifle with three-round bursts and infinite ammo, replacing their SMG. | Queued. |
| SPOT-17 | Root human Soldiers during committed pulse-rifle attacks and reduce movement speed/options to approximate AI Soldiers. Prioritize the human Hero's readable, consistent enemy experience. | Queued. |

SPOT-01 through SPOT-04 are implemented with the validation limits recorded
in their checkpoint evidence. Reports of missing enemies are native author
observations, not proof that one demonstrated defect explains every absence. Use current production
seams and release-mode evidence; increasing density or a debug-only spawn is not
by itself acceptance. Shael elected to collect natural Razor sightings during ordinary
play; another dedicated Razor test or sighting is not a sequencing prerequisite.
Preserve B28/B29 sanctuary and graduated pacing.

## Approval and handoff

SPOT-10 is the explicit exception to delegated design authority: present the
proposals before changing existing feat balance. SPOT-11 and SPOT-14 are separate
authorized changes, not authorization for unrelated rebalances. Record approvals
by feat and proposal, and carry unapproved proposals forward unchanged.

Keep `docs/NEXT_DEVELOPMENT_HANDOFF.md` current with the completed checkpoint,
verified remote commit in the delivery receipt, tests/limits and one next action.
At genuine context pressure, finish/push the current slice and give Shael a
self-contained handoff with an instruction to start a new conversation. Do not
claim an exact remaining thread capacity or promise background development.

## Preserved work and release order

Preserve accepted Crate appearance, P1–P4 and their evidence, and B28/B29. The
existing local acceptance → Steam Workshop item 3791535712 publication/parity →
matching VPS deployment order remains in force. Pending B29 native acceptance
is not satisfied by these static spot-update checks. Deferred work remains Low-End PC
Optimization (September 28–October 4, 2026) → Big Loot → Event System →
comprehensive systems audit. Queue work is not automatic scheduled execution.
