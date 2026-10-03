# Modular boss production tuning — 2026-10-03

This is the consolidated IMPLEMENTATION-TUNABLE record for the live GDD tab 07. It records concrete production choices used to realize the already-authored encounters. It does not replace the complete authored mechanics in tabs 05/HUMAN or establish native runtime acceptance.

Immutable authored constraints remain unchanged: exact Dungeon 1–20 order; one Gordon with no clones/turrets at 1; Gordon plus exactly four clones and four Sentries before Hector at 20; Chuck alone owns Dungeon 14 boss HP/title/receipt/key and Jane is subordinate; Joilette requires exactly three unique Toilet Cleaner hits; Melf freezes the committed party/kit and up to two executable signatures; Button remains E-only and solo-safe; native death is separate from key/jail/rescue; no new 21+ selection policy; final-Hero elimination retains the encounter, with only timer expiry causing automatic failure.

## Common framework tuning

- Normal new-boss health phase thresholds: 60% and 25%; Melf, Button and Joilette use their authored special phase conditions
- First-class primary archetypes use the existing champion progression: dungeon + floor(dungeon/3) + 2 within canonical caps; HP is derived through the existing ability/feat/hit-die pipeline, then frozen party scaling 1 / 1.2 / 1.4 / 1.6. No party damage multiplier
- The eighteen primary progression templates copy the existing Warden ability/class/hit-die profile, use their own exact archetype/external-health identity, base XP500 and primary-boss flag. Jane uses her own exact support identity, base XP80 and no primary-boss flag; ordinary attribution/XP/loot calculation remains authoritative. No subordinate receives a defeat receipt or key authority
- Registration fallback fields are melee damage8, burst damage8, melee cooldown1.4s, melee range96 and threat10. The fallback canonical melee damage profile is2d4+3 with reference8; each authored attack supplies its explicit packet when specified below. Primary manual AI does not independently fire these fallback attacks. Descriptor defaults for an omitted model/HP/speed are stock male02/700/150; the concrete module table below supplies the authored overrides
- Shared active-hostile ceiling 96 and shared EnemyRoster-plus-boss projectile ceiling 64. Module object/zone budget is capped at 64; module add budgets exclude its one primary. A pending add queue has at most 16 entries and 30-second lifetime; module-specific queues may use their stricter listed bounds
- One encounter service at 20 Hz; snapshots at 5 Hz, compressed packet maximum 32 KiB and decoded maximum 128 KiB. Up to 24 warnings and 24 transmitted zone entries; no client authority or per-hazard timer
- Up to 64 pending jobs, delay at most 60 seconds. Ownership includes campaign/run/epoch/level seed/graph/progression/arena/resources plus source and target profile/native incarnation. Nested work inherits the originating lease
- Ordinary object lifetime 0.1–60 seconds; reusable permanent architecture remains only for its exact encounter. Projectile speed at most 1400 units/second, gravity 0–1200, mass 1–150, radius 2–120, bounce count 0–4. A projectile may damage the same bound Hero life only once
- Zone radius 4–900, delay 0–20 seconds, active lifetime 0.05–30 seconds, interval 0.15–10 seconds. Lane width always means full width. Damage checks the promised shape, target life, current court, elevation and real cover
- Ground/skate/air speed 20–1100; skate/air steering factor 0.25–8 per second. Charges have a fixed captured destination, 0.25–5-second warning, speed 80–1100, bounded 0–400-unit vertical arc, signed lateral arc up to 120 units and authored minimum duration where specified. Arc travel participates in duration. Cancellation clears state once and cannot create new attacks, movement, healing, self-damage, Push or queued additions
- Generic stagger 0.2–6 seconds followed by a 2-second renewal guard. Authored self-damage is nonlethal and at most 18% of that actor’s maximum HP in total; module limits can be stricter
- Default new-boss death-scene/key delay is 4 seconds; explicit per-boss deathDuration overrides apply to both the scene and earliest key. The primary receipt seals immediately; no cinematic or subordinate owns a second receipt. Button additionally waits for its small Jail Key button
- Primary/support native admission uses the shared 96-actor ceiling. Failed primary allocation does not accumulate party snapshots. Partial Gordon-20 composition is rolled back and retried with fixed identity, never accepted at reduced count; each corner has at most 10 additional safe candidate checks
- Generic new courts are 5–7 cells wide and 5–7 odd-depth cells, with lower court, upper perimeter, two stair routes, protected west entry and separate east jail. Even descriptor depth 6 rounds up to physical depth 7; width 6 stays 6. Default authored air volume is floor+80 to floor+700, nominal gunship height 420; only Flightmeister is airborne. Drone ground-point targets receive their explicit 70-unit hover lift, with a 20-unit minimum clearance
- Route safety uses a finite 3×3 clearance sample lattice per court cell with ±96-unit offsets, expanded 18-unit Hero clearance, exact mandatory interaction/real Button/safe-anchor/current-Hero routes and entry-to-jail continuity. Mooky executes its separately authored graph waypoints; ground movement sweeps the true actor hull and ordinary movement can use a bounded 1-second detour retry through a six-node local visibility graph permitting a two-corner bypass
- Static shallow ramps use the canonical static-box authority: at most 24 support boxes per encounter, 2–6 steps per ramp, width 80–500, length 64–400, total height 4–48, per-step rise at most 12. These support surfaces have no damage/reward authority and retire with the encounter
- E interactions: one nearest front-facing visible owned object within 110 units; ordinary use debounce 0.2 seconds; module hold time remains explicit. Holds bind the exact Hero life and are discarded on release, range loss or incarnation change
- Wet/suds traction is bounded horizontal inertia, not a maximum-speed debuff: traction factor 0.45–1 scales 900 units/second² change toward ordinary movement velocity; preserve engine collision, class maximum speed and jump Z, with per-frame delta capped at 0.05 seconds. The transient state clears on exit/death/pause/reset
- Generic CONED constraint: radius 24–100, duration 0.2–4 seconds, at least 4 seconds of post-constraint protection; Conan’s listed shorter duration/escape rules apply. Its temporary high collision hull guarantees baseline-Hero escape
- Native solid prop Push uses the existing Push save/modifier/displacement authority. Object scales are bounded 0–2.5; boss body scales 0–1. Ignited/critical or non-pushable objects reject Push. Proposed solid displacement and subsequent motion must preserve court bounds and mandatory connectivity
- Client presentation uses one boss state, bounded warnings/objects, at most eight reusable optional props and one finite corpse ghost; actual primary scale/model/color/phase flags are frozen into the ghost. No per-frame model allocation
- Four original deterministic mono PCM cues at 22050 Hz: honk 0.38 seconds, spring boing 0.55 seconds, metal clang 0.5 seconds, low rumble 0.65 seconds. Standard punctuation playback is volume 0.7 at level 75; no soundtrack or Workshop dependency

## Primary module reference values

Values below are reference inputs before canonical RPG growth and frozen party HP. Exact mechanics and further per-attack choices follow.

| Boss ID | Base HP | Base speed | Visual scale | Objects/zones | Adds | Death scene seconds |
|---|---:|---:|---:|---:|---:|---:|
| chonker | 680 | 160 | 1 | 9 | 0 | 2.6 |
| felon | 840 | 185 | 3.4 | 18 | 0 | 3.8 |
| melf | 780 | 170 | 1 | 24 | 4 | 4 |
| ollie | 920 | 150 | 1.45 | 20 | 3 | 4 |
| crystal_bepis | 1000 | 145 | 1.1 | 18 | 0 | 4 |
| daryl | 1160 | 125 | 2.65 | 22 | 0 | 6.8 |
| sofa | 1360 | 85 | 2.8 | 20 | 0 | 4 |
| marion | 1500 | 170 | 1.55 | 20 | 0 | 5 |
| button | 800 | 0 | 1 | 24 | 6 | 4 |
| ray | 1250 | 110 | 1.7 | 18 | 0 | 4 |
| cornette | 1350 | 205 | 1.15 | 14 | 3 | 2.8 |
| moshi | 1400 | 105 | 1.7 | 22 | 0 | 4 |
| chuck | 1500 | 145 | 1.15 | 24 | 1 | 4 |
| rank_and_file | 1700 | 95 | 3.2 | 28 | 12 | 3.4 |
| flightmeister | 2200 | 250 | 1 | 22 | 0 | 6 |
| conan | 2050 | 145 | 6.8 | 40 | 0 | 5 |
| joilette | 950 | 100 | 3 | 22 | 7 | 4 |
| little_mooky | 2900 | 145 | 1 | 18 | 0 | 8 |


## Chonker the Honker

### Implemented authored outcomes

Ordinary-size pigeon, limited-turn skating, chase/reposition/bomb/defuse/punish grammar, Black timed bombs, Red armed proximity mines, one-slot Gold and THE BIG ONE, safely shoot-defusable objects, deterministic fast dropping laps, wing-flap anti-melee Push, tiny taunts, largest backfire punish and actual harmless failed-skate/feet/tip/HONK death scene. Red mine expiry is safe if it never triggers. Duplicate destroy events cannot repeat a defuse/backfire.

### Tuning

- Model models/pigeon.mdl; size1; baseHP680; speed160; maxObjects9; no adds; 5x5 industrial court
- Phase skate speeds160/235/275; turnRate1.8/second; waypoint stopDistance50
- Begin attack delay1.5s; normal cadence3.5s then2.5s; phase reset1.2s; pause reset1.5s
- Bomb active cap8, Gold/Big shared cap1. Floor safe-anchor clearance radius+90. Combined route proof radius+35. Bomb center+12Z; radius14; mass12; pushable; nonsolid. Life=fuse+2s
- Black: HP24, fuse4s, blast radius140, packet17/reference17, Push210, scale.55, black RGB24/24/24
- Red: HP30, maximum armed life12s, radius155, packet19/reference17, Push210, scale.6, red215/35/30. Arms after.8s; proximity115; triggering gives.85s final warning; untriggered expiry causes no explosion
- Gold: HP72, fuse6s, radius215, packet24/reference17, Push210, scale.85, gold245/195/30
- THE BIG ONE: HP130, fuse8s, radius290, packet29/reference17, Push210, scale1.3, gold255/215/35. Defuse warns a backfire along route for.35s, then stops/staggers Chonker4.5s. Exactly one resolution
- Phase1: Black bombs plus.85s stopped taunt. Phase2+ cycle multiples3 drop3 bombs with.65s separation and middle Red; ordinary even cycles Red otherwise Black. Phase3 every4th cycle Gold, every8th THE BIG ONE
- Wing flap within95 units: warning.45s/radius105, packet5/reference17, Push260; cooldown4s
- Death duration2.6s: failed skate0, running feet.8, tip1.5, final HONK1.9. No damage/key override
- Client: four small stock-render skate wheels, bounded tilt; tip pose90degrees; short final honk ring


## Felon the Melon

### Implemented authored outcomes

Distinct short/long/high body bounces with real committed damage/Push, hard landing recovery, bounded smashable and Push-displaceable arcing melons, spread, wall-bank projectile, long-jump trail, separately telegraphed wall rebound, phase-three impact self-damage ceiling, safe-region produce rain, high geometry escape, visual cracks and harmless final bounce/splat/chunk death. Explicit phase grammars ensure high/long bounces remain reachable after later ranged attacks unlock.

### Tuning

- Watermelon stock model; baseHP840, size3.4, speed185; maxObjects18, melon cap12, no adds, body Push immune; 6x5 concrete-bowl/ricochet court
- Begin1.8s; ordinary cadence3.1s, phase3 cadence2.4s; phase reset1.3s; pause reset1.5s
- Short bounce warning.65s, speed330, vertical arc65, width58, packet18/reference18, Push240, recovery.9s
- Long bounce warning.85s, speed485, arc100, width58, packet18, Push240, recovery1.8s. Three trail drops at quarter-path points; after warning+.3/.6/.9s, origin+65Z
- High bounce warning1.05s, speed280, arc240, packet24, otherwise long-bounce width/Push/recovery. Geometry stuck=less than16 units progress for3.5s during commitment, then high escape to legal point, next attack4s
- A wall trace with abs(normal.z)<.5 in phase2+ reflects original committed ground direction. Landing220 units along reflection; preview/recovery1.8s, then additional.25s Charge warning, speed320, arc65, width55, packet18, Push190, recovery1.6s; final hard-impact recovery1.8s. No midair tracking reversal
- Hard high/long landing phase3 applies1.2% maxHP per impact, total14% encounter cap and common nonlethal/self-damage ceiling
- Melon cap12: nativeHP18, radius16, scale1.15, life6s, gravity430, packet13/reference18, Push160, default origin+58Z, pushable
- Single/spread: speed clamp190..410 at.6*distance (distance bounded900), lift265,2bounces,mass10
- Bank: speed450,lift145,3bounces,mass12, aims at actual c.arena.ricochetPoints; warning1s at bank source/route. Fallback is a legal point but cannot itself prove wall semantics; native arena must supply real boundary anchors
- Trail: speed60,lift120,1bounce,mass8
- Rain: horizontal speed0, vertical-70,1bounce,mass12, origin350Z
- Bounce budget exhausted => harmless two chunks, model watermelon01_chunk02a, opposite X speeds75, Y40/Z65, gravity450, radius3,mass1,life1.1s,no damage
- Spread warning.85s radius150,3melons aimed at Y offsets-150/0/+150; ordinary single warning.75s radius65
- Produce Section: at most6 legal regions, safe-anchor clearance210, route proof radius90, warnings1.4+n*.16s, region radius90; next attack5s
- Phase1 grammar short/single/long/single/high; phase2 short/spread/long/bank/high/single; phase3 rain/long/bank/spread/high/short/single
- Death duration3.8s: final bounce1.3s with230-unit client visual peak, splat1.3, harmless chunk1.6 at center(-110,+35,+8), velocity90X,life2.1s
- Client phase3 red rind cracks and bounded roll; final floor splat, stock chunk


