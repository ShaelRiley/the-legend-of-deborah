-- Per-floor discovery extends the canonical minimap and RunManager state.
-- No personal item, saved inventory record or independent progression owner.
local Map, Run, Builder = LOD.MinimapServer, LOD.RunManager, LOD.MazeBuilder
local key = LOD.MazeGenerator.CellKey
local MAX_STEPS = 6

local function cellKey(c) return key(c.x, c.y, c.z) end
local function sortedKeys(t)
    local out = {}
    for k in pairs(t or {}) do out[#out + 1] = k end
    table.sort(out)
    return out
end
local function edgeKey(a, b) return a < b and a .. "|" .. b or b .. "|" .. a end

function Map:PlanFloorMaps(graph)
    if graph.FloorMapPlan then return true, graph.FloorMapPlan end
    local entrances, critical, protected, blocked = {}, {}, {}, {}
    local function protect(c) if c then protected[cellKey(c)] = true end end
    for _, c in ipairs(graph.CriticalPath or {}) do
        entrances[c.z] = entrances[c.z] or c
        critical[cellKey(c)] = true
    end
    entrances[graph.Start.z] = graph.Start
    local p = graph.Progression or {}
    protect(graph.Start); protect(graph.Goal); protect(p.CoreCell); protect(p.DeborahCell)
    for _, gate in ipairs(p.Gates or {}) do
        blocked[gate.edgeKey] = true; protect(gate.beforeCell); protect(gate.afterCell)
    end
    for _, card in ipairs(p.Keycards or {}) do protect(card.cell) end
    for _, edge in ipairs(graph.VerticalEdges or {}) do protect(edge.a); protect(edge.b) end
    for _, door in ipairs({p.JailEdge or {}, p.Warden and p.Warden.lock or {}}) do
        if door.edgeKey then blocked[door.edgeKey] = true end
        protect(door.beforeCell); protect(door.afterCell)
    end
    if p.Hunt then protect(p.Hunt.neilCell); protect(p.Hunt.bruteCell) end

    -- Arena galleries may add a physical layer outside the original critical
    -- spine. Its first BFS arrival is a canonical staircase endpoint, not a
    -- guessed coordinate or a route through missing floor geometry.
    local queue, seen, head = {cellKey(graph.Start)}, {[cellKey(graph.Start)]=true}, 1
    while queue[head] do
        local c = graph.Cells[queue[head]]; head = head + 1
        if c then
            entrances[c.z] = entrances[c.z] or c
            for _, nk in ipairs(sortedKeys(c.neighbors)) do
                if graph.Cells[nk] and not seen[nk] then seen[nk]=true; queue[#queue+1]=nk end
            end
        end
    end
    local rng = LOD.RNG.New(LOD.Seeds.Derive(graph.MasterLevelSeed or graph.LevelSeed, "floor-maps"))
    local plan = {maps={}, protectedCells={}}
    for floor=0,(graph.Layers or 1)-1 do
        local entry = entrances[floor]
        if not entry then return false, "floor map has no canonical entrance: " .. floor end
        local start = cellKey(entry)
        local distance, previous, q, at = {[start]=0}, {}, {start}, 1
        while q[at] do
            local ck=q[at]; at=at+1
            local c=graph.Cells[ck]
            if distance[ck] < MAX_STEPS then
                for _, nk in ipairs(sortedKeys(c.neighbors)) do
                    local n=graph.Cells[nk]
                    if n and n.z==floor and distance[nk]==nil and not blocked[edgeKey(ck,nk)] then
                        distance[nk]=distance[ck]+1;previous[nk]=ck;q[#q+1]=nk
                    end
                end
            end
        end
        local side, ordinary = {}, {}
        for _, ck in ipairs(sortedKeys(distance)) do
            local tag=graph.CellTags and graph.CellTags[ck] or {}
            if ck~=start and not protected[ck] and not tag.objective
                and tag.role~="boss" and tag.role~="resupply" then
                local pool=critical[ck] and ordinary or side
                pool[#pool+1]=ck
            end
        end
        local pool=#side>0 and side or ordinary
        local chosen=#pool>0 and pool[rng:Derive("floor:"..floor):Int(1,#pool)] or start
        local path, cursor = {}, chosen
        while cursor do
            path[#path+1]=cursor;plan.protectedCells[cursor]=true
            if cursor==start then break end
            cursor=previous[cursor]
        end
        local c=graph.Cells[chosen]
        plan.maps[floor]={floor=floor,cell={x=c.x,y=c.y,z=c.z},entrance=entry,
            path=path,distance=distance[chosen]}
    end
    graph.FloorMapPlan=plan
    return true, plan
end

function Map:CollectFloorMap(ply, ent)
    local state, maps = Run.State, self:PartyMaps()
    if not state or not maps or not state.BuildReady or state.Failed or state.LevelCleared
        or not IsValid(ply) or not ply:Alive() or not Run:IsActivePlayer(ply)
        or not IsValid(ent) or ent.LODFloorMapState~=maps then return false end
    local floor=ent:GetFloorIndex()
    local row=maps.plan.maps[floor]
    if not row or row.entity~=ent or maps.owned[floor] then return false end
    local radius=LOD.Config.Progression.KeycardTriggerRadius
    if ply:NearestPoint(ent:GetPos()):DistToSqr(ent:GetPos())>radius*radius then return false end
    -- Claim before any transport/announcement callback: simultaneous contacts
    -- cannot replay the award, and death cannot delete a shared discovery.
    maps.owned[floor]=true
    maps.mask=bit.bor(maps.mask,bit.lshift(1,floor))
    for _, recipient in ipairs(player.GetAll()) do
        if IsValid(recipient) then
            if LOD.MultiplayerContracts then LOD.MultiplayerContracts:SyncMapCompatibility(recipient) end
            local fx=LOD.RPGPresentation
            if recipient:Alive() and Run:IsActivePlayer(recipient) and fx and fx.SendFX then
                fx:SendFX(recipient,5,"Use map with Q","M works too")
            end
        end
    end
    if LOD.ProgressionDirector then
        LOD.ProgressionDirector:Announce("FLOOR "..(floor+1).." MAP FOUND — SHARED WITH THE PARTY",
            {event="floor_map_acquired",floor=floor+1})
    end
    ent:Remove()
    return true
end

if not Builder.LODFloorMapBuildWrapped then
Builder.LODFloorMapBuildWrapped=true
local baseBuild=Builder.Build
function Builder:Build(graph)
    local planned, plan=Map:PlanFloorMaps(graph)
    if not planned then return false, plan end
    Map.FloorMapSerial=(Map.FloorMapSerial or 0)+1
    local state=Run.State
    local maps={graph=graph,plan=plan,epoch=state.CampaignEpoch,level=state.Level,
        seed=state.LevelSeed,serial=Map.FloorMapSerial,mask=0,owned={}}
    state.FloorMaps=maps
    local ok, report, retry=baseBuild(self,graph)
    if not ok then return ok,report,retry end
    for floor=0,(graph.Layers or 1)-1 do
        local row=plan.maps[floor]
        local ent=ents.Create("lod_floor_map")
        if not IsValid(ent) then self:Cleanup();return false,"required floor map creation failed: "..floor end
        ent.LODFloorMapState=maps
        row.entity=ent
        ent:SetFloorIndex(floor)
        ent:SetPos(self:CellCenter(row.cell)+Vector(0,0,LOD.Config.Progression.KeycardHeight))
        ent:Spawn();ent:Activate();self:_Register(ent)
    end
    report.floorMaps=graph.Layers or 1
    report.entityCount=#self.Entities
    return true,report
end
end
