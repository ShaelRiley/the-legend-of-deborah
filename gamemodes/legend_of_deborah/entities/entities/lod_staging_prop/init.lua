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

local GUIDE_IDLE_SEQUENCES = {
    "idle02",
    "idle01",
    "idle03",
    "idle04",
    "idle_all_01",
    "idle"
}

local function validModel(preferred, fallback)
    if preferred and util.IsValidModel(preferred) then return preferred end
    if fallback and util.IsValidModel(fallback) then return fallback end
    return "models/props_junk/wood_crate001a.mdl"
end

local function startGuideIdle(ent)
    for _, sequenceName in ipairs(GUIDE_IDLE_SEQUENCES) do
        local sequence = ent:LookupSequence(sequenceName)
        if sequence and sequence >= 0 then
            ent:ResetSequence(sequence)
            ent:SetCycle(0)
            ent:SetPlaybackRate(0.82)
            ent.LODGuideIdleSequence = sequence
            return true
        end
    end

    local sequence = ent:SelectWeightedSequence(ACT_IDLE)
    if sequence and sequence >= 0 then
        ent:ResetSequence(sequence)
        ent:SetCycle(0)
        ent:SetPlaybackRate(0.82)
        ent.LODGuideIdleSequence = sequence
        return true
    end

    return false
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

local function ensureRoomDecor()
    local staging = LOD and LOD.StagingDeployment
    if not staging or not staging.HutCenter or not staging.HutAngles then return false end

    local validTorches = 0
    for _, torch in ipairs(staging.TorchEntities or {}) do
        if IsValid(torch) then validTorches = validTorches + 1 end
    end
    if IsValid(staging.SignEntity) and validTorches >= 2 then return true end

    removeIfValid(staging.SignEntity)
    for _, torch in ipairs(staging.TorchEntities or {}) do removeIfValid(torch) end
    staging.SignEntity = nil
    staging.TorchEntities = {}

    local center = staging.HutCenter
    local angles = staging.HutAngles
    local halfForward = math.max(120, tonumber(staging.HutHalfForward) or 180)
    local halfRight = math.max(90, tonumber(staging.HutHalfRight) or 130)
    local guideDistance = tonumber(staging.HutGuideDistance) or 72

    local sign = ents.Create("lod_staging_prop")
    if IsValid(sign) then
        sign:SetStageKind(sign.KIND_SIGN or 4)
        sign:SetStageLabel("IT'S DANGEROUS TO GO\nALONE! TAKE THIS.")
        sign:SetPos(localOffset(center, angles, halfForward - 18, 0, 112))
        sign:SetAngles(Angle(0, angles.y + 180, 0))
        sign:Spawn()
        sign:Activate()
        staging.SignEntity = appendHutEntity(staging, sign)
    end

    local torchForward = math.min(halfForward - 30, guideDistance + 38)
    local torchRight = math.min(halfRight - 26, math.max(70, halfRight * 0.32))
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

    return IsValid(staging.SignEntity) and #staging.TorchEntities >= 2
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
        startGuideIdle(self)
        timer.Simple(0, function()
            if IsValid(self) then ensureRoomDecor() end
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
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(255, 255, 255, 0))
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
