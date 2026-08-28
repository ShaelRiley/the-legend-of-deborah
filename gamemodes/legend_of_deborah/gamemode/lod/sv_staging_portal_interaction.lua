LOD = LOD or {}

local PORTAL_KIND = 2
local PORTAL_DISTANCE = 340

local function isPortal(ent)
    return IsValid(ent)
        and ent:GetClass() == "lod_staging_prop"
        and ent.GetStageKind
        and ent:GetStageKind() == PORTAL_KIND
end

local function aimedPortal(ply)
    if not IsValid(ply) then return nil end
    local best, bestFraction

    for _, ent in ipairs(ents.FindByClass("lod_staging_prop")) do
        if isPortal(ent) and ent.PortalAimFraction then
            local fraction = ent:PortalAimFraction(ply, ent.PORTAL_USE_DISTANCE or PORTAL_DISTANCE)
            if fraction and (not bestFraction or fraction < bestFraction) then
                best, bestFraction = ent, fraction
            end
        end
    end

    return best
end

-- Source's stock +use trace only sees the teleplatform's small low collision box.
-- Keep that normal entity Use path for the physical pad, but add a fallback for the
-- tall animated vortex. The fallback calls the existing Staging:DeployPlayer
-- authority directly; it does not duplicate or replace deployment state logic.
hook.Add("KeyPress", "LOD_StagingPortalVisibleVolumeUse", function(ply, key)
    if key ~= IN_USE then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if ply:GetNW2Bool("LOD_Deployed", false) or not ply:GetNW2Bool("LOD_Staged", false) then return end

    local staging = LOD and LOD.StagingDeployment
    if not staging or not staging.DeployPlayer then return end

    -- If Source already hit the physical portal entity, ENT:Use will execute the
    -- same authoritative function. Do not double-fire denial messages or deploy.
    local tr = ply:GetEyeTrace()
    if tr and isPortal(tr.Entity) then return end

    local portal = aimedPortal(ply)
    if not IsValid(portal) then return end
    staging:DeployPlayer(ply, portal)
end)

concommand.Add("lod_staging_portal_interaction_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local portals = 0
    local sharedAim = 0
    for _, ent in ipairs(ents.FindByClass("lod_staging_prop")) do
        if isPortal(ent) then
            portals = portals + 1
            if ent.PortalAimFraction then sharedAim = sharedAim + 1 end
        end
    end

    local pass = portals > 0 and sharedAim == portals
    local line = string.format(
        "portals=%d sharedAim=%d volume=104x156x166 distance=%d useFallback=ARMED result=%s",
        portals, sharedAim, PORTAL_DISTANCE, pass and "PASS" or "FAIL")
    print("[LOD:STAGING-PORTAL-INTERACTION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
