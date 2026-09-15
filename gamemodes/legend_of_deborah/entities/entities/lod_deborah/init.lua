AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel(LOD.Config.Models.Deborah)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionBounds(Vector(-18, -18, 0), Vector(18, 18, 72))
    self:SetTrigger(true)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
    self:DropToFloor()
    self:DrawShadow(true)

    local sequence = self:LookupSequence("LineIdle01")
    if sequence and sequence >= 0 then
        self:ResetSequence(sequence)
        self:SetPlaybackRate(1)
    end
end

function ENT:StartTouch(ent)
    if IsValid(ent) and ent:IsPlayer() then
        LOD.ProgressionDirector:OnDeborahTouched(ent)
    end
end


-- Run only the explicitly unlocked celebration; no locomotion or hull changes.
function ENT:Think()
    if self:GetNW2Bool("LOD_RescueCheerSequence",false) then
        self:FrameAdvance()
        if self:GetCycle()>=0.99 then self:SetCycle(0) end
        self:NextThink(CurTime()+0.05)
    else self:NextThink(CurTime()+0.25) end
    return true
end
