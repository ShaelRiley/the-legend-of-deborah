# Integrated gameplay and presentation refresh — 2026-09-17

Repository: `ShaelRiley/the-legend-of-deborah`, branch `main`; baseline
`aeaa6b3e24a53b9578be35cae2238f916eebb9e0`.

Authority: the explicit 26-part author request, current implementation, and live
GDD `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY` via 00/01 followed by
03–07 and the equipment rules in 90. The request expressly changes cinematic,
magic, economy and presentation rules. No routine GDD edit, server deployment,
Workshop publication, external asset or required dependency is included.

## Implemented checkpoint

| Request | Changes |
|---|---|
| 1 | Seven-second demolition with shared corridor opening, close oblique, moving low side, reverse and rubble/sign shots; finite explosion/smoke rendering; GAME OVER / THE PRISON HAS COLLAPSED / PRESS E TO START A NEW GAME. Existing five-second manual lockout and 20-second automatic restart remain server-owned. |
| 2 | Brute chooses melee, preserved charge or a travelling Bio projectile by range, sight and cooldown. Finite windups, visible/audio telegraphs, cancellation and original owner attribution. |
| 3 | Removed pattern runtime, pattern textures and generator. Explicit protected/A/B material maps, native base-map retention, bounded material pool, independent deterministic tints, retained aura and visibly varied muzzle size/duration/spokes. Safe native fallback for unsuitable topology. |
| 4 | Earlier eligible roster templates; Arc Casters additionally enter ambush compositions; Stalker/Beam Sweeper re-aims between commitments and no longer permanently inherits a shortened acquisition range. Placement diagnostics and deterministic distribution gate. |
| 5 | Summon puff lives 0.7 seconds above the floor, without an emitter or timer. Shorter windup, release-time target lead, close contact attacks, solid-cover and height checks; expiry also runs while simulation is frozen. |
| 6–8 | First-class Cone catalog/progression/cost/casting/Content/FX integration; relative Beam/Blast/Missile tuning. Black Bomb with striped fuse/ember; shared finite explosion pressure shell supplements existing elemental spectacle and exact area outlines. |
| 9–10 | Trace-based wrapped teammate identity with logger colors. Nearby combat rolls/status outcomes are routed using the observer's Wisdom. Private resource/progression/awareness notices stay private; observers do not acknowledge the owner's feedback. |
| 11–12 | LoD generation sounds suppressed at the entity source during build; player volume is never modified. Hermit gift uses a quieter energy cue; reviewed existing recent adventure audio and retained it. |
| 13–14 | Second staging board opposite Heroes of Legend; $DEB plus canonical DFT Value, descending top ceil(population/2), positive accounts only. Debbie sells owned unequipped generated equipment or atomically consumes 2–8 records for one generated item. |
| 15–16 | Visible trash bin, direct disposal, protected-item guards, disposal/equip/stow audio, valid/invalid targets, authoritative result messages and acknowledgement flash; denied actions resync instead of leaving optimistic state. |
| 17–18 | Status portrait color/expression, onset cue and visual pulse, explicit status caption replacing the name. Deterministic enemy status tint/aura and aimed caption; existing authoritative application/clear events remain in the logger. |
| 19 | Haste toggle replay/throttle fix and actual desired movement-input scaling alongside caps; client prediction follows the server multiplier. Ownership, funding, removal and life binding remain canonical. |
| 20 | Magic area/beam/projectile/summon traces include generated solid floor slabs. Real open vertical sight lines remain legal; impact areas begin on the near side of struck cover. |
| 21–23 | Spellbook availability labels/colors include resource, cooldown, lock and status failures, using Quantum-adjusted costs. Equipment defaults to O, with a binder and console command. Sheet director groups relevant resolved build values, including actual CON regeneration and status proc families. |
| 24–26 | Shared catalog of 17 throwable bombs: Physical, RAW, six elements, nine statuses. Normal loot/slots, common area damage and save/immunity API. Healing Potions clear all negative conditions even at full HP. All ordinary advertised weapon status riders are exercised through the production status pipeline; Intimidated uses Morale. |

## Tuning and economy

