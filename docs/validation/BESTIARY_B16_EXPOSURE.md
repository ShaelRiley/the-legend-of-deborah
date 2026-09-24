# Bestiary B16 — measured production exposure

The unchanged sample uses512 plans from32 generated mazes, parties1–4 and dungeons1–5. Gates remain25 planned,20 legal and5 early per sampled identity. Four trials were run; the first three failed and the fourth passed all48 identities. Final4939 encounters; Halter30/28/5, Pacer33/33/6. No seeds, sample length, placement rules, threat/hostile ceilings, companion enrichment or pass thresholds changed. The canonical integration run subsequently repeated this same passing sample.

## Exact trial changes

Trial1 appends four alternating tickets each for `halter_detail` and `pacer_chase` in sector2+ arena/ambush pools. All subsequent changes replace existing source tickets in place, scanning backward. Pool lengths and unaffected ticket positions stay fixed after trial1.

| Scope | Donor → recipient | Trial2 count | Trial3 count | Trial4 count |
| --- | --- | ---: | ---: | ---: |
| sector2 | `silencer_screen` → `halter_detail` | 2 | 4 | 4 |
| sector2 | `carrion_feast` → `pacer_chase` | 2 | 4 | 5 |
| sector2 | `arccaster_zone` → `gaoler_hold` | 1 | 1 | 1 |
| sector2 | `censer_advance` → `screenwright_detail` | 1 | 3 | 3 |
| sector2 | `accumulator_detail` → `halter_detail` | 1 | 1 | 1 |
| sector2 | `absolver_detail` → `pacer_chase` | 1 | 1 | 1 |
| sector3+ | `bombardier_pressure` → `halter_detail` | 3 | 3 | 3 |
| sector3+ | `outrider_detail` → `pacer_chase` | 2 | 2 | 2 |
| sector3+ | `repriser_detail` → `gaoler_hold` | 2 | 2 | 2 |
| sector3+ | `fusilier_screen` → `listener_detail` | 2 | 4 | 4 |
| sector3+ | `forker_crossfire` → `snarer_detail` | 1 | 2 | 2 |
| sector3+ | `carrion_feast` → `halter_detail` | 1 | 1 | 1 |

Rows execute in the table order within each scope. Trial2 transfers8 early/11 later tickets, trial3 transfers14/14, trial4 transfers15/14. Donors were chosen from measured higher-exposure cohorts; every donor retains its gates. This bounded ticket repair does not replace the required whole-phase campaign-aware ecology redesign.

## Complete measured counts

Each cell is planned/legal/early. Failed evidence is retained, including deficits in prior identities.

