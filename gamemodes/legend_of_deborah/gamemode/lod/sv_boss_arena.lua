-- Boss arenas extend the same graph/floor/stair/lock authorities as Gordon.
-- Every authored court keeps two elevation routes and a clear ground grid.
local A=LOD.WardenArena
local legacy=A.Plan
local R,N=LOD.RunManager,LOD.MazeNavigator
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function coord(c) return {x=c.x,y=c.y,z=c.z} end
local function edge(a,b) a,b=key(a),key(b);return a<b and a..'|'..b or b..'|'..a end
function A:Plan(g)
    local id=LOD.BossRegistry:Modular(R.State.Level)
    if not id then return legacy(self,g) end
    local d=LOD.BossEncounter.Modules[id];if not d then return false,'missing authored boss module '..id end
    local p=g.Progression;local goal=g.Cells[key(g.Goal)]
    if not goal or goal.x~=LOD.Config.Maze.Width or goal.z+1>6 then return false,'invalid boss terminal' end
    local cfg=d.arena or {};local width=math.Clamp(math.floor(cfg.width or 5),5,7)
    local depth=math.Clamp(math.floor(cfg.depth or 5),5,7);if depth%2==0 then depth=depth+1 end
    local x,y,z=goal.x,math.Clamp(goal.y,1+math.floor(depth/2),LOD.Config.Maze.Height-math.floor(depth/2)),goal.z
    local a={bossId=id,theme=cfg.theme or id,cells={},court={},entry={x=x+1,y=goal.y,z=z},
        center={x=x+2+math.floor(width/2),y=y,z=z},width=width,depth=depth}
    local function cell(cx,cy,cz,court)
        local c={x=cx,y=cy,z=cz,neighbors={}};local k=key(c)
        if g.Cells[k] then return nil end
        g.Cells[k]=c;a.cells[k]=true;if court then a.court[k]=true end;return c
    end
    local function join(c,d,vertical)
        c,d=g.Cells[key(c)],g.Cells[key(d)];if not c or not d then return false end
        c.neighbors[key(d)]=true;d.neighbors[key(c)]=true
        local e={a=coord(c),b=coord(d)};g.Edges[edge(c,d)]=e
        if vertical then g.VerticalEdges[#g.VerticalEdges+1]=e end;return true
    end
    if not cell(a.entry.x,a.entry.y,z) then return false,'boss entry overlap' end
    g.WardenVoid={}
    local half=math.floor(depth/2)
    for dz=0,1 do for dx=0,width-1 do for dy=-half,half do
        if dz==0 or dx==0 or dx==width-1 or math.abs(dy)==half then
            if not cell(x+2+dx,y+dy,z+dz,true) then return false,'boss court overlap' end
        else g.WardenVoid[LOD.MazeGenerator.CellKey(x+2+dx,y+dy,z+dz)]=true end
    end end end
    local jail=cell(x+width+2,y,z)
    for k in pairs(a.court) do local c=g.Cells[k]
        for _,delta in ipairs({{1,0},{0,1}}) do
            local q=g.Cells[LOD.MazeGenerator.CellKey(c.x+delta[1],c.y+delta[2],c.z)]
            if q and a.court[key(q)] then join(c,q) end
        end
    end
    join(goal,a.entry);join(a.entry,{x=x+2,y=goal.y,z=z})
    for _,dy in ipairs({-half,half}) do join({x=x+2,y=y+dy,z=z},{x=x+2,y=y+dy,z=z+1},true) end
    local before={x=x+width+1,y=y,z=z};join(before,jail)
    a.lock={index=4,beforeCell=coord(goal),afterCell=coord(a.entry),edgeKey=edge(goal,a.entry)}
    p.JailEdge={beforeCell=before,afterCell=coord(jail),edgeKey=edge(before,jail),pathIndex=#g.CriticalPath+width+3}
    p.DeborahCell=coord(jail);p.CoreCell=coord(a.center);p.Warden=a
    g.WanderLayers=g.Layers;g.Layers=math.max(g.Layers,z+2);g.Width=x+width+2
    p.Validation.orderedRoute='Start>Red>Blue>Yellow>Neil>Black Keycard>Black Gate>'..d.name..'>Jail Key>Jail Door>Rescue Target'
    local blocked={[p.Gates[4].edgeKey]=true,[p.JailEdge.edgeKey]=true}
    local reach=LOD.NeilBrute:Walk(g,{key(g.Start)},blocked)
    if reach[key(a.entry)] then return false,'boss entry bypasses Black Gate' end
    blocked[p.Gates[4].edgeKey]=nil;reach=LOD.NeilBrute:Walk(g,{key(g.Start)},blocked)
    for k in pairs(a.court) do if not reach[k] then return false,'disconnected boss court' end end
    if reach[key(jail)] then return false,'boss jail bypass' end
    -- Actual concrete boundary surfaces, not floor points pretending to ricochet.
    a.ricochetPoints={}
    local origin=N:CellCenter(a.center)
    a.airMin=origin+Vector(-(width*.5-.3)*LOD.Config.Maze.CellSize,-(depth*.5-.3)*LOD.Config.Maze.CellSize,80)
    a.airMax=origin+Vector((width*.5-.3)*LOD.Config.Maze.CellSize,(depth*.5-.3)*LOD.Config.Maze.CellSize,700)
    a.flightHeight=420
    local cellSize=LOD.Config.Maze.CellSize
    for _,dy in ipairs({-half,half}) do for dx=1,width-2 do
        local c=g.Cells[LOD.MazeGenerator.CellKey(x+2+dx,y+dy,z)]
        a.ricochetPoints[#a.ricochetPoints+1]=N:CellCenter(c)+Vector(0,dy<0 and -cellSize/2+64 or cellSize/2-64,60)
    end end
    return true,p
end
