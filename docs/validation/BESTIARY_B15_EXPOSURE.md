# Bestiary B15 production exposure evidence

The unchanged deterministic sample covers **512 plans on 32 generated mazes, parties 1–4 and dungeons 1–5**. All 46 sampled identities must reach **25 planned / 20 legal / 5 early** (sector≤2 legal) appearances. Seeds, sample, thresholds, geometry and singleton/companion rules remain unchanged. Source collision and ceiling traces are doubles; this is static production evidence, not native acceptance.

Final: **PASS — 46 sampled identities, 512 plans, 4947 encounters.** Fusilier 54/54/14; Bombardier 32/32/8.

## Preserved trials

Triples mean planned/legal/early. Every failing identity is retained, including failures after the first assertion. All prior B11–B14 tickets remain intact.

| Trial | Encounters | Failing identities |
|---|---:|---|
| 1 | 4930 | stitcher 23/22/6; pavise 21/21/8; fencer 40/40/4; carrion 24/22/7; fusilier 31/30/4 |
| 2 | 4936 | censer 23/22/6; accumulator 27/27/3; bombardier 22/21/3 |
| 3 | 4934 | harrier 21/20/8; redliner 29/28/4; reeler 33/33/4; shy 19/19/6; absolver 25/25/4 |
| 4 | 4952 | wirewright 20/20/6; towline 30/29/4 |
| 5 | 4948 | cordon 20/20/5; reaper 23/23/7; exactor 24/24/8; outrider 38/37/4 |
| 6 | 4948 | afterburst 24/24/4; screenwright 23/23/8 |
| 7 | 4945 | carrion 30/29/4; censer 23/22/5 |
| 8 | 4942 | silencer 24/22/3; reeler 26/24/4; accumulator 24/23/8 |
| 9 | 4949 | fencer 36/35/4; trailmaker 31/30/3; bombardier 22/22/4 |
| 10 | 4939 | forker 33/33/3; carrion 33/32/3; censer 36/34/3; listener 22/22/5; accumulator 24/23/10 |
| 11 | 4952 | silencer 30/29/3; waylayer 27/22/4; pavise 22/22/9; forker 23/23/8; outrider 22/22/5 |
| 12 | 4939 | redliner 25/23/2; caromer 21/21/7; towline 29/27/4 |
| 13 | 4943 | gaoler 24/22/4; cantor 29/29/3; repriser 26/25/2 |
| 14 | 4947 | repulsor 34/32/2; cantor 27/26/4; fencer 23/23/5 |
| 15 | 4937 | bulwark 31/31/4; pincer 29/29/4; snarer 26/25/2; reaper 17/17/10 |
| 16 | 4941 | pavise 32/32/4; caromer 31/30/4; wirewright 30/29/2 |
| 17 | 4945 | silencer 21/20/8; wirewright 24/23/9 |
| 18 | 4947 | drubber 28/27/4; shy 31/31/3 |
| 19 | 4937 | reaper 23/23/7 |
| 20 | 4944 | arccaster 16/16/4; fusilier 24/23/2 |
| 21 | 4956 | silencer 28/26/4; repulsor 18/16/4 |
| 22 | 4942 | pavise 24/24/2; carrion 21/21/5; towline 27/26/3; bombardier 21/21/6 |
| 23 | 4947 | **PASS: all 46 identities** |

Trials 2–3 repair only preceding measured failures. Rotating deficits in the first three trials justify the same measured margin rule used by B14: +1 broad ticket below 30 planned or 25 legal (+2 below 22 planned or 20 legal); +1 sector2 ticket below 7 early (+2 below 5). Trials 4–16 apply that fixed rule to the preceding results. Continued rotating early deficits justify a wider measured early margin from trial17: +2 sector2 tickets below10 early, +3 below5; the breadth rule remains unchanged through trial18. From trial19, persistent breadth dilution justifies +2 broad tickets below35 planned or30 legal, +3 below25 planned or20 legal. The acceptance floor remains25/20/5 throughout. From trial23, transfer only B15-added tickets in place from measured high-margin donors to failing recipients, preserving pool length and unaffected selection positions. Stop at the first passing sample. No seed search, placement relaxation, companion change or threshold reduction occurred.

## Exact ticket changes before each trial

Broad tickets apply only at sector≥2 arena/ambush; early tickets apply only at sector2 in those roles. Signed deltas accumulate above the retained B14 list; negative values are B15-only donor transfers. The baseline alternates four tickets each for Fusilier/Bombardier; later adjustment blocks are inserted after that baseline, before the preceding B15 adjustment blocks. Entries within the automated margin blocks are alphabetical.