| Identity | Trial1 | Trial2 | Trial3 | Trial4 |
| --- | ---: | ---: | ---: | ---: |
| `climber` | 108/96/94 | 108/96/94 | 108/96/94 | 108/96/94 |
| `razor` | 266/264/62 | 266/264/62 | 266/264/62 | 266/264/62 |
| `lurker` | 196/187/93 | 196/187/93 | 194/185/91 | 194/185/91 |
| `beamsweeper` | 102/101/35 | 102/101/35 | 103/102/35 | 103/102/35 |
| `flamer` | 122/120/107 | 122/120/107 | 122/120/107 | 122/120/107 |
| `arccaster` | 36/36/16 | 34/34/14 | 34/34/14 | 34/34/14 |
| `sentry` | 156/151/71 | 157/152/71 | 157/152/71 | 157/152/71 |
| `bigcrab` | 224/222/118 | 222/220/118 | 224/222/118 | 224/222/118 |
| `nodule` | 173/159/83 | 172/158/83 | 173/159/83 | 173/159/83 |
| `gaoler` | 18/16/4 | 28/26/6 | 28/26/6 | 28/26/6 |
| `silencer` | 47/47/24 | 44/44/22 | 40/40/18 | 40/40/18 |
| `repulsor` | 42/40/10 | 42/40/10 | 42/40/10 | 42/40/10 |
| `stitcher` | 38/34/10 | 38/34/10 | 38/34/10 | 38/34/10 |
| `bulwark` | 36/35/10 | 36/35/10 | 36/35/10 | 36/35/10 |
| `cantor` | 43/42/8 | 43/42/8 | 43/42/8 | 43/42/8 |
| `pincer` | 29/27/6 | 28/26/6 | 28/26/6 | 28/26/6 |
| `harrier` | 35/35/9 | 34/34/9 | 34/34/9 | 34/34/9 |
| `waylayer` | 38/32/7 | 38/32/7 | 38/32/7 | 38/32/7 |
| `pavise` | 38/37/12 | 37/36/12 | 39/38/12 | 39/38/12 |
| `repriser` | 50/47/8 | 46/44/8 | 44/42/8 | 44/42/8 |
| `redliner` | 31/30/8 | 30/29/8 | 30/29/8 | 30/29/8 |
| `caromer` | 35/35/11 | 35/35/11 | 35/35/11 | 35/35/11 |
| `reeler` | 35/34/14 | 35/34/14 | 35/34/14 | 35/34/14 |
| `forker` | 45/44/13 | 44/43/13 | 42/41/13 | 42/41/13 |
| `wirewright` | 41/40/11 | 41/40/11 | 40/39/11 | 40/39/11 |
| `snarer` | 23/23/11 | 24/24/11 | 26/26/11 | 26/26/11 |
| `cordon` | 34/32/6 | 34/32/6 | 35/33/6 | 35/33/6 |
| `reaper` | 38/38/8 | 38/38/8 | 38/38/8 | 38/38/8 |
| `drubber` | 30/30/11 | 29/29/11 | 29/29/11 | 29/29/11 |
| `fencer` | 40/37/8 | 41/38/8 | 42/39/9 | 42/39/9 |
| `afterburst` | 40/39/9 | 40/39/9 | 40/39/9 | 40/39/9 |
| `carrion` | 49/46/19 | 43/41/17 | 42/40/16 | 40/38/14 |
| `towline` | 34/32/9 | 34/32/9 | 35/33/9 | 35/33/9 |
| `screenwright` | 28/28/4 | 28/28/4 | 31/31/7 | 31/31/7 |
| `censer` | 35/34/15 | 36/35/15 | 32/31/12 | 32/31/12 |
| `trailmaker` | 41/40/9 | 41/40/9 | 41/40/9 | 41/40/9 |
| `listener` | 20/18/8 | 22/20/8 | 28/26/8 | 28/26/8 |
| `shy` | 25/24/9 | 25/24/9 | 25/24/9 | 25/24/9 |
| `absolver` | 35/34/15 | 35/34/15 | 35/34/15 | 35/34/15 |
| `exactor` | 26/26/13 | 26/26/13 | 26/26/13 | 26/26/13 |
| `outrider` | 48/48/10 | 37/37/10 | 37/37/10 | 37/37/10 |
| `conductor` | 28/28/7 | 28/28/7 | 27/27/7 | 27/27/7 |
| `siphoner` | 26/26/5 | 26/26/5 | 25/25/5 | 25/25/5 |
| `accumulator` | 45/45/14 | 43/43/12 | 43/43/12 | 43/43/12 |
| `fusilier` | 45/45/15 | 42/42/15 | 35/35/15 | 35/35/15 |
| `bombardier` | 50/49/11 | 42/42/11 | 42/42/11 | 42/42/11 |
| `halter` | 11/11/0 | 27/25/3 | 30/28/5 | 30/28/5 |
| `pacer` | 16/16/1 | 30/30/3 | 31/31/4 | 33/33/6 |

## Trial conclusions

- Trial1: DISTRIBUTION_SAMPLE plans=512 encounters=4939; deficits: gaoler 18/16/4, snarer 23/23/11, screenwright 28/28/4, listener 20/18/8, halter 11/11/0, pacer 16/16/1.
- Trial2: DISTRIBUTION_SAMPLE plans=512 encounters=4939; deficits: snarer 24/24/11, screenwright 28/28/4, listener 22/20/8, halter 27/25/3, pacer 30/30/3.
- Trial3: DISTRIBUTION_SAMPLE plans=512 encounters=4939; deficits: pacer 31/31/4.
- Trial4: DISTRIBUTION_SAMPLE plans=512 encounters=4939; deficits: none; all48 identities pass.

## Interpretation

This establishes bounded production exposure through actual planning and legal placement in the fixed sample. It is not full-campaign novelty/pacing proof, native Source observation, visual acceptance, real-network balance or low-end FPS evidence. Preserve the validated selection order; resample only after selection risk changes.
