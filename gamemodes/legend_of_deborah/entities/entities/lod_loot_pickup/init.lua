LOD = LOD or {}
LOD.RuntimeReceipts = LOD.RuntimeReceipts or {}
LOD.RuntimeReceipts["pickup"] = "stability-20260915-01"
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local DEFAULT_MODEL = "models/items/boxsrounds.mdl"

function ENT:Initialize()
    self.LODLootReady = false
    self:SetModel(self.LODLootModel or DEFAULT_MODEL)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 28))
    self:SetTrigger(true)
    self:SetUseType(SIMPLE_USE)
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(self.LODLootColor or Color(255, 196, 64, 240))
    self:SetModelScale(self.LODLootScale or 1.05, 0)
    self:DrawShadow(false)
    -- Spawn/trigger activation can overlap a player. Admit collection only once
    -- the director has finished metadata and owner-transmission registration.
    timer.Simple(0, function()
        if IsValid(self) and self.LODLootRegistered then self.LODLootReady = true end
    end)
end

function ENT:_TryCollect(ply, acceptEquipment)
    if not self.LODLootReady or self.LODCollected then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local director = LOD and LOD.LootDirector
    if not director or not director.Collect then return end
    if not director:IsPickupOwner(self, ply) then return end

    local ok = director:Collect(self, ply, acceptEquipment)
    if not ok then return end

    -- Keep removal outside native touch traversal; the grant is already sealed.
    timer.Simple(0, function() if IsValid(self) then self:Remove() end end)
end

function ENT:StartTouch(ent)
    self:_TryCollect(ent)
end

function ENT:Touch(ent)
    self:_TryCollect(ent)
end

function ENT:Use(activator)
    self:_TryCollect(activator, true)
end