## Daryl the Barrel

### Implemented authored outcomes

Real roll/toss/pop; explicit Stable→Armed→Critical→Detonated object state machine; native attackable/pierceable lesser barrels; movable Stable objects; line/cluster/rolling distinctions, atomic visible Fuse Transfer, chained blast proximity, bounded self-harm, diminishing/immune blast stagger, periodic cover/distance-readable Internal Fuse, sequential safe-gap signature and overheat, rare Blue repositioning pressure barrel, scorch presentation and actual harmless final fuse/explosion/scorch/final-barrel/fizzle scene.

### Tuning

- Stock explosive drum; baseHP1160,size2.65,speed125,maxObjects22,lesser cap12,no adds;6x5 Powder Yard requiring blast barriers and ramps
- Begin1.7s; normal cadence3.5s; phase reset1.5s; first Internal Fuse starts after phase3+5s; ordinary initial nextInternal14s
- Lesser barrel HP36,radius21,mass30,scale.8,life16s,nonsolid. Stock drum; ordinary RGB145/95/65. Safe-anchor clearance245, combined route proof radius90
- Stable movable; entering Armed disables arbitrary Push; Armed default1.8s then Critical.8s. Explicit labels/warning ring persist. Toss/roll auto-arm no later than2s, and floor impact can settle/arm sooner while preserving1.8+.8s readable fuse
- Toss origin+70Z, horizontal speed min360,.65*distance,lift250,gravity430,1bounce; Rolling speed310,initial Z-35,gravity0,0bounces. Contact packet7/reference22,Push110
- Normal blast radius155,packet23/reference22,Push190. Daryl proximity185. Self damage1.5% maxHP/nearby barrel; local maximum18%, further constrained by shared aggregate18%; cannot kill
- Blast-stagger immunity5s. First stagger1.6s; consecutive permitted durations1.6/(1+.65*(count-1)),floor.35s; chain count resets after18s without nearby blast
- Blast arms Stable neighbors within175 for.8s Armed+.8s Critical; no recursive instantaneous detonation
- Blue independently rolls1-in-14 on named RNG stream blue_barrel, RGB50/110/235. Blast radius190,packet2/reference22,Push370. Stable barrels within240 displaced at horizontal190+vertical65, staying Stable; no ordinary chain/self-damage
- Fuse Transfer: one active source and one Stable target;.8s visible lane warning,width36,radius24; exact source extinguishes atomically, target gets1.4s Armed+.8s Critical. Destroyed/changed recipient prevents transfer; never duplicates source fuse
- Line4 barrels on interpolated legal start/end; Cluster3 nearby offsets(-100,-45),(0,+90),(+100,-45); Signature up to7 preauthored legal point regions. Sequential admission warning1.3+n*.6s, then Armed1s (cluster1.5)+Critical.8. Generic pattern next4.2s; signature next8.8s
- Signature final overheat at8.5s,3.3s punish; preserved safe anchor and connectivity proof
- Internal Fuse stationary4.5s, radius310 warning, packet34/reference22,Push300, LOS/cover filtered. Actual self application2% maxHP each, local10% total/shared18% combined;2.2s postvent stagger/recovery; next fuse17s; attack reservation5.8s
- Pressure Pop warning.5,radius125,packet6/reference22,Push255,cooldown4,proximity110
- Phase1 roll/toss/pop/toss; phase2 line/toss/transfer/roll/cluster/rolling; phase3 signature/roll/cluster/toss/transfer/rolling with periodic Internal Fuse taking priority
- Death duration6.8s: long fuse0..2.8, harmless boom2.8, final drum enters4.1 at center(-150,+65,+25),velocity65X,life2.5,scale.65,hp0; lights5.1 and stops; fizzles6.1. No final explosion packet
- Client: bounded rolling body, visible fuse sphere, scorch cracks, finite cosmetic fireball and floor scorch


## Sofa King Dangerous

### Implemented authored outcomes

Heavy pursuit, committed body charge/skid, slam, anti-melee armrest, all five differentiated furniture projectiles with real reachable grammar, bounded barrage, detached temporary hazard retaining only main native boss HP, finite designated missed-charge smash interactions, fixed two-segment Broken-Leg Drift, vertical rectangular Full Recline with actual miss detection/inversion/melee opportunity/recovery shove, Cushion Mines, Furniture Storm+one Full Recline, torn springs and harmless final charge/leg/back/cushion/boing scene. Explicit reachable cushion-floor key exception, with safe fallback.

### Tuning

- Stock FurnitureCouch002a; baseHP1360,size2.8,speed85,maxObjects20,no adds;6x5 clear-lane Living Room
- Up to3 designated table islands,HP75,radius42,mass80,permanent/solid. Per-island and aggregate route proof radius65; safe clearance165. Only designated missed-charge contact/proximity145 may smash/stagger2.7s; hitting a Hero prevents this reward
- Begin1.5s,normal cadence3.9s,phase reset1.4s,pause reset1.5s; heavy pursuit speed85,turnRate55,stopDistance175
- Charge warning1.1s,width95,speed440,packet26/reference25,Push280,miss recovery2s/hit1.25s
- Phase3 drift first target=58% of fixed destination plus75 perpendicular units,speed525; second frozen target original destination with.35s extra warning,speed470,packet22,Push235. Both lanes previewed; no target reacquisition. Native movement-loss watchdog8s→safe1.2s recovery
- Furniture aggregate cap10; safe-anchor clearance radius+100 and route proof radius+30, with table exclusion100 vs others65
- All furniture warning1s, visible source+65Z or overhead destination, lane width110/radius70; others launch origin+60Z. NativeHP20 except table45, Pushable, one impact before break (cushion bounce allowance1)
- Chair: model FurnitureChair001a,speed360,lift20,gravity70,mass18,radius24,life4,packet14,Push130
- Lamp: FurnitureLamp001a,spawn310 above destination,speed0,Z-45,gravity440,mass14,radius22,life3,packet20,Push100
- Table: FurnitureTable001a,speed300,lift10,gravity70,mass48,radius46,life4.5,packet22,Push230
- Ottoman: FurnitureCouch001a,speed260,lift30,gravity70,mass28,radius35,life4.2,packet17,Push170
- Cushion: FurnitureCouch001a scaled.34,speed330,lift210,gravity440,mass5,radius17,life3.5,packet10,Push95
- Sectional Split: lane warning1.1,width130; chaise FurnitureCouch001a scaled1.8,origin+25Z,speed240,gravity0,radius52,mass65,HP60,life5.5,packet20,Push230. Native collision settles it; no bounce/body progression role, no arbitrary Push. Reconnect5.2s or destruction. Does not change main boss HP and never emits completion
- Armrest Swipe proximity135,cooldown4,warning.6,radius150,packet12,Push230
- Recliner Slam length220,width155,warning1.05; Full Recline length320,width210,warning1.6. Route proof endpoints radius=.55*width. Live rectangle lasts.18s,interval.2,packet24 or33,Push275. Actual filtered contacts decide hit vs miss
- Any hit / ordinary recline recovery1.7s. Missed Full Recline inversion4.1s with1.4x incoming club/slash melee damage only. Warning starts.65 before recovery shove; final radius180,packet8,Push300. Denied zone creation restores pose and enters1.2s safe recovery
- Cushion Mine cap4,HP15,scale.4,radius18,life4.5,nonsolid;2s warning radius100 thenpacket9,Push250,immediate retirement
- Barrage3 cushions at center andY±110; supplementary warnings/launch1.25/1.5s
- Storm4 catalog entries chair/lamp/table/ottoman,delays1+n*.55s,regions85; one Full Recline queued3.5s,attack reservation9s
- Phase1 charge/slam/cushion/charge/slam; phase2 charge/chair/split/barrage/lamp/slam/table/charge/ottoman; phase3 charge/mine/full/chair/split/barrage/storm/lamp/table/ottoman
- Death duration4s: visual short charge first.65s at65units/s; leg snap.65; back pose1.2; harmless cushion1.6 at death position+80Z,velocity(35,25,-30),gravity250,scale.4,life2; boing2.5. Key resolves stored safe floor beneath cushions, falls back to center if unsafe/invalid body
- Client: heavy phase3 broken-leg lean7degrees, vertical recline78degrees, inversion180degrees, stock-render torn stuffing/springs, detached seam indicator and finite boing ring


## Additional physical arena tuning

This section supersedes the earlier missing-arena-geometry limitation. The module Start methods now instantiate real bounded geometry; they no longer rely on arena-theme metadata for the bowl, ramps, barriers or racks.

### Actual Felon bowl admission

- Six outward-rising perimeter strips. North/south strips have width clamp180..500 based on ground court extents, length180,height32,4steps of8units. East/west each have two strips with width clamp140..320 and a360-unit central gap preserving the entry-to-jail axis
- Upper gallery points are excluded when deriving ground rim extents (ground elevation tolerance24)
- Each strip is floor-/route-admitted before B:StaticRamp; the canonical service validates footprint endpoints, creates lod_static_box solids, registers them with MazeBuilder and owns exact cleanup
- Six times four uses exactly24 static boxes, separate from unchanged maxObjects18, melon cap12 and ordinary projectile budgets
- Ramp yaw is outward ascent:270/90 for south/north and180/0 for west/east. Existing broad center remains at lower floor elevation. Segmented rim intentionally preserves traversable gaps
- No-room geometry admissions leave no misleading partial module record and never block ordinary boss/progression admission

### Actual Powder Yard admission

- Two permanent solid concrete barriers at center offsets(-230,-180) and(+230,+180), native collision radius65 and center lifted65 (actual ground-to130-unit-height cube); model props_c17/concrete_barrier001a
- Two permanent solid rack shelves at(-430,+330) and(+430,-330), radius45/center+45,mass120; model props_c17/FurnitureShelf001a
- Each rack visibly contains a harmless stock drum: props_c17/oildrum001,scale.55,center rack+32,hp0,nonsolid,permanent,cosmetic; these cannot become explosive resources
- All four solid islands have nativeHP0 (indestructible), no Push, no damage/use behavior, permanent lifetime; each placement validates the accumulated solid-position set at radius+35 and remains at least180 from the authored safe anchor
- Two actual loading ramps at center offsets(-450,-400),(+450,+400),yaw0/180,width180,length240,height40,4steps of10units. Floor and route validation radius125; safe-anchor clearance190. Explicit tests prove ramp footprints do not intersect the solid barrier/rack footprints
- Eight static boxes remain under separate24 cap. Object budget rises16→22 solely to preserve original12 lesser barrels+4 spare slots while reserving6 permanent scenery objects. No active attack-population increase


## Shared spatial and lifecycle choices

- Eight ground-sector anchors at 45-degree intervals, inset to 35% of actual ground-court X/Y spans from midpoint. Ground-point membership tolerance 32 units; use `B:Floor`, falling back to an existing legal point. This avoids upper/lower lexical-point clustering. Sector eight is reserved safe/dry space.
- These four resource bosses use the default 60%/25% common health phase transitions; Melf, Button and Joilette retain their authored special phase conditions. All pending work uses the exact-owner common queue. Pause cancels stale attacks, never resets phase, healing stock, jam, cleared drains or collected shopping inventory. Remaining uncommitted shopping purchases retelegraph after return.
- Shared runtime budgets additionally cap every admission. Object budget below includes permanent geometry, projectiles and zones. No arbitrary timers, random globals, world scans, directly spawned hostiles, private damage loops or Jail Key grants.
- Charge completion receives optional fourth collision-trace argument. Moshi uses `lateralArc` (signed horizontal curvature), not vertical `arc`. Bounce motion uses bounded common `height`. These service extensions were coordinated with framework lead.
- All cosmetic death objects set `cosmetic=true`, have no damage, collision or use authority. Optional `deathDestination` snapshot lets dead-body presentation end at a cart corral/vending machine. Native corpse/ghost render transforms remain client-only.


