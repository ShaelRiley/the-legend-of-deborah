# Bestiary B18 — measured production exposure

The unchanged sample uses512 plans from32 generated mazes, parties1–4 and dungeons1–5. Gates remain25 planned,20 legal and5 early per sampled identity. Six trials ran: five failed and the sixth passed all52 identities. Final4942 encounters; Censor32/32/8 and Surveyor30/30/6. No seeds, sample length, earlier placement rules, threat/hostile ceilings, companion enrichment or pass thresholds changed.

B18 appends ordinals58/59 to the existing production spawn order and adds singleton Censor+Shambler and Surveyor+Soldier templates in sector2+ arena/ambush pools. Both require safe/objective/transition exclusion, a legal same-floor exit, clear spawn hull and two100-unit lateral pockets. Surveyor additionally requires a96-unit refuge route and160-unit opposite escape route in at least one orientation. Actual Hero hull/support/route and frozen144/48-radius zone checks remain runtime commitment gates; this headless sample does not observe Source collision.

## Exact trial changes

Trial1 appends four alternating tickets each for `censor_detail` and `surveyor_detail`, after all unchanged B17 ticket appends and transfers. Trials2–6 replace existing donor tickets in place, retaining every pool length and unaffected ticket position after trial1. In every trial, sector2 scans forward and sector3+ scans backward. Rows execute in table order within each scope. Counts below are the complete per-trial transfer settings, not increments; zero means the row is absent. Final read-only ticket instrumentation verified every requested count exists in both arena/ambush pools. Donors came from measured surplus; final counts retain all gates.

| Scope | Donor → recipient | Trial2 | Trial3 | Trial4 | Trial5 | Trial6 |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| sector2 | `arccaster_zone` → `censor_detail` | 3 | 6 | 6 | 6 | 6 |
| sector2 | `repulsor_screen` → `surveyor_detail` | 3 | 6 | 6 | 6 | 6 |
| sector2 | `waylayer_cutoff` → `reeler_chase` | 2 | 5 | 5 | 5 | 5 |
| sector2 | `towline_detail` → `redliner_pressure` | 2 | 2 | 2 | 2 | 2 |
| sector2 | `fusilier_screen` → `interposer_detail` | 2 | 2 | 2 | 2 | 2 |
| sector2 | `towline_detail` → `reeler_chase` | 0 | 3 | 3 | 3 | 3 |
| sector2 | `towline_detail` → `censor_detail` | 0 | 0 | 4 | 4 | 4 |
| sector2 | `fusilier_screen` → `surveyor_detail` | 0 | 0 | 4 | 4 | 4 |
| sector2 | `waylayer_cutoff` → `surveyor_detail` | 0 | 0 | 0 | 3 | 6 |
| sector3+ | `arccaster_zone` → `gaoler_hold` | 3 | 3 | 3 | 3 | 3 |
| sector3+ | `repulsor_screen` → `surveyor_detail` | 4 | 7 | 7 | 7 | 7 |
| sector3+ | `listener_detail` → `censor_detail` | 3 | 3 | 3 | 3 | 3 |
| sector3+ | `fusilier_screen` → `shy_pressure` | 2 | 2 | 2 | 2 | 2 |
| sector3+ | `conductor_pressure` → `siphoner_pressure` | 2 | 2 | 2 | 2 | 2 |
| sector3+ | `wirewright_chase` → `bombardier_pressure` | 1 | 1 | 1 | 1 | 1 |
| sector3+ | `repriser_detail` → `pacer_chase` | 2 | 3 | 3 | 3 | 3 |
| sector3+ | `screenwright_detail` → `mourner_detail` | 2 | 2 | 2 | 2 | 2 |
| sector3+ | `pincer_detail` → `carrion_feast` | 1 | 1 | 1 | 1 | 1 |
| sector3+ | `harrier_screen` → `silencer_screen` | 2 | 2 | 2 | 2 | 2 |
| sector3+ | `snarer_detail` → `repulsor_screen` | 0 | 0 | 3 | 3 | 3 |

## Trial outcomes

