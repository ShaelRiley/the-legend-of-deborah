# Bestiary B18 — prison-edict validation

Base: verified remote `4b4c730a5d813ca3b8c6f6e877c0dc1192fe63dd`.
Scope: Censor/Surveyor, canonical behavior/production/presentation/manual,
live GDD and coordination records. Frozen baseline18; implemented61/63,
43/45 additions,2 remaining. No VPS deployment or Workshop publication.

## Fresh integrated gate

Command: `python3 tools/test_checkpoint_g_integration.py`.
One fresh canonical integration run passed **all203 suites with zero failures**
after final repairs; no gameplay/config/test edits followed. Full matrix:
[BESTIARY_B18_INTEGRATION.txt](BESTIARY_B18_INTEGRATION.txt).
All prior cohort, actor registry61+4 named, combat/status/defense/HP/reward,
syntax/wiring, manual, equipment, bosses/finale/succession/Abundance/Level21
regressions passed. No inherited result is substituted for this fresh run.

## Focused coverage

| Suite | Observable proof |
| --- | --- |
| `test_bestiary_b18.lua` | Actual AI Tick/shared Think, canonical CommitAttack/Ace and deferred receipt, real faction/GM mitigation/HP boundary. Preparation/passive/old-life actions excluded; fresh full retaliation warning; terminal watch service grace without late admission; refuge/outer escape, real enlarged Hero hulls and support; physical Held/Muted versus Raw Muted/forced-motion rules; first body/world cover and frozen lane; four-way B16/B18 order exclusion, callback-safe preflight/cap/replication/retirement; exact source/Hero/progression/status/run/graph/campaign replacement; native post-defense position/life/authorization; replay/reentry/newer attack and fixed error recovery. |
| `test_bestiary_b18_production.lua` | Real generated classes/usable feats/HP/XP and deterministic replay; registry61+4 and ordinals58/59; canonical spawn/variance/idempotence/cap; singleton complementary templates/enrichment; safe/objective/transition/gate/hull/lateral and Surveyor refuge/outer-escape placement; same-body budget-safe fallback. |
| `test_bestiary_b18_visual.lua` | Actual ENT:Draw with renderer/network/clock doubles: frozen source/lane/displaced refuge, literal instructions/countdowns, full/reduced semantic parity, late-observer reconstruction, malformed/expired/dead/drifting/out-of-range rejection and532 bounds at maximum-range extrema. |
| `test_feedback_language.lua`, `test_wand.lua` | Actual Forms/Wand settlement paths defer the original attack observation until successful activation; unaffordable, refunded and failed native casts do not notify; ordinary Ace/charges/cost/cooldown behavior retained. |
| `test_encounter_distribution.lua` | Unchanged512-plan/32-maze/parties1–4/dungeons1–5 sample:4942 encounters; all52 sampled identities meet25planned/20legal/5early. Censor32/32/8; Surveyor30/30/6. |

[Exposure evidence](BESTIARY_B18_EXPOSURE.md) retains six trials, all five
failures, exact ordered in-place donor transfers and per-identity results.
No resampling, threshold relaxation or prior geometry weakening. This does not
replace the remaining whole-phase campaign-aware ecology/director gate.

## Review and repairs

Censor observes the existing attack-commit authority, without input spying or
passive/previous-projectile damage triggers. Forms/Wand can fail after sealing
Ace, so an optional original-order/life/time receipt is captured then discarded
on failure or observed only on success. New orders/lives cannot receive a stale
successful cast. Optional observer errors cannot abort the Hero's accepted
attack. Reentry and a second notification cannot duplicate retaliation.

A timely attack immediately before watchEnd formerly risked being lost on the
next service tick. The watch cutoff remains2.4s; a separate0.2s processing grace
permits that receipt while rejecting later attacks. Every triggered shot still
receives its full1.2s warning. Actual source/target callbacks cannot erase newer
attacks or extend fixed recovery. Shared B16 admission repeats its token/cap
checks after geometry so native preflight cannot steal an intervening B18 order.

Surveyor's refuge is displaced from the threatened disc, with both actual
Hero-hull refuge access and opposite outer escape required. The current Hero
route and frozen mark support are rechecked; unsupported/forced/involuntary
position judgments fail closed. No private HP/resource/status/reward owner,
new body, faction exception or hidden homing was introduced.

## Manual and live design

Canonical manual regenerated:162 chapters/32chunks. Source SHA256:
`ea838aeb37d784ad14d74f5120e61a4373f3d7df3cdfc177861f735a145877db`.
The supplied Bestiary attachment matches the retained repository brief byte-for-byte.
Live GDD00→01→03/05/07 governed work. B18 design/tuning was authored and verified
before implementation; subsequent boundary refinements, evidence and B19
continuation were read-back verified across all five tabs. Final revision:
`ANLCKQne0matikIKl8JD0o445k7_rZli24BmaQgCbbrB27tMQBhkV8x_tfH6h9qYcICsSlu3OleGuwGDFgRPa3a7O0dHxawtu8R41sai2g`.
Ledger, active plan and B19 handoff preserve frozen target63 and ordered phases.

## Native checks still pending

Boundary doubles are **not Source observation or acceptance**. After the ordered
phases/audits, use gm_flatgrass for actual attack/watch/retaliation timing,
failed casts, body/world interception, refuge/support/scaled hulls/gates/Walls/
false floors, Raw/physical defenses and HP/XP/drops, full/reduced tells/audio,
death/revival/disconnect/late join/freeze/reset/same-seed rebuild and1–4-player
network/balance. Preserve prior cohorts and complete Gordon→Hector→Deborah,
sole staging successor, Abundance and Level21 cash. Evidence:
console_latest.txt+rpg_summary_latest.txt; session log only for event order.
No pre-sequence human/deployment gate. Next B19: final meaningful pair; target63/63
only after production gates. Campaign-aware ecology still remains within Bestiary.