## Ollie the Trolly

Descriptor: base HP 920, normal speed 150, model scale 1.45, actor hull±32X/±24Y/0–78Z, object cap 20, ordinary Cart Crab cap 3, 6×5 checkout court. Phase names are the exact authored three. Two 28-unit-radius route-validated shelving obstacles (validation radius 30), two nonblocking cart corral models, six destructible loose-stock objects occupy predefined route sectors 2/4/6. Loose stock: HP 12, radius 12, mass 8, 14-unit floor offset and alternating 42-unit lateral offset. Loose stock is pushable and never becomes an ordinary reward actor.

Basket catalog:

| Purchase | Count | Speed | Mass | Gravity | Lifetime | Damage / Push | Other |
|---|---:|---:|---:|---:|---:|---|---|
| Soup Can Barrage | 3 | 520 | 3 | 220 | 3 s | 9 / 0 | 32-unit fan spacing; early break |
| Bowling Ball | 1 | 420 | 42 | 100 | 5 s | 22 / 210 | radius 15; one bounce; does not break immediately |
| Angry Melon | 1 | 380 | 12 | 390 | 4 s | 15 / 0 | 105 splash radius |
| Explosive Purchase | 1 | 320 | 18 | 450 | 5 s | 20 / 0 | fuse 2.1 s; splash radius 135; does not break immediately |
| Bad Groceries | 1 zone | — | — | — | 5 s | 7 Poison / 0 | radius 120, warning .7 s, tick 1 s, >240 from reserved safe anchor |
| Cart Full of Crabs | up to 2 | ordinary AI | ordinary | ordinary | ordinary | native Big Crab attacks | no more than 3 active; `manual=false`; visual scale .65 |
| Spring-Loaded Prop | 1 | 720 | 16 | 100 | 2.5 s | 16 / 165 | fast near-flat throw |
| Mystery Bag | 2 known purchases | catalog | catalog | catalog | catalog | catalog | remix of explosive/melon/ball; isolated deterministic stream; only one high-intensity sequence |

Projectile common values: launch height 72, ordinary radius 11, projectile HP 10, upward impulse gravity×.35; target elevation +20. Rummage warning 1.15 s, default target warning radius 65, reload 1.4 s, action reservation 2.55 s. Exposed ball/explosive: height 88, HP 16, mass 1, lifespan 1.5 s. Destroying the exposed purchase cancels its launch exactly once and staggers 2 s; explosive backfire self-damage 16, subject to common nonlethal/diminishing cap.

Shopping Spree first eligible at 22 s, subsequent 34 s; route speed 220, steering response 3.5, 10 s collection deadline, waypoint reach radius 100, pickup radius 170. Collected set is frozen; sequential pulls every 1.8 s, plus 2 s terminal reservation. Heroes can destroy stock before collection. Empty basket: 3 s stagger. Pausing preserves uncommitted inventory, with new warnings on resume.

Price Check first eligible at 12 s, repeats after 18 s, holds one exact Hero binding for 3.5 s, speed 260, steering response 4 (1.8 when damaged), followed by charge to a frozen point. Normal charges: warning 1.2 s, width 70, speed 440, damage 16/Push260, recovery 2 s. Damaged Cart Crash: speed 650, damage24/Push260, every third ordinary attack; entering a designated corral within145 grants4 s stagger. Phase-three pursuit: speed205, steering response1.5 (normal4), so increased straight speed genuinely worsens turning. Attack cadence4.5 s/3.8 s in phase3. Phase-one catalog cans→ball→spring→explosive; later rotates seven outcomes; phase3 every fourth non-crash purchase is Mystery Bag. Mystery starts at .5+1.3/2.6 s, total high-intensity reservation6 s. Harmless expired-coupon dud is an isolated1/16 draw and gives2.5 s free window.

Death: nearest corral becomes `deathDestination`; cart veers for1 s, tips over1 s; break sound and THANK YOU FOR SHOPPING at1 s. Authored reachable key drop is corral+75X, validated or center fallback. Client cart face, stock rummage, wheel wobble and tilt are bounded render primitives, no extra entities.


## Crystal Bepis

Descriptor: base HP1000, speed145, scale1.1, object cap18, no adds, 6×5 break room. Phase3 exact caption DIET CRYSTAL; phase1/2 descriptive labels Refreshingly Toxic/Six-Pack Problem are presentation tuning. One nonblocking permanent vending machine at sector2; four successful drinks maximum per encounter. Stock and one pending jam persist across phases/pause. Hold E1.5 s jams exactly one reaching/dispensing attempt. Jam does not stack, consume stock, permanently disable the machine or itself complete the encounter. Jammed arrival: stagger3 s, recovery3 s, 4 s furious window with1.2 damage multiplier.

Vending: first thirst18 s, next attempt22 s after run starts (16 s in phase3), sprint300, steering response5, stop radius62/reach radius70, deadline8 s. Movement blockage accumulates with dt and cancels at2 s; unblocked time reduces it at1:1. Actual resolved damage builds focused interruption threshold6.5% maximum HP inside a rolling1.4 s window. One trivial hit cannot interrupt. Interrupted run:2 s stagger/recovery; successful drink:9% maximum HP, reduced to5% in phase3, capped by native max HP, then2.5 s recovery. Phase3 buff lasts7 s, movement185 vs145, attack cadence2.1 vs2.9 s; setting a new end time is nonstacking. Maximum nominal total healing is36% pre-Diet or20% if all drinks are Diet. Stock reaches SOLD OUT permanently.

Poison vocabulary:
- Bepis Toss: speed390, added up velocity210, gravity420, damage11, radius95 splash
- Fastball: speed720, gravity60, damage15, no splash
- Can Skip: speed560, gravity170, damage11, Push30, two bounces, no splash
- All cans: height60, target elevation24, mass2, radius8, HP7, life4 s; throws warn .9 s, radius65
- Six-Pack: exactly6 cans at .16 s intervals, 65-unit3×2 scatter, each own warning
- Shaken Can: radius110, warning.75 s, life4 s, damage7 Poison each1 s; reserved safe-space margin radius+90
- Soda Pop: .8 s warning, radius145, damage12 Poison/Push180; selected when target within125
- Soda Fountain: three60-wide lanes from fixed origin, endpoints380 forward and±110 lateral, delays .9/1.55/2.2 s, .6 s life/.65 s interval, damage10 Poison; skips reserved safe-space lanes
- CRYSTAL CLEAR: every second phase2/3 vending run, four premarked sector3–6 spray zones, radius95, life4.5 s; player may chase, detour, interrupt or pre-jam. Normal pending ranged commitments are cancelled when the run starts
- Initial attack2 s; movement between attacks uses ground sectors and steering response4; phase/pause defer attack2 s and next thirst at least3 s

Death destination machine+80X; model slumps over1 s, SOLD OUT then THANK YOU at1.5 s; one harmless can (life4, mass1, gravity350, velocity35X) dispenses. Authored vending-return key position machine+80X validated or center fallback.


## Ray D. Aitor

Descriptor: base HP1250, speed110, scale1.7, actor hull±24X/±45Y/0–90Z, object cap18, no adds, 6×6 boiler-room request (framework odd-depth normalization applies). Two permanent relief levers at sectors3/6, two nonblocking pipe manifolds at+45Z, two route-validated permanent concrete covers at sectors1/5 (radius42, validation45). Radiator glow states0–3, rattle, alarm and HUD mode communicate heat rather than a numerical pressure UI.

Pressure: starts0; rises5/s normally or8/s in REDLINE, plus14 per attack/18 REDLINE. At100, ordinary attacks stop. Emergency Vent:3 s warning followed by4 s danger; four candidate115-radius sectors, reserved safe sector excluded with radius+100 distance. Safe opening warning7 s/radius90. Native heat packet9/Push35 each1 s. After vent, all remaining vent zones retire. Cooled state:7 s normally/9 s REDLINE, damage multiplier1.3, movement55/steering1.5;3 s stagger, or5 s after PIPE DOWN. Reheating delays next attack1.5 s.

Relief E: hold.5 s, cooldown18 s, clears hot-zone origins within280. During warning/vent shortens vent end by1.5 s per lever, never earlier than now+.8; adds1.5 s cooled duration, maximum3. During cooled mode, may add1.5 s with same3 s cap. Otherwise relieves12 pressure. No valve is mandatory.

Ordinary cadence3.8 s, initial delay2 s; movement steering2.5. Shared heat zones reserve safe-anchor margin radius+100, including line-segment safe-gap testing.
- Steam Jet:48 half-width input (96 lane width), warning1.1, duration1
- Hot Pipe:radius145, warning.95, damage18 Fire/Push90
- Radiator Ram:warning1.25, speed390, width80, damage23 Physical/Push230; miss2.8 s stagger/recovery, hit1.5 s recovery
- Thermal Wake:radius55/width110, delay1.6, life4, fixed ram-origin→destination lane
- Heated Floor:radius115, delay1.2, life5
- Detached Pipe:windup1.3, warning radius80, speed420 plus180Z, gravity390, mass36, radius16, HP20, one bounce, life4, damage18 Fire/Push115, launch height70
- Burst Main:two100-wide lanes, delays1.2/2.1, duration1.2
- Pipe Sweep:380-wide lateral extent positioned140 ahead, width110, warning1.5, duration.8; permits retreat/close approach/flank rather than a full unavoidable ring
- Pipe Bombardment:exactly3 detached pipes under shared budget
- Pressure Hop: one shared warned charge, warning1.1s, speed280, arc height95, width70, minimum arc duration1.3s, maximum pending watchdog8s. Only the actual non-cancelled landing callback emits the radius115 Physical18/Push180 pulse. Cancellation gives no impact; recovery1.8s. Source/target leases persist through the full commitment
- REDLINE close leaks:radius85, warning.8, life2, every5 s
- PIPE DOWN:eligible36 s, repeats40 s;3 waves1.8 s apart; perimeter positions scale1.15−wave×.22 toward center; radius85/warning1/life1.1; sequence ends at7 s with full major vent. The safe sector remains reserved

Pause discards hop/charge commitments; interrupted vent restarts from pressure100 with fresh warning; interrupted PIPE DOWN likewise becomes a freshly warned vent. Death pressure/glow0, tiny hiss, one harmless falling pipe (life3, velocity40X80Z, gravity400); tip at1 s. KeyPosition is safe death-position+70X near fins, else center.


## Moshi the Washy

Descriptor: base HP1400, speed105, scale1.7, actor hull±45X/±45Y/0–95Z, object cap22, no adds, 6×6 upper-gallery laundromat request. Three optional jammed drains (sectors2/4/6, HP24, hold E.8 s) and two route-validated reinforced charge stops (sectors1/5, radius45, validation50). Drain and stop placements do not overlap. Native upper routes supplement two real raised dry platforms; the first platform replaces sector8 as the advertised dry anchor.

Authored drainage embodiment (final review repair): one central nonblocking `models/hunter/plates/plate1x1.mdl` grate at center+2Z, scale2.4; three nonblocking permanent channel objects (plate scale.08) connect that center to the optional jammed drain positions, with networked endpoints and bounded 26-wide channel rendering. Jammed drain covers now use real plate/grate models (scale1.1, radius22, +3Z) instead of generic levers. Central grate render half-size57, covers half-size25, nine metal grate bars each; channels have eight transverse bars each. The brown clog remains visible until the cover is cleared. These objects have no hidden damage or blocking collision.

Two dry islands lie at80% of the center→sector8/sector3 displacement, subject to four-corner supported-floor checks and a conservative165-radius alternate-route proof. Each footprint is256×200 units and height24. Each consists of two opposed128×200 StaticRamps, yaw0/180, each with four32-long treads and six-unit rises. The top landing is64×200; both opposing approaches are walkable without a special movement/jump ability. Four ramps use exactly16 encounter-owned `lod_static_box` entities from the separate shared24-static-box ceiling. Admission reserves room for an entire pair before spawning. Two nonblocking owned markers at+25Z label the dry landing. Geometry remains through pause/phase changes and is removed by exact common encounter cleanup. Total permanent ordinary-object count is11 (3 covers,3 channels,1 center grate,2 landing markers,2 reinforced stops), leaving11 of the22 ordinary object/hazard slots for active mechanics; the16 static supports use the separate geometry budget.

