AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local GUIDE_MODEL = "models/monk.mdl"
local PORTAL_MODEL = "models/props_lab/teleplatform.mdl"
local FALLBACK_MODEL = "models/props_lab/teleplatform.mdl"

local function validModel(preferred, fallback)
    if preferred and util.IsValidModel(preferred) then return preferred end
    if fallback and util.IsValidModel(fallback) then return fallback end
    return "models/props_junk/wood_crate001a.mdl"
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

    if staging:ClaimStarter(ply, self) then
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
