# Bestiary B19 — measured production exposure

The unchanged512-plan sample spans32 generated mazes, parties1–4 and dungeons1–5. Gates remain25 planned,20 legal and5 early per identity. Five trials ran: four failed, then trial5 passed all54 identities. Final4949 encounters; Relay34/34/6 and Lacemaker27/27/6. Seeds, sample length, earlier placement rules, encounter/hostile ceilings, companion enrichment and pass thresholds are unchanged.

B19 appends production ordinals60/61 and singleton Relay+Soldier and Lacemaker+Runner templates, sector2+ arena/ambush only. Both reject safe/objective/transition cells and require a clear native spawn hull, legal same-floor exit and two96-unit lateral routes. Exact-life allies, actual supported Hero hull/escape routes and visible finite link geometry remain runtime commitment gates; headless traces do not constitute native Source evidence.

## Exact trial changes

Trial1 appends four alternating `relay_detail`/`lacemaker_detail` tickets after every inherited B18 append/transfer. Trials2–5 replace existing donor tickets in place; pool lengths and unaffected positions remain fixed. Sector2 scans forward; sector3+ scans backward. Rows execute in table order. Counts below are complete settings for each trial, not increments. Final read-only instrumented evaluation verified every requested transfer had sufficient tickets in all four relevant pools (sector2 arena836/ambush831; sector3+ arena471/ambush468).

| Scope | Donor → recipient | Trial2 | Trial3 | Trial4 | Trial5 |
| --- | --- | ---: | ---: | ---: | ---: |
| sector2 | `pavise_advance` → `relay_detail` | 6 | 10 | 14 | 17 |
| sector2 | `accumulator_detail` → `lacemaker_detail` | 6 | 6 | 6 | 6 |
| sector2 | `redliner_pressure` → `afterburst_detail` | 4 | 4 | 4 | 4 |
| sector2 | `reeler_chase` → `silencer_screen` | 2 | 5 | 5 | 5 |
| sector2 | `towline_detail` → `bombardier_pressure` | 2 | 2 | 2 | 2 |
| sector3+ | `accumulator_detail` → `relay_detail` | 5 | 5 | 5 | 5 |
| sector3+ | `carrion_feast` → `lacemaker_detail` | 5 | 5 | 5 | 5 |
| sector3+ | `censer_advance` → `snarer_detail` | 3 | 1 | 1 | 1 |
| sector3+ | `pavise_advance` → `screenwright_detail` | 3 | 3 | 3 | 3 |
| sector3+ | `bulwark_line` → `shy_pressure` | 3 | 3 | 3 | 3 |
| sector3+ | `stitcher_detail` → `exactor_pressure` | 2 | 2 | 2 | 2 |
| sector3+ | `outrider_detail` → `fusilier_screen` | 3 | 3 | 3 | 3 |
| sector3+ | `censer_advance` → `afterburst_detail` | 3 | 3 | 0 | 0 |
| sector3+ | `stitcher_detail` → `afterburst_detail` | 0 | 0 | 3 | 3 |
| sector3+ | `absolver_detail` → `repulsor_screen` | 2 | 2 | 2 | 2 |

## Trial outcomes

- Trial1: 4948 encounters; failed — `silencer` 37/37/4, `repulsor` 24/24/6, `snarer` 23/22/5, `afterburst` 18/16/3, `screenwright` 21/20/5, `shy` 21/20/5, `exactor` 23/21/8, `fusilier` 22/22/10, `bombardier` 27/25/4, `relay` 13/13/0, `lacemaker` 13/13/1.
- Trial2: 4949 encounters; failed — `silencer` 39/39/4, `censer` 19/19/9, `relay` 31/31/3.
- Trial3: 4949 encounters; failed — `censer` 23/23/9, `relay` 31/31/3.
- Trial4: 4949 encounters; failed — `relay` 32/32/4.
- Trial5: 4949 encounters; passed all54 identities.

## Complete measured counts

Every value is planned/legal/early. All failing evidence is retained. Fixed inputs can yield different encounter totals because templates have distinct budget costs and companions.