- Cone: 3d6, 22 base Magic, 32-degree half-angle; base reach 480 plus canonical spatial scaling. Earth Content supplies Push; it is not an isolated special spell.
- Beam: 2d6 → 3d6, 20 → 18 Magic, 0.65-second recovery. Existing piercing line remains an immediate committed cast, not a new sustained/tick system.
- Blast: 45 → 30 Magic, unchanged 2d6 and connected-cell selection, now solid-cover constrained. Missile: 25 → 28 Magic, unchanged 3d6, travel, steering and radius.
- Brute: melee reach 115, warning 0.45 seconds, recovery 1.3 seconds. Ranged reach 1500, warning 0.9 seconds, recovery 3.5 seconds, speed 620, base damage 16 through the existing Bio damage path. Charge remains available at its existing range.
- Summon: warning 0.85 → 0.45 seconds, 0.12-second leading; damage unchanged. Reliability precedes damage inflation.
- Throwable bombs: 144-unit area, 2d6 plus the selected element/status and ordinary saves. Stink Bomb and Healing Potion drops remain available.
- Information range reuses the information-system progression: `max(1, WIS modifier)` maze cells.
- Sales use Equipment.Value directly. Fusion returns a valid existing-generator item within 85–100% of sacrificed value and refuses unsupported totals. No invented exchange rate or forged affix magnitudes.
- Free starting weapons and free DFT recreations are excluded from exchange, including old `initial:` records. SQLite failure leaves the original bag untouched; committed work swaps a prepared bag synchronously. Foreign IDs, repeated IDs, stale inputs and replayed ledger events are rejected.
- Rescue pool stays `100 × dungeon`. Junk sales add wallet balance, not lifetime rescue score or milestone tokens. Existing money has no newly introduced purchasing-power sink; reducing rescue rewards would penalize the objective without closing a minting exploit. Free-item minting is blocked at provenance instead.

## Validation

Baseline: all 104 existing suites passed before edits. Final command:

```
python3 tools/test_checkpoint_g_integration.py
```

Result: **107 suites passed, zero failures**, including full Lua syntax and Git
whitespace audits. The three new suites cover integrated gameplay, client state,
and encounter distribution. Existing tests were expanded for real SQLite
sell/fusion rollback, all weapon status riders, observer radius/packet privacy,
Brute selection and five-shot cinematic timing. Explicitly superseded six-form,
old tuning, pattern and camera assertions were updated; lifecycle assertions
were retained.

Distribution sample: **512 plans, 4,926 encounters**, 32 independently generated
solvable mazes, dungeon 1–5 and party 1–4. Planned/legal placements in the bounded
engine-clearance fixture: Climber 444/410; Razor (Manhack) 424/424; Lurker 208/192;
Beam Sweeper (Stalker) 261/248; Flamer 328/322; Arc Caster 210/206; Sentry 162/143;
Big Crab 242/236; Nodule 186/169. Every archetype also passes early-sector minimums.
This measures real templates, budgeting and placement policy, not native BSP
collision. An initial sample caught Arc Caster exclusion; that defect was repaired.
Planner BFS distances are checked against the existing path authority. The cache
is discarded at the end of each plan, so gate changes cannot leave stale routes.

Other finite checks cover solid-floor rejection versus an open shaft, Cone front/
side/rear selection, Bomb/Missile/throwable areas, funded Haste input and caps,
full-HP remedy cleanup, final derived values, finite puff lifetime, wrapped identity
behind a real trace boundary, and spell availability. Existing suites retain
inventory, multiplayer ownership, progression, restart and native resource guards.

## Native acceptance still required

This checkpoint is implemented and statically validated, **not runtime accepted**.
After updating/restarting the GMod server on `gm_flatgrass`:

1. Trigger timeout with two connected clients. Inspect all five compositions:
   maze fills each frame, corridor is clear, escalation/debris/smoke are readable,
   final rubble foreground and Flattywood background, seven-second timing, then
   manual and automatic restart. Repeat once from staging/spectator perspective.
2. Fight Brute and the newer roster. Check native animations, charge/melee contact,
   green travelling Bio telegraph, legal stairs, Stalker re-aim and Lurker ceiling
   clearance. `lod_encounter_distribution` reports accepted/rejected native placements.
3. Inspect first- and third-person procedural guns. `lod_weapon_regions` prints
   mounted material names and mapping. **Single-material/unknown meshes intentionally
   keep canonical surfaces; two tints require separable mapped gun materials.**
   Actual stock model mappings and perceptual tint/flash quality need native inspection.
4. In two-player combat, exercise all spell forms across a solid floor and an open
   stairwell; observe bomb area boundaries, remedy/ailment cleanup, nearby rolls,
   Haste prediction and summon contact/retirement.
5. In staging, sell/fuse different players' junk, observe the Stakeholders board,
   drag equipment between slots/bag/trash, reopen menus and reconnect. Verify a
   quiet build, normal subsequent audio, readable portrait/sheet/spellbook at the
   target resolution, and no lingering effects after a new campaign.

Use the usual `console_latest.txt` and `rpg_summary_latest.txt` evidence; screenshots
are useful for camera and material composition. No deployment is implied by this push.