Water/suds admission excludes each platform footprint expanded by hazard radius+32. Rinse segments remain at least245 from every platform center, conservatively protecting its full footprint. The safe platforms do not depend on opening any jammed drain. Client drainage drawing is dispatched per known owned object, allocates no models and performs no world scan. Long strip/landing render bounds are expanded once to match the custom geometry. No resource module defines an `onImpact` override, so every damaging projectile retains the shared Hero-impact resolver.

Core cycle: Fill4 s → Wash4.5 s → Spin5 s → Drain3.5 s → next Fill. Stage held while a punish window is active. Fill lays3 candidate zones; water radius125/traction.72, suds radius110/traction.48. Both warn.8, last at most11 s, interval1; safe-space exclusion radius+110. Heavy Load uses a suds zone on alternating fill placement. Drain clears all owned wet zones. Clearing a drain by E or shooting destroys nearby water/suds within250 and prevents future local filling; no drain required for progression. Pause clears traction/debris and resets transient cycle to Drain2 s, preserving phase and cleared drains.

Debris catalog (launch height70, vertical impulse170):

| Load | Speed | Mass | Gravity | Radius | Life | Warning | Damage/Push | Durability/bounce |
|---|---:|---:|---:|---:|---:|---:|---|---|
| Light | 540 | 3 | 260 | 9 | 3 | .8 | 9/35 | HP10, breaks |
| Medium | 410 | 15 | 390 | 13 | 4 | 1.1 | 15/90 | HP10, breaks |
| Heavy | 300 | 42 | 470 | 19 | 4.5 | 1.6 | 23/160 | HP24, one bounce |

Wash ejects every1.8 s, phase1 light/medium, later rotates all3 classes. Each shows named/color-coded load and warning radius4×projectile radius. Open drum lasts tell+.8 around ejection,1.4 on entering Wash,2 on Drain and during recovery. A hit within58 of forward34/up48 drum center gains1.2 damage only while open; rest of body remains normally vulnerable.

Spin: phase1 straight warning1.2, speed440, width75, damage20/Push230. Phase2/3 Off-Balance warning1.5, frozen signed lateral curvature±55 (alternating cycles), phase3 speed570. Miss2.8 s skid/wobble recovery; Hero hit1.3; designated reinforced geometry collision within150 produces4.5 s Spin-Out, independent of whether a Hero was hit. All charge recovery requests go through bounded common stagger.

Violent Spin: phase3, .8 s/radius150 warning, exactly3 orbit projectiles around radius110/height65, initial tangential230, angular progression2.2rad/s, velocity capped360, orbit1.8 s then finite departure, total life3.5, mass3, radius10, HP12, damage10/Push45. Ordinary phase3 charge starts1.4 s after spin begins. Walking Washer during Fill chooses new sector every1.2 s, speed180, bounce height45, steering2.5.

THE LOST SOCK occurs on alternating phase3 spin cycles: one harmless projectile, scale.15, mass.1 (common mass floor applies), radius3, life2, velocity110X130Z, gravity280; pause1.15 s, then massive off-angle charge. Offset100 units along fixed horizontal perpendicular, warning.85, speed680, width105, damage28/Push230. No target tracking after commitment.

RINSE CYCLE on phase2/3 Drain:3 candidate directional65-wide water lanes with warning.9/1.7/2.5, duration.6, interval.7, traction.8 and one canonical directional Push105 per admitted tick; no damage or duplicate radial Push. Segment distance175 preserves reserved dry space;245 from both actual raised-platform centers preserves their footprint.

Death: final shake/spin, DING at.8, door opens,3 harmless laundry pieces (life3, scale.3, gravity300, modest±35X70Y70Z); last harmless sock at1.6 (life3, scale.15, gravity250, velocity40X30Y80Z), then client tip after1.6. Cosmetic props originate at actual washer death position. No special arena key-location override is authored, so shared center key recovery remains.


## Melf

- 6×6 court, upper routes; 24 shared owned-object slots; 4 additional living-body allowance. Original committed party identities only.
- One kit per frozen Hero. Safe model/color/name/class/representative weapon, owned supported Forms/Contents, applicable elemental identity and class-derived profile. Ability scores copied at commitment and bounded 3–24. Canonical progression recomputation starts an AI profile from the scores, retaining class rules while excluding inventories, currencies, menu capabilities, resurrection, Summon Card, DFT, Time Management, capstones and copied utility-derived fields.
- At most two actually owned/executable signatures, chosen in frozen feat order: Bash/Walloper through canonical CrowbarDamageProfile; firearm cadence through canonical RateOfFireMultiplier; Mana Barrier ladder and True Faith/Mind Over Matter through native incoming mitigation; Aggressive Personality/Self-Actualization through native outgoing damage. Unsupported signatures are deliberately omitted rather than copied as inert ownership.
- Supported copied Forms: Cone, Blast, Beam, Bomb, Missile, Bolt, Super Ball, Watermelon and Wall. Summon is excluded as unsupported; the representative weapon remains available if no supported form or insufficient Magic. Costs use MagicForms.TotalBaseCost and OffensiveMagicCost; pools and synchronization use native Magic. Elements go through the framework's EnemyRoster/CombatRolls/MagicForms context, with no private status loop.
- Evil body HP = clamp(original max HP×1.5,150,260). Skeleton body HP = ceil(evil HP×0.85). Giant HP = 780×(1+0.35×(frozen party−1)). Native actor Health is authoritative for every body; there is no shadow aggregate HP pool.
- First primary is configured in place. Other bodies use SpawnActor; sealed native deaths transfer primary to a surviving body or begin the next stage after 1.8 seconds. Failed spawns retry through Think, without rerolling kits or giant selection. Giant identity is selected once with independent melf_giant_identity RNG. Late joins never add kits.
- Normal body speed 175, skeleton 230; ranged representative range 600, Fighter close range 120; Rogue routes toward a point 95 units behind the selected Hero. Phase 1 initially prefers original identity; phase 2 uses current nearest eligible Hero.
- Attack cadence 3s evil/2.1s skeleton/4.5s giant, divided only by applicable native firearm cadence. Physical warnings 1.1s/.75s skeleton; fixed bullet lane 38-unit tolerance and melee forward arc dot≥.65, current LOS required. Fighter native Push request 90, giant 180.
- Bone Break: accepted wall-crush context, major incoming damage≥35, force magnitude≥450, or a fresh canonical Pushback receipt with moved≥96/crushed. Break lasts 1.8s, with 8s admission cooldown; movement and pending body attack stop. Client pose and separated bone segments provide the disarticulation tell.
- Spell warning 1.1s; giant 1.65s. Radius 78/135. Beam width24/65; cone range240/360 and dot>.82, one packet per Hero. Wall width20, length150/260, extra delay.4s, life3s, interval1s, safe gap160.
- Spell projectiles: ordinary speed720, Bomb380 +180 upward, Missile450. Gravity350 for Bomb/Watermelon, otherwise0; lifetime4s; radius8/18; mass8. Super Ball3 bounces, Watermelon2; Bomb fuse2s; Bomb/Missile radius78/135. Missile steering interpolates ≤.18 per service step toward its bound original Hero life; lost life retains last aim, never reacquires a replacement.
- Giant Fighter: 1.6s slam radius135; 1.8s sweep width135; 1.4s cone Push within340 units/dot>.75/request220.
- Giant Rogue: 1.2s behind-party tell and 2.2s bounded move to supported point220 behind target at330 speed; weapon rain three65-radius marks spaced105, released1.6/2.0/2.4s; sequential shadows radius115, delay1.8/2.6/3.4s, life1.2s, safe gap180.
- Every fourth giant action is Stop Hitting Yourself: original Hero when still eligible, otherwise current nearest threat; frozen target and route; warning2s, speed390, width90, recovery2.5s. Four nonblocking mirror pylons; crossing a pylon within115 during actual completed charge segment reflects min(4.5% max HP,45), nonlethal and subject to shared total self-damage cap, plus3s native stagger.
- Giant visual size3.2 through NW renderer only; no native SetModelScale. Explicit locomotion hull84×84×210 and combat bounds92×92×220. Ordinary bounds32×32×72; combat28×28×72.
- Defeat: primary giant only; fractured core cosmetic, mirror shards/client fracture pose and YOU DEFEATED YOURSELF. No Hector/Director Heart/finale authority.


## Button for Punishment

### Body, health and successful-press counts

The registered primary ID is `button`, titled **Button for Punishment**, represented by stock `models/props_lab/reciever01b.mdl`. Its descriptor has base HP **800**, speed **0**, visual size **1**, `useOnly=true`, `manualPhase=true`, `deferKey=true`, a **24** combined owned-object/hazard budget and **6** additional living-actor slots. The primary is a manual, stationary `lod_hostile`, stopped at encounter start. It does not receive a separate custom locomotion hull; the shared default is mins **(−16,−16,0)** and maxs **(16,16,72)**. There is no second or proxy boss-health pool.

The number **800 is the progression starting/base HP, not a guarantee that every generated encounter displays exactly 800 maximum HP**. The normal monster progression authority first derives health from that starting value, generated level/class/abilities/hit dice and applicable ordinary feat effects. If that result is Hprogression, the common boss attachment sets starting native maximum HP to `max(1, floor(Hprogression × (1 + 0.2 × (P−1)) + 0.5))`, where committed party size P is clamped to **1–4**. Thus the common party multiplier is **1.0 / 1.2 / 1.4 / 1.6**. Button has no bespoke health-dice profile or independent HP jitter; authored boss variance fixes its random body-size multiplier at **1**. The Button module does not disable otherwise applicable shared class/feat regeneration. Its press count remains authoritative for round progression regardless of those ordinary HP effects, and its final use removes all remaining HP.

At Start, record H0 = the primary's then-current native GetMaxHealth(). Required successful health segments are `N = 8 + max(0,P−1)`, giving **8 / 9 / 10 / 11** successful cycles for parties of **1 / 2 / 3 / 4**. There are **N−1 ordinary successful cycles**, followed by **one Big Red Button cycle**. The separate post-defeat **JAIL KEY** press is additional; it does not increment the combat success count. A paired cycle requires two physical real-button uses but counts as only one successful cycle/health segment. Fakes and timed-out attempts never count.

The stored segment amount is exactly `H0/N`: **1/8 (12.5%)**, **1/9 (11.111…%)**, **1/10 (10%)** or **1/11 (9.0909…%)** of the initial native maximum per successful ordinary cycle. An ordinary accepted cycle requests `min(current native Health−1, H0/N)`, keeping the body nonlethal. The Big Red cycle requests its entire current native Health. The shared UseDamage method consumes the unique token `button:<cycle number>`, records combat attribution, subtracts the admitted amount directly from canonical actor Health, and calls the native OnKilled path at zero. These interaction decrements are intentionally not modified by ordinary Block, Dodge, CON mitigation or Arcane Shield. No alternate damage authority, fake defeat, reward grant or direct rescue is introduced.

Ordinary weapon, Magic, explosion, status or physics damage is rejected on the primary. The module's BeforeDamage allows ordinary damage to owned nonprimary actors; obstruction enemies remain normally damageable. The primary immunity does not make its adds invulnerable.

### Arena and baseline routes

The descriptor requests **The Gauntlet**, width **7**, depth **7**, upper routes enabled. The shared arena realizes a **7×7 ground court** with an upper perimeter gallery and **two baseline stair connections**. Current common cell size is **384 world units** and level-height separation is **384**. The protected entry/jail route uses the existing locked progression graph. No pedestal or required button requires class-specific mobility.

The module gathers SafePoint-approved court positions, then performs deterministic farthest-point sampling for at most **10** pedestal destinations. The first sample maximizes squared distance from arena center; later samples maximize their minimum squared distance from already selected points. A candidate must have that distance at least **128²**. Tie order is the existing deterministic point order. The shared point list starts with **eight spread ground-sector anchors**, followed by the remaining deterministic court/gallery points. The module rejects a destination set with fewer than **8** points and also requires `ValidateRoutes(c,{},24)` before accepting the set. Therefore its realized pedestal count is **8–10**, with **10** targeted, within the authored approximate 8–12 range. It never fills missing slots with an unsafe point.

Each pedestal is a nonblocking permanent owned Object at its safe floor point, model `models/props_c17/Concrete_Barrier001a.mdl`, visual scale **0.22**, HP **0**, label **BUTTON PEDESTAL <index>**. It consumes the shared object budget. Permanent objects renew their common **60-second** expiry horizon while serviced, rather than expiring after one 60-second fight interval.

