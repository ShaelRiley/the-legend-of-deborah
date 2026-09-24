# Canonical instruction manual

## Bestiary B18: Censor and Surveyor

The canonical book now teaches Censor’s attack-commit WATCH and separately
warned retaliation, plus Surveyor’s frozen threat ring and displaced refuge.
Literal counterplay, ordinary defenses, exact-life ownership, cover, interruption
and reduced-effects parity are explained in one new chapter. Both shipped
renderings are regenerated from `docs/manual/book.json`. Native Source/Chromium
readability and multiplayer timing remain pending.

## Level-20 finale and Deborah succession

The canonical source now teaches the 6.5-second celebration inside the existing
20-second victory/Tetris window, participating Heroes and rescued damsels, the
reduced-effects option, late arrivals, and the normal Level-21 handoff. Deborah
replaces the Hermit at his staging anchor; the pedestal retains its existing
starter/repeat-gift authority and her Use retains canonical Abundance. Earlier
staging and Game Master dialogue preserve the secret before Hector’s reveal.
Both manual renderings are regenerated from the same source. Automated parity
and transport checks are part of the checkpoint gate; native rendering remains
pending. See DEVELOPMENT_PLAN.md for current evidence and one native procedure.

## September 23, 2026 Hector and Level-20 rescue gate

The canonical source now teaches the Level-20 sequence: Gordon's defeat reveals
Hector; Heroes attack the Director's Heart in the court; Hector's defeat releases
the normal Jail Key; rescuing Deborah advances to Level 21+ SECURE THE BAG.
Welcome, quick-start, keycard route, Gordon and closing advice distinguish this
one-dungeon gate from Levels 1–19 and 21 onward. The dedicated Hector chapter
explains his visible core, telegraphs, phases, protected entrance, ordinary
revival, continuing collapse clock and existing rewards. Earlier Game Master
chapters retain their ambiguous identity.

Both shipped manual renderings are rebuilt from `docs/manual/book.json`.
Generated-content parity, offline reader navigation, manual lifecycle and server
transport regressions pass. Native Source/Chromium and multiplayer acceptance
remain pending. The current checkpoint and its single combat acceptance procedure
are recorded in `DEVELOPMENT_PLAN.md`; historical manual evidence follows below.

## September 15, 2026 native payload transport repair

Fresh native evidence identifies the actual launch failure. The client console
reports `Couldn't include file 'lod/manual/manifest.lua'` from line 6 of
`cl_instruction_manual.lua`. Because that include ran while the module loaded,
initialization stopped before the network receiver or `LOD.FieldManual:Open()`
could be registered. Both staging E and P → Manual were consequently inert. The
previous DHTML lifecycle repair was valid but downstream of this earlier fault;
its local harness did not model Garry's Mod client-file distribution.

The generated manifest and HTML chunks are now server-only source artifacts.
At server initialization they are concatenated into the one canonical document
and compressed once. Opening either entry point creates the reader frame
immediately and requests that payload. The server sends ordered, reliable chunks
of at most 60,000 bytes; the client bounds and verifies the transfer metadata,
reassembles and decompresses the exact document, then invokes the existing DHTML
lifecycle. The document is cached for later openings. A rejected, incomplete or
malformed transfer presents a retry control inside the already-visible frame.

The runtime audit now requires a server `manual` receipt and client
`manual_reader` receipt under build `stability-20260915-04`. The dedicated
transport regression proves exact byte preservation across multiple bounded
messages, while the client regression proves the window opens before delivery,
requests the payload, and completes the canonical bookmark/navigation bridge
after receipt.

## Earlier September 15, 2026 DHTML lifecycle repair

The initial portable-reader implementation registered `DHTML:AddFunction`
callbacks before `SetHTML`. Garry's Mod binds those functions to the current HTML
document and requires registration after it has loaded, so Chromium document
replacement could discard the bridge. The reader now binds its bounded position,
close and P/I/L functions from `OnDocumentReady` and queues bookmark restoration
from the same event. The regression double rejects any pre-document callback
registration, covering the native lifecycle that the original permissive mock
missed. Both launch paths still converge on `LOD.FieldManual:Open()`.

## Initial September 15, 2026 checkpoint

The continuation on `astra/equipment-update` replaces the staging-only reader
with `LOD.FieldManual`, loaded by the gamemode on every client. The shared Player
Menu has a **MANUAL** tab. The staging book's existing E interaction sends the
existing `LOD_OpenFieldManual` message to that same `Open()` method. It has no
separate renderer, content, or bookmark. Opening the already-visible manual
focuses its existing frame.

