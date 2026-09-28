# Big Loot implementation and validation

Baseline main: `fc166870633db5f277165d9c33ae00d82feaa81a`.
Final gameplay/test commit: `4f9ec7928f4a44107066da3095937655db806941`. Later closeout changes are documentation/evidence only.
The author-promoted `docs/briefs/BIG_LOOT_UPDATE.md` governs this checkpoint.
The shell HTTPS push lacked credentials. Authenticated GitHub Git-data publication
preserves all four source trees exactly, with the final source tree
`fb74489f5e53c1b7c9bfe512cd6b90c46df8b4cd` matching local validated commit `bd8de23f36afbf39a23baad5b9a03c6105f5909e`.
The remote-equivalent commit above differs only in commit metadata/parent IDs.
Publication uses a nonforced update from the verified baseline; local validation
commits are retained on `big-loot-validated-local`.

## Implemented vocabulary and architecture

The production baseline contains **45** meaningful identities: seven wearable
bases, seven weapon bases, seven named innate wearables and 24 consumables/utilities.
The 60 reusable properties are counted separately. **113** individually authored
archetypes yield **158 (3.5111×; 251.11% growth)**. Each guarantees a globally unique
positive signature, affinity and drawback; names, colors, random permutations,
numeric magnitudes and rarity tiers do not inflate the count. See
[the catalog](../BIG_LOOT_CATALOG.md) and [ecology design](../BIG_LOOT_ECOLOGY.md).

The existing equipment generator, equipped-effect authorities and LootDirector
own the expansion. Motifs, recent item/family/slot/effect suppression, exposure,
resource/slot/class context and legal topology guide rewards. Optional treasure
survives assistance decay without new entities. Inventory pressure reduces new
gear and preserves useful resource opportunities. The native weapon pool includes
upgraded starters after final wrapper loading. Receipts prevent rerolls; existing
DFT, Damsel, chest and fusion records keep their ownership/value guarantees.

Native inventory restore cannot resurrect a sold or trashed final weapon copy.
Sell/fuse bag changes participate in the existing SQLite transaction, with exact
life/campaign/bag guards and rollback. No new currency, capacity or combat owner.
The manual now contains 167 chapters in 32 chunks with build examples and ecology
explanations, using the existing assets and UI.

## Quantitative campaign evidence

32 campaigns × 20 actual generated dungeons × 2 individualized owners; 640 graphs,
61,440 enemy opportunities and 18,931 equipment offers. Final production loot,
staging, firearm, decay and equipment wrappers execute in their release order.

| Measure | Ecology | History-disabled control |
| --- | ---: | ---: |
| Added archetypes observed | 113 / 113 | 113 / 113 |
| Mean per-owner campaign exposure | 106.515625 / 113 | — |
| Minimum per-owner campaign exposure | 100 / 113 | — |
| Immediate repeated identity rate | 0.0530% | 0.7314% |
| Adjacent-dungeon Jaccard overlap | 2.7225% | 4.2500% |
| Value P10 / P50 / P90 | 128 / 166 / 250 | 129 / 166 / 252 |
| Highest observed value, depths 1–20 | 609 | 609 |

Immediate repeats fall 92.75%; adjacent-level overlap falls 35.94%. All baseline
21 equipment definitions and 24 consumable/utility definitions also appear.
Least exposed addition: Held Breath, 42 offers. No thematic family exceeds the
35% dominance gate. Rarity counts are 10,377 / 6,618 / 1,763 / 173; highest tier
is 0.914%. The separate authored-catalog sweep generates 6,780 records, including
high-depth extremes; maximum value 1,867, with exact budget/value equality.

All 15,422 nonreward support nodes survive decoration unchanged. There are 2,449
optional reward nodes; every admitted placement avoids protected objectives,
bosses, encounter homes and other reward placements. No extra static nodes or
progression gate changes are introduced. All ten motifs occur 256 times each.
Phrases are 552 lean / 1,543 scavenge / 465 cache; every campaign includes all three.
All 640 owner-level offer comparisons differ; a complete identical campaign reset
replays exactly. No-drop rate is 14,964 / 61,440 (24.36%).

