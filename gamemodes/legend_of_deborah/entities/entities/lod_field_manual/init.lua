AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
for index = 1, 4 do AddCSLuaFile(string.format("assets/html_%02d.lua", index)) end
for index = 1, 2 do AddCSLuaFile(string.format("assets/page_1_%02d.lua", index)) end
include("shared.lua")

util.AddNetworkString("LOD_OpenFieldManual")

function ENT:Initialize()
    self:SetModel("models/props_junk/PopCan01a.mdl")
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-28, -24, 0), Vector(28, 24, 54))
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
    self:SetRenderMode(RENDERMODE_NORMAL)
    self:SetColor(Color(255, 255, 255, 255))
    self:DrawShadow(false)
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() or not activator:Alive() then return end
    local staging = LOD and LOD.StagingDeployment
    if staging and staging.IsDeployed and staging:IsDeployed(activator) then return end
    if not activator:GetNW2Bool("LOD_Staged", false) then return end

    net.Start("LOD_OpenFieldManual")
    net.Send(activator)
end
