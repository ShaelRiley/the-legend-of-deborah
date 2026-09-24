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
    local tag=(graph.CellTags or {})[key(c)] or {}
    if (d.trap or d.melee or d.tactical or d.mobile or d.support=="cleanse" or d.condition or d.spacing or d.resource or d.crossfire or d.discipline or d.companion or d.edict or d.link) and tag.objective then return nil end
    local center=N:CellCenter(c)+Vector(0,0,2)
    if not clear(center,center) then return nil end
    -- Mobility specialists require local legal topology before entering production.
    -- Runtime commitments additionally trace actual bodies, floors and cover.
    if id=="pincer" or id=="harrier" or id=="waylayer" then
        if not LOD.EnemyPursuit or not LOD.EnemyPursuit:Placement(graph,c,id) then return nil end
    end
    if d.tactical=="screen" or d.condition or d.spacing or d.resource or d.crossfire or d.discipline or d.companion or d.edict or d.link then
        -- Guard planes, marked attacks and movement demands need in-cell flank pockets,
        -- not a whole graph cycle that excludes otherwise escapable rooms.
        local exit
        for _,k in ipairs(sorted(c.neighbors)) do
            local n=graph.Cells[k]
            if n and n.z==c.z and N:CanTraverse(graph,key(c),k) and not self:Safe(graph,n) then exit=n;break end
        end
        if not exit then return nil end
        local dir=N:CellCenter(exit)-center;dir.z=0;dir:Normalize()
        local side=Vector(-dir.y,dir.x,0)
        local pocket=d.link and 96 or 100
        if not clear(center,center+side*pocket) or not clear(center,center-side*pocket) then return nil end
        if d.edict==2 then
            -- Surveyor offers a 96-unit refuge and a 160-unit opposite escape.
            -- Either orientation suffices; real Hero hull/support is rechecked
            -- at commitment and throughout the warning by the edict authority.
            local right=clear(center,center+side*96) and clear(center,center-side*160)
            local left=clear(center,center-side*96) and clear(center,center+side*160)
            if not right and not left then return nil end
        end
        if d.companion==1 then
            -- A bodyguard needs room for a real body to advance into the firing
            -- lane, in addition to the Hero's two lateral escape pockets.
            -- Actual ward/actor support and frozen-route samples remain runtime gates.
            local lo,hi=Vector(-16,-16,2)*1.33,Vector(16,16,72)*1.33
            if not clear(center,center+dir*64,lo,hi) and not clear(center,center-dir*64,lo,hi) then return nil end
        end
    end
    if d.perception then
        local exit=false
        for _,k in ipairs(sorted(c.neighbors)) do
            local n=graph.Cells[k]
            if n and n.z==c.z and N:CanTraverse(graph,key(c),k) and not self:Safe(graph,n) then exit=true;break end
        end
        if not exit or not clear(center,center+Vector(96,0,0)) or not clear(center,center-Vector(96,0,0))
            or not clear(center,center+Vector(0,96,0)) or not clear(center,center-Vector(0,96,0)) then return nil end
    end
    if d.mobile then
        -- Admission checks fixed in-cell routes and room for a Hero to step
        -- outside the largest moving zone. Actual support/cover and actor hull
        -- are checked again when committing and servicing the motion.
        local exit
        for _,k in ipairs(sorted(c.neighbors)) do
            local n=graph.Cells[k]
            if n and n.z==c.z and N:CanTraverse(graph,key(c),k) and not self:Safe(graph,n) then exit=n;break end
        end
        if not exit then return nil end
        local lo,hi=Vector(-16,-16,2)*1.33,Vector(16,16,72)*1.33
        local half=(LOD.Config.Maze.CellSize or 384)*.5-24
        local function inside(p)
            return math.abs(p.x-center.x)+hi.x<=half and math.abs(p.y-center.y)+hi.y<=half
        end
        local feasible=false
        for _,dir in ipairs({Vector(1,0,0),Vector(-1,0,0),Vector(0,1,0),Vector(0,-1,0)}) do
            local side=Vector(-dir.y,dir.x,0)*112
            local finish=center+dir*144
            if inside(finish) and inside(finish+side) and inside(finish-side)
                and clear(center,finish,lo,hi)
                and clear(center,center+side) and clear(center,center-side)
                and clear(center+dir*72,center+dir*72+side) and clear(center+dir*72,center+dir*72-side)
                and clear(finish,finish+side) and clear(finish,finish-side)
                and clear(center+side,finish+side) and clear(center-side,finish-side) then feasible=true;break end
        end
        if not feasible then return nil end
    end
    if not d.stationary then
        if id=="climber" then
            local lane=LOD.Climber:NearestLane(graph,c,center)
            if not lane then return nil end
            return {pos=lane.pos,wallLane=lane}
        end
        return {pos=center}
    end
    if tag.objective then return nil end
    local exits={}
    for _,k in ipairs(sorted(c.neighbors)) do
        local n=graph.Cells[k]
        if n.z==c.z and N:CanTraverse(graph,key(c),k) and not self:Safe(graph,n) then exits[#exits+1]=n end
    end
    if id=="sentry" and not (role=="reward" or self:HasAlternate(graph,c)) then return nil end
    if #exits<2 and (d.trap or role~="reward") then return nil end
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
    relay_detail={name="Relay Detail",composition={relay=1,soldier=1}},
    lacemaker_detail={name="Lacemaker Detail",composition={lacemaker=1,runner=1}},
    censor_detail={name="Censor Detail",composition={censor=1,shambler=1}},
    surveyor_detail={name="Surveyor Detail",composition={surveyor=1,soldier=1}},
    interposer_detail={name="Interposer Detail",composition={interposer=1,soldier=1}},
    mourner_detail={name="Mourner Detail",composition={mourner=1,shambler=1}},
    halter_detail={name="Halter Detail",composition={halter=1,soldier=1}},
    pacer_chase={name="Pacer Chase",composition={pacer=1,runner=1}},
    fusilier_screen={name="Fusilier Screen",composition={fusilier=1,shambler=1}},
    bombardier_pressure={name="Bombardier Pressure",composition={bombardier=1,runner=1}},
    siphoner_pressure={name="Siphoner Pressure",composition={siphoner=1,runner=1}},
    accumulator_detail={name="Accumulator Detail",composition={accumulator=1,soldier=1}},
    outrider_detail={name="Outrider Detail",composition={outrider=1,soldier=1}},
    conductor_pressure={name="Conductor Pressure",composition={conductor=1,shambler=1}},
    absolver_detail={name="Absolver Detail",composition={absolver=1,shambler=2}},
    exactor_pressure={name="Exactor Pressure",composition={exactor=1,flamer=1}},
    listener_detail={name="Listener Detail",composition={listener=1,soldier=1}},
    shy_pressure={name="Shy Pressure",composition={shy=1,soldier=1}},
    censer_advance={name="Censer Advance",composition={censer=1,soldier=1}},
    trailmaker_chase={name="Trailmaker Chase",composition={trailmaker=1,runner=1}},
    towline_detail={name="Towline Detail",composition={towline=1,runner=1}},
    screenwright_detail={name="Screenwright Detail",composition={screenwright=1,soldier=1}},
    afterburst_detail={name="Afterburst Detail",composition={afterburst=1,soldier=1}},
    carrion_feast={name="Carrion Feast",composition={carrion=1,shambler=2}},
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
    repulsor_screen={name="Repulsor Screen",composition={repulsor=1,soldier=1}},
    stitcher_detail={name="Stitcher's Detail",composition={stitcher=1,shambler=2}},
    bulwark_line={name="Bulwark Line",composition={bulwark=1,soldier=1}},
    cantor_charge={name="Cantor's Charge",composition={cantor=1,runner=2}},
    pincer_detail={name="Pincer Detail",composition={pincer=1,soldier=1}},
    harrier_screen={name="Harrier Screen",composition={harrier=1,shambler=1}},
    waylayer_cutoff={name="Waylayer Cutoff",composition={waylayer=1,runner=1}},
    pavise_advance={name="Pavise Advance",composition={pavise=1,runner=1}},
    repriser_detail={name="Repriser Detail",composition={repriser=1,soldier=1}},
    caromer_screen={name="Caromer Screen",composition={caromer=1,shambler=1}},
    reeler_chase={name="Reeler Chase",composition={reeler=1,runner=1}},
    forker_crossfire={name="Forker Crossfire",composition={forker=1,soldier=1}},
    wirewright_chase={name="Wirewright Chase",composition={wirewright=1,runner=1}},
    snarer_detail={name="Snarer Detail",composition={snarer=1,soldier=1}},
    cordon_screen={name="Cordon Screen",composition={cordon=1,shambler=1}},
    reaper_detail={name="Reaper Detail",composition={reaper=1,soldier=1}},
    drubber_chase={name="Drubber Chase",composition={drubber=1,runner=1}},
    fencer_screen={name="Fencer Screen",composition={fencer=1,shambler=1}},
    redliner_pressure={name="Redliner Pressure",composition={redliner=1,shambler=1}}
}
for id,t in pairs(templates) do EC.Templates[id]=t end
local baseEligible=D._EligibleTemplates
function D:_EligibleTemplates(sector,role)
    -- Eligibility is a set. The campaign ecology selector owns weighting and
    -- novelty; historical per-cohort duplicate tickets are no longer authority.
    local out,seen={},{}
    local function add(id)
        if not seen[id] then seen[id]=true;out[#out+1]=id end
    end
    for _,id in ipairs(baseEligible(self,sector,role) or {}) do add(id) end
    if sector>=1 then
        if role=="ambush" or role=="arena" then add("climber_wall");add("flamer_pressure") end
        if role=="arena" or role=="reward" then
            add("bigcrab_breath");add("sentry_flank");add("lurker_ceiling");add("nodule_gas")
        end
    end
    if sector>=2 then
        add("razor_cover")
        if role=="arena" or role=="ambush" then add("arccaster_zone") end
        if role=="arena" or role=="reward" or role=="ambush" then add("beamsweeper_lane") end
    end
    if sector>=2 and (role=="arena" or role=="ambush") then
        for _,id in ipairs({
            "absolver_detail","accumulator_detail","afterburst_detail","bombardier_pressure",
            "bulwark_line","cantor_charge","caromer_screen","carrion_feast",
            "censer_advance","censor_detail","conductor_pressure","cordon_screen",
            "drubber_chase","exactor_pressure","fencer_screen","forker_crossfire",
            "fusilier_screen","gaoler_hold","halter_detail","harrier_screen",
            "interposer_detail","lacemaker_detail","listener_detail","mourner_detail",
            "outrider_detail","pacer_chase","pavise_advance","pincer_detail",
            "reaper_detail","redliner_pressure","reeler_chase","relay_detail",
            "repriser_detail","repulsor_screen","screenwright_detail","shy_pressure",
            "silencer_screen","siphoner_pressure","snarer_detail","stitcher_detail",
            "surveyor_detail","towline_detail","trailmaker_chase","waylayer_cutoff",
            "wirewright_chase",
        }) do add(id) end
    end
    return out
end
-- Party/depth enrichment adds ordinary bodies, never duplicate stationary hazards
-- or support/pursuit/reaction/trap/melee/tactical/mobile/crossfire/discipline specialists in one authored encounter.
local baseComposition=D._TemplateComposition
function D:_TemplateComposition(id,rng,scale)
    local c=baseComposition(self,id,rng,scale)
    for k,n in pairs(c or {}) do if E.Definitions[k] and (E.Definitions[k].stationary or E.Definitions[k].support or E.Definitions[k].pursuit or E.Definitions[k].reaction or E.Definitions[k].pattern or E.Definitions[k].trap or E.Definitions[k].melee or E.Definitions[k].tactical or E.Definitions[k].mobile or E.Definitions[k].condition or E.Definitions[k].spacing or E.Definitions[k].resource or E.Definitions[k].crossfire or E.Definitions[k].discipline or E.Definitions[k].companion or E.Definitions[k].edict or E.Definitions[k].link) then c[k]=math.min(1,n) end end
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
