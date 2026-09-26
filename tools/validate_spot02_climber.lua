-- Finite SPOT02 regression harness. Runs the actual Climber module with engine
-- boundaries stubbed; this is not native Source collision or multiplayer proof.
-- Run from repository root: lua tools/validate_spot02_climber.lua
local passed,failed=0,0
local function check(name,ok)
    if ok then passed=passed+1;print('PASS '..name)
    else failed=failed+1;print('FAIL '..name) end
end
local v={};v.__index=v
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},v) end
function v.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function v.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function v.__mul(a,b) if type(a)=='number' then a,b=b,a end;return Vector(a.x*b,a.y*b,a.z*b) end
function v.__div(a,b) return a*(1/b) end
function v:LengthSqr() return self.x*self.x+self.y*self.y+self.z*self.z end
function v:Length() return math.sqrt(self:LengthSqr()) end
function v:GetNormalized() local n=self:Length();return n>0 and self/n or Vector() end
function v:DistToSqr(b) return (self-b):LengthSqr() end
function v:Distance(b) return math.sqrt(self:DistToSqr(b)) end
function Angle(p,y,r) return {p=p,y=y,r=r,Forward=function(a) return Vector(math.cos(math.rad(a.y)),math.sin(math.rad(a.y)),0) end} end
math.Clamp=function(n,lo,hi) return math.max(lo,math.min(hi,n)) end
vector_origin=Vector();NULL={valid=false};MASK_NPCSOLID=1;MASK_SOLID=2;MASK_SHOT=3;ACT_IDLE=1;ACT_RUN=2;ACT_CLIMB_UP=3
local now,traceHook,entryDenied=0,nil,false
function CurTime() return now end
function IsValid(a) return type(a)=='table' and a.valid~=false end
local commands={};concommand={Add=function(name,fn) commands[name]=fn end}
util={TraceHull=function(t) return traceHook and traceHook(t) or {Hit=false,StartSolid=false} end,
    TraceLine=function() return {Hit=false,StartSolid=false} end}
local function key(c,y,z) if type(c)=='table' then return c.x..':'..c.y..':'..c.z end;return c..':'..y..':'..z end
LOD={Config={Maze={CellSize=384},Geometry={ContainerWidth=128},Encounter={LeashCells=6}},
    MazeGenerator={CellKey=key},EnemyRoster={},MazeNavigator={},EnemyUpdate={},RunManager={},HostileMotionV2={},RPGStatusElements={},EntrySafety={}}
local E,N,U,M,S=LOD.EnemyRoster,LOD.MazeNavigator,LOD.EnemyUpdate,LOD.HostileMotionV2,LOD.RPGStatusElements
E.Key=key
function E:Safe(g,c) local t=c and g.CellTags[key(c)] or {};return not c or t and (t.safe or t.entryApron or t.role=='boss' or t.role=='resupply') end
function N:CellCenter(c) return Vector(c.x*384,c.y*384,c.z*384) end
function N:WorldToCell(g,p) return g.Cells[key(math.floor(p.x/384+.5),math.floor(p.y/384+.5),math.floor(p.z/384+.5))] end
function N:CanTraverse(g,a,b) return not g.blocked[a..'|'..b] and not g.blocked[b..'|'..a] end
function N:PathToWaypoints(g,a) g.stairCalls=(g.stairCalls or 0)+1;return {{pos=self:CellCenter(a[1])},{pos=self:CellCenter(a[2])}} end
function E:LegalStep(e,a,b)
    local g=LOD.RunManager.State.Graph;local x,y=N:WorldToCell(g,a),N:WorldToCell(g,b)
    return not self:Safe(g,x) and not self:Safe(g,y) and x.z==y.z
        and (key(x)==key(y) or x.neighbors[key(y)] and N:CanTraverse(g,key(x),key(y)))
