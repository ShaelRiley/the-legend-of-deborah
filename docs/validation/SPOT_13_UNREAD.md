# SPOT-13 — Unread player-menu updates

## Authority, scope and publication boundary

Author-directed queue bullet SPOT-13 only. Repository `ShaelRiley/the-legend-of-deborah`,
branch `main`; actual gameplay parent `795dd444144e4e733dea58e56b4302bcb648f1ba`,
base tree `6ce1793cddc5fe07b5a75aaf0c62f74f82c26ed2`. The base archive, authentic
raw commit, modes/blob IDs and all 2179 entries were verified before modification.
An isolated workflow trigger must never be substituted for this gameplay parent.

Live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY` was read via 00 -> 01 ->
06/07. The existing author delegation covers the missing notification choices.
The single LOD-SPOT-13 supplement in each of 06 and 07 was written before code and
read back at revision
`ANLCKQmIMm_T7FU5TgAc9E36K4WlHuJdiUbhq63f7bNXKIXUwGQl2gGU0Y5wJL63wde-cooNSMj6vfXvdVsDLCdjQylrxqRCI1VW4hqA6A`.
Do not duplicate those sections. Inventory means the carried-item grid in the
existing first-class Equipment page, not Spellbook or a new seventh page.

Source implementation and the final focused test are complete. The finite
aggregate contract is 85 selected suites, retaining all 83 SPOT-12 selections,
plus the new production transition test and instruction-manual reader test.
Final local/independent receipts and verified child/tree/run are external to this
source snapshot and supplied by the delivery receipt. This document is not a
preemptive claim that an unrun aggregate or publication passed.

## Player-visible contract

A static red exclamation appears in a light-paper band immediately above the
CHARACTER, SPELLBOOK and EQUIPMENT buttons when that page has unseen meaningful
content. Die-Logger, Manual and Wallet never gain unread markers. Existing labels,
P/I/O/L direct-open behavior, menu access and non-pausing gameplay stay intact.

Character tracks level/class, identity traits, permanent ability provenance,
owned feats/capstone and pending choices. It excludes routine XP, current HP,
derived temporary modifiers and other volatile resource presentation. Spellbook
tracks owned Form/Content IDs, not cast availability, costs, cooldowns, Magic or
selection/bindings. Inventory tracks copied item records, stack amounts and
storage capacity, excluding remaining Wand charges, equipped-slot movement,
active-weapon switches, ammunition and derived Block chance.

The first authoritative snapshot of each page is a quiet baseline. Later changes
coalesce into one unread mark, which survives an unchanged full resynchronization.
Viewing a sibling, opening a loading frame or requesting data does not clear it.
Only the current corresponding page, after its updated children have painted,
acknowledges the exact current snapshot. A hidden, removed, replaced or minigame-
blocked page cannot acknowledge. An inventory rebuild deferred by either a
mouse-down drag watch or active drag retains its previous displayed snapshot;
painting those old items does not acknowledge the newer unseen inventory.

## Shared production seams

`sv_snapshot_delivery.lua` remains the single coalescing/deduplication owner.
The three relevant reliable channels receive an envelope with `_pageUpdate`
(epoch, revision, optional exact delta base) only after ordinary content dedup.
The underlying authoritative snapshot/gameplay tables are never annotated.
Equipment retains its existing full/delta writer and expanded client state.
A delta with an unavailable baseline requests the ordinary snapshot recovery.
The client rejects old/duplicate epochs/revisions before replacing visible data.

A presentation scope binds current RunManager state, player state, Hero
progression/identity, Soldier incarnation and alive state. The existing death
hook explicitly retires a life even when death and respawn occur between sends.
Disconnect retires that recipient. Producer-time owner replacement requeues
through the same delivery window instead of sending a stale DTO. Equal-valued
replacement identities still retire old pages. Ordinary floor/deployment serials
and cache cleanup alone do not reset surviving Hero unread state. Explicit
snapshot invalidation clears delivery caches, not presentation revisions.

`cl_ui_unread.lua`, loaded directly after `cl_ui_theme.lua`, owns only three
copied meaningful projections and current page/snapshot bindings. Receivers in
Character Sheet, Spellbook and Equipment admit, observe and display the same
snapshot. Completed page builders bind post-child PaintOver acknowledgments;
Inventory binds only after a real successful rebuild. The existing PageLinks
renderer draws markers on the parent, avoiding clipping outside button bounds.
No new network channel, polling loop, per-feature timer, actor scan, persistent
store or gameplay owner is introduced. The existing delivery timer is unchanged.

The marker band is 18 pixels, with a 16-by-18 light-paper backing and the existing
LOD_SheetKey font/red role. Character navigation moves from y76 to y100, with
body/loading offsets moved by 24 pixels. Die-Logger navigation moves from y78 to
y100 and its legend/body by 22 pixels. This reserves the marker band without
covering headings; actual draw bounds are asserted at 960x600, 1280x800 and
1920x1080. Other pages retain their existing navigation. SPOT-12 card painting,
selection outline, resolver, font fallback and cast/configuration rules are not
changed. Native Source font/render measurement is still required for acceptance.

## Focused evidence and retained failures

The final `focused-08` invocation of `tools/test_spot13_unread.lua` passed **317
numbered production-boundary assertions**. Its setup also executes the retained
equipment-economy fixture; that fixture's own assertions are not counted in 317.
The test uses actual snapshot producers, delivery, delta writer, client receivers,
page builders and Paint/PaintOver callbacks. Native entity/network/Derma APIs are
explicit deterministic boundary doubles, not actual Garry's Mod observation.

The selected production transitions cover quiet initial sync, dedup/coalescing,
closed/open/sibling pages, repeated/noisy data, real level/Form grants and stack
add/increment/consumption/depletion, storage capacity, stale/duplicate full/delta
packets, lost delta and exact-baseline recovery, resync, both drag stages,
loading/minigame/hidden/removed/replaced frames, header/badge geometry, surviving
floor transition, death (including no intervening packet), campaign/Hero/player-
state replacement, actual Soldier attach/retire, read-only Soldier sheet,
recipient isolation, reconnect and a producer-time lifecycle race.

Raw attempts and per-attempt source manifests are retained losslessly in
`SPOT_13_ATTEMPTS.tar.xz`, SHA256 `51c13072040bb707308183a626af71ffa5c0e205351156c4b37d07157ba558b3`.

- Initial four regressions passed: snapshot delivery, SPOT-12 Spellbook (1441
  focused assertions), Character layout and Equipment inventory UI.
- Focused 01 and 02 failed because the new fixture mutated recomputed scratch
  growth rather than permanent ability provenance. The fixture now changes a
  real persistent base ability; the second attempt retained an added traceback.
- Focused 03 failed because the portrait boundary adapter omitted its native
  Paint method. The adapter was completed, not the production renderer weakened.
- Focused 04 failed on the fixture's nonexistent `wand` family; the real registry
  ID is `weapon_lod_wand`. Focused 05 then passed 262 assertions.
- Header review found potential badge/heading overlap and production spacing was
  corrected. Focused 06 passed 293 assertions plus retained Character-layout and
  SPOT-05 Die-Logger regressions; assertions include actual header draw bounds.
- Focused 07 failed because direct fixture item removal left a dangling equipped
  slot. The depletion scenario now uses canonical Equipment consumption. Focused
  08 passed 317 assertions. The earlier failures remain failures.

The first documentation script stopped before writing manual/docs because it
assumed a block-based chapter; the real chapter uses a paragraph list. The
script was corrected without changing or dropping existing content. This was a
documentation preparation error, not a gameplay/test result.

The first aggregate was interrupted by the outer 200-second execution limit
after 33 passing suites, with no final receipt. It is not an 85-suite
pass. Its raw completed-suite output and post-interruption source manifest are
retained under aggregate-01-interrupted. No production/test changes followed;
only this provenance record and its lossless archive were extended.

A streaming launch was unavailable before the docs/final-gate command executed;
it is not a test result. All earlier SPOT-10/11/12 failed and interrupted evidence
remains unchanged. In particular the historical Skeleton timeout is not a native
performance result, and full Gate-B identity validation still has its pre-existing
`perkDisplayName` diagnostic issue. No full Gate-B pass is claimed.

## Finite final gate

Run once the complete source, manual and evidence are frozen:

```sh
python3 tools/build_manual.py
python3 tools/test_spot13_gate.py --output /outside/checkout/spot13-gate --suite-timeout 120 --workers 2
```

The inherited gate includes manual catalog/document/transport parity, asset and
release manifests, `git diff HEAD --check`, and every Lua source syntax check.
The expected Lua file count is 747; use the actual final receipt, not this
expectation, for delivery. Gate output stays outside the checkout to prevent a
self-referential source hash. Require identical before/after source hashes, no
changed files, matching independent source/tree and one non-forced child push
from the actual current main parent. Preserve any additional failed attempts.

## Native and release boundaries; next checkpoint

On the exact installed build in `gm_flatgrass`, obtain ordinary loot and a
progression/unlock while the relevant pages are closed; view a sibling first,
then each marked page. Observe that only the displayed page clears, ordinary
resource/cooldown changes stay quiet, and markers remain legible. Include a
short drag-deferred refresh and subsequent ordinary transition when available.
Return `console_latest.txt` + `rpg_summary_latest.txt` and a short observation;
use a screenshot for a visual defect and the detailed session only for timing.
No dedicated Razor retest is required. Headless tests do not prove native font,
appearance, actual networking/co-op, movement/balance or full campaign acceptance.

Preserve SPOT01-12, four-choice draft/stored-hand contracts, Float On six seconds
at 1 Magic/second, B28/B29, accepted Crate appearance and P1-P4. No Workshop or VPS
action is performed or authorized. Local acceptance -> Workshop 3791535712
package/source parity -> matching VPS remains mandatory.

After verified publication, next is **SPOT-14 Time Management**, prerequisite
INT 17. Reconcile units, eligible presence, stacking and join/leave anti-exploit
rules through the live GDD before implementation. SPOT-14 and deferred roadmap
work are not implemented by this checkpoint.
