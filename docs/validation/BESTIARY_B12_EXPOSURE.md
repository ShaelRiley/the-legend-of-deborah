# Bestiary B12 production exposure evidence

All trials use the unchanged 512-plan sample: 32 generated mazes, parties1–4, dungeons1–5. Every retained identity and both additions must meet25 planned /20 legal /5 early. Thresholds and sample are unchanged. Native collision/ceiling traces are doubles, not Source evidence.

Only selection tickets changed between trials. Mechanics, placement geometry and singleton/companion checks did not change. Existing B11 tickets remain.

## Trial1 — one base ticket per new identity

Failures: Arc Caster34/34/2, Absolver22/22/3, Exactor23/23/7.

```text
DISTRIBUTION climber planned=168 legal=146 early=108
DISTRIBUTION razor planned=272 legal=272 early=68
DISTRIBUTION lurker planned=191 legal=179 early=95
DISTRIBUTION beamsweeper planned=129 legal=125 early=41
DISTRIBUTION flamer planned=159 legal=157 early=115
DISTRIBUTION arccaster planned=34 legal=34 early=2
DISTRIBUTION sentry planned=153 legal=140 early=65
DISTRIBUTION bigcrab planned=250 legal=246 early=124
DISTRIBUTION nodule planned=206 legal=191 early=91
DISTRIBUTION gaoler planned=58 legal=54 early=10
DISTRIBUTION silencer planned=26 legal=26 early=7
DISTRIBUTION repulsor planned=52 legal=52 early=22
DISTRIBUTION stitcher planned=33 legal=32 early=13
DISTRIBUTION bulwark planned=37 legal=36 early=8
DISTRIBUTION cantor planned=51 legal=50 early=13
DISTRIBUTION pincer planned=41 legal=38 early=10
DISTRIBUTION harrier planned=43 legal=41 early=10
DISTRIBUTION waylayer planned=38 legal=32 early=6
DISTRIBUTION pavise planned=30 legal=29 early=9
DISTRIBUTION repriser planned=51 legal=49 early=19
DISTRIBUTION redliner planned=42 legal=42 early=13
DISTRIBUTION caromer planned=45 legal=44 early=12
DISTRIBUTION reeler planned=36 legal=35 early=8
DISTRIBUTION forker planned=34 legal=33 early=12
DISTRIBUTION wirewright planned=33 legal=33 early=10
DISTRIBUTION snarer planned=39 legal=37 early=13
DISTRIBUTION cordon planned=53 legal=49 early=13
DISTRIBUTION reaper planned=32 legal=30 early=10
DISTRIBUTION drubber planned=26 legal=25 early=9
DISTRIBUTION fencer planned=50 legal=50 early=14
DISTRIBUTION afterburst planned=53 legal=51 early=19
DISTRIBUTION carrion planned=42 legal=42 early=14
DISTRIBUTION towline planned=46 legal=45 early=10
DISTRIBUTION screenwright planned=33 legal=33 early=6
DISTRIBUTION censer planned=33 legal=33 early=11
DISTRIBUTION trailmaker planned=30 legal=29 early=12
DISTRIBUTION listener planned=41 legal=39 early=9
DISTRIBUTION shy planned=45 legal=42 early=8
DISTRIBUTION absolver planned=22 legal=22 early=3
DISTRIBUTION exactor planned=23 legal=23 early=7
/workspace/scratch/3c4fbcc4ead3/the-legend-of-deborah/tools/test_encounter_distribution.lua: ...-legend-of-deborah/tools/test_encounter_distribution.lua:129: arccaster unavailable in early/mid sectors
```

## Trial2 — add one Arc Caster, Absolver and Exactor ticket

Failures: Silencer27/26/4, Wirewright24/24/6, Drubber16/16/8. New identities: Absolver50/48/13; Exactor38/38/6.

