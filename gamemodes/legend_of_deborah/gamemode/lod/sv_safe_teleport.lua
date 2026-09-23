-- Shared relocation authority. Callers supply an actor and anchor, never trust a
-- client position. Graph reachability and native standing hulls are both required.
LOD.SafeTeleport = LOD.SafeTeleport or {}
local T, N, Run = LOD.SafeTeleport, assert(LOD.MazeNavigator), assert(LOD.RunManager)
local MC = LOD.Config.Maze
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end

function T:Hero(ply)
    if not LOD.Equipment:CanAct(ply) or not Run.State.BuildReady then return nil end
    local ps=Run:GetPlayerState(ply)
    if not ps or ps.eliminated or (ps.lives or 0)<=0 or not ps.deploymentComplete then return nil end
    if ply:GetMoveType()~=MOVETYPE_WALK or ply:InVehicle() then return nil end
    return ps
end

function T:Bind(ply)
    local ps=self:Hero(ply)
    if not ps then return nil end
    return {actor=ply,ps=ps,life=ps.equipmentLifeSerial,run=Run.State,
        seed=Run.State.LevelSeed,graph=Run.State.Graph}
end
function T:Matches(b)
    return b and self:Hero(b.actor)==b.ps and Run.State==b.run
        and Run.State.LevelSeed==b.seed and Run.State.Graph==b.graph
        and b.ps.equipmentLifeSerial==b.life or false
end

-- Navigation's nearest-cell fallback is appropriate for path recovery, but
-- would admit voids and outside coordinates here. Use exact grid membership.
function T:CellAt(graph,pos)
    if not graph or not pos then return nil end
    local x=math.floor((pos.x-MC.Origin.x)/MC.CellSize+(MC.Width+1)*.5+.5)
    local y=math.floor((pos.y-MC.Origin.y)/MC.CellSize+(MC.Height+1)*.5+.5)
    local z=math.floor((pos.z-MC.Origin.z)/MC.LevelHeight+.5)
    return graph.Cells[LOD.MazeGenerator.CellKey(x,y,z)]
end

function T:FlatCell(graph,cell)
    if not cell then return false end
    local k=key(cell)
    if graph.WardenVoid and graph.WardenVoid[k] then return false end
    for _,edge in ipairs(graph.VerticalEdges or {}) do
        if key(edge.a)==k or key(edge.b)==k then return false end
    end
    return true
end

local function floorHit(trace)
    local ent=trace.Entity
    return trace.Hit and not trace.StartSolid and not trace.AllSolid
        and trace.HitNormal and trace.HitNormal.z>=.9
        and IsValid(ent) and ent:GetClass()=="lod_static_box"
        and ent.LODGeneratedGeometry and ent:GetBoxKind()==1
end

function T:Landing(ply,graph,cell,pos)
    if not self:FlatCell(graph,cell) then return nil end
    local center=N:CellCenter(cell)
    local mins,maxs=ply:GetHull() -- always standing, including a crouched Hero
    local half=MC.CellSize*.5-8
    if pos.x+mins.x<center.x-half or pos.x+maxs.x>center.x+half
        or pos.y+mins.y<center.y-half or pos.y+maxs.y>center.y+half then return nil end
    local floor=util.TraceHull({start=Vector(pos.x,pos.y,center.z+16),
        endpos=Vector(pos.x,pos.y,center.z-8),mins=Vector(-1,-1,0),maxs=Vector(1,1,1),
        mask=MASK_PLAYERSOLID,filter=ply})
    if not floorHit(floor) or math.abs(floor.HitPos.z-center.z)>4 then return nil end
    local dest=Vector(pos.x,pos.y,floor.HitPos.z-mins.z+2)
    local hull=util.TraceHull({start=dest,endpos=dest,mins=mins,maxs=maxs,mask=MASK_PLAYERSOLID,filter=ply})
    if hull.Hit or hull.StartSolid or hull.AllSolid then return nil end
    -- All footprint corners need canonical support. A center ray alone admits
    -- ledges, stair cutouts and partial floors beneath a large Hero.
    for _,x in ipairs({mins.x,maxs.x}) do for _,y in ipairs({mins.y,maxs.y}) do
        local foot=Vector(dest.x+x,dest.y+y,center.z+8)
        local tr=util.TraceLine({start=foot,endpos=foot-Vector(0,0,16),mask=MASK_PLAYERSOLID,filter=ply})
        if not floorHit(tr) or math.abs(tr.HitPos.z-floor.HitPos.z)>2 then return nil end
    end end
    for _,offset in ipairs({Vector(0,0,4),Vector(0,0,maxs.z*.5)}) do
        if bit.band(util.PointContents(dest+offset),bit.bor(CONTENTS_SLIME,CONTENTS_WATER))~=0 then return nil end
    end
    for _,ent in ipairs(ents.FindInBox(dest+mins,dest+maxs)) do
        if ent~=ply and (ent:GetClass()=="trigger_hurt" or ent:IsPlayer() or ent:IsNPC() or ent.LODHostile) then return nil end
    end
    return dest
