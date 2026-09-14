# Adventure presentation candidate

Continues `49d398aaded72b50c02731e7033995f15590a4e6` on `hybrid/antigravity`.
Shael authorized a free presentation/production-value pass: whimsical Garry’s Mod
absurdity plus the wonder and discovery of early adventure games. Gameplay laws,
RNG, rewards, progression and the exact-SHA human acceptance gate are preserved.

## Changes

- Six original short musical motifs: discovery, unlocking, learning, leveling,
  feat confirmation and rescue. Synthesized from the checked-in score/generator;
  no sampled music, borrowed melodies, runtime synthesis or external audio service.
  Source-compatible mono 16-bit PCM at 22050 Hz; combined payload under 400 KiB.
- A small transient access-pass/container seal, opening-door glyph or spellbook
  flourish accompanies its actual successful event. Brief dry-humored captions
  provide personality without claiming extra gameplay effects. No persistent panel,
  camera/input lock, new gameplay particle entity or hidden-object detector.
- Keycards now visibly resemble physical access passes, with stripe, chip and
  printed letter. Gentle motion and depth-tested glints decorate already-rendered
  cards, keys and individualized loot. Existing PVS/ownership rules are preserved;
  there is no new entity scan, radar or through-wall outline.
- Rescue retains the balloons and Deborah’s “Fantastic!” with a short original
  fanfare, actual fleck confetti and spaced citizen voices instead of overlapping
  speech. Timed confetti/voice callbacks are invalidated by cleanup/replacement.
- Level-up retains its established timing/type hierarchy while losing its large
  opaque band/fullscreen wash. Feat confirmation now uses the correct display name.

## Shared event and performance contract

The existing `LOD_CombatRoll` packet carries a 4-bit presentation cue and 2-bit card
variant. The same record reaches live text and history. Success metadata comes from
the objective authority after a real transition, or existing successful loot/learn
observers; text is never parsed to infer success. Denials and duplicate packets do
not celebrate. No second event receiver or success authority was introduced.

One client accent controller arbitrates musical priority, with one active musical
voice and one transient visual. It uses seven fixed cooldown keys, six cached asset
checks and no polling timer. It resets on death/role notices and map cleanup. All
new assets are explicitly registered for client download by the server.

Cosmetic choices under Shael’s explicit presentation mandate: 0.65 default musical
accent volume; 0.65-second same-cue debounce (0.18 for feat confirmation); transient
ornaments last 1.4–2.1 seconds; glints cull at 900 units and obey depth; rescue emits
3×60 flecks, or 3×12 under reduced effects. These are presentation limits, not
mechanical timings, ranges or probabilities.

Client controls: `lod_adventure_volume 0..1` controls only the new musical accents;
`lod_reduced_effects 1` reduces optional motion, glints and confetti and disables
the celebration camera pullback. Ordinary gameplay sounds and event text remain.

## Validation and handoff

Complete Checkpoint-G gate: **52/52 suites**, including diff whitespace, project
Lua syntax, current 150-feat inventory with zero blank descriptions, original-audio
reproducibility/format/duration/headroom, event transport/history parity, duplicate
and denied-event isolation, client priority/mute/bounds, ornament renderer execution
with Source boundary fakes, and cleanup cancellation of rescue callbacks.

No Source-runtime audiovisual acceptance is claimed. Shael should install the new
exact SHA, fully restart GMod, and play normally on `gm_flatgrass`: collect a card,
open a gate, collect a weapon/cache, learn/choose something, and rescue Deborah.
Judge cue clarity, musical balance, frame pacing and HUD obstruction in combat;
compare reduced effects if desired. Existing RPG/feat/multiplayer tests still apply.
Finish/export the usual console and RPG summary logs.

No main promotion, public-server deployment or Workshop publication occurred.
The full RPG Update remains the release milestone; final manual reconciliation and
explicit human acceptance precede separately authorized live deployment.