The current shared route validator uses a baseline-Hero clearance graph with **nine samples per court cell**, offsets **−96, 0, +96** on each horizontal axis. It expands existing obstacle footprints by **18** units and validates traversable edges and approaches. Button's required anchors are its chosen pedestals (or court points before that set exists). Pedestals and interactable points need a reachable approach within **105** horizontal units; active Heroes and the jail-side anchor use **150**. The module's requested obstacle radius for route admission is **24**. Ground SafePoint admission uses the ordinary **32×32×72** baseline hull, and rejects blocked/unsupported court locations.

When no adequate safe pedestal set, legal destination or required real-button entity can be admitted, the module schedules a retry after **1 second** and does not start a playable countdown with a missing mandatory objective. The module is not a path-length solver: its countdown formula below uses Euclidean destination distance, while baseline connectivity/clearance are validated separately.

### Cycle placement, count transitions and countdown

Each BeginCycle clears the preceding real/fake buttons and temporary gauntlet lane/barricade, increments the encounter cycle serial, and resets only that cycle's individual pressed-object set. It does not erase successful prior segments or reset native HP. Destination selection uses the first current eligible target's position (the shared target ordering is stable by identity); if none is available, it falls back to the last stored destination and then center.

Candidates exclude the preceding cycle's first real pedestal, explicit exclusions and any point no longer SafePoint-valid. Sort by decreasing squared distance from the current origin, ties by pedestal index. Ordinary selection draws uniformly from ranks **1 through ceil(candidate count/2)** using the isolated deterministic **button_destination** stream. This means the farther half of currently admissible points, not arbitrary nearby points. The final Big Red Button chooses the single farthest remaining admissible point. The no-immediate-repeat exclusion remains in force for the final choice as well.

Phase names are **Press Here**, **Obstacle Course**, **PUNISHMENT**. The module explicitly sets phase from successful cycles divided by N, rather than boss HP: phase 2 begins at `successes/N ≥ 0.30`; phase 3 at `successes/N ≥ 0.65`. The resulting entry counts are:

- P=1, N=8: phase 2 after **3** successful cycles; phase 3 after **6**; Big Red is success **8**
- P=2, N=9: phase 2 after **3**; phase 3 after **6**; Big Red is success **9**
- P=3, N=10: phase 2 after **3**; phase 3 after **7**; Big Red is success **10**
- P=4, N=11: phase 2 after **4**; phase 3 after **8**; Big Red is success **11**

For the first chosen real destination, let d be its three-dimensional Euclidean distance from the origin captured for this cycle. The countdown is exactly `max(phase==3 and 32 or 40, d/150 + 18)`, plus **6 seconds** when two real buttons are actually created. Thus base windows are **40 seconds** in phases 1–2 and **32 seconds** in phase 3; **150 world units/second** is a conservative traversal-time reference used only in this formula, and **18 seconds** is the extra traversal/obstruction allowance. The formula does not change any Hero's actual movement speed. Its paired allowance does not separately sum two complete paths. Successful ordinary cycles start the next cycle after **1 second**.

Each real button requests a **REAL BUTTON — E** beacon at its position, radius **72**, red **(255,55,55)**, for the cycle window. The shared Warn service clamps a single cosmetic warning's lifetime to **30 seconds**; the authoritative deadline and HUD countdown retain the full formula-derived duration. Announcements are **PRESS HERE**, **TWO REAL BUTTONS — SAME WINDOW**, or **THE BIG RED BUTTON — DO NOT PRESS**. The HUD reports `PRESSES successes/N` and the remaining time rounded up to a whole second, clamped to zero, or **NEXT BUTTON** between cycles.

At `now ≥ deadline`, the module announces **TOO SLOW**, clears that cycle's real/fake buttons and temporary lane/barricade, and retries after **1 second**. It retains previous successes, phase and native HP. The failure does not add a lasting speed, damage, add-cap or timer penalty. The cycle serial still advances on subsequent BeginCycle calls, so the optional pair cadence is based on cycle attempts rather than successful rounds.

### Real/fake button embodiment and E approach requirements

Real and fake buttons use the receiver model at pedestal floor position plus **(0,0,26)**. They are nonblocking permanent HP-0 owned interactables. Real buttons are visual scale **1**, red **(255,35,35)**, labeled **E: PRESS HERE** or **DO NOT PRESS — THE BIG RED BUTTON**. Fake buttons are visibly smaller, scale **0.65**, amber **(245,175,35)**, with explicit **FAKE — PUNISHMENT** labeling. They cannot be mistaken for another unlabeled real objective solely because of their geometry.

The common KeyPress E dispatcher selects the nearest visible, front-facing owned use object, within **110** units measured from player origin. Its facing requirement is aim dot normalized eye-to-object direction **>0.35**. A current MASK_SHOT trace must be clear or hit that exact object; starting inside blocking geometry rejects the use. ObjectUse also checks a living current Hero, exact encounter ownership, object liveness and a **0.2-second** per-object use cooldown. No hold-to-use duration is configured for these buttons.

The combat real/fake button adds its own per-player, per-life approach gate. At every module Think, it measures distance from the Hero's origin to the raised button position:

- A sample at distance **≥144** marks an outside approach and clears its pending readiness time
- Entering distance **<80**, after that outside sample and without a detected jump, sets readiness to current time plus **0.25 seconds**
- A use requires the readiness time to have elapsed and current distance **≤96**
- Sampling elapsed time has a floor of **0.01 seconds**. A displacement whose length is **greater than max(96, elapsed×600)** clears the approach and readiness state
- The **600 units/second** number is a position-jump tolerance reference, not a Hero movement-speed grant or speed cap
- Entering via a teleport/jump detected inside the approach region does not qualify. The Hero must first establish another outside sample before approaching again
- A later sample outside144 resets readiness; a stale player profile/spawn/life binding is discarded. Within the144-unit region, the implementation does not reset the stored readiness merely because the Hero has stepped back outside80, provided no jump is detected; the final96-unit use limit still applies

These checks are applied separately to every real/fake object and must also match the current cycle serial, an unexpired deadline and an unclaimed/unretired object. The key button after defeat uses the common E visibility/range gate; it is not another timed gauntlet approach test.

### Solo, co-op pair and fake-button rules

A paired cycle is considered only when all of these are true: the cycle is not final, frozen P>1, at least **two** current eligible Heroes are present, phase≥2, and cycle serial is divisible by **3**. Its second point is selected farthest from the first, excluding the first and the previous cycle's first point. The pair is admitted only if point separation is at least **256** units. If no qualifying second point exists, this attempt stays a single-button cycle. Solo always has exactly one required real button; the final cycle also always has one.

Each real object is atomically claimed on accepted use. A first use in a pair announces **ONE PRESSED — REACH THE OTHER** but removes no boss HP. When the number of distinct claimed real-object IDs equals the number of real buttons, the cycle earns exactly one success and one health decrement. The rule is both buttons within the same timer, not a frame-perfect simultaneous press, and source does not require different Heroes to perform the two uses. Expiry drops that attempt's partial pair claims without touching earlier successful cycles.

In phase 3, excluding the final Big Red cycle, the module may place **one** fake at a separate remaining legal point, using the same farther-half selection rule from the first real point. Budget or destination failure simply omits this optional fake. A valid fake press can punish only once: announce **FAKE BUTTON — PUNISHMENT**, request native **1d4+0** melee Physical damage, reference **2.5**, plus a shared Push request of **80**, then retire that fake. It does not change the real objects, deadline, success count, phase or press-health segment. Ordinary native mitigation and the shared Push resolver apply to the fake's punishment.

### Obstruction and hazard tuning

Every admitted cycle may request one narrow **OBSTACLE LANE** between canonical court points **2 and 3**. Before requesting it, the module excludes the lane if either endpoint lies within **240** units of any current real button. This explicit test is endpoint-to-button distance, not distance from the entire segment. The lane warns for **2 seconds**, then remains active **6 seconds**, checks damage at **1-second** intervals, and deals native **1d4+0** bullet Physical damage with reference **2.5**. Its requested full width is **36** in phase 1 and **54** in phases 2–3; the current shared lane resolver uses half-width for point containment, so the transverse half-widths are **18** and **27**. The spec includes `safeGap=180`; the module does not supply a bespoke geometric cutout in this lane. Safe alternate space comes from the narrow lane and validated broad court/routes. The shared zone resolver additionally restricts floor-height difference to **160**, enforces LOS/current bound Hero life/source life, and uses the normal damage pipeline.

Phase 2+ may additionally request one temporary, destroyable, pushable barricade at canonical point **5**, only after route validation with radius24. Its stock model is `models/props_junk/wood_crate001a.mdl`, scale **0.55**, native durability **20 HP**, lifetime **7 seconds**, solid collision enabled. It uses the shared default collision radius **16** and mass **10** because the module does not override them; conservative route admission uses the separately requested24-unit footprint. No full-lane unbreakable barrier is authored. Each new cycle or timeout explicitly clears this barricade and the temporary lane.

Obstruction enemy replenishment becomes eligible immediately when a cycle starts and is checked every **4 seconds** while the deadline remains active. A queue request is added when living actors with role `gauntlet_obstruction` are fewer than `min(6,2+P)`, yielding thresholds **3 / 4 / 5 / 6**. Phase1 requests ordinary **Runner**. In phases2–3, an even cycle serial requests **Blitzer**, an odd cycle serial requests **Soldier**. Spawn destination is canonical point **6**; `manual=false` preserves their ordinary native AI, movement, attack definitions, progression, damage, XP and loot. Button does not invent separate add stats, speeds or reward rules.

The threshold checks living obstruction actors, not outstanding queued requests. The common hard admission cap remains **six additional living actors**, subject also to the global **96-active-hostile** ceiling and reservations. The shared add queue is capped at **16** entries; a request expires after **30 seconds** and otherwise retries under normal service/admission. Existing obstruction enemies are not removed after each ordinary success or timeout; they persist and replenish within those shared limits, so the court cannot be permanently sterilized. All module Objects and Zones, including the permanent pedestals, compete within the combined **24**-record live budget.

### Pause, defeat, recovery and Jail Key

On no-Hero/freeze pause, the module saves remaining countdown once and clears all real/fake per-life approach states. At its next active Think it restores deadline to `resume time + saved remaining time`, then clears the pause marker. Successful segment count, phase, native HP, current real/fake object claims and post-defeat receipt remain encounter-owned. Shared quiescence cancels transient offensive work and pauses further attacks; losing the last Hero does not itself reset the encounter. A replaced Hero must establish a fresh approach binding.

Before consuming the final Big Red use, the module clears its timed real/fake buttons and temporary lane/barricade and retires actors specifically owned as `gauntlet_obstruction`. It then uses the exact-once interaction debit for all remaining native HP. Only the legitimate current-primary native OnKilled receipt can complete the boss. Common completion seals `c.receipt`, marks the encounter dead, clears pending offensive/add work, retires remaining subordinate actors/objects through the deferred native cleanup path, opens the boss entry lock, and enters the existing TAKE_JAIL_KEY objective stage. The configured caption is **GAUNTLET SHUTDOWN — PRESS JAIL KEY**. No custom death-duration override is configured, so registration supplies the shared **4-second** death-scene/key delay. `deferKey=true` additionally keeps the key unavailable until the small Jail Key button has been used; both conditions must be satisfied.

Defeat clears any remaining cycle state, resets the key-button record and explicitly sets `keyReady=false`. During PostDefeat, if no live key button exists, the module retries one nonblocking permanent use Object with role **key_button** and kind **gauntlet_key_button** at canonical center plus **(0,0,24)**. It uses the receiver model, visual scale **0.4**, HP **0**, label **E: JAIL KEY**. The role is the shared explicit post-defeat interaction exception; it is not an offensive actor.

A living eligible Hero's valid use requires a dead encounter, a sealed receipt, no prior key-ready flag and an unclaimed exact object. It atomically claims that object, sets `keyReady=true`, announces **THANK YOU FOR YOUR COOPERATION**, calls the one shared EnsureKey authority, then retires the small button. Before readiness, the HUD says **E: JAIL KEY**; afterward it says **THANK YOU FOR YOUR COOPERATION**. Repeated/stale uses cannot issue another readiness transition. If object admission fails or the unpressed key button is lost, PostDefeat retries without recreating the boss. Once ready, PostDefeat continues EnsureKey so failed key admission or a lost uncollected key remains recoverable.

EnsureKey requires exact current encounter identity, legitimate defeat receipt, readiness, elapsed keyAt and no collected run JailKey. It reuses an existing valid JailKeyEntity rather than spawning a duplicate. Button has no special KeyPosition callback: it uses the safe canonical center, with shared safe-center fallback, and adds configured **KeycardHeight=40** world units for the native key entity. The key carries the same encounter/defeat receipt. Boss defeat, Big Red use and small-key-button use do not perform rescue: normal living-Hero key collection, jail opening and current rescue-target interaction remain required.

