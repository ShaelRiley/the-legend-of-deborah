AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

util.AddNetworkString("LOD_StagingStarterCelebration")

local GUIDE_MODEL = "models/monk.mdl"
local PORTAL_MODEL = "models/props_lab/teleplatform.mdl"
local TORCH_MODEL = "models/props_c17/light_cagelight02_on.mdl"
local FALLBACK_MODEL = "models/props_lab/teleplatform.mdl"

local WEAPON_LABELS = {
    weapon_shotgun = "SHOTGUN",
    weapon_smg1 = "SMG",
    weapon_357 = ".357 MAGNUM",
    weapon_ar2 = "AR2"
}

local function validModel(preferred, fallback)
    if preferred and util.IsValidModel(preferred) then return preferred end
    if fallback and util.IsValidModel(fallback) then return fallback end
    return "models/props_junk/wood_crate001a.mdl"
end

local function boneAngle(ent, name, ang)
    local bone = ent:LookupBone(name)
    if bone then ent:ManipulateBoneAngles(bone, ang) end
end

local function applyGrigoriPose(ent)
    if not IsValid(ent) then return end

    ent:ResetSequence(0)
    ent:SetCycle(0)
    ent:SetPlaybackRate(0)

    boneAngle(ent, "ValveBiped.Bip01_L_Thigh", Angle(0, 0, 18))
    boneAngle(ent, "ValveBiped.Bip01_R_Thigh", Angle(0, 0, -18))
    boneAngle(ent, "ValveBiped.Bip01_L_Calf", Angle(0, 0, -7))
    boneAngle(ent, "ValveBiped.Bip01_R_Calf", Angle(0, 0, 7))

    boneAngle(ent, "ValveBiped.Bip01_L_UpperArm", Angle(-8, -28, -58))
    boneAngle(ent, "ValveBiped.Bip01_L_Forearm", Angle(2, -70, -12))
    boneAngle(ent, "ValveBiped.Bip01_L_Hand", Angle(0, 0, 28))

    boneAngle(ent, "ValveBiped.Bip01_R_UpperArm", Angle(-12, 22, 52))
    boneAngle(ent, "ValveBiped.Bip01_R_Forearm", Angle(0, 58, 18))
    boneAngle(ent, "ValveBiped.Bip01_R_Hand", Angle(-8, 0, -28))

    for _, name in ipairs({
        "ValveBiped.Bip01_R_Finger1", "ValveBiped.Bip01_R_Finger11",
        "ValveBiped.Bip01_R_Finger2", "ValveBiped.Bip01_R_Finger21",
        "ValveBiped.Bip01_R_Finger3", "ValveBiped.Bip01_R_Finger31",
        "ValveBiped.Bip01_R_Finger4", "ValveBiped.Bip01_R_Finger41"
    }) do
        boneAngle(ent, name, Angle(0, 0, 58))
    end
    boneAngle(ent, "ValveBiped.Bip01_R_Finger0", Angle(0, -42, -28))
    boneAngle(ent, "ValveBiped.Bip01_R_Finger01", Angle(0, -18, -8))

    if ent.SetFlexScale then ent:SetFlexScale(1) end
    if ent.GetFlexNum and ent.GetFlexName and ent.SetFlexWeight then
        for flex = 0, ent:GetFlexNum() - 1 do
            local name = string.lower(ent:GetFlexName(flex) or "")
            local weight = nil
            if string.find(name, "smile", 1, true) or string.find(name, "happy", 1, true)
                or string.find(name, "grin", 1, true)
            then
                weight = 1
            elseif string.find(name, "jaw", 1, true)
                and (string.find(name, "drop", 1, true) or string.find(name, "open", 1, true))
            then
                weight = 0.24
            elseif string.find(name, "cheek", 1, true) and string.find(name, "raise", 1, true) then
                weight = 0.55
            end
            if weight then ent:SetFlexWeight(flex, weight) end
        end
    end

    ent.LODGuidePoseName = "wide-stance-hip-thumbs-up-grin"
end

local function localOffset(center, angles, forward, right, up)
    local yaw = Angle(0, angles.y, 0)
    return center
        + yaw:Forward() * (forward or 0)
        + yaw:Right() * (right or 0)
        + Vector(0, 0, up or 0)
end

