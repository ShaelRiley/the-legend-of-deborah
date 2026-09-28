-- Full production catalog on the accepted generation/economy fixtures.
-- Source entities, geometry traces and transport are doubled. Actual generators,
-- progression proofs, encounter reservations, event plans and lifecycle run.
local equipment=dofile('tools/test_equipment_economy_runtime.lua')
local F=dofile('tools/dungeon_event_fixture.lua')({lod=LOD,run=equipment.Run,realFloors=true})
local root,D,R,Run=F.root,F.D,F.R,F.Run
for index=#F.online,1,-1 do table.remove(F.online,index) end
net.WriteUInt,net.WriteFloat,net.WriteBool=F.noop,F.noop,F.noop
LOD.SnapshotDelivery={Queue=F.noop,Invalidate=F.noop}
ents.FindInBox=function() return {} end
timer.Create,timer.Remove=F.noop,F.noop
function table.HasValue(values,wanted) for _,value in pairs(values) do if value==wanted then return true end end;return false end
local vectorMeta=getmetatable(Vector())
function vectorMeta:Length() return math.sqrt(self:LengthSqr()) end
function vectorMeta:Distance(other) return math.sqrt(self:DistToSqr(other)) end
function vectorMeta:Dot(other) return self.x*other.x+self.y*other.y+self.z*other.z end
function vectorMeta:GetNormalized() local length=self:Length();return length>0 and self*(1/length) or Vector() end
function vectorMeta:Normalize() local normalized=self:GetNormalized();self.x,self.y,self.z=normalized.x,normalized.y,normalized.z end
local angleMeta={};angleMeta.__index=angleMeta
function Angle(p,y,r) return setmetatable({p=p or 0,y=y or 0,r=r or 0},angleMeta) end
function angleMeta:Forward() local p,y=math.rad(self.p),math.rad(self.y);return Vector(math.cos(p)*math.cos(y),math.cos(p)*math.sin(y),-math.sin(p)) end
function angleMeta:Right() local y=math.rad(self.y);return Vector(-math.sin(y),math.cos(y),0) end
function vectorMeta:Angle() return Angle(0,math.deg(math.atan(self.y,self.x)),0) end

-- Rich native Hero surface from the shared equipment gate; state and behavior
-- continue through real character/equipment/crypto authorities.
local nativeActor=F.actor
function F.actor(id)
 local actor=nativeActor(id)
 local equipped=equipment.actor(id)
 for name,value in pairs(equipped) do if actor[name]==nil then actor[name]=value end end
 actor.ps=equipped.ps
 actor.ps.identity,actor.ps.deploymentComplete,actor.ps.lives=id,true,3
 actor.GetNW2Int=actor.GetNW2Float
 return actor
end
F.a,F.b=F.actor('76561198177100001'),F.actor('76561198177100002')

dofile(root..'sv_maze_navigator.lua')
dofile(root..'sv_hostile_motion_v2.lua')
dofile(root..'sv_safe_teleport.lua')
local fixtureBuild=LOD.MazeBuilder.Build
dofile(root..'sv_progression_builder.lua')
LOD.MazeBuilder.Build=fixtureBuild
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_gate/init.lua')
local gateClass,nativeCreate=ENT,ents.Create
SOLID_BBOX=2
ents.Create=function(class)
 local entity=nativeCreate(class)
 if IsValid(entity) then
  function entity:SetModel(model) self.model=model end
  function entity:GetModel() return self.model end
  function entity:SetModelScale(scale) self.modelScale=scale end
  function entity:GetModelScale() return self.modelScale or 1 end
  function entity:SetMaterial(material) self.material=material end
  function entity:GetMaterial() return self.material or '' end
 end
 if class=='lod_gate' and IsValid(entity) then
  setmetatable(entity,{__index=gateClass})
  for _,field in ipairs({'GateIndex','GateAxis','Opened','OpenedAt','Solid'}) do
   entity['Set'..field]=function(self,value) self[field]=value end
   entity['Get'..field]=function(self) return self[field] end
  end
  entity.GetNotSolid=nil
  function entity:IsSolid() return self:GetSolid()~=SOLID_NONE and not self.NotSolid end
  function entity:SetCollisionBounds(lo,hi) self.boundsMin,self.boundsMax=lo,hi end
  entity.AddEFlags,entity.CollisionRulesChanged=F.noop,F.noop
  function entity:Spawn() self:Initialize() end
 end
 return entity
