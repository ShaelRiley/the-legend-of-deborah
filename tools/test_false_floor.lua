-- Production event, graph, generated slab compiler, actor binding and landing
-- checks. Native collision/transport are deterministic boundary doubles; this
-- does not claim Source gravity, rendering or network acceptance.
local F=dofile('tools/dungeon_event_fixture.lua')({realFloors=true})
local root,D,R,Run,B=F.root,F.D,F.R,F.Run,LOD.MazeBuilder
MOVETYPE_WALK,MASK_PLAYERSOLID,CONTENTS_SLIME,CONTENTS_WATER=2,3,16,32
bit={band=function(a,b) return a & b end,bor=function(a,b) return a | b end}
function LOD.Equipment:CanAct(p) return IsValid(p) and p:Alive() and p.active~=false and not p.soldier and not p.ps.inStaging and not p.ps.eliminated end
LOD.MazeNavigator={};dofile(root..'sv_maze_navigator.lua');dofile(root..'sv_safe_teleport.lua')
dofile(root..'sv_event_false_floor.lua')
local H=LOD.FalseFloorEvent
local MC=LOD.Config.Maze
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
local function build(seed)
 D.NextPreview='false_floor'
 assert(Run:BuildCurrentLevel(seed))
 local i=assert(D.Context.plan.instances[1]);assert(i.archetype=='false_floor')
 assert(D:ValidatePlacement(Run.State.Graph,R.Definitions.false_floor,i.placement))
 return i
