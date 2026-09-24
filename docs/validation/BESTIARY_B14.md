# Bestiary B14 — resource-pressure validation

Base: verified remote `e8279b1bf904e9a3954436d50063da6a5533e4bf`.
Scope: Siphoner + Accumulator only, canonical resource/combat/progression,
production, presentation, manual, live GDD and handoff. Frozen baseline18;
implemented53/63,35/45 additions,10 remaining. No VPS or Workshop publication.

## Fresh integrated gate

Command: `python3 tools/test_checkpoint_g_integration.py`.
Result: **all191 suites passed with zero failures in one fresh canonical run**.
The run followed final source, capability, callback, Aura Burst, manual and
exposure repairs. No gameplay/config/test edits followed it.
Full output: [integration matrix](BESTIARY_B14_INTEGRATION.txt).

The gate includes prior B1–B13 suites, ordinary combat/status/progression,
explicit progression registry (53 normal+4 named bosses), Lua syntax, release
wiring, manual source/reader/transport, bosses/finale/succession/Abundance and
Level21 cash. Inherited results are not substituted for this fresh run.

## Focused gates

| Suite | Observable coverage |
| --- | --- |
| `tools/test_bestiary_b14.lua` | Real outer AI Tick/shared Think; canonical Magic pools, regeneration/map suppression and Raw damage/Arcane Shield; warning/escape; fractional/empty pools and positive-surviving-HP drain; cost/Quantum; self-channel and natural repeated cast/recharge cycle; no overdraw/duplicate/refund; Feedback Loop cap/full-Magic snapshot; real Aura Burst preparation/resolution/observer and explicit supplemental bystanders; no aura for drain/recharge; source/Hero/pool/run/graph/progression/campaign identity matrix before/deadline; Held/Muted/morale/hit-stun; support/actual Hero hull/gates/escape; parties1–4; native sync/damage/aura reentry, replacement and failure; cap16, finite recovery/deadline/service gaps. |
| `tools/test_bestiary_b14_production.lua` | Two stable production IDs, append-only ordinals50/51,32 seeded actor generations/replays, correct usable feat capabilities, templates/companions, singleton enrichment, placement exclusions, actual spawn argument/order, caps/fallback, canonical rewards and cleanup. |
| `tools/test_bestiary_b14_visual.lua` | Real native Draw dispatch with boundary doubles; semantic funnel/lightning/battery geometry and countdown, full/reduced parity, frozen position, render bounds, finite expiry without new packets, nonfinite/range/drift/death/cancel/distance rejection. |
| `tools/test_encounter_distribution.lua` | Unchanged512 plans/32 mazes/parties1–4/dungeons1–5;4943 encounters; all44 sampled identities retain25 planned/20 legal/5 early gates. Siphoner45/43/9; Accumulator46/42/9. |

[Exposure evidence](BESTIARY_B14_EXPOSURE.md) retains ten failed measured trials,
the passing eleventh, the incomplete fixture-stop invocation, full final counts
and exact26 broad+30 sector2-only ticket additions (including four initial tickets
per new template). No thresholds, seed sample, geometry, companion rules,
entity ceilings or existing tickets were relaxed. Later campaign-aware director
ecology is still required; this sample does not claim complete campaign coverage.

## Repairs and explicit integration decisions

- Pure-Magic templates explicitly exclude physical attack capabilities; only
  Accumulator's real paid attack admits Quantum/discrete-cast feats.
- Capture pool references alongside canonical actor-life/progression scopes;
  no replacement Hero resource state can inherit the drain.
- Debit once before sync; seal full-Magic bonus; claim damage/recharge/drain
  before callbacks. Preserve a replacing attack. Retire spent callback failure
  by the fixed deadline instead of leaving an actor permanently stationary.
- Real generated Aura Burst remains separate supplemental cast damage, including
  nearby unmarked Heroes. Manual and live GDD explicitly disclose that exception.
  No drain rider transfers to the aura; recharge/drain are never cast activations.
- Reuse canonical Feedback Loop restoration and Magic regeneration; no new pool
  or regeneration timer. Arcane Shield settles HP/Magic before the drain rider.
- Generic roster fixture skips specialized resource admission just as for prior
  cohorts; dedicated tests exercise actual AI and the shared service instead.
- Manual chapter uses canonical rows and regenerates158 chapters/31 chunks.

Live GDD00/01/03/05/07 `LOD-BESTIARY-B14-001` holds design, tuning, evidence and
B15 continuation; every added paragraph in03/05/07 and final00/01/07 evidence
was read-back verified. Final GDD revision:
`ANLCKQmoOhNsX8N2MbS4W7FyY7SIDJzY6JOXJMWBWBA0fnJCrPyHlM95qbGCzpyw9AmTYVHJGGKzFALzUfd0WhucT_7Oql9TY_nuA0sDKA`. The ledger,
active plan and handoff retain the ordered phases and frozen denominator.

## Native boundary

Native entities, collision/physics, audio, rendering, damage delivery and network
transport are doubles. Production logic runs against them; static automated
validation is not Source runtime observation or acceptance.

After ordered phases/audits, test `gm_flatgrass`: actual Stalker/Vortigaunt models,
poses, full/reduced semantic warnings and positional audio; frozen mark escape
and recharge denial; support/collision/escape/gates/Walls/false floors; actual
Magic meters, regeneration/utility consequences, Arcane Shield/Quantum/Feedback
Loop/Aura Burst; status/morale; interruption, death/revival/disconnect/late join;
freeze/reset/same-seed rebuild; HP/XP/drops and1–4-player networking/balance.
Retain prior cohorts and campaign/finale/succession/Abundance/Level21 checks.
Evidence `console_latest.txt`+`rpg_summary_latest.txt`; session log only for order.

Next B15: targeted selection/design of a coherent remaining-roster pair, then
bounded implementation/production validation; target55/63 only after both qualify.
Remaining roster breadth and campaign-aware ecology precede Big Loot and Events.
