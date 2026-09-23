-- Hero-derived combat resolves one shared route. Native death presentation,
-- damage, XP and drops retain their existing authorities and schedules.
local D, Run = LOD.EventDirector, LOD.RunManager
local S = {id="skeleton_blockade",contract="BLOCKADE",production=true,reversible=true}
LOD.EventSkeletonBlockade = S
local function key(c) return LOD.MazeGenerator.CellKey(c.x,c.y,c.z) end
function S.CanResolve(_, g, p, reach) return reach[p.cellKey] == true end
function S.Validate(_, g, p)
    local e=g.Edges[p.edgeKey]
    return e and e.a.z==e.b.z and LOD.SafeTeleport:FlatCell(g,e.a)
        and LOD.SafeTeleport:FlatCell(g,e.b) or false
end
function S.Place(_, director, g, cell, environment)
    local k=key(cell)
    if director:ProtectedCells(g)[k] or not LOD.SafeTeleport:FlatCell(g,cell) then return end
    local neighbors={}; for n in pairs(cell.neighbors) do neighbors[#neighbors+1]=n end
    table.sort(neighbors)
    for _,n in ipairs(neighbors) do
        local ek=k<n and k.."|"..n or n.."|"..k
        local p={cellKey=k,edgeKey=ek}
        if S.Validate(nil,g,p) and director:ValidatePlacement(g,S,p,environment and environment.reserved,environment) then
            return p
        end
    end
end
local function pairOwned(director,i)
    return director:IsCurrent(i) and i.hostile and i.barrier and i.hostile~=i.barrier
        and i.entities[1]==i.hostile and i.entities[2]==i.barrier
        and IsValid(i.hostile) and IsValid(i.barrier)
        and i.hostile.LODEventInstance==i and i.barrier.LODEventInstance==i
        and i.hostile.LODSkeletonHero==true and i.barrier.LODEventBarrier==true
end
function S.Owned(director,i) return pairOwned(director,i) and i.state=="active" end
local function simulationLive(acceptedDeath)
    local s=Run.State
    -- A sealed lethal result may finish while an empty server pauses simulation;
    -- otherwise the shared death queue would consume its only pending callback.
    if s.SimulationFrozen and not acceptedDeath then return false end
    local c=s.CampaignClock
    return not c or not (c.expired or c.scene or c.deadline and SysTime()>=c.deadline)
end
function S.Create(director,i,g)
    local hostile,err=LOD.SkeletonHero:Spawn(director,i,g)
    if not IsValid(hostile) or i.entities[1]~=hostile or i.hostile~=hostile
        or hostile.LODEventInstance~=i then return nil,err or "Skeleton creation failed" end
    hostile:SetNW2String("LOD_EventArchetype",S.id)
    hostile:SetNW2String("LOD_EventID",i.id)
    local barrier,why=director:CreateBlockadeBarrier(i,g,"skeleton")
    if not barrier then return nil,why end
    if not IsValid(hostile) or hostile.LODDead or hostile:Health()<=0 or i.hostile~=hostile or i.barrier~=barrier
        or i.entities[1]~=hostile or i.entities[2]~=barrier
        or hostile.LODEventInstance~=i or barrier.LODEventInstance~=i
        or not director:Track(i,hostile) then return nil,"Skeleton resources lost during creation" end
    return hostile
end
function S.Interact() return false,"Defeat the Skeleton to open this passage." end

-- Called only by lod_hostile's canonical lethal callback, before any extension
-- kill hook runs. No native mutation or retained DamageInfo escapes this stack.
function S.AcceptDeath(hostile)
    local i=hostile.LODEventInstance
    if not S.Owned(D,i) or i.hostile~=hostile or i.combatDeath
        or hostile.LODDead or hostile:Health()>0 or not simulationLive() then return false end
    i.combatDeath=true; i.deathHostile=hostile
    return true
end
function S.RewardOwned(hostile)
    local i=hostile.LODEventInstance
    return pairOwned(D,i) and (i.state=="active" or i.state=="resolved")
        and i.combatDeath==true and i.deathHostile==hostile and i.hostile==hostile
        and hostile.LODDead==true and hostile:Health()<=0 and simulationLive(true) and not i.fault
end
local function fail(i,reason)
    if not D:IsCurrent(i) then return false end
    i.fault=reason
    -- The only recovery for lost required native resources is the canonical
    -- abort/cleanup path. Removal is never an alternative way to win this event.
    Run:FailCampaign("Skeleton blockade unavailable: "..reason)
    return false
end

-- Called by the existing shared corpse scheduler after the native damage stack.
function S.ResolveDeath(hostile)
    local i=hostile.LODEventInstance
    if not S.RewardOwned(hostile) then return false end
    if i.state=="resolved" then return true end
    if i.opening then return false end
    i.opening=true
    local barrier=i.barrier
    local ok,opened=pcall(function()
        barrier:SetOpened(true); barrier:SetOpenedAt(CurTime())
        barrier:SetSolid(SOLID_NONE); barrier:SetNotSolid(true)
        barrier:CollisionRulesChanged()
        return barrier:GetOpened() and not barrier:IsSolid()
    end)
    if not ok or not opened or not S.RewardOwned(hostile) or i.barrier~=barrier then
        -- Roll back only the captured obstacle in its exact surviving dungeon.
        if D:IsCurrent(i) and IsValid(barrier) and barrier.LODEventInstance==i and i.entities[2]==barrier then
            pcall(function()
                barrier:SetOpened(false);barrier:SetOpenedAt(0)
                barrier:SetSolid(SOLID_BBOX);barrier:SetNotSolid(false);barrier:CollisionRulesChanged()
            end)
        end
        i.opening=nil
        return fail(i,"native opening or ownership failed")
    end
    -- Seal before presentation; failed transport cannot create a second death.
    i.state="resolved"; i.opening=nil
    pcall(D.SyncAll,D)
    -- Transport may trigger teardown in an extension. The corpse scheduler
    -- must not continue native presentation on a removed or replaced actor.
    return S.RewardOwned(hostile)
end
function S.Removed(hostile)
    local i=hostile.LODEventInstance
    if D:IsCurrent(i) and i.hostile==hostile and i.state=="active" then i.fault="hostile removed" end
end
function S.Tick(director,i)
    if not director:IsCurrent(i) or i.state~="active" then return end
    if i.fault or not S.Owned(director,i) then fail(i,i.fault or "required entity lost or replaced") end
end
function S.Snapshot(i)
    local h=i.hostile
    local state=h and h.LODProgressionState
    local identity=state and state.characterIdentityPackage
    return {name=state and state.skeletonName or identity and identity.fullDisplayName or "Skeleton of a Hero",
        class=state and state.classId,level=state and state.level,defeated=i.combatDeath==true,
        opened=i.state=="resolved",hostileIndex=IsValid(h) and h:EntIndex() or 0,
        barrierIndex=IsValid(i.barrier) and i.barrier:EntIndex() or 0}
end
function S.Cleanup(_,i)
    i.combatDeath=nil; i.deathHostile=nil; i.opening=nil
    local attribution=LOD.CombatAttributionSystem
    if attribution and attribution.Ledgers and i.hostile then attribution.Ledgers[i.hostile]=nil end
end
S.previewNotice="Skeleton preview is unranked. Defeat the Hero-derived hostile on this side; its passage opens for everyone. Removal never counts as a kill."
LOD.EventRegistry:Register(S)