| Identity | Trial1 | Trial2 | Trial3 | Trial4 | Trial5 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `climber` | 110/98/94 | 110/98/94 | 110/98/94 | 110/98/94 | 110/98/94 |
| `razor` | 264/262/62 | 266/264/62 | 266/264/62 | 266/264/62 | 266/264/62 |
| `lurker` | 218/207/99 | 212/201/97 | 212/201/97 | 212/201/97 | 212/201/97 |
| `beamsweeper` | 104/103/34 | 104/102/35 | 102/100/35 | 102/100/35 | 102/100/35 |
| `flamer` | 123/119/102 | 128/124/102 | 128/124/102 | 128/124/102 | 128/124/102 |
| `arccaster` | 34/32/8 | 34/32/8 | 34/32/8 | 34/32/8 | 34/32/8 |
| `sentry` | 151/143/69 | 151/143/69 | 151/143/69 | 151/143/69 | 151/143/69 |
| `bigcrab` | 218/216/116 | 220/218/116 | 220/218/116 | 220/218/116 | 220/218/116 |
| `nodule` | 177/163/86 | 179/166/87 | 180/167/87 | 180/167/87 | 180/167/87 |
| `gaoler` | 30/30/8 | 30/30/8 | 30/30/8 | 30/30/8 | 30/30/8 |
| `silencer` | 37/37/4 | 39/39/4 | 39/39/6 | 39/39/6 | 39/39/6 |
| `repulsor` | 24/24/6 | 30/30/6 | 30/30/6 | 30/30/6 | 30/30/6 |
| `stitcher` | 42/42/8 | 38/38/8 | 38/38/8 | 30/30/8 | 30/30/8 |
| `bulwark` | 35/33/9 | 26/24/9 | 26/24/9 | 26/24/9 | 26/24/9 |
| `cantor` | 27/27/6 | 26/26/6 | 25/25/6 | 25/25/6 | 25/25/6 |
| `pincer` | 34/34/10 | 34/34/10 | 35/35/10 | 35/35/10 | 35/35/10 |
| `harrier` | 26/26/9 | 26/26/9 | 26/26/9 | 26/26/9 | 26/26/9 |
| `waylayer` | 32/30/9 | 33/31/9 | 33/31/9 | 33/31/9 | 33/31/9 |
| `pavise` | 42/42/18 | 31/31/15 | 31/31/15 | 30/30/14 | 28/28/12 |
| `repriser` | 27/27/11 | 26/26/11 | 26/26/11 | 26/26/11 | 26/26/11 |
| `redliner` | 40/40/8 | 38/38/6 | 38/38/6 | 38/38/6 | 38/38/6 |
| `caromer` | 27/27/9 | 26/26/9 | 26/26/9 | 26/26/9 | 26/26/9 |
| `reeler` | 37/35/14 | 36/34/14 | 33/31/11 | 33/31/11 | 33/31/11 |
| `forker` | 30/28/6 | 30/28/6 | 31/29/6 | 31/29/6 | 31/29/6 |
| `wirewright` | 36/35/12 | 36/35/12 | 36/35/12 | 36/35/12 | 36/35/12 |
| `snarer` | 23/22/5 | 36/35/5 | 28/27/5 | 28/27/5 | 28/27/5 |
| `cordon` | 33/31/13 | 33/31/13 | 34/32/13 | 34/32/13 | 34/32/13 |
| `reaper` | 34/34/9 | 35/35/9 | 35/35/9 | 35/35/9 | 35/35/9 |
| `drubber` | 32/32/12 | 32/32/12 | 32/32/12 | 32/32/12 | 32/32/12 |
| `fencer` | 26/25/9 | 26/25/9 | 26/25/9 | 26/25/9 | 26/25/9 |
| `afterburst` | 18/16/3 | 26/24/5 | 30/28/5 | 28/26/5 | 28/26/5 |
| `carrion` | 37/37/11 | 26/26/11 | 25/25/11 | 25/25/11 | 25/25/11 |
| `towline` | 32/30/12 | 29/27/9 | 29/27/9 | 29/27/9 | 29/27/9 |
| `screenwright` | 21/20/5 | 28/27/5 | 28/27/5 | 28/27/5 | 28/27/5 |
| `censer` | 39/39/9 | 19/19/9 | 23/23/9 | 33/33/9 | 33/33/9 |
| `trailmaker` | 28/28/11 | 28/28/11 | 28/28/11 | 28/28/11 | 28/28/11 |
| `listener` | 34/33/10 | 34/33/10 | 33/32/10 | 33/32/10 | 33/32/10 |
| `shy` | 21/20/5 | 29/28/5 | 29/28/5 | 29/28/5 | 29/28/5 |
| `absolver` | 34/34/14 | 33/33/14 | 33/33/14 | 33/33/14 | 33/33/14 |
| `exactor` | 23/21/8 | 28/26/8 | 28/26/8 | 28/26/8 | 28/26/8 |
| `outrider` | 36/36/10 | 27/27/10 | 27/27/10 | 27/27/10 | 27/27/10 |
| `conductor` | 33/33/8 | 33/33/8 | 33/33/8 | 33/33/8 | 33/33/8 |
| `siphoner` | 32/32/5 | 32/32/5 | 32/32/5 | 32/32/5 | 32/32/5 |
| `accumulator` | 49/48/19 | 31/30/16 | 33/32/16 | 33/32/16 | 33/32/16 |
| `fusilier` | 22/22/10 | 31/31/9 | 31/31/9 | 31/31/9 | 31/31/9 |
| `bombardier` | 27/25/4 | 30/28/7 | 30/28/7 | 30/28/7 | 30/28/7 |
| `halter` | 29/29/5 | 29/29/5 | 29/29/5 | 29/29/5 | 29/29/5 |
| `pacer` | 29/28/6 | 28/27/6 | 29/28/7 | 29/28/7 | 29/28/7 |
| `interposer` | 27/25/5 | 27/25/5 | 27/25/5 | 27/25/5 | 27/25/5 |
| `mourner` | 37/36/6 | 39/38/6 | 39/38/6 | 39/38/6 | 39/38/6 |
| `censor` | 29/26/6 | 28/25/6 | 28/25/6 | 28/25/6 | 28/25/6 |
| `surveyor` | 25/25/9 | 26/26/9 | 26/26/9 | 26/26/9 | 26/26/9 |
| `relay` | 13/13/0 | 31/31/3 | 31/31/3 | 32/32/4 | 34/34/6 |
| `lacemaker` | 13/13/1 | 27/27/6 | 27/27/6 | 27/27/6 | 27/27/6 |

These bounded ticket repairs do not replace the remaining whole-phase campaign-aware ecology/director work. Actual collision, timing, movement, player counterplay and1–4-player balance remain pending native Source checks.