Every body, add, pedestal, button and hazard is owned by this exact encounter/run/graph/seed/epoch identity. A removed native primary is recovered by the shared retained-body path with saved HP/max rather than being treated as defeat; the Button's `c.data` success/phase/deadline state is not recreated. Timer failure, reset, cleanup or replaced encounter identity revokes old callbacks/objects and retires owned work; equal numeric seeds do not authorize old work in another encounter. There are no module-private timers, unseeded random rolls or direct progression/reward grants.

### Additional client embodiment

The Button client renderer uses existing draw primitives and no model allocation. It draws a dark **(45,48,53)** base box relative to primary origin+(0,0,12), with mins **(−22,−18,−8)** and maxs **(22,18,4)**. The red button is a sphere of radius **15**, with **12×6** tessellation, offset a further **8** units upward while alive or **1** unit after defeat. Alive color is **(245,35,35)**; defeated color is **(75,30,30)**. Destination interaction models, beacon captions, server countdown and fake color/size remain the meaningful gameplay cues.

## Joilette

- 6×6 court, max22 objects/max7 Neils, primary HP950/speed100/visual3. BDD has a route-validated95-radius solid impact collider for the Cleaner; missing collider admissions retry. True primary BeforeDamage denial while hits<3. No fake damage absorption or resettable HP proxy. Third distinct Cleaner hit alone ends BDD.
- Three stable encounter-owned Cleaner slots, each generation bound. Initial opportunities scheduled at0/6/12s; loss/budget denial retries1s. Every pending slot has deterministic future opportunity; RNG never withholds the final Cleaner.
- Cleaner Neil uses archetype neil, ordinary AI,45% ordinary native HP and green cargo label. Native shared death/XP/loot continue; module only queues the unique encounter drop after native death. Bomb Neil uses same normal authority, orange BOMB label and an obvious delayed dropped explosive. Neither attaches to NeilHunt or issues Black Keycards.
- Cleaner bottle is a nonblocking, durable mandatory encounter Object. Pickup is E; each Hero may carry one. Receipt records exact target/profile/life binding; body death/disconnect/invalid location restores safe pickup. LMB uses D.PrimaryInput and throws only the carried individual; no separate weapon, global inventory, economy or arbitrary native timer.
- Throwable speed650 +70 up, gravity300, radius8, mass1, life5s, no bounce/damage. Impact on exact primary or exact live BDD object consumes once. Miss/expiry/lost projectile never increments hits and requeues that slot. Budget rejection leaves the held item intact. Duplicate/reentrant/stale-generation hits are inert. Hit progress is encounter-owned and independent of player reconnect.
- First hit moves Occupied→Out of Order and cracks BDD; third announces THIRD FLUSH, clears all Cleaner/BDD work and enters EXPOSED. Cleaner scheduling ends permanently for that encounter. Progress exactly0/3,1/3,2/3,3/3.
- Base attack interval4s, exposed2.6s. Neil cadence8s/5s exposed; native ceiling7 includes Cleaner Neils. One final rush grants at most2 extra ordinary Neils, attempted under the same ceiling.
- Flush Bomb mark1.5s (exposed1s); Double/Rapid second mark1.9s. Bomb falls from170 at−120/gravity400, radius10, life3, fuse1.3, blast100, durability8/mass4, native2d6 physical.
- Lid Slam/Chatter radius95, warn1s, ordinary life.2s/exposed1.1s, interval.55s, native2d5/Push95. Clogged Bomb2.4s delay. Overflow radius115, warn1.5s, life5s, interval1s, traction.78/Push25/native1d3, safe gap200.
- Toilet Paper Lash width45, warn1.2s, life.2s, native1d4/Push100. Exposed Toilet Charge warns1.3s, speed320, width80, recovery2s, native2d6/Push110.
- Defeat-only tiny Neil cosmetic and client implosion/flush spiral, BATHROOM SECURED. KeyPosition requests the reachable floor beneath the authored bowl, with common safe center fallback. Only exposed legitimate primary death may complete.


## Mirror body recovery tuning

Melf now retains one durable body record per frozen identity per phase, including exact encounter owner, native incarnation serial, last living HP/max/position and the bounded native Magic profile. Module AfterDamage and Think refresh snapshots. ActorReplaced rebinds the existing primary record to the framework-restored native actor and HP; no roster slot, receipt or giant selection is added. Support removal retries the normal SpawnActor boundary at most once per second at the same validated location, preserving all snapshots even across partial native creation failures. Missing support identities remain outstanding and block stage advancement until genuinely defeated. A recovered support can become primary only after its predecessor's legitimate death. Stale warning/projectile/charge callbacks retain their old native source incarnation and cannot execute on a replacement body. The common framework must snapshot HP/max/position immediately in ReplacePrimary (lead informed).



## Chuck Chuck Bo Buck

- Base archetype HP 1500; citizen scale 1.15; ground speed 145; ground turn blend 2.2. Actor-derived final HP still uses the common native progression/party/variance path.
- Phases: Fresh Cut → Heavy Timber → LUMBER LIQUIDATION. Initial wood delay 1.2s; phase-transition delay 1.3s. Phase 1 chooses plank/timber; phases 2/3 choose plank/timber/panel, independently deterministic. Failed admission waits .6s. Wind-up stops authored movement; recovery may reposition until .3s before next attack.
- Simultaneous wood projectiles 7; settled panels 3; total encounter object/zone budget 24; one owned support actor reserved.
- Citizen selection freezes among nine stock Group01 males and five females (01/02/03/04/06). Primary recovery restores the frozen model and beaver presentation rather than rerolling.

| Wood | Mass | Initial directional speed / added Z | Gravity | Radius | HP | Lifetime | Bounces | Damage / Push | Tell / recovery |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Plank | 9 | 720 /35 |120|13|14|3s|1|12 /105|.85s /1.1s|
| Timber |65|385 /220|380|26|35|5s|1|23 /240|1.55s /1.8s|
| Panel |22|285 /95|110|42|24|4s|0|9 /80|1.4s /1.65s|

- Plank breaks on admitted Hero impact; shallow world ricochet has one allowance, then breakage.
- Timber first ground hit becomes a 190-speed gravity-free planar roll lasting at most 1.5 additional seconds. Second contacts remain bounded by the common hit budget. Timber scale 1.3.
- Panel visibly tumbles at 65 degrees/s, then settles into a route-validated breakable solid object: HP24, mass22, radius46, lifetime5s, scale1.8. Admission validation uses radius65. Its client geometry is a broad wood sheet, distinct from timber's thick section and plank's thin rectangular section.
- Client embodiment draws two muzzle cheeks, broad dark nose, ears and two incisors over the stock citizen; a nine-slice rounded, flattened paddle behind the waist has twelve crosshatch lines. No Workshop models or dynamic client-model allocations.
- Chuck alone retains first-class name/title/HP/receipt. His legitimate native primary death invokes only the common post-boss key/jail flow; all Jane work belongs to his encounter and is retired by the shared completion cleanup.


## Jane the Propane (support)

- Registered support ID `jane_propane`; stock propane tank; base HP650, speed140, visual scale2.1. No official roster/level mapping or HUD boss bar. Initial support admission retries at 1s if native creation fails. Once admitted, Jane is never re-admitted; death/invalid native source means neutralization and source-owned hazard cancellation.
- Initial attack delay2.5s, phase delay2s. Ordinary cadence5s; phase3 cadence4.5s. Phases track Chuck and begin the newly introduced portion of their repertoire. Gas-jet skating speed120, phase3 155, turn blend1.1; controlled short-hop mode speed235/height65/turn1.4 after a .75s lateral-jet tell.
- Own arena props: two cylinder racks with rendered pipe/manifold/tank geometry, two route-validated permanent blast walls, and readable NO SMOKING/valve labels. These count toward the 24 total object budget.
- Pressure Jet: lane full-width65, tell1s, lifetime.4s, interval.5s, physical7, Push245.
- Flame Burst: committed length380, width80, tell1.25s, life.35s, interval.4s, Fire12. Blowtorch: five preannounced narrow lanes, width42, angle offsets [-.32,-.16,0,.16,.32] radians; each begins .32s after previous, Fire9, same finite .35s pass. All use the shared Fire pipeline.
- Propane Dash: tell1.15s, straight speed430, width52, physical10/Push160, recovery1.3s. Phase3 adds controlled lateral gas-jet hop after the dash.

### Cylinder state machine and valve interaction

- At most six live cylinders. Radius15, mass24, HP28, initial height18, lifetime10s, one native bounce, no impact explosion. Stable/lightly leaking cylinders accept shared Push; ignited/critical tanks resist punts.
- Nominal timetable from creation: Stable → Leaking at1.4s → Ignited at4.1s → Critical at5.1s → blast6.4s. At least1s separates first visible leak and ignition. Critical entry always grants at least.8s of explicit blast warning.
- State, color, label and pushability actually change. Stable blue-grey; Leaking yellow-green; Ignited orange; Critical red. States are not purely captions.
- Blast: radius135, shared blast17/Push210. Shooting/destroying a cylinder is a safe vent, never an unannounced blast.
- Valve aim region: within15 units of object position +(0,0,25). A stable valve shot starts leaking and gives >=1.4s ignition margin. Leaking valve hit redirects away from the shooter at speed220 and separately warns for >=1s; an ignited valve hit accelerates to Critical with1s warning. External Fire affects only explicitly Leaking cylinders, warning.85s and retaining the minimum1s leak interval. No Ice exception.
- Bowling previews its route1.2s, then speed250 with physical10/Push140. Rocket cylinders wait through leaking/ignition then propel at380 on a committed direction for <=2.5s; no ungated rocket source.
- Backfire against Jane requires distance<=175 and4s guard. Each application is min(remaining lifetime cap, maxHP*.035/(1+priorCount*.5)); total at most16% of Jane maxHP, nonlethal. Stagger diminishes as max(.35,1.6/count), with common immunity too. Companion recovery1.6s.

### Gas, signatures, recovery and death

- At most five active authored gas sections. Ordinary pocket radius105; ignition delay3.2s (helper floor2s); full-lived gas fire lasts2.4s with.8s tick and Fire8. Before ignition it causes zero damage.
- Separate ignition warning1.1s before fuel burns; active zone label/color changes. Gas uses shared zone geometry/LOS-filtered targets rather than an independent toxin/burn timer.
- Vent-and-Ignite: three genuinely directional lanes, width48 with validated endpoints/midpoints and permanent safe-anchor exclusion. Ignition delays2.95/3.6/4.25s; preannounced gas and later fire remain distinct.
- Cylinder Storm: bounded three drops, warnings/delays1.6/1.9/2.2s, ordinary cylinder cap still applies.
- Emergency Relief clears gas/fire, pushes only Stable/Leaking cylinders outward at180, postpones their ignition/critical/blast to4/5/6.3s; Jane is vulnerable4s, next attack4.6s. The window is genuinely safe from her cleared gas/fire; Chuck remains the primary opponent.
- PROPANE NIGHTMARE: three marked radius110 sections, ignitions3.6/6.3/9s; each fire lasts1.8s, so previous section is safe before the next lights. Three failed ignition clicks at.8/1.6/2.4s; Jane stops during the sequence. At10s full vent gives4s vulnerable recovery. Signature cannot overlap itself.
- During Jane recovery, damage to Jane is scaled1.2 through the ordinary native HP seam. No separate companion/boss HP pool is created.
- Jane lethal callback immediately marks support inert and gas records done, but schedules native hazard retirement outside the lethal stack. The .1s deferred cosmetic tank drifts at30 toward the rack for3.2s; a loose cylinder falls after1.25s for.7s at120 downward; client-only controlled explosion blooms at1.6s. No damage/key/receipt comes from that spectacle. Native source disappearance also clears her hazards and never respawns her.


## Rank and File