The sample keeps bags empty to isolate offered vocabulary and uses native
entity/trace/transport doubles. It does not measure human acquisition choices,
combat completion rates, real ammo consumption, native networking or subjective
balance. Separate full-bag tests cover 8,000 low-health opportunity draws.

## Full finite gate

**268/268 suites pass; 774 Lua syntax files.** All 264 inherited
suites remain, with four added Big Loot gates. Actual SQLite settlement/rollback,
DFT/token replay, Damsel gifts, deterministic fusion, same-family ammo, legacy
migration, pickup ownership, full-bag retry, consumed/trash finality, receipt
bounds/overflow, campaign reset/succession, manual/UI, combat/progression and
protected Bestiary/SPOT/Crate/lifecycle regressions pass.

```sh
python tools/test_checkpoint_g_integration.py --workers 4 --output ../big-loot-evidence
```

Frozen source digest before/after:
`f5267910bf3279db21ae408917c8d5d893f0b0dbb8c00aafd97862a9a2614632`.
No source changed during the gate. Gameplay and tools were checked against the
manifest again before this documentation closeout. Complete receipt:
[big_loot/matrix_receipt.json](big_loot/matrix_receipt.json).
Campaign summary: [big_loot/campaign_summary.json](big_loot/campaign_summary.json).
All gate logs/manifests and retained focused failures are archived in
[big_loot/automated_evidence.tar.gz](big_loot/automated_evidence.tar.gz), SHA256
`6fa199103e629e18d98c3309c6bef56c6bf965e4525ca5405b3f6e456ab7fe21`.

## Demonstrated failures repaired

- Baseline stale inventory capture recreated a discarded inactive revolver.
  Authoritative equipment-backed capture/restore now prevents resurrection.
- Real final wrapper order hid all twelve new pistol/crowbar archetypes from
  ordinary drops. The final shared pool now admits them, preserving weapon gates.
- Numeric-only phrase seed suffixes correlated first RNG draws: one campaign had
  80 ordinary phrases. A domain suffix restores lean/cache variation.
- Campaign seed 15838, dungeon 7, level seed 126835146 had only one preferred
  sector-3 reward cell for two rewards. Placement now tries canonical same-sector
  alternatives, then counts an optional omission if no legal space exists.
- Receipt overflow formerly retained passed spatial context. It now ignores all
  mutable context, and a changed-context replay regression passes.

Matrix attempt 01 has 25 passing suite records but no completion receipt and is
not counted as a full pass. Attempt 02 completes all 268 with unchanged source.
Early fixture setup/global collisions and direct invocation of SQLite-dependent
fixtures without their wrapper are not production defects; successful corrected
invocations and the final complete gate provide evidence.

## Live GDD write blocker

Live Doc: `1OSpgiWyiGmUCLFdq--WmCSZe6KQIr7_UTkQZklPV8lY`.
Read 00 → 01, targeted 90/05/06/07, with file-backed control-aware inspection.
Fresh reads confirm unchanged revision. Google Docs rejects edits with HTTP 400
`FAILED_PRECONDITION`, including revision-guarded batches, a single additive
paragraph and exact-tab text replacement. No live amendment succeeded; do not
claim the GDD is synchronized.

The exact seven-tab amendments, including all 113 authored rows, are preserved in
[big_loot/gdd_amendments.json](big_loot/gdd_amendments.json). Apply these as surgical
additions after document editing is available, using a fresh read and readback.
Do not replace the document, remove prior material or bypass access controls.
This remains an explicit incomplete delivery requirement.

## Native acceptance and deployment

Native GMod acceptance remains open. After updating the local install to the
verified published commit, restart GMod and use the existing `gm_flatgrass`
workflow. `lod_loot_ecology_status` reports the current director state;
`lod_big_loot_testkit measured_retreat` is an optional developer/admin diagnostic,
marks the run unranked and excludes its item from economy.

Verify item inspection/equip effects, a full bag then successful same-pickup retry,
sale/fusion, death and reconnect, and individualized co-op reward visibility.
Retain prior Soldier/Reckless, stairs, stomp/input, B28/B29, Crate and SPOT native
acceptance debt. Use `console_latest.txt` + `rpg_summary_latest.txt` and brief
observations; request the detailed session only for disputed event order.
No Workshop publication or VPS deployment occurred.