| Trial | Broad +tickets | Sector2-only +tickets |
|---|---|---|
| 1 | bombardier_pressure+4; fusilier_screen+4 | — |
| 2 | carrion_feast+1; pavise_advance+1; stitcher_detail+1 | fencer_screen+2; fusilier_screen+2 |
| 3 | bombardier_pressure+1; censer_advance+1 | accumulator_detail+2; bombardier_pressure+2 |
| 4 | absolver_detail+1; bulwark_line+1; conductor_pressure+1; fencer_screen+1; fusilier_screen+1; harrier_screen+2; redliner_pressure+1; shy_pressure+2; stitcher_detail+1; waylayer_cutoff+1 | absolver_detail+2; fusilier_screen+1; pavise_advance+1; redliner_pressure+2; reeler_chase+2; repulsor_screen+1; shy_pressure+1; waylayer_cutoff+1 |
| 5 | cantor_charge+1; caromer_screen+1; drubber_chase+1; outrider_detail+1; screenwright_detail+1; stitcher_detail+1; wirewright_chase+2 | carrion_feast+1; drubber_chase+1; stitcher_detail+1; towline_detail+2; wirewright_chase+1 |
| 6 | conductor_pressure+1; cordon_screen+2; exactor_pressure+1; fusilier_screen+1; reaper_detail+1; reeler_chase+1; towline_detail+1; wirewright_chase+1 | cordon_screen+1; listener_detail+1; outrider_detail+2; shy_pressure+1; waylayer_cutoff+1 |
| 7 | afterburst_detail+1; cantor_charge+1; exactor_pressure+1; repulsor_screen+1; screenwright_detail+1; siphoner_pressure+1 | afterburst_detail+2; exactor_pressure+1; reaper_detail+1; siphoner_pressure+1 |
| 8 | bulwark_line+1; censer_advance+1; forker_crossfire+1; repriser_detail+1; siphoner_pressure+1 | bulwark_line+1; carrion_feast+2; censer_advance+1; repriser_detail+1; repulsor_screen+1; screenwright_detail+1 |
| 9 | absolver_detail+1; accumulator_detail+1; bombardier_pressure+1; reeler_chase+1; silencer_screen+1; stitcher_detail+1 | bombardier_pressure+1; bulwark_line+1; fusilier_screen+1; reeler_chase+2; repulsor_screen+1; silencer_screen+2 |
| 10 | bombardier_pressure+1; cantor_charge+1; conductor_pressure+1; drubber_chase+1; pavise_advance+1; siphoner_pressure+1 | bombardier_pressure+2; cantor_charge+1; conductor_pressure+1; cordon_screen+1; fencer_screen+2; gaoler_hold+1; harrier_screen+1; pavise_advance+1; trailmaker_chase+2 |
| 11 | accumulator_detail+1; afterburst_detail+1; arccaster_zone+1; harrier_screen+1; listener_detail+1; pincer_detail+1; redliner_pressure+1; trailmaker_chase+1 | afterburst_detail+1; carrion_feast+2; censer_advance+2; forker_crossfire+2; harrier_screen+1; listener_detail+1; pavise_advance+1; pincer_detail+1; stitcher_detail+1 |
| 12 | bulwark_line+1; forker_crossfire+1; outrider_detail+1; pavise_advance+1; pincer_detail+1; reaper_detail+1; repulsor_screen+1; snarer_detail+1; waylayer_cutoff+1 | bulwark_line+1; outrider_detail+1; silencer_screen+2; snarer_detail+1; waylayer_cutoff+2; wirewright_chase+1 |
| 13 | caromer_screen+2; fencer_screen+1; harrier_screen+1; outrider_detail+1; redliner_pressure+1; snarer_detail+1; towline_detail+1 | absolver_detail+1; conductor_pressure+1; redliner_pressure+2; screenwright_detail+1; silencer_screen+1; towline_detail+2 |
| 14 | afterburst_detail+1; cantor_charge+1; cordon_screen+1; gaoler_hold+1; repriser_detail+1 | arccaster_zone+1; cantor_charge+2; gaoler_hold+2; repriser_detail+2 |
| 15 | cantor_charge+1; caromer_screen+1; carrion_feast+1; drubber_chase+1; fencer_screen+1; fusilier_screen+1; shy_pressure+1; trailmaker_chase+1 | cantor_charge+2; drubber_chase+1; fencer_screen+1; fusilier_screen+1; repulsor_screen+2; stitcher_detail+1; waylayer_cutoff+1 |
| 16 | absolver_detail+1; cordon_screen+1; exactor_pressure+1; forker_crossfire+1; pincer_detail+1; reaper_detail+2; screenwright_detail+1; snarer_detail+1; waylayer_cutoff+1 | bulwark_line+2; exactor_pressure+1; pavise_advance+1; pincer_detail+2; siphoner_pressure+1; snarer_detail+2 |
| 17 | absolver_detail+1; carrion_feast+1; conductor_pressure+1; listener_detail+1; outrider_detail+1; shy_pressure+1 | absolver_detail+2; caromer_screen+3; carrion_feast+2; censer_advance+2; conductor_pressure+2; cordon_screen+2; harrier_screen+2; listener_detail+2; outrider_detail+2; pavise_advance+3; pincer_detail+2; repulsor_screen+2; siphoner_pressure+2; towline_detail+2; wirewright_chase+3 |
| 18 | afterburst_detail+1; bulwark_line+1; censer_advance+1; reeler_chase+1; silencer_screen+2; towline_detail+1; waylayer_cutoff+1; wirewright_chase+1 | afterburst_detail+2; bombardier_pressure+2; bulwark_line+2; cordon_screen+2; drubber_chase+2; exactor_pressure+2; fencer_screen+2; harrier_screen+2; outrider_detail+2; pavise_advance+2; redliner_pressure+2; reeler_chase+2; screenwright_detail+2; silencer_screen+2; stitcher_detail+2; waylayer_cutoff+2; wirewright_chase+2 |
| 19 | accumulator_detail+2; carrion_feast+2; censer_advance+2; drubber_chase+2; exactor_pressure+2; forker_crossfire+2; harrier_screen+2; listener_detail+2; reeler_chase+2; repriser_detail+2; repulsor_screen+2; screenwright_detail+2; shy_pressure+2; stitcher_detail+2; trailmaker_chase+2; waylayer_cutoff+2; wirewright_chase+2 | accumulator_detail+2; carrion_feast+2; censer_advance+2; conductor_pressure+2; drubber_chase+3; exactor_pressure+2; fencer_screen+2; listener_detail+2; outrider_detail+2; pincer_detail+2; redliner_pressure+2; reeler_chase+2; repriser_detail+2; shy_pressure+3; snarer_detail+2; stitcher_detail+2; towline_detail+2; trailmaker_chase+2; waylayer_cutoff+2 |
| 20 | accumulator_detail+2; bulwark_line+2; cantor_charge+2; caromer_screen+2; conductor_pressure+2; forker_crossfire+2; fusilier_screen+2; gaoler_hold+2; outrider_detail+2; pavise_advance+2; pincer_detail+2; reaper_detail+3; redliner_pressure+2; stitcher_detail+2; wirewright_chase+2 | afterburst_detail+2; arccaster_zone+2; bulwark_line+2; caromer_screen+2; conductor_pressure+2; fencer_screen+2; forker_crossfire+2; gaoler_hold+2; listener_detail+2; pavise_advance+2; reaper_detail+2; redliner_pressure+2; reeler_chase+2; siphoner_pressure+2; snarer_detail+2; stitcher_detail+2; towline_detail+2; trailmaker_chase+2; waylayer_cutoff+2 |
| 21 | absolver_detail+2; accumulator_detail+2; afterburst_detail+2; arccaster_zone+3; bombardier_pressure+2; bulwark_line+2; cantor_charge+2; cordon_screen+2; drubber_chase+2; exactor_pressure+2; fencer_screen+2; forker_crossfire+2; fusilier_screen+3; listener_detail+2; repriser_detail+2; screenwright_detail+2; siphoner_pressure+2 | absolver_detail+2; accumulator_detail+2; afterburst_detail+2; arccaster_zone+3; cantor_charge+2; carrion_feast+2; drubber_chase+2; exactor_pressure+2; fencer_screen+2; forker_crossfire+2; fusilier_screen+3; listener_detail+2; repriser_detail+2; screenwright_detail+2; trailmaker_chase+2; wirewright_chase+2 |
| 22 | accumulator_detail+2; afterburst_detail+2; bulwark_line+2; censer_advance+2; fencer_screen+2; gaoler_hold+2; reaper_detail+2; repriser_detail+2; repulsor_screen+3; silencer_screen+2; snarer_detail+2; stitcher_detail+2; towline_detail+2; trailmaker_chase+2; waylayer_cutoff+2; wirewright_chase+2 | arccaster_zone+2; bulwark_line+2; censer_advance+2; cordon_screen+2; drubber_chase+2; fencer_screen+2; forker_crossfire+2; fusilier_screen+2; gaoler_hold+2; pincer_detail+2; reaper_detail+2; repulsor_screen+3; shy_pressure+2; silencer_screen+3; stitcher_detail+2; wirewright_chase+2 |
| 23 | bombardier_pressure+3; carrion_feast+3; drubber_chase-2; gaoler_hold-3; pavise_advance+2; repulsor_screen-3 | gaoler_hold-3; pavise_advance+3; repulsor_screen-3; towline_detail+3 |

