# Final hybrid integration and visual realignment

Starting branch: `hybrid/antigravity` at `2650b4a02354d882c5b5f794307766b772f5ce14`.
Scope: Shael's final presentation/integration mandate. No gameplay rebalance,
main merge, public deployment, or GDD edits.

## Findings and changes

- The Spellbook was a separate dark utility panel; history discarded semantic
  colors and created up to 1,000 panels and deferred layout callbacks. All now
  inherit the Player Sheet's ivory paper, serif copy, condensed headings,
  brick-red hierarchy, muted royal-blue identity and restrained ochre accents.
  Sheet, Spellbook and DIE-LOGGER have peer navigation; P/I/L switch surfaces
  exclusively, including delayed snapshot and keyboard-focus paths.
- One shared theme owns palette/fonts/paper/buttons. The live DIE-LOGGER is its
  compact derivative. Objective/HUD/Magic panels and the in-world leaderboard use
  the same vocabulary. Long leaderboard parties wrap onto cycling pages without
  altering rank order or persisted records. Existing staging signs/manual artwork
  and established world sound/particle families remain intact.
- One server formatter emits text plus semantic spans; the exact spans are used
  in the HUD, saved history and developer dispatch evidence. Steam identity is
  blue, literal `as` neutral, character identity brick red, independent of whether
  that human is actor or target. Dice are muted violet, continuations/results
  ochre, resource gains green, status violet and resistance blue. Labels/notation
  remain meaningful without color. Legacy history remains readable.
- Removed the obsolete 180-byte sender and duplicate damage formatter, obsolete
  celebration receiver/painter, and duplicate Wizard Feedback summary. Major FX
  transport installs synchronously. The actual Feedback dice record remains.
- Replaced detail-dropping 512-byte transport with a bounded 4-KiB record (bounded
  identities plus up to 3 KiB of detail). Actual dice retain independent chain
  starts: `+` separates base dice, `>` marks continuation, `@N+` records its actual
  explosion threshold, `=>` marks adjusted contribution. Hostile cached contracts
  retain their explosive formula and chain metadata. Magnum and Magic formatting
  reuse the same formatter; existing pierce-chain grouping remains intact.
- History retains 1,000 records, pages 50 at a time, and saves in two-second
  batches/on shutdown. A page is frozen while read; LATEST fetches the newest tail.
  Long UTF-8 identities wrap without byte loss. Replay suppression is bounded to
  1,024 recent transport serials. HUD overflow is explicitly linked to the full
  retained record rather than dropping the whole oversized entry.
- Cancelled Spellbook requests cannot reopen dismissed/superseded UI. Expired
  notices are dropped; newer lifecycle notices retire stale lifecycle banners.
  Resource/Form observers compare incarnation/campaign state. The Soldier ESC
  control disappears on role loss, and active Soldiers no longer read SPECTATOR
  in the life HUD. Progression wrappers preserve return tuples with nil holes.
  DIE-LOGGER send failures are contained at the presentation boundary.
- Beam uses a cyan laser core along the actual production trace endpoint;
  Content colors its impact. Blast adds vertical wave arcs. Both have an explicit
  caster-local labeled aperture for first-person visibility. World FX live in a
  dedicated module, cap at 48 entries, and skip depth/skybox passes. No particles,
  extra entities, dynamic lights or additional recurring gameplay hooks were added.
- Real dice continuations use gold outward rays with a short mechanical click.
  Wizard Feedback uses inward cyan brackets and its electrical sound. Level-up
  keeps its larger gold celebration and longer confirmation cadence. Status,
  resistance, danger/life and objective labels retain their distinct meanings.

## Validation and limits

Baseline Checkpoint G: **27/27 PASS**. Final gate results are supplied with the
pushed SHA in the courier handoff. Required gate: `git diff --check`, all Lua
syntax through `tools/run_lua54.py`, and `tools/test_checkpoint_g_integration.py`.

The existing focused tests now exercise real Blast/Beam production casts and
blocking trace endpoint, two-body ordering, actual FX receiver/renderer,
caster identity, skybox/depth exclusion and the effect cap. The prior test merely
constructed packets itself. Added semantic identity, 128-die text preservation,
UTF-8 wrapping, duplicate delivery, history span parity, stale-notice expiry and
cancelled/asynchronous Spellbook checks. Existing gameplay regressions remain.

**No Source runtime acceptance is claimed.** Engine font fallback, material
appearance, world occlusion, actual sound mix and Steam Deck readability require
the focused human test. Restart both client and server realms after installation:
DIE-LOGGER spans and Magic-FX caster identity changed their wire formats.

This pass preserves accepted mechanics, costs, RNG, saves, XP, Soldier admission,
rankings, maze generation and encounter balance. The live GDD's newer requirements
for an exhaustive canonical RPGEventRecord stream, the four-tab Player Menu with
portable booklet, starting-stat/class-core changes, and final manual reconciliation
are not claimed implemented by this bounded presentation pass. UI names follow the
explicit current instruction **DIE-LOGGER**, superseding older names in the GDD.

Live GDD consulted: `00 — AI ENTRYPOINT`, `01 — AI RULE INDEX`,
`03 — COMBAT, MAGIC & STATUS`, `06 — MULTIPLAYER, LIFECYCLE & UI`;
Doc ID `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.

## Focused runtime acceptance

1. Fresh `gm_flatgrass`: P → I → L (also with mouse buttons), close immediately
   after requesting I, then reopen. Check exclusive focus, paper styling, locked
   entries, selected labels and complete readable party names on the world board.
2. Cast available Blast/Beam in first person. Beam should remain blue/cyan with
   different Contents and terminate at blocking geometry; Blast must be legible
   from inside its pulse. Its pulse is not a promise of circular damage range.
3. Fight and inspect L: independent dice/continuations, Steam/character identity
   colors and exact live/history wording. Exercise a long chain, status/resistance,
   progression and a life/Soldier transition as available. A revived player should
   not receive a stale eliminated banner afterward. Check history after restarting.

Use `lod_rpg_test_mark HYBRID_REALIGNMENT` before testing and
`lod_rpg_test_finish HYBRID_REALIGNMENT; lod_rpg_test_upload_status` afterward.
Return the standard console, summary and session evidence; include one screenshot
of any layout failure. Do not promote or deploy based on headless results alone.
