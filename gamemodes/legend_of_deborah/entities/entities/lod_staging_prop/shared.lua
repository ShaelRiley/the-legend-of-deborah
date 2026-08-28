ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "LOD Staging Prop"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

ENT.KIND_GUIDE = 1
ENT.KIND_PORTAL = 2
ENT.KIND_WEAPON = 3
ENT.KIND_SIGN = 4
ENT.KIND_TORCH = 5
ENT.KIND_PEDESTAL = 6

-- Portal interaction geometry deliberately matches the visible floor pad + vortex
-- rather than the tiny stock teleplatform collision box. Coordinates are in the
-- portal entity's local space: X=depth, Y=horizontal width, Z=height.
ENT.PORTAL_USE_MINS = Vector(-52, -78, -12)
ENT.PORTAL_USE_MAXS = Vector(52, 78, 154)
ENT.PORTAL_USE_DISTANCE = 340

local function intersectSegmentAABB(origin, delta, mins, maxs)
    local tMin, tMax = 0, 1

    local function axis(o, d, mn, mx)
        if math.abs(d) < 0.000001 then
            return o >= mn and o <= mx
        end

        local a = (mn - o) / d
        local b = (mx - o) / d
        if a > b then a, b = b, a end
        tMin = math.max(tMin, a)
        tMax = math.min(tMax, b)
        return tMin <= tMax
    end

    if not axis(origin.x, delta.x, mins.x, maxs.x) then return nil end
    if not axis(origin.y, delta.y, mins.y, maxs.y) then return nil end
    if not axis(origin.z, delta.z, mins.z, maxs.z) then return nil end
    return tMin
end

-- Shared client/server ray test. The HUD prompt, local feedback, and authoritative
-- server Use fallback all call this same method so the visual and usable portal can
-- never drift apart again.
function ENT:PortalAimFraction(ply, maxDistance)
    if not IsValid(self) or self:GetStageKind() ~= self.KIND_PORTAL then return nil end
    if not IsValid(ply) or not ply:IsPlayer() then return nil end

    local distance = math.max(1, tonumber(maxDistance) or self.PORTAL_USE_DISTANCE)
    local eye = ply:EyePos()
    local endpoint = eye + ply:EyeAngles():Forward() * distance
    local localEye = self:WorldToLocal(eye)
    local localEnd = self:WorldToLocal(endpoint)
    local delta = localEnd - localEye

    return intersectSegmentAABB(localEye, delta, self.PORTAL_USE_MINS, self.PORTAL_USE_MAXS)
end

function ENT:IsPortalAimHit(ply, maxDistance)
    return self:PortalAimFraction(ply, maxDistance) ~= nil
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "StageKind")
    self:NetworkVar("String", 0, "StageLabel")

    -- Historical staging code still assigns an E-specific portal label. Keep the
    -- networked/world label input-agnostic; the client HUD resolves each player's
    -- actual +use binding independently.
    if SERVER then
        self:NetworkVarNotify("StageLabel", function(ent, _, _, newValue)
            if not IsValid(ent) or ent:GetStageKind() ~= ent.KIND_PORTAL then return end
            if tostring(newValue or "") ~= "PRESS E — ENTER THE DUNGEON" then return end
            timer.Simple(0, function()
                if IsValid(ent) and ent:GetStageKind() == ent.KIND_PORTAL
                    and ent:GetStageLabel() == "PRESS E — ENTER THE DUNGEON"
                then
                    ent:SetStageLabel("ENTER THE DUNGEON")
                end
            end)
        end)
    end
end