-- Author-reported empty/repetitive dungeons: production four-gate topology,
-- real planner/roaming authorities, Source entities/physics doubled by B23.
local T=dofile('tools/test_bestiary_b23.lua')
istable=istable or function(v) return type(v)=='table' end
local H,W=T.H,T.W
local D,Run=H.D,H.Run
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sv_neil_brute.lua');dofile(root..'sv_warden_arena.lua')
local EC=LOD.Config.Encounter
local key=LOD.MazeGenerator.CellKey
local function keyOf(c) return key(c.x,c.y,c.z) end
local function count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
local core={shambler=true,runner=true,soldier=true}
local report={plans=0,ready4=0,encounters=0,discretionary=0,otherIdentities=0,minOther=math.huge,
    otherBodies=0,plannedBodies=0,initialWanderers=0,sector4Squads=0,themes={}}
local originalTemplates=H.serial(EC.Templates)
assert(EC.ActiveHostileTarget==80 and EC.ActiveHostileCeiling==96,'changed live ceiling')
assert(H.serial(EC.MaxDiscretionaryPerSector)==H.serial({4,6,6,6}),'production slot tuning drift')
for i,n in ipairs({12,24,27,30}) do assert(EC.SectorBaseThreat[i]==n,'production threat tuning drift') end
-- The dev wrapper must not silently be necessary for release population.
local developer=false
local previousConVar=GetConVar
GetConVar=function(name)
 if name=='lod_developer_mode' then return {GetBool=function() return developer end} end
 return previousConVar and previousConVar(name)