```text
DISTRIBUTION climber planned=162 legal=138 early=108
DISTRIBUTION razor planned=296 legal=296 early=76
DISTRIBUTION lurker planned=196 legal=185 early=99
DISTRIBUTION beamsweeper planned=133 legal=128 early=41
DISTRIBUTION flamer planned=180 legal=178 early=114
DISTRIBUTION arccaster planned=38 legal=38 early=8
DISTRIBUTION sentry planned=169 legal=160 early=71
DISTRIBUTION bigcrab planned=226 legal=224 early=122
DISTRIBUTION nodule planned=185 legal=174 early=82
DISTRIBUTION gaoler planned=56 legal=56 early=16
DISTRIBUTION silencer planned=27 legal=26 early=4
DISTRIBUTION repulsor planned=54 legal=54 early=14
DISTRIBUTION stitcher planned=32 legal=31 early=10
DISTRIBUTION bulwark planned=40 legal=39 early=14
DISTRIBUTION cantor planned=36 legal=35 early=12
DISTRIBUTION pincer planned=38 legal=36 early=9
DISTRIBUTION harrier planned=50 legal=50 early=18
DISTRIBUTION waylayer planned=34 legal=30 early=6
DISTRIBUTION pavise planned=33 legal=32 early=8
DISTRIBUTION repriser planned=35 legal=34 early=14
DISTRIBUTION redliner planned=40 legal=37 early=13
DISTRIBUTION caromer planned=53 legal=51 early=11
DISTRIBUTION reeler planned=42 legal=42 early=12
DISTRIBUTION forker planned=29 legal=29 early=9
DISTRIBUTION wirewright planned=24 legal=24 early=6
DISTRIBUTION snarer planned=32 legal=32 early=10
DISTRIBUTION cordon planned=44 legal=43 early=17
DISTRIBUTION reaper planned=32 legal=32 early=8
DISTRIBUTION drubber planned=16 legal=16 early=8
DISTRIBUTION fencer planned=47 legal=47 early=14
DISTRIBUTION afterburst planned=41 legal=41 early=11
DISTRIBUTION carrion planned=44 legal=44 early=13
DISTRIBUTION towline planned=66 legal=63 early=19
DISTRIBUTION screenwright planned=38 legal=36 early=12
DISTRIBUTION censer planned=28 legal=28 early=5
DISTRIBUTION trailmaker planned=31 legal=31 early=9
DISTRIBUTION listener planned=36 legal=35 early=7
DISTRIBUTION shy planned=43 legal=42 early=15
DISTRIBUTION absolver planned=50 legal=48 early=13
DISTRIBUTION exactor planned=38 legal=38 early=6
/workspace/scratch/3c4fbcc4ead3/the-legend-of-deborah/tools/test_encounter_distribution.lua: ...-legend-of-deborah/tools/test_encounter_distribution.lua:129: silencer unavailable in early/mid sectors
```

## Trial3 — additionally add one Silencer, Wirewright and Drubber ticket

PASS: all forty sampled identities meet the unchanged gate. Absolver27/25/12; Exactor29/28/8. 512 plans /4944 encounters. Final B12 adjustment is six additional tickets, one each for arccaster_zone, absolver_detail, exactor_pressure, silencer_screen, wirewright_chase and drubber_chase.

```text
DISTRIBUTION climber planned=180 legal=158 early=110
DISTRIBUTION razor planned=282 legal=282 early=72
DISTRIBUTION lurker planned=213 legal=198 early=99
DISTRIBUTION beamsweeper planned=125 legal=119 early=43
DISTRIBUTION flamer planned=159 legal=156 early=114
DISTRIBUTION arccaster planned=64 legal=64 early=16
DISTRIBUTION sentry planned=160 legal=150 early=71
DISTRIBUTION bigcrab planned=222 legal=220 early=120
DISTRIBUTION nodule planned=186 legal=172 early=82
DISTRIBUTION gaoler planned=44 legal=44 early=12
DISTRIBUTION silencer planned=50 legal=47 early=6
DISTRIBUTION repulsor planned=54 legal=48 early=12
DISTRIBUTION stitcher planned=57 legal=55 early=18
DISTRIBUTION bulwark planned=30 legal=30 early=8
DISTRIBUTION cantor planned=30 legal=30 early=10
DISTRIBUTION pincer planned=41 legal=41 early=11
DISTRIBUTION harrier planned=43 legal=42 early=14
DISTRIBUTION waylayer planned=32 legal=29 early=6
DISTRIBUTION pavise planned=31 legal=30 early=11
DISTRIBUTION repriser planned=27 legal=25 early=6
DISTRIBUTION redliner planned=44 legal=43 early=11
DISTRIBUTION caromer planned=56 legal=55 early=15
DISTRIBUTION reeler planned=41 legal=40 early=10
DISTRIBUTION forker planned=42 legal=42 early=11
DISTRIBUTION wirewright planned=57 legal=54 early=17
DISTRIBUTION snarer planned=32 legal=31 early=7
DISTRIBUTION cordon planned=42 legal=41 early=11
DISTRIBUTION reaper planned=36 legal=35 early=8
DISTRIBUTION drubber planned=39 legal=39 early=6
DISTRIBUTION fencer planned=30 legal=29 early=9
DISTRIBUTION afterburst planned=35 legal=35 early=11
DISTRIBUTION carrion planned=43 legal=42 early=13
DISTRIBUTION towline planned=44 legal=44 early=12
DISTRIBUTION screenwright planned=40 legal=38 early=13
DISTRIBUTION censer planned=40 legal=39 early=13
DISTRIBUTION trailmaker planned=28 legal=25 early=6
DISTRIBUTION listener planned=40 legal=40 early=15
DISTRIBUTION shy planned=32 legal=32 early=7
DISTRIBUTION absolver planned=27 legal=25 early=12
DISTRIBUTION exactor planned=29 legal=28 early=8
DISTRIBUTION_SAMPLE plans=512 encounters=4944
ENCOUNTER_DISTRIBUTION_PASS: 512 deterministic plans / 4944 encounters, 32 generated mazes, party 1–4, dungeon 1–5
```