- Trial1: 4945 encounters; failed — `gaoler` 16/16/8, `silencer` 22/22/10, `redliner` 36/34/4, `reeler` 26/25/2, `carrion` 24/23/8, `shy` 21/19/6, `siphoner` 21/20/9, `bombardier` 23/22/9, `pacer` 23/21/6, `interposer` 34/32/4, `mourner` 23/23/5, `censor` 18/18/0, `surveyor` 10/10/1.
- Trial2: 4945 encounters; failed — `reeler` 26/25/2, `pacer` 24/22/6, `censor` 26/26/2, `surveyor` 17/17/2.
- Trial3: 4945 encounters; failed — `repulsor` 20/20/10, `censor` 26/26/2, `surveyor` 26/26/2.
- Trial4: 4943 encounters; failed — `surveyor` 27/27/3.
- Trial5: 4943 encounters; failed — `surveyor` 28/28/4.
- Trial6: 4942 encounters; passed all52 identities.

The first attempt at the distribution fixture stopped before sampling because the generic simple-attack test included the new specialized `edict` family while `BeginEdict` was still being implemented. Its existing specialized-family exclusion was extended to `edict`; all B18 behavior is covered by dedicated suites. That pre-sample harness failure is not a seventh exposure sample.

## Complete measured counts

Every cell is planned/legal/early. All failed evidence is retained, including deficits in prior identities. Fixed sample inputs can yield slightly different encounter totals because budget-fitting template choices and companions differ.

