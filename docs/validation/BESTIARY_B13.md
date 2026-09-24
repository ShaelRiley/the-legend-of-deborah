# Bestiary B13 — party-spacing validation

Base: verified remote `998c99dcafbb96fd89fd0b73d0c1a6ad6b4cfb8a`.
Scope: Outrider + Conductor only, canonical ownership/presentation/production,
manual, live GDD and handoff. Frozen baseline18; implemented51/63,33/45 additions,
12 remaining. No VPS deployment or Workshop publication.

## Fresh integrated gate

Command: `python3 tools/test_checkpoint_g_integration.py`.
Result: **all188 suites passed with zero failures in one fresh canonical run**.
This run followed the final spent-link lifecycle repair, callback guards, manual
repair and final exposure tuning. No gameplay/config/test edits followed it.
Full output: [integration matrix](BESTIARY_B13_INTEGRATION.txt).

This includes all B1–B13 suites, ordinary combat/status/progression, explicit
progression registry (51 normal+4 named bosses), Lua syntax, release wiring,
manual source/reader/transport, bosses/finale/staging succession/Abundance and
Level21 cash. Earlier checkpoints' evidence is retained as historical evidence,
not substituted for this fresh result.

## Focused gates

| Suite | Observable coverage |
| --- | --- |
| `tools/test_bestiary_b13.lua` | Real outer AI Tick and shared Think service; canonical physical/Raw damage/mitigation; frozen wedge and marks; no early damage; solo escape/fallback; parties1–4; deterministic partner selection; regroup/separation/cover/concealment; exact source and both Hero life/progression/dungeon/campaign matrix before and at deadline; statuses/morale; source drift; support/actual Hero collision hulls/lateral escape; bounded caps32/16, retries/deadlines/recovery; callback reentry/replacement/death and no late-join transfer. Seven behavior groups pass. |
| `tools/test_bestiary_b13_production.lua` | 32 seeded generated actors/replays; actual class/feat/capability/growth/HP; physical vs Wizard Magic; shared level-scaled XP once; real production variance/spawn order/ordinals/ceiling/idempotence; singleton/complementary templates; safe/objective/transition/hull/exit/pocket rejection; budget-safe ordinary fallback. |
| `tools/test_bestiary_b13_visual.lua` | Actual client ENT Draw boundary under full/reduced effects; fixed paired circles/link/countdown or melee wedge/isolation glyph; frozen coordinates; fresh solo warning and countdown; finite expiry without new packets; invalid/NaN/unbounded data, death/cancel/cull; render bounds. |
| `tools/test_encounter_distribution.lua` | Unchanged512 deterministic plans,32 mazes, parties1–4/dungeons1–5;4945 encounters; all42 sampled identities retain25 planned/20 legal/5 early gates. Outrider49/48/11; Conductor39/38/8. |

Seventeen failed exposure trials, exact ticket deltas and the final complete
count table are preserved in [exposure evidence](BESTIARY_B13_EXPOSURE.md).
Measured systemic dilution required70 broad repair tickets plus six sector2-only
tickets beyond new-template base tickets and retained B12 tuning. The thresholds,
seed sample, eligibility, population ceiling and gameplay geometry were unchanged.
Campaign-aware ecology remains a later Bestiary obligation, not claimed here.

## Repairs verified before integration

- Initialize the complete solo fallback before native warning callbacks.
- Preserve a replacement commitment during warning/release/damage callbacks;
  never emit a stale projectile or finish a newer attack.
- Retire a spent Conductor link after source-life replacement, preventing a
  valid entity from remaining stationary forever behind an already-released flag.
- Validate both paired recipients before damage; a lethal first hit alone does
  not suppress the already admitted second. Actual source/recipient replacement
  still blocks stale damage. Only the warned Hero can take a solo bolt hit.
- Draw the fresh solo warning from readiness while charging, not a nonexistent
  or stale release timestamp.
- Fix B11/B12 manual source `table` keys to the builder's `rows` contract, restoring
  omitted enemy descriptions. Regression assertions check rendered prose.
  B13 adds the party-spacing chapter;157 chapters/31 chunks, canonical bytes and
  offline reader/transport pass.

Live GDD00/01/03/05/07 `LOD-BESTIARY-B13-001` records design, tuning, production,
final automated evidence and B14 continuation; targeted readback verifies edits.
The ledger, active plan and next-development handoff preserve the ordered phases.

## Native boundary and remaining acceptance

Native entities, collision/physics, audio, rendering, damage delivery and network
transport are doubled. Production game logic runs against those boundaries;
this is static/automated validation, not Source observation or acceptance.

After ordered development/audits, test `gm_flatgrass`: actual antlion/Vortigaunt
poses, semantic warnings and audio in full/reduced effects; regroup/separate/solo
counterplay; support/collision/escape/gates/Walls/false floors; physical Block/
Dodge and Raw Magic/Arcane Shield; Held/Muted/morale; interruption, death/revival/
disconnect/late join; freeze/reset/same-seed rebuild; actual HP/XP/drops and
1–4-player networking/balance. Retain prior cohort/boss/finale/succession/Abundance/
endless-cash checks. Evidence `console_latest.txt` + `rpg_summary_latest.txt`;
request the session log only for event ordering.

Next: B14 resource-pressure proposals only; reconcile canonical resources before
authoring. Whole Bestiary roster breadth and campaign-aware director ecology
remain prerequisites to Big Loot and Events.