end
function U:Reachable(g,start,maximum)
    local d,q={[start]=0},{start};local head=1
    while q[head] do
        local k=q[head];head=head+1
        if d[k]<maximum then for nk in pairs(g.Cells[k].neighbors) do
            local t=g.CellTags[nk] or {}
            if not d[nk] and not t.safe and t.role~='boss' and N:CanTraverse(g,k,nk) then d[nk]=d[k]+1;q[#q+1]=nk end
        end end
    end
    return d
end
function E:AcquireTarget(p) return IsValid(p) and p.hero==true and not p.hidden end
function E:Visible() return true end
function E:Damage(e,p) e.bites=(e.bites or 0)+1 end
function M:Stop(e) e.LODMotionSpeed=0;e.LODMotionVelocity=vector_origin end
function M:FaceToward() end
function M:HoldHitStun(e,t) return t<(e.LODHitStunUntil or 0) end
function S:CanMoveVoluntarily(e) return not e.held end
function S:CanInitiateAttack(e) return not e.noAttack end
function S:Has(e,id) return e.fleeing,e.fleeing and {source=e.LODTarget} or nil end
function LOD.EntrySafety:MovementAllowed(e,a,b)
    e.entryChecks=(e.entryChecks or 0)+1
    local g=LOD.RunManager.State.Graph
    return not entryDenied and not E:Safe(g,N:WorldToCell(g,a)) and not E:Safe(g,N:WorldToCell(g,b))
end
local function graph()
    now=0;traceHook=nil;entryDenied=false
    local g={Cells={},CellTags={},blocked={}}
    LOD.RunManager.State={Graph=g,BuildReady=true}
    return g
end
local function cell(g,x,y,z)
    local c={x=x,y=y,z=z or 0,neighbors={}};g.Cells[key(c)]=c;return c
end
local function link(a,b) a.neighbors[key(b)]=true;b.neighbors[key(a)]=true end
local function cross()
    local g=graph();local west=cell(g,-1,0);local mid=cell(g,0,0);local east=cell(g,1,0)
    local north,south=cell(g,0,1),cell(g,0,-1)
    link(west,mid);link(mid,east);link(mid,north);link(mid,south)
    return g,west,mid,east
end
local function entity(c,pos)
    local e={pos=pos or N:CellCenter(c)+Vector(0,106,100),valid=true,LODArchetypeId='climber',LODHomeCellKey=key(c),
        LODWallInitialized=true,LODConfig={speed=205,fireRange=225},noAttack=true,LODActivated=true}
    function e:GetPos() return self.pos end;function e:SetPos(p) self.pos=p end
    function e:_SetActivity(a) self.activity=a end;function e:SetAngles(a) self.angles=a end
    function e:SetNW2Entity(k,x) self[k]=x end;function e:EmitSound() self.sounds=(self.sounds or 0)+1 end
    function e:_RefreshTarget() end;function e:Health() return 14 end;function e:EntIndex() return 1 end
    function e:IsPlayer() return self.hero==true end;function e:IsAdmin() return false end
    function e:EyePos() return self.pos+Vector(0,0,64) end
    function e:EyeAngles() return self.angles or Angle(0,0,0) end
    return e
end
local function hero(c) local p=entity(c,N:CellCenter(c));p.hero=true;return p end
local C
local source=os.getenv('LOD_CLIMBER_SOURCE') or 'gamemodes/legend_of_deborah/gamemode/lod/sv_climber.lua'
assert(loadfile(source))();C=LOD.Climber
local function endpoint(e) local r=e.LODWallRoute;return r and r[#r] end
local function finishRoute(e,max)
    for i=1,max or 500 do
        local wp=e.LODWallRoute and e.LODWallRoute[e.LODWallRouteIndex or 1]
        if not wp then return end
        if C:Step(e,wp.pos,205,.05,wp.stair) then e.LODWallRouteIndex=(e.LODWallRouteIndex or 1)+1 end
    end
end
local function ticks(e,n)
    for i=1,n do now=now+.05;C:Tick(e,LOD.RunManager.State,now) end
end
-- Positive regression: legal pursuit through a four-open-sided junction.
do
    local g,w,m,east=cross();local e=entity(w);local p=hero(east)
    check('junction is not a spawn wall',next(C:Lanes(g,m))==nil and C:NearestLane(g,m,p:GetPos())==nil)
    C:Route(e,g,p,false)
    local last=endpoint(e)
    check('pursuit route reaches opposite wall beyond junction',last and last.lane and key(last.lane.cell)==key(east))
    finishRoute(e)
    check('production Step traverses the junction',key(N:WorldToCell(g,e:GetPos()))==key(east))
    check('movement uses sanctuary admission', (e.entryChecks or 0)>0)
end
-- Consecutive wall-free cells, and acquisition from inside one.
do
    local g,w,m,east=cross();local finish=cell(g,2,0);link(east,finish)
    link(east,cell(g,1,1));link(east,cell(g,1,-1))
    local e=entity(w);C:Route(e,g,hero(finish),false)
    check('route crosses two consecutive wall-free junctions',endpoint(e) and key(endpoint(e).lane.cell)==key(finish))
    local inside=entity(w,N:CellCenter(m)+Vector(0,0,100));C:Route(inside,g,hero(finish),false)
    check('pursuit can begin inside a connector',endpoint(inside) and key(endpoint(inside).lane.cell)==key(finish))
end
-- Retiring a leap or latch in a junction must return to a real wall.
do
    local g,w,m=cross();local e=entity(w,N:CellCenter(m)+Vector(0,0,64))
    C:Detach(e);ticks(e,180)
    check('detach in junction exits wall-return state',not e.LODWallReturn)
    check('detach finishes on a real wall, not a virtual perch',e.LODWallLane and e.LODWallLane.side~=0 and not e.LODWallLane.transit)
    check('detach does not teleport back to spawn',e:GetPos():DistToSqr(N:CellCenter(m)+Vector(0,0,64))>1 and (e.entryChecks or 0)>1)
    local interrupted=entity(w,N:CellCenter(m)+Vector(0,0,90));interrupted.LODClimberLeap={target=hero(m),goal=Vector(),expires=10}
    C:Interrupt(interrupted);ticks(interrupted,180)
    check('interrupted junction leap returns to wall',not interrupted.LODClimberLeap and not interrupted.LODWallReturn and interrupted.LODWallLane~=nil)
end
-- No fabricated lane through a blocked wall cell, or blocked center.
do
    local g,w,m,east=cross();local e=entity(w)
    traceHook=function(t) return {Hit=t.start.x==0 and t.endpos.x==0,StartSolid=false} end
    C:Route(e,g,hero(east),false)
    check('blocked junction center has no transit route',not endpoint(e) or key(endpoint(e).lane.cell)~=key(east))
    g=graph();local a,b,c=cell(g,0,0),cell(g,1,0),cell(g,2,0);link(a,b);link(b,c)
    traceHook=function(t) return {Hit=t.start.x==384 and math.abs(t.start.y)>50,StartSolid=false} end
    e=entity(a);C:Route(e,g,hero(c),false)
    check('occluded real walls do not become invented connectors',not endpoint(e) or key(endpoint(e).lane.cell)~=key(c))
end
-- Gate state, safety regions, and the existing home leash remain authoritative.
do
    local g,w,m,east=cross();g.blocked[key(m)..'|'..key(east)]=true
    local e=entity(w);C:Route(e,g,hero(east),false)
    check('locked gate excludes destination',not endpoint(e) or key(endpoint(e).lane.cell)~=key(east))
    g.blocked={};C:Route(e,g,hero(east),false)
    check('opened gate restores route',endpoint(e) and key(endpoint(e).lane.cell)==key(east))
    for _,tag in ipairs({{safe=true},{entryApron=true},{role='resupply'},{role='boss'}}) do
        g.CellTags[key(m)]=tag;C:Route(e,g,hero(east),false)
        check('protected junction blocks transit '..(tag.role or (tag.entryApron and 'apron' or 'sanctuary')),not endpoint(e) or key(endpoint(e).lane.cell)~=key(east))
    end
    g.CellTags={};LOD.Config.Encounter.LeashCells=1;C:Route(e,g,hero(east),false)
    check('home leash excludes distant wall',not endpoint(e) or key(endpoint(e).lane.cell)~=key(east));LOD.Config.Encounter.LeashCells=6
end
-- Recheck physical and sanctuary admission at execution, not only plan time.
do
    local g,w,m,east=cross();local e=entity(w);local from=e:GetPos();local goal=from+Vector(10,0,0)
    traceHook=function() return {Hit=true,StartSolid=false} end;C:Step(e,goal,205,.05,false)
    check('swept collision prevents travel',e:GetPos():DistToSqr(from)==0)
    traceHook=function() return {Hit=false,StartSolid=true} end;C:Step(e,goal,205,.05,false)
    check('start-solid prevents travel',e:GetPos():DistToSqr(from)==0)
    traceHook=nil;entryDenied=true;C:Step(e,goal,205,.05,false)
    check('sanctuary guard prevents travel',e:GetPos():DistToSqr(from)==0)
    entryDenied=false;g.blocked[key(w)..'|'..key(m)]=true;e:SetPos(Vector(-195,0,100));from=e:GetPos()
    C:Step(e,Vector(-175,0,100),205,.05,false)
    check('gate closed after planning prevents execution',e:GetPos():DistToSqr(from)==0)
end
-- Existing flat wall following, corners, actual stair waypoints and morale direction.
do
    local g=graph();local a,b,c=cell(g,0,0),cell(g,1,0),cell(g,2,0);link(a,b);link(b,c)
    local e=entity(a);C:Route(e,g,hero(c),false)
    check('ordinary wall corridor remains routable',endpoint(e) and key(endpoint(e).lane.cell)==key(c))
    finishRoute(e);check('ordinary wall corridor reaches target cell',key(N:WorldToCell(g,e:GetPos()))==key(c))
    e=entity(b);C:Route(e,g,hero(c),true)
    check('morale route increases distance',endpoint(e) and endpoint(e).pos:DistToSqr(hero(c):EyePos())>e:GetPos():DistToSqr(hero(c):EyePos()))
    g=graph();a,b=cell(g,0,0),cell(g,0,0,1);link(a,b);e=entity(a)
    C:Route(e,g,hero(b),false)
    local stair=false;for _,wp in ipairs(e.LODWallRoute or {}) do stair=stair or wp.stair end
    check('vertical route uses canonical stair itinerary',(g.stairCalls or 0)>0 and stair)
    local from=e:GetPos();entryDenied=true;C:Step(e,from+Vector(0,0,20),205,.05,true)
    check('stair exemption never bypasses sanctuary',e:GetPos():DistToSqr(from)==0)
end
-- Stun/held movement and bounded recovery when no legal wall is available.
do
    local g,w,m=cross();local e=entity(w,N:CellCenter(m)+Vector(0,0,90));C:Detach(e)
    local from=e:GetPos();e.held=true;ticks(e,20)
    check('Held blocks return movement',e:GetPos():DistToSqr(from)==0)
    e.held=nil;e.LODHitStunUntil=now+2;ticks(e,20)
    check('hit stun blocks return movement',e:GetPos():DistToSqr(from)==0)
    e.LODHitStunUntil=0;for k in pairs(m.neighbors) do g.blocked[key(m)..'|'..k]=true end
    local originalRoute=C.Route;local calls=0
    C.Route=function(self,...) calls=calls+1;return originalRoute(self,...) end
    ticks(e,40);C.Route=originalRoute
    check('no legal return waits without teleport',e:GetPos():DistToSqr(from)==0 and e.LODWallReturn)
    check('failed recovery retries are throttled',calls>=1 and calls<=3)
    g.blocked={};ticks(e,180)
    check('return retries after reopening a route',not e.LODWallReturn and e.LODWallLane~=nil)
end
-- A former victim may have carried the Climber outside its original home leash.
do
    local g,w,m=cross();local oldHome=cell(g,-9,0)
    local e=entity(oldHome,N:CellCenter(m)+Vector(0,0,90));C:Detach(e);ticks(e,180)
    check('carried Climber recovers outside original pursuit leash',not e.LODWallReturn and e.LODWallLane~=nil)
    check('outside-leash recovery ends on a real wall',e.LODWallLane and not e.LODWallLane.transit)
end
-- Latch interruption and shared damage semantics stay unchanged.
do
    local g,w,m=cross();local p=hero(m);local e=entity(w,N:CellCenter(m)+Vector(0,0,50))
    e.LODClimberVictim=p;e.LODClimberFloor=0;e.noAttack=false
    C:Tick(e,LOD.RunManager.State,now);check('latch damage uses shared roster authority',e.bites==1)
    C:Interrupt(e);check('interrupt retains latch and delays bite',e.LODClimberVictim==p and e.LODNextBite==now+.4)
    ticks(e,5);check('interruption does not accelerate bite',e.bites==1)
    g.CellTags[key(m)]={safe=true};ticks(e,1)
    check('sanctuary target detaches latch',not e.LODClimberVictim and e.LODWallReturn)
end
do
    local status=commands.lod_climber_status
    check('read-only release diagnostic is registered',type(status)=='function')
    if status then
        local g,w=cross();local e=entity(w);local output={};local originalPrint=print
        LOD.EncounterDirector={Plan={ecology={theme='hunting'},encounters={
            {composition={climber=1}},{composition={climber=1},spawned=true}}},Entities={e}}
        E.PlacementStats={climber={accepted=2,rejected=1}}
        print=function(line) output[#output+1]=line end
        output={};status(entity(w));local denied=#output==0
        status(NULL);local text=table.concat(output,'\n');print=originalPrint
        check('ordinary player cannot query hidden enemies',denied)
        check('diagnostic distinguishes current composition, dormant, and living',text:find('currentComposition=2 dormant=1 living=1',1,true)~=nil)
        check('diagnostic exposes placement rejection separately',text:find('placementAccepted=2 placementRejected=1',1,true)~=nil)
        check('diagnostic preserves enemy state',e:GetPos():DistToSqr(N:CellCenter(w)+Vector(0,106,100))==0 and not e.LODWallRoute)
    else
        check('ordinary player cannot query hidden enemies',false)
        check('diagnostic distinguishes current composition, dormant, and living',false)
        check('diagnostic exposes placement rejection separately',false)
        check('diagnostic preserves enemy state',false)
    end
end
print(string.format('SPOT02 Climber: %d passed, %d failed',passed,failed))
if failed>0 then error('SPOT02 Climber regression failures',0) end
