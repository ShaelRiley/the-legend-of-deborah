# Bestiary B14 production exposure evidence

The unchanged deterministic sample covers 512 plans on 32 generated mazes, parties 1–4 and dungeons 1–5. Every retained sampled identity and both additions must meet 25 planned / 20 legal / 5 early (sector≤2 legal) appearances. Seeds, sample, thresholds, geometry and singleton/companion rules remain unchanged. Source collision and ceiling traces are doubles, not native acceptance.

Final: **PASS — 44 sampled identities, 512 plans, 4943 encounters.** Siphoner 45/43/9; Accumulator 46/42/9.

## Preserved trials

Triples mean planned/legal/early. Every failing identity is retained, including failures after the first assertion. All earlier B11–B13 tickets remain intact.

| Trial | Encounters | Failing identities |
|---|---:|---|
| 1 | 4943 | censer 31/31/4; trailmaker 24/24/4 |
| 2 | 4943 | cantor 24/24/6; shy 28/28/4; exactor 24/22/7; accumulator 37/36/4 |
| 3 | 4939 | harrier 25/24/4; accumulator 31/31/3 |
| 4 | 4939 | arccaster 24/24/6; pincer 24/23/5; waylayer 30/27/3; siphoner 27/25/4 |
| 5 | 4942 | arccaster 24/24/8; wirewright 24/24/9 |
| 6 | 4941 | arccaster 22/22/4 |
| 7 | 4933 | towline 18/18/4; exactor 24/24/12 |
| 8 | 4946 | forker 38/36/3; shy 24/23/6 |
| 9 | 4952 | gaoler 20/20/2; trailmaker 20/19/4 |
| 10 | 4938 | caromer 30/28/4; snarer 26/25/3; screenwright 30/28/4 |
| 11 | 4943 | **PASS: all44 identities** |

Trial 1 adds four tickets each for Siphoner Pressure and Accumulator Detail at sector≥2 arena/ambush, alongside retained specialist weights. Trial 2 adds one sector2-only Censer Advance and Trailmaker Chase ticket each. Trial 3 adds one sector2-only ticket each for Cantor Charge, Shy Pressure, Exactor Pressure and Accumulator Detail. An incomplete trial3 invocation ran during shared module edits and stopped before sampling because the generic fixture needed its resource-mode exclusion; it produced no exposure result.


| Trial | Added tickets before this trial (cumulative) |
|---|---|
|1|Four sector≥2 arena/ambush tickets each for Siphoner Pressure and Accumulator Detail.|
|2|Sector2: Censer+1, Trailmaker+1.|
|3|Sector2: Cantor+1, Shy+1, Exactor+1, Accumulator+1.|
|4|Sector2: Harrier+1, Accumulator+2.|
|5|Sector2: Arc Caster+1, Pincer+1, Waylayer+2, Siphoner+1.|
|6|Broad: Arc Caster+1, Wirewright+1.|
|7|Broad: Arc Caster+2.|
|8|Broad: Towline+2, Exactor+1.|
|9|Sector2: Forker+2, Shy+1.|
|10|Broad: gaoler_hold+2, afterburst_detail+1, trailmaker_chase+2, accumulator_detail+1. Sector2: gaoler_hold+2, afterburst_detail+1, trailmaker_chase+2, absolver_detail+1.|
|11|Broad: pincer_detail+1, repriser_detail+1, snarer_detail+1, cordon_screen+1, siphoner_pressure+1. Sector2: repriser_detail+1, caromer_screen+2, snarer_detail+2, screenwright_detail+2.|

After trial9, rotating deficits justified one coherent margin repair: every identity below30 planned or25 legal received one broad ticket (two below22 planned or20 legal); every identity below7 early received one sector2-only ticket (two below5). This fixed rule was applied for trials10 and11, stopping immediately at the first all-green result. No random-seed search, placement relaxation, companion change or acceptance-threshold reduction occurred.

## Exact B14 ticket additions

All counts are additions above the retained B13 selection list; broad applies only at sector≥2 arena/ambush, and early only at sector2 in those roles.

| Template | Broad +tickets | Sector2-only +tickets |
|---|---:|---:|
| absolver_detail | 0 | 1 |
| accumulator_detail | 5 | 3 |
| afterburst_detail | 1 | 1 |
| arccaster_zone | 3 | 1 |
| cantor_charge | 0 | 1 |
| caromer_screen | 0 | 2 |
| censer_advance | 0 | 1 |
| cordon_screen | 1 | 0 |
| exactor_pressure | 1 | 1 |
| forker_crossfire | 0 | 2 |
| gaoler_hold | 2 | 2 |
| harrier_screen | 0 | 1 |
| pincer_detail | 1 | 1 |
| repriser_detail | 1 | 1 |
| screenwright_detail | 0 | 2 |
| shy_pressure | 0 | 2 |
| siphoner_pressure | 5 | 1 |
| snarer_detail | 1 | 2 |
| towline_detail | 2 | 0 |
| trailmaker_chase | 2 | 3 |
| waylayer_cutoff | 0 | 2 |
| wirewright_chase | 1 | 0 |
| **Total** | **26** | **30** |

## Final full distribution

| Identity | Planned | Legal | Early |
|---|---:|---:|---:|
| climber | 124 | 114 | 96 |
| razor | 258 | 258 | 66 |
| lurker | 203 | 188 | 92 |
| beamsweeper | 113 | 111 | 45 |
| flamer | 148 | 146 | 110 |
| arccaster | 50 | 50 | 16 |
| sentry | 154 | 148 | 69 |
| bigcrab | 224 | 222 | 116 |
| nodule | 187 | 177 | 88 |
| gaoler | 70 | 68 | 22 |
| silencer | 44 | 44 | 8 |
| repulsor | 42 | 40 | 10 |
| stitcher | 29 | 28 | 6 |
| bulwark | 44 | 43 | 11 |
| cantor | 29 | 27 | 8 |
| pincer | 36 | 36 | 11 |
| harrier | 28 | 28 | 7 |
| waylayer | 42 | 37 | 12 |
| pavise | 26 | 26 | 7 |
| repriser | 51 | 50 | 12 |
| redliner | 28 | 27 | 5 |
| caromer | 35 | 34 | 12 |
| reeler | 28 | 27 | 7 |
| forker | 39 | 36 | 9 |
| wirewright | 34 | 34 | 6 |
| snarer | 52 | 50 | 14 |
| cordon | 33 | 31 | 11 |
| reaper | 25 | 25 | 11 |
| drubber | 46 | 46 | 10 |
| fencer | 31 | 30 | 7 |
| afterburst | 39 | 38 | 12 |
| carrion | 32 | 32 | 6 |
| towline | 45 | 43 | 7 |
| screenwright | 27 | 26 | 8 |
| censer | 32 | 32 | 13 |
| trailmaker | 35 | 35 | 14 |
| listener | 54 | 52 | 11 |
| shy | 40 | 40 | 17 |
| absolver | 33 | 32 | 16 |
| exactor | 38 | 38 | 12 |
| outrider | 39 | 39 | 16 |
| conductor | 36 | 36 | 10 |
| siphoner | 45 | 43 | 9 |
| accumulator | 46 | 42 | 9 |
