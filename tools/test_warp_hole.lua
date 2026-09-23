-- Real event, graph, generated floors and SafeTeleport authorities. Source
-- traces and packet delivery are the only boundary doubles; native acceptance
-- remains separate from this deterministic regression suite.
local F=dofile('tools/dungeon_event_fixture.lua')({realFloors=true})
local root,D,R,Run,B=F.root,F.D,F.R,F.Run,LOD.MazeBuilder
MOVETYPE_WALK,MASK_PLAYERSOLID,CONTENTS_SLIME,CONTENTS_WATER=2,3,16,32
bit={band=function(a,b) return a & b end,bor=function(a,b) return a | b end}
function LOD.Equipment:CanAct(p) return IsValid(p) and p:Alive() and p.active~=false and not p.soldier and not p.ps.inStaging and not p.ps.eliminated end
LOD.RPGAbilityRules={VoluntaryDashes={}}
LOD.Equipment.StompFlights={}
function LOD.Equipment:EndStatue(p) p.statueEnded=true end
LOD.MazeNavigator={};dofile(root..'sv_maze_navigator.lua');dofile(root..'sv_safe_teleport.lua')
dofile(root..'sv_event_warp_hole.lua')
local W=LOD.WarpHoleEvent
local function key(c) return F.G.CellKey(c.x,c.y,c.z) end
local function bounds(e)
 if e:IsPlayer() then local lo,hi=e:GetHull();return e:GetPos()+lo,e:GetPos()+hi end
 if e.BoxMins and e.BoxMaxs then return e:GetPos()+e.BoxMins,e:GetPos()+e.BoxMaxs end
end
local function overlap(a,b,c,d)
 return a.x<d.x and b.x>c.x and a.y<d.y and b.y>c.y and a.z<d.z and b.z>c.z
