# Bestiary B16 — movement-discipline validation

Base: verified remote `5f817c2eb3e99a14156fd3d783359a998d4f5fbb`.
Scope: Halter/Pacer, canonical movement/combat/production/presentation, manual,
live GDD and coordination records. Frozen baseline18; implemented57/63,
39/45 additions,6 remaining. No VPS deployment or Workshop publication.

## Fresh integrated gate

Command: `python3 tools/test_checkpoint_g_integration.py`.
**All197 suites pass with zero failures in one fresh canonical run.**
The run followed final gameplay/config/test repairs; no gameplay/config/test
edits followed. Full matrix: [integration output](BESTIARY_B16_INTEGRATION.txt).

Includes all prior Bestiary cohorts, canonical movement/Dodge/combat/status/
defenses, actor registry57 normal+4 named bosses, syntax/release wiring, manual
source/reader/transport, bosses/finale/succession/Abundance and Level21 cash.
Inherited results are not substituted for the fresh run.

## Focused coverage

| Suite | Observable proof |
| --- | --- |
| `test_bestiary_b16.lua` | Real AI Tick/shared Think and canonical FinishMove/DodgeMovement; class-relative threshold, preparation grace, every final-window observation (including inter-service/same-time violation), one physical packet or harmless obedience; exact source/Hero/status/progression/run/graph/campaign lifetimes; forced/nonwalk/stale/unknown/Held/cloak/morale/cover/range/support/actual hull failure; fixed deadline/recovery and missed coverage; exclusive per-Hero token, cap16, stale-owner release; real native packet/GM mitigation/HP boundary, failed final authorization, replay/reentry, life/geometry changes, preserving newer attacks/activity/tokens and finite callback-error retirement. Four focused PASS markers. |
| `test_bestiary_b16_production.lua` | Real canonical class/usable feats/HP/XP and seeded replay; append ordinals54/55; actual spawn/variance/progression/cap/idempotence; singleton templates and companion enrichment; safe/objective/transition/native-hull/lateral exclusion; same-body fallback; prior mixed ordinals. |
| `test_bestiary_b16_visual.lua` | Actual ENT:Draw against render/network doubles; server-snapshot tether, literal STOP/KEEP MOVING, distinct pause/chevron glyphs, PREPARE/JUDGMENT/countdown/final-quarter cue, full/reduced semantic parity, bounded expiry/range/drift/nonfinite/lifecycle checks and conservative500 bounds. |
| `test_encounter_distribution.lua` | Unchanged512-plan/32-maze/parties1–4/dungeons1–5 sample:4939 encounters, all48 sampled identities pass25planned/20legal/5early. Halter30/28/5, Pacer33/33/6. |

[Exposure record](BESTIARY_B16_EXPOSURE.md) retains all four trials, three failures,
exact ordered ticket changes and full per-identity counts. No threshold/sample/
seed/geometry/ceiling/companion relaxation. Production sample acceptance does not
establish complete campaign exposure; the campaign-aware director remains due.

## Review and repairs

The shared roster remains the sole commitment/service/damage owner. Canonical
FinishMove emits one bounded demand observation after the existing Dodge motion
qualifications; latest-only polling was rejected because intervening violations
could be overwritten. Forced-state samples cannot become valid just after force
expiry. Final judgment requires≥0.3s sample span, no gap>0.15s and last age<=0.1s;
missing coverage fails closed. Physical source Held/Muted are permitted; source
morale and attack prohibitions cancel. Solo options are checked with actual Hero
hulls and current supported legal same-cell positions.

The existing B15 native packet guard now admits generic exact-life roster packets
without adding a faction permit. Failed final authorization cannot become an
unregistered packet. It checks packet target/attacker/inflictor and one admission
around real GM mitigation; the commitment checks current life, support/hull and
ownership before native HP. Reentrant/throwing callbacks cannot repeat a verdict,
transfer it to a replacement, erase a new reservation or extend recovery. Cancel
clears ownership before replication; Finish does not overwrite a newer activity
created inside a Stop callback. B15's focused regression also passes unchanged.

Manual160 chapters/32 chunks is regenerated from canonical source, preserving
prior content. Source SHA256:
`be85f17641bc6b089654c639726bb20072b98e12937e3b803b028f94ee020a1c`.

## Live design and coordination

Live GDD00→01→03/05/07 governed work; B16 design/tuning was authored and read back
before implementation, then evidence/current continuation was updated and
read-back verified in00/01/03/05/07. Rule `LOD-BESTIARY-B16-001`.
Final revision:
`ANLCKQnTTQ7-Qej2o6EXFmgEEFTWlihiv41UNTVQoikwG2doNG3DlTQEKYQexiwLs3PW3TepQIgvyJiIWTU0MbbJf2BVWg4jCyXXRuRdsA`.
Ledger, active plan and B17 handoff preserve frozen target63 and ordered phases.

## Native checks still pending

Boundary doubles are **not Source observation or acceptance**. After ordered
phases/audits, test gm_flatgrass real STOP/GO timing, force/Held/slow/crouch,
actual support/hulls/gates/Walls/false floors, labels/tether visibility and
full/reduced audio/rendering, companion-pressure balance, Block/Dodge/HP/XP/drops,
1–4-player network timing, late join/death/revival/disconnect/freeze/reset/same-seed
rebuild. Preserve earlier cohorts and complete Gordon→Hector→Deborah/sole staging
successor/Abundance/Level21 regression checks. Evidence console_latest.txt plus
rpg_summary_latest.txt; session log only for event ordering. No pre-sequence
human test or deployment gate is introduced. Next bounded checkpoint: B17 only,
next coherent pair, target59/63 only after meaningful production validation.