end
dofile(root..'sv_m3_dense_testing.lua')
local firstGraph,firstPlan
for sample=1,16 do
 local campaign=sample*7919
 local specs={{level=1,party=1}}
 if sample<=2 then specs[#specs+1]={level=8,party=2};specs[#specs+1]={level=20,party=4} end
 for _,spec in ipairs(specs) do
  H.setParty(spec.party)
  Run.State={CampaignSeed=campaign,CampaignEpoch=1,RunId=1,Level=spec.level}
  local g=H.prepare(campaign,spec.level)
  -- H20 opened its three-gate fixtures. Exercise native reset state instead.
  Run.State.GatesOpen={false,false,false,false}
  local gateState=H.serial(Run.State.GatesOpen)
  local p=H.build(g);H.bounds(p)
  assert(#g.Progression.Gates==4 and g.Progression.Warden,'not the production progression stack')
  local pace=p.pacing.sectors[4]
  assert(pace.status=='ready','production hunt sector lost all pacing: '..campaign..':'..spec.level)
  assert(pace.goal==keyOf(g.Progression.Gates[4].beforeCell),'target is behind Black Gate')
  assert(p.tags[keyOf(g.Progression.CoreCell)].sector~=4,'fixture did not isolate boss reservation')
  assert(H.serial(Run.State.GatesOpen)==gateState,'planner unlocked gates to hide the bug')
  assert(not p.developerDenseTesting and p.populationRevision=='b27','not the release plan')
  local sig=H.signature(p);local pacing=H.serial(p.pacing)
  local repeated=H.build(g)
  assert(H.signature(repeated)==sig and H.serial(repeated.pacing)==pacing,'non-deterministic plan')
  p=repeated
  local other,optional,sector4,bodies,otherBodies={},0,0,0,0
  for _,enc in ipairs(p.encounters) do
   local tag=p.tags[enc.cellKey]
   assert(not tag.safe and tag.role~='boss','reserved home consumed')
   assert(H.serial(enc.plannedComposition)==H.serial(enc.composition),'initial roster lost')
   if not enc.objective then
    optional=optional+1;if enc.sector==4 then sector4=sector4+1 end
    assert(D:PacingAllows(p,g.Cells[enc.cellKey]),'quiet/recovery home')
   end
   for id,n in pairs(enc.composition) do
    bodies=bodies+n
    if not core[id] then other[id]=true;otherBodies=otherBodies+n end
    local def=LOD.EnemyRoster.Definitions[id]
    if def and (def.stationary or def.support or def.pursuit or def.reaction or def.pattern
        or def.trap or def.melee or def.tactical or def.mobile or def.condition or def.spacing
        or def.resource or def.crossfire or def.discipline or def.companion or def.edict or def.link) then
     assert(n==1,'duplicated specialist to manufacture density')
    end
   end
  end
  assert(optional<=22,'unbounded discretionary population')
  for k in pairs(g.Progression.Warden.cells) do assert(p.tags[k].safe and p.tags[k].role=='boss') end
  Run.State.BuildReady=true
  assert(D:CommitEcologyPlan(g));local memory=H.serial(Run.State.EncounterEcology)
  T.init(g);T.bounds(g)
  local snapshot=D:PopulationSnapshot()
  assert(snapshot.ready and snapshot.revision=='b27' and snapshot.plannedBodies==bodies)
  assert(snapshot.aliveBodies==snapshot.aliveWanderers and snapshot.aliveBodies<=96,'live/planned conflation')
  local before=T.signature();assert(H.serial(snapshot)==H.serial(D:PopulationSnapshot()),'unstable observer')
  assert(T.signature()==before and H.serial(Run.State.EncounterEcology)==memory,'observer mutated runtime')
  -- Opening earlier/Black gates must not move the sector's pacing endpoint.
  Run.State.GatesOpen={true,true,true,true}
  local reopened={seed=p.seed,tags=table.Copy(p.tags),ecology=p.ecology}
  D:BeginPacing(reopened,g)
  assert(reopened.pacing.sectors[4].goal==pace.goal and reopened.pacing.sectors[4].length==pace.length)
  if spec.level==1 then
   report.plans=report.plans+1;report.ready4=report.ready4+1;report.encounters=report.encounters+#p.encounters
   report.discretionary=report.discretionary+optional;report.otherIdentities=report.otherIdentities+count(other)
   report.minOther=math.min(report.minOther,count(other));report.otherBodies=report.otherBodies+otherBodies
   report.plannedBodies=report.plannedBodies+bodies;report.initialWanderers=report.initialWanderers+snapshot.aliveWanderers
   report.sector4Squads=report.sector4Squads+sector4;report.themes[p.ecology.theme]=true
   print(string.format('B26_RELEASE seed=%d theme=%s optional=%d otherIds=%d otherBodies=%d plannedBodies=%d wanderers=%d sector4=%d',
     campaign,p.ecology.theme,optional,count(other),otherBodies,bodies,snapshot.aliveWanderers,sector4))
  end
  firstGraph,firstPlan=g,p
 end
end
assert(count(report.themes)==6,'sample missed a motif')
assert(report.discretionary/report.plans>=9,'release still sparse')
assert(report.otherIdentities/report.plans>=6 and report.minOther>=4,'release still dominated by core-only fights')
assert(report.sector4Squads>=report.plans,'hunt population missing')
assert(H.serial(EC.Templates)==originalTemplates,'changed objective or specialist compositions')
-- Developer parity: denser test settings restore production tuning after a plan.
local config=H.serial({EC.SectorBaseThreat,EC.MaxDiscretionaryPerSector,EC.MajorSpacingCells})
developer=true;local dev=H.build(firstGraph);developer=false
assert(dev.developerDenseTesting and dev.pacing.sectors[4].status=='ready')
assert(H.serial({EC.SectorBaseThreat,EC.MaxDiscretionaryPerSector,EC.MajorSpacingCells})==config,'dev leaked config')
-- Snapshot retains the planned identity if native safety later substitutes it.
local enc=dev.encounters[1];local original=H.serial(enc.plannedComposition)
enc.composition={shambler=99}
local snap=D:PopulationSnapshot()
assert(H.serial(enc.plannedComposition)==original and snap.currentComposition.shambler>=99)
assert(snap.plannedBodies~=0 and H.serial(snap.planned)~=H.serial(snap.currentComposition))
D:Cleanup();assert(not D:PopulationSnapshot().ready,'retired plan shown as current')
print('BESTIARY_B26_PASS full-four-gate closed/open production topology; 20 plans plus replay; release/dev, protected homes, budgets, singleton companions, real roaming admission, observer purity; '..H.serial(report))
