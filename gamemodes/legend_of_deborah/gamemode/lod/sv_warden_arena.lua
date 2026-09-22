-- A bounded extension of the canonical maze graph, built by the same floor,
-- stair and wall authorities. No teleporter, detached arena or physics props.
LOD.WardenArena = LOD.WardenArena or {}
local A=LOD.WardenArena
local P,N,B=LOD.ProgressionDirector,LOD.MazeNavigator,LOD.MazeBuilder
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function ek(a,b) a,b=key(a),key(b);return a<b and a.."|"..b or b.."|"..a end
local function coord(c) return {x=c.x,y=c.y,z=c.z} end
function A:Plan(g)
    local p=g.Progression
    local goal=g.Cells[key(g.Goal)]
    if not goal or goal.x~=LOD.Config.Maze.Width then return false,"Warden entrance requires east terminal" end
    local x,y,z=goal.x,goal.y,goal.z
    if z+1>6 then return false,"Warden exceeds topology floor encoding" end
    local a={cells={},court={},entry={x=x+1,y=y,z=z},center={x=x+3,y=y,z=z}}
    local function cell(cx,cy,cz,court)
        local c={x=cx,y=cy,z=cz,neighbors={}};local k=key(c)
        assert(not g.Cells[k],"Warden reservation overlaps maze")
        g.Cells[k]=c;a.cells[k]=true;if court then a.court[k]=true end;return c
    end
    local function join(c,d,vertical)
        c,d=g.Cells[key(c)],g.Cells[key(d)]
        c.neighbors[key(d)]=true;d.neighbors[key(c)]=true
        local e={a=coord(c),b=coord(d)};g.Edges[ek(c,d)]=e
        if vertical then g.VerticalEdges[#g.VerticalEdges+1]=e end
    end
    cell(x+1,y,z)
    for dz=0,1 do for dx=2,4 do for dy=-1,1 do
        if dz==0 or dx~=3 or dy~=0 then cell(x+dx,y+dy,z+dz,true) end
    end end end
    local jail=cell(x+5,y,z)
    for k in pairs(a.court) do
        local c=g.Cells[k]
        for _,o in ipairs({{1,0},{0,1}}) do
            local d=g.Cells[LOD.MazeGenerator.CellKey(c.x+o[1],c.y+o[2],c.z)]
            if d and a.court[key(d)] then join(c,d) end
        end
    end
    join(goal,a.entry);join(a.entry,{x=x+2,y=y,z=z})
    for _,dy in ipairs({-1,1}) do join({x=x+2,y=y+dy,z=z},{x=x+2,y=y+dy,z=z+1},true) end
    local before={x=x+4,y=y,z=z};join(before,jail)
    a.lock={index=4,beforeCell=coord(goal),afterCell=coord(a.entry),edgeKey=ek(goal,a.entry)}
    p.JailEdge={beforeCell=before,afterCell=coord(jail),edgeKey=ek(before,jail),pathIndex=#g.CriticalPath+6}
    p.DeborahCell=coord(jail);p.CoreCell=coord(a.center);p.Warden=a
    g.WardenVoid={[LOD.MazeGenerator.CellKey(x+3,y,z+1)]=true}
    g.WanderLayers=g.Layers -- the private gallery is not a new wandering floor
    g.Layers=math.max(g.Layers,z+2);g.Width=x+5
    p.Validation.orderedRoute="Start>Red>Blue>Yellow>Neil>Black Keycard>Black Gate>Gordon>Jail Key>Jail Door>Deborah"
    local blocked={[p.Gates[4].edgeKey]=true,[p.JailEdge.edgeKey]=true}
    local reach=LOD.NeilBrute:Walk(g,{key(g.Start)},blocked)
    if reach[key(a.entry)] then return false,"boss entry bypasses Black Gate" end
    blocked[p.Gates[4].edgeKey]=nil
    reach=LOD.NeilBrute:Walk(g,{key(g.Start)},blocked)
    for k in pairs(a.court) do if not reach[k] then return false,"disconnected Warden court" end end
    if reach[key(jail)] then return false,"boss jail bypass" end
    return true,p
end
local plan=P.Plan
function P:Plan(g,seed)
    local ok,err=plan(self,g,seed);if not ok then return ok,err end
    return A:Plan(g)
end
local build=B._BuildProgressionEntities
function B:_BuildProgressionEntities(g)
    build(self,g)
    local a=g.Progression.Warden
    if a then
        local e=self:_SpawnProgressionGate(a.lock, g);self:_Register(e)
        if IsValid(e) then e.LODWardenEntry=true;e:OpenGate() end
    end
end
local traverse=N.CanTraverse
function N:CanTraverse(g,ak,bk)
    local a=g.Progression and g.Progression.Warden
    if a then
        local edge=ak<bk and ak.."|"..bk or bk.."|"..ak
        local s=LOD.RunManager.State
        if edge==a.lock.edgeKey and s.WardenStarted and not (s.Warden and s.Warden.dead) then return false end
        if edge==g.Progression.JailEdge.edgeKey and not s.JailDoorOpen then return false end
    end
    return traverse(self,g,ak,bk)
end
