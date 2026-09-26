# SPOT-05 — Canonical Die Logger audit

Date: September 26, 2026. Real upstream parent:
`789d63c843206061b416f0d108e7414e6aba0763`, tree
`6fef2a73975481b675ed4e018f401cfc07cbcc9f`.
The external delivery receipt supplies the verified child SHA, exact tree and
independent gate result; a document cannot contain its own commit identifier.
No Workshop publication, VPS deployment or service restart belongs to this checkpoint.

## Scope and authority

The explicit SPOT-05 request governs: audit actual producers and routing, restore
important omitted events, remove routine Magic-at-100 noise through the canonical
stream, and preserve full dice detail, meaningful outcomes, shared semantics,
life ownership and bounded history. No feat, damage, probability, resource-cost,
AI, population, physical-query or audio-lifetime balance was changed.

The live GDD was read through 00 → 01 → 06. LOD-UI-003/004/005 specify shared
server records, wording, ordering and identity spans. The older blanket
Magic-regeneration wording conflicted with the author's explicit noise exception.
A revision-guarded edit changed only that clause and added LOD-SPOT-05 to tab 06:
passive deterministic refill/synchronization and reaching capacity are HUD state,
not standalone events; actual spends, diversion, authored proc restoration, every
gameplay die, Health Regeneration and life/progression outcomes remain. Both
surfaces still consume the same stream. The addition was read back at revision
`ANLCKQkF6gJ8xnXBv9UtAl909CHfUBvOFxMiD6-jmGEovOZdKEyJR9bgcAAEZ3YW26p4R-wvOxrN3kcSvMijld5oEaMeRrcNXYL_m4y4vw`.
No exact HUMAN-only mechanic was required and no broader GDD rewrite was made.

## Production audit and repair

| Authority inspected | Defect / retained contract | Repair |
| --- | --- | --- |
| `sv_combat_rolls`, `sv_combat_feed_semantics`, `sv_feedback_language` | Paired actor/target calls could deliver the same resolution twice to nearby listeners; NPC-only paths could omit it. | One frozen sentence/serial, one union of valid participants and eligible WIS-range observers. Each listener receives at most one packet per resolution. No text/time-based merging of separate legitimate rolls. |
| Feedback family catalog and progression producers | Unknown `progression` fell back to public routine routing. | Explicit private progression family; level, feat, capstone and growth announcements keep owner-only routing. Public damage/roll families are explicit. |
| `sv_feedback_observers` and actual Magic/effect authorities | Magic synchronization emitted routine MAGIC FULL. Whole-HP regeneration and retained HP-growth dice were not consistently represented. | Remove only the passive full-cap observer. Preserve positive Feedback Loop/Arc Recovery restoration, including reaching 100. Observe actual HP increments and committed Hero/Soldier HP-growth records without creating rolls or replaying syncs. |
| `sv_rpg_status_elements` | Successful/failed saves, duration/recovery intervals, zero-result status damage and both elemental choice dice could be missing. | Capture the original returned values at their existing production seams. Preserve natural/modifier/total/DC, duration formula, rolled versus resolved interval, ordered recovery/damage dice and both Attunement choices. No additional RNG draw. |
| Dodge, Block and firearm completion | Failed qualified Dodge and ordinary misses were omitted; percentage rounding obscured exact sampled defense values. | Report actual sampled defense values and committed miss dice. Successful Dodge still explicitly resolves zero damage. Existing one-roll-per-attack caches and zero-chance/no-roll behavior remain. |
| Morale and Magic saves | Morale cooldown dice and Magic save natural/modifier detail were absent from the shared sentence. | Retain original draw order and formula with the actual save/DC/half-or-full result; calculations and settlement remain unchanged. |
| Enemy, boss, Seeker, Push, aura, retaliation and Magic damage callbacks | Separate or player-only recipient guards hid or duplicated resolved outcomes. | Reuse the same union delivery at existing completed-damage seams. Native lethal handling, damage authorization and settlement ownership remain unchanged. |
| Hero/Soldier/lifecycle observers | A replacement Hero/run or dormant Hero identity could be confused with current life/revival/Soldier activity. | Compare exact state, identity, progression owner, run and epoch. Initial/late-join/replacement sync establishes a baseline. Soldier labels use `Username as Soldier`; retired incarnation state cannot announce new growth. |
| `cl_feedback_language` and Player Menu history | Oversized persisted history was replayed through repeated truncation; serials were not retained on disk. | Load only the newest 1,000 rows, retaining original serial, order, text and semantic spans. Loaded history is not replayed live or ACKed. No new client event-category filter. |

This is a finite source audit and representative integration gate, not a claim
that every combination of every future producer has been natively observed.
Existing sealed generation, damage/explosion, resource, item and progression
authorities remain the authorities; this checkpoint does not add a parallel
logger, gameplay RNG, retained server history service or recurring world scan.

## Bounded work and parity

