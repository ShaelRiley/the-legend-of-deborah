AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local PC = LOD.Config.Progression

local function gateBounds(axis)
    local halfThickness = PC.GateThickness * 0.5
    local halfWidth = PC.GateWidth * 0.5
    local halfHeight = PC.GateBlockerHeight * 0.5
    if axis == 0 then
        return Vector(-halfThickness, -halfWidth, -halfHeight), Vector(halfThickness, halfWidth, halfHeight)
    end
    return Vector(-halfWidth, -halfThickness, -halfHeight), Vector(halfWidth, halfThickness, halfHeight)
end

function ENT:Initialize()
    self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    local mins, maxs = gateBounds(self:GetGateAxis())
    self:SetCollisionBounds(mins, maxs)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:SetUseType(SIMPLE_USE)
    self:SetOpened(false)
    self:SetOpenedAt(0)
    self:DrawShadow(false)
    self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    LOD.ProgressionDirector:TryOpenGate(self:GetGateIndex(), activator, self)
end

function ENT:OpenGate()
    if self:GetOpened() then return end
    self:SetOpened(true)
    self:SetOpenedAt(CurTime())
    self:SetSolid(SOLID_NONE)
    self:SetNotSolid(true)
    self:EmitSound("doors/door1_move.wav", 75, 100, 0.9)
end