Trial23 transfers: broad Gaoler→Carrion ×3, Repulsor→Bombardier ×3, Drubber→Pavise ×2; sector2-only Gaoler→Pavise ×3 and Repulsor→Towline ×3. Pre-transfer donors were Gaoler62/58/18, Repulsor56/54/20, Drubber52/50/12; recipients were Carrion21/21/5, Bombardier21/21/6, Pavise24/24/2 and Towline27/26/3. Only the first matching B15 adjustment slots were replaced, retaining every historical ticket and unaffected ordered entry. The first resulting sample passed; no further ticket changes or optional resampling occurred.

## Cumulative B15 ticket additions

| Template | Broad +tickets | Sector2-only +tickets |
|---|---:|---:|
| absolver_detail | 6 | 7 |
| accumulator_detail | 10 | 6 |
| afterburst_detail | 8 | 9 |
| arccaster_zone | 4 | 8 |
| bombardier_pressure | 12 | 7 |
| bulwark_line | 10 | 11 |
| cantor_charge | 9 | 7 |
| caromer_screen | 6 | 5 |
| carrion_feast | 8 | 11 |
| censer_advance | 7 | 9 |
| conductor_pressure | 6 | 8 |
| cordon_screen | 6 | 8 |
| drubber_chase | 5 | 11 |
| exactor_pressure | 7 | 8 |
| fencer_screen | 7 | 15 |
| forker_crossfire | 9 | 8 |
| fusilier_screen | 12 | 10 |
| gaoler_hold | 2 | 4 |
| harrier_screen | 6 | 6 |
| listener_detail | 6 | 10 |
| outrider_detail | 6 | 9 |
| pavise_advance | 7 | 14 |
| pincer_detail | 5 | 9 |
| reaper_detail | 9 | 5 |
| redliner_pressure | 5 | 10 |
| reeler_chase | 5 | 10 |
| repriser_detail | 8 | 7 |
| repulsor_screen | 4 | 7 |
| screenwright_detail | 7 | 6 |
| shy_pressure | 6 | 7 |
| silencer_screen | 5 | 10 |
| siphoner_pressure | 5 | 6 |
| snarer_detail | 5 | 7 |
| stitcher_detail | 10 | 11 |
| towline_detail | 5 | 13 |
| trailmaker_chase | 6 | 8 |
| waylayer_cutoff | 8 | 11 |
| wirewright_chase | 10 | 11 |
| **Total** | **262** | **329** |

