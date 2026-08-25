AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local PICKUP_MODEL = "models/items/boxsrounds.mdl"
local PICKUP_SOUND = "items/itempickup.wav"

function ENT:Initialize()
    self:SetModel(PICKUP_MODEL)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 24))
    self:SetTrigger(true)
    self:SetNotSolid(true)
    self:SetUseType(SIMPLE_USE)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(255, 196, 64, 235))
    self:SetModelScale(1.15, 0)
    self:DrawShadow(false)
end

function ENT:_TryCollect(ply)
    if self.LODCollected then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end

    local run = LOD and LOD.RunManager
    local state = run and run.State
    if not state or state.Failed or state.LevelCleared then return end
    if self.LODTemporaryAmmoLevelSeed and state.LevelSeed ~= self.LODTemporaryAmmoLevelSeed then return end
    if run.IsActivePlayer and not run:IsActivePlayer(ply) then return end

    local ammo = LOD and LOD.DiceAmmo
    if not ammo or not ammo.GrantTemporaryDrop then return end

    local granted = ammo:GrantTemporaryDrop(ply)
    if not granted then return end

    self.LODCollected = true
    ply:EmitSound(PICKUP_SOUND, 62, 100, 0.75, CHAN_ITEM)
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