local function appendHutEntity(staging, ent)
    if not IsValid(ent) then return nil end
    staging.HutEntities = staging.HutEntities or {}
    staging.HutEntities[#staging.HutEntities + 1] = ent
    return ent
end

local function removeIfValid(ent)
    if IsValid(ent) then ent:Remove() end
end

local function clearFeatureEntities(staging)
    removeIfValid(staging.SignEntity)
    removeIfValid(staging.ManualEntity)
    removeIfValid(staging.MirrorEntity)
    removeIfValid(staging.StarterPedestalEntity)
    for _, torch in ipairs(staging.TorchEntities or {}) do removeIfValid(torch) end
    staging.SignEntity = nil
    staging.ManualEntity = nil
    staging.MirrorEntity = nil
    staging.StarterPedestalEntity = nil
    staging.TorchEntities = {}
end

local function findDeborahDoll(staging)
    local center = staging.HutCenter
    if not center then return nil end
    local radius = math.max(tonumber(staging.HutHalfForward) or 448,
        tonumber(staging.HutHalfRight) or 288) + 32

    local best
    for _, ent in ipairs(ents.FindInBox(
        center + Vector(-radius, -radius, -36),
        center + Vector(radius, radius, 170)
    )) do
        if IsValid(ent) and ent:GetClass() ~= "lod_staging_prop"
            and ent:GetClass() ~= "lod_field_manual"
            and ent:GetClass() ~= "lod_staging_mirror"
        then
            local model = string.lower(ent:GetModel() or "")
            if model ~= "" and string.find(model, "doll", 1, true) then
                local distance = ent:GetPos():DistToSqr(center)
                if not best or distance < best.distance then
                    best = {entity = ent, distance = distance, model = model}
                end
            end
        end
    end
    return best
end

local function featureWallLayout(staging)
    local center = staging.HutCenter
    local yaw = Angle(0, staging.HutAngles.y, 0)
    local fwd, right = yaw:Forward(), yaw:Right()
    local halfF = math.max(120, tonumber(staging.HutHalfForward) or 448)
    local halfR = math.max(90, tonumber(staging.HutHalfRight) or 288)
    local inset = 46

    local doll = findDeborahDoll(staging)
    local manualPos, manualInward, mirrorPos, mirrorInward

    if doll and IsValid(doll.entity) then
        local rel = doll.entity:GetPos() - center
        local localF = rel:Dot(fwd)
        local localR = rel:Dot(right)
        local nearF = halfF - math.abs(localF)
        local nearR = halfR - math.abs(localR)

        if nearR <= nearF then
            local side = localR >= 0 and 1 or -1
            local tangent = math.Clamp(
                localF + (localF >= 0 and -82 or 82),
                -halfF + 90, halfF - 90)
            manualPos = center + right * (side * (halfR - inset)) + fwd * tangent
            manualInward = right * -side
            mirrorPos = center + right * (-side * (halfR - 14))
            mirrorInward = right * side
        else
            local side = localF >= 0 and 1 or -1
            local tangent = math.Clamp(
                localR + (localR >= 0 and -82 or 82),
                -halfR + 90, halfR - 90)
            manualPos = center + fwd * (side * (halfF - inset)) + right * tangent
            manualInward = fwd * -side
            mirrorPos = center + fwd * (-side * (halfF - 14))
            mirrorInward = fwd * side
        end

        staging.FeatureDollModel = doll.model
    else
        manualPos = center - right * (halfR - inset) + fwd * 42
        manualInward = right
        mirrorPos = center + right * (halfR - 14)
        mirrorInward = -right
        staging.FeatureDollModel = "not-found"
    end

    manualPos.z = center.z + 2
    mirrorPos.z = center.z + 2
    local manualAng = manualInward:Angle()
    manualAng.p, manualAng.r = 0, 0
    local mirrorAng = mirrorInward:Angle()
    mirrorAng.p, mirrorAng.r = 0, 0
    return manualPos, manualAng, mirrorPos, mirrorAng
end

local function ensureRoomDecor()
    local staging = LOD and LOD.StagingDeployment
    if not staging or not staging.HutCenter or not staging.HutAngles then return false end

    local validTorches = 0
    for _, torch in ipairs(staging.TorchEntities or {}) do
        if IsValid(torch) then validTorches = validTorches + 1 end
    end
    if IsValid(staging.SignEntity)
        and validTorches >= 2
        and IsValid(staging.ManualEntity)
        and IsValid(staging.MirrorEntity)
        and IsValid(staging.StarterPedestalEntity)
    then
        return true
    end

    clearFeatureEntities(staging)

    local center = staging.HutCenter
    local angles = staging.HutAngles
    local halfForward = math.max(120, tonumber(staging.HutHalfForward) or 180)
    local halfRight = math.max(90, tonumber(staging.HutHalfRight) or 130)
    local guideDistance = tonumber(staging.HutGuideDistance) or 72

    local sign = ents.Create("lod_staging_prop")
    if IsValid(sign) then
        sign:SetStageKind(sign.KIND_SIGN or 4)
        sign:SetStageLabel("IT'S DANGEROUS TO GO\nALONE! TAKE THIS.")
        sign:SetPos(localOffset(center, angles, halfForward - 48, 0, 96))
        sign:SetAngles(Angle(0, angles.y + 180, 0))
        sign:Spawn()
        sign:Activate()
        staging.SignEntity = appendHutEntity(staging, sign)
    end

    local torchForward = math.min(halfForward - 42, guideDistance + 48)
    local torchRight = math.min(halfRight - 34, math.max(74, halfRight * 0.32))
    for _, side in ipairs({-1, 1}) do
        local torch = ents.Create("lod_staging_prop")
        if IsValid(torch) then
            torch:SetStageKind(torch.KIND_TORCH or 5)
            torch:SetStageLabel("")
            torch.LODStageModel = TORCH_MODEL
            torch:SetPos(localOffset(center, angles, torchForward, torchRight * side, 34))
            torch:SetAngles(Angle(0, angles.y + 180, 0))
            torch:Spawn()
            torch:Activate()
            staging.TorchEntities[#staging.TorchEntities + 1] = appendHutEntity(staging, torch)
        end
    end

    local pedestal = ents.Create("lod_staging_prop")
    if IsValid(pedestal) then
        pedestal:SetStageKind(pedestal.KIND_PEDESTAL or 6)
        pedestal:SetStageLabel("")
        local starterPos = staging._StarterPosition and staging:_StarterPosition()
            or localOffset(center, angles, 24, 0, 20)
        pedestal:SetPos(Vector(starterPos.x, starterPos.y, center.z + 2))
        pedestal:SetAngles(angles)
        pedestal:Spawn()
        pedestal:Activate()
        staging.StarterPedestalEntity = appendHutEntity(staging, pedestal)
    end

    local manualPos, manualAng, mirrorPos, mirrorAng = featureWallLayout(staging)

    local manual = ents.Create("lod_field_manual")
    if IsValid(manual) then
        manual:SetPos(manualPos)
        manual:SetAngles(manualAng)
        manual:Spawn()
        manual:Activate()
        staging.ManualEntity = appendHutEntity(staging, manual)
    end

    local mirror = ents.Create("lod_staging_mirror")
    if IsValid(mirror) then
        mirror:SetPos(mirrorPos)
        mirror:SetAngles(mirrorAng)
        mirror:Spawn()
        mirror:Activate()
        staging.MirrorEntity = appendHutEntity(staging, mirror)
    end

    return IsValid(staging.SignEntity)
        and IsValid(staging.ManualEntity)
        and IsValid(staging.MirrorEntity)
        and IsValid(staging.StarterPedestalEntity)
end

function ENT:Initialize()
    local kind = self:GetStageKind()

    if kind == self.KIND_GUIDE then
        self:SetModel(validModel(self.LODStageModel, GUIDE_MODEL))
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionBounds(Vector(-18, -18, 0), Vector(18, 18, 74))
        self:SetCollisionGroup(COLLISION_GROUP_NONE)
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(196, 60, 60, 255))
        self:SetUseType(SIMPLE_USE)
        self:DrawShadow(true)
        timer.Simple(0, function()
            if not IsValid(self) then return end
            applyGrigoriPose(self)
            ensureRoomDecor()
        end)
        return
    end

    if kind == self.KIND_PORTAL then
        self:SetModel(validModel(self.LODStageModel, PORTAL_MODEL))
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_BBOX)
        self:SetCollisionBounds(Vector(-52, -52, 0), Vector(52, 52, 12))
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(92, 148, 255, 235))
        self:SetUseType(SIMPLE_USE)
        self:DrawShadow(false)
        return
    end

    if kind == self.KIND_SIGN then
        self:SetModel(validModel(nil, "models/props_junk/PopCan01a.mdl"))
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        self:SetRenderMode(RENDERMODE_NORMAL)
        self:SetColor(Color(255, 255, 255, 255))
        self:DrawShadow(false)
        return
    end

    if kind == self.KIND_TORCH then
        self:SetModel(validModel(self.LODStageModel, TORCH_MODEL))
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(150, 78, 42, 255))
        self:SetModelScale(0.42, 0)
        self:DrawShadow(false)
        return
    end

    if kind == self.KIND_PEDESTAL then
        self:SetModel(validModel(nil, "models/props_junk/PopCan01a.mdl"))
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
        self:SetRenderMode(RENDERMODE_NORMAL)
        self:SetColor(Color(255, 255, 255, 255))
        self:DrawShadow(false)
        return
    end

    self:SetModel(validModel(self.LODStageModel, FALLBACK_MODEL))
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-18, -18, 0), Vector(18, 18, 30))
    self:SetTrigger(true)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(248, 213, 105, 255))
    self:SetUseType(SIMPLE_USE)
    self:SetModelScale(1.08, 0)
    self:DrawShadow(false)
