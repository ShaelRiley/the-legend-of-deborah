local SOLDIER_HAND_BONE = "ValveBiped.Bip01_R_Hand"
local SIGHT_FORWARD_OFFSET = 18
local SIGHT_DOWN_OFFSET = 10
local SIGHT_SIDE_OFFSET = 2

local function installWeaponSiteAnchor()
    local stored = scripted_ents.GetStored("lod_hostile")
    local ENT = stored and stored.t
    if not ENT then return false end
    if ENT.LODWeaponSiteAnchorInstalled then return true end

    function ENT:_SoldierRawHandPos()
        local handBone = self:LookupBone(SOLDIER_HAND_BONE)
        if handBone then
            local handPos = self:GetBonePosition(handBone)
            if handPos and handPos ~= self:GetPos() then
                return handPos
            end
        end

        local attachment = self:LookupAttachment("anim_attachment_RH")
        if attachment and attachment > 0 then
            local data = self:GetAttachment(attachment)
            if data and data.Pos then return data.Pos end
        end

        return self:WorldSpaceCenter() + Vector(0, 0, 12)
    end

    function ENT:_SoldierMuzzlePos(aimPos)
        local rawHandPos = self:_SoldierRawHandPos()

        -- During an active burst, use the immutable warning aim point so the
        -- projectile spawn and visible laser share the same weapon-site anchor.
        if (not aimPos or aimPos == vector_origin) and self.LODSoldierBurst then
            local frozenAim = self:GetNW2Vector("LOD_SoldierAim", vector_origin)
            if frozenAim ~= vector_origin then aimPos = frozenAim end
        end

        local direction = self:GetForward()
        if aimPos and aimPos ~= vector_origin then
            local delta = aimPos - rawHandPos
            if delta:LengthSqr() > 0.001 then direction = delta:GetNormalized() end
        end

        -- Approximate the AR2 laser emitter rather than the actor's hand bone:
        -- forward of the firing hand, below it on the rifle line, and slightly
        -- inward toward the weapon body. This is presentation-critical because
        -- the warning beam is intended to read as a literal pre-shot laser sight.
        local rawPos = rawHandPos
            + direction * SIGHT_FORWARD_OFFSET
            - self:GetUp() * SIGHT_DOWN_OFFSET
            - self:GetRight() * SIGHT_SIDE_OFFSET

        local size = math.Clamp(self:GetNW2Float("LOD_SizeScale", 1), 0.33, 1.33)
        local mins = util.GetModelBounds and select(1, util.GetModelBounds(self:GetModel()))
            or Vector(-16, -16, 0)
        local motionV2 = self:GetNW2Bool("LOD_MotionV2", false)
        local verticalCompensation = motionV2 and -(mins.z * size) or mins.z * (1 - size)
        local localPos = self:WorldToLocal(rawPos) * size
        localPos.z = localPos.z + verticalCompensation
        return self:LocalToWorld(localPos)
    end

    ENT.LODWeaponSiteAnchorInstalled = true
    return true
end

-- Scripted entities are normally registered before the gamemode's server init.
-- Retain a zero-cost fallback for unusual load ordering so the first hostile can
-- install the override before its Spawn/Initialize path uses the muzzle helper.
if not installWeaponSiteAnchor() then
    hook.Add("OnEntityCreated", "LOD_InstallSoldierWeaponSiteAnchor", function(ent)
        if not IsValid(ent) or ent:GetClass() ~= "lod_hostile" then return end
        if installWeaponSiteAnchor() then
            hook.Remove("OnEntityCreated", "LOD_InstallSoldierWeaponSiteAnchor")
        end
    end)
end
