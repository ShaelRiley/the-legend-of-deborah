-- Production stair builder, rotated SOLID_BBOX bounds and hostile movement kernel.
-- TraceHull is a geometric swept-AABB boundary double, not native Source proof.
dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local noop=function() end
local clock=100
CurTime=function() return clock end
local V=getmetatable(Vector())
V.__div=function(a,b) return Vector(a.x/b,a.y/b,a.z/b) end
V.__unm=function(a) return Vector(-a.x,-a.y,-a.z) end
function V:Length2D() return math.sqrt(self.x*self.x+self.y*self.y) end
function V:Length2DSqr() return self.x*self.x+self.y*self.y end
function V:Dot(b) return self.x*b.x+self.y*b.y+self.z*b.z end
function Angle(p,y,r) return {p=p or 0,y=y or 0,r=r or 0} end
angle_zero=Angle()
MOVETYPE_NONE,SOLID_BBOX,COLLISION_GROUP_NONE,EFL_FORCE_CHECK_TRANSMIT=0,2,0,128
function table.Count(t) local n=0;for _ in pairs(t)do n=n+1 end;return n end
timer.Create=noop;timer.Remove=noop
LOD.HostileAnimation=nil;LOD.RPGStatusElements=nil;LOD.RPGAbilityRules=nil
LOD.MagicForms=nil;LOD.EntrySafety=nil;LOD.BossEncounter=nil
-- Load the actual class so waypoint advancement is also the production seam.
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_hostile/init.lua')
local Hostile=ENT
scripted_ents.GetStored=function(name)if name=='lod_hostile'then return{t=Hostile}end end
LOD.HostileMotionV2={}
dofile(root..'sv_hostile_motion_v2.lua')
local Motion=LOD.HostileMotionV2
assert(type(Motion.TraceStairMovement)=='function' and type(Motion.WaypointPosition)=='function',
    'production stair movement authority is missing')
