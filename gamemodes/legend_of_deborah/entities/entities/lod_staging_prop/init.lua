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

local function configureAnchor(ent)
    ent:SetModel(validModel(nil, "models/props_junk/PopCan01a.mdl"))
    ent:SetMoveType(MOVETYPE_NONE)
    ent:SetSolid(SOLID_NONE)
    ent:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    ent:SetRenderMode(RENDERMODE_NORMAL)
    ent:SetColor(Color(255, 255, 255, 255))
    ent:DrawShadow(false)
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
        self:DrawShadow(true)
        return
    end

    if kind == self.KIND_PORTAL then
        self:SetModel(validModel(self.LODStageModel, PORTAL_MODEL))
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_BBOX)
        -- Source's physical pad remains compact. The shared tall vortex volume in
        -- shared.lua is the authoritative aimed Use geometry.
        self:SetCollisionBounds(Vector(-52, -52, 0), Vector(52, 52, 12))
        self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        self:SetRenderMode(RENDERMODE_TRANSCOLOR)
        self:SetColor(Color(92, 148, 255, 235))
        self:SetUseType(SIMPLE_USE)
        self:DrawShadow(false)
        return
    end

    if kind == self.KIND_SIGN or kind == self.KIND_PEDESTAL then
        configureAnchor(self)
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

    -- Starter weapon pickup. Presentation model/class are supplied by staging.
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

    if not staging:ClaimStarter(ply, self) then return end

    net.Start("LOD_StagingStarterCelebration")
        net.WriteString(weaponClass)
        net.WriteString(weaponLabel)
        net.WriteString(weaponModel)
    net.Send(ply)

    self.LODStageClaimed = true
    self:Remove()
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
    local torches = 0
    if staging then
        for _, torch in ipairs(staging.TorchEntities or {}) do
            if IsValid(torch) then torches = torches + 1 end
        end
    end

    local guide = staging and staging.GuideEntity
    local pass = staging
        and IsValid(guide)
        and IsValid(staging.SignEntity)
        and torches >= 2
        and IsValid(staging.ManualEntity)
        and IsValid(staging.MirrorEntity)
        and IsValid(staging.StarterPedestalEntity)

    local line = string.format(
        "guide=%s pose=wide-thumbs-up-grin sign=%s torches=%d manual=%s mirror=%s starterPedestal=%s doll=%s celebrationNet=ARMED result=%s",
        tostring(IsValid(guide)), tostring(staging and IsValid(staging.SignEntity)), torches,
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
