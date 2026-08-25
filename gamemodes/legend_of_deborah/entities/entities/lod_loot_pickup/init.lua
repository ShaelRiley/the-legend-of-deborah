AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DEFAULT_MODEL = "models/items/boxsrounds.mdl"

function ENT:Initialize()
    self:SetModel(self.LODLootModel or DEFAULT_MODEL)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 28))
    self:SetTrigger(true)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(self.LODLootColor or Color(255, 196, 64, 240))
    self:SetModelScale(self.LODLootScale or 1.05, 0)
    self:DrawShadow(false)
end

function ENT:_TryCollect(ply)
    if self.LODCollected then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local director = LOD and LOD.LootDirector
    if not director or not director.Collect then return end
    if not director:IsPickupOwner(self, ply) then return end

    local ok = director:Collect(self, ply)
    if not ok then return end

    self.LODCollected = true
    self:Remove()
end

function ENT:StartTouch(ent)
    self:_TryCollect(ent)
end

function ENT:Touch(ent)
    self:_TryCollect(ent)
end

function ENT:Use(activator)
    self:_TryCollect(activator)
end