dofile(root..'sh_rng.lua');dofile(root..'sv_maze_generator.lua')
dofile(root..'sv_maze_builder.lua');dofile(root..'sv_maze_builder_floor_anchor.lua')
local B,G,N,MC,GC=LOD.MazeBuilder,LOD.MazeGenerator,LOD.MazeNavigator,LOD.Config.Maze,LOD.Config.Geometry
B.Build=function(_,graph)return graph end
dofile(root..'sv_m1_stair_geometry.lua')
ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/lod_static_box/init.lua')
local Box=ENT
local boxes={};local traceCalls=0
ents.Create=function(name)
 assert(name=='lod_static_box')
 local e=setmetatable({valid=true},{__index=Box})
 for _,field in ipairs({'Pos','Angles','BoxMins','BoxMaxs','BoxKind','Solid'})do
  e['Set'..field]=function(self,v)self[field]=v end
  e['Get'..field]=function(self)return self[field]end
 end
 for _,method in ipairs({'SetModel','SetMoveType','SetSolidFlags','SetCollisionGroup','DrawShadow','AddEFlags','Activate','SetNW2Bool'})do e[method]=noop end
 function e:GetClass()return 'lod_static_box'end
 function e:IsPlayer()return false end
 function e:SetCollisionBounds(a,b)self.collisionMins,self.collisionMaxs=a,b;self.low,self.high=self.Pos+a,self.Pos+b end
 function e:GetCollisionBounds()return self.collisionMins,self.collisionMaxs end
 function e:WorldSpaceAABB()return self.low,self.high end
 function e:Spawn()self:Initialize();boxes[#boxes+1]=self end
 function e:Remove()self.valid=false end
 return e
end
local EPS=1e-7
local function strictInside(p,lo,hi)
 return p.x>lo.x+EPS and p.x<hi.x-EPS and p.y>lo.y+EPS and p.y<hi.y-EPS and p.z>lo.z+EPS and p.z<hi.z-EPS
end
local function swept(q,e)
 local lo,hi=e.low-q.maxs,e.high-q.mins
 local from,to=q.start,q.endpos;local d=to-from
 local enter,leave=0,1;local normal=Vector()
 for _,axis in ipairs({'x','y','z'})do
  local p,v,a,b=from[axis],d[axis],lo[axis]+EPS,hi[axis]-EPS
  if math.abs(v)<EPS then if p<=a or p>=b then return nil end
  else
   local first,last=(a-p)/v,(b-p)/v;local sign=-1
   if first>last then first,last=last,first;sign=1 end
   if first>enter then enter=first;normal=Vector();normal[axis]=sign end
   leave=math.min(leave,last);if enter>leave then return nil end
  end
 end
 local startSolid=strictInside(from,lo,hi)
 if not startSolid and (enter<0 or enter>=1 or leave<=0)then return nil end
 return{Hit=true,StartSolid=startSolid,AllSolid=startSolid and strictInside(to,lo,hi),Fraction=startSolid and 0 or enter,
  FractionLeftSolid=leave,HitPos=from+d*(startSolid and 0 or enter),HitNormal=normal,Entity=e}
end
local function included(q,e)
 if type(q.filter)=='function'then return q.filter(e)~=false end
 if type(q.filter)=='table'then
  local found=false;for _,v in ipairs(q.filter)do if v==e then found=true;break end end
  return q.whitelist and found or not q.whitelist and not found
 end
 return q.filter~=e
end
local function geometricTrace(q)
 traceCalls=traceCalls+1
 assert(q.start and q.endpos and q.mins and q.maxs,'trace omitted its hull')
 local result={Hit=false,StartSolid=false,AllSolid=false,Fraction=1,HitPos=q.endpos,HitNormal=Vector()}
 for _,e in ipairs(boxes)do if IsValid(e)and included(q,e)then
  local hit=swept(q,e)
  if hit and (hit.StartSolid or hit.Fraction<result.Fraction)then result=hit;if hit.StartSolid then break end end
 end end
 return result
end
util.TraceHull=geometricTrace
local function clearAt(e,p)
 for _,box in ipairs(boxes)do if IsValid(box) and strictInside(p,box.low-e.high,box.high-e.low)then return false,box end end
 return true
end
local function actor(pos,kind,radius,height)
 local e=setmetatable({valid=true,LODHostile=true,LODActivated=true,LODConfig={speed=90},pos=pos,
  low=Vector(-(radius or 16),-(radius or 16),0),high=Vector(radius or 16,radius or 16,height or 72),LODArchetypeId=kind or'soldier'}, {__index=Hostile})
 if kind=='warden'then e.LODWarden=true elseif kind=='hector'then e.LODHector=true elseif kind=='neilbrute'then e.LODNeilBrute=true end
 function e:GetPos()return self.pos end
 function e:SetPos(p)local ok,box=clearAt(self,p);assert(ok,string.format('penetration case=%s pos=(%.9f,%.9f,%.9f) boxkind=%s box=(%.9f,%.9f,%.9f)-(%.9f,%.9f,%.9f) old=(%.9f,%.9f,%.9f)',self.caseLabel or'?',p.x,p.y,p.z,tostring(box and box.BoxKind),box and box.low.x or 0,box and box.low.y or 0,box and box.low.z or 0,box and box.high.x or 0,box and box.high.y or 0,box and box.high.z or 0,self.pos.x,self.pos.y,self.pos.z));self.pos=p end
 function e:GetCollisionBounds()return self.low,self.high end
 function e:WorldSpaceAABB()return self.pos+self.low,self.pos+self.high end
 function e:GetAngles()return Angle()end
 function e:SetAngles()end
 function e:GetNW2Float(_,default)return default end
 function e:IsPlayer()return false end
 function e:Health()return 100 end
 function e:GetClass()return'lod_hostile'end
 e.LODMotionLastUpdate=clock-.05
 return e
end
local axes={E={1,0},N={0,1},W={-1,0},S={0,-1}}
local function build(name,offset)
 local axis=axes[name];local a={x=5+(offset or 0),y=5,z=0,neighbors={}};local b={x=a.x,y=a.y,z=1,neighbors={}}
 local c={x=a.x-axis[1],y=a.y-axis[2],z=0,neighbors={}};local key=G.CellKey
 a.neighbors[key(c.x,c.y,c.z)]=true;a.neighbors[key(b.x,b.y,b.z)]=true;b.neighbors[key(a.x,a.y,a.z)]=true
 local edge={a=a,b=b,LODStairDirection=name,LODStairEntrySide=({E='W',W='E',N='S',S='N'})[name]}
 local g={Cells={[key(a.x,a.y,a.z)]=a,[key(b.x,b.y,b.z)]=b,[key(c.x,c.y,c.z)]=c},VerticalEdges={edge}}
 boxes={};B.Entities={};B.BuildFailures=0;B:Build(g);B:_BuildPerforatedFloor(b,edge);B:_BuildStair(edge)
 LOD.RunManager.State={Graph=g,BuildReady=true,LevelSeed=123,Level=1,GatesOpen={}}
 local center=B:CellCenter(a)
 local function at(x,y,z)return center+Vector(axis[1]*x-axis[2]*y,axis[2]*x+axis[1]*y,z)end
 return g,edge,at,a,b
end
local cases,steps=0,0
for _,name in ipairs({'E','N','W','S'})do
 local g,edge,at,lower,upper=build(name)
 -- Every ground family uses the same pre-SetPos collision authority.
 for _,kind in ipairs({'soldier','warden','hector','neilbrute'})do
  local e=actor(at(-160,120,2),kind)
  local to=at(-160,-120,2);local tr=Motion:TraceStairMovement(e,e:GetPos(),to)
  assert(tr and tr.Hit and tr.Fraction<1,'horizontal crossing tunneled through the stair body: '..name..'/'..kind)
  assert(not tr.StartSolid,'fixture starts outside the full stair/rail hull')
  local flat={pos=to,tolerance=18,stair=false};Motion:MoveToward(e,flat)
  assert(clearAt(e,e:GetPos()),'ordinary move penetrated a stair')
  cases=cases+1
  -- Switching a supported elevated actor to a flat goal cannot snap it down through a tread.
  local elevated=actor(at(-80,0,MC.LevelHeight+2),kind);elevated.caseLabel=name..'/'..kind..'/Zsnap'
  local beforeZ=elevated.pos.z;clock=clock+.05
  Motion:MoveToward(elevated,{pos=at(-80,0,2),tolerance=18,stair=false})
  assert(clearAt(elevated,elevated.pos),'non-stair goal snapped an elevated hull through a tread')
  assert(elevated.pos.z>=beforeZ-1e-6,'non-stair movement jumped down through the flight')
  cases=cases+1
 end
 -- Blocking collision must not turn a reachable same-cell Hero into a permanent stop.
 local crossing=actor(at(-80,120,2));crossing.caseLabel=name..'/complete-same-cell-crossing'
 local destination=at(-80,-120,2);local reached=false
 for tick=1,1000 do
  if crossing.pos:DistToSqr(destination)<=18^2 then reached=true;break end
  clock=clock+.05;Motion:MoveToward(crossing,{pos=destination,tolerance=18,stair=false})
 end
 assert(reached,'collision-safe movement froze instead of going around both stair corners: '..name)
 cases=cases+1
 -- A large step with both endpoints clear must still sweep, not tunnel through the flight.
 local fastStart=at(-80,120,2);local fast=actor(fastStart);fast.LODConfig.speed=10000;fast.caseLabel=name..'/large-step-sweep'
 clock=clock+.05;Motion:MoveToward(fast,{pos=at(-80,-120,2),tolerance=18,stair=false})
 local fastSweep=Motion:TraceStairMovement(fast,fastStart,fast.pos)
 assert(not fastSweep or not fastSweep.Hit,'large motion step tunneled between clear endpoints')
 cases=cases+1
 -- A same-cell goal inside the flight must correct to a clear side, not stop inside a tread.
 local sideActor=actor(at(-80,120,2));local inside={pos=at(-80,0,2),tolerance=18,stair=false}
 local sideGoal=Motion:WaypointPosition(sideActor,inside);assert(sideGoal and clearAt(sideActor,sideGoal),'inside-stair local goal has no clear side correction')
 assert(sideGoal:DistToSqr(inside.pos)>16^2,'inside-stair correction did not leave the solid flight');cases=cases+1
 -- The same XY does not complete a waypoint at an unvisited elevation.
 local e=actor(at(-360,0,2));local ups=N:PathToWaypoints(g,{lower,upper})
 assert(#ups==GC.StairSteps+2,'production route lost tread/landing waypoints')
 for _,wp in ipairs(ups)do assert(wp.stairGraph==g and wp.stairEdge==edge,'stair provenance missing')end
 e.LODWaypoints=ups;e.LODWaypointIndex=2;e.pos=Vector(ups[2].pos.x,ups[2].pos.y,ups[2].pos.z-80)
 e:_AdvanceWaypoint();assert(e.LODWaypointIndex==2,'equal XY skipped a different-height stair waypoint')
 -- Traverse the actual complete ascent and descent with production advancement.
 for _,path in ipairs({{lower,upper},{upper,lower}})do
  local route=N:PathToWaypoints(g,path);local moving=actor(route[1].pos)
  moving.LODWaypoints=route;moving.LODWaypointIndex=1;moving.caseLabel=name..'/'..path[1].z
  -- First landing may need support correction for a full footprint.
  local initial=Motion:WaypointPosition(moving,route[1]);assert(initial,'valid stair start has no supported goal');moving.pos=initial
  local done=false
  for tick=1,5000 do
   local wp=moving:_AdvanceWaypoint()
   if not wp then done=true;break end
   local goal=Motion:WaypointPosition(moving,wp);assert(goal,'normal hull lost its stair goal')
   moving.caseLabel=name..'/'..path[1].z..'/tick'..tick..'/wp'..moving.LODWaypointIndex;clock=clock+.05;Motion:MoveToward(moving,wp);assert(clearAt(moving,moving.pos),'stair traversal clipped a tread/slab/rail')
   steps=steps+1
  end
  assert(done,'complete stair traversal stalled: '..name..'/'..path[1].z)
  cases=cases+1
 end
 -- A too-wide hull must fail safely rather than cross either rail.
 local wide=actor(at(-GC.StairRun-80-40,0,2),'hector',80,96);local waypoint=N:PathToWaypoints(g,{lower,upper})[3]
 local wideRoute=N:PathToWaypoints(g,{lower,upper});wide.LODWaypoints=wideRoute;wide.LODWaypointIndex=1;wide.caseLabel=name..'/wide'
 local stuck=0;local completed=false
 for tick=1,1500 do
  local nextWP=wide:_AdvanceWaypoint();if not nextWP then completed=true;break end
  local previous=wide.pos;clock=clock+.05;Motion:MoveToward(wide,nextWP)
  if wide.pos:DistToSqr(previous)<1e-12 then stuck=stuck+1 else stuck=0 end
  assert(clearAt(wide,wide.pos),'wide hull was teleported into a rail')
  if stuck>=10 then break end
 end
 assert(not completed and stuck>=10,'oversize hull clipped through or bypassed the stair rails')
 cases=cases+1
end
-- Cache lifetime: a new graph and replacement geometry must not retain old boxes.
local g,edge,at=build('E');local e=actor(at(-160,120,2));assert(Motion:TraceStairMovement(e,e.pos,at(-160,-120,2)).Hit)
local oldStart,oldEnd=e.pos,at(-160,-120,2)
build('E',10);local cleared=Motion:TraceStairMovement(e,oldStart,oldEnd);assert(not cleared or not cleared.Hit,'graph replacement retained stale stair collision')
-- Same-graph replacement of the actual builder-owned immutable list.
local current=LOD.RunManager.State.Graph;local currentEdge=current.VerticalEdges[1];local base=B:CellCenter(currentEdge.a);local nearStart=base+Vector(-160,120,2);local nearEnd=base+Vector(-160,-120,2)
local currentActor=actor(nearStart);assert(Motion:TraceStairMovement(currentActor,nearStart,nearEnd).Hit,'replacement graph fixture never populated its index')
local originalEntities=B.Entities;B.Entities={};boxes={}
local noGeometry=Motion:TraceStairMovement(currentActor,nearStart,nearEnd);assert(not noGeometry or not noGeometry.Hit,'geometry replacement retained removed solids')
B.Entities=originalEntities
assert(traceCalls>0 and steps>100,'fixture did not exercise production movement')
print(string.format('HOSTILE_STAIR_COLLISION_PASS: cases=%d supportedmovementsteps=%d geometric_trace_calls=%d; four rotations/ordinary+legacyboss hulls/complete flights/no tunneling/full-height advancement/graph+geometry retirement; native acceptance pending',cases,steps,traceCalls))
