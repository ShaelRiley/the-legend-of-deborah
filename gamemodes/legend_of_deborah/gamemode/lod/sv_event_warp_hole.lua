-- A paired, dungeon-owned shortcut; ordinary navigation still proves every trip.
LOD.WarpHoleEvent = LOD.WarpHoleEvent or {}
local W, T, N, Run = LOD.WarpHoleEvent, LOD.SafeTeleport, LOD.MazeNavigator, LOD.RunManager
W.MinimumDungeonLevel, W.CooldownSeconds = 5, 1
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function endpointCell(instance, index, graph)
    return graph.Cells[index == 1 and instance.cellKey or instance.placement.destinationCellKey]
end
local function route(graph, a, b)
    return N:FindPath(graph,a,b) and N:FindPath(graph,b,a)
end

function W:TryTraverse(director, instance, ply, identity, entity)
    local binding = T:Bind(ply)
    local graph = binding and binding.graph
    local index = IsValid(entity) and entity.LODWarpEndpoint
    if not binding or (index ~= 1 and index ~= 2) or not instance.endpoints
        or instance.endpoints[index] ~= entity then return false, "Warp endpoint unavailable." end
    local other = instance.endpoints[3-index]
    local source, destination = endpointCell(instance,index,graph), endpointCell(instance,3-index,graph)
    local function current(skipTrace)
        -- The native trace in InteractionCurrent can invoke engine callbacks;
        -- recheck exact life, account and graph AFTER those callbacks return.
        if not skipTrace and not director:InteractionCurrent(instance,ply,identity,binding.ps,entity) then return false end
        local ps,clock=binding.ps,Run.State.CampaignClock
        return T:Matches(binding) and director:IsCurrent(instance) and instance.state=="active"
            and ply:SteamID64()==identity and ply:Alive() and Run:IsActivePlayer(ply)
            and not Run:IsSoldierControl(ply) and Run:GetPlayerState(ply)==ps
            and ps.deploymentComplete and not ps.inStaging and not ps.eliminated and (ps.lives or 0)>0
            and not Run.State.SimulationFrozen
            and not (clock and (clock.expired or clock.scene or (clock.deadline and SysTime()>=clock.deadline)))
            and instance.endpoints and instance.endpoints[index]==entity and instance.endpoints[3-index]==other
            and IsValid(entity) and entity.LODEventInstance==instance and entity.LODWarpEndpoint==index
            and IsValid(other) and other.LODEventInstance==instance and other.LODWarpEndpoint==3-index
            and instance.entities[index]==entity and instance.entities[3-index]==other
            and endpointCell(instance,index,graph)==source and endpointCell(instance,3-index,graph)==destination
            and ply:GetPos():DistToSqr(entity:GetPos())<=160*160
            and T:CellAt(graph,ply:GetPos())==source and route(graph,source,destination)
    end
    if not current() then return false, "Warp route or Hero changed." end
    instance.traversalCooldowns=instance.traversalCooldowns or setmetatable({},{__mode="k"})
    if CurTime()<(instance.traversalCooldowns[binding.ps] or 0) then return false, "Warp settling — wait one second." end
    local landing = T:Landing(ply,graph,destination,N:CellCenter(destination))
    if not landing or not current() then return false, "Arrival blocked or unsafe. Nothing moved." end
    local moved, why = T:MoveBound(binding,landing,current,destination)
    if not moved then return false, why end
    instance.linked=true
    instance.traversalCooldowns[binding.ps]=CurTime()+self.CooldownSeconds
    for _, endpoint in ipairs(instance.endpoints) do
        endpoint:SetNW2Bool("LOD_WarpLinked",true)
        endpoint:SetColor(Color(100,225,235))
    end
    director:SyncAll()
    return true, {endpoint=3-index,floor=destination.z+1,linked=true}
end

LOD.EventRegistry:Register({
    id="warp_hole",contract="UTILITY",production=true,nonblocking=true,pairedWarp=true,repeatable=true,
    minDungeonLevel=W.MinimumDungeonLevel,
    previewNotice="Warp-hole preview is unranked and bypasses the Dungeon Level 5 minimum. Use either cyan endpoint to link and traverse; free repeat trips, one second apart.",
    Place=function(_,director,g,cell,environment)
        if not T:FlatCell(g,cell) or director:ProtectedCells(g)[key(cell)] then return nil end
        for _,c in ipairs(g.CriticalPath or {}) do if key(c)==key(cell) then return nil end end
        local candidates={}
        for k,c in pairs(g.Cells) do if c.z~=cell.z and T:FlatCell(g,c) then candidates[#candidates+1]=k end end
        table.sort(candidates)
        LOD.RNG.New(LOD.Seeds.Derive(g.MasterLevelSeed or g.LevelSeed or 1,"warp-partner:"..key(cell)..":v1")):Shuffle(candidates)
        for i=1,math.min(#candidates,director.MaxPlacementAttempts) do
            local placement={cellKey=key(cell),destinationCellKey=candidates[i]}
            if director:ValidateEndpointPair(g,placement,environment and environment.reserved,environment) then return placement end
        end
    end,
    Validate=function(_,g,placement)
        local a,b=g.Cells[placement.cellKey],g.Cells[placement.destinationCellKey]
        return a and b and a.z~=b.z and T:FlatCell(g,a) and T:FlatCell(g,b) or false
    end,
    Create=function(director,instance,g)
        instance.endpoints,instance.linked={},false
        instance.traversalCooldowns=setmetatable({},{__mode="k"})
        for index=1,2 do
            local ent=ents.Create("lod_dungeon_event")
            if not IsValid(ent) then return nil,"warp endpoint creation failed" end
            if not director:Track(instance,ent) then ent:Remove();return nil,"stale warp creation" end
            instance.endpoints[index]=ent
            ent.LODWarpEndpoint=index
            ent:SetNW2String("LOD_EventArchetype","warp_hole")
            ent:SetNW2Int("LOD_WarpEndpoint",index)
            ent:SetNW2Bool("LOD_WarpLinked",false)
            ent:SetNW2Int("LOD_WarpDestinationFloor",endpointCell(instance,3-index,g).z+1)
            ent:SetPos(N:CellCenter(endpointCell(instance,index,g))+Vector(0,-80,8))
            ent:SetEventID(instance.id)
            ent:Spawn();ent:Activate()
            if not IsValid(ent) or not director:Track(instance,ent) then return nil,"stale warp creation" end
        end
        return instance.endpoints[1]
    end,
    Interact=function(director,instance,ply,identity,entity)
        return W:TryTraverse(director,instance,ply,identity,entity)
    end,
    Snapshot=function(instance)
        local graph=Run.State.Graph
        local details={linked=instance.linked==true,endpoints={}}
        for index,ent in ipairs(instance.endpoints or {}) do
            local cell,destination=endpointCell(instance,index,graph),endpointCell(instance,3-index,graph)
            details.endpoints[index]={entityIndex=IsValid(ent) and ent:EntIndex() or 0,cellKey=key(cell),
                floor=cell.z+1,destinationFloor=destination.z+1}
        end
        return details
    end,
    Cleanup=function(_,instance)
        instance.linked=false
        instance.endpoints=nil
        instance.traversalCooldowns=nil
        instance.interactions=nil
    end
})