end

-- Skeleton profile/combat/death are covered by the existing actor/lifecycle
-- gates. This same boundary isolates native combat from generation, without
-- disabling the real blockade or its placement/ownership/barrier authorities.
LOD.SkeletonHero={Spawn=function(_,director,instance,graph)
 local actor=ents.Create('lod_hostile')
 if not IsValid(actor) then return nil end
 if not director:Track(instance,actor) then actor:Remove();return nil end
 instance.hostile=actor;actor.LODHostile=true;actor.LODSkeletonHero=true;actor.hp=100
 function actor:Health() return self.hp end
 actor:SetPos(LOD.MazeBuilder:CellCenter(graph.Cells[instance.cellKey]));actor:Spawn();actor:Activate()
 return actor
end}

-- Load modules in boot dependency order. Record registration ownership rather
-- than assuming a single event identity per source file.
F.registrations={slot_machine='sv_event_slot_machine.lua'}
local function load(name)
 local before={};for id in pairs(R.Definitions) do before[id]=true end
 dofile(root..name)
 for id in pairs(R.Definitions) do if not before[id] then F.registrations[id]=name end end
end
load('sv_event_locked_chest.lua')
dofile(root..'sv_crypto_director.lua')
LOD.CryptoDirector.Sync=F.noop
for _,name in ipairs({'treasure_chest','vending_machine','false_floor','warp_hole','skeleton_blockade','equipment_quiz'}) do
 load('sv_event_'..name..'.lua')
end
dofile(root..'sv_debbie_junk.lua')
for _,name in ipairs({'transactions','services','incidents'}) do load('sv_event_'..name..'.lua') end

dofile(root..'sv_encounter_director.lua')
LOD.CombatRolls.HostileDamageProfiles=LOD.CombatRolls.HostileDamageProfiles or {}
LOD.WanderingDirector=LOD.WanderingDirector or {Config={ArchetypeWeights={}}}
dofile(root..'sv_m3_enemy_config.lua')
dofile(root..'sv_enemy_update.lua')
dofile(root..'sv_enemy_roster.lua');dofile(root..'sv_enemy_roster_placement.lua')
dofile(root..'sv_enemy_pursuit.lua');dofile(root..'sv_climber.lua')
for _,name in ipairs({'deadcrab','bioblaster','watcher','seeker'}) do dofile(root..'sv_'..name..'.lua') end
dofile(root..'sv_encounter_ecology_catalog.lua');dofile(root..'sv_encounter_ecology.lua')
for _,theme in pairs(LOD.EncounterDirector.EcologyCatalog.themes) do
 for id in pairs(theme.templates) do assert(LOD.Config.Encounter.Templates[id],'Missing production encounter template: '..id) end
end
Run._ActiveCount=function() return 2 end
util.TraceLine=function(trace)
 local delta=trace.endpos-trace.start
 if delta.z>200 then return {Hit=true,HitPos=trace.start+Vector(0,0,250),HitNormal=Vector(0,0,-1),Fraction=.5,StartSolid=false} end
 local distance=math.sqrt(delta:LengthSqr())
 local fraction=distance>320 and 320/distance or 1
 return {Hit=fraction<1,Fraction=fraction,StartSolid=false,HitPos=trace.start+delta*fraction,HitNormal=Vector(0,0,1)}
