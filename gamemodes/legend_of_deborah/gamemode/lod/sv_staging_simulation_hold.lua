LOD = LOD or {}

local Staging = LOD.StagingDeployment
local RunManager = LOD.RunManager
if not Staging or not RunManager then return end

local function connectedDeploymentCounts()
    local staged, deployed = 0, 0
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and RunManager.IsSlotActivePlayer and RunManager:IsSlotActivePlayer(ply) then
            local ps = RunManager:GetPlayerState(ply)
            if ps and ps.deploymentComplete == true then
                deployed = deployed + 1
            elseif ps then
                staged = staged + 1
            end
        end
    end
    return staged, deployed
end

-- RunManager's existing SimulationFrozen flag is already observed by hostile,
-- encounter, Magic/map, and campaign-time systems. Reuse that one authority rather
-- than inventing a second pause flag: if at least one reserved player is connected
-- but nobody has deployed yet, the generated dungeon waits. As soon as the first
-- player uses the portal, the normal RunManager unfreeze path resumes the campaign.
if not RunManager.LODStagingSimulationHoldInstalled then
    RunManager.LODStagingSimulationHoldInstalled = true
    local baseUpdateFreezeState = RunManager.UpdateFreezeState

    function RunManager:UpdateFreezeState()
        local state = self.State
        if state and state.BuildReady and not state.Failed and not state.LevelCleared then
            local staged, deployed = connectedDeploymentCounts()
            if staged > 0 and deployed == 0 then
                if not state.SimulationFrozen then
                    state.SimulationFrozen = true
                    state.FreezeStarted = CurTime()
                elseif state.FreezeStarted == nil then
                    state.FreezeStarted = CurTime()
                end
                Staging.SimulationHeldForStaging = true
                return true
            end
        end

        Staging.SimulationHeldForStaging = false
        return baseUpdateFreezeState(self)
    end
end

concommand.Add("lod_staging_simulation_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local staged, deployed = connectedDeploymentCounts()
    local state = RunManager.State or {}
    local held = Staging.SimulationHeldForStaging == true
    local passed = not (staged > 0 and deployed == 0) or held
    local line = string.format(
        "connectedStaged=%d connectedDeployed=%d stagingHold=%s simulationFrozen=%s result=%s",
        staged, deployed, tostring(held), tostring(state.SimulationFrozen == true),
        passed and "PASS" or "FAIL")
    print("[LOD:STAGING-SIM] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
