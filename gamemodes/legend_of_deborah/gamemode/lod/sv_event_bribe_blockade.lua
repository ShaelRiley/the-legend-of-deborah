-- Required-route toll with a concrete, permanently unspent approachable payment.
-- EventDirector owns planning/claims; Equipment owns every item and its value.
local E,Run,Builder=LOD.Equipment,LOD.RunManager,LOD.MazeBuilder
local B={id='bribe_blockade',contract='BLOCKADE',production=true,reversible=true,repeatable=true,price=50}
LOD.EventBribeBlockade=B
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
local function sorted(t) local out={};for k in pairs(t or {}) do out[#out+1]=k end;table.sort(out);return out end
local function optional(g,k,director)
    if director:ProtectedCells(g)[k] or not LOD.SafeTeleport:FlatCell(g,g.Cells[k]) then return false end
    for _,c in ipairs(g.CriticalPath or {}) do if key(c)==k then return false end end
    return true
end
function B.Collateral(g,placement)
    local seed=LOD.Seeds.Derive(g.MasterLevelSeed or g.LevelSeed or 1,'bribe-collateral:'..placement.edgeKey..':v1')
    return E:Generate(seed,g.DungeonLevel or Run.State.Level or 1,'ring',
        tostring(Run.State.RunId)..':bribe:'..tostring(g.MasterLevelSeed or g.LevelSeed)..':'..placement.edgeKey)
end
function B.CanResolve(_,g,placement,reach)
    if not reach[placement.cellKey] or not reach[placement.cacheCellKey] then return false end
    local item=B.Collateral(g,placement)
    return item and E:ValidateWearable(item) and E:Value(item)>=B.price or false
end
function B.Validate(_,g,p)
    local e=g.Edges[p.edgeKey]
    return e and e.a.z==e.b.z and LOD.SafeTeleport:FlatCell(g,e.a) and LOD.SafeTeleport:FlatCell(g,e.b)
        and g.Cells[p.cacheCellKey] and optional(g,p.cacheCellKey,LOD.EventDirector) or false
end
function B.Place(_,director,g,cell,environment)
    local k=key(cell)
    if director:ProtectedCells(g)[k] or not LOD.SafeTeleport:FlatCell(g,cell) then return end
    for _,neighbor in ipairs(sorted(cell.neighbors)) do
        local ek=k<neighbor and k..'|'..neighbor or neighbor..'|'..k
        local e=g.Edges[ek]
        if e and e.a.z==e.b.z and not director:ProtectedCells(g)[neighbor]
            and LOD.SafeTeleport:FlatCell(g,g.Cells[neighbor]) then
            local p={cellKey=k,edgeKey=ek}
            local reach=director:BlockadeApproach(g,p,environment)
            if reach and reach[k] then
                local caches={}
                for ck in pairs(reach) do
                    if ck~=k and ck~=neighbor and optional(g,ck,director) then caches[#caches+1]=ck end
                end
                table.sort(caches)
                LOD.RNG.New(LOD.Seeds.Derive(g.MasterLevelSeed or g.LevelSeed or 1,'bribe-cache:'..ek..':v1')):Shuffle(caches)
                for n=1,math.min(#caches,director.MaxPlacementAttempts) do
                    p.cacheCellKey=caches[n]
                    if director:ValidatePlacement(g,B,p,environment and environment.reserved,environment) then return p end
                end
            end
        end
    end
end
function B.Owned(director,i)
    if not director:IsCurrent(i) or i.state~='active' or not i.barrier or i.entities[3]~=i.barrier then return false end
    for n=1,3 do
        local ent=i.entities[n]
        if not IsValid(ent) or ent.LODEventInstance~=i then return false end
    end
    return i.entities[1].LODBribeRole=='terminal' and i.entities[2].LODBribeRole=='cache'
        and i.barrier.LODBribeRole=='barrier'
end
-- Native preparation is reversible; settlement seals the inventory and state
-- only after all native calls and one final pure ownership check have returned.
function B.PrepareOpen(i)
    local e=i.barrier
    e:SetOpened(true);e:SetOpenedAt(CurTime());e:SetSolid(SOLID_NONE);e:SetNotSolid(true)
    if e.CollisionRulesChanged then e:CollisionRulesChanged() end
    return IsValid(e) and e:GetOpened() and not e:IsSolid()
end
function B.RestoreClosed(i,expectedBarrier)
    local e=expectedBarrier or i.barrier
    -- A lost terminal/cache invalidates settlement, not restoration of the
    -- exact prepared obstacle. Never close a replacement or later dungeon.
    if not LOD.EventDirector:IsCurrent(i) or i.state~='active' or i.barrier~=e
        or i.entities[3]~=e or not IsValid(e) or e.LODEventInstance~=i
        or e.LODBribeRole~='barrier' then return end
    e:SetOpened(false);e:SetOpenedAt(0);e:SetSolid(SOLID_BBOX);e:SetNotSolid(false)
    if e.CollisionRulesChanged then e:CollisionRulesChanged() end
end
function B.Create(director,i,g)
    i.recovered=false
    i.collateral=B.Collateral(g,i.placement)
    if not i.collateral or not E:ValidateWearable(i.collateral) or E:Value(i.collateral)<B.price then return nil,'invalid collateral' end
    for index,ck in ipairs({i.cellKey,i.placement.cacheCellKey}) do
        local ent=ents.Create('lod_dungeon_event')
        if not IsValid(ent) then return nil,'bribe interaction creation failed' end
        if not director:Track(i,ent) then ent:Remove();return nil,'stale creation' end
        ent.LODBribeRole=index==1 and 'terminal' or 'cache'
        ent:SetNW2String('LOD_EventArchetype',B.id)
        ent:SetNW2String('LOD_BribeRole',ent.LODBribeRole)
        ent:SetPos(Builder:CellCenter(g.Cells[ck])+Vector(0,0,8))
        ent:SetEventID(i.id);ent:Spawn();ent:Activate()
        if not IsValid(ent) or not director:Track(i,ent) then return nil,'bribe interaction lost' end
    end
    local e=g.Edges[i.placement.edgeKey]
    local after=key(e.a)==i.cellKey and e.b or e.a
    local barrier=ents.Create('lod_gate')
    if not IsValid(barrier) then return nil,'barrier creation failed' end
    if not director:Track(i,barrier) then barrier:Remove();return nil,'stale barrier' end
    i.barrier=barrier;barrier.LODBribeRole='barrier'
    barrier:SetNW2String('LOD_EventArchetype',B.id)
    barrier:SetGateIndex(0)
    barrier:SetGateAxis(e.a.x~=e.b.x and 0 or 1)
    local height=LOD.Config.Progression.GateBlockerHeight
    barrier:SetPos((Builder:CellCenter(i.cell)+Builder:CellCenter(after))*.5+Vector(0,0,height*.5))
    barrier.LODOverheadHeight=Builder:ProgressionBarrierHeight({beforeCell=i.cell,afterCell=after},g)
    barrier:Spawn();barrier:Activate()
    if not IsValid(barrier) or not director:Track(i,barrier) then return nil,'barrier lost during creation' end
    return i.entities[1]
end
function B.Interact(director,i,ply,identity,entity) return B.Review(director,i,ply,identity,entity) end
function B.Snapshot(i)
    return {price=B.price,recovered=i.recovered==true,opened=i.state=='resolved',cacheCellKey=i.placement.cacheCellKey,
        collateralName=i.collateral and E:ItemName(i.collateral),collateralValue=i.collateral and E:Value(i.collateral),
        endpoints={{entityIndex=IsValid(i.entities[1]) and i.entities[1]:EntIndex() or 0,role='terminal'},
            {entityIndex=IsValid(i.entities[2]) and i.entities[2]:EntIndex() or 0,role='cache'}}}
end
function B.Cleanup(_,i)
    if B.PaymentCleanup then B.PaymentCleanup(i) end
    i.collateral=nil;i.recovered=false
end
B.previewNotice='Bribe preview is unranked. Toll: 50 $DEB of unequipped wearables, or recover the guaranteed lost-property ring. Confirmation surrenders the whole selection; no change.'
LOD.EventRegistry:Register(B)