- Base HP1700, scale3.2, skating/scraping speed95, turn blend.9. Object/zone cap28; ordinary zombie simultaneous cap min(12,6+party), hence7–10; pending queue cap14; ordinary add slots12 shared with the encounter/global ceiling.
- Records Department arena: three visible archive-door destinations, two optional shredders, four route-validated shelf rows at center offsets(±170,±240), leaving cross-aisles. Drawer labels render PERSONNEL/COMPLAINTS/DECEASED/PENDING/DENIED. Five visible drawers really extend by state; all remain extended in BACKLOG.
- Initial and phase-transition attack delay1.4s; ordinary cadence3.7s. Cycle introduces all four phase1 attacks, then all five phase2 routines, then avalanche/Mass Filing/surge in phase3. No late phase silently discards the earlier repertoire.
- Drawer Punch: lane length195, width95, tell.95s, life.25s, interval.3s, physical19/Push185; stationary1.65s.
- File Fan: five files with angle separation.13rad, tell1.2s, speed430. Paper Cut: one file, tell.75s, speed510. Both projectile mass1/radius10/HP3/gravity45/life2.4s/no bounce/break on impact. Fan physical7; Paper Cut4; Push35. Fan telegraph width150; Paper Cut30.
- Cabinet Charge: tell1.4s, speed385, width88, physical21/Push215,2s recoil/recovery; ordinary miss window remains.
- DENIED: frontal lane length310, width130, tell1.15s, life.35s, interval.4s, physical5/Push235.
- PERSONNEL batch min(3,1+party). ALL HANDS batch min(8,4+party), hence5–8; stationary/exposed6s, shared stagger5s, next attack7s. Native incoming damage multiplier1.3 while exposed. No heal from zombies.
- Zombie families are existing `afterburst`, `carrion`, `reaper`, `drubber`, `shy`; spawned with manual=false, preserving their ordinary AI/progression/reward authorities. DUPLICATE COPY selects only an already-owned, still-living zombie from this whitelist; batch min(3,1+party). No boss, elite, substitute or borrowed unrelated actor can be duplicated.
- Bounded queue service attempts at most once/.65s. Every native emergence gets1.15s warning. A shared/global ceiling rejection leaves the same entry pending; it does not lose the batch or silently exceed96. Party-local simultaneous cap also pauses it.
- PENDING: max4 markers, HP18, radius25, scale1.5, height9, delayed emergence4s, total lifetime16s. A marker remains attackable while awaiting actual native admission, including a full shared ceiling; cancellation/destruction/expiry cancels the linked queue entry. There is no hidden surviving spawn after folder cancellation.
- Shredder optional hold.6s, authored cooldown4s independent of common use debounce, cancellation radius300. Shooting a folder requires fewer interactions.
- MISFILED moves at most3 existing exact zombies through visible archive doors via shared delayed Relocate; same entity/HP/reward identity survives. No replacement zombies or parallel rewards.
- Records Avalanche: four radius80 marked regions excluding safe anchor by190, warning onset1.95/2.3/2.65/3s, life.3s, interval.4s, physical14/Push90. Visual binders fall from210 above at210 speed/gravity160 for<=1.2s, mass2/radius8, no additional damage.
- Mass Filing: PERSONNEL now → two PENDING folders at1.5s → DENIED at3.1s; stationary3.6s and next attack5.5s. Delayed DENIED retains the exact Hero binding.
- Phase3 optional drawer hit box: forward X>=18*size, abs(Y)<=22*size, Z12*size..68*size, multiplier1.25 on ordinary primary damage. Exposed-all1.3 takes precedence, never multiplies twice. All other body damage stays ordinary.
- Death duration3.4s; drawers open, nine finite cosmetic falling paper shapes, CASE CLOSED/MISC label and cabinet forward crash. Safe key location is floor105 units in front of the dead cabinet, captured before corpse disappearance; fallback is saved position/geometric center. Only the common primary receipt spawns the one key.


## Cornette, Who's Drills Hurt

- Base HP1350, stock female body with metal coloration(170,192,200), scale1.15. Skate speed205, phase3 235, turn blend.95. Total object/zone budget14; drone slots3. Heavy concrete drill columns: three permanent, route-validated solid objects, radius40/scale1.5, with additional actual tall concrete-column render geometry.
- Client geometry adds both helical tapering drill hands, four wheels per skate and metal shin plates. Missing-arm NW states remove the launched drill hand; wrist socket stays visible. Tears are finite render-only beams; motor/uneven-spin/phase3 smoke and sparks are render-only. No allocation inside Draw.
- Initial attack1.5s; phase transition1.4s; ordinary cadence3.4s. Earlier phase vocabulary remains in the sequence. Audible cry interval12s, level67, pitch105, volume.35; no per-frame cry sound.
- Drill Shot: alternating left/right, tell1.05s, speed760, gravity0, mass12/radius12/HP22/life3.4s, one ricochet; shared physical16/Push110, phase3 physical22. Actual owned projectile leaves the hand; its rendered helix follows the launch/reflected direction. The second wall hit embeds for.95s then returns; ordinary Hero hit becomes returning for.6s. Destroy/expiry and exact-owner lifetime fallback restore only the corresponding hand serial.
- Runaway Drill: only one active; tell1.5s, speed590, life5.5s, three ricochets. Cornette visibly lacks that hand until it expires/returns. No second runaway admitted while it lives.
- Painful Drilling: committed close lane length180/width105, tell.95s, sustained1.5s at.65s ticks, physical8 (phase3 11)/Push45; Cornette stationary/recovering2.5s. Cross Drill coordinates the same front pressure with rear drone acquisition.
- Tearful Retreat: selects farthest legal point from target, backward skate presentation speed190/turn1.1, retreat/recovery3s, next attack3.6s, route cue.65s.
- Phase2 drone cap2 solo,3 multiplayer; existing normal `razor` archetype with stock manhack, manual support AI, HP fraction1.3, scale1.2. First phase2 admission after.5s, then replacement/admission cooldown12s, including a full12s after a death. Unique monotonically increasing per-drone callback keys prevent replacements cancelling another live drone's shot.
- Drones choose legal points150–720 from target, preferring behind the Hero, opposite elevation>=45 and differentiated side; desired distance330. Move speed145, air height70, turn1.8. Ordinary shot cadence4.5s; visible charging1.15s, then committed speed490 projectile, radius9/mass1/life1.7s/no bounce/scale.35. Blast8, Push35; “Drill Them Toward Me” uses Push100 directed toward Cornette for5s. Rare warning bark probability1/5 from isolated stream.
- Phase3 strain: normal drill23, runaway34, sustained contact30, skate charge35. Reaches max100 → OW OW OW OW OW and real4.8s overheat vulnerability, clears close contact and stops Cornette; drones continue suppression. Recovery ends at20 strain. Idle decay3/s begins4s after last strain; no indefinite chain-lock. Existing longer column recovery is never shortened by overstrain.
- Any primary recovery window scales ordinary incoming damage1.25. This uses the existing native HP pool only.
- Drill-Skate Charge: committed straight rush, tell1.75s, speed650, width55, physical26/Push245. Normal recovery1.8s. Exact TraceHull contact with one of the owned heavy-column entities, and both hands present at commitment, gives both-drills-stuck recovery5.5s and next attack5.8s. Nearness to a column alone or a missing hand cannot counterfeit it.
- Death duration2.8s: crying stops, “Oh.”, both drills render harmlessly flying outward for1.6s at180 lateral speed, body spins400deg/s/falls, common key follows. No dying projectile damages Heroes.



## Marion the Carbarian — Dungeon 9

### Body, court and entrance

- BaseHP1500, ordinary speed170, model scale1.55, Push scale0.12, object/hazard budget20, adds0
- Stock citizen male07 with rendered car-grille breastplate, bumper, tyre shoulders and an oversized real hammer silhouette (handle + rectangular metal head)
- Four traffic lane centerlines at 1/5,2/5,3/5,4/5 of lower-floor Y extent; lane endpoints inset55 X. Yellow dashed road lines plus green safe medians render at the actual court coordinates
- Two heavy reinforced cars request lane1/4 far end minus130 X, plus/minus135 Y; permanent, indestructible, solid radius75, mass120; route validation radius85
- Entrance starts the harmless visible car at Marion's actual origin, 20 units above floor, toward lane 2's far endpoint at speed390; Marion commits to that same endpoint. Actor warning0.3s, speed400, arc32, width36, recovery1s. A non-cancelled finish removes the entrance car and previews the hammer wreck for0.7s at radius95. Intro watchdog3.8s; initial ordinary-attack delay4.5s and traffic delay7s. Cancellation clears the entrance without damage and schedules1.2s restart allowance

### Hammer and traffic

- Three sledge strikes capture origin and direction once: delays0.65/1.4/2.65s, radii110/125/150, damage14/16/27, Push70/70/180. First two centers65 units forward, overhead105. Entire combo blocks ordinary attacks4s
- Overhead within190 units of a designated heavy car sticks hammer:2.7s stagger/recovery
- Ground Pound radius205, warning1.1s, active0.2s (one tick), damage14, Push260, next attack2.8s
- Traffic cars: maximum6 live; stock car004a; radius48, mass120, HP65, gravity0. Ordinary traffic390 speed, kick410, hammer smash720. Lifetime=min(5s,path/speed+1s)
- Each car has exactly one spent primary-Hero impact: ordinary25 damage / smash38, Push280, reference18. Cross-car exact-life impact protection2.5s prevents pinball. A protected collision still consumes that car's contact
- Rush Hour picks two separated lanes, FORE uses exactly one. Alternating travel direction. Traffic preview1.6s, second lane0.7s later; waves6.8s in phase2 and10s in phase3, so background thins materially
- Car Kick designated visible wind-up car1.3s then launch, FORE2.2s; wind-up HP0, mass120. Intended line1000 units or captured legal target fallback; visible lane width130. Next ordinary attack after wind-up+1.8s
- Smash car alone permits one authored barrier ricochet. Collision must name the actual designated heavy-car entity. Depenetrate55 along normal, redirect toward Marion at270 for at most1.3s. After0.6s an unretired wreck within330 can stagger Marion3.2s. Arbitrary world impact does not produce this bonus

### Pileup, gag and death

- PILEUP triggers exactly once atHP≤20%. Three prospective wrecks use lane1–3 points at37%/49%/61% path plus115 Y, preview1.8s; every placement revalidates all existing solids at radius80. Radius75, permanent/indestructible, mass120; attack breather4s
- Roadside Assistance occurs every eleventh authored decision; disabled car offset110, HP35, lifetime4.8s. Warning2.4s then Fire zone radius125, delay0.4s, life1.5s, interval0.8s, canonical Fire damage10. Separate explosion warning1.8s, radius175, blast26/Push190. Destruction before ignition/explosion cancels the later hazard. Gag suspends next ordinary attack5s
- Phase grammars mix explicit pursuit, combo, Ground Pound, kick and FORE; pursuits choose safe lane edges135 off the centerline rather than generic direct chase. Reposition decision1.3s
- DeathDuration5s. Upright hammer is an 8s harmless prop at safe native death position; final car appears after1s, velocity450, life2.4s, no damage. Client body is carried off after1.5s. KeyPosition is the validated upright hammer position with safe center fallback; common service alone releases the key


## The Flightmeister — Dungeon 16

### Native body and flight

- BaseHP2200, movement250 baseline, scale1, explicit airborne=true, Push immune, budget22, adds0
- Stock `models/gunship.mdl`; physical flight hull(-95,-95,-42)→(95,95,86), broad native combat bounds(-190,-175,-78)→(190,175,120)
- Eight orbit anchors inset18% from lower-floor bounds. Three lane centers at quarters. Normal height=min(440,arena.flightHeight or400), low height=max(180,normal×0.58)
- Air-only Move with stop distance80 (custom pass70). Normal turn interpolation2.3, damaged1.3, giving visibly wider damaged turns. Maneuvers have a12s deadline: ordinary orbit-node timeout stops movement and grants2s exposed/reposition recovery; custom lane-pass completion or timeout uses that pass's authored bank recovery. Ordinary scheduling waits while a flight maneuver is active
- Initial wide orbit follows nodes1→2→3 at speed245 with4s final recovery; ordinary orbit/retreat-return follows5→6→7→8→1 at240 with1.8s recovery and nominal next-decision delay5s. Strafe275, low strafe300; bombing255; climb245; low return260; crosswind300. Routes are bounded arena anchors, never stock wandering
- A cannon strafe first reaches its exact authored/beacon lane mouth, then fires its four captured commitments at 1/5 increments of physical pass duration. Final bank recovery1.5s ordinary /4s beacon
- True Hover Fire calls Stop rather than continuing to fly during its punish window

### Fire and opportunities