P / I / L keep their existing Character / Spellbook / Die Log shortcuts. The
manual closes through the shared menu lifecycle, including terminal TIME OVER.
Ordinary reading requires no staging entity, living Hero, role, or deployment
state. Reading never pauses or changes gameplay. The physical entity's server
use validation remains intact.

The reader provides a chapter selector, literal text search, previous/next,
scrolling, 15–26 px text sizes, keyboard navigation, and a saved page/scroll/text
size. It uses ES5 JavaScript and embedded images; no network requests, external
fonts, or Workshop art are needed. General DHTML Lua execution is disabled;
only bounded bookmark, close, and P/I/L callbacks are exposed. Stale
callbacks cannot change a newly opened reader.

## One content authority

- Author guide prose in `docs/manual/book.json`.
- Export the final production feat/property catalog with
  `python3 tools/run_lua54.py tools/export_manual_catalog.lua`.
- Run `python3 tools/build_manual.py` to generate `docs/manual/manual.html` and
  the identical client payload in `gamemode/lod/manual/html_*.lua`.
- Optionally append `--pdf /absolute/path/Legend-of-Deborah-Instruction-Booklet.pdf`
  to render the same content as a 4.125 × 5.25 inch booklet, with PDF bookmarks
  and a multiple-of-four page count. This uses ReportLab, pypdf, and DejaVu fonts.

Generated HTML, Lua chunks, and PDF are renderings, not separately authored
manuals. The source check reconstructs the entire HTML and compares every byte
with the shipped client chunks. Each chunk stays below 64 KB. Retired entity
HTML/audio chunks are removed. The old autorun is an inert cleanup shim so an
existing installation does not retain its independent scrolling patcher.

The expanded guide contains 42 how-to chapters plus the full reference, for
124 in-game chapters including the cover. It includes all 135 ordinary feats,
six fallbacks, nine class capstones, and 60 equipment properties. The printable
edition is 136 pages because it includes the full rules reference, not only the
illustrated quick guide. Its chapter guide uses the in-game chapter numbers;
PDF bookmarks provide direct navigation.

## Reconciliation

The live GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`, normalized tabs
02–06 and exact relevant detail anchors, governed the mechanics audit. Current
continuation code and its final override order governed descriptions of the
implemented build. The author's explicit campaign-clock handoff supersedes the
older per-dungeon timer rule, as documented in `CAMPAIGN_TIMEOUT.md`.

Covered updates include: continuous campaign timeout and aftermath; six Forms
and six Contents; class cores and Wizard offense; Backstab and Fighter shield
Block; current ammo capacities and gun behavior; owned gear, multiple weapon
copies, wearables and special moves; potion/stink-bomb controls; equipment loss
on death; Tetris and comeback; Soldier lifecycle; all 18 ordinary enemies plus
Neil/Brute/Gordon; rescue-only DFT minting and current wallet settlement. Deferred
Heavy, alternate maze families, and the unshipped adaptive MusicDirector are not
taught as available features.

## Evidence and next native check

All 93 integrated automated suites pass. Gates include: canonical menu/reader lifecycle harness; production JavaScript
navigation test with a DOM double; generated-content parity and offline-asset
checks, including catalog parity with the final production graph; the complete integrated regression suite. The existing protected
regression harness now returns a loaded module's value, matching real `include`.
No gameplay authority was changed to satisfy that test.

PDF pages were rendered and visually inspected, including cover, illustrated
guide pages, dense tables, reference pages, and page contact sheets. A text-bound
audit found no text outside the safe page bounds. The cloud browser policy
blocked local preview URLs; no browser visual acceptance is claimed. The JS DOM
double verifies logic, not embedded Chromium layout.

**One native check on gm_flatgrass:** open the staging book with E, turn to a
middle chapter and scroll, switch to Character, enter the dungeon, then use
P → MANUAL. Confirm the same chapter/position, readable illustrations, text-size
controls, search, Escape/P/I/L, and no stacked windows. Return to staging and
use E again. Repeat with a second client and a dead/spectating player. Confirm
ordinary danger/time continues and terminal TIME OVER closes the reader.

Source/Chromium input, native rendering, and multiplayer runtime acceptance
remain pending. The prior native-crash release hold remains open; this checkpoint
does not deploy a public server or claim that crash is fixed.
