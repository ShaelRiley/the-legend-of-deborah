local E=LOD.EnemyRoster
local D=LOD.EncounterDirector
local EC=LOD.Config.Encounter
local N=LOD.MazeNavigator
local key=E.Key
local function sorted(t) local a={} for k in pairs(t or {}) do a[#a+1]=k end table.sort(a);return a end
function E:IsTransition(graph,c)
    for _,edge in ipairs(graph.VerticalEdges or {}) do if key(edge.a)==key(c) or key(edge.b)==key(c) then return true end end
    for _,g in ipairs(graph.Progression and graph.Progression.Gates or {}) do
        if key(g.beforeCell)==key(c) or key(g.afterCell)==key(c) then return true end
    end
    return false
end
function E:HasAlternate(graph,c)
    local neighbors={}
    for _,k in ipairs(sorted(c.neighbors)) do
        local n=graph.Cells[k]
        if n.z==c.z and N:CanTraverse(graph,key(c),k) and not self:Safe(graph,n) then neighbors[#neighbors+1]=k end
    end
    if #neighbors<2 then return false end
    local queue={neighbors[1]};local seen={[neighbors[1]]=true,[key(c)]=true};local head=1
    while queue[head] and head<=256 do
        local k=queue[head];head=head+1
        if k~=neighbors[1] then for i=2,#neighbors do if neighbors[i]==k then return true end end end
        for _,nextKey in ipairs(sorted(graph.Cells[k].neighbors)) do
            local n=graph.Cells[nextKey]
            if not seen[nextKey] and n.z==c.z and not self:Safe(graph,n) and N:CanTraverse(graph,k,nextKey) then
                seen[nextKey]=true;queue[#queue+1]=nextKey
            end
        end
    end
    return false
end
local function clear(from,to,mins,maxs)
    local tr=util.TraceHull({start=from,endpos=to,mins=mins or Vector(-16,-16,2),maxs=maxs or Vector(16,16,72),mask=MASK_NPCSOLID,
        filter=function(v) return not v.LODHostile and not v:IsPlayer() end})
    return not tr.Hit and not tr.StartSolid
end
function E:Placement(graph,c,id,role)
    local d=self.Definitions[id]
    if not d then return {} end
    if self:Safe(graph,c) or self:IsTransition(graph,c) then return nil end
    local center=N:CellCenter(c)+Vector(0,0,2)
    if not clear(center,center) then return nil end
    if not d.stationary then
        if id=="climber" then
            local lane=LOD.Climber:NearestLane(graph,c,center)
            if not lane then return nil end
            return {pos=lane.pos,wallLane=lane}
        end
        return {pos=center}
    end
    local tag=(graph.CellTags or {})[key(c)] or {}
    if tag.objective then return nil end
    local exits={}
    for _,k in ipairs(sorted(c.neighbors)) do
        local n=graph.Cells[k]
        if n.z==c.z and N:CanTraverse(graph,key(c),k) and not self:Safe(graph,n) then exits[#exits+1]=n end
    end
    if id=="sentry" and not (role=="reward" or self:HasAlternate(graph,c)) then return nil end
    if #exits<2 and role~="reward" then return nil end
    if #exits==0 then return nil end
    local dir=(N:CellCenter(exits[1])-center);dir.z=0;dir:Normalize()
    local yaw=dir:Angle().y
    -- Two in-cell side pockets, outside the firing line, must be hull-clear.
    local side=Vector(-dir.y,dir.x,0)
    if not clear(center,center+side*100) or not clear(center,center-side*100) then return nil end
    if id=="lurker" then
        local tr=util.TraceLine({start=center+Vector(0,0,90),endpos=center+Vector(0,0,LOD.Config.Maze.LevelHeight-8),mask=MASK_SOLID})
        if not tr.Hit or tr.StartSolid or tr.HitNormal.z>-.7 then return nil end
        local pos=tr.HitPos+Vector(0,0,-12)
        if not clear(pos+Vector(0,0,-24),center+Vector(0,0,48),Vector(-8,-8,-8),Vector(8,8,8)) then return nil end
        return {pos=pos,yaw=yaw,ceiling=true}
    elseif id=="beamsweeper" then
        local origin=center+Vector(0,0,56)
        local range=EC.Archetypes[id].fireRange
        for degrees=-45,45,15 do
            local tr=util.TraceLine({start=origin,endpos=origin+Angle(0,yaw+degrees,0):Forward()*range,mask=MASK_SOLID})
            if tr.StartSolid then return nil end
            if tr.Hit then range=math.min(range,origin:Distance(tr.HitPos)-8) end
        end
        if range<120 or not clear(center,center-dir*100) then return nil end
        return {pos=center,yaw=yaw,range=range}
    end
    return {pos=center,yaw=yaw}
end
local templates={
    climber_wall={name="Wall Hunt",composition={climber=1,shambler=1}},
    nodule_gas={name="Gas Pocket",composition={nodule=1}},
    flamer_pressure={name="Flame Pressure",composition={flamer=1,shambler=1}},
    bigcrab_breath={name="Big Crab",composition={bigcrab=1}},
    sentry_flank={name="Sentry Flank",composition={sentry=1}},
    razor_cover={name="Rotor Cover Break",composition={razor=1,soldier=1}},
    arccaster_zone={name="Arc Control",composition={arccaster=1,shambler=2}},
    lurker_ceiling={name="Ceiling Venom",composition={lurker=1}},
    beamsweeper_lane={name="Beam Crossing",composition={beamsweeper=1}},
    gaoler_hold={name="Gaoler's Pursuit",composition={gaoler=1,runner=1}},
    silencer_screen={name="Silence Detail",composition={silencer=1,shambler=1}},
    repulsor_screen={name="Repulsor Screen",composition={repulsor=1,soldier=1}}
}
for id,t in pairs(templates) do EC.Templates[id]=t end
local baseEligible=D._EligibleTemplates
function D:_EligibleTemplates(sector,role)
    local out=table.Copy(baseEligible(self,sector,role))
    if sector>=1 then
        if role=="ambush" or role=="arena" then out[#out+1]="climber_wall";out[#out+1]="flamer_pressure" end
        if role=="arena" or role=="reward" then out[#out+1]="bigcrab_breath";out[#out+1]="sentry_flank";out[#out+1]="lurker_ceiling";out[#out+1]="nodule_gas" end
    end
    if sector>=2 then
        if role=="arena" or role=="ambush" then
            out[#out+1]="gaoler_hold";out[#out+1]="silencer_screen";out[#out+1]="repulsor_screen"
        end
        out[#out+1]="razor_cover"
        if role=="arena" or role=="ambush" then out[#out+1]="arccaster_zone" end
        if role=="arena" or role=="reward" or role=="ambush" then out[#out+1]="beamsweeper_lane" end
    end
    return out
end
-- No duplicate stationary hazards in one cell when party/depth enriches a template.
local baseComposition=D._TemplateComposition
function D:_TemplateComposition(id,rng,scale)
    local c=baseComposition(self,id,rng,scale)
    for k,n in pairs(c or {}) do if E.Definitions[k] and E.Definitions[k].stationary then c[k]=math.min(1,n) end end
    return c
end
-- Validate physical placement before the unified spawner creates native actors.
-- If a generated candidate is unsuitable, retain its budget-safe ordinary body.
local baseSpawn=D._SpawnEncounter
function D:_SpawnEncounter(encounter)
    if not encounter or encounter.spawned or encounter.cleared then return baseSpawn(self,encounter) end
    local graph=LOD.RunManager.State.Graph
    encounter.rosterPlacements={}
    E.PlacementStats=E.PlacementStats or {}
    for _,id in ipairs(sorted(encounter.composition)) do
        if E.Definitions[id] then
            local p=E:Placement(graph,graph.Cells[encounter.cellKey],id,encounter.role)
            local stats=E.PlacementStats[id] or {accepted=0,rejected=0};E.PlacementStats[id]=stats
            if p then stats.accepted=stats.accepted+1;encounter.rosterPlacements[id]=p
            else
                stats.rejected=stats.rejected+1
                encounter.composition.shambler=(encounter.composition.shambler or 0)+encounter.composition[id]
                encounter.composition[id]=nil
            end
        end
    end
    return baseSpawn(self,encounter)
end
-- Constrained Flamer weight, with no other new wandering archetypes.
LOD.WanderingDirector.Config.ArchetypeWeights.flamer=3

concommand.Add("lod_encounter_distribution",function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    for _,id in ipairs(sorted(E.Definitions)) do
        local stats=(E.PlacementStats or {})[id] or {}
        print(string.format("[LOD:ROSTER] %s accepted=%d rejected=%d",id,stats.accepted or 0,stats.rejected or 0))
    end
end)