end

function ENT:_TryStarterClaim(ply)
    if self.LODStageClaimed then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local staging = LOD and LOD.StagingDeployment
    if not staging or not staging.ClaimStarter then return end

    local weaponClass = self.LODStagingWeaponClass or ""
    local weaponModel = self:GetModel() or ""
    local weaponLabel = WEAPON_LABELS[weaponClass] or string.upper(self:GetStageLabel() or "STARTER")

    if staging:ClaimStarter(ply, self) then
        net.Start("LOD_StagingStarterCelebration")
            net.WriteString(weaponClass)
            net.WriteString(weaponLabel)
            net.WriteString(weaponModel)
        net.Send(ply)

        self.LODStageClaimed = true
        self:Remove()
    end
end

function ENT:StartTouch(ent)
    if self:GetStageKind() == self.KIND_WEAPON then self:_TryStarterClaim(ent) end
end

function ENT:Touch(ent)
    if self:GetStageKind() == self.KIND_WEAPON then self:_TryStarterClaim(ent) end
end

function ENT:Use(activator)
    local kind = self:GetStageKind()
    if kind == self.KIND_WEAPON then
        self:_TryStarterClaim(activator)
        return
    end

    if kind == self.KIND_PORTAL then
        local staging = LOD and LOD.StagingDeployment
        if staging and staging.DeployPlayer then staging:DeployPlayer(activator, self) end
    end