end

function T:Resolve(target,anchor,mode)
    if not self:Hero(target) or not self:Hero(anchor) or target==anchor then return nil,"Hero unavailable" end
    if mode~="throw" and mode~="drink" then return nil,"Invalid destination mode" end
    local graph=Run.State.Graph
    local source=self:CellAt(graph,target:GetPos())
    local home=self:CellAt(graph,anchor:GetPos())
    if not source or not home or not N:FindPath(graph,source,home) then return nil,"No unlocked route to that Hero" end
    local cells={}
    for k in pairs(home.neighbors or {}) do
        local c=graph.Cells[k]
        if c and c.z==home.z and N:CanTraverse(graph,key(home),k) then cells[#cells+1]=c end
    end
    table.sort(cells,function(a,b)
        local da,db=N:CellCenter(a):DistToSqr(anchor:GetPos()),N:CellCenter(b):DistToSqr(anchor:GetPos())
        return da==db and key(a)<key(b) or da<db
    end)
    if mode=="drink" then table.insert(cells,1,home) end
    for _,cell in ipairs(cells) do
        local center=N:CellCenter(cell)
        local points={}
        if cell==home then points[#points+1]=anchor:GetPos() end
        points[#points+1]=center
        for _,offset in ipairs({{64,0},{-64,0},{0,64},{0,-64},{128,0},{-128,0},{0,128},{0,-128}}) do
            points[#points+1]=center+Vector(offset[1],offset[2],0)
        end
        table.sort(points,function(a,b)
            local da,db=a:DistToSqr(anchor:GetPos()),b:DistToSqr(anchor:GetPos())
            if da~=db then return da<db end
            if a.x~=b.x then return a.x<b.x end
            if a.y~=b.y then return a.y<b.y end
            return a.z<b.z
        end)
        for _,point in ipairs(points) do
            local dest=self:Landing(target,graph,cell,point)
            if dest then return dest end
        end
    end
    return nil,"No safe landing nearby"
end

function T:Relocate(targetBinding,anchorBinding,mode,spend)
    if not self:Matches(targetBinding) or not self:Matches(anchorBinding) then return false,"Hero changed" end
    local target,anchor=targetBinding.actor,anchorBinding.actor
    -- Resolve again at commit, after selection: gates, actors, hulls and the
    -- anchor may all have moved. No asynchronous work separates spend and move.
    local dest,why=self:Resolve(target,anchor,mode)
    if not dest then return false,why end
    if spend and not spend() then return false,"Card unavailable" end
    if LOD.RPGAbilityRules.VoluntaryDashes then LOD.RPGAbilityRules.VoluntaryDashes[target]=nil end
    target.LODForcedMovementUntil=nil
    target:SetLocalVelocity(Vector(0,0,0))
    target:SetPos(dest)
    return true,dest
end
