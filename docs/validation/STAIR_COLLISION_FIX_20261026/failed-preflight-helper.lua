-- Native generated-collider test in an OWNED disposable scene, not ordinary gameplay/FPS.
assert(SERVER and not LOD.BenchStairCollision)
local spec=assert(util.JSONToTable(file.Read('legend_of_deborah/bench_stair_collision_spec.json','DATA')),'missing source spec')
assert(type(spec.sha)=='string' and type(spec.files)=='table' and #spec.files>=4)
local proofs={}
for _,row in ipairs(spec.files)do local bytes=assert(file.Read(row.path,'GAME'),row.path);local sha=util.SHA256(bytes);assert(sha==row.sha256,'source mismatch '..row.path);proofs[#proofs+1]={path=row.path,sha256=sha}end
local M,N=assert(LOD.HostileMotionV2),assert(LOD.MazeNavigator)
local S=assert(LOD.RunManager.State);local graph=assert(S.Graph)
local functions={}
for _,name in ipairs({'MoveToward','WaypointPosition','TraceStairMovement','ConstrainStairMovement'})do
 local f=assert(M[name]);local info=debug.getinfo(f,'S');assert(info.source:find('sv_hostile_motion_v2.lua',1,true));functions[name]={source=info.source,first=info.linedefined,last=info.lastlinedefined}
end
local edge
for _,v in ipairs(graph.VerticalEdges or {})do if v.LODStairDirection and v.LODStairEntrySide then edge=v;break end end
assert(edge,'no generated legal stair flight')
local lower=edge.a.z<edge.b.z and edge.a or edge.b;local upper=edge.a.z>edge.b.z and edge.a or edge.b
local route={};N:_AppendVerticalWaypoints(graph,lower,upper,route)
assert(#route>=3);for _,w in ipairs(route)do assert(w.stair and w.stairGraph==graph and w.stairEdge==edge,'waypoint identity missing')end
local lease={started=SysTime(),actors={},results={},proofs=proofs,functions=functions,sha=spec.sha,originalFrozen=S.SimulationFrozen,steps=0}
LOD.BenchStairCollision=lease
local marker='LOD_BenchStairNativeValidation';local status=LOD.RPGStatusElements;local entry=LOD.EntrySafety;local boss=LOD.BossEncounter
local moveOriginal=status and status.CanMoveVoluntarily;local entryOriginal=entry and entry.MovementAllowed;local beforeOriginal=entry and entry.BeforeAI;local hullOriginal=boss and boss.Hull
local function owned(e)return IsValid(e) and e.LODStairNativeProbe==lease end
local moveWrapper=function(self,e,...)if owned(e)then return true end return moveOriginal(self,e,...)end
local entryWrapper=function(self,e,...)if owned(e)then return true end return entryOriginal(self,e,...)end
local beforeWrapper=function(self,e,...)if owned(e)then return false end return beforeOriginal(self,e,...)end
local hullWrapper=function(self,e,...)if owned(e)then return e:GetCollisionBounds()end return hullOriginal(self,e,...)end
if moveOriginal then status.CanMoveVoluntarily=moveWrapper end
if entryOriginal then entry.MovementAllowed=entryWrapper end
if beforeOriginal then entry.BeforeAI=beforeWrapper end
if hullOriginal then boss.Hull=hullWrapper end
S.SimulationFrozen=true
local function restore()
 local good=true
 for _,r in ipairs({{status,'CanMoveVoluntarily',moveWrapper,moveOriginal},{entry,'MovementAllowed',entryWrapper,entryOriginal},{entry,'BeforeAI',beforeWrapper,beforeOriginal},{boss,'Hull',hullWrapper,hullOriginal}})do
  if r[1] and r[4]then if r[1][r[2]]==r[3]then r[1][r[2]]=r[4]else good=false end end
 end
 if LOD.RunManager.State==S then S.SimulationFrozen=lease.originalFrozen else good=false end
 for _,e in ipairs(lease.actors)do if IsValid(e)then e:Remove()end end
 return good
end
function lease:Stop(reason,errorText)
 if self.stopped then return end;self.stopped=true;hook.Remove('Think',marker);timer.Remove(marker)
 local restored=restore();LOD.BenchStairCollision=nil
 local count,passed=0,true
 for _,r in ipairs(self.results)do count=count+1;passed=passed and r.passed end
 passed=passed and count==9 and self.steps>0 and reason=='complete' and restored
 file.Write('legend_of_deborah/bench_stair_collision_result.json',util.TableToJSON({passed=passed,reason=reason,error=errorText,sha=self.sha,source_files=self.proofs,functions=self.functions,restored=restored,seconds=SysTime()-self.started,steps=self.steps,cases=count,expected_cases=9,results=self.results,edge={direction=edge.LODStairDirection,entry=edge.LODStairEntrySide,lower={x=lower.x,y=lower.y,z=lower.z}},scope='Native TraceHull against actual generated tread/rail/landing colliders after every production MoveToward step, actual _AdvanceWaypoint and real server time. Disposable frozen scene; test actors have paused own AI coroutine, neutral status/entry wrappers and 32x72 hull, boss flags exercise physical gateway only. This is NOT ordinary boss AI, full gameplay, FPS or all-orientation acceptance.'},true))
end
timer.Create(marker,110,1,function()lease:Stop('lease_timeout')end)
local function pausedBehaviour()while true do coroutine.yield()end end
local function spawn(kind,pos)
 local e=ents.Create('lod_hostile');assert(IsValid(e));e.RunBehaviour=pausedBehaviour;e.LODStairNativeProbe=lease;e.LODArchetypeId='shambler';e.LODActivated=false;e:SetPos(pos);e:Spawn();e:Activate();assert(IsValid(e));e.RunBehaviour=pausedBehaviour;lease.actors[#lease.actors+1]=e
 e.LODStairNativeProbe=lease;e.LODActivated=false;e.LODDead=false;e.LODConfig=table.Copy(e.LODConfig or {});e.LODConfig.speed=200;e.LODHitStunUntil=0
 e:SetCollisionBounds(Vector(-16,-16,0),Vector(16,16,72));e:SetPos(pos);e.LODMotionLastUpdate=CurTime();e.LODStrideRNG=nil
 if kind=='warden'then e.LODWarden=true;e.LODWardenOwner={};e.LODArchetypeId='warden'
 elseif kind=='hector'then e.LODHector=true;e.LODHectorEncounter={};e.LODArchetypeId='hector'
 elseif kind=='neil'then e.LODNeilBrute=true;e.LODArchetypeId='neil'
 elseif kind=='generic_boss'then e.LODBossEncounter=true end
 return e
end
local probe=spawn('ordinary',route[1].pos);M:WaypointPosition(probe,route[1])
local index=assert(graph.LODHostileStairCollision);local flight=assert(index.byEdge[edge]);assert(#flight.treads>=1 and #flight.solids>=1)
local allSolids,seen={},{}
for _,f in ipairs(index.flights)do for _,e in ipairs(f.solids)do if IsValid(e)and not seen[e]then seen[e]=true;allSolids[#allSolids+1]=e end end end
assert(#allSolids>=#flight.solids);probe:Remove()
local function clear(e)
 local lo,hi=e:GetCollisionBounds();local pos=e:GetPos()
 local tr=util.TraceHull({start=pos,endpos=pos,mins=lo,maxs=hi,mask=MASK_NPCSOLID,filter=allSolids,whitelist=true,ignoreworld=true})
 return not tr.StartSolid and not tr.AllSolid,tr
end
local active={};local phase=0;local walkCases={{'ordinary','up'},{'ordinary','down'},{'generic_boss','up'},{'generic_boss','down'}};local walkIndex=0
local function finish(c,passed,why,tr)
 if c.finished then return end;c.finished=true
 lease.results[#lease.results+1]={kind=c.kind,mode=c.mode,passed=passed,reason=why,steps=c.steps,seconds=CurTime()-c.start,travel=c.travel,maxDisplacement=c.maxDisplacement,finalDistance=IsValid(c.e) and c.e:GetPos():Distance(c.goal) or nil,waypointIndex=IsValid(c.e) and c.e.LODWaypointIndex or nil,waypointCount=c.route and #c.route or nil,hull={mins={-16,-16,0},maxs={16,16,72}},startSolid=tr and tr.StartSolid or false,allSolid=tr and tr.AllSolid or false}
 if IsValid(c.e)then c.e:Remove()end
end
local function startCross()
 phase=1;local direction=Vector(flight.dx,flight.dy,0);local side=Vector(-flight.dy,flight.dx,0)
 local from=flight.base-direction*(LOD.Config.Geometry.StairRun*.5)+side*90+Vector(0,0,2)
 local goal=flight.base+direction*80-side*90+Vector(0,0,2)
 for _,kind in ipairs({'ordinary','warden','hector','neil','generic_boss'})do
  local e=spawn(kind,from);local ok=clear(e);assert(ok,'horizontal fixture starts embedded')
  active[#active+1]={e=e,kind=kind,mode='horizontal',goal=goal,startPos=from,last=from,start=CurTime(),steps=0,travel=0,maxDisplacement=0,waypoint={pos=goal,tolerance=10}}
 end
end
local function startWalk()
 phase=2;walkIndex=walkIndex+1
 local item=walkCases[walkIndex];if not item then lease:Stop('complete');return end
 local rows={};if item[2]=='up'then N:_AppendVerticalWaypoints(graph,lower,upper,rows)else N:_AppendVerticalWaypoints(graph,upper,lower,rows)end
 local e=spawn(item[1],rows[1].pos);local from=M:WaypointPosition(e,rows[1]);assert(from);e:SetPos(from);assert(clear(e),'flight fixture starts embedded')
 e.LODWaypoints=rows;e.LODWaypointIndex=1
 active={{e=e,kind=item[1],mode=item[2],goal=rows[#rows].pos,startPos=from,last=from,start=CurTime(),steps=0,travel=0,maxDisplacement=0,route=rows}}
end
startCross()
local nextStep=CurTime()+.03
hook.Add('Think',marker,function()
 if lease.stopped or CurTime()<nextStep then return end;nextStep=CurTime()+.015
 local ok,err=pcall(function()
  lease.steps=lease.steps+1;local pending=0
  for _,c in ipairs(active)do if not c.finished then
   if not IsValid(c.e)then finish(c,false,'actor_removed')else
    local waypoint=c.route and c.e:_AdvanceWaypoint() or c.waypoint
    if not waypoint then finish(c,true,'complete_flight')else
     M:MoveToward(c.e,waypoint);c.steps=c.steps+1
     local pos=c.e:GetPos();c.travel=c.travel+pos:Distance(c.last);c.maxDisplacement=math.max(c.maxDisplacement,pos:Distance(c.startPos));c.last=pos
     local valid,tr=clear(c.e)
     if not valid then finish(c,false,'native_stair_penetration',tr)
     elseif not c.route and pos:Distance(c.goal)<=12 then finish(c,c.maxDisplacement>20,'crossed_with_clear_hull')
     elseif CurTime()-c.start>(c.route and 18 or 12)then finish(c,false,'timeout')end
    end
   end
   if not c.finished then pending=pending+1 end
  end end
  if pending==0 then startWalk()end
 end)
 if not ok then lease:Stop('error',tostring(err))end
end)
file.Write('legend_of_deborah/bench_stair_collision_started.json',util.TableToJSON({passed=true,sha=spec.sha,flight_treads=#flight.treads,flight_solids=#flight.solids,all_stair_solids=#allSolids,expected_cases=9,lease_seconds=110,original_population_frozen=true,ordinary_gameplay=false},true))