end

concommand.Add("lod_staging_presentation_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local staging = LOD and LOD.StagingDeployment
    local guide = staging and staging.GuideEntity
    local sign = staging and staging.SignEntity
    local torches = 0
    if staging then
        for _, torch in ipairs(staging.TorchEntities or {}) do
            if IsValid(torch) then torches = torches + 1 end
        end
    end

    local pass = staging
        and IsValid(guide)
        and IsValid(sign)
        and torches >= 2
        and IsValid(staging.ManualEntity)
        and IsValid(staging.MirrorEntity)
        and IsValid(staging.StarterPedestalEntity)

    local line = string.format(
        "guide=%s pose=wide-thumbs-up-grin sign=%s torches=%d manual=%s mirror=%s starterPedestal=%s doll=%s celebrationNet=ARMED result=%s",
        tostring(IsValid(guide)), tostring(IsValid(sign)), torches,
        tostring(staging and IsValid(staging.ManualEntity)),
        tostring(staging and IsValid(staging.MirrorEntity)),
        tostring(staging and IsValid(staging.StarterPedestalEntity)),
        tostring(staging and staging.FeatureDollModel or "none"),
        pass and "PASS" or "FAIL")
    print("[LOD:STAGING-PRESENTATION] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)

concommand.Add("lod_staging_manual_status", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local staging = LOD and LOD.StagingDeployment
    local pass = staging and IsValid(staging.ManualEntity) and IsValid(staging.MirrorEntity)
    local line = string.format(
        "manual=%s mirror=%s starterPedestal=%s hut=%s reader=ATTACHED-23-PAGE sounds=ATTACHED result=%s",
        tostring(staging and IsValid(staging.ManualEntity)),
        tostring(staging and IsValid(staging.MirrorEntity)),
        tostring(staging and IsValid(staging.StarterPedestalEntity)),
        tostring(staging and staging._HutValid and staging:_HutValid() or false),
        pass and "PASS" or "FAIL")
    print("[LOD:STAGING-MANUAL] " .. line)
    if IsValid(ply) then ply:ChatPrint(line) end
end)