| Identity | Trial1 | Trial2 | Trial3 | Trial4 | Trial5 | Trial6 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `climber` | 106/94/94 | 106/94/94 | 106/94/94 | 106/94/94 | 106/94/94 | 106/94/94 |
| `razor` | 250/250/62 | 248/248/62 | 244/244/62 | 246/246/62 | 246/246/62 | 246/246/62 |
| `lurker` | 201/190/96 | 199/188/94 | 199/188/94 | 201/190/94 | 201/190/94 | 201/190/94 |
| `beamsweeper` | 111/108/37 | 110/107/37 | 110/107/37 | 110/107/37 | 110/107/37 | 110/107/37 |
| `flamer` | 126/123/102 | 126/123/102 | 126/123/102 | 126/123/102 | 126/123/102 | 126/123/102 |
| `arccaster` | 60/60/16 | 40/40/14 | 40/40/14 | 40/40/14 | 40/40/14 | 40/40/14 |
| `sentry` | 149/144/71 | 149/144/71 | 149/144/71 | 152/147/71 | 152/147/71 | 152/147/71 |
| `bigcrab` | 216/214/116 | 216/214/116 | 218/216/116 | 220/218/116 | 220/218/116 | 218/216/116 |
| `nodule` | 177/165/86 | 175/163/86 | 174/162/86 | 175/163/87 | 175/163/87 | 174/162/86 |
| `gaoler` | 16/16/8 | 34/34/10 | 34/34/10 | 34/34/10 | 34/34/10 | 34/34/10 |
| `silencer` | 22/22/10 | 32/32/10 | 32/32/10 | 30/30/10 | 30/30/10 | 30/30/10 |
| `repulsor` | 50/50/12 | 38/38/10 | 20/20/10 | 36/36/10 | 36/36/10 | 36/36/10 |
| `stitcher` | 36/36/7 | 37/37/7 | 37/37/7 | 37/37/7 | 37/37/7 | 36/36/7 |
| `bulwark` | 28/28/12 | 28/28/12 | 28/28/12 | 28/28/12 | 28/28/12 | 27/27/12 |
| `cantor` | 34/33/7 | 33/32/7 | 33/32/7 | 33/32/7 | 33/32/7 | 34/33/7 |
| `pincer` | 35/35/9 | 34/34/9 | 34/34/9 | 34/34/9 | 34/34/9 | 34/34/9 |
| `harrier` | 35/35/10 | 29/29/10 | 29/29/10 | 29/29/10 | 29/29/10 | 29/29/10 |
| `waylayer` | 44/38/16 | 43/37/16 | 41/35/14 | 41/35/14 | 40/34/13 | 37/32/11 |
| `pavise` | 27/26/13 | 27/26/13 | 27/26/13 | 27/26/13 | 27/26/13 | 27/26/13 |
| `repriser` | 41/40/10 | 40/39/10 | 36/35/10 | 36/35/10 | 36/35/10 | 36/35/10 |
| `redliner` | 36/34/4 | 39/37/6 | 39/37/6 | 39/37/6 | 39/37/6 | 39/37/6 |
| `caromer` | 33/33/9 | 33/33/9 | 33/33/9 | 32/32/8 | 32/32/8 | 31/31/8 |
| `reeler` | 26/25/2 | 26/25/2 | 30/29/6 | 28/27/6 | 28/27/6 | 28/27/6 |
| `forker` | 29/28/10 | 28/27/10 | 29/28/10 | 30/29/10 | 30/29/10 | 30/29/10 |
| `wirewright` | 41/40/13 | 38/37/13 | 38/37/13 | 38/37/13 | 38/37/13 | 38/37/13 |
| `snarer` | 44/44/12 | 46/46/12 | 46/46/12 | 37/37/12 | 37/37/12 | 36/36/12 |
| `cordon` | 25/22/8 | 26/23/8 | 26/23/8 | 25/23/8 | 25/23/8 | 25/23/8 |
| `reaper` | 31/31/6 | 30/30/5 | 29/29/5 | 30/30/5 | 30/30/5 | 31/31/5 |
| `drubber` | 26/26/10 | 26/26/10 | 25/25/10 | 25/25/10 | 25/25/10 | 25/25/10 |
| `fencer` | 36/34/7 | 37/35/7 | 37/35/7 | 37/35/7 | 37/35/7 | 37/35/7 |
| `afterburst` | 30/28/10 | 32/30/10 | 32/30/10 | 32/30/10 | 32/30/10 | 32/30/10 |
| `carrion` | 24/23/8 | 25/24/8 | 25/24/8 | 26/24/8 | 26/24/8 | 26/24/8 |
| `towline` | 40/40/17 | 39/39/15 | 37/37/13 | 32/32/8 | 32/32/8 | 32/32/8 |
| `screenwright` | 36/35/10 | 31/30/10 | 31/30/10 | 30/29/10 | 30/29/10 | 30/29/10 |
| `censer` | 25/23/10 | 25/23/10 | 25/23/10 | 25/23/10 | 25/23/10 | 25/23/10 |
| `trailmaker` | 35/35/13 | 35/35/13 | 36/36/13 | 36/36/13 | 36/36/13 | 36/36/13 |
| `listener` | 42/42/11 | 38/38/11 | 38/38/11 | 38/38/11 | 38/38/11 | 39/39/11 |
| `shy` | 21/19/6 | 27/25/6 | 27/25/6 | 27/25/6 | 27/25/6 | 27/26/6 |
| `absolver` | 38/38/7 | 39/39/7 | 38/38/7 | 36/36/7 | 36/36/7 | 36/36/7 |
| `exactor` | 28/27/8 | 28/27/8 | 28/27/8 | 28/27/8 | 28/27/8 | 28/27/8 |
| `outrider` | 38/38/10 | 39/39/10 | 39/39/10 | 39/39/10 | 39/39/10 | 39/39/10 |
| `conductor` | 39/37/12 | 32/31/12 | 32/31/12 | 32/31/12 | 32/31/12 | 32/31/12 |
| `siphoner` | 21/20/9 | 26/25/9 | 26/25/9 | 26/25/9 | 26/25/9 | 26/25/9 |
| `accumulator` | 26/26/5 | 25/25/5 | 25/25/5 | 26/26/5 | 26/26/5 | 26/26/5 |
| `fusilier` | 45/45/15 | 35/35/14 | 35/35/14 | 34/34/13 | 34/34/13 | 34/34/13 |
| `bombardier` | 23/22/9 | 26/25/9 | 27/26/9 | 27/26/9 | 27/26/9 | 27/26/9 |
| `halter` | 26/25/9 | 26/25/9 | 26/25/9 | 25/24/9 | 25/24/9 | 25/24/9 |
| `pacer` | 23/21/6 | 24/22/6 | 30/28/6 | 31/29/6 | 31/29/6 | 31/29/6 |
| `interposer` | 34/32/4 | 36/34/5 | 36/34/5 | 36/34/5 | 36/34/5 | 36/34/5 |
| `mourner` | 23/23/5 | 32/32/5 | 32/32/5 | 32/32/5 | 32/32/5 | 32/32/5 |
| `censor` | 18/18/0 | 26/26/2 | 26/26/2 | 32/32/8 | 32/32/8 | 32/32/8 |
| `surveyor` | 10/10/1 | 17/17/2 | 26/26/2 | 27/27/3 | 28/28/4 | 30/30/6 |

This bounded exposure repair does not replace the later whole-phase campaign-aware ecology/director work. Native collision, actual player counterplay, timing and network/balance remain pending Source checks.
