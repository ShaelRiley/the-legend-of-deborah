# Bestiary B15 — careless-fire interaction validation

Base: verified remote `b6cb650f32c40ed5bd4b04e2fcf3bd40f4d9945e`.
Scope: Fusilier + Bombardier, canonical combat/faction/production/presentation,
manual, live GDD and checkpoint records. Frozen baseline18; implemented55/63,
37/45 additions,8 remaining. No VPS deployment or Workshop publication.

## Fresh integrated gate

Command: `python3 tools/test_checkpoint_g_integration.py`.
Result: **all194 suites passed with zero failures in one fresh canonical run**.
The run followed all final gameplay/config/test repairs; no gameplay/config/test
edits followed it.
Full output: [integration matrix](BESTIARY_B15_INTEGRATION.txt).

The gate includes all prior Bestiary cohorts, ordinary combat/status/defenses,
progression registry55 normal+4 named bosses, Lua syntax, release wiring, manual
source/reader/transport, bosses/finale/succession/Abundance and Level21 cash.
Inherited passes are not substituted for this fresh run.

## Focused coverage

| Suite | Observable evidence |
| --- | --- |
| `test_bestiary_b15.lua` | Real AI Tick/shared Think; actual faction hook and GM combat/mitigation; first native body interception with excluded/replaced/new bodies absorbing harmlessly; frozen blast bait, individual/source cover, one shared roll and primary-death-independent admission; source/recipient/dungeon/campaign lifetimes, Held/Muted/morale/hit-stun, source drift/support/escape/actual and changed diagonal Hero hulls, deadlines/gaps/candidate and commitment caps; native roll/resolve/mitigation/damage callbacks, reentry/errors, fixed recovery, preserving newer attacks; exact packet target/attacker/inflictor and one GM admission; real entity OnKilled/deferred death/loot authorities, no fabricated Hero kill or contribution XP, prior earned contributions settle once. Six focused PASS markers. |
| `test_bestiary_b15_production.lua` | Two genuine production IDs; append-only52/53;32 seeded class/feat/HP generations/replays; physical capability eligibility; canonical progression/rewards; singleton templates and companion enrichment; actual spawner argument/order/idempotence, hostile caps, safe/objective/gate/transition/support-pocket admission and bounded fallback. |
| `test_bestiary_b15_visual.lua` | Real native ENT:Draw dispatch against render/network/trace doubles; frozen lane, one first-body/world clipping trace, semantic body brackets; radius72 blast with fragments/height; finite countdowns, full/reduced parity, malformed/range/drift/distance/death/expiry rejection, render bounds500, no particle/model/light proliferation. |
| `test_encounter_distribution.lua` | Unchanged512 plans/32 generated mazes/parties1–4/dungeons1–5,4947 encounters. All46 sampled identities pass25 planned/20 legal/5 early. Fusilier54/54/14; Bombardier32/32/8. |

## Measured selection and repairs

[Exposure evidence](BESTIARY_B15_EXPOSURE.md) preserves all23 measured trials,
including22 failures, exact per-trial changes, final donor transfers and full46
counts. Final B15 additions:262 broad sector2+ tickets and329 sector2-only,
including four initial tickets per new template. Prior tickets remain intact.
No seed/sample/threshold/geometry/ceiling/companion relaxation. Broad pool-length
changes repeatedly shifted other selections; measured margins were widened,
then eight broad and six early tickets were transferred in place from high-margin
B15 additions to deficient identities, preserving pool lengths and other indices.
That final transfer passed in one run; its exact ordered sequence is retained.
Whole-phase campaign-aware director ecology remains required. This sample does
not establish complete campaign exposure or native balance.

Focused review repaired diagonal Hero-hull underestimation and rechecks current
native hulls during warning geometry. Exact DamageInfo authorization is consumed
once by faction admission; a weak record validates actual target, attacker and
inflictor, claims one GM entry and rechecks after canonical mitigation/report
callbacks before native HP settlement. Source/recipient replacement, reentry or
an exception cannot transfer damage or leave a source pinned past its deadline.
Recovery is sealed at release so callback delay does not extend it. Simultaneous
blast admission preserves other recipients if the primary dies, but source-life
replacement still cancels remaining settlements. Ally hit reports go to the
captured Hero without changing enemy attribution. Ordinary XP/loot owners remain.

Generic roster fixtures skip this specialized admission just as earlier cohorts;
the dedicated suite exercises its actual AI/service. Historical B14 spawn-order
assertions now permit appended entries while preserving exact50/51 positions;
B15 asserts exact length53 and52/53 positions. Manual159 chapters/31 chunks is
rebuilt from the canonical source, retaining all prior player-facing content.

Live GDD00/01/03/05/07 `LOD-BESTIARY-B15-001` design, tuning, exact selection
adjustments, evidence and B16 continuation were read-back verified. Final revision:
`ANLCKQmK539PouEOIYVkjoBtKDBwfGQkGKE3H2fWUY_nBqE5B2wWo54uD6U5Ildqwgy28H5omG5rW34Y-9fO4lCHDjDQBsqpWux8aWiJYw`.
The ledger, active plan and B16 handoff retain frozen target63 and ordered phases.

## Native boundary

Native entities, collision traces, rendering/audio/network transport and actual
engine HP application remain boundary doubles. Real production Lua runs against
them; automated validation is not Source runtime observation or acceptance.
The final Lua mitigation seam rejects stale packets before the ordinary native
HP write; arbitrary engine-internal behavior still requires native observation.

After ordered phases/audits, test gm_flatgrass actual model/poses, first-body
interception, companion blast bait and real world/body cover; collision/escape/
support/gates/Walls/false floors; Block/Dodge/HP/XP/drop attribution; status/morale,
death/revival/disconnect/late join, freeze/reset/same-seed rebuild, full/reduced
warnings/audio and1–4-player networking/balance. Retain prior cohorts and complete
campaign/finale/succession/Abundance/Level21 regressions. Evidence
console_latest.txt+rpg_summary_latest.txt; session log only for event ordering.

Next B16: targeted choice/authorship of a coherent remaining-roster pair, bounded
implementation/production validation, target57/63 only when both qualify.
Eight additions and campaign-aware ecology remain before Big Loot and Events.
