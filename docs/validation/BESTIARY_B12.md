# Bestiary B12 — condition interaction validation

Parent: `5c38f7dcdb062064d942967998c375460e593ee1`.
Live GDD03/05/07: `LOD-BESTIARY-B12-001`; entrypoint/index follow B13.
Absolver and Exactor complete49/63 normal identities; baseline18 unchanged.

## Finite gate and evidence

- `tools/test_bestiary_b12.lua`: real roster Tick/Think and canonical combat/
  status/Block; three ailments; lexical capture; refreshing the same entry vs
  expiry/remedy/reapplication; frozen geometry; isolated co-op target; real Hero
  escape hull despite SizeScale0.33 source; fixed service gap/deadline and
  recovery; max16; no extra control or bodies; ordinary life-bound fallback.
  Matrix covers source/Hero death, removal/disconnect, status-life/progression
  replacement, run/seed/graph/progression/campaign replacement, freeze/failure/
  clear, cover/support/height/cell changes, Held/Muted/morale/attack prohibition.
  Native callbacks cover reentry and source/target invalidation; zero/Block/
  lethal damage does not consume an ailment or replacement life.
- `tools/test_bestiary_b12_support.lua`: real Status and EnemySupport; one
  captured negative cure; beneficial preservation; no HP/revival/XP/currency;
  exact entry/life/run/floor/range/LOS/interruptions;31 invalidation paths;
  128-candidate bound and16-channel cap; actual nested competing Begin/Apply
  keeps the winning reservation; cancellation/clear callbacks cannot duplicate
  settlement, consume a replacement or use an invalid native actor for a cue.
- `tools/test_bestiary_b12_production.lua`:32 seeded actor generations/replays,
  usable class/feat capabilities, HP/XP once, real spawn/variance/ordinals,
  cap/retry/idempotence/budget fallback and ordinary room admission. Retained B11
  production, B2 support and canonical status matrix also pass targeted runs.
- `tools/test_bestiary_b12_visual.lua`: actual native Draw seam under render/
  NW2/clock doubles; full/reduced glyphs, tether/mark/countdown, fixed-position
  geometry, finite expiry without another packet, native render bounds,
  interruption/death/distance suppression and ordinary fallback presentation.
- Unchanged512-plan sample:4944 encounters,32 mazes, parties1–4/dungeons1–5;
  Absolver27 planned/25 legal/12 early; Exactor29/28/8. All forty sampled identities
  meet unchanged25/20/5. [Full failed and final trials](BESTIARY_B12_EXPOSURE.md).
- Canonical manual156 chapters/31 chunks. Lua syntax, release wiring, manual
  reader/transport and accepted combat/campaign regressions are in integration.

## Integrated result — preserve the failed assertion

One fresh `python3 tools/test_checkpoint_g_integration.py` run executed185 suites:
**184 passed; one failed**: Protected: Behavioral Regressions Gate.
Its sole failure was `archetype progression template count must be 51` in the
explicit `sv_rpg_validation.lua` registry, which had not yet listed B12's two
identities. Added `absolver` and `exactor` without weakening any assertion; the
expected registry now contains49 ordinary identities plus4 named bosses.

Fresh affected-suite rerun:
`python3 tools/run_lua54.py tools/test_checkpoint_g_protected_regressions.lua`
passed all six protected regression families and Overall RPG Subsystem Validation.
Final evidence is **185 suites covered and green across the integration run plus
this targeted rerun**, not a claim of one185-suite zero-failure run. No combat,
behavior, status, placement or presentation changes followed integration. Only
that explicit diagnostic registry and documentation changed. This bounded repair
requires no repeated broad run under the current compute policy.

Review failures repaired before integration: lethal-target cure before native
Alive updates; source-size hull substituted for Hero escape hull; another source's
reservation being retired after nested competing Apply. Regression tests retain
all three failures' observable cases. Failed sampling trials remain above.

## Native acceptance still outstanding

All native entity/collision/support/HP/render/network boundaries are doubled.
After the ordered phases, gm_flatgrass must establish: real condition application,
Absolver tether/cure and Muted interruption; Exactor circle/cure/escape/physical
Block/Dodge and Flamer combination; actual support/hull/gate/Wall/false-floor
interaction; death/revival/disconnect/late join; freeze/reset/same-seed rebuild;
full/reduced warning/audio clarity;1–4-player networking/balance/performance;
all B1–B11 and boss/finale/succession/Abundance/Level21 regressions.
Evidence: console_latest.txt+rpg_summary_latest.txt; session log only for ordering.
No deployment or Workshop publication. Static success is not Source acceptance.