end
local extra={}
local function entities()
 local all={};for _,e in ipairs(F.created) do all[#all+1]=e end
 for _,p in ipairs(F.online) do all[#all+1]=p end
 for _,e in ipairs(extra) do all[#all+1]=e end
 return all
end
ents.FindInBox=function(lo,hi)
 local found={}
 for _,e in ipairs(entities()) do
  local a,b=bounds(e)
  if IsValid(e) and a and overlap(lo,hi,a,b) then found[#found+1]=e end
 end
 return found
end
local traceMode,traceCallback
local function filtered(filter,e)
 if type(filter)=='table' and filter[1] then for _,x in ipairs(filter) do if x==e then return true end end;return false end
 if type(filter)=='function' then return filter(e)==false end
 return filter==e
end
local function trace(data)
 if traceCallback then traceCallback(data) end
 local mins,maxs=data.mins or Vector(),data.maxs or Vector()
 local best={Hit=false,StartSolid=false,AllSolid=false,Fraction=1,HitPos=data.endpos,HitNormal=Vector(0,0,1)}
 if traceMode=='blocked' then return {Hit=true,StartSolid=true,AllSolid=true,Fraction=0,HitPos=data.start,HitNormal=Vector(0,0,1)} end
 for _,e in ipairs(entities()) do
  local lo,hi=bounds(e)
  if IsValid(e) and lo and not e.NotSolid and not filtered(data.filter,e) then
   local low,high=lo-maxs,hi-mins
   local enter,leave=0,1
   local inside=true
   for _,axis in ipairs({'x','y','z'}) do
    local p,delta=data.start[axis],data.endpos[axis]-data.start[axis]
    if p<=low[axis] or p>=high[axis] then inside=false end
    if math.abs(delta)<.000001 then
     if p<=low[axis] or p>=high[axis] then enter=2;break end
    else
     local a,b=(low[axis]-p)/delta,(high[axis]-p)/delta
     if a>b then a,b=b,a end
     enter,leave=math.max(enter,a),math.min(leave,b)
    end
   end
   if enter<=leave and enter<=best.Fraction and enter<1 and leave>0 then
    best={Hit=true,StartSolid=inside,AllSolid=inside and leave>=1,Fraction=enter,Entity=e,
     HitPos=data.start+(data.endpos-data.start)*enter,HitNormal=Vector(0,0,1)}
   end
  end
 end
 return best
end
util.TraceLine,util.TraceHull=trace,trace
util.PointContents=function() return traceMode=='water' and CONTENTS_WATER or 0 end

local function prepare(p)
 function p:SetLocalVelocity(v) self.localVelocity=v end
 p.active,p.dead,p.soldier,p.ps.inStaging,p.ps.eliminated=true,false,false,false,false
 p.ps.deploymentComplete,p.ps.lives=true,3
end
local a,b=F.a,F.b
prepare(a);prepare(b)
local function build(seed)
 D.NextPreview='warp_hole'
 assert(Run:BuildCurrentLevel(seed))
 local i=assert(D.Context.plan.instances[1]);assert(i.archetype=='warp_hole')
 assert(D:ValidatePlacement(Run.State.Graph,R.Definitions.warp_hole,i.placement))
 return i
end
local instance=build(2)
local graph,definition=Run.State.Graph,R.Definitions.warp_hole
local source,destination=graph.Cells[instance.cellKey],graph.Cells[instance.placement.destinationCellKey]
local graphBefore=F.graphSignature(graph)
assert(source.z~=destination.z and definition.contract=='UTILITY')
assert(#instance.entities==2 and instance.endpoints[1]~=instance.endpoints[2] and not instance.linked)
-- Independent locked-edge walks check every progression stage, including the
-- closed rescue jail. Neither teleport direction may create earlier access.
local blocked={};for _,gate in ipairs(graph.Progression.Gates) do blocked[gate.edgeKey]=true end
blocked[graph.Progression.JailEdge.edgeKey]=true
if graph.Progression.Warden and graph.Progression.Warden.lock then blocked[graph.Progression.Warden.lock.edgeKey]=true end
local function reachable(start)
 local seen,queue={[start]=true},{start};local at=1
 while queue[at] do
  local k=queue[at];at=at+1
  for n in pairs(graph.Cells[k].neighbors) do
   local ek=k<n and k..'|'..n or n..'|'..k
   if not seen[n] and not blocked[ek] then seen[n]=true;queue[#queue+1]=n end
  end
 end
 return seen
end
for stage=0,#graph.Progression.Gates+1 do
 local reach=reachable(key(graph.Start))
 assert((reach[key(source)]==true)==(reach[key(destination)]==true),'Warp cannot bypass any progression stage')
 if reach[key(source)] then
  assert(reachable(key(destination))[key(source)] and reachable(key(source))[key(destination)],'Both ordinary return routes required')
 end
 local gate=graph.Progression.Gates[stage+1]
 if gate then blocked[gate.edgeKey]=nil else blocked[graph.Progression.JailEdge.edgeKey]=nil end
end
local placement=instance.placement
for _,candidate in ipairs({
 {cellKey=placement.cellKey},
 {cellKey=placement.cellKey,destinationCellKey='absent'},
 {cellKey=placement.cellKey,destinationCellKey=placement.cellKey},
 {cellKey=key(graph.Start),destinationCellKey=placement.destinationCellKey},
 {cellKey=placement.cellKey,destinationCellKey=key(graph.Goal)},
 {cellKey=placement.cellKey,destinationCellKey=placement.destinationCellKey,addedEdges={}}
}) do assert(not D:ValidatePlacement(graph,definition,candidate),'Invalid warp endpoint accepted') end
for _,k in ipairs({placement.cellKey,placement.destinationCellKey}) do
 assert(not D:ValidatePlacement(graph,definition,placement,{[k]=true}),'Sibling reservation ignored')
 local altered=table.Copy(graph);altered.CriticalPath[#altered.CriticalPath+1]=altered.Cells[k]
 assert(not D:ValidatePlacement(altered,definition,placement),'Critical endpoint accepted')
 altered=table.Copy(graph);altered.CellTags={[k]={safe=true}}
 assert(not D:ValidatePlacement(altered,definition,placement),'Safe endpoint accepted')
 altered=table.Copy(graph)
 for neighbor in pairs(altered.Cells[k].neighbors) do altered.Cells[neighbor].neighbors[k]=nil end
 altered.Cells[k].neighbors={}
 assert(not D:ValidatePlacement(altered,definition,placement),'Disconnected endpoint accepted')
 assert(not D:ValidatePlacement(graph,definition,placement,nil,{cells={[k]=true}}),'Combined blocked-cell route accepted')
end
local originalPlace=definition.Place
local attempts=0;definition.Place=function() attempts=attempts+1;return {cellKey='absent'} end
assert(not D:Plan(graph,{preview='warp_hole'}) and attempts==D.MaxPlacementAttempts)
definition.Place=originalPlace
assert(F.graphSignature(graph)==graphBefore,'Endpoint proof modified production topology')
local first,second=instance.endpoints[1],instance.endpoints[2]
local center,other=B:CellCenter(source),B:CellCenter(destination)
local away=center+Vector(240,0,2)
local function near(p,endpoint) prepare(p);p.pos=endpoint:GetPos() end
local function unchanged(p,endpoint,why)
 near(p,endpoint);local before=p.pos;local moves=p.moves
 assert(not D:Interact(endpoint,p),why)
 assert(p.pos==before and p.moves==moves,'Rejected arrival displaced Hero: '..why)
 assert(not instance.linked,'Rejected arrival activated dormant pair: '..why)
end
b.pos=away
for _,mode in ipairs({'blocked','water'}) do traceMode=mode;unchanged(a,first,mode) end
traceMode=nil
b.pos=other+Vector(0,0,2);unchanged(a,first,'occupied arrival');b.pos=away
-- Native support and standing-hull checks use the generated floor entities.
local support=util.TraceLine({start=other+Vector(0,0,8),endpos=other-Vector(0,0,16),filter=a}).Entity
assert(IsValid(support) and support.LODGeneratedGeometry)
support.NotSolid=true;unchanged(a,first,'missing generated support');support.NotSolid=false
local hazard=ents.Create('trigger_hurt');hazard:SetPos(other+Vector(0,0,2));hazard:SetBoxMins(Vector(-20,-20,0));hazard:SetBoxMaxs(Vector(20,20,80))
unchanged(a,first,'trigger hurt');hazard:Remove()
local ceiling=ents.Create('prop_physics');ceiling:SetPos(other+Vector(0,0,45))
ceiling:SetBoxMins(Vector(-80,-80,0));ceiling:SetBoxMaxs(Vector(80,80,10))
unchanged(a,first,'standing hull under low ceiling');ceiling:Remove()
a.hullHalf=200;unchanged(a,first,'oversized standing hull');a.hullHalf=nil
for _,state in ipairs({'vehicle','noclip','spectator','soldier','dead','staging','undeployed','eliminated','no_lives','frozen','expired'}) do
 near(a,first);local moves=a.moves
 if state=='vehicle' then a.vehicle=true elseif state=='noclip' then a.moveType=8
 elseif state=='spectator' then a.active=false elseif state=='soldier' then a.soldier=true
 elseif state=='dead' then a.dead=true elseif state=='staging' then a.ps.inStaging=true
 elseif state=='undeployed' then a.ps.deploymentComplete=false elseif state=='eliminated' then a.ps.eliminated=true
 elseif state=='no_lives' then a.ps.lives=0 elseif state=='frozen' then Run.State.SimulationFrozen=true
 elseif state=='expired' then Run.State.CampaignClock={expired=true} end
 assert(not D:Interact(first,a) and a.moves==moves and not instance.linked,'Ineligible Hero traversed: '..state)
 a.vehicle,a.moveType=false,nil;Run.State.SimulationFrozen,Run.State.CampaignClock=nil,nil
end
-- Reentrant native queries can invalidate exact Hero, life, source, paired
-- entity, account or generation ownership before any movement commits.
for _,change in ipairs({'life','state','epoch','graph','identity','entity','destination','tracking','source','spectator','soldier','clock','late_clock','late_frozen','late_occupancy'}) do
 near(a,first);b.pos=away
 local oldPS,oldEpoch,oldGraph,oldId=a.ps,Run.State.CampaignEpoch,Run.State.Graph,a.id
 local oldEntities=instance.entities;local oldLife=a.ps.equipmentLifeSerial
 local fired,landingSeen=false,false;local moves=a.moves
 traceCallback=function(data)
  -- Wait for arrival support query, or the first subsequent LOS callback.
  if fired then return end
  if change:find('late_',1,true) then
   if data.mins then landingSeen=true;return end
   if not landingSeen or data.mask~=MASK_SOLID then return end
  elseif not data.mins then return end
  fired=true
  if change=='life' then a.ps.equipmentLifeSerial=(oldLife or 0)+1
  elseif change=='state' then a.ps=table.Copy(a.ps)
  elseif change=='epoch' then Run.State.CampaignEpoch=oldEpoch+1
  elseif change=='graph' then Run.State.Graph=table.Copy(oldGraph)
  elseif change=='identity' then a.id='76561198599999999'
  elseif change=='entity' then first.valid=false
  elseif change=='destination' then second.valid=false
  elseif change=='tracking' then instance.entities={}
  elseif change=='source' then a.pos=away
  elseif change=='spectator' then a.active=false
  elseif change=='soldier' then a.soldier=true
  elseif change=='clock' or change=='late_clock' then Run.State.CampaignClock={expired=true}
  elseif change=='late_frozen' then Run.State.SimulationFrozen=true
  elseif change=='late_occupancy' then b.pos=other+Vector(0,0,2) end
 end
 assert(not D:Interact(first,a),'Stale traversal accepted: '..change)
 traceCallback=nil
 assert(fired and not instance.linked and a.moves==moves,'Stale traversal moved/activated: '..change)
 a.ps,a.id=oldPS,oldId;oldPS.equipmentLifeSerial=oldLife
 Run.State.CampaignEpoch,Run.State.Graph=oldEpoch,oldGraph;Run.State.CampaignClock=nil;Run.State.SimulationFrozen=nil
 first.valid,second.valid=true,true;instance.entities=oldEntities
end
-- Movement teardown can introduce an occupant after the first landing probe.
near(a,first);b.pos=away
local endStatue=LOD.Equipment.EndStatue
LOD.Equipment.EndStatue=function(self,p) endStatue(self,p);b.pos=other+Vector(0,0,2) end
local moves=a.moves
assert(not D:Interact(first,a) and a.moves==moves and not instance.linked,'Post-teardown occupied arrival accepted')
LOD.Equipment.EndStatue=endStatue
near(a,first);b.pos=away
LOD.Equipment.StompFlights[a]={};LOD.RPGAbilityRules.VoluntaryDashes[a]={};a.LODForcedMovementUntil=999
first:Use(a)
assert(instance.linked and a.moves==1 and a.pos:DistToSqr(other+Vector(0,0,2))<1,'Native Use must link and traverse')
assert(a.localVelocity:LengthSqr()==0 and a.statueEnded and not LOD.Equipment.StompFlights[a]
 and not LOD.RPGAbilityRules.VoluntaryDashes[a] and not a.LODForcedMovementUntil,'Shared move must clear incompatible movement')
assert(not D:Claim(instance,a.id),'Repeatable utility cannot consume a claim')
assert(not D:Interact(second,a),'Immediate return must respect Hero cooldown')
local wallet=assert(F.Store:Read(a.id));assert(wallet.balance==0 and next(wallet.tokens)==nil,'Warp must be free')
-- Second Hero does not inherit the first Hero cooldown or claims.
a.pos=away;near(b,first)
assert(D:Interact(first,b) and b.moves==1)
b.pos=away
F.now=F.now+W.CooldownSeconds
near(a,second);assert(D:Interact(second,a) and a.moves==2)
assert(a.pos:DistToSqr(center+Vector(0,0,2))<1)
for _,p in ipairs({a,b}) do
 local row=D:Snapshot(p).events[1]
 assert(row.details.linked and not row.claimed and #row.details.endpoints==2)
 for n,endpoint in ipairs(instance.endpoints) do assert(row.details.endpoints[n].entityIndex==endpoint:EntIndex()) end
end
local newcomer=F.actor('76561198500000001');prepare(newcomer);newcomer.pos=away
F.hooks.LOD_DungeonEventSnapshot(newcomer);table.remove(F.timers)()
local packet=F.packets[#F.packets]
assert(packet.recipient==newcomer and packet.body.events[1].details.linked and #packet.body.events[1].details.endpoints==2)
local stale,children=instance,{first,second}
D:Cleanup('warp lifecycle test')
for _,e in ipairs(children) do assert(not IsValid(e) and not D:Interact(e,a)) end
assert(#D:Snapshot(a).events==0 and not W:TryTraverse(D,stale,a,a.id,first))
local createdFrom=#F.created
local create=ents.Create;local creations=0
ents.Create=function(class)
 if class=='lod_dungeon_event' then creations=creations+1;if creations==2 then return nil end end
 return create(class)
end
D.NextPreview='warp_hole'
assert(not Run:BuildCurrentLevel(2),'Half a pair must fail the generation')
ents.Create=create
assert(not Run.State.BuildReady and not D.Context)
for n=createdFrom+1,#F.created do
 if F.created[n].class=='lod_dungeon_event' then assert(not IsValid(F.created[n]),'Partial endpoint leaked') end
end
instance=build(2)
assert(instance~=stale and not instance.linked and not D:IsCurrent(stale),'Generation must reset activation')
assert(instance.cellKey==placement.cellKey and instance.placement.destinationCellKey==placement.destinationCellKey)
assert(F.graphSignature(Run.State.Graph)==graphBefore,'Seeded regeneration changed topology')
-- Cleanup is legal during native traces or shared movement teardown. The
-- obsolete callback must not recreate claims, activation or cooldown ownership.
for _,boundary in ipairs({'landing','line_of_sight','statue'}) do
 local currentInstance=instance;local endpoint=instance.endpoints[1]
 near(a,endpoint);b.pos=away;newcomer.pos=away
 local moves=a.moves;local fired=false;local endStatue=LOD.Equipment.EndStatue
 if boundary=='statue' then
  LOD.Equipment.EndStatue=function(self,p)
   endStatue(self,p);fired=true;D:Cleanup('reentrant statue teardown')
  end
 else
  traceCallback=function(data)
   if not fired and (boundary=='line_of_sight' or data.mins) then
    fired=true;D:Cleanup('reentrant native trace')
   end
  end
 end
 local safe,accepted=pcall(D.Interact,D,endpoint,a)
 traceCallback=nil;LOD.Equipment.EndStatue=endStatue
 assert(safe and not accepted and fired and a.moves==moves,'Cleanup callback displaced or errored: '..boundary)
 assert(not currentInstance.linked and not currentInstance.traversalCooldowns and not D.Context,'Cleanup callback reclaimed stale state')
 for _,e in ipairs(currentInstance.entities) do assert(not IsValid(e)) end
 instance=build(2)
end
-- Run the actual client snapshot receiver and HUD callback against both native
-- endpoint IDs. A recycled/mismatched entity may show only synchronization.
local incoming,drawn,looked
net.ReadTable=function() return incoming end
LOD.UI={};LocalPlayer=function() return a end
input={LookupBinding=function() return 'e' end}
ScrW,ScrH=function() return 1000 end,function() return 800 end
TEXT_ALIGN_CENTER,TEXT_ALIGN_TOP=1,2
draw={SimpleTextOutlined=function(line) drawn[#drawn+1]=line end}
function a:GetEyeTrace() return {Entity=looked} end
dofile(root..'cl_dungeon_events.lua')
local function render(ent)
 looked=ent;a.pos=ent:GetPos();drawn={}
 function ent:GetNW2Int(k,default) local v=self.nw[k];return v==nil and default or v end
 F.hooks.LOD_DungeonEventPrompt()
 return table.concat(drawn,'\n')
end
incoming=D:Snapshot(a);F.receivers.LOD_DungeonEvents()
for n,endpoint in ipairs(instance.endpoints) do
 assert(endpoint:GetEventID()==instance.id)
 local text=render(endpoint)
 assert(text:find('ENDPOINT '..n,1,true) and text:find('LINK AND TRAVERSE',1,true),'Both actual endpoints need dormant prompts')
end
local liveToken=LOD.DungeonEvents.token
incoming={token=tostring(tonumber(liveToken)-1),events={}}
F.receivers.LOD_DungeonEvents();assert(LOD.DungeonEvents.token==liveToken,'Older generation snapshot replaced current pair')
local endpoint=instance.endpoints[2];local index=endpoint.index
endpoint.index=index+100000
local text=render(endpoint)
assert(text:find('Synchronizing warp',1,true) and not text:find('LINK AND TRAVERSE',1,true),'Recycled endpoint index matched stale row')
endpoint.index=index
D:Cleanup('warp suite complete')
print('WARP_HOLE_PASS: actual paired production generation, independent ordered-stage/return proof, endpoint rejection, SafeTeleport support/hull/occupancy, native Use/repeat/cooldown/two Heroes, late joins, exact lifecycle rejection, partial creation rollback and cleanup')