- Cannon Strafe width90, warning0.6s per commitment, damage16. Initial whole-lane preview1.2s, width120; exposed underside3.5s, next decision5.8s minimum
- Hover three fixed suppression lanes65 apart, starts spaced0.65s, each warning1s, width70, damage13. Stationary recovery4s, exposed engine5s, next attack5.8s
- Underside hits below actorZ+28 during exposure scale ordinary resolved damage×1.18. Engine counter builds only from actual resolved hits in that region; threshold5.5% maxHP then resets, requests2.6s stagger/recovery. Ordinary damage is never disabled
- Bombing marks five circles in one lane, radius110, delays1.6+i×0.45s, damage27/Push190, each0.18s one tick. Bombing flies the selected lane endpoints, with2.5s ordinary bank or4s beacon bank. The other two lanes remain safe; next decision6s
- Heavy Ordnance exactly two readable attackable stock helicopter bombs: target spread±70; impact warnings1.5+i×0.35s and projectile launch delays1+i×0.35s (i=1,2), radius18, mass30, HP20, life3.5s, no bounce, gravity220. Velocity targets1.2s travel with132 vertical compensation; blast radius105, damage30/Push170. Next decision4.5s
- Two expendable wooden covers: HP75, radius50, admission55, permanent until destroyed. Cover Break warns2s, blast radius125, damage23/Push140, removes only an explicitly expendable cover; next attack4.2s. With no expendable piece, use Bombing instead
- Crosswind affects a single width200 lane after1.4s for0.3s; filtered target callback applies Push210 and no direct damage. Pass recovery2s, or4s when beacon-attracted; next decision4.7s
- Two optional targeting beacons: hold E0.3s, shared cooldown24s, attract the next pass into lane1 or3; no damage; guarantee4s vulnerable bank/recovery on the consumed strafe, bombing, Crosswind or dive; strafe/bombing/Crosswind use that lane's actual endpoints; an attracted dive commits to its grounded far endpoint
- Desperation Dive: actual air charge toward captured grounded target+80Z, warning2.4s, speed420, width130, physical damage35/Push280. Actual designated hard-cover entity collision gives5s stagger; an otherwise completed beacon-attracted dive gives4s, and an ordinary non-structure completion2.5s. Common swept trace owns collision; no teleport. trace.cancelled clears diving without any stagger/bonus, and independent deadline3.4+path/420 recovers a missing callback
- DOGFIGHT: ordinary or phase3 low strafe now, climb3.2s, bombing5.5s, hover9.3s, low return12s, final stop/exposure15s for5s. The signature sets a16s sequence hold and initial20s next-attack deadline; final recovery at15s sets the next attack5s later. Phase changes clear the sequence and impose1.8s restart allowance; pause clears it with2s restart allowance. These are explicit separately readable phases, not a renamed repeated shot
- Cannon projection uses captured target-floor elevation so upper galleries are real alternate positions rather than absolute immunity
- Four mandatory permanent granite cover requests use scale1.35/radius85 and combined-solid route-admission radius90. New attacks require at least two surviving pieces. Rejected admissions retry at2s intervals using supported candidates more than260 units from center and separated by at least260 from existing cover; their HP0 makes them indestructible through the ordinary object-damage path

### Death

- DeathDuration6s, optional snapshot deathTarget is the captured designated hard-cover point
- Engine failure / failed orbit becomes a shrinking-radius95 controlled spiral over4.8s into that structure, roll to115°, with a short harmless impact ring; the designated structure is retained as a6s harmless cosmetic after normal death cleanup. Smoke is finite render geometry. Native key remains center via common authority


## Conan the Cone — Dungeon 17

### Body, obstacles and space grammar

- BaseHP2050, speed145, scale6.8, Push scale0.08, budget40, adds0
- Traffic-cone native collision(-62,-62,0)→(62,62,180); combat bounds(-80,-80,0)→(80,80,255)
- Four actual marked lanes at fifths, endpoints inset70 X. Fourteen permanent harmless native models embody the roadwork:8 concrete curb sections (scale0.35) along the two edges,4 gantry posts sized from model bounds toward330 height, and2 overhead native timber crossbeams fitted across the court (all scale bounds0.05–8). These consume the shared module budget, are nonsolid/nonoffensive, and retire with encounter cleanup; client-only gantry substitutes were removed
- Three finite designated road signs/barriers: HP80, solid radius36, route-admission42, at lane1–3 far end minus80X plus115Y. Only their actual collision identity grants barrier punish and consumes one sign
- All five explicit formation topologies exist: funnel6, zig-zag5, partial ring5, lane divider5, chicane6. Local spacing=min(120,courtYextent/12). Combined formation/old-solid routes validate before scheduling and at every actual admission
- Mini-cone global module cap12, HP22, radius19, route radius26, mass7, scale1.2, life16s, Push scale2.2, no AI. Spawn preview0.9s. Full-line roadblocks cover only a section of one lane
- Lane Closure clears its predecessor: exactly one active closure, width145, warning1.4s, duration5.8s, interval1s, damage12/Push70. Exactly three major alternate lanes remain open
- Work Zone radius145, warning1.2s, life3.5s, interval1s, damage13/Push100; next attack3.8s

### Charges, CONED and finale

- Cone Charge warning1.5s, speed430, width64, damage25/Push250, recovery1.7s, next decision4.5s
- Detour commits both target coordinates before movement, previews both full-width130 segments together, then first speed430 → second warning0.65s/speed430. Midpoint offsets160 sideways at half X. First recovery0.6s, second1.8s; next ordinary decision7s. No target reacquisition between segments
- Actual designated sign impact removes that finite sign, clears mini-cones and staggers3.5s. Ordinary miss gives1.5s punish
- CONED locks one exact Hero life and its floor point; circle radius140, warning1.9s, upward arc400, minimumDuration1.8s (common travel bound also includes arc), speed330, contact width95, damage18/Push25, recovery2s. Final trap requires a real charge Hero hit AND the originally bound Hero still inside125 of final landing. Miss/stale life gives2.4s stuck punish, never an arbitrary substitute victim
- Trap is canonical movement constraint key per encounter/attempt, radius55, duration3.2s, no damage loop. Trap forbids normal attacks. Solo always auto-escapes. Same exact Hero life receives13s anti-chain immunity
- Visible escape lever life3.4s, E hold0.25s. Only another current Hero may help; each0.75s-separated successful use reduces remaining trap by1.4s; early release destroys lever and releases the shared constraint immediately. Invalid victim life, pause, phase transition, retire and defeat all release. Before launching CONED, an exact-owned native hull update raises the collision minimum toZ80 while maximum stays180; ordinary72-unit Heroes can always physically escape after release. Restore original hull only after every actual Hero (including invisible Heroes) is at least160 away; a nearby Hero during pause keeps the high safe hull
- Charge callbacks reject trace.cancelled without trap, stagger or second-segment continuation. Independent expiry: ordinary charge≤18s from3+path/430(+3 for detour); CONED3.4+sqrt(path²+800²)/330; missing native callback invokes Stop and clears the flags with1.2s restart allowance
- Phase3 cooperative double CONED is only enabled with≥2 active targets/frozen party≥2; target identities differ and second launch waits7.5s. Scheduler held14s. Solo gets one ordinary CONED; no doubled lock
- Cascade8 outward directions45° apart; warning1.3s, speed310, lift110/gravity200, radius18, mass7, HP18, life2.4s, one bounce, damage14/Push130; next decision4.5s
- Construction Frenzy combines one closure + one validated maze in another lane + charge after1.5s. No unbounded maze or multi-closure stacking; ordinary scheduler waits7s
- DeathDuration5s: monumental210-unit charge over1.3s ends at an actual native0.75-scale traffic-cone prop, life5s, harmless. SafePoint validates the snag destination and serializes it to the death ghost. Flip180° over1.1s with180-unit hop and inverted rest; client-only tiny-cone substitute removed. ROAD OPEN and center key use canonical completion


## Little Mooky — Dungeon 19

### Native Strider, graph, covers and knees

- BaseHP2900, baseline145 speed, stock `models/combine_strider.mdl`, scale1, Push immune, budget18, adds0
- High physical body hull(-92,-92,245)→(92,92,455) intentionally leaves a baseline-Hero underbody passage. Native combat bounds(-225,-220,115)→(225,220,480) admit main-body and front-knee hits
- Eight boss-specific lower-floor movement nodes: X endpoints185 inside floor-center extents, Y endpoints28% inside; edge midpoints produce a validated bidirectional ring. Every directed edge samples nine supported floor points and performs a native TraceHull using the actual high body hull, then validates connectivity. Graph construction/revalidation happens after initial cover placement and on each changed owned-solid ID/position fingerprint. Movement admits only a native-hull-clear approach to an authored node followed by approved edges. Each actual leg calls Move with opts.path={exactWaypoint}; no generic Navigator shortcut is allowed. Every live leg is re-swept before servicing. Blocked motion replans at most twice,0.8s apart, then1.5s unchanged-HP recovery, without false route advancement or fabricated major stagger
- Four permanent covers; two secondary wooden covers HP65/radius55 (admission60), at centerY±270; only secondary cover is destructible
- Native attachments `left foot`/`right foot`/`back foot` and tested bone candidates are used when provided by the model. Fallback rig markers are explicit, visible and inside the admitted combat bounds: front knees(145,±140,190), feet(145,±140,5), rear foot(-175,0,5) in actor basis. This is an authored deterministic fallback, not native rig acceptance
- Each knee counts actual main-HP damage inside72 radius with a rolling concentration gap≤4s. Threshold4.5% actor maxHP, no separate HP or scripted health subtraction. Buckle3.2s/recovery, visually lowered4.2s, recovered knee guard12s. Damage during lowering cannot restagger. Exposed main body aboveactorZ+230 gets×1.20 ordinary damage
- Underbody cannon safety requires XYdistance<145 and localZ<220; stomps/legs/reposition still counter that legitimate high-risk route. Rig marker NW updates at most4Hz; expired knee protection clears its visual

### Cannon, legs and movement

- Pulse lane width80, warning0.9s, active0.18s with interval1s, damage16, Push30; next decision2.2s. Ground/gallery attack plane is fixed to captured target floor
- Sweep Fire three fixed lanes170 apart across the perpendicular, warning0.9s then0.55s spacing, each ordinary pulse; next3.5s
- Leg Strike radius170, warning1.15s, damage25/Push270, single0.2s tick, next2.7s. Triple Stomp independently marks left/right/back footprints0.8s apart; next4.8s
- Strider Step previews1.1s, width130, target one valid graph edge, speed135 phase1/175 phase2, Hunter195 phase3; stop45, bounded12s step then1.2s successful recovery. Nominal next decision3.5s, but ordinary attacks remain held until the explicit-path Step completes; each path call uses turnRate28 and stopDistance45
- Heavy Cannon width135, warning2.35s, damage34/Push210, next4.1s. Occasional phase2/3 pulse while still partially lowered is allowed after the stagger window
- Container Kick follows fixed node1→node3 parallel lane+100Y; prevalidates eventual cover, max2 settled covers. Warning1.8s, speed340, radius65, mass120, HP90, scale0.24, duration=min(4s,path/340), no gravity. Damage30/Push250 through ordinary projectile hit, then safe stop/settle. Final container cover HP90, solidradius80/admission85. Invalid settling positions are discarded, never block routes
- Maximum two Mooky Laser events per encounter:1s visible charge, then2.5s final locked lane, width115, damage42/Push210. Coordinates are copied before callbacks; movement/death/replacement does not retarget it. Later laser choices fall back to ordinary Heavy Cannon
- Damaged aim jitters offsets-125,+105,-55,0Y at0.28s intervals; at1.12s commits a fixed heavy lane with1.6s final warning. Next4.5s; no post-lock tracking
- MOOKY WALK retreats at155 to node1, then crosses to node3 at115; turnRate28 for ground MotionV2, stop45, bounded30s whole sequence. Retreat uses the shortest native-clear approved ring route; forward Walk executes node1→2→3 explicitly. Timeout/blockage gives1.5s unchanged-HP safe recovery, not the successful far-turn stagger. Initial ordinary-attack deadline35s; only actual far-side arrival grants the five-second major stagger. During actual walk, three leg-column circles radius95 warn0.55s every1.4s, damage20/Push210; ordinary pulse every2s with1s warning. Far-side completion stops and staggers5s, no attacks through that recovery

### Death

- DeathDuration8s: cannon stops; two failing1.2s steps, kneel begins2.4s for1.5s, collapse4.1–5.2s, harmless impact ring5.0–5.8s; silence then tiny metal tink7s (volume0.45, pitch160, level65). Only LITTLE MOOKY DEFEATED uses defeat caption, delayed7.2s until after the tink; center key remains canonical

## Scope and evidence boundary

These are implementation-tunable production values, subject to later authorized balancing. The exact authored constraints at the beginning of this record are immutable for this implementation. Source validation and headless behavioral outcomes are separate from native GMod collision, model/rig alignment, audio/visual readability, cooperative feel and Steam Deck performance acceptance.

Additional small realizations: Button presses record their exact canonical HP decrement through the existing combat-attribution ledger before native OnKilled, preserving ordinary XP/loot ownership. Joilette’s last cosmetic Neil rises with velocity140Z then gravity600 and lifetime0.85s before disappearing into the bowl; it is harmless. Death/key/client expiry uses identical absolute deadlines.
