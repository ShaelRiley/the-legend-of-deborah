AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_NONE)
    self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(255, 255, 255, 0))
    self:DrawShadow(false)
end
