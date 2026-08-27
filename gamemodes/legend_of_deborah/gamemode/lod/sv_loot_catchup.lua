LOD = LOD or {}

local Loot = LOD.LootDirector
local RunManager = LOD.RunManager
if not Loot or not RunManager then return end

Loot.InitialLevelOneIdentities = Loot.InitialLevelOneIdentities or {}
Loot.InitialAdmissionEpoch = Loot.InitialAdmissionEpoch or -1
Loot.InitialSnapshotWasEmpty = Loot.InitialSnapshotWasEmpty == true

local baseBuildStaticPlan = Loot.BuildStaticPlan
function Loot:BuildStaticPlan(graph)
    local ok, planOrErr = baseBuildStaticPlan(self, graph)
    if not ok then return ok, planOrErr end

    local state = RunManager.State
    local epoch = state and state.CampaignEpoch or 0
    if (state and state.Level or 1) == 1 and self.InitialAdmissionEpoch ~= epoch then
        self.InitialAdmissionEpoch = epoch
        self.InitialLevelOneIdentities = {}

        -- Only identities eligible to occupy the initial four active slots count
        -- as initial Level-1 participants. Extra connected spectators remain true
        -- join-in-progress players if they enter play later.
        local connected = RunManager:_SortedConnectedPlayers()
        local limit = math.min(#connected, LOD.Config.MaxActivePlayers or 4)
        for index = 1, limit do
            local id = RunManager:IdentityOf(connected[index])
            if id then self.InitialLevelOneIdentities[id] = true end
        end

        -- On a listen server InitPostEntity can build Level 1 before the host's
        -- PlayerInitialSpawn exists. Remember that empty startup snapshot so the
        -- first identity admitted a moment later is treated as the bootstrap host,
        -- not as a late joiner. Only that first identity receives this fallback;
        -- later Level-1 arrivals still get the intended JIP catch-up kit.
        self.InitialSnapshotWasEmpty = limit == 0
    end

    return true, planOrErr
end

local baseTryActivate = RunManager.TryActivatePlayer
function RunManager:TryActivatePlayer(ply)
    local existed = self:GetPlayerState(ply) ~= nil
    local playedBefore = self:_PlayedCount()
    local active = baseTryActivate(self, ply)
    if not active or existed then return active end

    local ps = self:GetPlayerState(ply)
    local id = self:IdentityOf(ply)
    if not ps or not id then return active end

    local level = self.State.Level or 1
    local sameInitialEpoch = Loot.InitialAdmissionEpoch == (self.State.CampaignEpoch or 0)
    local initialFromSnapshot = level == 1
        and sameInitialEpoch
        and Loot.InitialLevelOneIdentities[id] == true
    local bootstrapHost = level == 1
        and sameInitialEpoch
        and Loot.InitialSnapshotWasEmpty == true
        and playedBefore == 0

    local initialLevelOne = initialFromSnapshot or bootstrapHost
    if bootstrapHost then
        Loot.InitialLevelOneIdentities[id] = true
        Loot.InitialSnapshotWasEmpty = false
    end

    ps.initialLevelOneParticipant = initialLevelOne == true
    if not initialLevelOne then
        ps.catchupLevel = level
    else
        ps.catchupLevel = nil
        ps.catchupGrantedLevel = nil
    end

    return active
end