end
local instance=build(2)
local graph,definition=Run.State.Graph,R.Definitions.false_floor
local source,destination=graph.Cells[instance.cellKey],graph.Cells[instance.placement.destinationCellKey]
local graphBefore=F.graphSignature(graph)
assert(source.x==destination.x and source.y==destination.y and source.z==destination.z+1)
-- An independent locked-edge walk checks both endpoints at every ordered stage,
-- including the closed rescue jail. No drop edge is inserted into the graph.
local blocked={};for _,gate in ipairs(graph.Progression.Gates) do blocked[gate.edgeKey]=true end
blocked[graph.Progression.JailEdge.edgeKey]=true
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
 assert((reach[key(source)]==true)==(reach[key(destination)]==true),'Fall cannot bypass any progression stage')
 if reach[key(source)] then assert(reachable(key(destination))[key(source)],'Landing needs existing locked-graph return route') end
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
}) do assert(not D:ValidatePlacement(graph,definition,candidate),'Invalid drop placement accepted') end
assert(not D:ValidatePlacement(graph,definition,placement,{[placement.destinationCellKey]=true}))
assert(not D:ValidatePlacement(graph,definition,placement,{[placement.cellKey]=true}))
local altered=table.Copy(graph);altered.CriticalPath[#altered.CriticalPath+1]=altered.Cells[placement.destinationCellKey]
assert(not D:ValidatePlacement(altered,definition,placement),'Lower critical endpoint must be protected')
altered=table.Copy(graph);altered.CellTags={[placement.destinationCellKey]={safe=true}}
assert(not D:ValidatePlacement(altered,definition,placement),'Safe landing endpoint must reject')
altered=table.Copy(graph)
for neighbor in pairs(altered.Cells[placement.destinationCellKey].neighbors) do altered.Cells[neighbor].neighbors[placement.destinationCellKey]=nil end
altered.Cells[placement.destinationCellKey].neighbors={}
assert(not D:ValidatePlacement(altered,definition,placement),'Disconnected landing must reject even if source remains optional')
local originalPlace=definition.Place
local attempts=0;definition.Place=function() attempts=attempts+1;return {cellKey='absent'} end
assert(not D:Plan(graph,{preview='false_floor'}) and attempts==D.MaxPlacementAttempts)
definition.Place=originalPlace
assert(F.graphSignature(graph)==graphBefore,'Event proof cannot alter production topology')
local center,lower=B:CellCenter(source),B:CellCenter(destination)
local lid=instance.floor.lid
assert(#instance.floor.rims==4 and #instance.entities==5 and instance.floor.original.NotSolid)
assert(lid.BoxMaxs.x-lid.BoxMins.x==128 and lid.BoxMaxs.y-lid.BoxMins.y==128)
local a,b=F.a,F.b
local function standing(p)
 p.pos=center+Vector(0,0,2);p.groundEntity=lid;p.grounded=true
 p.active,p.dead,p.soldier,p.ps.inStaging,p.ps.eliminated=true,false,false,false,false
 p.ps.deploymentComplete,p.ps.lives=true,3
end
local away=center+Vector(200,0,2)
a.pos,b.pos=away,away
standing(a)
assert(not D:Interact(lid,a),'Use is not the hazard trigger')
-- Inspect actual built collision: the closed lid supports the center and every
-- surrounding rim remains traversable after the center is opened.
local support=function(x,y) return trace({start=center+Vector(x,y,8),endpos=center+Vector(x,y,-32),filter=a}) end
assert(support(0,0).Entity==lid)
for _,offset in ipairs({{100,0},{-100,0},{0,100},{0,-100}}) do assert(support(offset[1],offset[2]).Hit) end
for _,state in ipairs({'spectator','soldier','dead','staging','undeployed','airborne','wrong_ground','too_large','edge','frozen','expired'}) do
 standing(a);a.hullHeight=nil;a.hullHalf=nil
 if state=='spectator' then a.active=false elseif state=='soldier' then a.soldier=true elseif state=='dead' then a.dead=true
 elseif state=='staging' then a.ps.inStaging=true elseif state=='undeployed' then a.ps.deploymentComplete=false
 elseif state=='airborne' then a.grounded=false elseif state=='wrong_ground' then a.groundEntity=instance.floor.original
 elseif state=='too_large' then a.hullHalf=70
 elseif state=='edge' then a.pos=center+Vector(63,0,2)
 elseif state=='frozen' then Run.State.SimulationFrozen=true elseif state=='expired' then Run.State.CampaignClock={expired=true} end
 assert(not H:TryOpen(D,instance,a),'Ineligible trigger accepted: '..state)
 Run.State.SimulationFrozen=nil;Run.State.CampaignClock=nil
end
standing(a)
traceMode='blocked';assert(not H:TryOpen(D,instance,a));traceMode='water';assert(not H:TryOpen(D,instance,a));traceMode=nil
b.pos=lower+Vector(0,0,2);assert(not H:TryOpen(D,instance,a),'Occupied landing accepted')
b.pos=center+Vector(35,0,-100);assert(not H:TryOpen(D,instance,a),'Occupied drop column accepted')
b.pos=away
local moves=a.moves
assert(H:TryOpen(D,instance,a),'Safe grounded Hero should open the real lid')
assert(instance.open and lid.NotSolid and lid.nw.LOD_GeometryHidden and a.moves==moves,'Native gravity must own descent; no SetPos')
assert(not H:TryOpen(D,instance,b),'Shared floor cannot open twice')
assert(not support(0,0).Hit,'Opened panel retains unexpected central collision')
for _,offset in ipairs({{100,0},{-100,0},{0,100},{0,-100}}) do assert(support(offset[1],offset[2]).Hit,'Walk-around rim lost') end
for _,p in ipairs({a,b}) do local row=D:Snapshot(p).events[1];assert(row.details.open and not row.claimed and row.details.destinationCellKey==key(destination)) end
local newcomer=F.actor('76561198500000001');newcomer.pos=away
F.hooks.LOD_DungeonEventSnapshot(newcomer);table.remove(F.timers)()
assert(F.packets[#F.packets].recipient==newcomer and F.packets[#F.packets].body.events[1].details.open,'Late join needs shared open state')
a.pos=lower+Vector(0,0,2)
F.now=F.now+H.OpenSeconds-0.1;H:Tick(D,instance);assert(instance.open,'Minimum reset duration')
F.now=F.now+0.2
b.pos=center+Vector(0,0,-24);H:Tick(D,instance);assert(instance.open,'Cannot reclose on a body')
b.pos=away
local prop=ents.Create('prop_physics');prop:SetPos(center);prop:SetBoxMins(Vector(-10,-10,-10));prop:SetBoxMaxs(Vector(10,10,10))
H:Tick(D,instance);assert(instance.open,'Cannot reclose on physics obstruction')
prop:Remove();H:Tick(D,instance)
assert(not instance.open and not lid.NotSolid and not lid.nw.LOD_GeometryHidden,'Clear aperture must rearm')
standing(b);a.pos=away
assert(H:TryOpen(D,instance,b),'Second Hero can retrigger rearmed shared floor')
b.pos=away;F.now=F.now+H.OpenSeconds;H:Tick(D,instance);assert(not instance.open)
-- Reentrant native traces may invalidate exact ownership/life/campaign while
-- the landing is checked. Every such attempt must leave solid support intact.
for _,change in ipairs({'life','state','epoch','graph','identity','entity','tracking','spectator','soldier','clock'}) do
 standing(a);b.pos=away
 local oldPS,oldEpoch,oldGraph,oldId=a.ps,Run.State.CampaignEpoch,Run.State.Graph,a.id
 local oldEntities=instance.entities;local oldLife=a.ps.equipmentLifeSerial
 local fired=false
 traceCallback=function()
  if fired then return end;fired=true
  if change=='life' then a.ps.equipmentLifeSerial=(oldLife or 0)+1
  elseif change=='state' then a.ps=table.Copy(a.ps)
  elseif change=='epoch' then Run.State.CampaignEpoch=oldEpoch+1
  elseif change=='graph' then Run.State.Graph=table.Copy(oldGraph)
  elseif change=='identity' then a.id='76561198599999999'
  elseif change=='entity' then lid.valid=false
  elseif change=='tracking' then instance.entities={}
  elseif change=='spectator' then a.active=false
  elseif change=='soldier' then a.soldier=true
  elseif change=='clock' then Run.State.CampaignClock={expired=true} end
 end
 assert(not H:TryOpen(D,instance,a),'Stale trigger accepted: '..change)
 traceCallback=nil
 assert(fired and not instance.open and not lid.NotSolid,'Stale trigger changed collision: '..change)
 a.ps,a.id=oldPS,oldId;oldPS.equipmentLifeSerial=oldLife
 Run.State.CampaignEpoch,Run.State.Graph=oldEpoch,oldGraph;Run.State.CampaignClock=nil
 lid.valid=true;instance.entities=oldEntities
end
standing(a);assert(H:TryOpen(D,instance,a))
a.pos=away
local stale,original,children=instance,instance.floor.original,{}
for _,e in ipairs(instance.entities) do children[#children+1]=e end
D:Cleanup('false floor lifecycle test')
assert(not original.NotSolid and not original.nw.LOD_GeometryHidden and not original.LODFalseFloor,'Cleanup restores original slab')
for _,e in ipairs(children) do assert(not IsValid(e)) end
assert(#D:Snapshot(a).events==0 and not H:TryOpen(D,stale,a))
F.now=F.now+100;H:Tick(D,stale)
assert(not original.NotSolid,'Stale tick cannot alter restored floor')
-- Fail midway through native slab replacement: partial rims are removed and
-- the original remains solid. A retry can use exactly that untouched slab.
local create=ents.Create;local createdFrom=#F.created;local creations=0
ents.Create=function(class)
 creations=creations+1
 if creations==3 then return nil end
 return create(class)
end
assert(not B:CreateFalseFloor(source,H.ApertureHalf))
ents.Create=create
assert(not original.NotSolid and not original.nw.LOD_GeometryHidden and not original.LODFalseFloor)
for i=createdFrom+1,#F.created do assert(not IsValid(F.created[i]),'Partial rim leaked') end
local replacement=assert(B:CreateFalseFloor(source,H.ApertureHalf));B:RestoreFalseFloor(replacement)
for _,e in ipairs(replacement.rims) do e:Remove() end;replacement.lid:Remove()
local nextInstance=build(2)
assert(nextInstance~=stale and not D:IsCurrent(stale) and not IsValid(lid))
assert(F.graphSignature(Run.State.Graph)==graphBefore,'Reset must preserve seeded maze/progression')
-- Cleanup during a falling body cannot restore collision through that body.
instance=nextInstance;lid=instance.floor.lid;standing(a)
assert(H:TryOpen(D,instance,a));a.pos=center+Vector(0,0,-20)
local transferred={};for _,e in ipairs(instance.entities) do transferred[#transferred+1]=e end
local retainedOriginal=instance.floor.original
D:Cleanup('occupied aperture')
assert(retainedOriginal.NotSolid and #instance.entities==0,'Occupied cleanup transfers inert geometry to builder')
for _,e in ipairs(transferred) do assert(IsValid(e) and not e.LODEventInstance,'Transferred geometry must lose event ownership') end
F.now=F.now+100;H:Tick(D,instance);assert(lid.NotSolid,'Stale open tick must remain inert')
B:Cleanup()
for _,e in ipairs(transferred) do assert(not IsValid(e),'Builder teardown must remove transferred aperture') end
-- A native reset trace can invalidate the generation while the query runs.
instance=build(2);lid=instance.floor.lid;standing(a);assert(H:TryOpen(D,instance,a));a.pos=away
F.now=F.now+H.OpenSeconds
local epoch=Run.State.CampaignEpoch;local resetFired=false
traceCallback=function() if not resetFired then resetFired=true;Run.State.CampaignEpoch=epoch+1 end end
H:Tick(D,instance);traceCallback=nil
assert(resetFired and instance.open and lid.NotSolid,'Stale reset must not change collision')
Run.State.CampaignEpoch=epoch
D:Cleanup('false floor suite complete')
print('FALSE_FLOOR_PASS: production floor geometry, independent gate-stage/return proof, endpoint rejection, native support/landing/column checks, shared repeatable reset/late join, exact actor lifecycle rejection, partial creation rollback and cleanup')
