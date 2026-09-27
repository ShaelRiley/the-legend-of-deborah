-- Final runtime stair override + actual static-box collision bounds, not the
-- superseded base-builder aperture. This is a geometric envelope test, not a
-- replacement for native Source movement/prediction acceptance.
dofile('tools/test_enemy_update.lua')
local root = 'gamemodes/legend_of_deborah/gamemode/lod/'
function table.Count(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
function Angle(p,y,r) return {p=p,y=y,r=r} end
angle_zero = Angle(0,0,0)
dofile(root..'sh_rng.lua')
dofile(root..'sv_maze_generator.lua')
dofile(root..'sv_maze_builder.lua')
dofile(root..'sv_maze_builder_floor_anchor.lua')
local B,G,MC,GC = LOD.MazeBuilder,LOD.MazeGenerator,LOD.Config.Maze,LOD.Config.Geometry
-- Exercise production direction assignment without running unrelated builders.
B.Build = function(_,graph) return graph end
dofile(root..'sv_m1_stair_geometry.lua')
local savedInclude,savedAdd = include,AddCSLuaFile
include=function() end; AddCSLuaFile=function() end
ENT={}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_static_box/init.lua')
local Box=ENT
include,AddCSLuaFile=savedInclude,savedAdd
SOLID_BBOX=2; COLLISION_GROUP_NONE=0; EFL_FORCE_CHECK_TRANSMIT=128
local boxes={}
ents={Create=function(class)
    assert(class=='lod_static_box')
    local e=setmetatable({valid=true},{__index=Box})
    for _,field in ipairs({'Pos','Angles','BoxMins','BoxMaxs','BoxKind','Solid'}) do
        e['Set'..field]=function(self,v) self[field]=v end
        e['Get'..field]=function(self) return self[field] end
    end
    for _,method in ipairs({'SetModel','SetMoveType','SetSolidFlags','SetCollisionGroup',
        'DrawShadow','AddEFlags','Activate','SetNW2Bool'}) do e[method]=function() end end
    function e:SetCollisionBounds(a,b) self.low,self.high=self.Pos+a,self.Pos+b end
    function e:Spawn() self:Initialize(); boxes[#boxes+1]=self end
    return e
end}
local axes={E={1,0},N={0,1},W={-1,0},S={0,-1}}
local opposite={E='W',W='E',N='S',S='N'}
dofile(root..'sh_player_scale_collision.lua')
local low,high=LOD.PlayerScaleCollision:Bounds({Crouching=function() return false end})
assert(low.x==-16 and low.y==-16 and low.z==0 and high.x==16 and high.y==16 and high.z==72)
local radius,height,step,epsilon=high.x,high.z,18,0.00001
local clearanceRequired=height+step+2 -- full upright step envelope + seam margin
local scenarios,samples,crossings,minimum=0,0,0,math.huge
local function overlaps(a,b,c,d) return a<d-epsilon and b>c+epsilon end
local function xyHit(pos,e)
    return overlaps(pos.x-radius,pos.x+radius,e.low.x,e.high.x)
       and overlaps(pos.y-radius,pos.y+radius,e.low.y,e.high.y)
end
local function clearAt(pos,bodyHeight)
    for _,e in ipairs(boxes) do
        if xyHit(pos,e) and overlaps(pos.z,pos.z+bodyHeight,e.low.z,e.high.z) then return false,e end
    end
    return true
end
local function pointSupported(pos)
    for _,e in ipairs(boxes) do
        if e.BoxKind==1 and math.abs(e.high.z-pos.z)<epsilon and
            pos.x>=e.low.x-epsilon and pos.x<=e.high.x+epsilon and
            pos.y>=e.low.y-epsilon and pos.y<=e.high.y+epsilon then return true end
    end
    return false
end
local function checkEdge(graph,edge)
    B:Build(graph)
    local lower=edge.a.z<edge.b.z and edge.a or edge.b
    local upper=edge.a.z>edge.b.z and edge.a or edge.b
    local dir=assert(axes[edge.LODStairDirection])
    assert(edge.LODStairEntrySide,'mandatory staircase lost its legal approach')
    local center=B:CellCenter(lower)
    local function at(x,y,z)
        return center+Vector(dir[1]*x-dir[2]*y,dir[2]*x+dir[1]*y,z)
    end
    boxes={}; B.Entities={}; B.BuildFailures=0
    B:_BuildPerforatedFloor(upper,edge); B:_BuildStair(edge)
    assert(#boxes==4+GC.StairSteps+4,'repair must not add collision entities')
    for _,e in ipairs(boxes) do
        assert(e.Solid==SOLID_BBOX and e:IsLODCollisionReady(),'native solid must remain enabled')
        if e.BoxKind==1 then assert(e.high.z-e.low.z==GC.FloorThickness) end
    end
    local rear=boxes[4]
    local rearX0,rearX1=rear.BoxMins.x,rear.BoxMaxs.x
    assert(rearX1-rearX0>=2*radius+16,'rear crossover lost full-hull walking margin')
    assert(GC.StairWidth==128 and GC.StairSteps==24 and GC.StairRun==320)
    assert(MC.LevelHeight/GC.StairSteps<=step,'riser exceeds walkable step height')
    -- Check every interval at its critical transitions, not only tread centers.
    -- Support uses the entire footprint: its leading edge can stand on a higher
    -- tread while the trailing edge is still underneath the ceiling slab.
    local xs={-GC.StairRun-radius, MC.CellSize/2-radius}
    for _,e in ipairs(boxes) do
        local offset=e.BoxKind==1 and 0 or -GC.StairRun/2
        for _,edgeX in ipairs({offset+e.BoxMins.x,offset+e.BoxMaxs.x}) do
            for _,sign in ipairs({-1,1}) do
                for _,jitter in ipairs({-0.001,0.001}) do xs[#xs+1]=edgeX+sign*radius+jitter end
            end
        end
    end
    table.sort(xs)
    local positions={}
    for i,x in ipairs(xs) do
        if x>=-GC.StairRun-radius and x<=MC.CellSize/2-radius then
            positions[#positions+1]=x
            if xs[i+1] and xs[i+1]<=MC.CellSize/2-radius then
                positions[#positions+1]=(x+xs[i+1])/2
            end
        end
    end
    local localMinimum=math.huge
    for _,lateral in ipairs({-40,0,40}) do
        for _,x in ipairs(positions) do
            local pos=at(x,lateral,0)
            local feet=x+radius>0 and MC.LevelHeight or 0
            for _,e in ipairs(boxes) do
                if e.BoxKind==2 and xyHit(pos,e) then feet=math.max(feet,e.high.z-center.z) end
            end
            pos.z=center.z+feet
            assert(clearAt(pos,height),'upright body intersects generated stair geometry')
            for _,e in ipairs(boxes) do
                if e.BoxKind==1 and xyHit(pos,e) and e.low.z>pos.z then
                    localMinimum=math.min(localMinimum,e.low.z-pos.z)
                end
            end
            samples=samples+1
        end
    end
    assert(localMinimum>=clearanceRequired, string.format(
        'STAIR_HEADROOM_FAIL: %s z=%d clearance=%g; upright step envelope requires %g',
        edge.LODStairDirection,lower.z,localMinimum,clearanceRequired))
    minimum=math.min(minimum,localMinimum)
    -- Full-footprint, no-jump upper loop: forward landing -> both side decks ->
    -- rear crossover. The real rail collision must leave the rear crossing open.
    local rearMiddle=(rearX0+rearX1)/2
    local route={{96,-96},{96,96},{rearMiddle,96},{rearMiddle,-96},{96,-96}}
    for i=2,#route do
        local a,b=route[i-1],route[i]
        local distance=math.max(math.abs(b[1]-a[1]),math.abs(b[2]-a[2]))
        for j=0,math.ceil(distance) do
            local t=j/math.ceil(distance)
            local pos=at(a[1]+(b[1]-a[1])*t,a[2]+(b[2]-a[2])*t,MC.LevelHeight)
            assert(clearAt(pos,height),'upper no-jump route blocked by rail/slab')
            for _,dx in ipairs({-radius,0,radius}) do
                for _,dy in ipairs({-radius,0,radius}) do
                    assert(pointSupported(pos+Vector(dx,dy,0)),'upper route footprint over a hole')
                end
            end
            crossings=crossings+1
        end
    end
    scenarios=scenarios+1
end
-- Every rotation, floor elevation and edge endpoint ordering with an actual
-- graph-open lower approach; no hardcoded LODStairDirection bypass.
for _,name in ipairs({'E','N','W','S'}) do
    local d=axes[name]
    for z=0,2 do
        for _,reverse in ipairs({false,true}) do
            local a={x=5,y=5,z=z,neighbors={}}
            local b={x=5,y=5,z=z+1,neighbors={}}
            local c={x=5-d[1],y=5-d[2],z=z,neighbors={}}
            local key=G.CellKey
            a.neighbors[key(c.x,c.y,c.z)]=true
            local edge={a=reverse and b or a,b=reverse and a or b}
            local graph={Cells={[key(a.x,a.y,a.z)]=a,[key(b.x,b.y,b.z)]=b,
                [key(c.x,c.y,c.z)]=c},VerticalEdges={edge}}
            checkEdge(graph,edge)
            assert(edge.LODStairDirection==name and edge.LODStairEntrySide==opposite[name])
        end
    end
end
local generated=0
for seed=1,16 do
    local graph=assert(G:Generate(seed*7719))
    for _,edge in ipairs(graph.VerticalEdges) do checkEdge(graph,edge); generated=generated+1 end
end
assert(generated>=48,'generated-maze coverage unexpectedly shrank')
print(string.format('STAIR_HEADROOM_PASS: %d orientations/elevations/endpoint/generated flights; '..
    '%d hull samples; %d supported upper-loop samples; minimum headroom %g >= %g; '..
    'solid floors, rails, 24 risers, legal approaches and no-jump crossover retained; native acceptance pending',
    scenarios,samples,crossings,minimum,clearanceRequired))
