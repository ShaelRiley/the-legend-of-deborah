-- Exercise the actual merged-wall compiler and graph/stair waypoint authority.
local env=dofile('tools/test_enemy_update.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
function table.Count(t) local n=0;for _ in pairs(t) do n=n+1 end;return n end
dofile(root..'sh_rng.lua')
dofile(root..'sv_maze_generator.lua')
local G,MC,GC=LOD.MazeGenerator,LOD.Config.Maze,LOD.Config.Geometry
local key=G.CellKey
local boxes={}
ents={Create=function(class)
    assert(class=='lod_static_box')
    local e={valid=true}
    function e:SetPos(v) self.pos=v end
    function e:SetAngles() end
    function e:SetBoxMins(v) self.mins=v end
    function e:SetBoxMaxs(v) self.maxs=v end
    function e:SetBoxKind(v) self.kind=v end
    function e:Spawn() assert(self.kind==4);boxes[#boxes+1]=self end
    function e:Activate() end
    function e:IsLODCollisionReady() return true end
    return e
end}
LOD.WallVisuals={SetSegments=function() return true end}
local B=LOD.MazeBuilder
B._Register=function(_,e) assert(IsValid(e)) end
B.BuildFailures=0
angle_zero={}
dofile(root..'sv_maze_builder_static_walls.lua')
local function edge(a,b) local x,y=key(a.x,a.y,a.z),key(b.x,b.y,b.z);return x<y and x..'|'..y or y..'|'..x end
local function compile(g) boxes={};B:_BuildWalls(g);return boxes end
local function hit(from,to,hull)
 for _,box in ipairs(boxes) do
    local low,high=box.pos+box.mins,box.pos+box.maxs
    local enter,leave=0,1
    for _,axis in ipairs({'x','y','z'}) do
        local lo,hi=low[axis],high[axis]
        if hull then lo=lo-(axis=='z' and 72 or 16);hi=hi+(axis=='z' and 0 or 16) end
        local delta=to[axis]-from[axis]
        if math.abs(delta)<.00001 then
            if from[axis]<=lo or from[axis]>=hi then enter=2;break end
        else
            local a,b=(lo-from[axis])/delta,(hi-from[axis])/delta
            if a>b then a,b=b,a end
            enter,leave=math.max(enter,a),math.min(leave,b)
        end
    end
    if enter<leave and leave>0 and enter<1 then return true end
 end
 return false
end
local a,b={x=3,y=3,z=0},{x=4,y=3,z=0}
local upperA,upperB={x=3,y=3,z=1},{x=4,y=3,z=1}
local g={Cells={[key(3,3,0)]=a,[key(4,3,0)]=b},Edges={}}
compile(g)
for _,z in ipairs({280,600,1200,4000,16000}) do
 assert(hit(B:CellCenter(a)+Vector(0,0,z),B:CellCenter(b)+Vector(0,0,z),true),'Cannot vault a crate boundary at height '..z)
end
for _,c in ipairs({upperA,upperB}) do g.Cells[key(c.x,c.y,c.z)]=c end
g.Edges[edge(upperA,upperB)]={a=upperA,b=upperB}
compile(g)
assert(hit(B:CellCenter(a)+Vector(0,0,280),B:CellCenter(b)+Vector(0,0,280),true))
assert(not hit(B:CellCenter(upperA)+Vector(0,0,2),B:CellCenter(upperB)+Vector(0,0,2),true),'Upper crossing must remain open')
-- Adjacent segments with different ceilings cannot be merged across the opening.
local c,d={x=3,y=4,z=0},{x=4,y=4,z=0}
g.Cells[key(3,4,0)]=c;g.Cells[key(4,4,0)]=d;compile(g)
assert(hit(B:CellCenter(c)+Vector(0,0,600),B:CellCenter(d)+Vector(0,0,600),true),'Adjacent tall segment must remain closed')
assert(not hit(B:CellCenter(upperA)+Vector(0,0,2),B:CellCenter(upperB)+Vector(0,0,2),true))
g.Edges={};g.Cells[key(4,3,1)]=nil;g.WardenVoid={[key(4,3,1)]=true};compile(g)
assert(not hit(B:CellCenter(upperA)+Vector(0,0,2),B:CellCenter(upperB)+Vector(0,0,2),true),'Gallery overlook must remain open')
local crossings,stairs,peak=0,0,0
for seed=1,8 do
 local graph=assert(G:Generate(seed*7719))
 compile(graph);peak=math.max(peak,#boxes)
 for _,e in pairs(graph.Edges) do
    if e.a.z==e.b.z then
        assert(not hit(B:CellCenter(e.a)+Vector(0,0,2),B:CellCenter(e.b)+Vector(0,0,2),true),'Canonical horizontal edge blocked')
        crossings=crossings+1
    end
 end
 for _,e in ipairs(graph.VerticalEdges) do
    local path=LOD.MazeNavigator:PathToWaypoints(graph,{e.a,e.b})
    for i=2,#path do
        assert(not hit(path[i-1].pos+Vector(0,0,2),path[i].pos+Vector(0,0,2),true),'Compiled stair flight blocked by overhead wall')
    end
    stairs=stairs+1
 end
end
assert(crossings>100 and stairs>=24)
print('OVERHEAD_WALLS_PASS: five vault heights; upper opening; gallery; split merge; '..crossings..' legal crossings and '..stairs..' stair flights across eight seeds; peak '..peak..' merged boxes')

-- Closed doors use the same overhead column; opening removes the entire native
-- collision on that entity, including repeated black-gate reconciliation.
local classes={}
local oldAdd,oldInclude=AddCSLuaFile,include
AddCSLuaFile=function() end;include=function() end
for _,name in ipairs({'lod_gate','lod_jail_door'}) do
 ENT={};dofile('gamemodes/legend_of_deborah/entities/entities/'..name..'/init.lua');classes[name]=ENT
end
AddCSLuaFile,include=oldAdd,oldInclude
SOLID_BBOX=2;SOLID_NONE=0
local originalCreate=ents.Create
ents.Create=function(name)
 if not classes[name] then return originalCreate(name) end
 local e=setmetatable({valid=true},{__index=classes[name]})
 for _,field in ipairs({'Pos','GateAxis','DoorAxis','GateIndex','Opened','OpenedAt','Solid','NotSolid'}) do
  e['Set'..field]=function(self,value) self[field]=value end
  e['Get'..field]=function(self) return self[field] end
 end
 for _,method in ipairs({'SetModel','SetMoveType','SetCollisionGroup','SetUseType','DrawShadow','AddEFlags','Activate','EmitSound','CollisionRulesChanged'}) do e[method]=function() end end
 e.SetCollisionBounds=function(self,mins,maxs) self.mins,self.maxs=mins,maxs end
 e.Spawn=function(self) self:Initialize() end
 return e
end
dofile(root..'sv_progression_builder.lua')
local doorGraph={Cells={[key(3,3,0)]=a,[key(4,3,0)]=b},Edges={}}
local meta={beforeCell=a,afterCell=b,index=4}
for _,kind in ipairs({'gate','jail'}) do
 local e=kind=='gate' and B:_SpawnProgressionGate(meta,doorGraph) or B:_SpawnJailDoor(meta,doorGraph)
 assert(e.Solid==SOLID_BBOX and e.Pos.z+e.maxs.z==16384,'Closed door cannot be vaulted')
 if kind=='gate' then e:OpenGate();e:OpenGate() else e:OpenDoor() end
 assert(e.Solid==SOLID_NONE and e.NotSolid and e.Opened,'Door opens its entire overhead collision')
end
print('OVERHEAD_DOORS_PASS: native gate/jail collision extension and complete idempotent gate opening')
