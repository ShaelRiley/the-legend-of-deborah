LOD = LOD or {}

local Loot = LOD.LootDirector
local RunManager = LOD.RunManager
if not Loot or not RunManager then return end

Loot.InitialLevelOneIdentities = Loot.InitialLevelOneIdentities or {}
Loot.InitialAdmissionEpoch = Loot.InitialAdmissionEpoch or -1

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
    end

    return true, planOrErr
end

local baseTryActivate = RunManager.TryActivatePlayer
function RunManager:TryActivatePlayer(ply)
    local existed = self:GetPlayerState(ply) ~= nil
    local active = baseTryActivate(self, ply)
    if not active or existed then return active end

    local ps = self:GetPlayerState(ply)
    local id = self:IdentityOf(ply)
    if not ps or not id then return active end

    local level = self.State.Level or 1
    local initialLevelOne = level == 1
        and Loot.InitialAdmissionEpoch == (self.State.CampaignEpoch or 0)
        and Loot.InitialLevelOneIdentities[id] == true

    if not initialLevelOne then
        ps.catchupLevel = level
    end

    return active
end
