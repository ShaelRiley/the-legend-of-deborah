# SPOT-12 — Spellbook card/backdrop availability colors

## Scope, authority and finite gate

Actual gameplay parent: `8b2e936f83f9740f40082fd0c3d04dc3feafde01`;
parent tree: `414bd946b75bc29e367430e9c1af3e70e56261e0`.
Connected GitHub confirmed main before edits. The independent SPOT-11 archive,
all 2174 tracked modes/blob IDs, exact tree and authentic raw commit were restored
locally. No source-reconstruction commit or isolated trigger is gameplay ancestry.
Direct container Git DNS transport was unavailable; connected tools own publication.

Read AGENTS, DEVELOPMENT_PLAN, NEXT_DEVELOPMENT_HANDOFF, SPOT_UPDATES,
SPOT_11_DRAFTS, TEST_LOGGING and live GDD 00 -> 01 -> relevant 03/06/07.
LOD-UI-002/005 retain shared paper-menu grammar and non-color semantics;
LOD-MAG-001 and LOD-FORM-001 retain Magic ownership/resource and class authority.
The current author request extends card presentation, not cast eligibility.
No missing authored availability detail required a broad HUMAN-tab read.
Before production edits, LOD-SPOT-12 supplements were inserted into live 06/07
and read back at revision:
`ANLCKQnNWm0iL4XgaF8u15mVQz3m7-qBEFByhhCF9lRk4ub01FcCuvsDBZkzXl3cF-LSOe4Q7oRLpTYsd6SnBJqaQXZTxIcvjP8LNzMcnw`.
Existing SPOT-10/11 law, all other tabs and historical evidence were preserved.

The finite gate declared in those supplements: actual production Paint/layout,
live state transitions, snapshot replacement, configuration callbacks, numeric
text contrast >=4.5:1, retained applicable regressions, manual parity and Lua syntax.
No SPOT-13 markers, SPOT-14 feat, gameplay retuning or deferred-roadmap work.

## Implementation

Only `cl_spellbook.lua` changes runtime behavior. `Book:Availability` is unchanged:
ownership -> valid living body -> Muted/Intimidated/active held throwable ->
shared cooldown -> relevant Ball/Wall limit -> ceil of snapshot-adjusted Form
plus Content cost -> available/selected. The existing server-built snapshot and
replicated body state remain the inputs. No new replicated state or timer.

| Existing state | Full backdrop / border hue |
| --- | --- |
| AVAILABLE; READY / SELECTED | Shared blue |
| BLOCKED; NEED MAGIC | Shared red |
| COOLDOWN; BALL LIMIT; WALL LIMIT | Shared gold |
| LOCKED; WIZARD / LOCKED; UNAVAILABLE | Shared muted gray-brown |

Full opaque card fill is 78% light paper + 22% state accent. Title/status ink
is 70% state accent + 30% body ink; cost/description use body ink. Nearest-integer
RGB rounding and four lazy cached treatments avoid per-repaint Color allocation.
Selection adds an inset dark two-pixel outline inside the one-pixel state border;
it never replaces the availability fill. Hover retains the same state accent.
Descriptions use the existing DermaDefault fallback when their ordinary small font
exceeds the measured card width. Literal text, current selection and binding
labels remain. The actual tested viewports are 960x600, 1280x800 and 1920x1080;
these tests use an explicit deterministic font-measurement adapter, not Source.

Owned cards remain selectable/rebindable during temporary casting restrictions;
locked cards reject direct callbacks too. Mouse buttons 2/3/4/5, selected Content,
server class/ownership checks, placement preflight, Magic spending and cooldowns
are unchanged. AVAILABLE is existing client feedback, not a promise that every
server placement/cap/lifecycle preflight will succeed.

The canonical `docs/manual/book.json` teaches the four surface states and separate
selection outline. `tools/build_manual.py` regenerates the offline HTML and the
same server-delivered manual payload; no independently authored second booklet.

## Evidence and limits

Pre-closeout: **83/83 selected suites**, **1441 new SPOT-12 production
snapshot/paint/layout/state/callback assertions**, **745 Lua syntax checks**,
unchanged source. Minimum computed foreground/background contrast is **5.119:1**
over all tested card text. See `SPOT_12_PRE_CLOSEOUT.json` for exact commands,
selection, hashes and results. All 79 SPOT-11 selections remain; additions are
`test_spot12_spellbook.lua`, `test_magic_mouse_bindings.lua`,
`test_magic_inventory_refresh.lua` and `test_minigame_ui.lua`.

Both final staged local and independent gates must use this unchanged selection:

```bash
python3 tools/test_spot12_gate.py --output /outside/source/empty-evidence-dir --suite-timeout 120 --workers 2
```

Their exact source/tree/commit/run identity and verified non-forced publication
belong in the external delivery receipt, not a self-referential future SHA here.
No full campaign matrix, full Gate-B identity pass, native engine font/visual,
co-op, movement, balance or rejoin acceptance is claimed. The pre-existing
`perkDisplayName` diagnostic boundary remains; SPOT-11 failures remain failures.
Float On stays six seconds at 1 Magic/s. Earlier SPOT01-11, B28/B29, accepted Crate
appearance and P1-P4 are untouched.

### Honest attempt history

`SPOT_12_ATTEMPTS.tar.xz` preserves raw logs, partial receipts and the first focused
source/test pair. Focused attempt 1 failed a measured description-width assertion
at 960 pixels (`Directional force cone`); the fallback fixed production rendering,
not the assertion. Focused attempt 2 passed all 1441 assertions. A streaming gate
launch was unavailable. The first synchronous full gate was interrupted by the
outer tool execution limit after 57 passing suites; it has no final receipt and is
NOT an 83-suite pass. The next complete run retained all tests, two workers and
the explicit 120-second per-suite budget. These are harness outcomes, not native
performance measurements. No assertion, seed or selection was weakened.

## One native procedure and release boundary

Install the verified source, fully quit/restart GMod, and use gm_flatgrass during
ordinary play. Open I and check that blue/red/gold/muted backdrops agree with their
literal status labels. Observe Magic depletion/recovery or a normal cooldown;
selected cards must keep their dark outline without hiding a warning. Verify
locked reasons, current Form/Content and mouse bindings remain legible at the
actual display size. Held throwables should show BLOCKED without preventing
configuration of owned cards. Native appearance and font fit remain unaccepted
until observed; headless results are not screenshots.

Return `console_latest.txt` + `rpg_summary_latest.txt` and a short observation from
that exact installed build; detailed session only for timing diagnosis. No dedicated
Razor test. Preserve local acceptance -> Workshop 3791535712 package/source parity
-> matching VPS. No Workshop/VPS action occurred or is authorized here.

Next separate bullet: SPOT-13 unread-update markers for Spellbook, Character Sheet
and Inventory, with page-specific clearing only when the corresponding update is
viewed. Reconcile live notification/snapshot law before that next implementation.
