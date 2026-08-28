if engine.ActiveGamemode and engine.ActiveGamemode() ~= "legend_of_deborah" then return end

util.AddNetworkString("LOD_StagingPortalTransit")

local PORTAL_KIND = 2
local TRANSIT_DURATION = 0.62
local INSTALL_TIMER = "LOD_StagingPortalTransitInstall"
local pending = setmetatable({}, {__mode = "k"})

local function getRunState(ply)
    local run = LOD and LOD.RunManager
    if not run or not IsValid(ply) then return nil end
    local ps = run:GetPlayerState(ply)
    return run, ps
end

local function eligibleForTransit(ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return false end

    local run, ps = getRunState(ply)
    if not run or not ps or ps.deploymentComplete or not ps.starterClaimed then return false end
    if run.IsSlotActivePlayer and not run:IsSlotActivePlayer(ply) then return false end

    local state = run.State
    if not state or not state.BuildReady or state.Failed or state.LevelCleared then return false end
    local destination = state.CheckpointPos or (state.BuildReport and state.BuildReport.startPos)
    if not destination then return false end

    return true
end

local function broadcastTransit(phase, ply, portal, pos, duration)
    net.Start("LOD_StagingPortalTransit")
        net.WriteUInt(math.Clamp(tonumber(phase) or 0, 0, 3), 2)
        net.WriteEntity(IsValid(ply) and ply or Entity(0))
        net.WriteEntity(IsValid(portal) and portal or Entity(0))
        net.WriteVector(pos or vector_origin)
        net.WriteFloat(tonumber(duration) or 0)
    net.Broadcast()
end

local function portalCenter(portal)
    if not IsValid(portal) then return vector_origin end
    return portal:GetPos() + Vector(0, 0, 68)
end

local function playActivationCue(portal, ply)
    if not IsValid(portal) then return end
    local pos = portalCenter(portal)

    -- One low teleporter spool plus a three-step rising chime makes portal use
    -- immediately distinguishable from the ordinary idle vortex and weapon pickup.
    portal:EmitSound("ambient/machines/teleport3.wav", 78, 82, 0.78, CHAN_STATIC)
    sound.Play("buttons/button17.wav", pos, 68, 92, 0.34)

    timer.Simple(0.15, function()
        if not IsValid(portal) or not IsValid(ply) or not pending[ply] then return end
        sound.Play("buttons/button17.wav", pos, 70, 118, 0.42)
    end)
    timer.Simple(0.31, function()
        if not IsValid(portal) or not IsValid(ply) or not pending[ply] then return end
        sound.Play("buttons/button17.wav", pos, 72, 148, 0.50)
    end)

    util.ScreenShake(pos, 2.2, 18, 0.38, 230)
end

local function playArrivalCue(ply)
    if not IsValid(ply) then return end
    local pos = ply:GetPos() + Vector(0, 0, 42)
    sound.Play("buttons/button17.wav", pos, 74, 182, 0.58)
    util.ScreenShake(pos, 2.6, 22, 0.24, 190)
end

local function installPortalTransit()
    local stored = scripted_ents.GetStored("lod_staging_prop")
    local class = stored and stored.t
    if not class or not isfunction(class.Use) then return false end
    if class.LODPortalTransitFeedbackInstalled then return true end

    local baseUse = class.Use
    class.LODPortalTransitFeedbackInstalled = true
    class.LODPortalTransitFeedbackBaseUse = baseUse

    function class:Use(activator)
        local kind = self.GetStageKind and self:GetStageKind() or 0
        if kind ~= PORTAL_KIND or not IsValid(activator) or not activator:IsPlayer() then
            return baseUse(self, activator)
        end

        -- Preserve all existing denial/invalid-state behavior immediately. The
        -- transit ceremony only begins once the player has actually earned entry.
        if not eligibleForTransit(activator) then
            return baseUse(self, activator)
        end

        if pending[activator] then return end
        pending[activator] = {
            portal = self,
            started = CurTime()
        }

        activator:Freeze(true)
        activator:SetLocalVelocity(vector_origin)
        broadcastTransit(0, activator, self, portalCenter(self), TRANSIT_DURATION)
        playActivationCue(self, activator)

        timer.Simple(TRANSIT_DURATION, function()
            local record = pending[activator]
            if not record then return end
            pending[activator] = nil

            if not IsValid(activator) then return end
            activator:Freeze(false)
            if not IsValid(self) then return end

            -- Deployment itself remains owned by the existing staging authority.
            -- We merely delay that authoritative call long enough for the portal
            -- commitment to be perceived, then observe whether it succeeded.
            baseUse(self, activator)

            timer.Simple(0, function()
                if not IsValid(activator) then return end
                local staging = LOD and LOD.StagingDeployment
                if not staging or not staging.IsDeployed or not staging:IsDeployed(activator) then return end

                local arrival = activator:GetPos() + Vector(0, 0, 42)
                broadcastTransit(1, activator, self, arrival, 0.78)
                playArrivalCue(activator)
            end)
        end)
    end

    print("[LOD:STAGING-PORTAL] transit feedback armed duration=" .. tostring(TRANSIT_DURATION))
    return true
end

hook.Add("InitPostEntity", "LOD_StagingPortalTransitInit", function()
    if installPortalTransit() then timer.Remove(INSTALL_TIMER) end
end)

timer.Create(INSTALL_TIMER, 0.25, 0, function()
    if installPortalTransit() then timer.Remove(INSTALL_TIMER) end
end)

hook.Add("PlayerDisconnected", "LOD_StagingPortalTransitDisconnect", function(ply)
    pending[ply] = nil
end)

concommand.Add("lod_staging_portal_feedback_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local stored = scripted_ents.GetStored("lod_staging_prop")
    local class = stored and stored.t
    local armed = class and class.LODPortalTransitFeedbackInstalled == true or false
    local line = string.format(
        "armed=%s duration=%.2f audio=rising-portal-cue visual=blue-gold-maze-sigil result=%s",
        tostring(armed), TRANSIT_DURATION, armed and "PASS" or "FAIL")
    print("[LOD:STAGING-PORTAL] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