end
local eventBuild,originalPlan=LOD.MazeBuilder.Build,D.Plan
LOD.MazeBuilder.Build=function() return true,{} end
dofile(root..'sv_m3_run_integration.lua')
local encounterBuild=LOD.MazeBuilder.Build
LOD.MazeBuilder.Build=eventBuild
function F.encounterSignature(graph)
 local plan={}
 for field,value in pairs(graph.EncounterPlan) do if field~='ecologyReceipt' then plan[field]=value end end
 return WalletJSONEncode({tags=graph.CellTags,encounters=plan})
end
D.Plan=function(self,graph,options)
 assert(encounterBuild(LOD.MazeBuilder,graph))
 local reservations=F.encounterSignature(graph)
 assert(#graph.EncounterPlan.encounters>3,'Production encounter reservations missing')
 assert(graph.EncounterPlan.ecology and graph.EncounterPlan.ecology.theme,'Production encounter theme missing')
 local accepted,result,retry=originalPlan(self,graph,options)
 assert(reservations==F.encounterSignature(graph),
  'Event planning changed encounter reservations')
 return accepted,result,retry
end

local function key(cell) return F.G.CellKey(cell.x,cell.y,cell.z) end
local function edge(a,b) return a<b and a..'|'..b or b..'|'..a end
local function count(values) local n=0;for _ in pairs(values) do n=n+1 end;return n end
local function walk(graph,start,blocked,cells)
 local seen,queue={},{}
 if graph.Cells[start] and not (cells and cells[start]) then seen[start]=true;queue[1]=start end
 local at=1
 while queue[at] do
  local current=queue[at];at=at+1
  for neighbor in pairs(graph.Cells[current].neighbors) do
   if not seen[neighbor] and not blocked[edge(current,neighbor)] and not (cells and cells[neighbor]) then
    seen[neighbor]=true;queue[#queue+1]=neighbor
   end
  end
 end
 return seen
end
function F.signature(plan)
 local rows={tostring(plan.selectedCount)}
 for _,instance in ipairs(plan.instances) do
  rows[#rows+1]=instance.id..'/'..WalletJSONEncode(instance.placement)..'/'..instance.seed
 end
 return table.concat(rows,';')
end
function F.Prove(graph,plan)
 assert(F.G:Validate(graph) and LOD.GraphIntegrity:Audit(graph).valid and graph.Progression.Validation.valid)
 local occupied,blockades,hazardEdges,hazardCells={},{},{},{}
 local protected=D:ProtectedCells(graph)
 local identities={}
 for _,instance in ipairs(plan.instances) do
  local placement,definition=instance.placement,R.Definitions[instance.archetype]
  identities[instance.archetype]=true
  local resources={[instance.cellKey]=true}
  for _,field in ipairs({'destinationCellKey','cacheCellKey','approachCellKey'}) do
   if placement[field] then resources[placement[field]]=true end
  end
  local function reserveEdge(k)
   local record=assert(graph.Edges[k]);resources[key(record.a)],resources[key(record.b)],resources[k]=true,true,true
  end
  if placement.edgeKey then reserveEdge(placement.edgeKey) end
  for k in pairs(placement.blockedCells or {}) do resources[k]=true;hazardCells[k]=true end
  for k in pairs(placement.blockedEdges or {}) do reserveEdge(k);hazardEdges[k]=true end
  for k in pairs(resources) do
   assert(not occupied[k],'Event resources overlap: '..k);occupied[k]=true
   if graph.Cells[k] then assert(not protected[k],'Encounter/progression reservation stolen: '..k) end
  end
  if instance.contract=='BLOCKADE' then blockades[#blockades+1]=instance end
  assert(D:ValidatePlacement(graph,definition,placement))
  assert(instance.state=='active' and D:IsCurrent(instance) and IsValid(instance.entities[1]))
  for _,entity in ipairs(instance.entities) do assert(IsValid(entity) and entity.LODEventInstance==instance) end
  if definition.presentation then
   assert(instance.entities[1]:GetClass()=='lod_dungeon_event')
   assert(instance.entities[1]:GetModel()==definition.presentation.model,'Native presentation model not applied')
  end
 end
 assert(plan.selectedCount==count(identities),'Selected identities were dropped or duplicated')
 for _,id in ipairs(plan.selected or {}) do assert(identities[id],'Selected identity silently dropped') end
 for _,row in ipairs(plan.placementDiagnostics or {}) do
  assert(row.attempts>0 and row.attempts<=D.MaxPlacementAttempts,'Unbounded placement search')
 end
 assert(D:ValidateRoutes(graph,hazardEdges,hazardCells))

 -- Independent graph traversal replays approachable resolutions followed by
 -- key/gate/boss/jail order. The production validation alone is not the oracle.
 local progression,blocked=graph.Progression,table.Copy(hazardEdges)
 for _,instance in ipairs(blockades) do blocked[instance.placement.edgeKey]=true end
 for _,gate in ipairs(progression.Gates) do blocked[gate.edgeKey]=true end
 blocked[progression.JailEdge.edgeKey]=true
 if progression.Warden and progression.Warden.lock then blocked[progression.Warden.lock.edgeKey]=true end
 local settled={}
 local function advance()
  for _=1,#blockades+1 do
   local reach,changed=walk(graph,key(graph.Start),blocked,hazardCells),false
   for _,instance in ipairs(blockades) do
    if not settled[instance] and reach[instance.cellKey] then
     local definition=R.Definitions[instance.archetype]
     assert(definition.CanResolve(definition,graph,instance.placement,reach),
      'Blockade requires inaccessible resources: '..instance.archetype)
     if instance.placement.cacheCellKey then assert(reach[instance.placement.cacheCellKey],'Resolution cache behind its barrier') end
     settled[instance]=true;blocked[instance.placement.edgeKey]=hazardEdges[instance.placement.edgeKey];changed=true
    end
   end
   if not changed then return reach end
  end
  error('Finite blockade resolution exceeded')
 end
 for ordinal,gate in ipairs(progression.Gates) do
  local reach=advance()
  local objective=progression.Keycards and progression.Keycards[ordinal] and progression.Keycards[ordinal].cell
   or (ordinal==4 and progression.Hunt and progression.Hunt.neilCell)
  assert(not objective or reach[key(objective)],'Gate objective unreachable')
  assert(reach[key(gate.beforeCell)] and not reach[key(gate.afterCell)],'Ordered gate bypass')
  blocked[gate.edgeKey]=hazardEdges[gate.edgeKey]
 end
 local reach=advance()
 assert(reach[key(progression.CoreCell)] and not reach[key(progression.DeborahCell)],'Boss/jail order changed')
 blocked[progression.JailEdge.edgeKey]=hazardEdges[progression.JailEdge.edgeKey]
 assert(advance()[key(progression.DeborahCell)],'Rescue unreachable')
 for _,instance in ipairs(blockades) do assert(settled[instance],'Unresolved required blockade') end
 return identities
end
function F.Build(seed,preview)
 D.NextPreview=preview
 local from=#F.created+1
 local history=WalletJSONEncode(Run.State.EventEcology)
 local ok,reason=Run:BuildCurrentLevel(seed)
 if not ok then
  assert(not D.Context and not Run.State.BuildReady and Run.State.LevelSeed==seed)
  assert(history==WalletJSONEncode(Run.State.EventEcology),'Failed build committed event history')
  for index=from,#F.created do assert(not IsValid(F.created[index]),'Rejected build leaked resource') end
  return nil,reason
 end
 local graph,plan=Run.State.Graph,D.Context.plan
 F.Prove(graph,plan)
 if preview then assert(history==WalletJSONEncode(Run.State.EventEcology),'Preview committed event history') end
 return plan,graph
end
F.count,F.walk,F.edge=count,walk,edge
return F