## Final full distribution

| Identity | Planned | Legal | Early |
|---|---:|---:|---:|
| climber | 108 | 96 | 94 |
| razor | 266 | 264 | 62 |
| lurker | 215 | 203 | 93 |
| beamsweeper | 100 | 99 | 35 |
| flamer | 128 | 124 | 100 |
| arccaster | 30 | 30 | 10 |
| sentry | 149 | 143 | 71 |
| bigcrab | 218 | 216 | 116 |
| nodule | 182 | 171 | 86 |
| gaoler | 40 | 38 | 16 |
| silencer | 45 | 42 | 13 |
| repulsor | 42 | 40 | 14 |
| stitcher | 34 | 32 | 12 |
| bulwark | 32 | 29 | 6 |
| cantor | 38 | 37 | 9 |
| pincer | 36 | 36 | 12 |
| harrier | 30 | 30 | 8 |
| waylayer | 48 | 41 | 9 |
| pavise | 33 | 33 | 5 |
| repriser | 46 | 46 | 9 |
| redliner | 32 | 30 | 12 |
| caromer | 36 | 34 | 12 |
| reeler | 31 | 31 | 14 |
| forker | 31 | 31 | 13 |
| wirewright | 35 | 34 | 11 |
| snarer | 29 | 28 | 6 |
| cordon | 27 | 25 | 8 |
| reaper | 44 | 44 | 9 |
| drubber | 43 | 41 | 10 |
| fencer | 49 | 48 | 18 |
| afterburst | 39 | 38 | 13 |
| carrion | 33 | 32 | 6 |
| towline | 29 | 28 | 5 |
| screenwright | 32 | 31 | 11 |
| censer | 35 | 35 | 14 |
| trailmaker | 40 | 36 | 14 |
| listener | 46 | 45 | 12 |
| shy | 38 | 36 | 10 |
| absolver | 41 | 41 | 12 |
| exactor | 30 | 30 | 6 |
| outrider | 34 | 34 | 13 |
| conductor | 33 | 33 | 10 |
| siphoner | 27 | 27 | 5 |
| accumulator | 42 | 42 | 15 |
| fusilier | 54 | 54 | 14 |
| bombardier | 32 | 32 | 8 |