A combat resolution scans connected players once and unions at most the actual
participants. Existing WIS distance and living-observer eligibility remain; direct
player participants receive their event without becoming distance-dependent.
Private families do not acquire nearby recipients. Semantic formatting and JSON
encoding occur once per resolution; ACK ownership remains with direct recipients.

Dice records carry at most 64 original values per ordered part; all parts use the
same label and explicit part count. The 130-value test checks three successive
records with no omitted values. Existing text bounds, 10-record transient tail,
1,000-row retained history, 1,024-serial replay set, 50-row page, batched persistence,
512 outstanding-feedback limit and 15-second ACK lifetime are unchanged. Events
that genuinely repeat get new serials; network replays of a serial do not.

The canonical manual's existing combat chapter now teaches the same distinction,
recipient scope, ordered dice and bounded history. Both shipped renderings were
regenerated from `docs/manual/book.json`; no second manual authority was created.

## Finite validation and provenance

Run from the repository root, with a new empty evidence directory outside it:

```bash
python3 tools/test_spot05_gate.py --output /tmp/lod-spot05-gate
```

The final defined gate contains **38 selected suites**: 76 focused production
assertions, related combat/status/progression/lifecycle/feedback regressions,
B28 and bounded B29 recorded-layout/dispatch/combat regressions, SPOT-02/03/04,
Crate geometry/hull/assets, manifest, Soldier sheet, Damsel audio, manual content
and transport, whitespace and all-source Lua syntax. The runner uses at most four
workers, a 45-second per-suite bound, per-suite receipts written immediately,
and an all-source snapshot before/after to reject mutation during testing.

The final local gate passed **38/38**, with **76/76** focused assertions and
**732 Lua files** syntax checked; all source was unchanged during execution.
`SPOT_05_GATE.json` retains the receipt/log hashes and earlier 36-suite snapshot,
plus candidate source hashes labeled separately. Only coordination/evidence text
was updated afterward; no production, test or manual bytes changed. The exact
frozen-tree independent result is recorded in the delivery receipt.
The gate deliberately uses existing B29 `--runtime`: it does **not** claim the
additional 20-seed exposure sweep or full campaign-wide matrix.

Initial evidence is retained in `SPOT_05_ATTEMPTS.txt`, not overwritten:

- The old feedback and Block fixtures expected batch recipients/two source calls.
  They now check one canonical event and both actual participants; gameplay RNG
  and defense assertions remain.
- New harness attempts exposed incomplete engine/progression fixture setup,
  missing Block module loading and an incorrect expected miss sentence. Those
  boundary fixtures were corrected to exercise actual production modules.
- The initial broader run exposed a new presentation exception when a legacy
  save fixture supplies a total but no natural. `ReportSave` now guards absent
  detail rather than inventing a die or interrupting gameplay; a production
  regression case covers this. The original failure remains in the receipt.
- That first run was interrupted before the additional B29 exposure sweep
  completed. It has no complete aggregate pass and the omitted samples are not
  counted. The subsequent bounded 36-suite run passed; final manual gates extend
  the frozen candidate to 38 selected suites.

The historical SPOT-04 evidence remains **227 passing suites, one unchanged-parent
Color-fixture failure and two campaign-wide suites not run**, not a full 230 pass.
Its separate SPOT-01 50-check result is inherited, not freshly rerun here. Fresh
SPOT-02/03/04 targeted results are 44/55/74 respectively. A source harness's stubbed
`resource.AddWorkshop` message is not a Workshop action.

## Compact native procedure — still unaccepted

Install the exact candidate locally and fully restart GMod; SPOT-04's audio
lifetime fields make an old/new hot-load mixture unsuitable. Play normally, with
no forced Razor exposure or density retune. Watch the lower-right readout and
press **L** soon afterward: compare the same event's wording, dice, part order
and identity colors. The HUD is only a fading tail; older events should remain
in the bounded history, not permanently on the HUD.

Spend Magic and let it refill to 100: no routine MAGIC FULL line should appear.
A real authored restoration proc may still report its positive restoration.
During ordinary combat, inspect an available miss, failed/successful Dodge,
status save/duration/recovery, or Health Regeneration. Do not require a particular
random status, feat or level-up merely to finish ordinary play. With another
player, compare participant/nearby delivery and private progression; verify real
life loss/revival and role identity when those transitions occur naturally.

Provide same-session **console_latest.txt + rpg_summary_latest.txt** and a brief
readability report or screenshot/clip of any discrepancy. A summary/validator
alone cannot establish visible wording, order, layout, audible cues or multiplayer
parity. Detailed event logs are optional for a specific ordering investigation;
release-mode detailed-RPG logging limitations remain in TEST_LOGGING.md.

Native GMod rendering, transport, density/readability, multiplayer isolation and
all earlier audio/Climber/Razor/B29/Crate native gates remain unaccepted. No
Workshop or VPS operation is authorized by headless success.
